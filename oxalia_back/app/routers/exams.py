import uuid
from pathlib import Path

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.database import get_db
from app.models.exam import Exam, ExamStatus
from app.models.user import User
from app.repositories import exam_repository, inference_result_repository
from app.schemas.exam import ExamOut, ExamStatsOut, InferenceResultOut
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


@router.get(
    "",
    response_model=list[ExamOut],
    summary="List the current user's exams",
    description="Newest-first paginated history of the caller's exams.",
)
async def list_exams(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[ExamOut]:
    exams = await exam_repository.list_by_owner(
        db, current_user.id, limit=limit, offset=offset
    )
    return [ExamOut.model_validate(exam) for exam in exams]


# Declared before /{exam_id} so the literal path wins over the path parameter.
@router.get(
    "/stats",
    response_model=ExamStatsOut,
    summary="Aggregate exam statistics for the Home dashboard",
)
async def get_exam_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ExamStatsOut:
    counts = await exam_repository.stats_by_owner(db, current_user.id)
    model_versions = await inference_result_repository.model_version_counts(
        db, current_user.id
    )
    in_flight = counts[ExamStatus.PENDING] + counts[ExamStatus.PROCESSING]
    return ExamStatsOut(
        total=sum(counts.values()),
        completed=counts[ExamStatus.COMPLETED],
        processing=in_flight,
        failed=counts[ExamStatus.FAILED],
        model_versions=model_versions,
    )


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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Result not ready yet")
    return InferenceResultOut.model_validate(result)


@router.get(
    "/{exam_id}/image",
    summary="Download the stored exam image",
    response_class=FileResponse,
    responses={status.HTTP_404_NOT_FOUND: {"description": "Exam or file not found"}},
)
async def get_exam_image(
    exam_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FileResponse:
    exam = await exam_repository.get_by_id(db, uuid.UUID(exam_id))
    if exam is None or exam.owner_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exam not found")

    stored_path = Path(exam.storage_path)
    if not stored_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Image file is no longer available",
        )
    return FileResponse(stored_path, media_type=exam.content_type)
