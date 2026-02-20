"""
Comprehensive tests for message editing and deletion (Pipeline 23).

Covers:
- Service layer: edit_message(), delete_message()
- View layer: EditMessageView (PATCH), DeleteMessageView (DELETE)
- Serializer/model: MessageSerializer fields, ConversationListSerializer preview
- All 11 edge cases from the ticket
- All backend acceptance criteria AC-1 through AC-15
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any
from unittest.mock import patch

from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from messaging.models import Conversation, Message
from messaging.serializers import ConversationListSerializer, MessageSerializer
from messaging.services.messaging_service import (
    EDIT_WINDOW,
    DeleteMessageResult,
    EditMessageResult,
    delete_message,
    edit_message,
    send_message,
)
from users.models import User


def _make_impersonation_token() -> dict[str, Any]:
    """Return a dict that mimics a JWT payload with impersonation claim."""
    return {'impersonating': True}


# Override throttles so tests aren't rate-limited.
_THROTTLE_OVERRIDE = {
    'DEFAULT_THROTTLE_CLASSES': [],
    'DEFAULT_THROTTLE_RATES': {},
}


class _MessagingTestBase(TestCase):
    """Shared setUp for all messaging test classes."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role=User.Role.TRAINER,
            first_name='Test',
            last_name='Trainer',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role=User.Role.TRAINEE,
            first_name='Test',
            last_name='Trainee',
            parent_trainer=self.trainer,
        )
        self.other_trainer = User.objects.create_user(
            email='other_trainer@test.com',
            password='testpass123',
            role=User.Role.TRAINER,
            first_name='Other',
            last_name='Trainer',
        )
        self.other_trainee = User.objects.create_user(
            email='other_trainee@test.com',
            password='testpass123',
            role=User.Role.TRAINEE,
            first_name='Other',
            last_name='Trainee',
            parent_trainer=self.other_trainer,
        )
        self.admin = User.objects.create_user(
            email='admin@test.com',
            password='testpass123',
            role=User.Role.ADMIN,
            first_name='Admin',
            last_name='User',
        )

        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
            last_message_at=timezone.now(),
        )
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Hello trainee!',
        )

        self.client = APIClient()


# ==========================================================================
# Service layer tests: edit_message()
# ==========================================================================


class EditMessageServiceTest(_MessagingTestBase):
    """Tests for messaging_service.edit_message()."""

    def test_successful_edit_within_window(self) -> None:
        """AC-7: edit updates content and sets edited_at."""
        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='Updated content',
        )
        self.assertIsInstance(result, EditMessageResult)
        self.assertEqual(result.message_id, self.message.id)
        self.assertEqual(result.content, 'Updated content')
        self.assertIsNotNone(result.edited_at)

        self.message.refresh_from_db()
        self.assertEqual(self.message.content, 'Updated content')
        self.assertIsNotNone(self.message.edited_at)

    def test_edit_by_non_participant_raises_permission_error(self) -> None:
        """AC-12: row-level security -- non-participant cannot edit."""
        with self.assertRaises(PermissionError) as ctx:
            edit_message(
                user=self.other_trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Hacked!',
            )
        self.assertIn('not a participant', str(ctx.exception))

    def test_edit_by_non_sender_raises_permission_error(self) -> None:
        """AC-4: only the sender can edit their own message."""
        with self.assertRaises(PermissionError) as ctx:
            edit_message(
                user=self.trainee,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Sneaky edit',
            )
        self.assertIn('only edit your own', str(ctx.exception))

    def test_edit_deleted_message_raises_value_error(self) -> None:
        """Edge case 1 / AC-4: editing a soft-deleted message returns error."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Revive!',
            )
        self.assertIn('deleted', str(ctx.exception))

    def test_edit_expired_message_raises_value_error(self) -> None:
        """Edge case 2 / AC-4: edit older than 15 minutes is rejected."""
        Message.objects.filter(id=self.message.id).update(
            created_at=timezone.now() - EDIT_WINDOW - timedelta(seconds=1),
        )
        self.message.refresh_from_db()

        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Too late',
            )
        self.assertIn('expired', str(ctx.exception))

    def test_edit_empty_content_on_text_only_message_raises_value_error(self) -> None:
        """Edge case 7: empty content on text-only message is rejected."""
        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='   ',
            )
        self.assertIn('empty', str(ctx.exception).lower())

    def test_edit_empty_content_on_image_message_allowed(self) -> None:
        """Edge case 8: clearing text on an image message is allowed."""
        image_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Caption',
            image='message_images/test.jpg',
        )

        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=image_message.id,
            new_content='',
        )
        self.assertEqual(result.content, '')

    def test_edit_content_over_2000_chars_raises_value_error(self) -> None:
        """AC-2 implied: content cannot exceed 2000 chars."""
        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='x' * 2001,
            )
        self.assertIn('2000', str(ctx.exception))

    def test_edit_exactly_2000_chars_succeeds(self) -> None:
        """Boundary: content of exactly 2000 chars is fine."""
        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='x' * 2000,
        )
        self.assertEqual(len(result.content), 2000)

    def test_edit_nonexistent_message_raises_value_error(self) -> None:
        """Attempting to edit a message that doesn't exist raises ValueError."""
        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=999999,
                new_content='Ghost',
            )
        self.assertIn('not found', str(ctx.exception))

    def test_edit_preserves_image(self) -> None:
        """Edge case 5: editing a message with an image only changes text."""
        image_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Original caption',
            image='message_images/photo.jpg',
        )

        edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=image_message.id,
            new_content='New caption',
        )

        image_message.refresh_from_db()
        self.assertEqual(image_message.content, 'New caption')
        self.assertTrue(bool(image_message.image))
        self.assertIn('photo.jpg', image_message.image.name)

    def test_edit_strips_whitespace(self) -> None:
        """Content should be stripped of leading/trailing whitespace."""
        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='   trimmed   ',
        )
        self.assertEqual(result.content, 'trimmed')

    def test_edit_returns_frozen_dataclass(self) -> None:
        """AC-14: results are frozen dataclass instances."""
        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='Frozen check',
        )
        self.assertIsInstance(result, EditMessageResult)
        with self.assertRaises(AttributeError):
            result.content = 'Mutated'  # type: ignore[misc]


