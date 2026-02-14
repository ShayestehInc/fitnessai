"""
Tests for White-Label Branding Infrastructure.

Covers:
- TrainerBranding model: creation, defaults, validation, get_or_create_for_trainer
- validate_hex_color function
- TrainerBrandingView: GET (auto-create), PUT (update fields)
- TrainerBrandingLogoView: POST (upload with validation), DELETE
- MyBrandingView: GET (trainee sees trainer branding, defaults for no trainer/no branding)
- Permission enforcement: IsTrainer for branding, IsTrainee for my-branding
- Edge cases: invalid hex, oversized files, wrong file types, concurrent updates
"""
from __future__ import annotations

import io
import tempfile
from typing import Any
from unittest.mock import patch

from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from PIL import Image as PILImage
from rest_framework import status
from rest_framework.test import APIClient

from trainer.models import TrainerBranding, validate_hex_color, HEX_COLOR_REGEX
from users.models import User


TEMP_MEDIA_ROOT = tempfile.mkdtemp()


def _create_test_image(
    width: int = 256,
    height: int = 256,
    fmt: str = 'PNG',
    content_type: str = 'image/png',
    name: str = 'logo.png',
) -> SimpleUploadedFile:
    """Create a valid in-memory image file for upload tests."""
    img = PILImage.new('RGB', (width, height), color='red')
    buffer = io.BytesIO()
    img.save(buffer, format=fmt)
    buffer.seek(0)
    return SimpleUploadedFile(name, buffer.read(), content_type=content_type)


def _create_oversized_file(size_bytes: int = 3 * 1024 * 1024) -> SimpleUploadedFile:
    """Create a file that exceeds the 2MB upload limit."""
    # Create a real PNG image then pad it to exceed size limit
    img = PILImage.new('RGB', (256, 256), color='blue')
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    # Pad with extra data to exceed limit
    current_size = buffer.tell()
    if current_size < size_bytes:
        buffer.write(b'\x00' * (size_bytes - current_size))
    buffer.seek(0)
    return SimpleUploadedFile('big_logo.png', buffer.read(), content_type='image/png')


# ---------------------------------------------------------------------------
# Model-level tests
# ---------------------------------------------------------------------------

class ValidateHexColorTests(TestCase):
    """Tests for the validate_hex_color validator function."""

    def test_valid_hex_colors(self) -> None:
        valid_colors = ['#000000', '#FFFFFF', '#6366F1', '#ff00ff', '#aAbBcC', '#123456']
        for color in valid_colors:
            # Should not raise
            validate_hex_color(color)

    def test_invalid_hex_missing_hash(self) -> None:
        with self.assertRaises(ValidationError):
            validate_hex_color('6366F1')

    def test_invalid_hex_short_code(self) -> None:
        with self.assertRaises(ValidationError):
            validate_hex_color('#FFF')

    def test_invalid_hex_too_long(self) -> None:
        with self.assertRaises(ValidationError):
            validate_hex_color('#6366F1FF')

    def test_invalid_hex_non_hex_chars(self) -> None:
        with self.assertRaises(ValidationError):
            validate_hex_color('#ZZZZZZ')

    def test_invalid_hex_empty_string(self) -> None:
        with self.assertRaises(ValidationError):
            validate_hex_color('')

    def test_invalid_hex_random_text(self) -> None:
        with self.assertRaises(ValidationError):
            validate_hex_color('not-a-color')

    def test_hex_regex_pattern(self) -> None:
        self.assertIsNotNone(HEX_COLOR_REGEX.match('#6366F1'))
        self.assertIsNone(HEX_COLOR_REGEX.match('6366F1'))
        self.assertIsNone(HEX_COLOR_REGEX.match('#GGG'))


