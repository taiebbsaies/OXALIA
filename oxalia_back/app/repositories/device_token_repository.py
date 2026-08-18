import uuid

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device_token import DeviceToken


async def upsert(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    token: str,
    platform: str,
) -> DeviceToken:
    """Attach a token to the user. If the token already exists (even for
    another user — e.g. logout/login on the same device), reassign it.
    """
    result = await db.execute(select(DeviceToken).where(DeviceToken.token == token))
    existing = result.scalar_one_or_none()
    if existing is not None:
        existing.user_id = user_id
        existing.platform = platform
        await db.commit()
        await db.refresh(existing)
        return existing

    device = DeviceToken(user_id=user_id, token=token, platform=platform)
    db.add(device)
    await db.commit()
    await db.refresh(device)
    return device


async def list_tokens_for_user(db: AsyncSession, user_id: uuid.UUID) -> list[str]:
    result = await db.execute(select(DeviceToken.token).where(DeviceToken.user_id == user_id))
    return list(result.scalars().all())


async def delete_token(db: AsyncSession, user_id: uuid.UUID, token: str) -> None:
    await db.execute(
        delete(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.token == token,
        )
    )
    await db.commit()


async def delete_tokens(db: AsyncSession, tokens: list[str]) -> None:
    if not tokens:
        return
    await db.execute(delete(DeviceToken).where(DeviceToken.token.in_(tokens)))
    await db.commit()
