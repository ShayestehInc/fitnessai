"""
Tests for correlation analytics — v6.5 Step 15.
"""
from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from trainer.models import TraineeActivitySummary
from trainer.services.correlation_analytics_service import (
    CohortComparison,
    CorrelationOverview,
    ExerciseProgression,
    TraineePatterns,
    _compute_adherence_stats,
    _pearson_r,
    get_cohort_analysis,
    get_correlation_overview,
    get_trainee_patterns,
)
from users.models import User
from workouts.models import Exercise, LiftMax, LiftSetLog


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _create_trainer(email: str = 'trainer@test.com') -> User:
    return User.objects.create_user(
        email=email, password='pass1234', role='TRAINER',
    )


def _create_trainee(trainer: User, email: str = 'trainee@test.com') -> User:
    return User.objects.create_user(
        email=email, password='pass1234', role='TRAINEE',
        parent_trainer=trainer,
    )


def _seed_summaries(
    trainee: User,
    days: int = 14,
    *,
    food: bool = True,
    workout: bool = True,
    protein: bool = True,
    calorie: bool = True,
    sleep: float = 7.5,
    volume: float = 5000.0,
) -> list[TraineeActivitySummary]:
    """Create N days of activity summaries."""
    today = timezone.now().date()
    summaries = []
    for i in range(days):
        summaries.append(TraineeActivitySummary.objects.create(
            trainee=trainee,
            date=today - timedelta(days=i),
            logged_food=food,
            logged_workout=workout,
            hit_protein_goal=protein,
            hit_calorie_goal=calorie,
            sleep_hours=sleep,
            total_volume=volume,
            workouts_completed=1 if workout else 0,
            total_sets=20 if workout else 0,
        ))
    return summaries


# ---------------------------------------------------------------------------
# Unit tests — Pearson correlation
# ---------------------------------------------------------------------------

class PearsonCorrelationTests(TestCase):
    """Test the _pearson_r helper."""

    def test_perfect_positive_correlation(self) -> None:
        xs = [1.0, 2.0, 3.0, 4.0, 5.0]
        ys = [2.0, 4.0, 6.0, 8.0, 10.0]
        r = _pearson_r(xs, ys)
        self.assertAlmostEqual(r, 1.0, places=5)

    def test_perfect_negative_correlation(self) -> None:
        xs = [1.0, 2.0, 3.0, 4.0, 5.0]
        ys = [10.0, 8.0, 6.0, 4.0, 2.0]
        r = _pearson_r(xs, ys)
        self.assertAlmostEqual(r, -1.0, places=5)

    def test_no_correlation(self) -> None:
        xs = [1.0, 2.0, 3.0, 4.0, 5.0]
        ys = [5.0, 5.0, 5.0, 5.0, 5.0]  # constant — std=0
        r = _pearson_r(xs, ys)
        self.assertEqual(r, 0.0)

    def test_insufficient_data_returns_zero(self) -> None:
        r = _pearson_r([1.0, 2.0], [3.0, 4.0])  # n<3
        self.assertEqual(r, 0.0)

    def test_empty_lists(self) -> None:
        self.assertEqual(_pearson_r([], []), 0.0)

    def test_mismatched_lengths(self) -> None:
        self.assertEqual(_pearson_r([1.0, 2.0, 3.0], [1.0, 2.0]), 0.0)


# ---------------------------------------------------------------------------
# Unit tests — Adherence stats
# ---------------------------------------------------------------------------

class AdherenceStatsTests(TestCase):
    """Test _compute_adherence_stats helper."""

    def test_empty_days(self) -> None:
        stats = _compute_adherence_stats([])
        self.assertEqual(stats['total_days'], 0)
        self.assertEqual(stats['food_logging_pct'], 0)

    def test_full_adherence(self) -> None:
        days = [
            {
                'logged_food': True, 'logged_workout': True,
                'hit_protein_goal': True, 'hit_calorie_goal': True,
                'sleep_hours': 8.0, 'total_volume': 5000,
            }
            for _ in range(7)
        ]
        stats = _compute_adherence_stats(days)
        self.assertEqual(stats['total_days'], 7)
        self.assertEqual(stats['food_logging_pct'], 100.0)
        self.assertEqual(stats['workout_logging_pct'], 100.0)
        self.assertEqual(stats['protein_adherence_pct'], 100.0)
        self.assertEqual(stats['calorie_adherence_pct'], 100.0)
        self.assertAlmostEqual(stats['avg_sleep_hours'], 8.0)
        self.assertAlmostEqual(stats['avg_daily_volume'], 5000.0)


