"""
Tests for the Session Runner — v6.5 Step 8.

Covers:
- start_session: normal flow, duplicate active session, stale session auto-abandon,
  IDOR (wrong trainee), invalid plan_session, zero-slot session
- log_set: normal flow, session not in_progress, invalid slot/set, creates LiftSetLog,
  auto-advance slot index, already completed set, zero-rep log
- skip_set: normal flow, with reason, already completed set
- complete_session: normal flow, triggers LiftMax recalc, progression integration,
  already completed, pending sets remaining, all-skipped session
- abandon_session: normal flow, preserves partial data, no progression evaluation
- get_session_status: full status, progress percentage
- get_active_session: returns active, returns None when none
- Rest timer: slot_role defaults, modality overrides, between-exercise bonus, trainer override
- API endpoints: auth required, role enforcement (trainee only), IDOR protection
- Edge cases: all-skipped session, zero-slot session, zero-rep log
"""
from __future__ import annotations

import uuid
from datetime import timedelta
from decimal import Decimal
from unittest.mock import MagicMock, patch

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User
from workouts.models import (
    ActiveSession,
    ActiveSetLog,
    DecisionLog,
    Exercise,
    LiftMax,
    LiftSetLog,
    PlanSession,
    PlanSlot,
    PlanWeek,
    ProgressionProfile,
    SetStructureModality,
    TrainingPlan,
)
from workouts.services.rest_timer_service import (
    RestPrescription,
    get_rest_duration,
)
from workouts.services.session_runner_service import (
    SessionError,
    SessionStatus,
    SessionSummary,
    abandon_session,
    complete_session,
    get_active_session,
    get_session_status,
    log_set,
    skip_set,
    start_session,
)


# ---------------------------------------------------------------------------
# Shared setup
# ---------------------------------------------------------------------------


