"""Firebase Cloud Messaging helpers.

Initializes lazily from FIREBASE_CREDENTIALS_PATH. If the path is missing
or invalid, send calls become no-ops so local/dev works without Firebase.
"""

from __future__ import annotations

import logging
from pathlib import Path

from app.config import settings

logger = logging.getLogger(__name__)

_app_ready = False
_init_attempted = False


def _ensure_app() -> bool:
    global _app_ready, _init_attempted
    if _app_ready:
        return True
    if _init_attempted:
        return False
    _init_attempted = True

    cred_path = (settings.FIREBASE_CREDENTIALS_PATH or "").strip()
    if not cred_path:
        logger.warning("FCM disabled: FIREBASE_CREDENTIALS_PATH is not set")
        return False

    path = Path(cred_path)
    if not path.is_file():
        logger.warning("FCM disabled: credentials file not found at %s", path)
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(str(path)))
        _app_ready = True
        logger.info("Firebase Admin initialized for FCM")
        return True
    except Exception:
        logger.exception("FCM disabled: failed to initialize Firebase Admin")
        return False


def send_to_tokens(
    tokens: list[str],
    *,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> list[str]:
    """Send a notification to each token. Returns tokens that should be deleted
    (unregistered / invalid).
    """
    if not tokens or not _ensure_app():
        return []

    from firebase_admin import messaging

    stale: list[str] = []
    payload = {k: str(v) for k, v in (data or {}).items()}

    for token in tokens:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=payload,
            token=token,
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    click_action="FLUTTER_NOTIFICATION_CLICK"
                ),
            ),
        )
        try:
            messaging.send(message)
        except Exception as exc:
            # Invalid / unregistered tokens should be purged so we stop retrying.
            name = type(exc).__name__.lower()
            text = str(exc).lower()
            if (
                "unregistered" in name
                or "notfound" in name
                or "unregistered" in text
                or "requested entity was not found" in text
            ):
                stale.append(token)
            else:
                logger.exception("FCM send failed for a device token")

    return stale
