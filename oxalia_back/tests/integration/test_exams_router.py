import uuid

import pytest

from app.config import settings
from app.models.exam import Exam, ExamStatus
from app.models.inference_result import InferenceResult
from app.routers import exams as exams_router

JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 32


@pytest.fixture(autouse=True)
def _isolate_uploads_and_inference(monkeypatch, tmp_path):
    """Store uploads in a temp dir and stub out background inference so tests
    never touch the real DB session owned by the background task."""
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))

    async def _noop_inference(exam_id, image_path):
        return None

    monkeypatch.setattr(exams_router, "run_inference", _noop_inference)


async def register_and_login(client) -> tuple[str, dict]:
    email = f"doc_{uuid.uuid4().hex}@test.com"
    password = "StrongPassw0rd!"

    resp = await client.post(
        "/auth/register",
        json={"email": email, "password": password, "full_name": "Dr Test"},
    )
    assert resp.status_code == 201
    user_id = resp.json()["id"]

    resp = await client.post("/auth/login", json={"email": email, "password": password})
    assert resp.status_code == 200
    token = resp.json()["access_token"]

    return user_id, {"Authorization": f"Bearer {token}"}


async def upload_exam(client, headers: dict, patient_name: str = "Jane Doe"):
    return await client.post(
        "/exams/upload",
        files={"file": ("scan.jpg", JPEG_BYTES, "image/jpeg")},
        data={"patient_name": patient_name},
        headers=headers,
    )


async def test_upload_requires_auth(client):
    resp = await client.post(
        "/exams/upload",
        files={"file": ("scan.jpg", JPEG_BYTES, "image/jpeg")},
        data={"patient_name": "Jane Doe"},
    )
    assert resp.status_code in (401, 403)


async def test_upload_valid_image_returns_201_pending(client):
    _, headers = await register_and_login(client)

    resp = await upload_exam(client, headers, patient_name="Jane Doe")

    assert resp.status_code == 201
    body = resp.json()
    assert body["patient_name"] == "Jane Doe"
    assert body["original_filename"] == "Jane_Doe.jpg"
    assert body["content_type"] == "image/jpeg"
    assert body["size_bytes"] == len(JPEG_BYTES)
    assert body["status"] == "pending"


async def test_upload_blank_patient_name_rejected(client):
    _, headers = await register_and_login(client)

    resp = await client.post(
        "/exams/upload",
        files={"file": ("scan.jpg", JPEG_BYTES, "image/jpeg")},
        data={"patient_name": "   "},
        headers=headers,
    )
    assert resp.status_code == 400


async def test_upload_empty_image_rejected(client):
    _, headers = await register_and_login(client)

    resp = await client.post(
        "/exams/upload",
        files={"file": ("empty.jpg", b"", "image/jpeg")},
        data={"patient_name": "Jane Doe"},
        headers=headers,
    )
    assert resp.status_code == 400


async def test_upload_spoofed_image_rejected(client):
    _, headers = await register_and_login(client)

    resp = await client.post(
        "/exams/upload",
        files={"file": ("malware.jpg", b"MZ" + b"\x00" * 64, "image/jpeg")},
        data={"patient_name": "Jane Doe"},
        headers=headers,
    )
    assert resp.status_code == 415


async def test_get_exam_returns_own_exam(client):
    _, headers = await register_and_login(client)
    exam_id = (await upload_exam(client, headers)).json()["id"]

    resp = await client.get(f"/exams/{exam_id}", headers=headers)

    assert resp.status_code == 200
    assert resp.json()["id"] == exam_id


async def test_get_exam_not_found(client):
    _, headers = await register_and_login(client)

    resp = await client.get(f"/exams/{uuid.uuid4()}", headers=headers)

    assert resp.status_code == 404


async def test_get_exam_of_other_user_returns_404(client):
    _, headers_owner = await register_and_login(client)
    exam_id = (await upload_exam(client, headers_owner)).json()["id"]

    _, headers_other = await register_and_login(client)
    resp = await client.get(f"/exams/{exam_id}", headers=headers_other)

    assert resp.status_code == 404


async def test_get_result_not_ready_returns_404(client):
    _, headers = await register_and_login(client)
    exam_id = (await upload_exam(client, headers)).json()["id"]

    resp = await client.get(f"/exams/{exam_id}/result", headers=headers)

    assert resp.status_code == 404


async def test_get_result_failed_exam_returns_500(client, db):
    user_id, headers = await register_and_login(client)
    exam = Exam(
        owner_id=uuid.UUID(user_id),
        patient_name="Jane Doe",
        original_filename="Jane_Doe.jpg",
        storage_path="uploads/scan.jpg",
        content_type="image/jpeg",
        size_bytes=len(JPEG_BYTES),
        status=ExamStatus.FAILED,
    )
    db.add(exam)
    await db.commit()

    resp = await client.get(f"/exams/{exam.id}/result", headers=headers)

    assert resp.status_code == 500