class SessionRunnerTestBase(TestCase):
    """Shared setup: trainer, trainee, exercise, plan hierarchy, API clients."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="sr_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee = User.objects.create_user(
            email="sr_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.other_trainer = User.objects.create_user(
            email="sr_other_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.other_trainee = User.objects.create_user(
            email="sr_other_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.other_trainer,
        )
        self.admin = User.objects.create_user(
            email="sr_admin@test.com",
            password="testpass123",
            role="ADMIN",
        )

        # Exercises
        self.exercise_bench = Exercise.objects.create(
            name="Bench Press",
            primary_muscle_group="chest",
            equipment="barbell",
            is_public=True,
        )
        self.exercise_squat = Exercise.objects.create(
            name="Barbell Squat",
            primary_muscle_group="quads",
            equipment="barbell",
            is_public=True,
        )
        self.exercise_curl = Exercise.objects.create(
            name="Bicep Curl",
            primary_muscle_group="biceps",
            equipment="dumbbell",
            is_public=True,
        )

        # Progression profile
        self.profile = ProgressionProfile.objects.create(
            name="Test Double Prog",
            slug="test-double-prog-sr",
            progression_type="double_progression",
            rules={"load_increment_lb": 5, "target_rpe": 8, "lock_in": "practical"},
            deload_rules={},
            failure_rules={
                "consecutive_failures_for_deload": 2,
                "load_reduction_pct": 5,
            },
            is_system=True,
        )

        # Training plan hierarchy
        self.plan = TrainingPlan.objects.create(
            trainee=self.trainee,
            name="Session Runner Test Plan",
            goal="strength",
            status="active",
            duration_weeks=8,
            created_by=self.trainer,
            default_progression_profile=self.profile,
        )
        self.week = PlanWeek.objects.create(
            plan=self.plan,
            week_number=1,
            is_deload=False,
        )
        self.plan_session = PlanSession.objects.create(
            week=self.week,
            day_of_week=0,
            label="Upper A",
            order=0,
        )
        # Slot 1: primary compound, 3 sets
        self.slot1 = PlanSlot.objects.create(
            session=self.plan_session,
            exercise=self.exercise_bench,
            order=1,
            slot_role="primary_compound",
            sets=3,
            reps_min=6,
            reps_max=8,
            rest_seconds=90,
        )
        # Slot 2: accessory, 2 sets
        self.slot2 = PlanSlot.objects.create(
            session=self.plan_session,
            exercise=self.exercise_curl,
            order=2,
            slot_role="accessory",
            sets=2,
            reps_min=10,
            reps_max=12,
            rest_seconds=90,
        )

        # Other trainee's plan (for IDOR tests)
        self.other_plan = TrainingPlan.objects.create(
            trainee=self.other_trainee,
            name="Other Plan",
            goal="hypertrophy",
            status="active",
            duration_weeks=4,
            created_by=self.other_trainer,
        )
        self.other_week = PlanWeek.objects.create(
            plan=self.other_plan,
            week_number=1,
            is_deload=False,
        )
        self.other_plan_session = PlanSession.objects.create(
            week=self.other_week,
            day_of_week=1,
            label="Other Upper",
            order=0,
        )
        PlanSlot.objects.create(
            session=self.other_plan_session,
            exercise=self.exercise_bench,
            order=1,
            slot_role="primary_compound",
            sets=3,
            reps_min=6,
            reps_max=8,
            rest_seconds=90,
        )

        # API clients
        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)

        self.other_trainee_client = APIClient()
        self.other_trainee_client.force_authenticate(user=self.other_trainee)

        self.admin_client = APIClient()
        self.admin_client.force_authenticate(user=self.admin)

        self.anon_client = APIClient()

    def _start_session(self, trainee_id: int | None = None, plan_session_id: str | None = None) -> SessionStatus:
        """Helper to start a session with default or custom args."""
        return start_session(
            trainee_id=trainee_id or self.trainee.pk,
            plan_session_id=plan_session_id or str(self.plan_session.pk),
        )

    def _log_all_sets(self, session_id: str) -> None:
        """Log all pending sets for a session."""
        set_logs = ActiveSetLog.objects.filter(
            active_session_id=session_id,
            status=ActiveSetLog.Status.PENDING,
        ).order_by('plan_slot__order', 'set_number')
        for sl in set_logs:
            log_set(
                active_session_id=session_id,
                slot_id=str(sl.plan_slot_id),
                set_number=sl.set_number,
                completed_reps=8,
                load_value=Decimal("135.00"),
                load_unit='lb',
            )

    def _skip_all_sets(self, session_id: str) -> None:
        """Skip all pending sets for a session."""
        set_logs = ActiveSetLog.objects.filter(
            active_session_id=session_id,
            status=ActiveSetLog.Status.PENDING,
        ).order_by('plan_slot__order', 'set_number')
        for sl in set_logs:
            skip_set(
                active_session_id=session_id,
                slot_id=str(sl.plan_slot_id),
                set_number=sl.set_number,
                reason='test skip',
            )


# ---------------------------------------------------------------------------
# start_session tests
# ---------------------------------------------------------------------------


class StartSessionTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_normal_flow(self, mock_prescription: MagicMock) -> None:
        """Starting a session creates ActiveSession + ActiveSetLog rows."""
        mock_prescription.return_value = self._mock_prescription()

        result = self._start_session()

        self.assertEqual(result.status, 'in_progress')
        self.assertEqual(result.trainee_id, self.trainee.pk)
        self.assertEqual(result.plan_session_id, str(self.plan_session.pk))
        self.assertEqual(result.total_sets, 5)  # 3 + 2
        self.assertEqual(result.completed_sets, 0)
        self.assertEqual(result.pending_sets, 5)
        self.assertEqual(result.progress_pct, 0.0)
        self.assertEqual(result.current_slot_index, 0)
        self.assertEqual(len(result.slots), 2)

        # Verify DB state
        session = ActiveSession.objects.get(pk=result.active_session_id)
        self.assertEqual(session.status, ActiveSession.Status.IN_PROGRESS)
        self.assertEqual(
            ActiveSetLog.objects.filter(active_session=session).count(),
            5,
        )

        # Verify DecisionLog was created
        decision = DecisionLog.objects.filter(
            decision_type='session_started',
        ).latest('created_at')
        self.assertEqual(
            decision.context['active_session_id'],
            str(session.pk),
        )

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_duplicate_active(self, mock_prescription: MagicMock) -> None:
        """Cannot start a second session while one is in_progress."""
        mock_prescription.return_value = self._mock_prescription()

        self._start_session()

        with self.assertRaises(SessionError) as ctx:
            self._start_session()

        self.assertEqual(ctx.exception.error_code, 'active_session_exists')
        self.assertIn('active_session_id', ctx.exception.extra)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_stale_auto_abandon(self, mock_prescription: MagicMock) -> None:
        """Stale sessions (>4h) are auto-abandoned on start_session."""
        mock_prescription.return_value = self._mock_prescription()

        # Create a stale session
        stale_time = timezone.now() - timedelta(hours=5)
        stale_session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.IN_PROGRESS,
            started_at=stale_time,
        )

        # Starting a new session should auto-abandon the stale one
        result = self._start_session()

        self.assertEqual(result.status, 'in_progress')
        stale_session.refresh_from_db()
        self.assertEqual(stale_session.status, ActiveSession.Status.ABANDONED)
        self.assertEqual(stale_session.abandon_reason, 'auto_abandoned_stale')

    def test_start_session_idor_other_trainee_plan(self) -> None:
        """Cannot start a session from another trainee's plan."""
        with self.assertRaises(SessionError) as ctx:
            start_session(
                trainee_id=self.trainee.pk,
                plan_session_id=str(self.other_plan_session.pk),
            )
        self.assertEqual(ctx.exception.error_code, 'plan_session_not_found')

    def test_start_session_invalid_plan_session_id(self) -> None:
        """Invalid plan_session_id returns plan_session_not_found."""
        fake_id = str(uuid.uuid4())
        with self.assertRaises(SessionError) as ctx:
            start_session(
                trainee_id=self.trainee.pk,
                plan_session_id=fake_id,
            )
        self.assertEqual(ctx.exception.error_code, 'plan_session_not_found')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_zero_slots(self, mock_prescription: MagicMock) -> None:
        """Session with no slots returns no_exercises_in_session."""
        empty_session = PlanSession.objects.create(
            week=self.week,
            day_of_week=2,
            label="Empty Day",
            order=1,
        )
        with self.assertRaises(SessionError) as ctx:
            start_session(
                trainee_id=self.trainee.pk,
                plan_session_id=str(empty_session.pk),
            )
        self.assertEqual(ctx.exception.error_code, 'no_exercises_in_session')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_prescription_fallback(self, mock_prescription: MagicMock) -> None:
        """If progression engine fails, falls back to base prescription."""
        mock_prescription.side_effect = ValueError("no max found")

        result = self._start_session()

        # Should still succeed with fallback prescription
        self.assertEqual(result.status, 'in_progress')
        self.assertEqual(result.total_sets, 5)

        # Verify set logs have base prescription values
        set_log = ActiveSetLog.objects.filter(
            active_session_id=result.active_session_id,
            plan_slot=self.slot1,
            set_number=1,
        ).first()
        self.assertIsNotNone(set_log)
        self.assertEqual(set_log.prescribed_reps_min, self.slot1.reps_min)
        self.assertEqual(set_log.prescribed_reps_max, self.slot1.reps_max)
        self.assertIsNone(set_log.prescribed_load)

    def _mock_prescription(self, load: Decimal | None = Decimal("135.00")) -> MagicMock:
        from workouts.services.progression_engine_service import NextPrescription
        return NextPrescription(
            slot_id=str(uuid.uuid4()),
            exercise_id=self.exercise_bench.pk,
            exercise_name="Bench Press",
            progression_type='double_progression',
            event_type='hold',
            sets=3,
            reps_min=6,
            reps_max=8,
            load_value=load,
            load_unit='lb',
            load_percentage=None,
            reason_codes=['normal'],
            reason_display='Normal prescription.',
            confidence='high',
        )


