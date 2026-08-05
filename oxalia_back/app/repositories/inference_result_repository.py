import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inference_result import InferenceResult


async def create(db: AsyncSession, result: InferenceResult) -> InferenceResult:
    db.add(result)
    await db.commit()
    await db.refresh(result)
    return result


async def get_by_exam_id(db: AsyncSession, exam_id: uuid.UUID) -> InferenceResult | None:
    result = await db.execute(select(InferenceResult).where(InferenceResult.exam_id == exam_id))
    return result.scalar_one_or_none()
