import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import Role


class UserCreate(BaseModel):
    email: EmailStr = Field(examples=["clinician@oxalia.health"])
    password: str = Field(min_length=8, max_length=128, examples=["StrongPassw0rd!"])
    full_name: str = Field(min_length=1, max_length=255, examples=["Dr. Jane Doe"])


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: Role
    is_active: bool
    created_at: datetime
