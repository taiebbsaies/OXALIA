from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, require_role
from app.database import get_db
from app.models.user import Role, User
from app.schemas.auth import LoginRequest, RefreshRequest, TokenPair
from app.schemas.user import ChangePasswordRequest, LinkPhoneRequest, UserCreate, UserOut
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
        status.HTTP_401_UNAUTHORIZED: {
            "description": "Refresh token is invalid, expired, or revoked"
        },
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


@router.get(
    "/me",
    response_model=UserOut,
    summary="Get the current authenticated user",
    description=(
        "Returns the profile of the user identified by the supplied bearer access token. "
        "Requires a valid `Authorization: Bearer <access_token>` header."
    ),
    responses={
        status.HTTP_401_UNAUTHORIZED: {"description": "Missing, invalid or expired access token"},
    },
)
async def get_me(current_user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(current_user)


@router.patch(
    "/me/password",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Change the current user's password",
    description=(
        "Verifies the supplied `old_password` against the stored hash, then replaces it "
        "with `new_password` (subject to the same strength policy as registration). "
        "Requires a valid `Authorization: Bearer <access_token>` header."
    ),
    responses={
        status.HTTP_400_BAD_REQUEST: {
            "description": (
                "Current password is incorrect, or new password is the same as the old one"
            )
        },
        status.HTTP_401_UNAUTHORIZED: {"description": "Missing, invalid or expired access token"},
        status.HTTP_422_UNPROCESSABLE_CONTENT: {
            "description": "Validation error (password policy)"
        },
    },
)
async def change_password(
    data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    await auth_service.change_password(db, current_user, data)


@router.patch(
    "/me/phone",
    response_model=UserOut,
    summary="Link or unlink a WhatsApp phone number",
    description=(
        "Stores the clinician's international phone number (digits with country code). "
        "n8n uses WhatsApp's sender number to attribute ingested X-rays. "
        "Send `phone_number: null` or an empty string to unlink."
    ),
)
async def link_phone(
    data: LinkPhoneRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserOut:
    user = await auth_service.link_phone(db, current_user, data)
    return UserOut.model_validate(user)


@router.get(
    "/admin-check",
    response_model=UserOut,
    summary="Example admin-only endpoint (RBAC demo)",
    description=(
        "Demonstrates role-based access control: only users with the `admin` role may "
        "access this endpoint. Intended as a template for future admin-only routes."
    ),
    responses={
        status.HTTP_401_UNAUTHORIZED: {"description": "Missing, invalid or expired access token"},
        status.HTTP_403_FORBIDDEN: {"description": "Authenticated user is not an admin"},
    },
)
async def admin_check(
    current_user: User = Depends(require_role(Role.ADMIN)),
) -> UserOut:
    return UserOut.model_validate(current_user)
