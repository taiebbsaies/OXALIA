import uuid

from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)
from app.models.user import Role


def test_password_hash_and_verify():
    plain = "StrongPassw0rd!"
    hashed = hash_password(plain)
    assert hashed != plain
    assert verify_password(plain, hashed) is True
    assert verify_password("wrong", hashed) is False


def test_access_token_roundtrip():
    user_id = uuid.uuid4()
    token = create_access_token(user_id, Role.CLINICIAN)
    payload = decode_access_token(token)
    assert payload["sub"] == str(user_id)
    assert payload["role"] == Role.CLINICIAN.value
