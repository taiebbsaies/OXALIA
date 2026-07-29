import uuid

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.database import get_db
from app.models.exam import Exam, ExamStatus
from app.models.user import User
from app.repositories import exam_repository, inference_result_repository
from app.schemas.exam import ExamOut, InferenceResultOut
from app.services import image_service
from app.services.inference_orchestrator import run_inference

router = APIRouter()


@router.post(
    "/upload",
    response_model=ExamOut,
    status_code=status.HTTP_201_CREATED,
    summary="Upload an X-ray image for analysis",
    description=(
        "Validates and stores the uploaded image, then schedules asynchronous "
        "inference in the background. Poll GET /exams/{id}/result for the outcome."
    ),
)
async def upload_exam(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ExamOut:
    stored_path, size_bytes = await image_service.save_upload(file)

    exam = Exam(
        owner_id=current_user.id,
        original_filename=file.filename or "unknown",
        storage_path=str(stored_path),
        content_type=file.content_type or "application/octet-stream",
        size_bytes=size_bytes,
    )
    exam = await exam_repository.create(db, exam)

    background_tasks.add_task(run_inference, exam.id, stored_path)

    return ExamOut.model_validate(exam)


@router.get("/{exam_id}", response_model=ExamOut, summary="Get exam status")
async def get_exam(
    exam_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ExamOut:
    exam = await exam_repository.get_by_id(db, uuid.UUID(exam_id))
    if exam is None or exam.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exam not found")
    return ExamOut.model_validate(exam)


@router.get(
    "/{exam_id}/result",
    response_model=InferenceResultOut,
    summary="Get inference result for an exam",
    responses={status.HTTP_404_NOT_FOUND: {"description": "Exam or result not found"}},
)
async def get_exam_result(
    exam_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> InferenceResultOut:
    exam = await exam_repository.get_by_id(db, uuid.UUID(exam_id))
    if exam is None or exam.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exam not found")

    if exam.status == ExamStatus.FAILED:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Inference failed for this exam",
        )

    result = await inference_result_repository.get_by_exam_id(db, exam.id)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Result not ready yet"
        )
    return InferenceResultOut.model_validate(result)