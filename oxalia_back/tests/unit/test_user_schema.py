import pytest
from pydantic import ValidationError

from app.schemas.user import LinkTelegramRequest, UserCreate


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


def test_link_telegram_accepts_digits():
    assert LinkTelegramRequest(telegram_user_id="123456789").telegram_user_id == "123456789"
    assert LinkTelegramRequest(telegram_user_id="").telegram_user_id is None


def test_link_telegram_rejects_non_digits():
    with pytest.raises(ValidationError):
        LinkTelegramRequest(telegram_user_id="not-an-id")
