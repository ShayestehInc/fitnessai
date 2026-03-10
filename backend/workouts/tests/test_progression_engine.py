"""
Tests for the Progression Engine — v6.5 Step 7.

Covers:
- Unit tests for all 5 evaluators (staircase_percent, rep_staircase, double_progression, linear, wave_by_month)
- compute_next_prescription: no profile, gap > 14 days, normal operation
- evaluate_progression_readiness: no max, no history, deload week, ready state
- apply_progression: creates event + decision log, updates slot, trainee restriction
- Helper functions: _hold_prescription, _round_load, _check_completion, _count_consecutive_failures
- _resolve_load_unit with LiftMax vs LiftSetLog fallback
- Seed command runs without error
- ProgressionProfileViewSet: role-based CRUD
- PlanSlotViewSet progression actions: next-prescription, apply-progression, progression-history, progression-readiness
"""
from __future__ import annotations

import uuid
from datetime import date, timedelta
from decimal import Decimal
from typing import Any
from unittest.mock import patch

from django.core.management import call_command
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User
from workouts.models import (
    DecisionLog,
    Exercise,
    LiftMax,
    LiftSetLog,
    PlanSession,
    PlanSlot,
    PlanWeek,
    ProgressionEvent,
    ProgressionProfile,
    TrainingPlan,
)
from workouts.services.progression_engine_service import (
    NextPrescription,
    ProgressionReadiness,
    _check_completion,
    _count_consecutive_failures,
    _hold_prescription,
    _resolve_load_unit,
    _round_load,
    apply_progression,
    compute_next_prescription,
    evaluate_progression_readiness,
    get_progression_history,
)


# ---------------------------------------------------------------------------
# Factories / helpers
# ---------------------------------------------------------------------------


class ProgressionTestBase(TestCase):
    """Shared setup: trainer, trainee, exercise, plan hierarchy, API clients."""

    def setUp(self) -> None:
        self.admin = User.objects.create_user(
            email="admin@test.com",
            password="testpass123",
            role="ADMIN",
        )
        self.trainer = User.objects.create_user(
            email="trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee = User.objects.create_user(
            email="trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.other_trainer = User.objects.create_user(
            email="other_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.other_trainee = User.objects.create_user(
            email="other_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.other_trainer,
        )

        # Exercise
        self.exercise = Exercise.objects.create(
            name="Barbell Bench Press",
            primary_muscle_group="chest",
            equipment="barbell",
            is_public=True,
        )
        self.lower_exercise = Exercise.objects.create(
            name="Barbell Squat",
            primary_muscle_group="quads",
            equipment="barbell",
            is_public=True,
        )

        # Progression profiles
        self.staircase_profile = ProgressionProfile.objects.create(
            name="Test Staircase Percent",
            slug="test-staircase-percent",
            progression_type="staircase_percent",
            rules={"step_pct": 2.5, "work_weeks": 4, "start_pct": 75},
            deload_rules={
                "intensity_drop_pct": 10,
                "deload_pct": 65,
                "volume_drop_pct": 40,
            },
            failure_rules={"consecutive_failures_for_deload": 2},
            is_system=True,
        )
        self.rep_staircase_profile = ProgressionProfile.objects.create(
            name="Test Rep Staircase",
            slug="test-rep-staircase",
            progression_type="rep_staircase",
            rules={
                "rep_step": 1,
                "load_increment_upper_lb": 5,
                "load_increment_lower_lb": 10,
            },
            deload_rules={},
            failure_rules={
                "consecutive_failures_for_deload": 2,
                "action": "reduce_load",
                "load_reduction_pct": 5,
            },
            is_system=True,
        )
        self.double_prog_profile = ProgressionProfile.objects.create(
            name="Test Double Progression",
            slug="test-double-progression",
            progression_type="double_progression",
            rules={"load_increment_lb": 5, "target_rpe": 8, "lock_in": "practical"},
            deload_rules={},
            failure_rules={
                "consecutive_failures_for_deload": 2,
                "load_reduction_pct": 5,
            },
            is_system=True,
        )
        self.linear_profile = ProgressionProfile.objects.create(
            name="Test Linear",
            slug="test-linear",
            progression_type="linear",
            rules={"increment_lb": 5, "frequency": "session"},
            deload_rules={},
            failure_rules={"consecutive_failures_for_deload": 2, "deload_pct": 10},
            is_system=True,
        )
        self.wave_profile = ProgressionProfile.objects.create(
            name="Test Wave-by-Month",
            slug="test-wave-by-month",
            progression_type="wave_by_month",
            rules={
                "week_percentages": [75, 80, 85, 65],
                "week_reps": [10, 8, 5, 10],
                "week_sets": [5, 4, 5, 3],
            },
            deload_rules={},
            failure_rules={},
            is_system=True,
        )

        # Training plan hierarchy
        self.plan = TrainingPlan.objects.create(
            trainee=self.trainee,
            name="Test Plan",
            goal="strength",
            status="active",
            duration_weeks=8,
            created_by=self.trainer,
            default_progression_profile=self.staircase_profile,
        )
        self.week = PlanWeek.objects.create(
            plan=self.plan,
            week_number=1,
            is_deload=False,
        )
        self.deload_week = PlanWeek.objects.create(
            plan=self.plan,
            week_number=2,
            is_deload=True,
        )
        self.session = PlanSession.objects.create(
            week=self.week,
            day_of_week=0,
            label="Upper A",
            order=0,
        )
        self.deload_session = PlanSession.objects.create(
            week=self.deload_week,
            day_of_week=0,
            label="Deload Upper",
            order=0,
        )
        self.slot = PlanSlot.objects.create(
            session=self.session,
            exercise=self.exercise,
            order=1,
            slot_role="primary_compound",
            sets=4,
            reps_min=6,
            reps_max=8,
            rest_seconds=120,
            load_prescription_pct=Decimal("80.00"),
        )
        self.deload_slot = PlanSlot.objects.create(
            session=self.deload_session,
            exercise=self.exercise,
            order=1,
            slot_role="primary_compound",
            sets=3,
            reps_min=8,
            reps_max=10,
            rest_seconds=90,
        )

        # LiftMax
        self.lift_max = LiftMax.objects.create(
            trainee=self.trainee,
            exercise=self.exercise,
            e1rm_current=Decimal("225.00"),
            tm_current=Decimal("200.00"),
            tm_percentage=Decimal("90.00"),
        )

        # API clients
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(user=self.admin)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)

        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee)

        self.other_trainer_client = APIClient()
        self.other_trainer_client.force_authenticate(user=self.other_trainer)

    def _create_set_logs(
        self,
        exercise: Exercise | None = None,
        trainee: User | None = None,
        session_date: date | None = None,
        count: int = 4,
        reps: int = 8,
        load: Decimal = Decimal("160.00"),
        rpe: Decimal | None = Decimal("8.0"),
    ) -> list[LiftSetLog]:
        """Create a batch of LiftSetLog entries for one session."""
        exercise = exercise or self.exercise
        trainee = trainee or self.trainee
        session_date = session_date or date.today()
        logs: list[LiftSetLog] = []
        for i in range(1, count + 1):
            log = LiftSetLog.objects.create(
                trainee=trainee,
                exercise=exercise,
                session_date=session_date,
                set_number=i,
                entered_load_value=load,
                entered_load_unit="lb",
                canonical_external_load_value=load,
                canonical_external_load_unit="lb",
                completed_reps=reps,
                rpe=rpe,
            )
            logs.append(log)
        return logs


