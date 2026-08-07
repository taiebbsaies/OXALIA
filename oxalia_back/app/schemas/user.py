import re
import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import Role

_PASSWORD_POLICY = re.compile(
    r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,128}$"
)


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


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: Role
    is_active: bool
    created_at: datetime