# ---------------------------------------------------------------------------
# log_set tests
# ---------------------------------------------------------------------------


class LogSetTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_normal_flow(self, mock_prescription: MagicMock) -> None:
        """Logging a set marks it completed and returns updated status."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        first_log = ActiveSetLog.objects.filter(
            active_session_id=session_id,
            plan_slot=self.slot1,
            set_number=1,
        ).first()

        result = log_set(
            active_session_id=session_id,
            slot_id=str(first_log.plan_slot_id),
            set_number=1,
            completed_reps=8,
            load_value=Decimal("140.00"),
            load_unit='lb',
            rpe=Decimal("7.5"),
            rest_actual_seconds=120,
            notes='Felt strong',
        )

        self.assertEqual(result.completed_sets, 1)
        self.assertEqual(result.pending_sets, 4)

        first_log.refresh_from_db()
        self.assertEqual(first_log.status, ActiveSetLog.Status.COMPLETED)
        self.assertEqual(first_log.completed_reps, 8)
        self.assertEqual(first_log.completed_load_value, Decimal("140.00"))
        self.assertEqual(first_log.rpe, Decimal("7.5"))
        self.assertEqual(first_log.notes, 'Felt strong')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_on_completed_session(self, mock_prescription: MagicMock) -> None:
        """Cannot log a set on a completed session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        self._log_all_sets(session_id)
        complete_session(session_id, actor_id=self.trainee.pk)

        with self.assertRaises(SessionError) as ctx:
            log_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=1,
                completed_reps=8,
            )
        self.assertEqual(ctx.exception.error_code, 'session_already_completed')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_on_abandoned_session(self, mock_prescription: MagicMock) -> None:
        """Cannot log a set on an abandoned session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        abandon_session(session_id, actor_id=self.trainee.pk, reason='tired')

        with self.assertRaises(SessionError) as ctx:
            log_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=1,
                completed_reps=8,
            )
        self.assertEqual(ctx.exception.error_code, 'session_already_abandoned')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_invalid_slot(self, mock_prescription: MagicMock) -> None:
        """Logging a set with invalid slot_id raises set_not_found."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()

        with self.assertRaises(SessionError) as ctx:
            log_set(
                active_session_id=session_status.active_session_id,
                slot_id=str(uuid.uuid4()),
                set_number=1,
                completed_reps=8,
            )
        self.assertEqual(ctx.exception.error_code, 'set_not_found')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_invalid_set_number(self, mock_prescription: MagicMock) -> None:
        """Logging a set with invalid set_number raises set_not_found."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()

        with self.assertRaises(SessionError) as ctx:
            log_set(
                active_session_id=session_status.active_session_id,
                slot_id=str(self.slot1.pk),
                set_number=99,
                completed_reps=8,
            )
        self.assertEqual(ctx.exception.error_code, 'set_not_found')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_already_completed(self, mock_prescription: MagicMock) -> None:
        """Cannot log a set that was already completed."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        # Log set 1 of slot1
        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=8,
        )

        # Try to log the same set again
        with self.assertRaises(SessionError) as ctx:
            log_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=1,
                completed_reps=8,
            )
        self.assertEqual(ctx.exception.error_code, 'set_already_logged')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_auto_advance_slot_index(self, mock_prescription: MagicMock) -> None:
        """Slot index advances when all sets in current slot are done."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        # Verify initial slot index
        session = ActiveSession.objects.get(pk=session_id)
        self.assertEqual(session.current_slot_index, 0)

        # Complete all 3 sets of slot1
        for set_num in range(1, 4):
            log_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=set_num,
                completed_reps=8,
                load_value=Decimal("135.00"),
            )

        # Slot index should advance to 1 (slot2)
        session.refresh_from_db()
        self.assertEqual(session.current_slot_index, 1)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_zero_reps(self, mock_prescription: MagicMock) -> None:
        """Zero reps is valid (failed attempt)."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        result = log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=0,
            load_value=Decimal("225.00"),
        )

        self.assertEqual(result.completed_sets, 1)
        set_log = ActiveSetLog.objects.get(
            active_session_id=session_id,
            plan_slot=self.slot1,
            set_number=1,
        )
        self.assertEqual(set_log.completed_reps, 0)
        self.assertEqual(set_log.status, ActiveSetLog.Status.COMPLETED)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_creates_no_lift_set_log_yet(self, mock_prescription: MagicMock) -> None:
        """LiftSetLog is NOT created during log_set, only on complete/abandon."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        initial_count = LiftSetLog.objects.count()

        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=8,
            load_value=Decimal("135.00"),
        )

        self.assertEqual(LiftSetLog.objects.count(), initial_count)


# ---------------------------------------------------------------------------
# skip_set tests
# ---------------------------------------------------------------------------


class SkipSetTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_skip_set_normal_flow(self, mock_prescription: MagicMock) -> None:
        """Skipping a set marks it as skipped."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        result = skip_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
        )

        self.assertEqual(result.skipped_sets, 1)
        self.assertEqual(result.pending_sets, 4)

        set_log = ActiveSetLog.objects.get(
            active_session_id=session_id,
            plan_slot=self.slot1,
            set_number=1,
        )
        self.assertEqual(set_log.status, ActiveSetLog.Status.SKIPPED)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_skip_set_with_reason(self, mock_prescription: MagicMock) -> None:
        """Skip reason is saved on the set log."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        skip_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            reason='Shoulder pain',
        )

        set_log = ActiveSetLog.objects.get(
            active_session_id=session_id,
            plan_slot=self.slot1,
            set_number=1,
        )
        self.assertEqual(set_log.skip_reason, 'Shoulder pain')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_skip_set_already_completed(self, mock_prescription: MagicMock) -> None:
        """Cannot skip a set that was already completed."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=8,
        )

        with self.assertRaises(SessionError) as ctx:
            skip_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=1,
            )
        self.assertEqual(ctx.exception.error_code, 'set_already_logged')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_skip_set_advances_slot_index(self, mock_prescription: MagicMock) -> None:
        """Skipping all sets in a slot advances the slot index."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        # Skip all 3 sets of slot1
        for set_num in range(1, 4):
            skip_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=set_num,
                reason='skip test',
            )

        session = ActiveSession.objects.get(pk=session_id)
        self.assertEqual(session.current_slot_index, 1)


# ---------------------------------------------------------------------------
# complete_session tests
# ---------------------------------------------------------------------------


class CompleteSessionTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.apply_progression')
    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_session_normal_flow(
        self, mock_prescription: MagicMock, mock_apply: MagicMock,
    ) -> None:
        """Completing a session marks it completed and creates LiftSetLogs."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        from workouts.services.progression_engine_service import ProgressionEventResult
        mock_apply.return_value = ProgressionEventResult(
            slot_id=str(self.slot1.pk),
            event_type='advance',
            old_prescription={},
            new_prescription={},
            reason_codes=['all_sets_complete'],
        )

        session_status = self._start_session()
        session_id = session_status.active_session_id

        self._log_all_sets(session_id)
        initial_lsl_count = LiftSetLog.objects.count()

        result = complete_session(session_id, actor_id=self.trainee.pk)

        self.assertEqual(result.status, 'completed')
        self.assertEqual(result.completed_sets, 5)
        self.assertEqual(result.skipped_sets, 0)
        self.assertIsNotNone(result.duration_seconds)

        # LiftSetLogs created
        new_lsl_count = LiftSetLog.objects.count()
        self.assertEqual(new_lsl_count - initial_lsl_count, 5)

        # DecisionLog
        decision = DecisionLog.objects.filter(
            decision_type='session_completed',
        ).latest('created_at')
        self.assertIsNotNone(decision)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_session_pending_sets_remaining(self, mock_prescription: MagicMock) -> None:
        """Cannot complete a session with pending sets."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        # Only log 1 of 5 sets
        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=8,
        )

        with self.assertRaises(SessionError) as ctx:
            complete_session(session_id, actor_id=self.trainee.pk)
        self.assertEqual(ctx.exception.error_code, 'pending_sets_remaining')
        self.assertEqual(ctx.exception.extra['count'], 4)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_session_already_completed(self, mock_prescription: MagicMock) -> None:
        """Cannot complete an already completed session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        self._log_all_sets(session_id)
        complete_session(session_id, actor_id=self.trainee.pk)

        with self.assertRaises(SessionError) as ctx:
            complete_session(session_id, actor_id=self.trainee.pk)
        self.assertEqual(ctx.exception.error_code, 'session_already_completed')

    @patch('workouts.services.session_runner_service.apply_progression')
    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_session_all_skipped(
        self, mock_prescription: MagicMock, mock_apply: MagicMock,
    ) -> None:
        """All-skipped session does NOT create LiftSetLogs or trigger progression."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        session_status = self._start_session()
        session_id = session_status.active_session_id
        initial_lsl_count = LiftSetLog.objects.count()

        self._skip_all_sets(session_id)
        result = complete_session(session_id, actor_id=self.trainee.pk)

        self.assertEqual(result.status, 'completed')
        self.assertEqual(result.completed_sets, 0)
        self.assertEqual(result.skipped_sets, 5)

        # No LiftSetLogs created
        self.assertEqual(LiftSetLog.objects.count(), initial_lsl_count)

        # apply_progression should NOT be called for fully-skipped slots
        mock_apply.assert_not_called()

    @patch('workouts.services.session_runner_service.apply_progression')
    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_session_mixed_completed_skipped(
        self, mock_prescription: MagicMock, mock_apply: MagicMock,
    ) -> None:
        """Mixed completed/skipped: LiftSetLogs only for completed, progression only for slots with completions."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        from workouts.services.progression_engine_service import ProgressionEventResult
        mock_apply.return_value = ProgressionEventResult(
            slot_id=str(self.slot1.pk),
            event_type='hold',
            old_prescription={},
            new_prescription={},
            reason_codes=['partial'],
        )

        session_status = self._start_session()
        session_id = session_status.active_session_id

        # Complete slot1 sets, skip slot2 sets
        for set_num in range(1, 4):
            log_set(
                active_session_id=session_id,
                slot_id=str(self.slot1.pk),
                set_number=set_num,
                completed_reps=8,
                load_value=Decimal("135.00"),
            )
        for set_num in range(1, 3):
            skip_set(
                active_session_id=session_id,
                slot_id=str(self.slot2.pk),
                set_number=set_num,
                reason='skip test',
            )

        initial_lsl_count = LiftSetLog.objects.count()
        result = complete_session(session_id, actor_id=self.trainee.pk)

        self.assertEqual(result.completed_sets, 3)
        self.assertEqual(result.skipped_sets, 2)
        self.assertEqual(LiftSetLog.objects.count() - initial_lsl_count, 3)

    @patch('workouts.services.session_runner_service.apply_progression')
    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_session_triggers_lift_max_update(
        self, mock_prescription: MagicMock, mock_apply: MagicMock,
    ) -> None:
        """Completing a session calls MaxLoadService.update_max_from_set for each completed set."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        from workouts.services.progression_engine_service import ProgressionEventResult
        mock_apply.return_value = ProgressionEventResult(
            slot_id=str(self.slot1.pk),
            event_type='hold',
            old_prescription={},
            new_prescription={},
            reason_codes=['done'],
        )

        session_status = self._start_session()
        session_id = session_status.active_session_id
        self._log_all_sets(session_id)

        with patch('workouts.services.session_runner_service.MaxLoadService') as mock_max_svc:
            complete_session(session_id, actor_id=self.trainee.pk)
            self.assertEqual(mock_max_svc.update_max_from_set.call_count, 5)


# ---------------------------------------------------------------------------
# abandon_session tests
# ---------------------------------------------------------------------------


class AbandonSessionTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_abandon_session_normal_flow(self, mock_prescription: MagicMock) -> None:
        """Abandoning marks session as abandoned with reason."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        result = abandon_session(session_id, actor_id=self.trainee.pk, reason='gym closed')

        self.assertEqual(result.status, 'abandoned')
        self.assertIsNotNone(result.duration_seconds)
        self.assertEqual(result.progression_results, [])

        session = ActiveSession.objects.get(pk=session_id)
        self.assertEqual(session.abandon_reason, 'gym closed')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_abandon_session_preserves_partial_data(self, mock_prescription: MagicMock) -> None:
        """Abandonment saves completed sets to LiftSetLog, not pending/skipped."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        # Complete 2 sets, skip 1
        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=8,
            load_value=Decimal("135.00"),
        )
        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=2,
            completed_reps=7,
            load_value=Decimal("135.00"),
        )
        skip_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=3,
            reason='pain',
        )

        initial_lsl_count = LiftSetLog.objects.count()
        result = abandon_session(session_id, actor_id=self.trainee.pk, reason='pain')

        self.assertEqual(result.completed_sets, 2)
        self.assertEqual(result.skipped_sets, 1)
        # Only 2 completed sets saved to LiftSetLog
        self.assertEqual(LiftSetLog.objects.count() - initial_lsl_count, 2)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_abandon_session_no_progression_evaluation(self, mock_prescription: MagicMock) -> None:
        """Abandonment does NOT trigger progression evaluation."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        self._log_all_sets(session_id)

        with patch('workouts.services.session_runner_service.apply_progression') as mock_apply:
            result = abandon_session(session_id, actor_id=self.trainee.pk)
            mock_apply.assert_not_called()

        self.assertEqual(result.progression_results, [])

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_abandon_already_completed_session(self, mock_prescription: MagicMock) -> None:
        """Cannot abandon an already completed session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        self._log_all_sets(session_id)
        complete_session(session_id, actor_id=self.trainee.pk)

        with self.assertRaises(SessionError) as ctx:
            abandon_session(session_id, actor_id=self.trainee.pk)
        self.assertEqual(ctx.exception.error_code, 'session_already_completed')


# ---------------------------------------------------------------------------
# get_session_status tests
# ---------------------------------------------------------------------------


class GetSessionStatusTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_full_status(self, mock_prescription: MagicMock) -> None:
        """get_session_status returns full status with all fields."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()

        result = get_session_status(session_status.active_session_id)

        self.assertEqual(result.status, 'in_progress')
        self.assertEqual(result.total_sets, 5)
        self.assertEqual(result.total_slots, 2)
        self.assertIsNotNone(result.started_at)
        self.assertIsNotNone(result.elapsed_seconds)
        self.assertEqual(result.plan_session_label, 'Upper A')

        # Check slot structure
        self.assertEqual(len(result.slots), 2)
        self.assertEqual(result.slots[0].exercise_name, 'Bench Press')
        self.assertEqual(len(result.slots[0].sets), 3)
        self.assertEqual(result.slots[1].exercise_name, 'Bicep Curl')
        self.assertEqual(len(result.slots[1].sets), 2)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_progress_percentage(self, mock_prescription: MagicMock) -> None:
        """Progress percentage is computed correctly."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()
        session_id = session_status.active_session_id

        # 0% initially
        self.assertEqual(session_status.progress_pct, 0.0)

        # Log 1 of 5 sets = 20%
        log_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=1,
            completed_reps=8,
        )
        result = get_session_status(session_id)
        self.assertEqual(result.progress_pct, 20.0)

        # Skip 1 more = 40%
        skip_set(
            active_session_id=session_id,
            slot_id=str(self.slot1.pk),
            set_number=2,
        )
        result = get_session_status(session_id)
        self.assertEqual(result.progress_pct, 40.0)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_current_slot_is_current_flag(self, mock_prescription: MagicMock) -> None:
        """The is_current flag is set on the correct slot."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        session_status = self._start_session()

        # Initially slot 0 is current
        self.assertTrue(session_status.slots[0].is_current)
        self.assertFalse(session_status.slots[1].is_current)


