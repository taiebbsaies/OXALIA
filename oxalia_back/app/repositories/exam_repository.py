import uuid
from collections.abc import Sequence
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exam import Exam, ExamStatus


async def create(db: AsyncSession, exam: Exam) -> Exam:
    db.add(exam)
    await db.commit()
    await db.refresh(exam)
    return exam


async def get_by_id(db: AsyncSession, exam_id: uuid.UUID) -> Exam | None:
    result = await db.execute(select(Exam).where(Exam.id == exam_id))
    return result.scalar_one_or_none()


async def update_status(db: AsyncSession, exam: Exam, status: ExamStatus) -> Exam:
    exam.status = status
    await db.commit()
    await db.refresh(exam)
    return exam


async def list_by_owner(
    db: AsyncSession,
    owner_id: uuid.UUID,
    *,
    limit: int = 50,
    offset: int = 0,
) -> Sequence[Exam]:
    """Newest-first page of a user's exams for the History tab."""
    result = await db.execute(
        select(Exam)
        .where(Exam.owner_id == owner_id)
        .order_by(Exam.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


async def stats_by_owner(db: AsyncSession, owner_id: uuid.UUID) -> dict[ExamStatus, int]:
    """Per-status exam counts for the Home dashboard."""
    result = await db.execute(
        select(Exam.status, func.count()).where(Exam.owner_id == owner_id).group_by(Exam.status)
    )
    counts = {status: 0 for status in ExamStatus}
    counts.update(result.all())
    return counts


async def stats_all(db: AsyncSession) -> dict[ExamStatus, int]:
    """Per-status exam counts across every user, for the admin dashboard."""
    result = await db.execute(select(Exam.status, func.count()).group_by(Exam.status))
    counts = {status: 0 for status in ExamStatus}
    counts.update(result.all())
    return counts


async def count_created_since(db: AsyncSession, since: datetime) -> int:
    result = await db.execute(
        select(func.count()).select_from(Exam).where(Exam.created_at >= since)
    )
    return result.scalar_one()


async def volume_per_day(db: AsyncSession, since: datetime) -> dict[str, int]:
    """Daily exam-upload counts from [since] to now, for the volume chart."""
    day = func.date(Exam.created_at)
    result = await db.execute(
        select(day, func.count()).where(Exam.created_at >= since).group_by(day).order_by(day)
    )
    return {str(d): c for d, c in result.all()}
