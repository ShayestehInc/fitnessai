"""
Tests for audit trail + comprehensive exports — v6.5 Step 16.
"""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from trainer.models import TraineeActivitySummary
from trainer.services.audit_export_service import (
    export_decision_logs_csv,
    export_trainee_nutrition_csv,
    export_trainee_progress_csv,
    export_trainee_workout_csv,
)
from trainer.services.audit_service import (
    AuditSummary,
    get_audit_summary,
    get_audit_timeline,
)
from users.models import User
from workouts.models import DecisionLog, Exercise, LiftMax, LiftSetLog, WeightCheckIn


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


def _create_decision(actor: User, decision_type: str = 'exercise_swap') -> DecisionLog:
    return DecisionLog.objects.create(
        actor_type='trainer',
        actor=actor,
        decision_type=decision_type,
        context={'plan_id': 1},
        inputs_snapshot={'old_exercise': 'Bench Press'},
        final_choice={'new_exercise': 'Incline Press'},
        reason_codes=['pain_flag'],
    )


def _create_exercise(trainer: User, name: str = 'Bench Press') -> Exercise:
    return Exercise.objects.create(
        name=name,
        created_by=trainer,
        is_public=False,
    )


# ---------------------------------------------------------------------------
# Audit Summary Tests
# ---------------------------------------------------------------------------

class AuditSummaryTests(TestCase):
    """Test get_audit_summary service."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()

    def test_empty_returns_zeros(self) -> None:
        summary = get_audit_summary(trainer=self.trainer, days=30)
        self.assertIsInstance(summary, AuditSummary)
        self.assertEqual(summary.total_decisions, 0)
        self.assertEqual(summary.recent_decisions_7d, 0)
        self.assertEqual(summary.reverted_count, 0)

    def test_counts_trainer_decisions(self) -> None:
        _create_decision(self.trainer, 'exercise_swap')
        _create_decision(self.trainer, 'exercise_swap')
        _create_decision(self.trainer, 'progression')

        summary = get_audit_summary(trainer=self.trainer, days=30)
        self.assertEqual(summary.total_decisions, 3)
        self.assertEqual(len(summary.by_type), 2)
        self.assertEqual(len(summary.by_actor), 1)

    def test_excludes_other_trainer_decisions(self) -> None:
        other_trainer = _create_trainer('other@test.com')
        _create_decision(self.trainer, 'swap')
        _create_decision(other_trainer, 'swap')

        summary = get_audit_summary(trainer=self.trainer, days=30)
        self.assertEqual(summary.total_decisions, 1)

    def test_includes_trainee_decisions(self) -> None:
        trainee = _create_trainee(self.trainer)
        _create_decision(trainee, 'undo')

        summary = get_audit_summary(trainer=self.trainer, days=30)
        self.assertEqual(summary.total_decisions, 1)

    def test_days_clamped(self) -> None:
        summary = get_audit_summary(trainer=self.trainer, days=0)
        self.assertEqual(summary.period_days, 1)

        summary = get_audit_summary(trainer=self.trainer, days=9999)
        self.assertEqual(summary.period_days, 365)


# ---------------------------------------------------------------------------
# Audit Timeline Tests
# ---------------------------------------------------------------------------

class AuditTimelineTests(TestCase):
    """Test get_audit_timeline service."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()

    def test_empty_timeline(self) -> None:
        entries = get_audit_timeline(trainer=self.trainer, days=30)
        self.assertEqual(entries, [])

    def test_returns_entries_newest_first(self) -> None:
        _create_decision(self.trainer, 'first')
        _create_decision(self.trainer, 'second')

        entries = get_audit_timeline(trainer=self.trainer, days=30)
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0].decision_type, 'second')
        self.assertEqual(entries[1].decision_type, 'first')

    def test_pagination(self) -> None:
        for i in range(5):
            _create_decision(self.trainer, f'type_{i}')

        entries = get_audit_timeline(trainer=self.trainer, days=30, limit=2, offset=0)
        self.assertEqual(len(entries), 2)

        entries = get_audit_timeline(trainer=self.trainer, days=30, limit=2, offset=2)
        self.assertEqual(len(entries), 2)

    def test_description_includes_actor(self) -> None:
        _create_decision(self.trainer, 'exercise_swap')
        entries = get_audit_timeline(trainer=self.trainer, days=30)
        self.assertIn(self.trainer.email, entries[0].description)
        self.assertIn('Exercise Swap', entries[0].description)


# ---------------------------------------------------------------------------
# Decision Log Export Tests
# ---------------------------------------------------------------------------

class DecisionLogExportTests(TestCase):
    """Test export_decision_logs_csv."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()

    def test_empty_export(self) -> None:
        result = export_decision_logs_csv(self.trainer, days=30)
        self.assertIn('Timestamp', result.content)
        self.assertEqual(result.row_count, 0)

    def test_export_contains_data(self) -> None:
        _create_decision(self.trainer, 'exercise_swap')
        result = export_decision_logs_csv(self.trainer, days=30)
        self.assertEqual(result.row_count, 1)
        self.assertIn('exercise_swap', result.content)
        self.assertIn(self.trainer.email, result.content)


# ---------------------------------------------------------------------------
# Trainee Workout Export Tests
# ---------------------------------------------------------------------------

class TraineeWorkoutExportTests(TestCase):
    """Test export_trainee_workout_csv."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        self.exercise = _create_exercise(self.trainer)

    def test_wrong_trainee_raises(self) -> None:
        other_trainer = _create_trainer('other@test.com')
        with self.assertRaises(ValueError):
            export_trainee_workout_csv(other_trainer, self.trainee.pk, days=30)

    def test_empty_export(self) -> None:
        result = export_trainee_workout_csv(self.trainer, self.trainee.pk, days=30)
        self.assertEqual(result.row_count, 0)
        self.assertIn('Date', result.content)

    def test_export_with_data(self) -> None:
        LiftSetLog.objects.create(
            trainee=self.trainee,
            exercise=self.exercise,
            session_date=timezone.now().date(),
            set_number=1,
            entered_load_value=Decimal('135'),
            entered_load_unit='lb',
            canonical_external_load_value=Decimal('61.2'),
            completed_reps=8,
            rpe=Decimal('7.5'),
        )
        result = export_trainee_workout_csv(self.trainer, self.trainee.pk, days=30)
        self.assertEqual(result.row_count, 1)
        self.assertIn('Bench Press', result.content)
        self.assertIn('135', result.content)


