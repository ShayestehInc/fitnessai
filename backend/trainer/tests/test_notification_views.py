"""
Tests for Trainer Notification endpoints.

Covers:
- NotificationListView: GET /api/trainer/notifications/ (paginated, newest first, is_read filter)
- UnreadCountView: GET /api/trainer/notifications/unread-count/
- MarkNotificationReadView: POST /api/trainer/notifications/<pk>/read/
- MarkAllReadView: POST /api/trainer/notifications/mark-all-read/
- DeleteNotificationView: DELETE /api/trainer/notifications/<pk>/
- Auth/Permission enforcement (unauthenticated, non-trainer role)
- Row-level security (trainer A cannot access trainer B's notifications)
- Pagination
- Mark-read idempotency
- Edge cases (empty data, concurrent mark-all-read, etc.)
"""
from __future__ import annotations

import time
from datetime import timedelta
from typing import Any

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from trainer.models import TrainerNotification
from users.models import User


def _create_notification(
    trainer: User,
    *,
    notification_type: str = TrainerNotification.NotificationType.GENERAL,
    title: str = 'Test notification',
    message: str = 'Test message body',
    data: dict[str, Any] | None = None,
    is_read: bool = False,
) -> TrainerNotification:
    """Helper to create a TrainerNotification for tests."""
    return TrainerNotification.objects.create(
        trainer=trainer,
        notification_type=notification_type,
        title=title,
        message=message,
        data=data or {},
        is_read=is_read,
        read_at=timezone.now() if is_read else None,
    )


# ---------------------------------------------------------------------------
# NotificationListView tests
# ---------------------------------------------------------------------------