# ---------------------------------------------------------------------------
# get_active_session tests
# ---------------------------------------------------------------------------


class GetActiveSessionTests(SessionRunnerTestBase):

    def test_no_active_session(self) -> None:
        """Returns None when no active session exists."""
        result = get_active_session(self.trainee.pk)
        self.assertIsNone(result)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_returns_active_session(self, mock_prescription: MagicMock) -> None:
        """Returns the active session if one exists."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )
        self._start_session()

        result = get_active_session(self.trainee.pk)
        self.assertIsNotNone(result)
        self.assertEqual(result.status, 'in_progress')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_auto_abandons_stale_session(self, mock_prescription: MagicMock) -> None:
        """get_active_session auto-abandons stale sessions."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        stale_time = timezone.now() - timedelta(hours=5)
        stale = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.IN_PROGRESS,
            started_at=stale_time,
        )

        result = get_active_session(self.trainee.pk)
        self.assertIsNone(result)

        stale.refresh_from_db()
        self.assertEqual(stale.status, ActiveSession.Status.ABANDONED)
        self.assertEqual(stale.abandon_reason, 'auto_abandoned_stale')


# ---------------------------------------------------------------------------
# Rest Timer Service tests
# ---------------------------------------------------------------------------


class RestTimerTests(TestCase):

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="rt_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee = User.objects.create_user(
            email="rt_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.exercise = Exercise.objects.create(
            name="Test Exercise RT",
            primary_muscle_group="chest",
            equipment="barbell",
            is_public=True,
        )
        self.plan = TrainingPlan.objects.create(
            trainee=self.trainee,
            name="RT Plan",
            goal="strength",
            status="active",
            duration_weeks=4,
            created_by=self.trainer,
        )
        self.week = PlanWeek.objects.create(
            plan=self.plan, week_number=1, is_deload=False,
        )
        self.session = PlanSession.objects.create(
            week=self.week, day_of_week=0, label="RT Day", order=0,
        )

    def _create_slot(
        self,
        slot_role: str = "primary_compound",
        rest_seconds: int = 90,
        modality: SetStructureModality | None = None,
    ) -> PlanSlot:
        order = PlanSlot.objects.filter(session=self.session).count() + 1
        return PlanSlot.objects.create(
            session=self.session,
            exercise=self.exercise,
            order=order,
            slot_role=slot_role,
            sets=3,
            reps_min=6,
            reps_max=8,
            rest_seconds=rest_seconds,
            set_structure_modality=modality,
        )

    def test_slot_role_defaults(self) -> None:
        """Each slot_role gets the correct default rest."""
        cases = {
            'primary_compound': 180,
            'secondary_compound': 120,
            'isolation': 90,
            'accessory': 60,
        }
        for role, expected_rest in cases.items():
            slot = self._create_slot(slot_role=role, rest_seconds=90)
            result = get_rest_duration(slot, set_number=1)
            # Note: isolation with rest_seconds=90 = the default, so it falls through
            # to slot_role_default which is 90 for isolation, matching the default.
            self.assertEqual(
                result.rest_seconds, expected_rest,
                f"Failed for slot_role={role}: expected {expected_rest}, got {result.rest_seconds}",
            )
            self.assertEqual(result.source, 'slot_role_default')

    def test_trainer_override(self) -> None:
        """If PlanSlot.rest_seconds differs from default 90, it's a trainer override."""
        slot = self._create_slot(slot_role="primary_compound", rest_seconds=150)
        result = get_rest_duration(slot, set_number=1)
        self.assertEqual(result.rest_seconds, 150)
        self.assertEqual(result.source, 'trainer_override')

    def test_modality_override(self) -> None:
        """Modality with known slug overrides role default."""
        modality = SetStructureModality.objects.create(
            name="Myo Reps",
            slug="myo_reps",
            description="Myo rep style training",
        )
        slot = self._create_slot(slot_role="primary_compound", modality=modality)
        result = get_rest_duration(slot, set_number=1)
        self.assertEqual(result.rest_seconds, 20)
        self.assertEqual(result.source, 'modality_override')

    def test_between_exercise_bonus(self) -> None:
        """Last set of slot gets +30s bonus."""
        slot = self._create_slot(slot_role="accessory")
        result = get_rest_duration(slot, set_number=3, is_last_set_of_slot=True)
        # accessory default = 60 + 30 bonus = 90
        self.assertEqual(result.rest_seconds, 90)
        self.assertTrue(result.is_between_exercises)

    def test_no_bonus_for_non_last_set(self) -> None:
        """Non-last sets do not get between-exercise bonus."""
        slot = self._create_slot(slot_role="accessory")
        result = get_rest_duration(slot, set_number=1, is_last_set_of_slot=False)
        self.assertEqual(result.rest_seconds, 60)
        self.assertFalse(result.is_between_exercises)

    def test_modality_unknown_slug_falls_back_to_role(self) -> None:
        """Unknown modality slug falls back to slot_role_default."""
        modality = SetStructureModality.objects.create(
            name="Custom Modality",
            slug="unknown_custom",
            description="Not in override list",
        )
        slot = self._create_slot(slot_role="secondary_compound", modality=modality)
        result = get_rest_duration(slot, set_number=1)
        self.assertEqual(result.rest_seconds, 120)
        self.assertEqual(result.source, 'slot_role_default')

    def test_trainer_override_takes_priority_over_modality(self) -> None:
        """Trainer override (non-default rest_seconds) takes priority over modality."""
        modality = SetStructureModality.objects.create(
            name="Drop Sets",
            slug="drop_sets",
            description="Drop set style",
        )
        slot = self._create_slot(
            slot_role="primary_compound",
            rest_seconds=200,  # non-default = trainer override
            modality=modality,
        )
        result = get_rest_duration(slot, set_number=1)
        self.assertEqual(result.rest_seconds, 200)
        self.assertEqual(result.source, 'trainer_override')


