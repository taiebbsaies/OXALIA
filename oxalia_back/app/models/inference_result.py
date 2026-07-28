import uuid

from sqlalchemy import JSON, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.mixins import TimestampMixin, UUIDMixin
from app.database import Base


class InferenceResult(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "inference_results"

    exam_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("exams.id", ondelete="CASCADE"), nullable=False, unique=True
    )
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    result_json: Mapped[dict] = mapped_column(JSON, nullable=False)

    def __repr__(self) -> str:
        return f"<InferenceResult exam_id={self.exam_id} model_version={self.model_version}>"