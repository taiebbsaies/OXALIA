import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.models.exam import ExamStatus


class ExamOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    original_filename: str
    content_type: str
    size_bytes: int
    status: ExamStatus
    created_at: datetime


class InferenceResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    exam_id: uuid.UUID
    model_version: str
    result_json: dict
    created_at: datetime