class NotificationListViewTests(TestCase):
    """Tests for GET /api/trainer/notifications/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@notif.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/notifications/'

    def test_list_returns_200(self) -> None:
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_list_empty_returns_empty_results(self) -> None:
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['results'], [])
        self.assertEqual(response.data['count'], 0)

    def test_list_returns_notifications(self) -> None:
        _create_notification(self.trainer, title='Notification A')
        _create_notification(self.trainer, title='Notification B')
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 2)
        self.assertEqual(len(response.data['results']), 2)

    def test_list_newest_first(self) -> None:
        n1 = _create_notification(self.trainer, title='Older')
        n2 = _create_notification(self.trainer, title='Newer')
        response = self.client.get(self.url)
        results = response.data['results']
        self.assertEqual(results[0]['id'], n2.id)
        self.assertEqual(results[1]['id'], n1.id)

    def test_list_includes_expected_fields(self) -> None:
        _create_notification(
            self.trainer,
            notification_type=TrainerNotification.NotificationType.WORKOUT_COMPLETED,
            title='Workout Done',
            message='John finished leg day',
            data={'trainee_id': 42},
        )
        response = self.client.get(self.url)
        item = response.data['results'][0]
        expected_fields = {
            'id', 'notification_type', 'title', 'message',
            'data', 'is_read', 'read_at', 'created_at',
        }
        self.assertEqual(set(item.keys()), expected_fields)

    def test_list_filter_is_read_true(self) -> None:
        _create_notification(self.trainer, title='Unread', is_read=False)
        _create_notification(self.trainer, title='Read', is_read=True)
        response = self.client.get(self.url, {'is_read': 'true'})
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['title'], 'Read')

    def test_list_filter_is_read_false(self) -> None:
        _create_notification(self.trainer, title='Unread', is_read=False)
        _create_notification(self.trainer, title='Read', is_read=True)
        response = self.client.get(self.url, {'is_read': 'false'})
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['title'], 'Unread')

    def test_list_filter_is_read_1_means_true(self) -> None:
        _create_notification(self.trainer, title='Unread', is_read=False)
        _create_notification(self.trainer, title='Read', is_read=True)
        response = self.client.get(self.url, {'is_read': '1'})
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['title'], 'Read')

    def test_list_filter_is_read_yes_means_true(self) -> None:
        _create_notification(self.trainer, title='Unread', is_read=False)
        _create_notification(self.trainer, title='Read', is_read=True)
        response = self.client.get(self.url, {'is_read': 'yes'})
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['title'], 'Read')

    def test_list_no_filter_returns_all(self) -> None:
        _create_notification(self.trainer, title='Unread', is_read=False)
        _create_notification(self.trainer, title='Read', is_read=True)
        response = self.client.get(self.url)
        self.assertEqual(response.data['count'], 2)

    def test_list_pagination_default_page_size_20(self) -> None:
        for i in range(25):
            _create_notification(self.trainer, title=f'Notif {i}')
        response = self.client.get(self.url)
        self.assertEqual(response.data['count'], 25)
        self.assertEqual(len(response.data['results']), 20)
        self.assertIsNotNone(response.data['next'])

    def test_list_pagination_second_page(self) -> None:
        for i in range(25):
            _create_notification(self.trainer, title=f'Notif {i}')
        response = self.client.get(self.url, {'page': 2})
        self.assertEqual(response.data['count'], 25)
        self.assertEqual(len(response.data['results']), 5)
        self.assertIsNone(response.data['next'])

    def test_list_pagination_custom_page_size(self) -> None:
        for i in range(10):
            _create_notification(self.trainer, title=f'Notif {i}')
        response = self.client.get(self.url, {'page_size': 5})
        self.assertEqual(response.data['count'], 10)
        self.assertEqual(len(response.data['results']), 5)

    def test_list_pagination_max_page_size_50(self) -> None:
        for i in range(60):
            _create_notification(self.trainer, title=f'Notif {i}')
        response = self.client.get(self.url, {'page_size': 100})
        # Should be capped at 50
        self.assertEqual(len(response.data['results']), 50)

    def test_list_data_field_populated(self) -> None:
        _create_notification(
            self.trainer,
            data={'trainee_id': 99, 'action': 'completed_workout'},
        )
        response = self.client.get(self.url)
        item = response.data['results'][0]
        self.assertEqual(item['data']['trainee_id'], 99)
        self.assertEqual(item['data']['action'], 'completed_workout')

    def test_list_read_at_null_for_unread(self) -> None:
        _create_notification(self.trainer, is_read=False)
        response = self.client.get(self.url)
        self.assertIsNone(response.data['results'][0]['read_at'])

    def test_list_read_at_set_for_read(self) -> None:
        _create_notification(self.trainer, is_read=True)
        response = self.client.get(self.url)
        self.assertIsNotNone(response.data['results'][0]['read_at'])


# ---------------------------------------------------------------------------
# UnreadCountView tests
# ---------------------------------------------------------------------------

class UnreadCountViewTests(TestCase):
    """Tests for GET /api/trainer/notifications/unread-count/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@unread.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/notifications/unread-count/'

    def test_unread_count_zero_when_no_notifications(self) -> None:
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['unread_count'], 0)

    def test_unread_count_reflects_unread_only(self) -> None:
        _create_notification(self.trainer, is_read=False)
        _create_notification(self.trainer, is_read=False)
        _create_notification(self.trainer, is_read=True)
        response = self.client.get(self.url)
        self.assertEqual(response.data['unread_count'], 2)

    def test_unread_count_all_read_returns_zero(self) -> None:
        _create_notification(self.trainer, is_read=True)
        _create_notification(self.trainer, is_read=True)
        response = self.client.get(self.url)
        self.assertEqual(response.data['unread_count'], 0)

    def test_unread_count_response_format(self) -> None:
        response = self.client.get(self.url)
        self.assertIn('unread_count', response.data)
        self.assertIsInstance(response.data['unread_count'], int)


# ---------------------------------------------------------------------------
# MarkNotificationReadView tests
# ---------------------------------------------------------------------------