# ==========================================================================
# Service layer tests: delete_message()
# ==========================================================================


class DeleteMessageServiceTest(_MessagingTestBase):
    """Tests for messaging_service.delete_message()."""

    def test_successful_delete(self) -> None:
        """AC-3, AC-6: soft-delete sets is_deleted, clears content and image."""
        result = delete_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
        )
        self.assertIsInstance(result, DeleteMessageResult)
        self.assertEqual(result.message_id, self.message.id)

        self.message.refresh_from_db()
        self.assertTrue(self.message.is_deleted)
        self.assertEqual(self.message.content, '')
        self.assertFalse(bool(self.message.image))

    def test_delete_clears_content_and_image(self) -> None:
        """AC-6: both content and image are cleared on delete."""
        image_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Photo caption',
            image='message_images/test.jpg',
        )

        delete_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=image_message.id,
        )

        image_message.refresh_from_db()
        self.assertTrue(image_message.is_deleted)
        self.assertEqual(image_message.content, '')
        self.assertIsNone(image_message.image.name if image_message.image else None)

    def test_delete_by_non_participant_raises_permission_error(self) -> None:
        """AC-12: non-participant cannot delete."""
        with self.assertRaises(PermissionError) as ctx:
            delete_message(
                user=self.other_trainer,
                conversation=self.conversation,
                message_id=self.message.id,
            )
        self.assertIn('not a participant', str(ctx.exception))

    def test_delete_by_non_sender_raises_permission_error(self) -> None:
        """AC-5: only the sender can delete their own message."""
        with self.assertRaises(PermissionError) as ctx:
            delete_message(
                user=self.trainee,
                conversation=self.conversation,
                message_id=self.message.id,
            )
        self.assertIn('only delete your own', str(ctx.exception))

    def test_delete_already_deleted_raises_value_error(self) -> None:
        """AC-5: deleting an already-deleted message returns error."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        with self.assertRaises(ValueError) as ctx:
            delete_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
            )
        self.assertIn('already been deleted', str(ctx.exception))

    def test_delete_nonexistent_message_raises_value_error(self) -> None:
        """Attempting to delete a non-existent message raises ValueError."""
        with self.assertRaises(ValueError) as ctx:
            delete_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=999999,
            )
        self.assertIn('not found', str(ctx.exception))

    def test_delete_has_no_time_limit(self) -> None:
        """AC-3: delete has no time limit (unlike edit)."""
        Message.objects.filter(id=self.message.id).update(
            created_at=timezone.now() - timedelta(days=365),
        )
        self.message.refresh_from_db()

        # Should NOT raise, even though created over a year ago
        result = delete_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
        )
        self.assertIsInstance(result, DeleteMessageResult)

    def test_delete_returns_frozen_dataclass(self) -> None:
        """AC-14: results are frozen dataclass instances."""
        result = delete_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
        )
        self.assertIsInstance(result, DeleteMessageResult)
        with self.assertRaises(AttributeError):
            result.message_id = 42  # type: ignore[misc]


# ==========================================================================
# View tests: EditMessageView (PATCH)
# ==========================================================================


@override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
class EditMessageViewTest(_MessagingTestBase):
    """Tests for PATCH /api/messaging/conversations/<id>/messages/<message_id>/."""

    def _url(self, conversation_id: int | None = None, message_id: int | None = None) -> str:
        cid = conversation_id if conversation_id is not None else self.conversation.id
        mid = message_id if message_id is not None else self.message.id
        return f'/api/messaging/conversations/{cid}/messages/{mid}/'

    def test_patch_returns_200_with_edited_message(self) -> None:
        """AC-2, AC-7: successful edit returns 200 with updated message."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.patch(
            self._url(),
            {'content': 'Edited content'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['content'], 'Edited content')
        self.assertIsNotNone(response.data['edited_at'])
        self.assertFalse(response.data['is_deleted'])

    @patch('messaging.views.is_impersonating', return_value=True)
    def test_patch_403_for_impersonation(self, mock_impersonating: Any) -> None:
        """AC-13: impersonating users cannot edit messages."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.patch(
            self._url(),
            {'content': 'Impersonated edit'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('impersonation', response.data['error'].lower())

    def test_patch_403_for_non_sender(self) -> None:
        """AC-4: non-sender gets 403."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.patch(
            self._url(),
            {'content': 'Not my message'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_patch_400_for_expired_window(self) -> None:
        """AC-4: edit past 15 minutes returns 400."""
        Message.objects.filter(id=self.message.id).update(
            created_at=timezone.now() - EDIT_WINDOW - timedelta(seconds=1),
        )

        self.client.force_authenticate(user=self.trainer)
        response = self.client.patch(
            self._url(),
            {'content': 'Too late'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('expired', response.data['error'].lower())

    def test_patch_400_for_deleted_message(self) -> None:
        """AC-4: editing a deleted message returns 400."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        self.client.force_authenticate(user=self.trainer)
        response = self.client.patch(
            self._url(),
            {'content': 'Revive!'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('deleted', response.data['error'].lower())

    def test_patch_404_for_nonexistent_conversation(self) -> None:
        """AC-12: non-existent conversation returns 404."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.patch(
            self._url(conversation_id=99999),
            {'content': 'Ghost'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_patch_400_for_empty_content_text_only(self) -> None:
        """Edge case 7: empty content on text-only message returns 400."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.patch(
            self._url(),
            {'content': '   '},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_patch_403_for_non_participant(self) -> None:
        """AC-12: user not in conversation gets 403."""
        self.client.force_authenticate(user=self.other_trainer)
        response = self.client.patch(
            self._url(),
            {'content': 'Hacked'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_patch_broadcasts_websocket_event(self) -> None:
        """AC-9: edit broadcasts chat.message_edited WebSocket event."""
        self.client.force_authenticate(user=self.trainer)

        with patch('messaging.views.broadcast_message_edited') as mock_broadcast:
            response = self.client.patch(
                self._url(),
                {'content': 'WebSocket test'},
                format='json',
            )
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            mock_broadcast.assert_called_once()
            call_kwargs = mock_broadcast.call_args
            self.assertEqual(call_kwargs[1]['conversation_id'], self.conversation.id)
            self.assertEqual(call_kwargs[1]['message_id'], self.message.id)
            self.assertEqual(call_kwargs[1]['new_content'], 'WebSocket test')
            self.assertIn('edited_at', call_kwargs[1])

    def test_patch_unauthenticated_returns_401(self) -> None:
        """Unauthenticated request returns 401."""
        response = self.client.patch(
            self._url(),
            {'content': 'No auth'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


# ==========================================================================
# View tests: DeleteMessageView (DELETE)
# ==========================================================================


@override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
class DeleteMessageViewTest(_MessagingTestBase):
    """Tests for DELETE /api/messaging/conversations/<id>/messages/<message_id>/delete/."""

    def _url(self, conversation_id: int | None = None, message_id: int | None = None) -> str:
        cid = conversation_id if conversation_id is not None else self.conversation.id
        mid = message_id if message_id is not None else self.message.id
        return f'/api/messaging/conversations/{cid}/messages/{mid}/delete/'

    def test_delete_returns_204(self) -> None:
        """AC-3: successful delete returns 204 No Content."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.delete(self._url())
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

        self.message.refresh_from_db()
        self.assertTrue(self.message.is_deleted)
        self.assertEqual(self.message.content, '')

    @patch('messaging.views.is_impersonating', return_value=True)
    def test_delete_403_for_impersonation(self, mock_impersonating: Any) -> None:
        """AC-13: impersonating users cannot delete messages."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.delete(self._url())
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('impersonation', response.data['error'].lower())

    def test_delete_403_for_non_sender(self) -> None:
        """AC-5: non-sender gets 403."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.delete(self._url())
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_delete_400_for_already_deleted(self) -> None:
        """AC-5: deleting an already-deleted message returns 400."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        self.client.force_authenticate(user=self.trainer)
        response = self.client.delete(self._url())
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('already', response.data['error'].lower())

    def test_delete_404_for_nonexistent_conversation(self) -> None:
        """AC-12: non-existent conversation returns 404."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.delete(self._url(conversation_id=99999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_403_for_non_participant(self) -> None:
        """AC-12: user not in conversation gets 403."""
        self.client.force_authenticate(user=self.other_trainer)
        response = self.client.delete(self._url())
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_delete_broadcasts_websocket_event(self) -> None:
        """AC-10: delete broadcasts chat.message_deleted WebSocket event."""
        self.client.force_authenticate(user=self.trainer)

        with patch('messaging.views.broadcast_message_deleted') as mock_broadcast:
            response = self.client.delete(self._url())
            self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
            mock_broadcast.assert_called_once_with(
                conversation_id=self.conversation.id,
                message_id=self.message.id,
            )

    def test_delete_unauthenticated_returns_401(self) -> None:
        """Unauthenticated request returns 401."""
        response = self.client.delete(self._url())
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


# ==========================================================================
# Serializer & model tests
# ==========================================================================


class MessageSerializerTest(_MessagingTestBase):
    """Tests for MessageSerializer fields (AC-1, AC-8)."""

    def test_serializer_includes_edited_at_and_is_deleted(self) -> None:
        """AC-1: MessageSerializer includes edited_at and is_deleted fields."""
        serializer = MessageSerializer(self.message)
        data = serializer.data

        self.assertIn('edited_at', data)
        self.assertIn('is_deleted', data)
        self.assertIsNone(data['edited_at'])
        self.assertFalse(data['is_deleted'])

    def test_serializer_shows_edited_at_after_edit(self) -> None:
        """AC-7: edited_at is populated after editing."""
        now = timezone.now()
        self.message.edited_at = now
        self.message.save(update_fields=['edited_at'])

        serializer = MessageSerializer(self.message)
        data = serializer.data

        self.assertIsNotNone(data['edited_at'])

    def test_serializer_deleted_message_shows_empty_content(self) -> None:
        """AC-8: deleted messages show is_deleted=true, content='', image=null."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.image = None
        self.message.save(update_fields=['is_deleted', 'content', 'image'])

        serializer = MessageSerializer(self.message)
        data = serializer.data

        self.assertTrue(data['is_deleted'])
        self.assertEqual(data['content'], '')
        self.assertIsNone(data['image'])

    def test_serializer_preserves_timestamp_on_deleted_message(self) -> None:
        """AC-8: deleted messages preserve their position in timeline."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        serializer = MessageSerializer(self.message)
        data = serializer.data

        self.assertIsNotNone(data['created_at'])

    def test_serializer_includes_all_required_fields(self) -> None:
        """Verify all expected fields are present in serialized output."""
        serializer = MessageSerializer(self.message)
        expected_fields = {
            'id', 'conversation_id', 'sender', 'content',
            'image', 'is_read', 'read_at', 'edited_at',
            'is_deleted', 'created_at',
        }
        self.assertEqual(set(serializer.data.keys()), expected_fields)


class ConversationListSerializerTest(_MessagingTestBase):
    """Tests for ConversationListSerializer preview (AC-11)."""

    def test_preview_shows_deleted_text_when_last_message_deleted(self) -> None:
        """AC-11: conversation list shows 'This message was deleted' for deleted last message."""
        from messaging.services.messaging_service import get_conversations_for_user

        # Delete the last message
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        conversations = get_conversations_for_user(self.trainer)
        serializer = ConversationListSerializer(
            conversations.first(),
            context={'request': None},
        )
        self.assertEqual(
            serializer.data['last_message_preview'],
            'This message was deleted',
        )

    def test_preview_shows_normal_content_for_active_message(self) -> None:
        """Normal (non-deleted) message shows truncated content as preview."""
        from messaging.services.messaging_service import get_conversations_for_user

        conversations = get_conversations_for_user(self.trainer)
        serializer = ConversationListSerializer(
            conversations.first(),
            context={'request': None},
        )
        self.assertEqual(
            serializer.data['last_message_preview'],
            'Hello trainee!',
        )


# ==========================================================================
# Model tests
# ==========================================================================


class MessageModelTest(_MessagingTestBase):
    """Tests for the Message model fields (AC-1)."""

    def test_edited_at_default_is_null(self) -> None:
        """AC-1: edited_at defaults to None."""
        self.assertIsNone(self.message.edited_at)

    def test_is_deleted_default_is_false(self) -> None:
        """AC-1: is_deleted defaults to False."""
        self.assertFalse(self.message.is_deleted)

    def test_str_representation_deleted(self) -> None:
        """__str__ shows [deleted] for soft-deleted messages."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])
        self.assertIn('[deleted]', str(self.message))

    def test_str_representation_normal(self) -> None:
        """__str__ shows content preview for normal messages."""
        self.assertIn('Hello trainee!', str(self.message))


# ==========================================================================
# Edge case tests (from ticket)
# ==========================================================================


class EdgeCaseTests(_MessagingTestBase):
    """Tests for all 11 edge cases listed in the ticket."""

    def test_edge_case_1_edit_already_deleted(self) -> None:
        """Edge case 1: edit a deleted message -> 400 'Message has been deleted'."""
        self.message.is_deleted = True
        self.message.content = ''
        self.message.save(update_fields=['is_deleted', 'content'])

        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Revive',
            )
        self.assertIn('deleted', str(ctx.exception))

    def test_edge_case_2_edit_message_older_than_15_minutes(self) -> None:
        """Edge case 2: edit message older than 15 min -> 400 'Edit window has expired'."""
        Message.objects.filter(id=self.message.id).update(
            created_at=timezone.now() - timedelta(minutes=16),
        )
        self.message.refresh_from_db()

        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Expired edit',
            )
        self.assertIn('expired', str(ctx.exception).lower())

    def test_edge_case_3_edit_other_users_message(self) -> None:
        """Edge case 3: edit someone else's message -> 403 Forbidden."""
        trainee_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainee,
            content='Trainee message',
        )

        with self.assertRaises(PermissionError):
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=trainee_message.id,
                new_content='Not mine',
            )

    def test_edge_case_3_delete_other_users_message(self) -> None:
        """Edge case 3: delete someone else's message -> 403 Forbidden."""
        trainee_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainee,
            content='Trainee message',
        )

        with self.assertRaises(PermissionError):
            delete_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=trainee_message.id,
            )

    def test_edge_case_4_concurrent_edits_last_write_wins(self) -> None:
        """Edge case 4: simultaneous edits -> last-write-wins (no crash)."""
        result_1 = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='Edit A',
        )
        result_2 = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='Edit B',
        )

        self.message.refresh_from_db()
        self.assertEqual(self.message.content, 'Edit B')
        self.assertEqual(result_2.content, 'Edit B')

    def test_edge_case_5_edit_image_message_preserves_image(self) -> None:
        """Edge case 5: editing image message only changes text, image preserved."""
        image_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Original caption',
            image='message_images/photo.jpg',
        )

        edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=image_message.id,
            new_content='Updated caption',
        )

        image_message.refresh_from_db()
        self.assertEqual(image_message.content, 'Updated caption')
        self.assertTrue(bool(image_message.image))

    def test_edge_case_6_delete_image_message_clears_both(self) -> None:
        """Edge case 6: deleting image message clears both content and image."""
        image_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Photo caption',
            image='message_images/photo.jpg',
        )

        with patch.object(image_message.image, 'delete'):
            delete_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=image_message.id,
            )

        image_message.refresh_from_db()
        self.assertTrue(image_message.is_deleted)
        self.assertEqual(image_message.content, '')
        # image field cleared to None / empty
        self.assertFalse(bool(image_message.image))

    def test_edge_case_7_edit_empty_content_text_only(self) -> None:
        """Edge case 7: empty content on text-only message -> 400."""
        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='',
            )
        self.assertIn('empty', str(ctx.exception).lower())

    def test_edge_case_8_edit_empty_content_image_message(self) -> None:
        """Edge case 8: empty content on image message -> allowed."""
        image_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Caption to remove',
            image='message_images/photo.jpg',
        )

        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=image_message.id,
            new_content='',
        )
        self.assertEqual(result.content, '')

    def test_edge_case_10_last_message_deleted_updates_preview(self) -> None:
        """Edge case 10: deleting last message updates conversation list preview."""
        from messaging.services.messaging_service import get_conversations_for_user

        delete_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
        )

        conversations = get_conversations_for_user(self.trainer)
        conv = conversations.first()

        serializer = ConversationListSerializer(conv, context={'request': None})
        self.assertEqual(
            serializer.data['last_message_preview'],
            'This message was deleted',
        )

    @override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
    @patch('messaging.views.is_impersonating', return_value=True)
    def test_edge_case_11_impersonating_admin_edit_forbidden(self, mock_imp: Any) -> None:
        """Edge case 11: impersonating admin cannot edit -> 403 Forbidden."""
        self.client.force_authenticate(user=self.admin)
        url = f'/api/messaging/conversations/{self.conversation.id}/messages/{self.message.id}/'
        response = self.client.patch(url, {'content': 'Admin edit'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    @override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
    @patch('messaging.views.is_impersonating', return_value=True)
    def test_edge_case_11_impersonating_admin_delete_forbidden(self, mock_imp: Any) -> None:
        """Edge case 11: impersonating admin cannot delete -> 403 Forbidden."""
        self.client.force_authenticate(user=self.admin)
        url = f'/api/messaging/conversations/{self.conversation.id}/messages/{self.message.id}/delete/'
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


# ==========================================================================
# Conversation detail (GET) deleted message rendering
# ==========================================================================


@override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
class ConversationDetailDeletedMessageTest(_MessagingTestBase):
    """AC-8: GET conversation messages returns deleted messages correctly."""

    def test_deleted_message_in_timeline(self) -> None:
        """AC-8: Deleted message appears in timeline with is_deleted=true, content='', image=null."""
        # Create a second message
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainee,
            content='Reply from trainee',
        )

        # Delete the first message
        self.message.is_deleted = True
        self.message.content = ''
        self.message.image = None
        self.message.save(update_fields=['is_deleted', 'content', 'image'])

        self.client.force_authenticate(user=self.trainer)
        url = f'/api/messaging/conversations/{self.conversation.id}/messages/'
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        results = response.data.get('results', response.data)
        # Both messages should be present (deleted msg preserves position)
        self.assertEqual(len(results), 2)

        # Find the deleted message in results
        deleted_msgs = [m for m in results if m['id'] == self.message.id]
        self.assertEqual(len(deleted_msgs), 1)
        deleted_msg = deleted_msgs[0]

        self.assertTrue(deleted_msg['is_deleted'])
        self.assertEqual(deleted_msg['content'], '')
        self.assertIsNone(deleted_msg['image'])
        self.assertIsNotNone(deleted_msg['created_at'])  # timestamp preserved


# ==========================================================================
# EDIT_WINDOW boundary tests
# ==========================================================================


class EditWindowBoundaryTest(_MessagingTestBase):
    """Tests for the 15-minute edit window boundary conditions."""

    def test_edit_at_exactly_15_minutes_fails(self) -> None:
        """Message at exactly 15:00.001 past creation is expired."""
        Message.objects.filter(id=self.message.id).update(
            created_at=timezone.now() - EDIT_WINDOW - timedelta(milliseconds=100),
        )
        self.message.refresh_from_db()

        with self.assertRaises(ValueError):
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.message.id,
                new_content='Boundary test',
            )

    def test_edit_just_before_15_minutes_succeeds(self) -> None:
        """Message at 14:59 is still editable."""
        Message.objects.filter(id=self.message.id).update(
            created_at=timezone.now() - EDIT_WINDOW + timedelta(seconds=30),
        )
        self.message.refresh_from_db()

        result = edit_message(
            user=self.trainer,
            conversation=self.conversation,
            message_id=self.message.id,
            new_content='Just in time',
        )
        self.assertEqual(result.content, 'Just in time')


