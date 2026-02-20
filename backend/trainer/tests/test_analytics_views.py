"""
Tests for Trainer Analytics Views (Pipeline 26).

Covers:
- AdherenceAnalyticsView: calorie_goal_rate field in response
- AdherenceTrendView: daily adherence trends, aggregation, edge cases
- _parse_days_param: parameter validation and clamping
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import cast

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from trainer.models import TraineeActivitySummary
from users.models import User


def _create_trainer(email: str = 'trainer@test.com') -> User:
    return User.objects.create_user(
        email=email,
        password='testpass123',
        role=User.Role.TRAINER,
        first_name='Test',
        last_name='Trainer',
    )


def _create_trainee(trainer: User, email: str = 'trainee@test.com') -> User:
    return User.objects.create_user(
        email=email,
        password='testpass123',
        role=User.Role.TRAINEE,
        parent_trainer=trainer,
        first_name='Test',
        last_name='Trainee',
    )


def _auth_client(user: User) -> APIClient:
    client = APIClient()
    token = cast(str, str(RefreshToken.for_user(user).access_token))
    client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
    return client


def _create_summary(
    trainee: User,
    day: date,
    logged_food: bool = False,
    logged_workout: bool = False,
    hit_protein_goal: bool = False,
    hit_calorie_goal: bool = False,
) -> TraineeActivitySummary:
    return TraineeActivitySummary.objects.create(
        trainee=trainee,
        date=day,
        logged_food=logged_food,
        logged_workout=logged_workout,
        hit_protein_goal=hit_protein_goal,
        hit_calorie_goal=hit_calorie_goal,
    )


class AdherenceAnalyticsCalorieRateTests(TestCase):
    """Tests for the calorie_goal_rate field added to AdherenceAnalyticsView."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        self.client = _auth_client(self.trainer)
        self.url = '/api/trainer/analytics/adherence/'

    def test_calorie_goal_rate_present_in_response(self) -> None:
        """Response includes calorie_goal_rate field."""
        today = timezone.now().date()
        _create_summary(self.trainee, today, hit_calorie_goal=True)
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('calorie_goal_rate', resp.data)

    def test_calorie_goal_rate_calculation(self) -> None:
        """calorie_goal_rate is correctly calculated as % of days with hit_calorie_goal."""
        today = timezone.now().date()
        _create_summary(self.trainee, today, hit_calorie_goal=True)
        _create_summary(self.trainee, today - timedelta(days=1), hit_calorie_goal=False)
        _create_summary(self.trainee, today - timedelta(days=2), hit_calorie_goal=True)
        resp = self.client.get(self.url, {'days': 7})
        # 2 out of 3 = 66.7%
        self.assertAlmostEqual(resp.data['calorie_goal_rate'], 66.7, places=1)

    def test_calorie_goal_rate_zero_when_no_data(self) -> None:
        """calorie_goal_rate is 0 when there are no tracking days."""
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['calorie_goal_rate'], 0)

    def test_calorie_goal_rate_zero_when_no_hits(self) -> None:
        """calorie_goal_rate is 0 when no trainee hit their calorie goal."""
        today = timezone.now().date()
        _create_summary(self.trainee, today, hit_calorie_goal=False, logged_food=True)
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['calorie_goal_rate'], 0.0)

    def test_calorie_goal_rate_100_when_all_hit(self) -> None:
        """calorie_goal_rate is 100 when all days have calorie goal hit."""
        today = timezone.now().date()
        for i in range(5):
            _create_summary(self.trainee, today - timedelta(days=i), hit_calorie_goal=True)
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['calorie_goal_rate'], 100.0)


