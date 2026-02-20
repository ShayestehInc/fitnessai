"""
Tests for image attachment support in direct messages (Pipeline 21).

Covers: image upload validation, send with image, image-only messages,
image+text, conversation list preview, push notification body, and
backward compatibility with text-only messages.
"""
from __future__ import annotations

import io
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from messaging.models import Conversation, Message
from messaging.services.messaging_service import (
    get_conversations_for_user,
    send_message,
)
from users.models import User


def _create_test_image(
    name: str = 'test.jpg',
    content_type: str = 'image/jpeg',
    size: int = 1024,
) -> SimpleUploadedFile:
    """Create a minimal valid JPEG file for testing."""
    # Minimal JPEG header (SOI + APP0 + EOI markers)
    jpeg_header = (
        b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
        b'\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t'
        b'\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a'
        b'\x1f\x1e\x1d\x1a\x1c\x1c $.\' ",#\x1c\x1c(7),01444\x1f\'9=82<.342'
        b'\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00'
        b'\xff\xc4\x00\x1f\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00'
        b'\x00\x00\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b'
        b'\xff\xda\x00\x08\x01\x01\x00\x00?\x00T\xdb\xae\xa7R\xa8\x01\x00'
        b'\xff\xd9'
    )
    # Pad to requested size
    content = jpeg_header + b'\x00' * max(0, size - len(jpeg_header))
    return SimpleUploadedFile(name, content, content_type=content_type)


def _create_oversized_image(name: str = 'big.jpg') -> SimpleUploadedFile:
    """Create an image that exceeds the 5MB limit."""
    size = 5 * 1024 * 1024 + 1  # 5MB + 1 byte
    return _create_test_image(name=name, size=size)


