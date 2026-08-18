"""Unit tests for the HTTP-based external AI service adapter."""

from pathlib import Path

import httpx
import pytest

from app.core.http_model_adapter import HttpModelAdapter
from app.core.http_model_adapter import _parse_response as parse_response


def test_parse_response_normalizes_findings():
    payload = {
        "findings": [
            {"label": "Pneumonia", "probability": 0.87},
            {"label": "No Finding", "probability": "0.12"},
        ]
    }

    result = parse_response(payload, model_version="test-1.0", image_path=Path("scan.jpg"))

    assert result == {
        "model_version": "test-1.0",
        "findings": [
            {"label": "Pneumonia", "probability": 0.87},
            {"label": "No Finding", "probability": 0.12},
        ],
        "processed_file": "scan.jpg",
    }


def test_parse_response_ignores_malformed_payload():
    result = parse_response("not a dict", model_version="test-1.0", image_path=Path("scan.jpg"))

    assert result == {
        "model_version": "test-1.0",
        "findings": [],
        "processed_file": "scan.jpg",
    }


async def test_predict_raises_without_configured_url(monkeypatch, tmp_path):
    monkeypatch.setattr("app.core.http_model_adapter.settings.AI_SERVICE_URL", "")

    image_path = tmp_path / "scan.jpg"
    image_path.write_bytes(b"\xff\xd8\xff\xe0")

    adapter = HttpModelAdapter()
    with pytest.raises(RuntimeError):
        await adapter.predict(image_path)


async def test_predict_calls_external_service_and_normalizes_result(monkeypatch, tmp_path):
    monkeypatch.setattr(
        "app.core.http_model_adapter.settings.AI_SERVICE_URL", "https://ai.example.com/predict"
    )
    monkeypatch.setattr("app.core.http_model_adapter.settings.AI_SERVICE_API_KEY", "secret-key")

    image_path = tmp_path / "scan.jpg"
    image_path.write_bytes(b"\xff\xd8\xff\xe0")

    captured_request: dict = {}

    async def fake_post(self, url, headers=None, files=None):
        captured_request["url"] = url
        captured_request["headers"] = headers
        return httpx.Response(
            status_code=200,
            json={"findings": [{"label": "Cardiomegaly", "probability": 0.42}]},
            request=httpx.Request("POST", url),
        )

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    adapter = HttpModelAdapter()
    result = await adapter.predict(image_path)

    assert captured_request["url"] == "https://ai.example.com/predict"
    assert captured_request["headers"] == {"Authorization": "Bearer secret-key"}
    assert result["model_version"] == adapter.model_version
    assert result["findings"] == [{"label": "Cardiomegaly", "probability": 0.42}]
    assert result["processed_file"] == "scan.jpg"


async def test_predict_raises_on_http_error(monkeypatch, tmp_path):
    monkeypatch.setattr(
        "app.core.http_model_adapter.settings.AI_SERVICE_URL", "https://ai.example.com/predict"
    )

    image_path = tmp_path / "scan.jpg"
    image_path.write_bytes(b"\xff\xd8\xff\xe0")

    async def fake_post(self, url, headers=None, files=None):
        return httpx.Response(
            status_code=500,
            json={"error": "model unavailable"},
            request=httpx.Request("POST", url),
        )

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post)

    adapter = HttpModelAdapter()
    with pytest.raises(httpx.HTTPStatusError):
        await adapter.predict(image_path)
