import uuid
from pathlib import Path

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    Form,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, require_ingest_api_key
from app.database import get_db
from app.models.exam import Exam, ExamStatus
from app.models.user import User
from app.repositories import exam_repository, inference_result_repository, user_repository
from app.schemas.exam import ExamOut, ExamStatsOut, InferenceResultOut
from app.services import image_service
from app.services.inference_orchestrator import run_inference
from app.services.patient_naming import filename_from_patient_name, normalize_patient_name
from app.services.phone_number import is_valid_phone_number, normalize_phone_number

router = APIRouter()


async def _create_exam_from_upload(
    *,
    db: AsyncSession,
    background_tasks: BackgroundTasks,
    file: UploadFile,
    patient_name: str,
    owner: User,
    allow_generic_content_type: bool = False,
) -> ExamOut:
    cleaned_name = normalize_patient_name(patient_name)
    if not cleaned_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Patient name is required",
        )

    stored_path, size_bytes, content_type = await image_service.save_upload(
        file, allow_generic_content_type=allow_generic_content_type
    )

    exam = Exam(
        owner_id=owner.id,
        patient_name=cleaned_name,
        original_filename=filename_from_patient_name(cleaned_name),
        storage_path=str(stored_path),
        content_type=content_type,
        size_bytes=size_bytes,
    )
    exam = await exam_repository.create(db, exam)
    background_tasks.add_task(run_inference, exam.id, stored_path)
    return ExamOut.model_validate(exam)


@router.post(
    "/upload",
    response_model=ExamOut,
    status_code=status.HTTP_201_CREATED,
    summary="Upload an X-ray image for analysis",
    description=(
        "Validates and stores the uploaded image, then schedules asynchronous "
        "inference in the background. Poll GET /exams/{id}/result for the outcome. "
        "Requires a patient_name form field used as the exam display name."
    ),
)
async def upload_exam(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    patient_name: str = Form(..., min_length=1, max_length=255),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ExamOut:
    return await _create_exam_from_upload(
        db=db,
        background_tasks=background_tasks,
        file=file,
        patient_name=patient_name,
        owner=current_user,
    )


@router.post(
    "/ingest",
    response_model=ExamOut,
    status_code=status.HTTP_201_CREATED,
    summary="Ingest an X-ray from n8n / WhatsApp",
    description=(
        "Server-to-server upload. Authenticate with `X-Ingest-Key` (not a doctor password). "
        "Looks up the clinician by `phone_number` (WhatsApp sender) and stores the exam "
        "under that owner. Use the WhatsApp caption as `patient_name`."
    ),
    dependencies=[Depends(require_ingest_api_key)],
)
async def ingest_exam(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    patient_name: str = Form(..., min_length=1, max_length=255),
    phone_number: str = Form(..., min_length=8, max_length=20),
    db: AsyncSession = Depends(get_db),
) -> ExamOut:
    phone = normalize_phone_number(phone_number)
    if not is_valid_phone_number(phone):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="phone_number must be an international number with country code",
        )

    owner = await user_repository.get_by_phone_number(db, phone)
    if owner is None or not owner.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No OXALIA account is linked to this WhatsApp number",
        )

    return await _create_exam_from_upload(
        db=db,
        background_tasks=background_tasks,
        file=file,
        patient_name=patient_name,
        owner=owner,
        allow_generic_content_type=True,
    )


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
    exams = await exam_repository.list_by_owner(db, current_user.id, limit=limit, offset=offset)
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
    model_versions = await inference_result_repository.model_version_counts(db, current_user.id)
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