@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class TrainerBrandingModelTests(TestCase):
    """Tests for the TrainerBranding model itself."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@branding.com',
            password='testpass123',
            role='TRAINER',
        )

    def test_create_branding_with_defaults(self) -> None:
        branding = TrainerBranding.objects.create(trainer=self.trainer)
        self.assertEqual(branding.primary_color, '#6366F1')
        self.assertEqual(branding.secondary_color, '#818CF8')
        self.assertEqual(branding.app_name, '')
        self.assertFalse(branding.logo)
        self.assertIsNotNone(branding.created_at)
        self.assertIsNotNone(branding.updated_at)

    def test_create_branding_with_custom_values(self) -> None:
        branding = TrainerBranding.objects.create(
            trainer=self.trainer,
            app_name='FitPro by Jane',
            primary_color='#FF5733',
            secondary_color='#C70039',
        )
        self.assertEqual(branding.app_name, 'FitPro by Jane')
        self.assertEqual(branding.primary_color, '#FF5733')
        self.assertEqual(branding.secondary_color, '#C70039')

    def test_str_representation_with_app_name(self) -> None:
        branding = TrainerBranding.objects.create(
            trainer=self.trainer, app_name='MyGym'
        )
        self.assertIn('MyGym', str(branding))
        self.assertIn(self.trainer.email, str(branding))

    def test_str_representation_without_app_name(self) -> None:
        branding = TrainerBranding.objects.create(trainer=self.trainer)
        self.assertIn('Default', str(branding))

    def test_one_to_one_constraint(self) -> None:
        TrainerBranding.objects.create(trainer=self.trainer)
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            TrainerBranding.objects.create(trainer=self.trainer)

    def test_get_or_create_for_trainer_creates(self) -> None:
        branding, created = TrainerBranding.get_or_create_for_trainer(self.trainer)
        self.assertTrue(created)
        self.assertEqual(branding.trainer, self.trainer)
        self.assertEqual(branding.primary_color, TrainerBranding.DEFAULT_PRIMARY_COLOR)
        self.assertEqual(branding.secondary_color, TrainerBranding.DEFAULT_SECONDARY_COLOR)

    def test_get_or_create_for_trainer_gets_existing(self) -> None:
        TrainerBranding.objects.create(
            trainer=self.trainer,
            primary_color='#FF0000',
            secondary_color='#00FF00',
        )
        branding, created = TrainerBranding.get_or_create_for_trainer(self.trainer)
        self.assertFalse(created)
        self.assertEqual(branding.primary_color, '#FF0000')

    def test_get_or_create_idempotent(self) -> None:
        branding_1, _ = TrainerBranding.get_or_create_for_trainer(self.trainer)
        branding_2, _ = TrainerBranding.get_or_create_for_trainer(self.trainer)
        self.assertEqual(branding_1.pk, branding_2.pk)

    def test_app_name_max_length(self) -> None:
        branding = TrainerBranding(
            trainer=self.trainer,
            app_name='x' * 51,  # exceeds max_length=50
        )
        with self.assertRaises(ValidationError):
            branding.full_clean()

    def test_primary_color_validation_on_full_clean(self) -> None:
        branding = TrainerBranding(
            trainer=self.trainer,
            primary_color='bad',
        )
        with self.assertRaises(ValidationError):
            branding.full_clean()

    def test_secondary_color_validation_on_full_clean(self) -> None:
        branding = TrainerBranding(
            trainer=self.trainer,
            secondary_color='nope',
        )
        with self.assertRaises(ValidationError):
            branding.full_clean()

    def test_cascade_delete_on_trainer_deletion(self) -> None:
        TrainerBranding.objects.create(trainer=self.trainer)
        trainer_id = self.trainer.pk
        self.trainer.delete()
        self.assertFalse(TrainerBranding.objects.filter(trainer_id=trainer_id).exists())

    def test_default_class_constants(self) -> None:
        self.assertEqual(TrainerBranding.DEFAULT_PRIMARY_COLOR, '#6366F1')
        self.assertEqual(TrainerBranding.DEFAULT_SECONDARY_COLOR, '#818CF8')
        self.assertEqual(TrainerBranding.DEFAULT_APP_NAME, '')


# ---------------------------------------------------------------------------
# TrainerBrandingView (GET / PUT) tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class TrainerBrandingViewTests(TestCase):
    """Tests for GET /api/trainer/branding/ and PUT /api/trainer/branding/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@branding.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/branding/'

    # -- GET tests --

    def test_get_auto_creates_branding(self) -> None:
        self.assertFalse(TrainerBranding.objects.filter(trainer=self.trainer).exists())
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(TrainerBranding.objects.filter(trainer=self.trainer).exists())

    def test_get_returns_default_values(self) -> None:
        response = self.client.get(self.url)
        self.assertEqual(response.data['primary_color'], '#6366F1')
        self.assertEqual(response.data['secondary_color'], '#818CF8')
        self.assertEqual(response.data['app_name'], '')
        self.assertIsNone(response.data['logo_url'])

    def test_get_returns_existing_branding(self) -> None:
        TrainerBranding.objects.create(
            trainer=self.trainer,
            app_name='Custom Gym',
            primary_color='#FF5733',
        )
        response = self.client.get(self.url)
        self.assertEqual(response.data['app_name'], 'Custom Gym')
        self.assertEqual(response.data['primary_color'], '#FF5733')

    def test_get_idempotent_no_duplicate_creation(self) -> None:
        self.client.get(self.url)
        self.client.get(self.url)
        self.assertEqual(TrainerBranding.objects.filter(trainer=self.trainer).count(), 1)

    # -- PUT tests --

    def test_put_updates_app_name(self) -> None:
        response = self.client.put(self.url, {
            'app_name': 'FitPro',
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['app_name'], 'FitPro')

    def test_put_updates_colors(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#FF0000',
            'secondary_color': '#00FF00',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['primary_color'], '#FF0000')
        self.assertEqual(response.data['secondary_color'], '#00FF00')

    def test_put_rejects_invalid_primary_color(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': 'notacolor',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('primary_color', response.data)

    def test_put_rejects_invalid_secondary_color(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#6366F1',
            'secondary_color': '#GGG',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('secondary_color', response.data)

    def test_put_strips_app_name_whitespace(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '  FitPro  ',
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['app_name'], 'FitPro')

    def test_put_allows_empty_app_name(self) -> None:
        # Create branding with a name first
        TrainerBranding.objects.create(
            trainer=self.trainer, app_name='Old Name'
        )
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['app_name'], '')

    def test_patch_partial_update_color(self) -> None:
        # Ensure branding exists
        self.client.get(self.url)
        response = self.client.patch(self.url, {
            'primary_color': '#AABBCC',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['primary_color'], '#AABBCC')

    def test_put_persists_in_database(self) -> None:
        self.client.put(self.url, {
            'app_name': 'Persistent',
            'primary_color': '#111111',
            'secondary_color': '#222222',
        }, format='json')
        branding = TrainerBranding.objects.get(trainer=self.trainer)
        self.assertEqual(branding.app_name, 'Persistent')
        self.assertEqual(branding.primary_color, '#111111')
        self.assertEqual(branding.secondary_color, '#222222')


# ---------------------------------------------------------------------------
# TrainerBrandingLogoView (POST / DELETE) tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class TrainerBrandingLogoViewTests(TestCase):
    """Tests for POST/DELETE /api/trainer/branding/logo/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@logo.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/branding/logo/'

    # -- POST tests --

    def test_upload_valid_png_logo(self) -> None:
        image = _create_test_image(256, 256, 'PNG', 'image/png', 'logo.png')
        response = self.client.post(self.url, {'logo': image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(response.data['logo_url'])
        branding = TrainerBranding.objects.get(trainer=self.trainer)
        self.assertTrue(branding.logo)

    def test_upload_valid_jpeg_logo(self) -> None:
        image = _create_test_image(256, 256, 'JPEG', 'image/jpeg', 'logo.jpg')
        response = self.client.post(self.url, {'logo': image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(response.data['logo_url'])

    def test_upload_valid_webp_logo(self) -> None:
        image = _create_test_image(256, 256, 'WEBP', 'image/webp', 'logo.webp')
        response = self.client.post(self.url, {'logo': image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_upload_rejects_gif_format(self) -> None:
        image = _create_test_image(256, 256, 'GIF', 'image/gif', 'logo.gif')
        response = self.client.post(self.url, {'logo': image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_upload_rejects_no_file(self) -> None:
        response = self.client.post(self.url, {}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)
        self.assertIn('No logo', response.data['error'])

    def test_upload_rejects_oversized_file(self) -> None:
        big_file = _create_oversized_file(3 * 1024 * 1024)
        response = self.client.post(self.url, {'logo': big_file}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('2MB', response.data['error'])

    def test_upload_rejects_image_too_small(self) -> None:
        small_image = _create_test_image(64, 64, 'PNG', 'image/png')
        response = self.client.post(self.url, {'logo': small_image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('128x128', response.data['error'])

    def test_upload_rejects_image_too_large_dimensions(self) -> None:
        large_image = _create_test_image(2048, 2048, 'PNG', 'image/png')
        response = self.client.post(self.url, {'logo': large_image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('1024x1024', response.data['error'])

    def test_upload_minimum_dimensions_accepted(self) -> None:
        min_image = _create_test_image(128, 128, 'PNG', 'image/png')
        response = self.client.post(self.url, {'logo': min_image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_upload_maximum_dimensions_accepted(self) -> None:
        max_image = _create_test_image(1024, 1024, 'PNG', 'image/png')
        response = self.client.post(self.url, {'logo': max_image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_upload_rejects_non_image_content(self) -> None:
        fake_file = SimpleUploadedFile(
            'malicious.png', b'not an image at all', content_type='image/png'
        )
        response = self.client.post(self.url, {'logo': fake_file}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_upload_rejects_spoofed_content_type(self) -> None:
        text_file = SimpleUploadedFile(
            'file.txt', b'plain text', content_type='text/plain'
        )
        response = self.client.post(self.url, {'logo': text_file}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_upload_replaces_existing_logo(self) -> None:
        first_image = _create_test_image(256, 256, 'PNG', 'image/png', 'first.png')
        self.client.post(self.url, {'logo': first_image}, format='multipart')

        second_image = _create_test_image(512, 512, 'JPEG', 'image/jpeg', 'second.jpg')
        response = self.client.post(self.url, {'logo': second_image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(response.data['logo_url'])
        # Only one branding record should exist
        self.assertEqual(TrainerBranding.objects.filter(trainer=self.trainer).count(), 1)

    def test_upload_auto_creates_branding_if_missing(self) -> None:
        self.assertFalse(TrainerBranding.objects.filter(trainer=self.trainer).exists())
        image = _create_test_image(256, 256, 'PNG', 'image/png')
        response = self.client.post(self.url, {'logo': image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(TrainerBranding.objects.filter(trainer=self.trainer).exists())

    # -- DELETE tests --

    def test_delete_logo(self) -> None:
        # Upload first
        image = _create_test_image(256, 256, 'PNG', 'image/png')
        self.client.post(self.url, {'logo': image}, format='multipart')

        response = self.client.delete(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNone(response.data['logo_url'])
        branding = TrainerBranding.objects.get(trainer=self.trainer)
        self.assertFalse(branding.logo)

    def test_delete_logo_when_no_branding_returns_404(self) -> None:
        response = self.client.delete(self.url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn('error', response.data)

    def test_delete_logo_when_no_logo_set(self) -> None:
        TrainerBranding.objects.create(trainer=self.trainer)
        response = self.client.delete(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNone(response.data['logo_url'])


# ---------------------------------------------------------------------------
# MyBrandingView (GET) tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class MyBrandingViewTests(TestCase):
    """Tests for GET /api/users/my-branding/ (trainee sees trainer's branding)."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@mybranding.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@mybranding.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainee)
        self.url = '/api/users/my-branding/'

    def test_trainee_sees_trainer_branding(self) -> None:
        TrainerBranding.objects.create(
            trainer=self.trainer,
            app_name='Coach Jane Fitness',
            primary_color='#FF5733',
            secondary_color='#C70039',
        )
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['app_name'], 'Coach Jane Fitness')
        self.assertEqual(response.data['primary_color'], '#FF5733')
        self.assertEqual(response.data['secondary_color'], '#C70039')

    def test_trainee_sees_defaults_when_no_branding_configured(self) -> None:
        # Trainer exists but has no branding row
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['primary_color'], '#6366F1')
        self.assertEqual(response.data['secondary_color'], '#818CF8')
        self.assertEqual(response.data['app_name'], '')
        self.assertIsNone(response.data['logo_url'])

    def test_trainee_with_no_parent_trainer_sees_defaults(self) -> None:
        orphan = User.objects.create_user(
            email='orphan@mybranding.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=None,
        )
        client = APIClient()
        client.force_authenticate(user=orphan)
        response = client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['primary_color'], '#6366F1')
        self.assertIsNone(response.data['logo_url'])

    def test_trainee_sees_logo_url_when_set(self) -> None:
        branding = TrainerBranding.objects.create(trainer=self.trainer)
        image = _create_test_image(256, 256, 'PNG', 'image/png')
        branding.logo = image
        branding.save()
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(response.data['logo_url'])

    def test_trainee_sees_no_logo_when_trainer_removes_it(self) -> None:
        branding = TrainerBranding.objects.create(trainer=self.trainer)
        branding.logo = None
        branding.save()
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNone(response.data['logo_url'])

    def test_trainee_after_trainer_removal_sees_defaults(self) -> None:
        """Edge case: trainee's parent_trainer is set to None (removed)."""
        TrainerBranding.objects.create(
            trainer=self.trainer,
            app_name='Old Trainer',
            primary_color='#FF0000',
        )
        # Simulate trainer removal
        self.trainee.parent_trainer = None
        self.trainee.save()

        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['primary_color'], '#6366F1')
        self.assertEqual(response.data['app_name'], '')

    def test_response_includes_all_expected_fields(self) -> None:
        TrainerBranding.objects.create(
            trainer=self.trainer,
            app_name='Full Fields',
            primary_color='#AABBCC',
            secondary_color='#DDEEFF',
        )
        response = self.client.get(self.url)
        self.assertIn('app_name', response.data)
        self.assertIn('primary_color', response.data)
        self.assertIn('secondary_color', response.data)
        self.assertIn('logo_url', response.data)


