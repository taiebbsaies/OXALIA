import uuid

from sqlalchemy import select
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