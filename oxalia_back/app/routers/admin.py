import uuid
from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import require_role
from app.database import get_db
from app.models.exam import ExamStatus
from app.models.user import Role, User
from app.repositories import exam_repository, inference_result_repository, user_repository
from app.schemas.admin import (
    AdminStatsOut,
    AdminUserOut,
    AdminUserUpdate,
    ExamVolumePoint,
    UserGrowthPoint,
)

router = APIRouter(dependencies=[Depends(require_role(Role.ADMIN))])

_TREND_WINDOW_DAYS = 14


@router.get(
    "/stats",
    response_model=AdminStatsOut,
    summary="Platform-wide statistics for the admin dashboard",
)
async def get_admin_stats(db: AsyncSession = Depends(get_db)) -> AdminStatsOut:
    now = datetime.now(UTC)
    since_7d = now - timedelta(days=7)
    since_30d = now - timedelta(days=30)
    since_trend = now - timedelta(days=_TREND_WINDOW_DAYS)

    total_users = await user_repository.count_total(db)
    active_users = await user_repository.count_active(db)
    role_counts = await user_repository.count_by_role(db)
    new_users_7d = await user_repository.count_created_since(db, since_7d)
    new_users_30d = await user_repository.count_created_since(db, since_30d)
    user_growth_raw = await user_repository.signups_per_day(db, since_trend)

    exam_counts = await exam_repository.stats_all(db)
    new_exams_7d = await exam_repository.count_created_since(db, since_7d)
    new_exams_30d = await exam_repository.count_created_since(db, since_30d)
    exam_volume_raw = await exam_repository.volume_per_day(db, since_trend)

    model_versions = await inference_result_repository.model_version_counts_all(db)
    avg_processing_seconds = await inference_result_repository.avg_processing_seconds_all(db)

    completed = exam_counts[ExamStatus.COMPLETED]
    failed = exam_counts[ExamStatus.FAILED]
    resolved = completed + failed
    failure_rate_pct = round((failed / resolved) * 100, 2) if resolved else 0.0

    return AdminStatsOut(
        total_users=total_users,
        active_users=active_users,
        inactive_users=total_users - active_users,
        admin_count=role_counts[Role.ADMIN],
        clinician_count=role_counts[Role.CLINICIAN],
        new_users_7d=new_users_7d,
        new_users_30d=new_users_30d,
        total_exams=sum(exam_counts.values()),
        completed_exams=completed,
        processing_exams=exam_counts[ExamStatus.PROCESSING],
        failed_exams=failed,
        pending_exams=exam_counts[ExamStatus.PENDING],
        new_exams_7d=new_exams_7d,
        new_exams_30d=new_exams_30d,
        failure_rate_pct=failure_rate_pct,
        model_versions=model_versions,
        avg_processing_seconds=avg_processing_seconds,
        user_growth=[
            UserGrowthPoint(date=day, count=count) for day, count in sorted(user_growth_raw.items())
        ],
        exam_volume=[
            ExamVolumePoint(date=day, count=count) for day, count in sorted(exam_volume_raw.items())
        ],
    )


@router.get(
    "/users",
    response_model=list[AdminUserOut],
    summary="List every user, newest first",
)
async def list_users(
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[AdminUserOut]:
    users = await user_repository.list_all(db, limit=limit, offset=offset)
    exam_counts = await user_repository.exam_counts_by_owner(db)
    return [_to_admin_user_out(u, exam_counts) for u in users]


@router.patch(
    "/users/{user_id}",
    response_model=AdminUserOut,
    summary="Update a user's role and/or active status",
    responses={
        status.HTTP_404_NOT_FOUND: {"description": "User not found"},
        status.HTTP_400_BAD_REQUEST: {"description": "Would remove the last active admin"},
    },
)
async def update_user(
    user_id: uuid.UUID,
    data: AdminUserUpdate,
    current_user: User = Depends(require_role(Role.ADMIN)),
    db: AsyncSession = Depends(get_db),
) -> AdminUserOut:
    user = await user_repository.get_by_id(db, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    demoting_or_deactivating_admin = user.role == Role.ADMIN and (
        data.role == Role.CLINICIAN or data.is_active is False
    )
    if demoting_or_deactivating_admin and await _is_last_active_admin(db, user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot remove the last active admin",
        )

    updated = await user_repository.update_fields(
        db, user, role=data.role, is_active=data.is_active
    )
    exam_counts = await user_repository.exam_counts_by_owner(db)
    return _to_admin_user_out(updated, exam_counts)


@router.delete(
    "/users/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a user account",
    responses={
        status.HTTP_404_NOT_FOUND: {"description": "User not found"},
        status.HTTP_400_BAD_REQUEST: {
            "description": "Self-deletion, or deleting the last active admin"
        },
    },
)
async def delete_user(
    user_id: uuid.UUID,
    current_user: User = Depends(require_role(Role.ADMIN)),
    db: AsyncSession = Depends(get_db),
) -> None:
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own account",
        )

    user = await user_repository.get_by_id(db, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.role == Role.ADMIN and await _is_last_active_admin(db, user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete the last active admin",
        )

    await user_repository.delete(db, user)


async def _is_last_active_admin(db: AsyncSession, user: User) -> bool:
    role_counts = await user_repository.count_by_role(db)
    return user.is_active and role_counts[Role.ADMIN] <= 1


def _to_admin_user_out(user: User, exam_counts: dict[uuid.UUID, int]) -> AdminUserOut:
    return AdminUserOut(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        is_active=user.is_active,
        created_at=user.created_at,
        exam_count=exam_counts.get(user.id, 0),
    )
