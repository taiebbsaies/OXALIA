import io

import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers

from app.config import settings
from app.services import image_service

JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 32
PNG_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32


def make_upload(
    data: bytes, filename: str = "scan.jpg", content_type: str = "image/jpeg"
) -> UploadFile:
    headers = Headers({"content-type": content_type})
    return UploadFile(file=io.BytesIO(data), filename=filename, headers=headers)


@pytest.fixture
def upload_dir(monkeypatch, tmp_path):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    return tmp_path


async def test_save_upload_valid_jpeg(upload_dir):
    stored_path, size_bytes, content_type = await image_service.save_upload(make_upload(JPEG_BYTES))

    assert stored_path.exists()
    assert stored_path.read_bytes() == JPEG_BYTES
    assert size_bytes == len(JPEG_BYTES)
    assert content_type == "image/jpeg"
    assert stored_path.parent == upload_dir


async def test_save_upload_valid_png(upload_dir):
    stored_path, size_bytes, content_type = await image_service.save_upload(
        make_upload(PNG_BYTES, filename="scan.png", content_type="image/png")
    )

    assert stored_path.exists()
    assert size_bytes == len(PNG_BYTES)
    assert content_type == "image/png"


async def test_empty_file_rejected(upload_dir):
    with pytest.raises(HTTPException) as exc_info:
        await image_service.save_upload(make_upload(b""))

    assert exc_info.value.status_code == 400


async def test_oversized_file_rejected(upload_dir, monkeypatch):
    monkeypatch.setattr(settings, "MAX_UPLOAD_SIZE_MB", 0)

    with pytest.raises(HTTPException) as exc_info:
        await image_service.save_upload(make_upload(JPEG_BYTES))

    assert exc_info.value.status_code == 413


async def test_disallowed_declared_content_type_rejected(upload_dir):
    with pytest.raises(HTTPException) as exc_info:
        await image_service.save_upload(
            make_upload(JPEG_BYTES, filename="notes.txt", content_type="text/plain")
        )

    assert exc_info.value.status_code == 415


async def test_spoofed_content_type_rejected(upload_dir):
    """Client claims image/jpeg but the bytes are not a real image."""
    fake_image = b"MZ" + b"\x00" * 64

    with pytest.raises(HTTPException) as exc_info:
        await image_service.save_upload(make_upload(fake_image))

    assert exc_info.value.status_code == 415
    assert not list(upload_dir.iterdir())


async def test_octet_stream_allowed_when_flag_set(upload_dir):
    stored_path, size_bytes, content_type = await image_service.save_upload(
        make_upload(JPEG_BYTES, filename="photo", content_type="application/octet-stream"),
        allow_generic_content_type=True,
    )
    assert content_type == "image/jpeg"
    assert stored_path.exists()
    assert size_bytes == len(JPEG_BYTES)
