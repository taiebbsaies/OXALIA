import pytest
from pydantic import ValidationError

from app.schemas.user import LinkPhoneRequest, UserCreate
from app.services.phone_number import normalize_phone_number


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


def test_link_phone_normalizes_international():
    assert LinkPhoneRequest(phone_number="+216 12 345 678").phone_number == "21612345678"
    assert LinkPhoneRequest(phone_number="").phone_number is None


def test_link_phone_rejects_invalid():
    with pytest.raises(ValidationError):
        LinkPhoneRequest(phone_number="not-a-phone")


def test_normalize_phone_strips_00_prefix():
    assert normalize_phone_number("0021612345678") == "21612345678"
