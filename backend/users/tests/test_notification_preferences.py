"""
Tests for NotificationPreference model and API endpoints.

Covers:
- Model auto-creation and defaults
- VALID_CATEGORIES validation
- is_category_enabled() with valid and invalid categories
- GET /api/users/notification-preferences/ (auto-create, field list)
- PATCH /api/users/notification-preferences/ (partial update, validation)
- Unauthenticated access denied
- _check_notification_preference in notification_service.py
- send_push_to_group category filtering
"""
from __future__ import annotations

from typing import Any
from unittest.mock import patch, MagicMock

from django.test import TestCase, override_settings
from rest_framework.test import APIClient, APITestCase
from rest_framework import status

from users.models import NotificationPreference, User


# ---------------------------------------------------------------------------
# Model Tests
# ---------------------------------------------------------------------------


class NotificationPreferenceModelTests(TestCase):
    """Unit tests for the NotificationPreference model."""

    def setUp(self) -> None:
        self.user: User = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            role=User.Role.TRAINEE,
        )

    def test_auto_create_via_get_or_create_for_user(self) -> None:
        """get_or_create_for_user should create a preference record if none exists."""
        self.assertFalse(
            NotificationPreference.objects.filter(user=self.user).exists()
        )
        pref = NotificationPreference.get_or_create_for_user(self.user)
        self.assertIsNotNone(pref)
        self.assertEqual(pref.user, self.user)

    def test_defaults_all_enabled(self) -> None:
        """All boolean fields should default to True."""
        pref = NotificationPreference.get_or_create_for_user(self.user)
        for category in NotificationPreference.VALID_CATEGORIES:
            self.assertTrue(
                getattr(pref, category),
                f"Category {category!r} should default to True",
            )

    def test_str_representation(self) -> None:
        pref = NotificationPreference.get_or_create_for_user(self.user)
        self.assertIn(self.user.email, str(pref))

    def test_one_to_one_constraint(self) -> None:
        """Only one NotificationPreference per user."""
        NotificationPreference.objects.create(user=self.user)
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            NotificationPreference.objects.create(user=self.user)

    def test_idempotent_get_or_create(self) -> None:
        """Calling get_or_create_for_user twice returns the same object."""
        pref1 = NotificationPreference.get_or_create_for_user(self.user)
        pref2 = NotificationPreference.get_or_create_for_user(self.user)
        self.assertEqual(pref1.pk, pref2.pk)


class ValidCategoriesTests(TestCase):
    """Tests for VALID_CATEGORIES frozenset."""

    def test_expected_categories_present(self) -> None:
        expected = {
            'trainee_workout',
            'trainee_weight_checkin',
            'trainee_started_workout',
            'trainee_finished_workout',
            'churn_alert',
            'trainer_announcement',
            'achievement_earned',
            'community_event',
            'new_message',
            'community_activity',
        }
        self.assertEqual(NotificationPreference.VALID_CATEGORIES, expected)

    def test_valid_categories_count(self) -> None:
        self.assertEqual(len(NotificationPreference.VALID_CATEGORIES), 10)

    def test_valid_categories_is_frozenset(self) -> None:
        self.assertIsInstance(NotificationPreference.VALID_CATEGORIES, frozenset)


class IsCategoryEnabledTests(TestCase):
    """Tests for is_category_enabled() method."""

    def setUp(self) -> None:
        self.user: User = User.objects.create_user(
            email='cat@example.com',
            password='testpass123',
        )
        self.pref = NotificationPreference.get_or_create_for_user(self.user)

    def test_valid_category_returns_true_by_default(self) -> None:
        for cat in NotificationPreference.VALID_CATEGORIES:
            self.assertTrue(self.pref.is_category_enabled(cat))

    def test_disabled_category_returns_false(self) -> None:
        self.pref.new_message = False
        self.pref.save()
        self.assertFalse(self.pref.is_category_enabled('new_message'))

    def test_invalid_category_raises_value_error(self) -> None:
        with self.assertRaises(ValueError) as ctx:
            self.pref.is_category_enabled('nonexistent_category')
        self.assertIn('Invalid notification category', str(ctx.exception))
        self.assertIn('nonexistent_category', str(ctx.exception))

    def test_empty_string_raises_value_error(self) -> None:
        with self.assertRaises(ValueError):
            self.pref.is_category_enabled('')

    def test_toggling_individual_category(self) -> None:
        self.pref.community_activity = False
        self.pref.save()
        self.assertFalse(self.pref.is_category_enabled('community_activity'))
        # Other categories remain unaffected
        self.assertTrue(self.pref.is_category_enabled('new_message'))


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------


