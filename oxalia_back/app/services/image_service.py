import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from app.config import settings


def _validate(file: UploadFile, size_bytes: int) -> None:
    if file.content_type not in settings.allowed_content_types_list:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported content type: {file.content_type}",
        )

    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if size_bytes > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds {settings.MAX_UPLOAD_SIZE_MB} MB limit",
        )


async def save_upload(file: UploadFile) -> tuple[Path, int]:
    """Validate and persist an uploaded image to disk.

    Returns (stored_path, size_bytes).
    """
    contents = await file.read()
    size_bytes = len(contents)
    _validate(file, size_bytes)

    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)

    extension = Path(file.filename or "").suffix or ".bin"
    stored_name = f"{uuid.uuid4().hex}{extension}"
    stored_path = upload_dir / stored_name

    stored_path.write_bytes(contents)
    return stored_path, size_bytes
    