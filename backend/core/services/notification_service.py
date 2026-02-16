"""
Firebase Cloud Messaging push notification service.

Wraps firebase-admin SDK for sending push notifications to users.
Firebase app is initialized lazily from FIREBASE_CREDENTIALS_PATH env var.
All errors are handled gracefully -- this service never raises.
"""
from __future__ import annotations

import logging
from typing import Any

from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_app: Any = None
_firebase_init_attempted: bool = False


def _ensure_firebase_initialized() -> bool:
    """Lazy-initialize Firebase Admin SDK. Returns True if ready."""
    global _firebase_app, _firebase_init_attempted

    if _firebase_app is not None:
        return True

    if _firebase_init_attempted:
        return False

    _firebase_init_attempted = True

    credentials_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', '')
    if not credentials_path:
        logger.warning(
            "FIREBASE_CREDENTIALS_PATH is not set. Push notifications are disabled."
        )
        return False

    try:
        import firebase_admin  # type: ignore[import-untyped]
        from firebase_admin import credentials as fb_credentials  # type: ignore[import-untyped]

        cred = fb_credentials.Certificate(credentials_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK initialized successfully.")
        return True
    except FileNotFoundError:
        logger.warning(
            "Firebase credentials file not found at: %s. Push notifications disabled.",
            credentials_path,
        )
        return False
    except Exception:
        logger.exception("Failed to initialize Firebase Admin SDK.")
        return False


def send_push_notification(
    user_id: int,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> bool:
    """
    Send push notification to all active device tokens for a user.

    Returns True if at least one message was delivered successfully.
    Never raises -- returns False on complete failure.
    """
    if not _ensure_firebase_initialized():
        return False

    from users.models import DeviceToken

    tokens = list(
        DeviceToken.objects.filter(
            user_id=user_id,
            is_active=True,
        ).values_list('id', 'token')
    )

    if not tokens:
        return False

    return _send_to_tokens(tokens, title, body, data or {})


def send_push_to_group(
    user_ids: list[int],
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> int:
    """
    Send push notification to all active device tokens for a group of users.

    Returns count of users reached (at least one token per user succeeded).
    Never raises -- returns 0 on complete failure.
    """
    if not _ensure_firebase_initialized():
        return 0

    if not user_ids:
        return 0

    from users.models import DeviceToken

    tokens = list(
        DeviceToken.objects.filter(
            user_id__in=user_ids,
            is_active=True,
        ).values_list('id', 'token', 'user_id')
    )

    if not tokens:
        return 0

    # Group tokens by user
    user_tokens: dict[int, list[tuple[int, str]]] = {}
    for token_id, token_value, uid in tokens:
        user_tokens.setdefault(uid, []).append((token_id, token_value))

    users_reached = 0
    all_token_pairs: list[tuple[int, str]] = []
    for uid, pairs in user_tokens.items():
        all_token_pairs.extend(pairs)

    succeeded_token_ids = _send_to_tokens_batch(
        all_token_pairs, title, body, data or {},
    )

    # Count users who had at least one successful delivery
    succeeded_user_ids: set[int] = set()
    token_id_to_user: dict[int, int] = {}
    for token_id, _, uid in tokens:
        token_id_to_user[token_id] = uid

    for token_id in succeeded_token_ids:
        uid = token_id_to_user.get(token_id)
        if uid is not None:
            succeeded_user_ids.add(uid)

    return len(succeeded_user_ids)


def _send_to_tokens(
    tokens: list[tuple[int, str]],
    title: str,
    body: str,
    data: dict[str, str],
) -> bool:
    """Send to a list of (token_id, token_value) pairs. Returns True if any succeeded."""
    succeeded_ids = _send_to_tokens_batch(tokens, title, body, data)
    return len(succeeded_ids) > 0


def _send_to_tokens_batch(
    tokens: list[tuple[int, str]],
    title: str,
    body: str,
    data: dict[str, str],
) -> set[int]:
    """
    Send push notifications in batches of 500 (FCM limit).
    Returns set of token_ids that succeeded.
    Deactivates tokens that return UnregisteredError or SenderIdMismatchError.
    """
    try:
        from firebase_admin import messaging  # type: ignore[import-untyped]
    except ImportError:
        logger.warning("firebase-admin not installed. Cannot send push notifications.")
        return set()

    succeeded_ids: set[int] = set()
    deactivate_ids: list[int] = []

    # Process in batches of 500
    batch_size = 500
    for i in range(0, len(tokens), batch_size):
        batch = tokens[i:i + batch_size]
        messages = []
        batch_map: list[int] = []  # Maps message index to token_id

        for token_id, token_value in batch:
            msg = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data,
                token=token_value,
            )
            messages.append(msg)
            batch_map.append(token_id)

        try:
            response = messaging.send_each(messages)
            for idx, send_response in enumerate(response.responses):
                token_id = batch_map[idx]
                if send_response.success:
                    succeeded_ids.add(token_id)
                elif send_response.exception is not None:
                    exc = send_response.exception
                    # Mark unregistered or mismatched tokens as inactive
                    if isinstance(exc, (
                        messaging.UnregisteredError,
                        messaging.SenderIdMismatchError,
                    )):
                        deactivate_ids.append(token_id)
                        logger.debug(
                            "Deactivating token %d: %s",
                            token_id,
                            type(exc).__name__,
                        )
        except Exception:
            logger.warning(
                "Failed to send FCM batch (tokens %d-%d)",
                i, i + len(batch),
            )

    # Bulk deactivate invalid tokens
    if deactivate_ids:
        from users.models import DeviceToken
        DeviceToken.objects.filter(id__in=deactivate_ids).update(is_active=False)

    return succeeded_ids