# ---------------------------------------------------------------------------
# Trainee Nutrition Export Tests
# ---------------------------------------------------------------------------

class TraineeNutritionExportTests(TestCase):
    """Test export_trainee_nutrition_csv."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)

    def test_empty_export(self) -> None:
        result = export_trainee_nutrition_csv(self.trainer, self.trainee.pk, days=30)
        self.assertEqual(result.row_count, 0)

    def test_export_with_data(self) -> None:
        TraineeActivitySummary.objects.create(
            trainee=self.trainee,
            date=timezone.now().date(),
            logged_food=True,
            logged_workout=True,
            calories_consumed=2200,
            protein_consumed=180,
            carbs_consumed=250,
            fat_consumed=70,
            hit_protein_goal=True,
            hit_calorie_goal=True,
            sleep_hours=7.5,
        )
        result = export_trainee_nutrition_csv(self.trainer, self.trainee.pk, days=30)
        self.assertEqual(result.row_count, 1)
        self.assertIn('2200', result.content)
        self.assertIn('180', result.content)


# ---------------------------------------------------------------------------
# Trainee Progress Export Tests
# ---------------------------------------------------------------------------

class TraineeProgressExportTests(TestCase):
    """Test export_trainee_progress_csv."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)

    def test_empty_export(self) -> None:
        result = export_trainee_progress_csv(self.trainer, self.trainee.pk, days=90)
        self.assertEqual(result.row_count, 0)

    def test_export_with_weight_checkin(self) -> None:
        WeightCheckIn.objects.create(
            user=self.trainee,
            date=timezone.now().date(),
            weight=Decimal('185.5'),
        )
        result = export_trainee_progress_csv(self.trainer, self.trainee.pk, days=90)
        self.assertGreaterEqual(result.row_count, 1)
        self.assertIn('185.5', result.content)
        self.assertIn('Weight Check-in', result.content)

    def test_export_with_e1rm_history(self) -> None:
        exercise = _create_exercise(self.trainer)
        today_str = timezone.now().date().isoformat()
        LiftMax.objects.create(
            trainee=self.trainee,
            exercise=exercise,
            e1rm_value=Decimal('100.0'),
            e1rm_history=[
                {'date': today_str, 'value': 100.0},
                {'date': (timezone.now().date() - timedelta(days=7)).isoformat(), 'value': 95.0},
            ],
        )
        result = export_trainee_progress_csv(self.trainer, self.trainee.pk, days=90)
        self.assertGreaterEqual(result.row_count, 2)
        self.assertIn('e1RM', result.content)


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------

class AuditAPITests(TestCase):
    """Test audit + export API endpoints."""

    def setUp(self) -> None:
        self.trainer = _create_trainer()
        self.trainee = _create_trainee(self.trainer)
        self.client = APIClient()
        self.client.force_authenticate(user=self.trainer)

    def test_audit_summary_endpoint(self) -> None:
        resp = self.client.get('/api/trainer/audit/summary/')
        self.assertEqual(resp.status_code, 200)
        self.assertIn('total_decisions', resp.data)
        self.assertIn('by_type', resp.data)
        self.assertIn('by_actor', resp.data)

    def test_audit_timeline_endpoint(self) -> None:
        resp = self.client.get('/api/trainer/audit/timeline/')
        self.assertEqual(resp.status_code, 200)
        self.assertIn('entries', resp.data)

    def test_decision_logs_export_endpoint(self) -> None:
        resp = self.client.get('/api/trainer/export/decision-logs/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'text/csv')

    def test_trainee_workout_export_endpoint(self) -> None:
        resp = self.client.get(f'/api/trainer/export/trainee/{self.trainee.pk}/workout-history/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'text/csv')

    def test_trainee_nutrition_export_endpoint(self) -> None:
        resp = self.client.get(f'/api/trainer/export/trainee/{self.trainee.pk}/nutrition-history/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'text/csv')

    def test_trainee_progress_export_endpoint(self) -> None:
        resp = self.client.get(f'/api/trainer/export/trainee/{self.trainee.pk}/progress/')
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp['Content-Type'], 'text/csv')

    def test_trainee_cannot_access_audit(self) -> None:
        self.client.force_authenticate(user=self.trainee)
        resp = self.client.get('/api/trainer/audit/summary/')
        self.assertEqual(resp.status_code, 403)

    def test_unauthenticated_denied(self) -> None:
        self.client.force_authenticate(user=None)
        resp = self.client.get('/api/trainer/audit/summary/')
        self.assertEqual(resp.status_code, 401)

    def test_wrong_trainee_export_404(self) -> None:
        resp = self.client.get('/api/trainer/export/trainee/99999/workout-history/')
        self.assertEqual(resp.status_code, 404)

    def test_other_trainer_trainee_404(self) -> None:
        other_trainer = _create_trainer('other@test.com')
        other_trainee = _create_trainee(other_trainer, 'ot@test.com')
        resp = self.client.get(f'/api/trainer/export/trainee/{other_trainee.pk}/workout-history/')
        self.assertEqual(resp.status_code, 404)
