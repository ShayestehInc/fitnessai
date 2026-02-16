"""
WebSocket consumer for real-time community feed updates.

Trainees connect to a group based on their parent_trainer's ID.
JWT authentication is performed via query parameter (token=...).
"""
from __future__ import annotations

import json
import logging
from typing import Any

from channels.generic.websocket import AsyncJsonWebSocketConsumer  # type: ignore[import-untyped]

logger = logging.getLogger(__name__)


class CommunityFeedConsumer(AsyncJsonWebSocketConsumer):
    """
    WebSocket consumer for the community feed.

    Connect:  ws://host/ws/community/feed/?token=<JWT>
    Receives: new_post, post_deleted, new_comment events from the channel layer.
    """

    group_name: str = ''
    trainer_id: int | None = None

    async def connect(self) -> None:
        """Authenticate user and join the trainer's feed group."""
        user = await self._authenticate()
        if user is None:
            await self.close(code=4001)
            return

        trainer_id = await self._get_trainer_id(user)
        if trainer_id is None:
            await self.close(code=4003)
            return

        self.trainer_id = trainer_id
        self.group_name = f'community_feed_{trainer_id}'

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name,
        )
        await self.accept()
        logger.debug(
            "WebSocket connected: user=%s, group=%s",
            user.id, self.group_name,
        )

    async def disconnect(self, code: int) -> None:
        """Leave the feed group on disconnect."""
        if self.group_name:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name,
            )

    async def receive_json(self, content: dict[str, Any], **kwargs: Any) -> None:
        """
        Handle incoming messages from the client.
        Currently clients only listen; we send a heartbeat acknowledgment.
        """
        msg_type = content.get('type')
        if msg_type == 'ping':
            await self.send_json({'type': 'pong'})

    # ------------------------------------------------------------------
    # Channel layer event handlers
    # ------------------------------------------------------------------

    async def feed_new_post(self, event: dict[str, Any]) -> None:
        """Forward new post to the client."""
        await self.send_json({
            'type': 'new_post',
            'post': event['post'],
        })

    async def feed_post_deleted(self, event: dict[str, Any]) -> None:
        """Forward post deletion to the client."""
        await self.send_json({
            'type': 'post_deleted',
            'post_id': event['post_id'],
        })

    async def feed_new_comment(self, event: dict[str, Any]) -> None:
        """Forward new comment to the client."""
        await self.send_json({
            'type': 'new_comment',
            'post_id': event['post_id'],
            'comment': event['comment'],
        })

    # ------------------------------------------------------------------
    # Auth helpers
    # ------------------------------------------------------------------

    async def _authenticate(self) -> Any:
        """
        Authenticate user from JWT token in query params.
        Returns User instance or None.
        """
        from channels.db import database_sync_to_async  # type: ignore[import-untyped]

        query_string = self.scope.get('query_string', b'').decode('utf-8')
        params = dict(
            pair.split('=', 1)
            for pair in query_string.split('&')
            if '=' in pair
        )
        token = params.get('token')
        if not token:
            return None

        @database_sync_to_async  # type: ignore[misc]
        def get_user_from_token(jwt_token: str) -> Any:
            try:
                from rest_framework_simplejwt.tokens import AccessToken  # type: ignore[import-untyped]
                from users.models import User

                validated = AccessToken(jwt_token)
                user_id = validated.get('user_id')
                if user_id is None:
                    return None
                return User.objects.get(id=user_id, is_active=True)
            except Exception:
                return None

        return await get_user_from_token(token)

    async def _get_trainer_id(self, user: Any) -> int | None:
        """Get the trainer ID for a user."""
        from channels.db import database_sync_to_async  # type: ignore[import-untyped]

        @database_sync_to_async  # type: ignore[misc]
        def _get_id(u: Any) -> int | None:
            if u.is_trainee() and u.parent_trainer_id:
                return u.parent_trainer_id
            elif u.is_trainer():
                return u.id
            return None

        return await _get_id(user)
