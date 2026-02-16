"""
Tests for achievement endpoints and the check_and_award_achievements service.
"""
from __future__ import annotations

from datetime import date, timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from community.models import Achievement, UserAchievement
from community.services.achievement_service import (
    check_and_award_achievements,
    _consecutive_days,
)
from users.models import User
from workouts.models import DailyLog


class ConsecutiveDaysTests(TestCase):
    """Unit tests for the _consecutive_days helper."""

    def test_empty_set_returns_zero(self) -> None:
        self.assertEqual(_consecutive_days(set()), 0)

    def test_single_today(self) -> None:
        today = timezone.now().date()
        self.assertEqual(_consecutive_days({today}), 1)

    def test_single_yesterday(self) -> None:
        yesterday = timezone.now().date() - timedelta(days=1)
        self.assertEqual(_consecutive_days({yesterday}), 1)

    def test_three_day_streak(self) -> None:
        today = timezone.now().date()
        dates = {today, today - timedelta(days=1), today - timedelta(days=2)}
        self.assertEqual(_consecutive_days(dates), 3)

    def test_gap_resets_streak(self) -> None:
        today = timezone.now().date()
        dates = {today, today - timedelta(days=2)}  # gap on day -1
        self.assertEqual(_consecutive_days(dates), 1)

    def test_old_dates_no_streak(self) -> None:
        """Dates far in the past don't count as current streak."""
        old = timezone.now().date() - timedelta(days=30)
        self.assertEqual(_consecutive_days({old}), 0)


class CheckAndAwardAchievementsTests(TestCase):
    """Tests for the check_and_award_achievements service."""

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
        # Create workout count achievements
        self.first_workout = Achievement.objects.create(
            name='First Steps',
            description='Complete 1 workout',
            icon_name='directions_walk',
            criteria_type=Achievement.CriteriaType.WORKOUT_COUNT,
            criteria_value=1,
        )
        self.five_workouts = Achievement.objects.create(
            name='Getting Started',
            description='Complete 5 workouts',
            icon_name='fitness_center',
            criteria_type=Achievement.CriteriaType.WORKOUT_COUNT,
            criteria_value=5,
        )

    def test_awards_workout_count_achievement(self) -> None:
        """Trainee earns 'First Steps' after 1 workout."""
        DailyLog.objects.create(
            trainee=self.trainee,
            date=timezone.now().date(),
            workout_data={'exercises': [{'name': 'Bench Press'}]},
        )
        earned = check_and_award_achievements(self.trainee, 'workout_completed')
        self.assertEqual(len(earned), 1)
        self.assertEqual(earned[0].achievement, self.first_workout)

    def test_does_not_double_award(self) -> None:
        """Same achievement is not awarded twice."""
        DailyLog.objects.create(
            trainee=self.trainee,
            date=timezone.now().date(),
            workout_data={'exercises': [{'name': 'Bench Press'}]},
        )
        first = check_and_award_achievements(self.trainee, 'workout_completed')
        self.assertEqual(len(first), 1)

        second = check_and_award_achievements(self.trainee, 'workout_completed')
        self.assertEqual(len(second), 0)

    def test_unrelated_trigger_no_award(self) -> None:
        """Weight check-in trigger doesn't check workout achievements."""
        DailyLog.objects.create(
            trainee=self.trainee,
            date=timezone.now().date(),
            workout_data={'exercises': [{'name': 'Bench Press'}]},
        )
        earned = check_and_award_achievements(self.trainee, 'weight_checkin')
        self.assertEqual(len(earned), 0)

    def test_unknown_trigger_returns_empty(self) -> None:
        """Unknown trigger name returns empty list."""
        earned = check_and_award_achievements(self.trainee, 'unknown_trigger')
        self.assertEqual(len(earned), 0)

    def test_no_achievements_seeded_returns_empty(self) -> None:
        """If no achievements exist for criteria type, returns empty."""
        Achievement.objects.all().delete()
        DailyLog.objects.create(
            trainee=self.trainee,
            date=timezone.now().date(),
            workout_data={'exercises': [{'name': 'Bench Press'}]},
        )
        earned = check_and_award_achievements(self.trainee, 'workout_completed')
        self.assertEqual(len(earned), 0)


class AchievementEndpointTests(TestCase):
    """Tests for /api/community/achievements/ endpoints."""

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
        self.achievement = Achievement.objects.create(
            name='First Steps',
            description='Complete 1 workout',
            icon_name='directions_walk',
            criteria_type=Achievement.CriteriaType.WORKOUT_COUNT,
            criteria_value=1,
        )
        self.client = APIClient()

    def test_list_achievements_with_earned_status(self) -> None:
        """Endpoint returns achievements with earned flag."""
        UserAchievement.objects.create(user=self.trainee, achievement=self.achievement)

        self.client.force_authenticate(user=self.trainee)
        response = self.client.get('/api/community/achievements/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertTrue(response.data[0]['earned'])
        self.assertIsNotNone(response.data[0]['earned_at'])

    def test_list_achievements_unearned(self) -> None:
        """Unearned achievements have earned=False."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.get('/api/community/achievements/')
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data[0]['earned'])
        self.assertIsNone(response.data[0]['earned_at'])

    def test_recent_achievements(self) -> None:
        """Recent endpoint returns last 5 earned achievements."""
        UserAchievement.objects.create(user=self.trainee, achievement=self.achievement)

        self.client.force_authenticate(user=self.trainee)
        response = self.client.get('/api/community/achievements/recent/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'First Steps')

    def test_trainer_cannot_access(self) -> None:
        """Trainer is blocked from achievement endpoints."""
        self.client.force_authenticate(user=self.trainer)
        response = self.client.get('/api/community/achievements/')
        self.assertEqual(response.status_code, 403)
