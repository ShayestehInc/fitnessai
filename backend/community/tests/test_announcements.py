"""
Tests for announcement endpoints: trainer CRUD and trainee read/unread/mark-read.
"""
from __future__ import annotations

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from community.models import Announcement, AnnouncementReadStatus
from users.models import User


class TrainerAnnouncementCRUDTests(TestCase):
    """Tests for trainer announcement CRUD under /api/trainer/announcements/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.other_trainer = User.objects.create_user(
            email='other_trainer@test.com',
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
        self.url = '/api/trainer/announcements/'

    def test_list_own_announcements(self) -> None:
        """Trainer sees only their own announcements."""
        Announcement.objects.create(trainer=self.trainer, title='A1', body='Body1')
        Announcement.objects.create(trainer=self.trainer, title='A2', body='Body2')
        Announcement.objects.create(trainer=self.other_trainer, title='Other', body='Other')

        self.client.force_authenticate(user=self.trainer)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['results']), 2)

    def test_create_announcement(self) -> None:
        """Trainer can create an announcement."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.post(self.url, {
            'title': 'New Announcement',
            'body': 'This is the body.',
            'is_pinned': True,
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['title'], 'New Announcement')
        self.assertTrue(response.data['is_pinned'])
        self.assertEqual(Announcement.objects.filter(trainer=self.trainer).count(), 1)

    def test_create_validates_title_length(self) -> None:
        """Title over 200 chars is rejected."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.post(self.url, {
            'title': 'x' * 201,
            'body': 'Body',
        }, format='json')
        self.assertEqual(response.status_code, 400)

    def test_create_validates_body_required(self) -> None:
        """Body is required."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.post(self.url, {
            'title': 'Title',
        }, format='json')
        self.assertEqual(response.status_code, 400)

    def test_update_announcement(self) -> None:
        """Trainer can update their own announcement."""
        a = Announcement.objects.create(trainer=self.trainer, title='Old', body='Old body')
        self.client.force_authenticate(user=self.trainer)
        response = self.client.put(f'{self.url}{a.id}/', {
            'title': 'Updated',
            'body': 'Updated body',
            'is_pinned': True,
        }, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['title'], 'Updated')

    def test_update_other_trainers_announcement_returns_404(self) -> None:
        """Trainer cannot update another trainer's announcement."""
        a = Announcement.objects.create(trainer=self.other_trainer, title='Other', body='Body')
        self.client.force_authenticate(user=self.trainer)
        response = self.client.put(f'{self.url}{a.id}/', {
            'title': 'Hacked',
            'body': 'Hacked body',
        }, format='json')
        self.assertEqual(response.status_code, 404)

    def test_delete_announcement(self) -> None:
        """Trainer can delete their own announcement."""
        a = Announcement.objects.create(trainer=self.trainer, title='Delete me', body='Body')
        self.client.force_authenticate(user=self.trainer)
        response = self.client.delete(f'{self.url}{a.id}/')
        self.assertEqual(response.status_code, 204)
        self.assertFalse(Announcement.objects.filter(id=a.id).exists())

    def test_trainee_cannot_access_trainer_endpoints(self) -> None:
        """Trainee is blocked from trainer announcement endpoints."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 403)

    def test_unauthenticated_blocked(self) -> None:
        """Unauthenticated requests are blocked."""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 401)


class TraineeAnnouncementTests(TestCase):
    """Tests for trainee announcement endpoints under /api/community/announcements/."""

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
        self.orphan_trainee = User.objects.create_user(
            email='orphan@test.com',
            password='testpass123',
            role='TRAINEE',
        )
        self.client = APIClient()
        self.base_url = '/api/community/announcements/'

    def test_list_announcements_from_trainer(self) -> None:
        """Trainee sees announcements from their parent_trainer."""
        Announcement.objects.create(trainer=self.trainer, title='A1', body='Body1')
        Announcement.objects.create(trainer=self.trainer, title='A2', body='Body2', is_pinned=True)

        self.client.force_authenticate(user=self.trainee)
        response = self.client.get(self.base_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['results']), 2)
        # Pinned first
        self.assertTrue(response.data['results'][0]['is_pinned'])

    def test_no_parent_trainer_returns_empty(self) -> None:
        """Trainee with no parent_trainer sees empty list."""
        self.client.force_authenticate(user=self.orphan_trainee)
        response = self.client.get(self.base_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['results']), 0)

    def test_unread_count_all_unread(self) -> None:
        """Without read status, all announcements are unread."""
        Announcement.objects.create(trainer=self.trainer, title='A1', body='Body1')
        Announcement.objects.create(trainer=self.trainer, title='A2', body='Body2')

        self.client.force_authenticate(user=self.trainee)
        response = self.client.get(f'{self.base_url}unread-count/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['unread_count'], 2)

    def test_unread_count_after_mark_read(self) -> None:
        """After marking as read, unread count drops to 0."""
        Announcement.objects.create(trainer=self.trainer, title='A1', body='Body1')

        self.client.force_authenticate(user=self.trainee)
        self.client.post(f'{self.base_url}mark-read/')

        response = self.client.get(f'{self.base_url}unread-count/')
        self.assertEqual(response.data['unread_count'], 0)

    def test_unread_count_new_announcement_after_read(self) -> None:
        """New announcement after mark-read shows as unread."""
        Announcement.objects.create(trainer=self.trainer, title='Old', body='Body')

        self.client.force_authenticate(user=self.trainee)
        self.client.post(f'{self.base_url}mark-read/')

        # Create a new announcement (created_at will be after last_read_at)
        Announcement.objects.create(trainer=self.trainer, title='New', body='Body')

        response = self.client.get(f'{self.base_url}unread-count/')
        self.assertEqual(response.data['unread_count'], 1)

    def test_mark_read_returns_timestamp(self) -> None:
        """Mark-read returns last_read_at timestamp."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(f'{self.base_url}mark-read/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('last_read_at', response.data)

    def test_mark_read_no_trainer_returns_400(self) -> None:
        """Mark-read without parent_trainer returns 400."""
        self.client.force_authenticate(user=self.orphan_trainee)
        response = self.client.post(f'{self.base_url}mark-read/')
        self.assertEqual(response.status_code, 400)

    def test_unread_count_no_trainer_returns_zero(self) -> None:
        """Orphan trainee gets unread_count = 0."""
        self.client.force_authenticate(user=self.orphan_trainee)
        response = self.client.get(f'{self.base_url}unread-count/')
        self.assertEqual(response.data['unread_count'], 0)