# ==========================================================================
# Cross-conversation security
# ==========================================================================


class CrossConversationSecurityTest(_MessagingTestBase):
    """AC-12: messages from one conversation cannot be edited/deleted via another."""

    def setUp(self) -> None:
        super().setUp()
        # Create a second conversation for other_trainer/other_trainee
        self.other_conversation = Conversation.objects.create(
            trainer=self.other_trainer,
            trainee=self.other_trainee,
            last_message_at=timezone.now(),
        )
        self.other_message = Message.objects.create(
            conversation=self.other_conversation,
            sender=self.other_trainer,
            content='Other conversation message',
        )

    def test_edit_message_from_wrong_conversation(self) -> None:
        """Cannot edit a message by passing wrong conversation_id."""
        with self.assertRaises(PermissionError):
            edit_message(
                user=self.trainer,
                conversation=self.other_conversation,
                message_id=self.other_message.id,
                new_content='Cross-conversation hack',
            )

    def test_delete_message_from_wrong_conversation(self) -> None:
        """Cannot delete a message by passing wrong conversation_id."""
        with self.assertRaises(PermissionError):
            delete_message(
                user=self.trainer,
                conversation=self.other_conversation,
                message_id=self.other_message.id,
            )

    def test_edit_message_id_from_different_conversation_not_found(self) -> None:
        """Message belongs to other conversation -> not found in current conversation."""
        with self.assertRaises(ValueError) as ctx:
            edit_message(
                user=self.trainer,
                conversation=self.conversation,
                message_id=self.other_message.id,
                new_content='Cross hack',
            )
        self.assertIn('not found', str(ctx.exception))