# ===========================================================================
# Helper function tests
# ===========================================================================


class RoundLoadTests(TestCase):
    """Tests for _round_load()."""

    def test_rounds_to_nearest_increment(self) -> None:
        self.assertEqual(_round_load(Decimal("152.3")), Decimal("152.5"))

    def test_rounds_down(self) -> None:
        self.assertEqual(_round_load(Decimal("151.1")), Decimal("150.0"))

    def test_exact_value_unchanged(self) -> None:
        self.assertEqual(_round_load(Decimal("150.0")), Decimal("150.0"))

    def test_custom_increment(self) -> None:
        self.assertEqual(
            _round_load(Decimal("153"), Decimal("5")),
            Decimal("155"),
        )

    def test_zero_increment_returns_as_is(self) -> None:
        self.assertEqual(_round_load(Decimal("153.7"), Decimal("0")), Decimal("153.7"))

    def test_negative_increment_returns_as_is(self) -> None:
        self.assertEqual(
            _round_load(Decimal("153.7"), Decimal("-1")), Decimal("153.7")
        )


class CheckCompletionTests(TestCase):
    """Tests for _check_completion()."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="t_check@test.com", password="testpass123", role="TRAINER"
        )
        self.trainee = User.objects.create_user(
            email="c_check@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.exercise = Exercise.objects.create(
            name="Test Exercise CC",
            primary_muscle_group="chest",
            is_public=True,
        )

    def _make_sets(self, reps_list: list[int]) -> list[LiftSetLog]:
        logs: list[LiftSetLog] = []
        for i, reps in enumerate(reps_list, 1):
            logs.append(
                LiftSetLog(
                    trainee=self.trainee,
                    exercise=self.exercise,
                    session_date=date.today(),
                    set_number=i,
                    completed_reps=reps,
                    canonical_external_load_value=Decimal("100"),
                    canonical_external_load_unit="lb",
                )
            )
        return logs

    def test_completed_all_sets_and_reps(self) -> None:
        sets = self._make_sets([8, 8, 8, 8])
        self.assertTrue(_check_completion(sets, 4, 6))

    def test_fewer_sets_than_prescribed(self) -> None:
        sets = self._make_sets([8, 8])
        self.assertFalse(_check_completion(sets, 4, 6))

    def test_one_set_below_rep_min(self) -> None:
        sets = self._make_sets([8, 8, 5, 8])
        self.assertFalse(_check_completion(sets, 4, 6))

    def test_empty_sets(self) -> None:
        self.assertFalse(_check_completion([], 4, 6))

    def test_extra_sets_only_first_n_checked(self) -> None:
        sets = self._make_sets([8, 8, 8, 8, 3])
        self.assertTrue(_check_completion(sets, 4, 6))


class CountConsecutiveFailuresTests(TestCase):
    """Tests for _count_consecutive_failures()."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="t_ccf@test.com", password="testpass123", role="TRAINER"
        )
        self.trainee = User.objects.create_user(
            email="c_ccf@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.exercise = Exercise.objects.create(
            name="Test Exercise CCF",
            primary_muscle_group="chest",
            is_public=True,
        )

    def _make_session(self, reps_list: list[int]) -> list[LiftSetLog]:
        return [
            LiftSetLog(
                trainee=self.trainee,
                exercise=self.exercise,
                session_date=date.today(),
                set_number=i,
                completed_reps=reps,
                canonical_external_load_value=Decimal("100"),
                canonical_external_load_unit="lb",
            )
            for i, reps in enumerate(reps_list, 1)
        ]

    def test_no_failures(self) -> None:
        sessions = [self._make_session([8, 8, 8, 8])]
        self.assertEqual(_count_consecutive_failures(sessions, 4, 6), 0)

    def test_one_failure_then_success(self) -> None:
        sessions = [
            self._make_session([5, 5, 5, 5]),  # most recent = fail
            self._make_session([8, 8, 8, 8]),  # older = pass
        ]
        self.assertEqual(_count_consecutive_failures(sessions, 4, 6), 1)

    def test_two_consecutive_failures(self) -> None:
        sessions = [
            self._make_session([4, 4, 4, 4]),
            self._make_session([5, 5, 5, 5]),
        ]
        self.assertEqual(_count_consecutive_failures(sessions, 4, 6), 2)

    def test_empty_sessions(self) -> None:
        self.assertEqual(_count_consecutive_failures([], 4, 6), 0)