class SendMessageWithImageTests(TestCase):
    """Tests for POST /api/messaging/conversations/<id>/send/ with images."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = f'/api/messaging/conversations/{self.conversation.id}/send/'

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_send_image_only_message(self, mock_push: object, mock_broadcast: object) -> None:
        """Image-only message (no text content) should succeed."""
        image = _create_test_image()
        response = self.client.post(self.url, {'image': image}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNotNone(response.data['image'])
        self.assertEqual(response.data['content'], '')

        message = Message.objects.get(id=response.data['id'])
        self.assertTrue(bool(message.image))
        self.assertEqual(message.content, '')

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_send_image_with_text(self, mock_push: object, mock_broadcast: object) -> None:
        """Message with both text and image should succeed."""
        image = _create_test_image()
        response = self.client.post(
            self.url,
            {'content': 'Check this out!', 'image': image},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNotNone(response.data['image'])
        self.assertEqual(response.data['content'], 'Check this out!')

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_send_text_only_backward_compatible(self, mock_push: object, mock_broadcast: object) -> None:
        """Text-only messages (JSON) should continue to work identically."""
        response = self.client.post(
            self.url,
            {'content': 'Hello!'},
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(response.data['image'])
        self.assertEqual(response.data['content'], 'Hello!')

    def test_reject_empty_message(self) -> None:
        """Message with no content and no image should be rejected."""
        response = self.client.post(self.url, {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_reject_whitespace_only_no_image(self) -> None:
        """Whitespace-only content with no image should be rejected."""
        response = self.client.post(
            self.url,
            {'content': '   '},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_reject_oversized_image(self) -> None:
        """Image over 5MB should be rejected."""
        image = _create_oversized_image()
        response = self.client.post(self.url, {'image': image}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('5MB', response.data['error'])

    def test_reject_invalid_image_type_gif(self) -> None:
        """GIF images should be rejected."""
        gif = SimpleUploadedFile('test.gif', b'GIF89a\x01\x00', content_type='image/gif')
        response = self.client.post(self.url, {'image': gif}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('JPEG, PNG, and WebP', response.data['error'])

    def test_reject_invalid_image_type_svg(self) -> None:
        """SVG images should be rejected."""
        svg = SimpleUploadedFile('test.svg', b'<svg></svg>', content_type='image/svg+xml')
        response = self.client.post(self.url, {'image': svg}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_reject_pdf_as_image(self) -> None:
        """PDF files should be rejected."""
        pdf = SimpleUploadedFile('test.pdf', b'%PDF-1.4', content_type='application/pdf')
        response = self.client.post(self.url, {'image': pdf}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_accept_png_image(self, mock_push: object, mock_broadcast: object) -> None:
        """PNG images should be accepted."""
        # Minimal PNG
        png_data = (
            b'\x89PNG\r\n\x1a\n'  # PNG signature
            b'\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02'
            b'\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx'
            b'\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82'
        )
        png = SimpleUploadedFile('test.png', png_data, content_type='image/png')
        response = self.client.post(self.url, {'image': png}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNotNone(response.data['image'])

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_accept_webp_image(self, mock_push: object, mock_broadcast: object) -> None:
        """WebP images should be accepted."""
        webp = SimpleUploadedFile('test.webp', b'RIFF\x00\x00\x00\x00WEBP', content_type='image/webp')
        response = self.client.post(self.url, {'image': webp}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_image_url_is_absolute(self, mock_push: object, mock_broadcast: object) -> None:
        """Image URL in response should be absolute (includes host)."""
        image = _create_test_image()
        response = self.client.post(self.url, {'image': image}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            response.data['image'].startswith('http'),
            f"Image URL should be absolute, got: {response.data['image']}",
        )

    def test_row_level_security_blocks_non_participant(self) -> None:
        """Non-participant should not be able to send images."""
        other_trainer = User.objects.create_user(
            email='other@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client.force_authenticate(user=other_trainer)

        image = _create_test_image()
        response = self.client.post(self.url, {'image': image}, format='multipart')

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class StartConversationWithImageTests(TestCase):
    """Tests for POST /api/messaging/conversations/start/ with images."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/messaging/conversations/start/'

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_start_conversation_with_image(self, mock_push: object, mock_broadcast: object) -> None:
        """Starting a new conversation with an image should succeed."""
        image = _create_test_image()
        response = self.client.post(
            self.url,
            {'trainee_id': self.trainee.id, 'image': image},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data['is_new_conversation'])
        self.assertIsNotNone(response.data['message']['image'])

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_start_conversation_with_image_and_text(self, mock_push: object, mock_broadcast: object) -> None:
        """Starting a conversation with both text and image should work."""
        image = _create_test_image()
        response = self.client.post(
            self.url,
            {
                'trainee_id': self.trainee.id,
                'content': 'Welcome!',
                'image': image,
            },
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['message']['content'], 'Welcome!')
        self.assertIsNotNone(response.data['message']['image'])

    def test_start_conversation_reject_oversized_image(self) -> None:
        """Oversized images should be rejected when starting a conversation."""
        image = _create_oversized_image()
        response = self.client.post(
            self.url,
            {'trainee_id': self.trainee.id, 'image': image},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_start_conversation_reject_invalid_type(self) -> None:
        """Invalid image types should be rejected when starting a conversation."""
        gif = SimpleUploadedFile('test.gif', b'GIF89a', content_type='image/gif')
        response = self.client.post(
            self.url,
            {'trainee_id': self.trainee.id, 'image': gif},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_trainee_cannot_start_conversation(self) -> None:
        """Only trainers can start conversations (with or without images)."""
        self.client.force_authenticate(user=self.trainee)
        image = _create_test_image()
        response = self.client.post(
            self.url,
            {'trainee_id': self.trainee.id, 'image': image},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class ConversationListImagePreviewTests(TestCase):
    """Tests for conversation list preview with image messages."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)

    def test_image_only_preview_shows_sent_a_photo(self) -> None:
        """Conversation preview should show 'Sent a photo' for image-only last message."""
        image = _create_test_image()
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='',
            image=image,
        )
        self.conversation.last_message_at = Message.objects.last().created_at  # type: ignore[union-attr]
        self.conversation.save(update_fields=['last_message_at'])

        response = self.client.get('/api/messaging/conversations/')
        conversations = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(len(conversations), 1)
        self.assertEqual(conversations[0]['last_message_preview'], 'Sent a photo')

    def test_text_message_preview_shows_text(self) -> None:
        """Conversation preview should show text content for text messages."""
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Hello trainee!',
        )
        self.conversation.last_message_at = Message.objects.last().created_at  # type: ignore[union-attr]
        self.conversation.save(update_fields=['last_message_at'])

        response = self.client.get('/api/messaging/conversations/')
        conversations = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(conversations[0]['last_message_preview'], 'Hello trainee!')

    def test_image_plus_text_preview_shows_text(self) -> None:
        """Conversation preview should show text when message has both image and text."""
        image = _create_test_image()
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Check this form!',
            image=image,
        )
        self.conversation.last_message_at = Message.objects.last().created_at  # type: ignore[union-attr]
        self.conversation.save(update_fields=['last_message_at'])

        response = self.client.get('/api/messaging/conversations/')
        conversations = response.data['results'] if 'results' in response.data else response.data
        self.assertEqual(conversations[0]['last_message_preview'], 'Check this form!')


class PushNotificationImageTests(TestCase):
    """Tests for push notification body with image messages."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
            first_name='John',
            last_name='Trainer',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = f'/api/messaging/conversations/{self.conversation.id}/send/'

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_image_only_push_notification_body(self, mock_push: object, mock_broadcast: object) -> None:
        """Push notification for image-only message should show has_image=True."""
        image = _create_test_image()
        self.client.post(self.url, {'image': image}, format='multipart')

        mock_push.assert_called_once()  # type: ignore[union-attr]
        call_kwargs = mock_push.call_args  # type: ignore[union-attr]
        self.assertTrue(call_kwargs[1].get('has_image') or call_kwargs.kwargs.get('has_image'))

    @patch('messaging.views.broadcast_new_message')
    @patch('messaging.views.send_message_push_notification')
    def test_text_only_push_notification_no_image_flag(self, mock_push: object, mock_broadcast: object) -> None:
        """Push notification for text-only message should not flag as image."""
        self.client.post(self.url, {'content': 'Hello!'}, format='json')

        mock_push.assert_called_once()  # type: ignore[union-attr]
        call_kwargs = mock_push.call_args  # type: ignore[union-attr]
        # has_image should be False for text-only
        has_image = call_kwargs[1].get('has_image', call_kwargs.kwargs.get('has_image', False))
        self.assertFalse(has_image)


class MessageServiceImageTests(TestCase):
    """Tests for the messaging service layer with image support."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
        )

    def test_send_message_with_image_returns_image_url(self) -> None:
        """Service should return image_url in the result."""
        image = _create_test_image()
        result = send_message(
            sender=self.trainer,
            conversation=self.conversation,
            content='',
            image=image,
        )

        self.assertIsNotNone(result.image_url)
        self.assertIn('message_images/', result.image_url)  # type: ignore[operator]

    def test_send_message_text_only_no_image_url(self) -> None:
        """Text-only message result should have image_url=None."""
        result = send_message(
            sender=self.trainer,
            conversation=self.conversation,
            content='Hello!',
        )

        self.assertIsNone(result.image_url)

    def test_send_message_rejects_empty(self) -> None:
        """Message with no content and no image should raise ValueError."""
        with self.assertRaises(ValueError) as ctx:
            send_message(
                sender=self.trainer,
                conversation=self.conversation,
                content='',
            )
        self.assertIn('text or an image', str(ctx.exception))

    def test_send_message_updates_conversation_timestamp(self) -> None:
        """Sending an image message should update conversation.last_message_at."""
        self.assertIsNone(self.conversation.last_message_at)

        image = _create_test_image()
        send_message(
            sender=self.trainer,
            conversation=self.conversation,
            content='',
            image=image,
        )

        self.conversation.refresh_from_db()
        self.assertIsNotNone(self.conversation.last_message_at)

    def test_image_upload_path_uses_uuid(self) -> None:
        """Image upload path should use UUID, not original filename."""
        image = _create_test_image(name='my_secret_photo.jpg')
        result = send_message(
            sender=self.trainer,
            conversation=self.conversation,
            content='',
            image=image,
        )

        self.assertNotIn('my_secret_photo', result.image_url or '')
        self.assertIn('message_images/', result.image_url or '')


class AnnotationLastMessageImageTests(TestCase):
    """Tests for the annotated_last_message_has_image annotation."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
        )

    def test_annotation_true_when_last_message_has_image(self) -> None:
        """Annotation should be True when last message has an image."""
        image = _create_test_image()
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='',
            image=image,
        )
        self.conversation.last_message_at = Message.objects.last().created_at  # type: ignore[union-attr]
        self.conversation.save(update_fields=['last_message_at'])

        conversations = get_conversations_for_user(self.trainer)
        conv = conversations.first()
        self.assertIsNotNone(conv)
        self.assertTrue(getattr(conv, 'annotated_last_message_has_image', False))

    def test_annotation_false_when_last_message_text_only(self) -> None:
        """Annotation should be False when last message has no image."""
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Hello!',
        )
        self.conversation.last_message_at = Message.objects.last().created_at  # type: ignore[union-attr]
        self.conversation.save(update_fields=['last_message_at'])

        conversations = get_conversations_for_user(self.trainer)
        conv = conversations.first()
        self.assertIsNotNone(conv)
        self.assertFalse(getattr(conv, 'annotated_last_message_has_image', True))

    def test_annotation_checks_last_message_not_any(self) -> None:
        """Annotation should check the LAST message, not any message."""
        # First message has an image
        image = _create_test_image()
        Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='',
            image=image,
        )
        # Second message (most recent) is text-only
        msg = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainee,
            content='Thanks!',
        )
        self.conversation.last_message_at = msg.created_at
        self.conversation.save(update_fields=['last_message_at'])

        conversations = get_conversations_for_user(self.trainer)
        conv = conversations.first()
        self.assertIsNotNone(conv)
        # Should be False because the LAST message is text-only
        self.assertFalse(getattr(conv, 'annotated_last_message_has_image', True))

    def test_annotation_false_when_no_messages(self) -> None:
        """Annotation should be False when conversation has no messages."""
        conversations = get_conversations_for_user(self.trainer)
        conv = conversations.first()
        self.assertIsNotNone(conv)
        self.assertFalse(getattr(conv, 'annotated_last_message_has_image', True))


class MessageModelImageTests(TestCase):
    """Tests for the Message model image field."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.conversation = Conversation.objects.create(
            trainer=self.trainer,
            trainee=self.trainee,
        )

    def test_message_str_with_image_only(self) -> None:
        """Message __str__ should show [Photo] for image-only messages."""
        image = _create_test_image()
        message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='',
            image=image,
        )
        self.assertIn('[Photo]', str(message))

    def test_message_str_with_text(self) -> None:
        """Message __str__ should show text content when present."""
        message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Hello!',
        )
        self.assertIn('Hello!', str(message))

    def test_message_image_defaults_to_none(self) -> None:
        """Message image should default to None."""
        message = Message.objects.create(
            conversation=self.conversation,
            sender=self.trainer,
            content='Test',
        )
        self.assertFalse(bool(message.image))
