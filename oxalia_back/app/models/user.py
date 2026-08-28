import enum

from sqlalchemy import Boolean, Enum, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.mixins import TimestampMixin, UUIDMixin
from app.database import Base


class Role(str, enum.Enum):
    CLINICIAN = "clinician"
    ADMIN = "admin"


class User(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[Role] = mapped_column(
        Enum(Role, name="user_role", native_enum=False), nullable=False, default=Role.CLINICIAN
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    telegram_user_id: Mapped[str | None] = mapped_column(
        String(32), unique=True, index=True, nullable=True
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r} role={self.role}>"
