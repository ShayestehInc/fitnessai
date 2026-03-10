"""
Tests for Daily Digest + Message Drafting — v6.5 Step 11.
"""
from __future__ import annotations

from datetime import date, timedelta

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from trainer.models import (
    DailyDigest,
    DigestPreference,
    TraineeActivitySummary,
)
from trainer.services.daily_digest_service import (
    draft_trainee_message,
    generate_daily_digest,
    get_digest_history,
    get_or_create_digest_preference,
    mark_digest_read,
    update_digest_preference,
)
from users.models import User


class DigestTestBase(TestCase):
    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="dd_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee1 = User.objects.create_user(
            email="dd_trainee1@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.trainee2 = User.objects.create_user(
            email="dd_trainee2@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.target_date = date.today() - timedelta(days=1)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)

        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee1)


class GenerateDigestTest(DigestTestBase):
    def test_generates_digest(self) -> None:
        result = generate_daily_digest(
            trainer=self.trainer,
            target_date=self.target_date,
        )
        self.assertIsNotNone(result.digest_id)
        self.assertEqual(result.metrics.total_trainees, 2)

    def test_idempotent(self) -> None:
        r1 = generate_daily_digest(trainer=self.trainer, target_date=self.target_date)
        r2 = generate_daily_digest(trainer=self.trainer, target_date=self.target_date)
        self.assertEqual(r1.digest_id, r2.digest_id)

    def test_with_activity_data(self) -> None:
        TraineeActivitySummary.objects.create(
            trainee=self.trainee1,
            date=self.target_date,
            workouts_completed=1,
            logged_workout=True,
            logged_food=True,
            hit_calorie_goal=True,
            hit_protein_goal=True,
        )
        result = generate_daily_digest(
            trainer=self.trainer,
            target_date=self.target_date,
        )
        self.assertEqual(result.metrics.workouts_completed, 1)
        self.assertEqual(result.metrics.active_trainees, 1)
        self.assertGreater(result.metrics.avg_compliance_pct, 0)

    def test_summary_text_not_empty(self) -> None:
        result = generate_daily_digest(
            trainer=self.trainer,
            target_date=self.target_date,
        )
        self.assertIn('Daily Digest', result.summary_text)


class DigestPreferenceTest(DigestTestBase):
    def test_get_or_create(self) -> None:
        pref = get_or_create_digest_preference(self.trainer)
        self.assertEqual(pref.delivery_method, 'in_app')
        self.assertEqual(pref.delivery_hour, 7)

    def test_update(self) -> None:
        pref = update_digest_preference(
            self.trainer,
            delivery_method='email',
            delivery_hour=9,
        )
        self.assertEqual(pref.delivery_method, 'email')
        self.assertEqual(pref.delivery_hour, 9)

    def test_ignores_invalid_fields(self) -> None:
        pref = update_digest_preference(
            self.trainer,
            invalid_field='bad',
        )
        self.assertIsNotNone(pref)


class DigestHistoryTest(DigestTestBase):
    def test_returns_ordered(self) -> None:
        generate_daily_digest(trainer=self.trainer, target_date=self.target_date)
        generate_daily_digest(
            trainer=self.trainer,
            target_date=self.target_date - timedelta(days=1),
        )
        history = get_digest_history(self.trainer)
        self.assertEqual(len(history), 2)
        self.assertGreater(history[0].date, history[1].date)


class MarkReadTest(DigestTestBase):
    def test_marks_as_read(self) -> None:
        result = generate_daily_digest(
            trainer=self.trainer,
            target_date=self.target_date,
        )
        mark_digest_read(result.digest_id)
        digest = DailyDigest.objects.get(pk=result.digest_id)
        self.assertIsNotNone(digest.read_at)


class DraftMessageTest(DigestTestBase):
    def test_encouragement(self) -> None:
        draft = draft_trainee_message(
            trainer=self.trainer,
            trainee=self.trainee1,
            message_type='encouragement',
        )
        self.assertIn('Great work', draft)

    def test_missed_workout(self) -> None:
        draft = draft_trainee_message(
            trainer=self.trainer,
            trainee=self.trainee1,
            message_type='missed_workout',
        )
        self.assertIn('missed', draft.lower())

    def test_with_context(self) -> None:
        draft = draft_trainee_message(
            trainer=self.trainer,
            trainee=self.trainee1,
            message_type='check_in',
            context='Has been logging inconsistently',
        )
        self.assertIn('inconsistently', draft)

    def test_unknown_type_falls_back(self) -> None:
        draft = draft_trainee_message(
            trainer=self.trainer,
            trainee=self.trainee1,
            message_type='unknown_type',
        )
        self.assertIn('checking in', draft)


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------


class DigestAPITest(DigestTestBase):
    def test_generate_endpoint(self) -> None:
        resp = self.trainer_client.post(
            '/api/trainer/ai/daily-digest/generate/',
            data={'date': str(self.target_date)},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('digest_id', resp.data)
        self.assertIn('metrics', resp.data)

    def test_generate_trainee_forbidden(self) -> None:
        resp = self.trainee_client.post(
            '/api/trainer/ai/daily-digest/generate/',
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_history_endpoint(self) -> None:
        generate_daily_digest(trainer=self.trainer, target_date=self.target_date)
        resp = self.trainer_client.get('/api/trainer/ai/daily-digest/history/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 1)

    def test_detail_marks_read(self) -> None:
        result = generate_daily_digest(
            trainer=self.trainer,
            target_date=self.target_date,
        )
        resp = self.trainer_client.get(
            f'/api/trainer/ai/daily-digest/{result.digest_id}/',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(resp.data['read_at'])

    def test_preferences_get(self) -> None:
        resp = self.trainer_client.get(
            '/api/trainer/ai/daily-digest/preferences/',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['delivery_method'], 'in_app')

    def test_preferences_patch(self) -> None:
        resp = self.trainer_client.patch(
            '/api/trainer/ai/daily-digest/preferences/',
            data={'delivery_method': 'email', 'delivery_hour': 9},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['delivery_method'], 'email')

    def test_draft_message_endpoint(self) -> None:
        resp = self.trainer_client.post(
            '/api/trainer/ai/draft-message/',
            data={
                'trainee_id': self.trainee1.pk,
                'message_type': 'encouragement',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('draft', resp.data)

    def test_draft_message_invalid_type(self) -> None:
        resp = self.trainer_client.post(
            '/api/trainer/ai/draft-message/',
            data={
                'trainee_id': self.trainee1.pk,
                'message_type': 'invalid',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_draft_message_wrong_trainee(self) -> None:
        other_trainee = User.objects.create_user(
            email="other@test.com",
            password="testpass123",
            role="TRAINEE",
        )
        resp = self.trainer_client.post(
            '/api/trainer/ai/draft-message/',
            data={
                'trainee_id': other_trainee.pk,
                'message_type': 'check_in',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)