# ---------------------------------------------------------------------------
# API endpoint tests
# ---------------------------------------------------------------------------


class SessionAPITests(SessionRunnerTestBase):
    """Tests for the session API endpoints via HTTP."""

    def _get_base_url(self) -> str:
        return '/api/workouts/sessions/'

    # --- Auth / Role enforcement ---

    def test_start_requires_auth(self) -> None:
        """Unauthenticated request returns 401."""
        resp = self.anon_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_start_rejects_trainer(self) -> None:
        """Trainer (non-impersonating) gets 403."""
        resp = self.trainer_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_start_rejects_admin(self) -> None:
        """Admin (non-impersonating) gets 403."""
        resp = self.admin_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_api(self, mock_prescription: MagicMock) -> None:
        """POST /sessions/start/ creates a session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'in_progress')
        self.assertEqual(resp.data['total_sets'], 5)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_start_session_api_conflict(self, mock_prescription: MagicMock) -> None:
        """POST /sessions/start/ with active session returns 409."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(resp.data['error'], 'active_session_exists')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_log_set_api(self, mock_prescription: MagicMock) -> None:
        """POST /sessions/{id}/log-set/ logs a set."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        start_resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        session_id = start_resp.data['active_session_id']

        resp = self.trainee_client.post(
            f'{self._get_base_url()}{session_id}/log-set/',
            {
                'slot_id': str(self.slot1.pk),
                'set_number': 1,
                'completed_reps': 8,
                'load_value': '135.00',
                'load_unit': 'lb',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['completed_sets'], 1)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_skip_set_api(self, mock_prescription: MagicMock) -> None:
        """POST /sessions/{id}/skip-set/ skips a set."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        start_resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        session_id = start_resp.data['active_session_id']

        resp = self.trainee_client.post(
            f'{self._get_base_url()}{session_id}/skip-set/',
            {
                'slot_id': str(self.slot1.pk),
                'set_number': 1,
                'reason': 'too heavy',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['skipped_sets'], 1)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_complete_api(self, mock_prescription: MagicMock) -> None:
        """POST /sessions/{id}/complete/ completes a session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        start_resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        session_id = start_resp.data['active_session_id']

        # Log/skip all sets
        set_logs = ActiveSetLog.objects.filter(
            active_session_id=session_id,
        ).order_by('plan_slot__order', 'set_number')
        for sl in set_logs:
            self.trainee_client.post(
                f'{self._get_base_url()}{session_id}/log-set/',
                {
                    'slot_id': str(sl.plan_slot_id),
                    'set_number': sl.set_number,
                    'completed_reps': 8,
                },
                format='json',
            )

        resp = self.trainee_client.post(
            f'{self._get_base_url()}{session_id}/complete/',
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'completed')
        self.assertEqual(resp.data['completed_sets'], 5)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_abandon_api(self, mock_prescription: MagicMock) -> None:
        """POST /sessions/{id}/abandon/ abandons a session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        start_resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        session_id = start_resp.data['active_session_id']

        resp = self.trainee_client.post(
            f'{self._get_base_url()}{session_id}/abandon/',
            {'reason': 'gym closing'},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'abandoned')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_active_endpoint(self, mock_prescription: MagicMock) -> None:
        """GET /sessions/active/ returns active session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        # No active session -> 404
        resp = self.trainee_client.get(f'{self._get_base_url()}active/')
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

        # Start a session
        self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )

        resp = self.trainee_client.get(f'{self._get_base_url()}active/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'in_progress')

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_idor_protection_retrieve(self, mock_prescription: MagicMock) -> None:
        """Other trainee cannot access another trainee's session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        start_resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        session_id = start_resp.data['active_session_id']

        # Other trainee tries to access it
        resp = self.other_trainee_client.get(
            f'{self._get_base_url()}{session_id}/',
        )
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_idor_protection_log_set(self, mock_prescription: MagicMock) -> None:
        """Other trainee cannot log a set on another trainee's session."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        start_resp = self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )
        session_id = start_resp.data['active_session_id']

        resp = self.other_trainee_client.post(
            f'{self._get_base_url()}{session_id}/log-set/',
            {
                'slot_id': str(self.slot1.pk),
                'set_number': 1,
                'completed_reps': 8,
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_list_sessions(self, mock_prescription: MagicMock) -> None:
        """GET /sessions/ returns trainee's sessions."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )

        resp = self.trainee_client.get(f'{self._get_base_url()}')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        results = resp.data.get('results', resp.data)
        self.assertGreaterEqual(len(results), 1)

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_list_sessions_status_filter(self, mock_prescription: MagicMock) -> None:
        """GET /sessions/?status=in_progress filters by status."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        self.trainee_client.post(
            f'{self._get_base_url()}start/',
            {'plan_session_id': str(self.plan_session.pk)},
            format='json',
        )

        resp = self.trainee_client.get(f'{self._get_base_url()}?status=in_progress')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

        resp_completed = self.trainee_client.get(f'{self._get_base_url()}?status=completed')
        self.assertEqual(resp_completed.status_code, status.HTTP_200_OK)

    def test_list_sessions_invalid_status_filter(self) -> None:
        """GET /sessions/?status=bogus returns 400."""
        resp = self.trainee_client.get(f'{self._get_base_url()}?status=bogus')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(resp.data['error'], 'invalid_status')


# ---------------------------------------------------------------------------
# Stale session edge cases
# ---------------------------------------------------------------------------


class StaleSessionTests(SessionRunnerTestBase):

    @patch('workouts.services.session_runner_service.compute_next_prescription')
    def test_stale_session_saves_completed_sets(self, mock_prescription: MagicMock) -> None:
        """Auto-abandoned stale session saves completed sets to LiftSetLog."""
        mock_prescription.return_value = StartSessionTests._mock_prescription(
            StartSessionTests, load=Decimal("135.00"),
        )

        stale_time = timezone.now() - timedelta(hours=5)
        stale_session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.IN_PROGRESS,
            started_at=stale_time,
        )
        # Add a completed set log
        ActiveSetLog.objects.create(
            active_session=stale_session,
            plan_slot=self.slot1,
            exercise=self.exercise_bench,
            set_number=1,
            prescribed_reps_min=6,
            prescribed_reps_max=8,
            prescribed_load=Decimal("135.00"),
            status=ActiveSetLog.Status.COMPLETED,
            completed_reps=8,
            completed_load_value=Decimal("135.00"),
            completed_load_unit='lb',
        )

        initial_lsl_count = LiftSetLog.objects.count()

        # Trigger stale check
        get_active_session(self.trainee.pk)

        stale_session.refresh_from_db()
        self.assertEqual(stale_session.status, ActiveSession.Status.ABANDONED)
        self.assertEqual(LiftSetLog.objects.count() - initial_lsl_count, 1)

    def test_fresh_session_not_auto_abandoned(self) -> None:
        """Sessions within 4 hours are not auto-abandoned."""
        recent_time = timezone.now() - timedelta(hours=3)
        session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.IN_PROGRESS,
            started_at=recent_time,
        )
        # Add a set log so get_session_status works
        ActiveSetLog.objects.create(
            active_session=session,
            plan_slot=self.slot1,
            exercise=self.exercise_bench,
            set_number=1,
            prescribed_reps_min=6,
            prescribed_reps_max=8,
            status=ActiveSetLog.Status.PENDING,
        )

        result = get_active_session(self.trainee.pk)
        self.assertIsNotNone(result)
        self.assertEqual(result.status, 'in_progress')

        session.refresh_from_db()
        self.assertEqual(session.status, ActiveSession.Status.IN_PROGRESS)


# ---------------------------------------------------------------------------
# Model constraint tests
# ---------------------------------------------------------------------------


class ModelConstraintTests(SessionRunnerTestBase):

    def test_unique_active_session_per_trainee(self) -> None:
        """DB constraint prevents two in_progress sessions for same trainee."""
        ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.IN_PROGRESS,
            started_at=timezone.now(),
        )
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            ActiveSession.objects.create(
                trainee=self.trainee,
                plan_session=self.plan_session,
                status=ActiveSession.Status.IN_PROGRESS,
                started_at=timezone.now(),
            )

    def test_unique_set_per_slot_per_session(self) -> None:
        """DB constraint prevents duplicate set_number for same slot in same session."""
        session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.IN_PROGRESS,
            started_at=timezone.now(),
        )
        ActiveSetLog.objects.create(
            active_session=session,
            plan_slot=self.slot1,
            exercise=self.exercise_bench,
            set_number=1,
            prescribed_reps_min=6,
            prescribed_reps_max=8,
        )
        from django.db import IntegrityError
        with self.assertRaises(IntegrityError):
            ActiveSetLog.objects.create(
                active_session=session,
                plan_slot=self.slot1,
                exercise=self.exercise_bench,
                set_number=1,
                prescribed_reps_min=6,
                prescribed_reps_max=8,
            )

    def test_plan_session_set_null_on_delete(self) -> None:
        """Deleting plan_session sets FK to NULL, session survives."""
        session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status=ActiveSession.Status.COMPLETED,
            started_at=timezone.now(),
        )
        plan_session_id = self.plan_session.pk
        # Delete the plan session's slots first (PROTECT on exercise FK)
        PlanSlot.objects.filter(session=self.plan_session).delete()
        self.plan_session.delete()

        session.refresh_from_db()
        self.assertIsNone(session.plan_session_id)
        # Session still exists
        self.assertTrue(ActiveSession.objects.filter(pk=session.pk).exists())