class MarkNotificationReadViewTests(TestCase):
    """Tests for POST /api/trainer/notifications/<pk>/read/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@read.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)

    def _url(self, pk: int) -> str:
        return f'/api/trainer/notifications/{pk}/read/'

    def test_mark_unread_as_read(self) -> None:
        notif = _create_notification(self.trainer, is_read=False)
        response = self.client.post(self._url(notif.pk))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        notif.refresh_from_db()
        self.assertTrue(notif.is_read)
        self.assertIsNotNone(notif.read_at)

    def test_mark_read_returns_updated_notification(self) -> None:
        notif = _create_notification(self.trainer, is_read=False, title='Check')
        response = self.client.post(self._url(notif.pk))
        self.assertEqual(response.data['title'], 'Check')
        self.assertTrue(response.data['is_read'])
        self.assertIsNotNone(response.data['read_at'])

    def test_mark_read_idempotent(self) -> None:
        """Marking an already-read notification should succeed without error."""
        notif = _create_notification(self.trainer, is_read=True)
        original_read_at = notif.read_at
        response = self.client.post(self._url(notif.pk))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        notif.refresh_from_db()
        self.assertTrue(notif.is_read)
        # read_at should NOT change on re-mark
        self.assertEqual(notif.read_at, original_read_at)

    def test_mark_read_nonexistent_returns_404(self) -> None:
        response = self.client.post(self._url(99999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn('error', response.data)

    def test_mark_read_decrements_unread_count(self) -> None:
        n1 = _create_notification(self.trainer, is_read=False)
        _create_notification(self.trainer, is_read=False)

        count_url = '/api/trainer/notifications/unread-count/'
        response = self.client.get(count_url)
        self.assertEqual(response.data['unread_count'], 2)

        self.client.post(self._url(n1.pk))

        response = self.client.get(count_url)
        self.assertEqual(response.data['unread_count'], 1)


# ---------------------------------------------------------------------------
# MarkAllReadView tests
# ---------------------------------------------------------------------------

class MarkAllReadViewTests(TestCase):
    """Tests for POST /api/trainer/notifications/mark-all-read/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@markall.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)
        self.url = '/api/trainer/notifications/mark-all-read/'

    def test_mark_all_read_multiple(self) -> None:
        for _ in range(5):
            _create_notification(self.trainer, is_read=False)
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['marked_count'], 5)

        # Verify all are now read
        unread = TrainerNotification.objects.filter(
            trainer=self.trainer, is_read=False,
        ).count()
        self.assertEqual(unread, 0)

    def test_mark_all_read_skips_already_read(self) -> None:
        _create_notification(self.trainer, is_read=False)
        _create_notification(self.trainer, is_read=True)
        response = self.client.post(self.url)
        self.assertEqual(response.data['marked_count'], 1)

    def test_mark_all_read_with_no_unread(self) -> None:
        _create_notification(self.trainer, is_read=True)
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['marked_count'], 0)

    def test_mark_all_read_with_no_notifications(self) -> None:
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['marked_count'], 0)

    def test_mark_all_read_sets_read_at(self) -> None:
        _create_notification(self.trainer, is_read=False)
        _create_notification(self.trainer, is_read=False)
        self.client.post(self.url)
        for notif in TrainerNotification.objects.filter(trainer=self.trainer):
            self.assertTrue(notif.is_read)
            self.assertIsNotNone(notif.read_at)

    def test_mark_all_read_concurrent_safe(self) -> None:
        """Second call to mark-all-read should mark 0 (already done)."""
        for _ in range(3):
            _create_notification(self.trainer, is_read=False)
        resp1 = self.client.post(self.url)
        self.assertEqual(resp1.data['marked_count'], 3)
        resp2 = self.client.post(self.url)
        self.assertEqual(resp2.data['marked_count'], 0)

    def test_mark_all_read_does_not_affect_other_trainer(self) -> None:
        other_trainer = User.objects.create_user(
            email='other@markall.com',
            password='testpass123',
            role='TRAINER',
        )
        _create_notification(self.trainer, is_read=False)
        _create_notification(other_trainer, is_read=False)

        self.client.post(self.url)

        # Other trainer's notification should still be unread
        other_unread = TrainerNotification.objects.filter(
            trainer=other_trainer, is_read=False,
        ).count()
        self.assertEqual(other_unread, 1)


# ---------------------------------------------------------------------------
# DeleteNotificationView tests
# ---------------------------------------------------------------------------