class AdherenceTrendViewTests(TestCase):
    """Tests for the new AdherenceTrendView endpoint."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        self.client = _auth_client(self.trainer)
        self.url = '/api/trainer/analytics/adherence/trends/'

    def test_returns_200(self) -> None:
        """Endpoint returns 200 for authenticated trainer."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_response_shape(self) -> None:
        """Response has period_days and trends keys."""
        resp = self.client.get(self.url, {'days': 7})
        self.assertIn('period_days', resp.data)
        self.assertIn('trends', resp.data)
        self.assertEqual(resp.data['period_days'], 7)
        self.assertIsInstance(resp.data['trends'], list)

    def test_empty_trends_when_no_data(self) -> None:
        """Returns empty trends array when no activity summaries exist."""
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['trends'], [])

    def test_trend_point_fields(self) -> None:
        """Each trend point has all expected fields."""
        today = timezone.now().date()
        _create_summary(self.trainee, today, logged_food=True)
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(len(resp.data['trends']), 1)
        point = resp.data['trends'][0]
        self.assertIn('date', point)
        self.assertIn('food_logged_rate', point)
        self.assertIn('workout_logged_rate', point)
        self.assertIn('protein_goal_rate', point)
        self.assertIn('calorie_goal_rate', point)
        self.assertIn('trainee_count', point)

    def test_daily_rates_calculation(self) -> None:
        """Rates are calculated correctly per day."""
        today = timezone.now().date()
        trainee2 = _create_trainee(self.trainer, email='trainee2@test.com')
        # Day 1: both log food, one hits protein
        _create_summary(self.trainee, today, logged_food=True, hit_protein_goal=True)
        _create_summary(trainee2, today, logged_food=True, hit_protein_goal=False)

        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(len(resp.data['trends']), 1)
        point = resp.data['trends'][0]
        self.assertEqual(point['date'], today.isoformat())
        self.assertEqual(point['food_logged_rate'], 100.0)  # 2/2
        self.assertEqual(point['protein_goal_rate'], 50.0)  # 1/2
        self.assertEqual(point['trainee_count'], 2)

    def test_multiple_days_sorted_ascending(self) -> None:
        """Trend points are sorted by date ascending."""
        today = timezone.now().date()
        _create_summary(self.trainee, today, logged_food=True)
        _create_summary(self.trainee, today - timedelta(days=2), logged_workout=True)
        resp = self.client.get(self.url, {'days': 7})
        dates = [p['date'] for p in resp.data['trends']]
        self.assertEqual(dates, sorted(dates))

    def test_days_param_defaults_to_30(self) -> None:
        """Days parameter defaults to 30."""
        resp = self.client.get(self.url)
        self.assertEqual(resp.data['period_days'], 30)

    def test_days_param_clamped_min(self) -> None:
        """Days parameter is clamped to minimum of 1."""
        resp = self.client.get(self.url, {'days': -5})
        self.assertEqual(resp.data['period_days'], 1)

    def test_days_param_clamped_max(self) -> None:
        """Days parameter is clamped to maximum of 365."""
        resp = self.client.get(self.url, {'days': 999})
        self.assertEqual(resp.data['period_days'], 365)

    def test_days_param_invalid_string(self) -> None:
        """Invalid days parameter falls back to 30."""
        resp = self.client.get(self.url, {'days': 'abc'})
        self.assertEqual(resp.data['period_days'], 30)

    def test_calorie_goal_rate_in_trends(self) -> None:
        """Calorie goal rate is correctly computed in trend data."""
        today = timezone.now().date()
        _create_summary(self.trainee, today, hit_calorie_goal=True)
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['trends'][0]['calorie_goal_rate'], 100.0)

    def test_trainer_isolation(self) -> None:
        """Trainer can only see their own trainees' data."""
        other_trainer = _create_trainer(email='other@test.com')
        other_trainee = _create_trainee(other_trainer, email='other-trainee@test.com')
        today = timezone.now().date()
        _create_summary(other_trainee, today, logged_food=True)

        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['trends'], [])

    def test_requires_authentication(self) -> None:
        """Unauthenticated requests are rejected."""
        client = APIClient()
        resp = client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_requires_trainer_role(self) -> None:
        """Non-trainer users are rejected."""
        trainee_client = _auth_client(self.trainee)
        resp = trainee_client.get(self.url)
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_excludes_inactive_trainees(self) -> None:
        """Inactive trainees are excluded from trend data."""
        today = timezone.now().date()
        self.trainee.is_active = False
        self.trainee.save()
        _create_summary(self.trainee, today, logged_food=True)

        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['trends'], [])

    def test_data_outside_period_excluded(self) -> None:
        """Data older than the requested period is excluded."""
        today = timezone.now().date()
        _create_summary(self.trainee, today - timedelta(days=10), logged_food=True)
        resp = self.client.get(self.url, {'days': 7})
        self.assertEqual(resp.data['trends'], [])