async def test_get_result_completed_exam_returns_result(client, db):
    user_id, headers = await register_and_login(client)
    exam = Exam(
        owner_id=uuid.UUID(user_id),
        patient_name="Jane Doe",
        original_filename="Jane_Doe.jpg",
        storage_path="uploads/scan.jpg",
        content_type="image/jpeg",
        size_bytes=len(JPEG_BYTES),
        status=ExamStatus.COMPLETED,
    )
    db.add(exam)
    await db.commit()

    result = InferenceResult(
        exam_id=exam.id,
        model_version="stub-0.1.0",
        result_json={"findings": [{"label": "No Finding", "probability": 0.91}]},
    )
    db.add(result)
    await db.commit()

    resp = await client.get(f"/exams/{exam.id}/result", headers=headers)

    assert resp.status_code == 200
    body = resp.json()
    assert body["exam_id"] == str(exam.id)
    assert body["model_version"] == "stub-0.1.0"
    assert body["result_json"]["findings"][0]["label"] == "No Finding"


async def test_list_exams_returns_only_own_newest_first(client):
    _, headers_owner = await register_and_login(client)
    first_id = (await upload_exam(client, headers_owner)).json()["id"]
    second_id = (await upload_exam(client, headers_owner)).json()["id"]

    _, headers_other = await register_and_login(client)
    await upload_exam(client, headers_other)

    resp = await client.get("/exams", headers=headers_owner)

    assert resp.status_code == 200
    ids = [exam["id"] for exam in resp.json()]
    assert ids == [second_id, first_id]


async def test_list_exams_pagination(client):
    _, headers = await register_and_login(client)
    for _ in range(3):
        await upload_exam(client, headers)

    page = await client.get("/exams?limit=2&offset=0", headers=headers)
    rest = await client.get("/exams?limit=2&offset=2", headers=headers)

    assert len(page.json()) == 2
    assert len(rest.json()) == 1


async def test_stats_empty_for_new_user(client):
    _, headers = await register_and_login(client)

    resp = await client.get("/exams/stats", headers=headers)

    assert resp.status_code == 200
    assert resp.json() == {
        "total": 0,
        "completed": 0,
        "processing": 0,
        "failed": 0,
        "model_versions": {},
    }


async def test_stats_counts_statuses_and_model_versions(client, db):
    user_id, headers = await register_and_login(client)
    owner = uuid.UUID(user_id)

    for status_value in (
        ExamStatus.COMPLETED,
        ExamStatus.COMPLETED,
        ExamStatus.PENDING,
        ExamStatus.FAILED,
    ):
        exam = Exam(
            owner_id=owner,
            patient_name="Jane Doe",
            original_filename="Jane_Doe.jpg",
            storage_path="uploads/scan.jpg",
            content_type="image/jpeg",
            size_bytes=len(JPEG_BYTES),
            status=status_value,
        )
        db.add(exam)
        await db.commit()
        if status_value == ExamStatus.COMPLETED:
            db.add(
                InferenceResult(
                    exam_id=exam.id,
                    model_version="stub-0.1.0",
                    result_json={"findings": []},
                )
            )
            await db.commit()

    resp = await client.get("/exams/stats", headers=headers)

    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 4
    assert body["completed"] == 2
    assert body["processing"] == 1
    assert body["failed"] == 1
    assert body["model_versions"] == {"stub-0.1.0": 2}


async def test_get_exam_image_returns_stored_file(client):
    _, headers = await register_and_login(client)
    exam_id = (await upload_exam(client, headers)).json()["id"]

    resp = await client.get(f"/exams/{exam_id}/image", headers=headers)

    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("image/jpeg")
    assert resp.content == JPEG_BYTES


async def test_get_exam_image_of_other_user_returns_404(client):
    _, headers_owner = await register_and_login(client)
    exam_id = (await upload_exam(client, headers_owner)).json()["id"]

    _, headers_other = await register_and_login(client)
    resp = await client.get(f"/exams/{exam_id}/image", headers=headers_other)

    assert resp.status_code == 404


async def test_get_exam_image_missing_file_returns_404(client, db):
    user_id, headers = await register_and_login(client)
    exam = Exam(
        owner_id=uuid.UUID(user_id),
        patient_name="Jane Doe",
        original_filename="Jane_Doe.jpg",
        storage_path="uploads/does-not-exist.jpg",
        content_type="image/jpeg",
        size_bytes=len(JPEG_BYTES),
    )
    db.add(exam)
    await db.commit()

    resp = await client.get(f"/exams/{exam.id}/image", headers=headers)

    assert resp.status_code == 404