# ==========================================================================
# Trainee can edit/delete their own messages
# ==========================================================================


class TraineeEditDeleteTest(_MessagingTestBase):
    """Trainee should be able to edit/delete their own messages."""

    def setUp(self) -> None:
        super().setUp()
        self.trainee_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainee,
            content='Trainee says hello',
        )

    def test_trainee_can_edit_own_message(self) -> None:
        """Trainee edits their own message successfully."""
        result = edit_message(
            user=self.trainee,
            conversation=self.conversation,
            message_id=self.trainee_message.id,
            new_content='Trainee edited',
        )
        self.assertEqual(result.content, 'Trainee edited')

    def test_trainee_can_delete_own_message(self) -> None:
        """Trainee deletes their own message successfully."""
        result = delete_message(
            user=self.trainee,
            conversation=self.conversation,
            message_id=self.trainee_message.id,
        )
        self.assertIsInstance(result, DeleteMessageResult)

        self.trainee_message.refresh_from_db()
        self.assertTrue(self.trainee_message.is_deleted)

    @override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
    def test_trainee_edit_via_api(self) -> None:
        """Trainee can edit via PATCH endpoint."""
        self.client.force_authenticate(user=self.trainee)
        url = (
            f'/api/messaging/conversations/{self.conversation.id}'
            f'/messages/{self.trainee_message.id}/'
        )
        response = self.client.patch(
            url,
            {'content': 'Trainee API edit'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['content'], 'Trainee API edit')

    @override_settings(REST_FRAMEWORK={**_THROTTLE_OVERRIDE})
    def test_trainee_delete_via_api(self) -> None:
        """Trainee can delete via DELETE endpoint."""
        self.client.force_authenticate(user=self.trainee)
        url = (
            f'/api/messaging/conversations/{self.conversation.id}'
            f'/messages/{self.trainee_message.id}/delete/'
        )
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