# ---------------------------------------------------------------------------
# Service-level tests
# ---------------------------------------------------------------------------

class CorrelationOverviewTests(TestCase):
    """Test get_correlation_overview service."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()

    def test_empty_trainees_returns_empty(self) -> None:
        overview = get_correlation_overview(trainer=self.trainer, days=30)
        self.assertIsInstance(overview, CorrelationOverview)
        self.assertEqual(overview.correlations, [])
        self.assertEqual(overview.insights, [])
        self.assertEqual(overview.cohort_comparisons, [])

    def test_with_trainees_returns_insights(self) -> None:
        # Create 3 trainees with varied adherence
        t1 = _create_trainee(self.trainer, 'high@test.com')
        t2 = _create_trainee(self.trainer, 'mid@test.com')
        t3 = _create_trainee(self.trainer, 'low@test.com')

        _seed_summaries(t1, 14, protein=True, calorie=True, sleep=8.0, volume=6000)
        _seed_summaries(t2, 14, protein=True, calorie=False, sleep=7.0, volume=4000)
        _seed_summaries(t3, 14, protein=False, calorie=False, sleep=5.0, volume=2000)

        overview = get_correlation_overview(trainer=self.trainer, days=30)
        self.assertEqual(overview.period_days, 30)
        # With 3 trainees we should get at least some correlations
        self.assertGreaterEqual(len(overview.correlations), 1)

    def test_days_clamped(self) -> None:
        overview = get_correlation_overview(trainer=self.trainer, days=1)
        self.assertEqual(overview.period_days, 7)  # min 7

        overview = get_correlation_overview(trainer=self.trainer, days=9999)
        self.assertEqual(overview.period_days, 365)  # max 365


class TraineePatternsTests(TestCase):
    """Test get_trainee_patterns service."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)

    def test_trainee_not_found_raises(self) -> None:
        with self.assertRaises(ValueError):
            get_trainee_patterns(trainer=self.trainer, trainee_id=99999, days=30)

    def test_other_trainers_trainee_raises(self) -> None:
        other_trainer = _create_trainer('other@test.com')
        other_trainee = _create_trainee(other_trainer, 'other_trainee@test.com')
        with self.assertRaises(ValueError):
            get_trainee_patterns(
                trainer=self.trainer,
                trainee_id=other_trainee.pk,
                days=30,
            )

    def test_returns_patterns(self) -> None:
        _seed_summaries(self.trainee, 14)
        patterns = get_trainee_patterns(
            trainer=self.trainer,
            trainee_id=self.trainee.pk,
            days=30,
        )
        self.assertIsInstance(patterns, TraineePatterns)
        self.assertEqual(patterns.trainee_id, self.trainee.pk)
        self.assertEqual(patterns.period_days, 30)
        self.assertIsInstance(patterns.adherence_stats, dict)
        self.assertIn('food_logging_pct', patterns.adherence_stats)

    def test_high_adherence_insight(self) -> None:
        _seed_summaries(self.trainee, 14, protein=True, calorie=True)
        patterns = get_trainee_patterns(
            trainer=self.trainer,
            trainee_id=self.trainee.pk,
            days=30,
        )
        insight_types = [i.insight_type for i in patterns.insights]
        self.assertIn('high_adherence', insight_types)

    def test_low_protein_insight(self) -> None:
        _seed_summaries(self.trainee, 14, protein=False, calorie=True)
        patterns = get_trainee_patterns(
            trainer=self.trainer,
            trainee_id=self.trainee.pk,
            days=30,
        )
        insight_types = [i.insight_type for i in patterns.insights]
        self.assertIn('low_protein_adherence', insight_types)


