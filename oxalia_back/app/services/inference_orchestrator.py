from pathlib import Path
from uuid import UUID

from app.core.stub_model_adapter import StubModelAdapter
from app.database import AsyncSessionLocal
from app.models.exam import ExamStatus
from app.models.inference_result import InferenceResult
from app.repositories import exam_repository, inference_result_repository

# Swap this single line later to plug in the real OXALIA 2D adapter.
model_adapter = StubModelAdapter()


async def run_inference(exam_id: UUID, image_path: Path) -> None:
    """Runs in the background after upload. Owns its own DB session since it
    executes outside the request's dependency-injected session lifecycle.
    """
    async with AsyncSessionLocal() as db:
        exam = await exam_repository.get_by_id(db, exam_id)
        if exam is None:
            return

        try:
            await exam_repository.update_status(db, exam, ExamStatus.PROCESSING)
            output = await model_adapter.predict(image_path)

            result = InferenceResult(
                exam_id=exam.id,
                model_version=model_adapter.model_version,
                result_json=output,
            )
            await inference_result_repository.create(db, result)
            await exam_repository.update_status(db, exam, ExamStatus.COMPLETED)
        except Exception:
            await exam_repository.update_status(db, exam, ExamStatus.FAILED)
            raise
