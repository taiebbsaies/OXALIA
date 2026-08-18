from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user
from app.database import get_db
from app.models.user import User
from app.repositories import device_token_repository
from app.schemas.device import DeviceTokenIn, DeviceTokenOut

router = APIRouter()


@router.post(
    "/fcm-token",
    response_model=DeviceTokenOut,
    summary="Register this device for push notifications",
)
async def register_fcm_token(
    body: DeviceTokenIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DeviceTokenOut:
    await device_token_repository.upsert(
        db,
        user_id=current_user.id,
        token=body.token.strip(),
        platform=body.platform.strip().lower(),
    )
    return DeviceTokenOut()


@router.delete(
    "/fcm-token",
    response_model=DeviceTokenOut,
    summary="Unregister this device from push notifications",
)
async def unregister_fcm_token(
    body: DeviceTokenIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> DeviceTokenOut:
    await device_token_repository.delete_token(db, current_user.id, body.token.strip())
    return DeviceTokenOut(status="unregistered")