class ResolveLoadUnitTests(TestCase):
    """Tests for _resolve_load_unit()."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="t_rlu@test.com", password="testpass123", role="TRAINER"
        )
        self.trainee = User.objects.create_user(
            email="c_rlu@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.exercise = Exercise.objects.create(
            name="Test Exercise RLU",
            primary_muscle_group="chest",
            is_public=True,
        )

    def test_defaults_to_lb_when_no_data(self) -> None:
        self.assertEqual(_resolve_load_unit(None, []), "lb")

    def test_uses_set_log_unit_as_fallback(self) -> None:
        log = LiftSetLog(
            trainee=self.trainee,
            exercise=self.exercise,
            session_date=date.today(),
            set_number=1,
            completed_reps=8,
            canonical_external_load_value=Decimal("100"),
            canonical_external_load_unit="kg",
        )
        self.assertEqual(_resolve_load_unit(None, [[log]]), "kg")

    def test_lift_max_without_load_unit_falls_through(self) -> None:
        lift_max = LiftMax(
            trainee=self.trainee,
            exercise=self.exercise,
            tm_current=Decimal("200"),
        )
        # LiftMax doesn't have load_unit field; hasattr check should return False
        self.assertEqual(_resolve_load_unit(lift_max, []), "lb")


class HoldPrescriptionTests(ProgressionTestBase):
    """Tests for _hold_prescription()."""

    def test_returns_hold_event_type(self) -> None:
        result = _hold_prescription(self.slot, "linear", ["no_history"])
        self.assertEqual(result.event_type, "hold")
        self.assertEqual(result.progression_type, "linear")
        self.assertIn("no_history", result.reason_codes)

    def test_preserves_slot_prescription(self) -> None:
        result = _hold_prescription(self.slot, "linear", ["test"])
        self.assertEqual(result.sets, self.slot.sets)
        self.assertEqual(result.reps_min, self.slot.reps_min)
        self.assertEqual(result.reps_max, self.slot.reps_max)

    def test_confidence_is_low(self) -> None:
        result = _hold_prescription(self.slot, "linear", ["test"])
        self.assertEqual(result.confidence, "low")


# ===========================================================================
# Evaluator tests
# ===========================================================================


class StaircasePercentEvaluatorTests(ProgressionTestBase):
    """Tests for _evaluate_staircase_percent."""

    def test_normal_step_progression(self) -> None:
        """First step: start_pct + 0*step_pct = 75% TM."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=2))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.progression_type, "staircase_percent")
        self.assertEqual(result.event_type, "progression")
        # 75% of 200 TM = 150
        self.assertEqual(result.load_value, Decimal("150.0"))
        self.assertEqual(result.confidence, "high")

    def test_deload_after_consecutive_failures(self) -> None:
        """Two failures in a row triggers deload."""
        # Two failed sessions
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=3),
        )
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "deload")
        self.assertIn("consecutive_failures", result.reason_codes)
        self.assertIn("deload_triggered", result.reason_codes)

    def test_no_lift_max_gives_low_confidence(self) -> None:
        """Without a TM, load_value is None and confidence is low."""
        self.lift_max.delete()
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=2))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertIsNone(result.load_value)
        self.assertEqual(result.confidence, "low")

    def test_load_capped_at_100_percent(self) -> None:
        """Percentage should never exceed 100% TM."""
        # Create enough progression events to push step beyond 100%
        for i in range(20):
            ProgressionEvent.objects.create(
                trainee=self.trainee,
                exercise=self.exercise,
                plan_slot=self.slot,
                event_type="progression",
                reason_codes=["step_progression"],
            )
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=2))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        if result.load_percentage is not None:
            self.assertLessEqual(result.load_percentage, Decimal("100"))


