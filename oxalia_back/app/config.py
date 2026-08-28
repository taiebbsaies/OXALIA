from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings, loaded from environment variables / .env file."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Database
    DATABASE_URL: str

    # JWT
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_EXPIRE_MINUTES: int

    # App
    PROJECT_NAME: str
    ENVIRONMENT: str
    # Uploads
    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_SIZE_MB: int = 10
    ALLOWED_CONTENT_TYPES: str = "image/jpeg,image/png"

    # Firebase Cloud Messaging (optional — push is a no-op if unset)
    FIREBASE_CREDENTIALS_PATH: str = ""

    # AI inference: toggle between the placeholder stub and a real external
    # AI service without touching code — flip USE_STUB_MODEL once the
    # service is configured.
    USE_STUB_MODEL: bool = True
    AI_SERVICE_URL: str = ""
    AI_SERVICE_API_KEY: str = ""
    AI_SERVICE_MODEL: str = "densenet121-res224-all"
    AI_SERVICE_TIMEOUT_SECONDS: int = 120

    # n8n / Telegram ingest (server-to-server). Leave empty to disable ingest.
    INGEST_API_KEY: str = ""

    @property
    def allowed_content_types_list(self) -> list[str]:
        return [t.strip() for t in self.ALLOWED_CONTENT_TYPES.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