class CohortAnalysisTests(TestCase):
    """Test get_cohort_analysis service."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()

    def test_empty_trainees(self) -> None:
        result = get_cohort_analysis(trainer=self.trainer, days=30)
        self.assertEqual(result, [])

    def test_single_cohort_returns_empty(self) -> None:
        """If all trainees are in one cohort, no comparison possible."""
        t1 = _create_trainee(self.trainer, 'a@test.com')
        t2 = _create_trainee(self.trainer, 'b@test.com')
        # Both high adherence
        _seed_summaries(t1, 14, food=True, workout=True)
        _seed_summaries(t2, 14, food=True, workout=True)
        result = get_cohort_analysis(trainer=self.trainer, days=30, threshold=70.0)
        self.assertEqual(result, [])

    def test_two_cohorts_returns_comparisons(self) -> None:
        t_high = _create_trainee(self.trainer, 'high@test.com')
        t_low = _create_trainee(self.trainer, 'low@test.com')
        _seed_summaries(t_high, 14, food=True, workout=True)
        _seed_summaries(t_low, 14, food=False, workout=False)
        result = get_cohort_analysis(trainer=self.trainer, days=30, threshold=70.0)
        self.assertIsInstance(result, list)
        self.assertGreater(len(result), 0)
        self.assertIsInstance(result[0], CohortComparison)
        self.assertEqual(result[0].high_count, 1)
        self.assertEqual(result[0].low_count, 1)


# ---------------------------------------------------------------------------
# API tests
# ---------------------------------------------------------------------------

class CorrelationAPITests(TestCase):
    """Test the 3 correlation analytics API endpoints."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        _seed_summaries(self.trainee, 14)
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)

    def test_correlations_overview_endpoint(self) -> None:
        resp = self.client.get('/api/trainer/analytics/correlations/')
        self.assertEqual(resp.status_code, 200)
        self.assertIn('correlations', resp.data)
        self.assertIn('insights', resp.data)
        self.assertIn('cohort_comparisons', resp.data)
        self.assertIn('period_days', resp.data)

    def test_trainee_patterns_endpoint(self) -> None:
        resp = self.client.get(
            f'/api/trainer/analytics/trainee/{self.trainee.pk}/patterns/'
        )
        self.assertEqual(resp.status_code, 200)
        self.assertIn('trainee_id', resp.data)
        self.assertIn('insights', resp.data)
        self.assertIn('exercise_progressions', resp.data)
        self.assertIn('adherence_stats', resp.data)

    def test_trainee_patterns_not_found(self) -> None:
        resp = self.client.get('/api/trainer/analytics/trainee/99999/patterns/')
        self.assertEqual(resp.status_code, 404)

    def test_cohort_endpoint(self) -> None:
        resp = self.client.get('/api/trainer/analytics/cohort/')
        self.assertEqual(resp.status_code, 200)
        self.assertIn('comparisons', resp.data)
        self.assertIn('threshold', resp.data)

    def test_cohort_with_custom_params(self) -> None:
        resp = self.client.get('/api/trainer/analytics/cohort/?days=60&threshold=50')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['period_days'], 60)
        self.assertEqual(resp.data['threshold'], 50.0)

    def test_trainee_cannot_access(self) -> None:
        self.client.force_authenticate(user=self.trainee)
        resp = self.client.get('/api/trainer/analytics/correlations/')
        self.assertEqual(resp.status_code, 403)

    def test_unauthenticated_denied(self) -> None:
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/trainer/analytics/correlations/')
        self.assertEqual(resp.status_code, 401)

    def test_invalid_days_uses_default(self) -> None:
        resp = self.client.get('/api/trainer/analytics/correlations/?days=abc')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.data['period_days'], 30)

    def test_other_trainers_trainee_denied(self) -> None:
        other_trainer = _create_trainer('other@test.com')
        other_trainee = _create_trainee(other_trainer, 'ot@test.com')
        resp = self.client.get(
            f'/api/trainer/analytics/trainee/{other_trainee.pk}/patterns/'
        )
        self.assertEqual(resp.status_code, 404)
