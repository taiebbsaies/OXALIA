from pydantic import BaseModel, Field


class DeviceTokenIn(BaseModel):
    token: str = Field(..., min_length=10, max_length=512)
    platform: str = Field(..., min_length=2, max_length=32, examples=["android", "ios"])


class DeviceTokenOut(BaseModel):
    status: str = "registered"
