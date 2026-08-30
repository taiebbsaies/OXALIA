import uuid
from collections.abc import Sequence
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exam import Exam
from app.models.user import Role, User


async def get_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_by_id(db: AsyncSession, user_id: uuid.UUID) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def get_by_phone_number(db: AsyncSession, phone_number: str) -> User | None:
    result = await db.execute(select(User).where(User.phone_number == phone_number))
    return result.scalar_one_or_none()


async def create(db: AsyncSession, user: User) -> User:
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def list_all(
    db: AsyncSession,
    *,
    limit: int = 100,
    offset: int = 0,
) -> Sequence[User]:
    """Newest-first page of every user, for the admin user-management table."""
    result = await db.execute(
        select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
    )
    return result.scalars().all()


async def exam_counts_by_owner(db: AsyncSession) -> dict[uuid.UUID, int]:
    """Exam count per owner, used to annotate the admin user table."""
    result = await db.execute(select(Exam.owner_id, func.count()).group_by(Exam.owner_id))
    return dict(result.all())


async def update_password(db: AsyncSession, user: User, *, hashed_password: str) -> User:
    user.hashed_password = hashed_password
    await db.commit()
    await db.refresh(user)
    return user


async def update_fields(
    db: AsyncSession,
    user: User,
    *,
    role: Role | None = None,
    is_active: bool | None = None,
) -> User:
    if role is not None:
        user.role = role
    if is_active is not None:
        user.is_active = is_active
    await db.commit()
    await db.refresh(user)
    return user


async def update_phone_number(db: AsyncSession, user: User, phone_number: str | None) -> User:
    user.phone_number = phone_number
    await db.commit()
    await db.refresh(user)
    return user


async def delete(db: AsyncSession, user: User) -> None:
    await db.delete(user)
    await db.commit()


async def count_total(db: AsyncSession) -> int:
    result = await db.execute(select(func.count()).select_from(User))
    return result.scalar_one()


async def count_by_role(db: AsyncSession) -> dict[Role, int]:
    result = await db.execute(select(User.role, func.count()).group_by(User.role))
    counts = {role: 0 for role in Role}
    counts.update(result.all())
    return counts


async def count_active(db: AsyncSession) -> int:
    result = await db.execute(
        select(func.count()).select_from(User).where(User.is_active.is_(True))
    )
    return result.scalar_one()


async def count_created_since(db: AsyncSession, since: datetime) -> int:
    result = await db.execute(
        select(func.count()).select_from(User).where(User.created_at >= since)
    )
    return result.scalar_one()


async def signups_per_day(db: AsyncSession, since: datetime) -> dict[str, int]:
    """Daily signup counts from [since] to now, for the growth chart."""
    day = func.date(User.created_at)
    result = await db.execute(
        select(day, func.count()).where(User.created_at >= since).group_by(day).order_by(day)
    )
    return {str(d): c for d, c in result.all()}