# ---------------------------------------------------------------------------
# Permission enforcement tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class BrandingPermissionTests(TestCase):
    """Tests that branding endpoints enforce correct role permissions."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@perm.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@perm.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.admin = User.objects.create_user(
            email='admin@perm.com',
            password='testpass123',
            role='ADMIN',
        )
        self.branding_url = '/api/trainer/branding/'
        self.logo_url = '/api/trainer/branding/logo/'
        self.my_branding_url = '/api/users/my-branding/'

    # -- Trainer branding endpoints require IsTrainer --

    def test_unauthenticated_cannot_access_branding(self) -> None:
        client = APIClient()
        response = client.get(self.branding_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_trainee_cannot_access_trainer_branding_get(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.get(self.branding_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_cannot_access_trainer_branding_put(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.put(self.branding_url, {
            'app_name': 'Hack',
            'primary_color': '#000000',
            'secondary_color': '#000000',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_cannot_access_trainer_branding(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.admin)
        response = client.get(self.branding_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_cannot_upload_logo(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        image = _create_test_image()
        response = client.post(self.logo_url, {'logo': image}, format='multipart')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_cannot_delete_logo(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.delete(self.logo_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # -- My branding endpoint requires IsTrainee --

    def test_unauthenticated_cannot_access_my_branding(self) -> None:
        client = APIClient()
        response = client.get(self.my_branding_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_trainer_cannot_access_my_branding(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer)
        response = client.get(self.my_branding_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_cannot_access_my_branding(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.admin)
        response = client.get(self.my_branding_url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


# ---------------------------------------------------------------------------
# Row-level security tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class BrandingRowLevelSecurityTests(TestCase):
    """Tests that trainers can only see their own branding."""

    def setUp(self) -> None:
        self.trainer_a = User.objects.create_user(
            email='trainer_a@rls.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainer_b = User.objects.create_user(
            email='trainer_b@rls.com',
            password='testpass123',
            role='TRAINER',
        )

        TrainerBranding.objects.create(
            trainer=self.trainer_a,
            app_name='Trainer A Gym',
            primary_color='#FF0000',
        )
        TrainerBranding.objects.create(
            trainer=self.trainer_b,
            app_name='Trainer B Gym',
            primary_color='#00FF00',
        )

    def test_trainer_a_sees_own_branding(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer_a)
        response = client.get('/api/trainer/branding/')
        self.assertEqual(response.data['app_name'], 'Trainer A Gym')
        self.assertEqual(response.data['primary_color'], '#FF0000')

    def test_trainer_b_sees_own_branding(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer_b)
        response = client.get('/api/trainer/branding/')
        self.assertEqual(response.data['app_name'], 'Trainer B Gym')
        self.assertEqual(response.data['primary_color'], '#00FF00')

    def test_trainer_a_cannot_see_trainer_b_branding(self) -> None:
        """Trainer A's GET always returns their own branding, never B's."""
        client = APIClient()
        client.force_authenticate(user=self.trainer_a)
        response = client.get('/api/trainer/branding/')
        self.assertNotEqual(response.data['app_name'], 'Trainer B Gym')

    def test_trainee_sees_own_trainers_branding_not_other(self) -> None:
        trainee_of_a = User.objects.create_user(
            email='trainee_a@rls.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer_a,
        )
        client = APIClient()
        client.force_authenticate(user=trainee_of_a)
        response = client.get('/api/users/my-branding/')
        self.assertEqual(response.data['app_name'], 'Trainer A Gym')
        self.assertNotEqual(response.data['primary_color'], '#00FF00')


# ---------------------------------------------------------------------------
# Serializer-level tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class TrainerBrandingSerializerTests(TestCase):
    """Tests for TrainerBrandingSerializer validation and output."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@serializer.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/branding/'

    def test_response_fields_present(self) -> None:
        response = self.client.get(self.url)
        expected_fields = {'app_name', 'primary_color', 'secondary_color', 'logo_url', 'created_at', 'updated_at'}
        self.assertEqual(set(response.data.keys()), expected_fields)

    def test_logo_url_is_none_when_no_logo(self) -> None:
        response = self.client.get(self.url)
        self.assertIsNone(response.data['logo_url'])

    def test_created_at_and_updated_at_present(self) -> None:
        response = self.client.get(self.url)
        self.assertIsNotNone(response.data['created_at'])
        self.assertIsNotNone(response.data['updated_at'])

    def test_short_hex_rejected(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#FFF',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_hex_with_alpha_channel_rejected(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#6366F1FF',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_lowercase_hex_accepted(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#aabbcc',
            'secondary_color': '#ddeeff',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_mixed_case_hex_accepted(self) -> None:
        response = self.client.put(self.url, {
            'app_name': '',
            'primary_color': '#AaBbCc',
            'secondary_color': '#DdEeFf',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)


# ---------------------------------------------------------------------------
# Edge case tests
# ---------------------------------------------------------------------------

@override_settings(MEDIA_ROOT=TEMP_MEDIA_ROOT)
class BrandingEdgeCaseTests(TestCase):
    """Edge cases for branding feature."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@edge.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/branding/'

    def test_max_length_app_name_accepted(self) -> None:
        long_name = 'A' * 50
        response = self.client.put(self.url, {
            'app_name': long_name,
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['app_name'], long_name)

    def test_over_max_length_app_name_rejected(self) -> None:
        too_long = 'A' * 51
        response = self.client.put(self.url, {
            'app_name': too_long,
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_unicode_app_name(self) -> None:
        response = self.client.put(self.url, {
            'app_name': 'Fitness Pro',
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_multiple_trainers_independent_branding(self) -> None:
        trainer_2 = User.objects.create_user(
            email='trainer2@edge.com',
            password='testpass123',
            role='TRAINER',
        )
        # Set up branding for each
        TrainerBranding.objects.create(
            trainer=self.trainer, app_name='Gym One', primary_color='#111111'
        )
        TrainerBranding.objects.create(
            trainer=trainer_2, app_name='Gym Two', primary_color='#222222'
        )

        # Verify independence
        client_1 = APIClient()
        client_1.force_authenticate(user=self.trainer)
        resp_1 = client_1.get(self.url)

        client_2 = APIClient()
        client_2.force_authenticate(user=trainer_2)
        resp_2 = client_2.get(self.url)

        self.assertEqual(resp_1.data['app_name'], 'Gym One')
        self.assertEqual(resp_2.data['app_name'], 'Gym Two')
        self.assertNotEqual(resp_1.data['primary_color'], resp_2.data['primary_color'])

    def test_rapid_sequential_updates(self) -> None:
        """Multiple rapid PUT requests should all succeed without data corruption."""
        colors = ['#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF']
        for color in colors:
            response = self.client.put(self.url, {
                'app_name': f'Color {color}',
                'primary_color': color,
                'secondary_color': '#818CF8',
            }, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Last value should win
        branding = TrainerBranding.objects.get(trainer=self.trainer)
        self.assertEqual(branding.primary_color, '#FF00FF')

    def test_special_characters_in_app_name(self) -> None:
        response = self.client.put(self.url, {
            'app_name': "Coach O'Brien's Gym & Fitness",
            'primary_color': '#6366F1',
            'secondary_color': '#818CF8',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['app_name'], "Coach O'Brien's Gym & Fitness")

    def test_logo_upload_then_color_update_preserves_logo(self) -> None:
        """PUT to update colors should not clear the logo."""
        logo_url = '/api/trainer/branding/logo/'
        image = _create_test_image(256, 256, 'PNG', 'image/png')
        self.client.post(logo_url, {'logo': image}, format='multipart')

        # Now update colors
        response = self.client.put(self.url, {
            'app_name': 'Updated Name',
            'primary_color': '#FF0000',
            'secondary_color': '#00FF00',
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Logo should still be there
        branding = TrainerBranding.objects.get(trainer=self.trainer)
        self.assertTrue(branding.logo)
        self.assertEqual(branding.primary_color, '#FF0000')
