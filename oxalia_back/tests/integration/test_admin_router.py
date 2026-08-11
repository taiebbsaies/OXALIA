import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import Role
from app.repositories import user_repository

JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 32


async def register_and_login(client, *, full_name: str = "Dr Test") -> tuple[str, dict]:
    email = f"doc_{uuid.uuid4().hex}@test.com"
    password = "StrongPassw0rd!"

    resp = await client.post(
        "/auth/register",
        json={"email": email, "password": password, "full_name": full_name},
    )
    assert resp.status_code == 201
    user_id = resp.json()["id"]

    resp = await client.post("/auth/login", json={"email": email, "password": password})
    assert resp.status_code == 200
    token = resp.json()["access_token"]

    return user_id, {"Authorization": f"Bearer {token}"}


async def promote_to_admin(db: AsyncSession, user_id: str) -> None:
    user = await user_repository.get_by_id(db, uuid.UUID(user_id))
    await user_repository.update_fields(db, user, role=Role.ADMIN)


async def test_admin_endpoints_require_auth(client):
    assert (await client.get("/admin/stats")).status_code in (401, 403)
    assert (await client.get("/admin/users")).status_code in (401, 403)


async def test_admin_endpoints_reject_non_admin(client):
    _, headers = await register_and_login(client)

    resp = await client.get("/admin/stats", headers=headers)
    assert resp.status_code == 403

    resp = await client.get("/admin/users", headers=headers)
    assert resp.status_code == 403


async def test_admin_stats_returns_platform_counters(client, db):
    admin_id, admin_headers = await register_and_login(client, full_name="Dr Admin")
    await promote_to_admin(db, admin_id)
    _, clinician_headers = await register_and_login(client, full_name="Dr Clinician")

    resp = await client.get("/admin/stats", headers=admin_headers)
    assert resp.status_code == 200
    body = resp.json()
    assert body["total_users"] >= 2
    assert body["clinician_count"] >= 1
    assert body["admin_count"] >= 1
    assert "user_growth" in body
    assert "exam_volume" in body


async def test_admin_can_list_users(client, db):
    admin_id, admin_headers = await register_and_login(client, full_name="Dr Admin")
    await promote_to_admin(db, admin_id)
    clinician_id, _ = await register_and_login(client, full_name="Dr Clinician")

    resp = await client.get("/admin/users", headers=admin_headers)
    assert resp.status_code == 200
    emails_and_ids = {u["id"] for u in resp.json()}
    assert admin_id in emails_and_ids
    assert clinician_id in emails_and_ids


async def test_admin_can_change_user_role(client, db):
    admin_id, admin_headers = await register_and_login(client, full_name="Dr Admin")
    await promote_to_admin(db, admin_id)
    clinician_id, _ = await register_and_login(client, full_name="Dr Clinician")

    resp = await client.patch(
        f"/admin/users/{clinician_id}", json={"role": "admin"}, headers=admin_headers
    )
    assert resp.status_code == 200
    assert resp.json()["role"] == "admin"


async def test_admin_cannot_delete_self(client, db):
    admin_id, admin_headers = await register_and_login(client, full_name="Dr Admin")
    await promote_to_admin(db, admin_id)

    resp = await client.delete(f"/admin/users/{admin_id}", headers=admin_headers)
    assert resp.status_code == 400


async def test_admin_can_delete_other_user(client, db):
    admin_id, admin_headers = await register_and_login(client, full_name="Dr Admin")
    await promote_to_admin(db, admin_id)
    clinician_id, _ = await register_and_login(client, full_name="Dr Clinician")

    resp = await client.delete(f"/admin/users/{clinician_id}", headers=admin_headers)
    assert resp.status_code == 204

    resp = await client.get("/admin/users", headers=admin_headers)
    remaining_ids = {u["id"] for u in resp.json()}
    assert clinician_id not in remaining_ids


async def test_cannot_remove_last_active_admin(client, db):
    admin_id, admin_headers = await register_and_login(client, full_name="Dr Admin")
    await promote_to_admin(db, admin_id)

    resp = await client.patch(
        f"/admin/users/{admin_id}", json={"role": "clinician"}, headers=admin_headers
    )
    assert resp.status_code == 400
