import uuid

import pytest
from fastapi import HTTPException

from app.schemas.user import UserCreate
from app.services.auth_service import register


@pytest.mark.asyncio
async def test_register_creates_clinician(db):
    email = f"doc_{uuid.uuid4().hex}@test.com"
    data = UserCreate(email=email, password="StrongPassw0rd!", full_name="Dr Test")
    user = await register(db, data)
    assert user.email == email
    assert user.role.value == "clinician"


@pytest.mark.asyncio
async def test_register_duplicate_email_fails(db):
    email = f"doc_{uuid.uuid4().hex}@test.com"
    data = UserCreate(email=email, password="StrongPassw0rd!", full_name="Dr Test")
    await register(db, data)

    with pytest.raises(HTTPException) as exc_info:
        await register(db, data)

    assert exc_info.value.status_code == 409
