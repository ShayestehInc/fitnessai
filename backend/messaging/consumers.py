"""
WebSocket consumer for real-time direct messaging.

Each conversation has its own channel group: messaging_conversation_{id}.
JWT authentication is performed via query parameter (token=...).
Supports: new messages, typing indicators, read receipts.
"""
from __future__ import annotations

import logging
from typing import Any

from channels.generic.websocket import AsyncJsonWebsocketConsumer  # type: ignore[import-untyped]

logger = logging.getLogger(__name__)


class DirectMessageConsumer(AsyncJsonWebsocketConsumer):
    """
    WebSocket consumer for a single conversation.

    Connect:  ws://host/ws/messaging/<conversation_id>/?token=<JWT>
    Sends:    new_message, typing_indicator, read_receipt events.
    Receives: typing (from client to broadcast to other party).
    """

    group_name: str = ''
    conversation_id: int = 0
    user_id: int = 0

    async def connect(self) -> None:
        """Authenticate user, verify conversation access, join group."""
        self.conversation_id = int(self.scope['url_route']['kwargs']['conversation_id'])

        user = await self._authenticate()
        if user is None:
            await self.close(code=4001)
            return

        self.user_id = user.id

        # Verify user is a participant in this conversation
        has_access = await self._check_conversation_access(user, self.conversation_id)
        if not has_access:
            await self.close(code=4003)
            return

        self.group_name = f'messaging_conversation_{self.conversation_id}'

        await self.channel_layer.group_add(
            self.group_name,
            self.channel_name,
        )
        await self.accept()
        logger.debug(
            "Messaging WebSocket connected: user=%d, conversation=%d",
            user.id, self.conversation_id,
        )

    async def disconnect(self, code: int) -> None:
        """Leave the conversation group on disconnect."""
        if self.group_name:
            await self.channel_layer.group_discard(
                self.group_name,
                self.channel_name,
            )

    async def receive_json(self, content: dict[str, Any], **kwargs: Any) -> None:
        """
        Handle incoming messages from the client.

        Supported types:
        - ping: heartbeat
        - typing: broadcast typing indicator to other party
        """
        msg_type = content.get('type')

        if msg_type == 'ping':
            await self.send_json({'type': 'pong'})

        elif msg_type == 'typing':
            # Broadcast typing indicator to the group (other party).
            # Coerce is_typing to a strict bool to prevent injection of
            # arbitrary data via the WebSocket frame.
            is_typing = bool(content.get('is_typing', True))
            if self.group_name:
                await self.channel_layer.group_send(
                    self.group_name,
                    {
                        'type': 'chat.typing',
                        'user_id': self.user_id,
                        'is_typing': is_typing,
                    },
                )

    # ------------------------------------------------------------------
    # Channel layer event handlers
    # ------------------------------------------------------------------

    async def chat_new_message(self, event: dict[str, Any]) -> None:
        """Forward new message to the client."""
        await self.send_json({
            'type': 'new_message',
            'message': event['message'],
        })

    async def chat_typing(self, event: dict[str, Any]) -> None:
        """Forward typing indicator to client (skip self)."""
        if event.get('user_id') == self.user_id:
            return
        await self.send_json({
            'type': 'typing_indicator',
            'user_id': event['user_id'],
            'is_typing': event.get('is_typing', True),
        })

    async def chat_read_receipt(self, event: dict[str, Any]) -> None:
        """Forward read receipt to the client."""
        await self.send_json({
            'type': 'read_receipt',
            'reader_id': event['reader_id'],
            'read_at': event['read_at'],
        })

    async def chat_message_edited(self, event: dict[str, Any]) -> None:
        """Forward message-edited event to the client."""
        await self.send_json({
            'type': 'message_edited',
            'message_id': event['message_id'],
            'content': event['content'],
            'edited_at': event['edited_at'],
        })

    async def chat_message_deleted(self, event: dict[str, Any]) -> None:
        """Forward message-deleted event to the client."""
        await self.send_json({
            'type': 'message_deleted',
            'message_id': event['message_id'],
        })

    # ------------------------------------------------------------------
    # Auth helpers
    # ------------------------------------------------------------------

    async def _authenticate(self) -> Any:
        """Authenticate user from JWT token in query params."""
        from urllib.parse import parse_qs

        from channels.db import database_sync_to_async  # type: ignore[import-untyped]

        query_string = self.scope.get('query_string', b'').decode('utf-8')
        parsed = parse_qs(query_string)
        token_values = parsed.get('token', [])
        token = token_values[0] if token_values else None
        if not token:
            return None

        @database_sync_to_async  # type: ignore[misc]
        def get_user_from_token(jwt_token: str) -> Any:
            from rest_framework_simplejwt.exceptions import TokenError  # type: ignore[import-untyped]
            from rest_framework_simplejwt.tokens import AccessToken  # type: ignore[import-untyped]
            from users.models import User

            try:
                validated = AccessToken(jwt_token)
                user_id = validated.get('user_id')
                if user_id is None:
                    return None
                return User.objects.get(id=user_id, is_active=True)
            except (TokenError, User.DoesNotExist, ValueError, KeyError) as exc:
                logger.debug("WebSocket JWT auth failed: %s", exc)
                return None

        return await get_user_from_token(token)

    async def _check_conversation_access(
        self,
        user: Any,
        conversation_id: int,
    ) -> bool:
        """Check if user is a participant in an active (non-archived) conversation."""
        from channels.db import database_sync_to_async  # type: ignore[import-untyped]

        @database_sync_to_async  # type: ignore[misc]
        def _check(u: Any, cid: int) -> bool:
            from django.db.models import Q
            from messaging.models import Conversation

            return Conversation.objects.filter(
                Q(trainer=u) | Q(trainee=u),
                id=cid,
                is_archived=False,
            ).exists()

        return await _check(user, conversation_id)
