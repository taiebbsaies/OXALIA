API_DESCRIPTION = """
Backend API for the **OXALIA Mobile Inference Platform** — a mobile-ready infrastructure for
deploying AI-assisted medical imaging analysis (X-ray triage) to clinicians in the field.

This API is built around a swappable inference contract: the mobile app, authentication, and
orchestration layers are fully decoupled from the underlying AI model, so the placeholder model
used today can be replaced by the final OXALIA 2D model with no changes to this API surface.

### Authentication

Most endpoints require a JWT **access token** obtained via `/auth/login`. Pass it as:

```
Authorization: Bearer <access_token>
```

Access tokens are short-lived. Use `/auth/refresh` with a valid **refresh token** to obtain a new
token pair without requiring the user to log in again.
"""

TAGS_METADATA = [
    {
        "name": "auth",
        "description": "Account registration, login, token refresh and logout. "
        "Implements JWT access tokens with rotating, revocable refresh tokens.",
    },
    {
        "name": "system",
        "description": (
            "Operational endpoints (health checks) used by orchestration and monitoring."
        ),
    },
]
