import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.user import Role


class AdminUserOut(BaseModel):
    """User row as shown in the admin user-management table."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    full_name: str
    role: Role
    is_active: bool
    created_at: datetime
    exam_count: int = 0


class AdminUserUpdate(BaseModel):
    """Partial update for a user — role and/or active flag."""

    role: Role | None = None
    is_active: bool | None = None


class UserGrowthPoint(BaseModel):
    """One bucket in the signups-over-time chart."""

    date: str
    count: int


class ExamVolumePoint(BaseModel):
    """One bucket in the exams-over-time chart."""

    date: str
    count: int


class AdminStatsOut(BaseModel):
    """Platform-wide statistics for the admin dashboard."""

    # Users
    total_users: int
    active_users: int
    inactive_users: int
    admin_count: int
    clinician_count: int
    new_users_7d: int
    new_users_30d: int

    # Exams
    total_exams: int
    completed_exams: int
    processing_exams: int
    failed_exams: int
    pending_exams: int
    new_exams_7d: int
    new_exams_30d: int
    failure_rate_pct: float = Field(
        description="Percentage of resolved exams (completed + failed) that failed."
    )

    # Model / performance
    model_versions: dict[str, int]
    avg_processing_seconds: float | None = Field(
        default=None,
        description="Average time between upload and completed inference, in seconds.",
    )

    # Trends (last 14 days, oldest first)
    user_growth: list[UserGrowthPoint]
    exam_volume: list[ExamVolumePoint]