class RepStaircaseEvaluatorTests(ProgressionTestBase):
    """Tests for _evaluate_rep_staircase."""

    def setUp(self) -> None:
        super().setUp()
        self.slot.progression_profile = self.rep_staircase_profile
        self.slot.save()

    def test_rep_climb_when_completed(self) -> None:
        """Completed session below reps_max -> climb reps."""
        # Last session: 4x7 (completed, below reps_max=8)
        self._create_set_logs(reps=7, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")
        self.assertIn("rep_climb", result.reason_codes)
        self.assertEqual(result.reps_min, 8)  # 7 + 1 rep_step

    def test_top_rung_increases_load_upper_body(self) -> None:
        """At reps_max -> load +5lb (upper body), reps reset."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")
        self.assertIn("top_rung_reached", result.reason_codes)
        self.assertEqual(result.reps_min, self.slot.reps_min)  # reset to bottom
        self.assertEqual(result.load_value, Decimal("165.0"))  # 160 + 5

    def test_top_rung_lower_body_larger_increment(self) -> None:
        """Lower body exercise gets +10lb increment."""
        # Create slot with lower body exercise
        lower_slot = PlanSlot.objects.create(
            session=self.session,
            exercise=self.lower_exercise,
            order=2,
            slot_role="primary_compound",
            sets=4,
            reps_min=6,
            reps_max=8,
            rest_seconds=120,
            progression_profile=self.rep_staircase_profile,
        )
        LiftMax.objects.create(
            trainee=self.trainee,
            exercise=self.lower_exercise,
            e1rm_current=Decimal("315"),
            tm_current=Decimal("280"),
        )
        self._create_set_logs(
            exercise=self.lower_exercise,
            reps=8,
            load=Decimal("200"),
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(lower_slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")
        self.assertIn("top_rung_reached", result.reason_codes)
        self.assertEqual(result.load_value, Decimal("210.0"))  # 200 + 10

    def test_hold_when_not_completed(self) -> None:
        """Incomplete session -> hold."""
        self._create_set_logs(reps=4, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("incomplete_session", result.reason_codes)

    def test_no_history_returns_hold(self) -> None:
        """No LiftSetLog history -> hold with no_history."""
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("no_history", result.reason_codes)

    def test_failure_reduces_load(self) -> None:
        """Two consecutive failures -> reduce load by 5%."""
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=3),
        )
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "failure")
        self.assertIn("consecutive_failures", result.reason_codes)
        # 160 * (1 - 0.05) = 152 -> rounded to 152.5
        self.assertEqual(result.load_value, Decimal("152.5"))


class DoubleProgressionEvaluatorTests(ProgressionTestBase):
    """Tests for _evaluate_double_progression."""

    def setUp(self) -> None:
        super().setUp()
        self.slot.progression_profile = self.double_prog_profile
        self.slot.save()

    def test_all_sets_at_top_increases_load(self) -> None:
        """All sets hit reps_max at target RPE -> load increases."""
        self._create_set_logs(
            reps=8,  # reps_max
            rpe=Decimal("8.0"),
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")
        self.assertIn("all_sets_at_top", result.reason_codes)
        self.assertEqual(result.load_value, Decimal("165.0"))  # 160 + 5

    def test_hold_when_not_all_at_top(self) -> None:
        """Not all sets at reps_max -> hold (keep working in range)."""
        self._create_set_logs(
            reps=7,  # below reps_max
            rpe=Decimal("8.0"),
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("working_in_range", result.reason_codes)

    def test_hold_when_effort_too_high(self) -> None:
        """All sets at top but RPE > 9 (too hard) -> hold."""
        self._create_set_logs(
            reps=8,
            rpe=Decimal("10.0"),  # RPE 10, target is 8, tolerance is 1
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")

    def test_no_rpe_still_progresses(self) -> None:
        """All sets at top with no RPE data -> progresses (avg is None)."""
        self._create_set_logs(
            reps=8,
            rpe=None,
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")

    def test_failure_reduces_load(self) -> None:
        """Two consecutive failures -> reduce load."""
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=3),
        )
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "failure")
        self.assertIn("consecutive_failures", result.reason_codes)

    def test_no_history_returns_hold(self) -> None:
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("no_history", result.reason_codes)


class LinearEvaluatorTests(ProgressionTestBase):
    """Tests for _evaluate_linear."""

    def setUp(self) -> None:
        super().setUp()
        self.slot.progression_profile = self.linear_profile
        self.slot.save()

    def test_completed_session_increases_load(self) -> None:
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")
        self.assertEqual(result.load_value, Decimal("165.0"))  # 160 + 5

    def test_incomplete_session_holds(self) -> None:
        self._create_set_logs(reps=4, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("incomplete_session", result.reason_codes)

    def test_two_failures_triggers_deload(self) -> None:
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=3),
        )
        self._create_set_logs(
            reps=3,
            session_date=date.today() - timedelta(days=1),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "deload")
        self.assertIn("consecutive_failures", result.reason_codes)
        # 160 * 0.9 = 144 -> rounded to 145
        self.assertEqual(result.load_value, Decimal("145.0"))

    def test_no_history_returns_hold(self) -> None:
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("no_history", result.reason_codes)


class WaveByMonthEvaluatorTests(ProgressionTestBase):
    """Tests for _evaluate_wave_by_month."""

    def setUp(self) -> None:
        super().setUp()
        self.slot.progression_profile = self.wave_profile
        self.slot.save()

    def test_week_1_accumulation(self) -> None:
        """First week: accumulation at 75% TM, 5x10."""
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.progression_type, "wave_by_month")
        self.assertEqual(result.event_type, "progression")
        self.assertEqual(result.load_percentage, Decimal("75"))
        self.assertEqual(result.sets, 5)
        self.assertEqual(result.reps_min, 10)
        self.assertEqual(result.load_value, Decimal("150.0"))  # 200 * 0.75

    def test_week_4_deload(self) -> None:
        """After 3 progression events -> deload week (week 4, index 3)."""
        for _ in range(3):
            ProgressionEvent.objects.create(
                trainee=self.trainee,
                exercise=self.exercise,
                plan_slot=self.slot,
                event_type="progression",
                reason_codes=["wave_progression"],
            )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "deload")
        self.assertEqual(result.load_percentage, Decimal("65"))
        self.assertEqual(result.sets, 3)
        self.assertEqual(result.reps_min, 10)

    def test_no_lift_max_gives_no_load_value(self) -> None:
        self.lift_max.delete()
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertIsNone(result.load_value)
        self.assertEqual(result.confidence, "low")

    def test_wave_cycles_back_after_4_weeks(self) -> None:
        """After 4 events, cycles back to week 1 (accumulation)."""
        for i in range(4):
            event_type = "deload" if i == 3 else "progression"
            ProgressionEvent.objects.create(
                trainee=self.trainee,
                exercise=self.exercise,
                plan_slot=self.slot,
                event_type=event_type,
                reason_codes=["wave"],
            )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "progression")
        self.assertEqual(result.load_percentage, Decimal("75"))


# ===========================================================================
# compute_next_prescription top-level tests
# ===========================================================================


class ComputeNextPrescriptionTests(ProgressionTestBase):
    """Tests for the top-level compute_next_prescription function."""

    def test_no_profile_returns_hold(self) -> None:
        """Slot and plan with no profile -> hold."""
        self.plan.default_progression_profile = None
        self.plan.save()
        self.slot.progression_profile = None
        self.slot.save()
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("no_progression_profile", result.reason_codes)

    def test_slot_profile_overrides_plan_default(self) -> None:
        """Slot profile takes precedence over plan default."""
        self.slot.progression_profile = self.linear_profile
        self.slot.save()
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.progression_type, "linear")

    def test_gap_over_14_days_triggers_deload(self) -> None:
        """Training gap > 14 days triggers automatic 10% deload."""
        self._create_set_logs(
            reps=8,
            session_date=date.today() - timedelta(days=20),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "deload")
        self.assertIn("training_gap", result.reason_codes)
        self.assertEqual(result.load_percentage, Decimal("90"))
        # 200 * 0.90 = 180
        self.assertEqual(result.load_value, Decimal("180.0"))

    def test_gap_deload_without_lift_max(self) -> None:
        """Gap deload with no TM -> load_value is None."""
        self.lift_max.delete()
        self._create_set_logs(
            reps=8,
            session_date=date.today() - timedelta(days=20),
        )
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "deload")
        self.assertIsNone(result.load_value)

    def test_unsupported_progression_type_returns_hold(self) -> None:
        """Unknown progression_type -> hold with unsupported_type."""
        bad_profile = ProgressionProfile.objects.create(
            name="Bad Profile",
            slug="bad-profile",
            progression_type="nonexistent_type",
            rules={},
            deload_rules={},
            failure_rules={},
        )
        self.slot.progression_profile = bad_profile
        self.slot.save()
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")
        self.assertIn("unsupported_type", result.reason_codes)

    def test_no_history_uses_evaluator_directly(self) -> None:
        """With no sessions, evaluator should handle it (e.g. rep_staircase returns hold)."""
        self.slot.progression_profile = self.rep_staircase_profile
        self.slot.save()
        result = compute_next_prescription(self.slot, self.trainee.pk)
        self.assertEqual(result.event_type, "hold")


# ===========================================================================
# evaluate_progression_readiness tests
# ===========================================================================


class EvaluateProgressionReadinessTests(ProgressionTestBase):
    """Tests for evaluate_progression_readiness."""

    def test_no_profile_blocker(self) -> None:
        self.plan.default_progression_profile = None
        self.plan.save()
        self.slot.progression_profile = None
        self.slot.save()
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertFalse(result.is_ready)
        self.assertIn("no_progression_profile", result.blockers)

    def test_no_lift_max_blocker(self) -> None:
        self.lift_max.delete()
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertIn("no_max", result.blockers)

    def test_insufficient_history_blocker(self) -> None:
        """Fewer than MIN_SESSIONS_FOR_PROGRESSION sessions -> blocker."""
        # Only 1 session
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertIn("insufficient_history", result.blockers)

    def test_gap_detected_blocker(self) -> None:
        """Session > 14 days ago -> gap blocker."""
        self._create_set_logs(
            reps=8,
            session_date=date.today() - timedelta(days=20),
        )
        self._create_set_logs(
            reps=8,
            session_date=date.today() - timedelta(days=21),
        )
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertIn("gap_detected", result.blockers)

    def test_deload_week_blocker(self) -> None:
        """Slot in a deload week -> deload_week blocker."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=3))
        result = evaluate_progression_readiness(self.deload_slot, self.trainee.pk)
        self.assertIn("deload_week", result.blockers)

    def test_ready_when_no_blockers(self) -> None:
        """All conditions met -> is_ready True."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=4))
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertTrue(result.is_ready)
        self.assertEqual(result.blockers, [])
        self.assertEqual(result.recent_sessions, 2)

    def test_completion_rate_calculated(self) -> None:
        """Sets_completed_rate is calculated correctly."""
        # Session 1: complete
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        # Session 2: incomplete (3 reps < reps_min=6)
        self._create_set_logs(reps=3, session_date=date.today() - timedelta(days=4))
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        # 1/2 completed = 50%
        self.assertEqual(result.sets_completed_rate, Decimal("50.0"))

    def test_consecutive_failures_counted(self) -> None:
        self._create_set_logs(reps=3, session_date=date.today() - timedelta(days=1))
        self._create_set_logs(reps=3, session_date=date.today() - timedelta(days=3))
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertEqual(result.consecutive_failures, 2)

    def test_avg_rpe_from_most_recent(self) -> None:
        self._create_set_logs(
            reps=8,
            rpe=Decimal("7.5"),
            session_date=date.today() - timedelta(days=1),
        )
        self._create_set_logs(
            reps=8,
            rpe=Decimal("9.0"),
            session_date=date.today() - timedelta(days=3),
        )
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        # Should be avg RPE from most recent session only
        self.assertEqual(result.avg_rpe, Decimal("7.5"))

    def test_no_sessions_returns_none_for_optional_fields(self) -> None:
        result = evaluate_progression_readiness(self.slot, self.trainee.pk)
        self.assertIsNone(result.last_session_date)
        self.assertIsNone(result.avg_rpe)
        self.assertIsNone(result.sets_completed_rate)


# ===========================================================================
# apply_progression tests
# ===========================================================================


class ApplyProgressionTests(ProgressionTestBase):
    """Tests for apply_progression service function."""

    def _make_prescription(self, **overrides: Any) -> NextPrescription:
        defaults = {
            "slot_id": str(self.slot.pk),
            "exercise_id": self.exercise.pk,
            "exercise_name": self.exercise.name,
            "progression_type": "linear",
            "event_type": "progression",
            "sets": 4,
            "reps_min": 6,
            "reps_max": 8,
            "load_value": Decimal("165.00"),
            "load_unit": "lb",
            "load_percentage": None,
            "reason_codes": ["session_completed", "load_increased"],
            "reason_display": "Completed. Load +5lb.",
            "confidence": "high",
        }
        defaults.update(overrides)
        return NextPrescription(**defaults)

    def test_creates_progression_event(self) -> None:
        prescription = self._make_prescription()
        result = apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=self.trainer.pk,
            trainee_id=self.trainee.pk,
        )
        self.assertEqual(result.event_type, "progression")
        event = ProgressionEvent.objects.get(pk=result.event_id)
        self.assertEqual(event.event_type, "progression")
        self.assertEqual(event.trainee_id, self.trainee.pk)
        self.assertEqual(event.exercise_id, self.exercise.pk)

    def test_creates_decision_log(self) -> None:
        prescription = self._make_prescription()
        result = apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=self.trainer.pk,
            trainee_id=self.trainee.pk,
        )
        log = DecisionLog.objects.get(pk=result.decision_log_id)
        self.assertEqual(log.decision_type, "progression_applied")
        self.assertEqual(log.actor_type, "user")
        self.assertIn("slot_id", log.context)

    def test_updates_slot_prescription(self) -> None:
        prescription = self._make_prescription(sets=5, reps_min=5, reps_max=7)
        apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=self.trainer.pk,
            trainee_id=self.trainee.pk,
        )
        self.slot.refresh_from_db()
        self.assertEqual(self.slot.sets, 5)
        self.assertEqual(self.slot.reps_min, 5)
        self.assertEqual(self.slot.reps_max, 7)

    def test_old_prescription_captured(self) -> None:
        old_sets = self.slot.sets
        old_reps_min = self.slot.reps_min
        prescription = self._make_prescription(sets=5)
        result = apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=self.trainer.pk,
            trainee_id=self.trainee.pk,
        )
        self.assertEqual(result.old_prescription["sets"], old_sets)
        self.assertEqual(result.old_prescription["reps_min"], old_reps_min)

    def test_system_actor_type(self) -> None:
        prescription = self._make_prescription()
        result = apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=None,
            trainee_id=self.trainee.pk,
            actor_type="system",
        )
        log = DecisionLog.objects.get(pk=result.decision_log_id)
        self.assertEqual(log.actor_type, "system")

    def test_progression_event_linked_to_profile(self) -> None:
        prescription = self._make_prescription()
        result = apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=self.trainer.pk,
            trainee_id=self.trainee.pk,
        )
        event = ProgressionEvent.objects.get(pk=result.event_id)
        self.assertEqual(event.progression_profile_id, self.staircase_profile.pk)

    def test_event_linked_to_decision_log(self) -> None:
        prescription = self._make_prescription()
        result = apply_progression(
            slot=self.slot,
            prescription=prescription,
            actor_id=self.trainer.pk,
            trainee_id=self.trainee.pk,
        )
        event = ProgressionEvent.objects.get(pk=result.event_id)
        self.assertIsNotNone(event.decision_log)
        self.assertEqual(str(event.decision_log.pk), result.decision_log_id)


# ===========================================================================
# get_progression_history tests
# ===========================================================================


class GetProgressionHistoryTests(ProgressionTestBase):
    """Tests for get_progression_history."""

    def test_returns_events_for_slot(self) -> None:
        for i in range(3):
            ProgressionEvent.objects.create(
                trainee=self.trainee,
                exercise=self.exercise,
                plan_slot=self.slot,
                event_type="progression",
                reason_codes=["test"],
            )
        events = get_progression_history(self.slot)
        self.assertEqual(len(events), 3)

    def test_ordered_newest_first(self) -> None:
        for i in range(3):
            ProgressionEvent.objects.create(
                trainee=self.trainee,
                exercise=self.exercise,
                plan_slot=self.slot,
                event_type="progression",
                reason_codes=[f"event_{i}"],
            )
        events = get_progression_history(self.slot)
        # Newest first: events[0].created_at >= events[1].created_at
        self.assertGreaterEqual(events[0].created_at, events[1].created_at)

    def test_max_50_events(self) -> None:
        for i in range(60):
            ProgressionEvent.objects.create(
                trainee=self.trainee,
                exercise=self.exercise,
                plan_slot=self.slot,
                event_type="progression",
                reason_codes=["test"],
            )
        events = get_progression_history(self.slot)
        self.assertLessEqual(len(events), 50)

    def test_does_not_include_other_slots(self) -> None:
        ProgressionEvent.objects.create(
            trainee=self.trainee,
            exercise=self.exercise,
            plan_slot=self.slot,
            event_type="progression",
            reason_codes=["mine"],
        )
        ProgressionEvent.objects.create(
            trainee=self.trainee,
            exercise=self.exercise,
            plan_slot=self.deload_slot,
            event_type="progression",
            reason_codes=["other"],
        )
        events = get_progression_history(self.slot)
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0].reason_codes, ["mine"])


# ===========================================================================
# Seed command test
# ===========================================================================


class SeedProgressionProfilesTests(TestCase):
    """Test that the seed command runs without error."""

    def test_seed_command_creates_profiles(self) -> None:
        call_command("seed_progression_profiles")
        self.assertGreaterEqual(ProgressionProfile.objects.filter(is_system=True).count(), 5)

    def test_seed_command_idempotent(self) -> None:
        """Running seed twice should not create duplicates."""
        call_command("seed_progression_profiles")
        count_first = ProgressionProfile.objects.filter(is_system=True).count()
        call_command("seed_progression_profiles")
        count_second = ProgressionProfile.objects.filter(is_system=True).count()
        self.assertEqual(count_first, count_second)


# ===========================================================================
# ProgressionProfileViewSet API tests
# ===========================================================================


class ProgressionProfileViewSetTests(ProgressionTestBase):
    """Tests for ProgressionProfile CRUD API."""

    LIST_URL = "/api/workouts/progression-profiles/"

    def _detail_url(self, pk: str) -> str:
        return f"{self.LIST_URL}{pk}/"

    def test_trainer_can_list_profiles(self) -> None:
        response = self.trainer_client.get(self.LIST_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_trainee_can_list_profiles(self) -> None:
        response = self.trainee_client.get(self.LIST_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_trainer_creates_non_system_profile(self) -> None:
        data = {
            "name": "Trainer Custom",
            "slug": "trainer-custom",
            "progression_type": "linear",
            "rules": {"increment_lb": 5},
            "deload_rules": {},
            "failure_rules": {},
        }
        response = self.trainer_client.post(self.LIST_URL, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        profile = ProgressionProfile.objects.get(slug="trainer-custom")
        self.assertFalse(profile.is_system)
        self.assertEqual(profile.created_by_id, self.trainer.pk)

    def test_admin_creates_system_profile(self) -> None:
        data = {
            "name": "Admin System",
            "slug": "admin-system",
            "progression_type": "linear",
            "rules": {"increment_lb": 10},
            "deload_rules": {},
            "failure_rules": {},
        }
        response = self.admin_client.post(self.LIST_URL, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        profile = ProgressionProfile.objects.get(slug="admin-system")
        self.assertTrue(profile.is_system)

    def test_trainee_cannot_create_profile(self) -> None:
        data = {
            "name": "Trainee Profile",
            "slug": "trainee-profile",
            "progression_type": "linear",
            "rules": {},
            "deload_rules": {},
            "failure_rules": {},
        }
        response = self.trainee_client.post(self.LIST_URL, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_cannot_modify_system_profile(self) -> None:
        url = self._detail_url(str(self.staircase_profile.pk))
        response = self.trainer_client.patch(
            url, {"name": "Hacked"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_modify_system_profile(self) -> None:
        url = self._detail_url(str(self.staircase_profile.pk))
        response = self.admin_client.patch(
            url, {"name": "Updated Name"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_trainer_cannot_delete_system_profile(self) -> None:
        url = self._detail_url(str(self.staircase_profile.pk))
        response = self.trainer_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_can_delete_own_profile(self) -> None:
        profile = ProgressionProfile.objects.create(
            name="My Profile",
            slug="my-profile",
            progression_type="linear",
            rules={},
            deload_rules={},
            failure_rules={},
            is_system=False,
            created_by=self.trainer,
        )
        url = self._detail_url(str(profile.pk))
        response = self.trainer_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

    def test_trainee_cannot_delete_profile(self) -> None:
        profile = ProgressionProfile.objects.create(
            name="Trainer Profile",
            slug="trainer-profile-del",
            progression_type="linear",
            rules={},
            deload_rules={},
            failure_rules={},
            is_system=False,
            created_by=self.trainer,
        )
        url = self._detail_url(str(profile.pk))
        response = self.trainee_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_other_trainer_cannot_see_trainer_profile(self) -> None:
        """Trainer-created profiles are only visible to creator + their trainees."""
        profile = ProgressionProfile.objects.create(
            name="Private Profile",
            slug="private-profile",
            progression_type="linear",
            rules={},
            deload_rules={},
            failure_rules={},
            is_system=False,
            created_by=self.trainer,
        )
        url = self._detail_url(str(profile.pk))
        response = self.other_trainer_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_trainee_sees_system_and_trainer_profiles(self) -> None:
        ProgressionProfile.objects.create(
            name="Trainer Custom 2",
            slug="trainer-custom-2",
            progression_type="linear",
            rules={},
            deload_rules={},
            failure_rules={},
            is_system=False,
            created_by=self.trainer,
        )
        response = self.trainee_client.get(self.LIST_URL)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data if isinstance(response.data, list) else response.data.get("results", response.data)
        slugs = {p["slug"] for p in results}
        self.assertIn("trainer-custom-2", slugs)

    def test_validate_rules_must_be_dict(self) -> None:
        data = {
            "name": "Bad Rules",
            "slug": "bad-rules",
            "progression_type": "linear",
            "rules": "not a dict",
            "deload_rules": {},
            "failure_rules": {},
        }
        response = self.trainer_client.post(self.LIST_URL, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


# ===========================================================================
# PlanSlotViewSet progression action tests
# ===========================================================================


class PlanSlotProgressionActionTests(ProgressionTestBase):
    """Tests for PlanSlot progression-related actions."""

    def _slot_url(self, action: str) -> str:
        return f"/api/workouts/plan-slots/{self.slot.pk}/{action}/"

    def test_next_prescription_returns_data(self) -> None:
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        response = self.trainer_client.get(self._slot_url("next-prescription"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("progression_type", response.data)
        self.assertIn("event_type", response.data)
        self.assertIn("load_value", response.data)
        self.assertIn("reason_codes", response.data)

    def test_next_prescription_trainee_can_view(self) -> None:
        """Trainees should be able to see their next prescription."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        response = self.trainee_client.get(self._slot_url("next-prescription"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_apply_progression_by_trainer(self) -> None:
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        response = self.trainer_client.post(
            self._slot_url("apply-progression"), {}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("event_id", response.data)
        self.assertIn("decision_log_id", response.data)

    def test_apply_progression_trainee_blocked(self) -> None:
        """Trainees cannot apply progression."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        response = self.trainee_client.post(
            self._slot_url("apply-progression"), {}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_apply_progression_admin_allowed(self) -> None:
        """Admins can apply progression."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        response = self.admin_client.post(
            self._slot_url("apply-progression"), {}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_apply_progression_with_overrides(self) -> None:
        """Trainer can override computed prescription."""
        self._create_set_logs(reps=8, session_date=date.today() - timedelta(days=1))
        response = self.trainer_client.post(
            self._slot_url("apply-progression"),
            {"override_sets": 5, "override_reps_min": 4, "override_load": "170.00"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.slot.refresh_from_db()
        self.assertEqual(self.slot.sets, 5)
        self.assertEqual(self.slot.reps_min, 4)

    def test_progression_history_returns_events(self) -> None:
        ProgressionEvent.objects.create(
            trainee=self.trainee,
            exercise=self.exercise,
            plan_slot=self.slot,
            event_type="progression",
            reason_codes=["test"],
        )
        response = self.trainer_client.get(self._slot_url("progression-history"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data), 1)

    def test_progression_history_empty(self) -> None:
        response = self.trainer_client.get(self._slot_url("progression-history"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)

    def test_progression_readiness_returns_data(self) -> None:
        response = self.trainer_client.get(self._slot_url("progression-readiness"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("is_ready", response.data)
        self.assertIn("blockers", response.data)
        self.assertIn("consecutive_failures", response.data)

    def test_progression_readiness_shows_blockers(self) -> None:
        self.lift_max.delete()
        response = self.trainer_client.get(self._slot_url("progression-readiness"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["is_ready"])
        self.assertIn("no_max", response.data["blockers"])

    def test_other_trainer_cannot_access_slot_actions(self) -> None:
        """Row-level security: other trainer can't see this slot."""
        response = self.other_trainer_client.get(self._slot_url("next-prescription"))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_unauthenticated_cannot_access(self) -> None:
        anon_client = APIClient()
        response = anon_client.get(self._slot_url("next-prescription"))
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])


# ===========================================================================
# NextPrescription dataclass sanity tests
# ===========================================================================


class NextPrescriptionDataclassTests(TestCase):
    """Sanity tests for the NextPrescription frozen dataclass."""

    def test_frozen(self) -> None:
        p = NextPrescription(
            slot_id="abc",
            exercise_id=1,
            exercise_name="Bench",
            progression_type="linear",
            event_type="progression",
            sets=4,
            reps_min=6,
            reps_max=8,
            load_value=Decimal("100"),
            load_unit="lb",
            load_percentage=None,
            reason_codes=["test"],
            reason_display="Test",
            confidence="high",
        )
        with self.assertRaises(AttributeError):
            p.sets = 5  # type: ignore[misc]

    def test_all_fields_present(self) -> None:
        p = NextPrescription(
            slot_id="abc",
            exercise_id=1,
            exercise_name="Bench",
            progression_type="linear",
            event_type="hold",
            sets=3,
            reps_min=8,
            reps_max=10,
            load_value=None,
            load_unit="lb",
            load_percentage=Decimal("80"),
            reason_codes=["no_history"],
            reason_display="Hold: no changes.",
            confidence="low",
        )
        self.assertEqual(p.slot_id, "abc")
        self.assertIsNone(p.load_value)
        self.assertEqual(p.load_percentage, Decimal("80"))