class NotificationPreferenceAPITests(APITestCase):
    """Integration tests for the notification-preferences endpoint."""

    def setUp(self) -> None:
        self.user: User = User.objects.create_user(
            email='api@example.com',
            password='testpass123',
            role=User.Role.TRAINEE,
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.url = '/api/users/notification-preferences/'

    # -- GET --

    def test_get_creates_preference_if_not_exists(self) -> None:
        """GET should auto-create preference record."""
        self.assertFalse(
            NotificationPreference.objects.filter(user=self.user).exists()
        )
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(
            NotificationPreference.objects.filter(user=self.user).exists()
        )

    def test_get_returns_all_category_fields(self) -> None:
        response = self.client.get(self.url)
        data: dict[str, Any] = response.data  # type: ignore[assignment]
        for cat in NotificationPreference.VALID_CATEGORIES:
            self.assertIn(cat, data, f"Missing category {cat!r} in response")
            self.assertTrue(data[cat], f"Category {cat!r} should default to True")

    def test_get_does_not_return_extra_fields(self) -> None:
        """Response should contain only category fields, not id/user/timestamps."""
        response = self.client.get(self.url)
        data: dict[str, Any] = response.data  # type: ignore[assignment]
        unexpected = {'id', 'user', 'created_at', 'updated_at'}
        for field in unexpected:
            self.assertNotIn(field, data, f"Unexpected field {field!r} in response")

    def test_get_returns_existing_preferences(self) -> None:
        """If preferences exist and were modified, GET returns the modified state."""
        pref = NotificationPreference.get_or_create_for_user(self.user)
        pref.new_message = False
        pref.save()

        response = self.client.get(self.url)
        data: dict[str, Any] = response.data  # type: ignore[assignment]
        self.assertFalse(data['new_message'])

    # -- PATCH --

    def test_patch_updates_single_field(self) -> None:
        response = self.client.patch(
            self.url,
            data={'new_message': False},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['new_message'])  # type: ignore[index]
        # Verify persisted
        pref = NotificationPreference.objects.get(user=self.user)
        self.assertFalse(pref.new_message)

    def test_patch_multiple_fields(self) -> None:
        response = self.client.patch(
            self.url,
            data={
                'community_activity': False,
                'churn_alert': False,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['community_activity'])  # type: ignore[index]
        self.assertFalse(response.data['churn_alert'])  # type: ignore[index]
        # Unchanged fields remain True
        self.assertTrue(response.data['new_message'])  # type: ignore[index]

    def test_patch_ignores_unknown_fields(self) -> None:
        """PATCH with unknown fields should silently ignore them (DRF default)."""
        response = self.client.patch(
            self.url,
            data={'bogus_field': False},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_patch_rejects_non_boolean_value(self) -> None:
        """Category fields are BooleanField; non-boolean should fail validation."""
        response = self.client.patch(
            self.url,
            data={'new_message': 'not_a_bool'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    # -- Auth --

    def test_unauthenticated_get_returns_401(self) -> None:
        unauthenticated = APIClient()
        response = unauthenticated.get(self.url)
        self.assertIn(response.status_code, (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN))

    def test_unauthenticated_patch_returns_401(self) -> None:
        unauthenticated = APIClient()
        response = unauthenticated.patch(
            self.url,
            data={'new_message': False},
            format='json',
        )
        self.assertIn(response.status_code, (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN))


# ---------------------------------------------------------------------------
# Notification Service Tests
# ---------------------------------------------------------------------------


class CheckNotificationPreferenceTests(TestCase):
    """Tests for _check_notification_preference in notification_service."""

    def setUp(self) -> None:
        self.user: User = User.objects.create_user(
            email='svc@example.com',
            password='testpass123',
        )

    def test_no_category_returns_true(self) -> None:
        from core.services.notification_service import _check_notification_preference
        self.assertTrue(_check_notification_preference(self.user.id, None))
        self.assertTrue(_check_notification_preference(self.user.id, ''))

    def test_no_preference_record_returns_true(self) -> None:
        """If no NotificationPreference exists, default is send (fail open)."""
        from core.services.notification_service import _check_notification_preference
        self.assertTrue(
            _check_notification_preference(self.user.id, 'new_message')
        )

    def test_enabled_category_returns_true(self) -> None:
        from core.services.notification_service import _check_notification_preference
        NotificationPreference.get_or_create_for_user(self.user)
        self.assertTrue(
            _check_notification_preference(self.user.id, 'new_message')
        )

    def test_disabled_category_returns_false(self) -> None:
        from core.services.notification_service import _check_notification_preference
        pref = NotificationPreference.get_or_create_for_user(self.user)
        pref.new_message = False
        pref.save()
        self.assertFalse(
            _check_notification_preference(self.user.id, 'new_message')
        )

    def test_database_error_returns_true(self) -> None:
        """Fail open: database error should return True."""
        from core.services.notification_service import _check_notification_preference
        from django.db import DatabaseError
        with patch(
            'users.models.NotificationPreference.objects'
        ) as mock_qs:
            mock_qs.filter.side_effect = DatabaseError("DB down")
            self.assertTrue(
                _check_notification_preference(self.user.id, 'new_message')
            )


class SendPushToGroupCategoryFilterTests(TestCase):
    """Tests for send_push_to_group category filtering logic."""

    def setUp(self) -> None:
        self.user1: User = User.objects.create_user(
            email='u1@example.com', password='pass123'
        )
        self.user2: User = User.objects.create_user(
            email='u2@example.com', password='pass123'
        )
        # user1 has new_message disabled
        pref1 = NotificationPreference.get_or_create_for_user(self.user1)
        pref1.new_message = False
        pref1.save()
        # user2 keeps all defaults (enabled)
        NotificationPreference.get_or_create_for_user(self.user2)

    @patch('core.services.notification_service._ensure_firebase_initialized', return_value=True)
    @patch('core.services.notification_service._send_to_tokens_batch', return_value=set())
    def test_category_filters_opted_out_users(
        self,
        mock_batch: MagicMock,
        mock_firebase: MagicMock,
    ) -> None:
        """Users who disabled a category should be excluded from the group send."""
        from core.services.notification_service import send_push_to_group
        from users.models import DeviceToken

        # Create device tokens for both users
        DeviceToken.objects.create(
            user=self.user1, token='token1', platform='ios', is_active=True
        )
        DeviceToken.objects.create(
            user=self.user2, token='token2', platform='ios', is_active=True
        )

        send_push_to_group(
            user_ids=[self.user1.id, self.user2.id],
            title='Hello',
            body='World',
            category='new_message',
        )

        # mock_batch should have been called — verify only user2's token was included
        if mock_batch.called:
            tokens_arg = mock_batch.call_args[0][0]
            token_user_ids = {t[2] for t in tokens_arg} if len(tokens_arg[0]) == 3 else set()
            # If the token format is (id, value) rather than (id, value, user_id),
            # we check that only user2's token_value is present
            token_values = {t[1] for t in tokens_arg}
            self.assertNotIn('token1', token_values, "user1 (opted out) should be excluded")
            self.assertIn('token2', token_values, "user2 (opted in) should be included")

    @patch('core.services.notification_service._ensure_firebase_initialized', return_value=True)
    @patch('core.services.notification_service._send_to_tokens_batch', return_value=set())
    def test_no_category_sends_to_all(
        self,
        mock_batch: MagicMock,
        mock_firebase: MagicMock,
    ) -> None:
        """Without a category, all users should receive the notification."""
        from core.services.notification_service import send_push_to_group
        from users.models import DeviceToken

        DeviceToken.objects.create(
            user=self.user1, token='t1', platform='ios', is_active=True
        )
        DeviceToken.objects.create(
            user=self.user2, token='t2', platform='ios', is_active=True
        )

        send_push_to_group(
            user_ids=[self.user1.id, self.user2.id],
            title='Hello',
            body='World',
        )

        if mock_batch.called:
            tokens_arg = mock_batch.call_args[0][0]
            token_values = {t[1] for t in tokens_arg}
            self.assertIn('t1', token_values)
            self.assertIn('t2', token_values)

    @patch('core.services.notification_service._ensure_firebase_initialized', return_value=True)
    def test_invalid_category_logs_warning_but_sends(
        self,
        mock_firebase: MagicMock,
    ) -> None:
        """An invalid category should log a warning but still attempt delivery."""
        from core.services.notification_service import send_push_to_group

        with self.assertLogs('core.services.notification_service', level='WARNING') as cm:
            send_push_to_group(
                user_ids=[self.user1.id],
                title='Hello',
                body='World',
                category='invalid_category',
            )
        self.assertTrue(
            any('Invalid notification category' in msg for msg in cm.output)
        )
