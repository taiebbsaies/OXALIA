import re
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import Role
from app.services.phone_number import is_valid_phone_number, normalize_phone_number

_PASSWORD_POLICY = re.compile(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,128}$")


class UserCreate(BaseModel):
    email: EmailStr = Field(examples=["clinician@oxalia.health"])
    password: str = Field(min_length=8, max_length=128, examples=["StrongPassw0rd!"])
    full_name: str = Field(min_length=1, max_length=255, examples=["Dr. Jane Doe"])

    @field_validator("password")
    @classmethod
    def password_must_meet_policy(cls, value: str) -> str:
        if not _PASSWORD_POLICY.match(value):
            raise ValueError(
                "Password must be at least 8 characters and include uppercase, "
                "lowercase, a number, and a special character"
            )
        return value


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(examples=["OldPassw0rd!"])
    new_password: str = Field(min_length=8, max_length=128, examples=["NewPassw0rd!"])

    @field_validator("new_password")
    @classmethod
    def new_password_must_meet_policy(cls, value: str) -> str:
        if not _PASSWORD_POLICY.match(value):
            raise ValueError(
                "Password must be at least 8 characters and include uppercase, "
                "lowercase, a number, and a special character"
            )
        return value


class LinkPhoneRequest(BaseModel):
    """WhatsApp number in international form. Empty string unlinks."""

    phone_number: str | None = Field(
        default=None,
        max_length=20,
        examples=["+21612345678"],
    )

    @field_validator("phone_number")
    @classmethod
    def phone_must_be_international(cls, value: str | None) -> str | None:
        if value is None:
            return None
        stripped = value.strip()
        if stripped == "":
            return None
        digits = normalize_phone_number(stripped)
        if not is_valid_phone_number(digits):
            raise ValueError(
                "Phone must be an international number with country code "
                "(8-15 digits, e.g. +21612345678)"
            )
        return digits


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: Role
    is_active: bool
    created_at: datetime
    phone_number: str | None = None
