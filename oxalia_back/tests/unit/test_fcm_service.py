"""Unit tests for FCM send helpers (no real Firebase calls)."""

from app.services import fcm_service


def test_send_to_tokens_noop_without_credentials(monkeypatch):
    monkeypatch.setattr(fcm_service, "_app_ready", False)
    monkeypatch.setattr(fcm_service, "_init_attempted", False)
    monkeypatch.setattr(fcm_service.settings, "FIREBASE_CREDENTIALS_PATH", "")

    stale = fcm_service.send_to_tokens(
        ["fake-token"],
        title="Analysis ready",
        body="Results for Jane Doe are ready to review.",
        data={"exam_id": "abc"},
    )

    assert stale == []
