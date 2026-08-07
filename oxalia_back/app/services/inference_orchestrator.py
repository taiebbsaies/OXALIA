from pathlib import Path
from uuid import UUID

from app.core.stub_model_adapter import StubModelAdapter
from app.database import AsyncSessionLocal
from app.models.exam import ExamStatus
from app.models.inference_result import InferenceResult
from app.repositories import device_token_repository, exam_repository, inference_result_repository
from app.services import fcm_service

# Swap this single line later to plug in the real OXALIA 2D adapter.
model_adapter = StubModelAdapter()


async def _notify_exam_owner(
    db,
    *,
    owner_id: UUID,
    exam_id: UUID,
    patient_name: str,
    success: bool,
) -> None:
    tokens = await device_token_repository.list_tokens_for_user(db, owner_id)
    if not tokens:
        return

    if success:
        title = "Analysis ready"
        body = f"Results for {patient_name} are ready to review."
        status = "completed"
    else:
        title = "Analysis failed"
        body = f"Analysis for {patient_name} could not be completed."
        status = "failed"

    stale = fcm_service.send_to_tokens(
        tokens,
        title=title,
        body=body,
        data={
            "exam_id": str(exam_id),
            "type": "exam_status",
            "status": status,
        },
    )
    if stale:
        await device_token_repository.delete_tokens(db, stale)


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
            await _notify_exam_owner(
                db,
                owner_id=exam.owner_id,
                exam_id=exam.id,
                patient_name=exam.patient_name,
                success=True,
            )
        except Exception:
            await exam_repository.update_status(db, exam, ExamStatus.FAILED)
            await _notify_exam_owner(
                db,
                owner_id=exam.owner_id,
                exam_id=exam.id,
                patient_name=exam.patient_name,
                success=False,
            )
            raise
