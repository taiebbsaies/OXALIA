from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import (
    create_access_token,
    generate_refresh_token,
    hash_password,
    hash_token,
    refresh_token_expiry,
    verify_password,
)
from app.models.refresh_token import RefreshToken
from app.models.user import Role, User
from app.repositories import refresh_token_repository, user_repository
from app.schemas.auth import TokenPair
from app.schemas.user import UserCreate


async def register(db: AsyncSession, data: UserCreate) -> User:
    existing = await user_repository.get_by_email(db, data.email)
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    user = User(
        email=data.email,
        hashed_password=hash_password(data.password),
        full_name=data.full_name,
        role=Role.CLINICIAN,
    )
    return await user_repository.create(db, user)


async def authenticate(db: AsyncSession, email: str, password: str) -> User:
    user = await user_repository.get_by_email(db, email)
    if user is None or not verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password"
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user")
    return user


async def issue_token_pair(db: AsyncSession, user: User) -> TokenPair:
    access_token = create_access_token(user.id, user.role)
    raw_refresh_token = generate_refresh_token()

    refresh_token = RefreshToken(
        user_id=user.id,
        token_hash=hash_token(raw_refresh_token),
        expires_at=refresh_token_expiry(),
    )
    await refresh_token_repository.create(db, refresh_token)

    return TokenPair(access_token=access_token, refresh_token=raw_refresh_token)


async def refresh_token_pair(db: AsyncSession, raw_refresh_token: str) -> TokenPair:
    token_hash = hash_token(raw_refresh_token)
    stored_token = await refresh_token_repository.get_valid_by_hash(db, token_hash)
    if stored_token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token"
        )

    user = await user_repository.get_by_id(db, stored_token.user_id)
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    await refresh_token_repository.revoke(db, stored_token)
    return await issue_token_pair(db, user)


async def logout(db: AsyncSession, raw_refresh_token: str) -> None:
    token_hash = hash_token(raw_refresh_token)
    stored_token = await refresh_token_repository.get_valid_by_hash(db, token_hash)
    if stored_token is not None:
        await refresh_token_repository.revoke(db, stored_token)
