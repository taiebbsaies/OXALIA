from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import LoginRequest, RefreshRequest, TokenPair
from app.schemas.user import UserCreate, UserOut
from app.services import auth_service

router = APIRouter()


@router.post(
    "/register",
    response_model=UserOut,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new clinician account",
    description=(
        "Creates a new user account with the `clinician` role. Admin accounts cannot be "
        "created through this public endpoint."
    ),
    responses={
        status.HTTP_409_CONFLICT: {"description": "Email is already registered"},
        status.HTTP_422_UNPROCESSABLE_CONTENT: {"description": "Validation error"},
    },
)
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)) -> UserOut:
    user = await auth_service.register(db, data)
    return UserOut.model_validate(user)


@router.post(
    "/login",
    response_model=TokenPair,
    summary="Authenticate and obtain a token pair",
    description=(
        "Verifies email/password credentials and returns a short-lived JWT access token "
        "together with a long-lived, revocable refresh token."
    ),
    responses={
        status.HTTP_401_UNAUTHORIZED: {"description": "Invalid email or password"},
        status.HTTP_403_FORBIDDEN: {"description": "Account is inactive"},
    },
)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)) -> TokenPair:
    user = await auth_service.authenticate(db, data.email, data.password)
    return await auth_service.issue_token_pair(db, user)


@router.post(
    "/refresh",
    response_model=TokenPair,
    summary="Exchange a refresh token for a new token pair",
    description=(
        "Validates the supplied refresh token, revokes it, and issues a brand new "
        "access/refresh token pair (rotation). Reusing an already-rotated or expired "
        "refresh token is rejected."
    ),
    responses={
        status.HTTP_401_UNAUTHORIZED: {"description": "Refresh token is invalid, expired, or revoked"},
    },
)
async def refresh(data: RefreshRequest, db: AsyncSession = Depends(get_db)) -> TokenPair:
    return await auth_service.refresh_token_pair(db, data.refresh_token)


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revoke a refresh token",
    description=(
        "Revokes the supplied refresh token so it can no longer be used to obtain new "
        "access tokens. The current access token remains valid until it naturally expires."
    ),
)
async def logout(data: RefreshRequest, db: AsyncSession = Depends(get_db)) -> None:
    await auth_service.logout(db, data.refresh_token)
