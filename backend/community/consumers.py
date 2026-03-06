"""
WebSocket consumer for real-time community feed updates.

Trainees connect to a group based on their parent_trainer's ID.
JWT authentication is performed via query parameter (token=...).
"""
from __future__ import annotations

import logging
from typing import Any

from channels.generic.websocket import AsyncJsonWebsocketConsumer  # type: ignore[import-untyped]

logger = logging.getLogger(__name__)


class CommunityFeedConsumer(AsyncJsonWebsocketConsumer):
    """
    WebSocket consumer for the community feed.

    Connect:  ws://host/ws/community/feed/?token=<JWT>
    Receives: new_post, post_deleted, new_comment events from the channel layer.
    Supports: subscribe/unsubscribe to space-specific groups.
    """

    group_name: str = ''
    trainer_id: int | None = None
    space_groups: set[str]

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.space_groups = set()

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
        """Leave the feed group and all space groups on disconnect."""
        if self.group_name:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name,
            )
        # Leave all subscribed space groups
        for space_group in self.space_groups:
            await self.channel_layer.group_discard(
                space_group,
                self.channel_name,
            )
        self.space_groups.clear()

    async def receive_json(self, content: dict[str, Any], **kwargs: Any) -> None:
        """
        Handle incoming messages from the client.
        Supports: ping, subscribe_space, unsubscribe_space.
        """
        msg_type = content.get('type')
        if msg_type == 'ping':
            await self.send_json({'type': 'pong'})
        elif msg_type == 'subscribe_space':
            space_id = content.get('space_id')
            if space_id is not None:
                group = f'community_space_{space_id}'
                if group not in self.space_groups:
                    await self.channel_layer.group_add(group, self.channel_name)
                    self.space_groups.add(group)
                    await self.send_json({
                        'type': 'subscribed_space',
                        'space_id': space_id,
                    })
        elif msg_type == 'unsubscribe_space':
            space_id = content.get('space_id')
            if space_id is not None:
                group = f'community_space_{space_id}'
                if group in self.space_groups:
                    await self.channel_layer.group_discard(group, self.channel_name)
                    self.space_groups.discard(group)
                    await self.send_json({
                        'type': 'unsubscribed_space',
                        'space_id': space_id,
                    })

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

    async def feed_reaction_update(self, event: dict[str, Any]) -> None:
        """Forward reaction count update to the client."""
        await self.send_json({
            'type': 'reaction_update',
            'post_id': event['post_id'],
            'reactions': event['reactions'],
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