class DeleteNotificationViewTests(TestCase):
    """Tests for DELETE /api/trainer/notifications/<pk>/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@delete.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)

    def _url(self, pk: int) -> str:
        return f'/api/trainer/notifications/{pk}/'

    def test_delete_notification_success(self) -> None:
        notif = _create_notification(self.trainer)
        response = self.client.delete(self._url(notif.pk))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(
            TrainerNotification.objects.filter(pk=notif.pk).exists()
        )

    def test_delete_nonexistent_returns_404(self) -> None:
        response = self.client.delete(self._url(99999))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn('error', response.data)

    def test_delete_already_deleted_returns_404(self) -> None:
        notif = _create_notification(self.trainer)
        pk = notif.pk
        notif.delete()
        response = self.client.delete(self._url(pk))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_reduces_count(self) -> None:
        n1 = _create_notification(self.trainer)
        _create_notification(self.trainer)
        self.assertEqual(
            TrainerNotification.objects.filter(trainer=self.trainer).count(), 2
        )
        self.client.delete(self._url(n1.pk))
        self.assertEqual(
            TrainerNotification.objects.filter(trainer=self.trainer).count(), 1
        )


# ---------------------------------------------------------------------------
# Authentication & Permission tests
# ---------------------------------------------------------------------------

class NotificationPermissionTests(TestCase):
    """Tests that notification endpoints enforce IsTrainer permission."""

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
        self.ambassador = User.objects.create_user(
            email='ambassador@perm.com',
            password='testpass123',
            role='AMBASSADOR',
        )
        self.notif = _create_notification(self.trainer)

    # --- Unauthenticated ---

    def test_unauthenticated_list_returns_401(self) -> None:
        client = APIClient()
        response = client.get('/api/trainer/notifications/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_unread_count_returns_401(self) -> None:
        client = APIClient()
        response = client.get('/api/trainer/notifications/unread-count/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_mark_read_returns_401(self) -> None:
        client = APIClient()
        response = client.post(f'/api/trainer/notifications/{self.notif.pk}/read/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_mark_all_read_returns_401(self) -> None:
        client = APIClient()
        response = client.post('/api/trainer/notifications/mark-all-read/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_delete_returns_401(self) -> None:
        client = APIClient()
        response = client.delete(f'/api/trainer/notifications/{self.notif.pk}/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    # --- Trainee role (should be 403) ---

    def test_trainee_list_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.get('/api/trainer/notifications/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_unread_count_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.get('/api/trainer/notifications/unread-count/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_mark_read_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.post(f'/api/trainer/notifications/{self.notif.pk}/read/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_mark_all_read_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.post('/api/trainer/notifications/mark-all-read/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_delete_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainee)
        response = client.delete(f'/api/trainer/notifications/{self.notif.pk}/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # --- Admin role (should be 403, not a trainer) ---

    def test_admin_list_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.admin)
        response = client.get('/api/trainer/notifications/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_unread_count_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.admin)
        response = client.get('/api/trainer/notifications/unread-count/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    # --- Ambassador role (should be 403) ---

    def test_ambassador_list_returns_403(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.ambassador)
        response = client.get('/api/trainer/notifications/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


# ---------------------------------------------------------------------------
# Row-level security tests
# ---------------------------------------------------------------------------

class NotificationRowLevelSecurityTests(TestCase):
    """Tests that trainers can only access their own notifications."""

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
        self.notif_a = _create_notification(
            self.trainer_a, title='Notification for A',
        )
        self.notif_b = _create_notification(
            self.trainer_b, title='Notification for B',
        )

    def test_trainer_a_only_sees_own_notifications(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer_a)
        response = client.get('/api/trainer/notifications/')
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(
            response.data['results'][0]['title'], 'Notification for A',
        )

    def test_trainer_b_only_sees_own_notifications(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer_b)
        response = client.get('/api/trainer/notifications/')
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(
            response.data['results'][0]['title'], 'Notification for B',
        )

    def test_trainer_a_cannot_mark_trainer_b_notification_read(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer_a)
        response = client.post(
            f'/api/trainer/notifications/{self.notif_b.pk}/read/',
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        # Verify notification is still unread
        self.notif_b.refresh_from_db()
        self.assertFalse(self.notif_b.is_read)

    def test_trainer_a_cannot_delete_trainer_b_notification(self) -> None:
        client = APIClient()
        client.force_authenticate(user=self.trainer_a)
        response = client.delete(
            f'/api/trainer/notifications/{self.notif_b.pk}/',
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        # Verify notification still exists
        self.assertTrue(
            TrainerNotification.objects.filter(pk=self.notif_b.pk).exists()
        )

    def test_unread_count_only_counts_own(self) -> None:
        _create_notification(self.trainer_a, is_read=False)
        _create_notification(self.trainer_a, is_read=False)
        _create_notification(self.trainer_b, is_read=False)

        client_a = APIClient()
        client_a.force_authenticate(user=self.trainer_a)
        response_a = client_a.get('/api/trainer/notifications/unread-count/')
        # trainer_a has 3 unread (notif_a from setUp + 2 from here)
        self.assertEqual(response_a.data['unread_count'], 3)

        client_b = APIClient()
        client_b.force_authenticate(user=self.trainer_b)
        response_b = client_b.get('/api/trainer/notifications/unread-count/')
        # trainer_b has 2 unread (notif_b from setUp + 1 from here)
        self.assertEqual(response_b.data['unread_count'], 2)

    def test_mark_all_read_only_affects_own(self) -> None:
        _create_notification(self.trainer_a, is_read=False)
        _create_notification(self.trainer_b, is_read=False)

        client_a = APIClient()
        client_a.force_authenticate(user=self.trainer_a)
        client_a.post('/api/trainer/notifications/mark-all-read/')

        # Trainer A's should all be read
        a_unread = TrainerNotification.objects.filter(
            trainer=self.trainer_a, is_read=False,
        ).count()
        self.assertEqual(a_unread, 0)

        # Trainer B's should still be unread
        b_unread = TrainerNotification.objects.filter(
            trainer=self.trainer_b, is_read=False,
        ).count()
        self.assertGreater(b_unread, 0)


# ---------------------------------------------------------------------------
# Notification type tests
# ---------------------------------------------------------------------------

class NotificationTypeTests(TestCase):
    """Tests for various notification types."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@types.com',
            password='testpass123',
            role='TRAINER',
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)

    def test_all_notification_types_returned_correctly(self) -> None:
        types = [
            TrainerNotification.NotificationType.TRAINEE_READINESS,
            TrainerNotification.NotificationType.WORKOUT_COMPLETED,
            TrainerNotification.NotificationType.WORKOUT_MISSED,
            TrainerNotification.NotificationType.GOAL_HIT,
            TrainerNotification.NotificationType.CHECK_IN,
            TrainerNotification.NotificationType.MESSAGE,
            TrainerNotification.NotificationType.GENERAL,
        ]
        for ntype in types:
            _create_notification(self.trainer, notification_type=ntype, title=f'Type: {ntype}')

        response = self.client.get('/api/trainer/notifications/')
        self.assertEqual(response.data['count'], len(types))

        returned_types = {item['notification_type'] for item in response.data['results']}
        expected_types = {str(t) for t in types}
        self.assertEqual(returned_types, expected_types)

    def test_notification_with_rich_data(self) -> None:
        data = {
            'trainee_id': 42,
            'trainee_name': 'John Doe',
            'workout_name': 'Push Day',
            'duration_minutes': 75,
        }
        _create_notification(self.trainer, data=data)
        response = self.client.get('/api/trainer/notifications/')
        item = response.data['results'][0]
        self.assertEqual(item['data']['trainee_id'], 42)
        self.assertEqual(item['data']['trainee_name'], 'John Doe')
        self.assertEqual(item['data']['workout_name'], 'Push Day')
        self.assertEqual(item['data']['duration_minutes'], 75)

    def test_notification_with_empty_data(self) -> None:
        _create_notification(self.trainer, data={})
        response = self.client.get('/api/trainer/notifications/')
        item = response.data['results'][0]
        self.assertEqual(item['data'], {})
