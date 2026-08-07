import pytest
from pydantic import ValidationError

from app.schemas.user import UserCreate


def test_user_create_accepts_strong_password():
    user = UserCreate(
        email="doc@oxalia.health",
        password="StrongPassw0rd!",
        full_name="Dr Test",
    )
    assert user.password == "StrongPassw0rd!"


@pytest.mark.parametrize(
    "password",
    [
        "short1!",  # too short
        "alllowercase1!",  # no uppercase
        "ALLUPPERCASE1!",  # no lowercase
        "NoNumberHere!",  # no digit
        "NoSpecial123",  # no special
    ],
)
def test_user_create_rejects_weak_password(password):
    with pytest.raises(ValidationError):
        UserCreate(
            email="doc@oxalia.health",
            password=password,
            full_name="Dr Test",
        )
