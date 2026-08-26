from pathlib import Path
from typing import Any

import httpx

from app.config import settings
from app.core.model_adapter import ModelAdapter


def _parse_response(payload: Any, *, model_version: str, image_path: Path) -> dict[str, Any]:
    """Normalize the external service's response into our stable result shape.

    If the real AI service returns a different schema, only this function
    needs to change — routers, repositories, and the mobile app all treat
    `result_json` as an opaque dict, so nothing else is affected.
    """
    findings = payload.get("findings", []) if isinstance(payload, dict) else []
    normalized_findings = [
        {
            "label": str(item.get("label", "Unknown")),
            "probability": float(item.get("probability", 0.0)),
        }
        for item in findings
        if isinstance(item, dict)
    ]

    return {
        "model_version": model_version,
        "findings": normalized_findings,
        "processed_file": image_path.name,
    }


class HttpModelAdapter(ModelAdapter):
    """Calls an external AI inference service over HTTP.

    Configured entirely through environment variables (`AI_SERVICE_URL`,
    `AI_SERVICE_API_KEY`, `AI_SERVICE_TIMEOUT_SECONDS`) so the underlying
    service can be swapped without touching code — only `_parse_response`
    needs to change if the response schema differs.
    """

    @property
    def model_version(self) -> str:
        return settings.AI_SERVICE_MODEL or "http-external-0.1.0"

    async def predict(self, image_path: Path) -> dict[str, Any]:
        if not settings.AI_SERVICE_URL:
            raise RuntimeError(
                "AI_SERVICE_URL is not configured; cannot call the external AI service"
            )

        headers = {}
        if settings.AI_SERVICE_API_KEY:
            headers["Authorization"] = f"Bearer {settings.AI_SERVICE_API_KEY}"

        async with httpx.AsyncClient(timeout=settings.AI_SERVICE_TIMEOUT_SECONDS) as client:
            with image_path.open("rb") as image_file:
                files = {"file": (image_path.name, image_file, "application/octet-stream")}
                response = await client.post(settings.AI_SERVICE_URL, headers=headers, files=files)
            response.raise_for_status()
            payload = response.json()

        return _parse_response(payload, model_version=self.model_version, image_path=image_path)
