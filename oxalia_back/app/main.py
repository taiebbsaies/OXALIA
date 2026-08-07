from fastapi import FastAPI

from app.config import settings
from app.core.openapi import API_DESCRIPTION, TAGS_METADATA
from app.routers.auth import router as auth_router
from app.routers.devices import router as devices_router
from app.routers.exams import router as exams_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    description=API_DESCRIPTION,
    version="0.1.0",
    contact={"name": "OXALIA Team", "url": "https://github.com"},
    license_info={"name": "Proprietary"},
    openapi_tags=TAGS_METADATA,
    swagger_ui_parameters={
        "persistAuthorization": True,
        "displayRequestDuration": True,
        "filter": True,
        "tryItOutEnabled": True,
    },
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(exams_router, prefix="/exams", tags=["exams"])
app.include_router(devices_router, prefix="/devices", tags=["devices"])


@app.get(
    "/health",
    tags=["system"],
    summary="Liveness check",
    description="Returns 200 if the API process is up. Does not check downstream dependencies "
    "such as the database.",
)
async def health() -> dict[str, str]:
    return {"status": "ok"}
