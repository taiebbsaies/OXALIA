import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from app.config import settings

_MAGIC_BYTES: dict[bytes, str] = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
}


def _detect_real_content_type(contents: bytes) -> str | None:
    """Inspect the file's magic bytes instead of trusting the client-declared type."""
    for signature, content_type in _MAGIC_BYTES.items():
        if contents.startswith(signature):
            return content_type
    return None


def _validate(file: UploadFile, contents: bytes) -> None:
    size_bytes = len(contents)

    if size_bytes == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty",
        )

    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if size_bytes > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail=f"File exceeds {settings.MAX_UPLOAD_SIZE_MB} MB limit",
        )

    if file.content_type not in settings.allowed_content_types_list:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported content type: {file.content_type}",
        )

    real_content_type = _detect_real_content_type(contents)
    if real_content_type is None or real_content_type not in settings.allowed_content_types_list:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="File content does not match an allowed image format",
        )


async def save_upload(file: UploadFile) -> tuple[Path, int]:
    """Validate and persist an uploaded image to disk.

    Returns (stored_path, size_bytes).
    """
    contents = await file.read()
    _validate(file, contents)
    size_bytes = len(contents)

    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)

    extension = Path(file.filename or "").suffix or ".bin"
    stored_name = f"{uuid.uuid4().hex}{extension}"
    stored_path = upload_dir / stored_name

    stored_path.write_bytes(contents)
    return stored_path, size_bytes
