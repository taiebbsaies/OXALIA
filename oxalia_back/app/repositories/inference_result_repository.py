import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exam import Exam
from app.models.inference_result import InferenceResult


async def create(db: AsyncSession, result: InferenceResult) -> InferenceResult:
    db.add(result)
    await db.commit()
    await db.refresh(result)
    return result


async def get_by_exam_id(db: AsyncSession, exam_id: uuid.UUID) -> InferenceResult | None:
    result = await db.execute(select(InferenceResult).where(InferenceResult.exam_id == exam_id))
    return result.scalar_one_or_none()


async def model_version_counts(db: AsyncSession, owner_id: uuid.UUID) -> dict[str, int]:
    """How many of the user's analyses ran on each model version."""
    result = await db.execute(
        select(InferenceResult.model_version, func.count())
        .join(Exam, Exam.id == InferenceResult.exam_id)
        .where(Exam.owner_id == owner_id)
        .group_by(InferenceResult.model_version)
    )
    return dict(result.all())


async def model_version_counts_all(db: AsyncSession) -> dict[str, int]:
    """How many analyses ran on each model version, across every user."""
    result = await db.execute(
        select(InferenceResult.model_version, func.count()).group_by(InferenceResult.model_version)
    )
    return dict(result.all())


async def avg_processing_seconds_all(db: AsyncSession) -> float | None:
    """Average time between exam upload and completed inference, in seconds."""
    delta_seconds = func.extract("epoch", InferenceResult.created_at - Exam.created_at)
    result = await db.execute(
        select(func.avg(delta_seconds)).join(Exam, Exam.id == InferenceResult.exam_id)
    )
    avg_seconds = result.scalar_one_or_none()
    return float(avg_seconds) if avg_seconds is not None else None
