"""
Tests for Session Feedback + Trainer Routing Rules — v6.5 Step 9.

Covers:
- Service layer (feedback_service.py):
  - submit_feedback: creates feedback, pain events, DecisionLog, evaluates routing rules
  - submit_feedback: triggers notifications for matching routing rules
  - submit_feedback: no trainer = no routing rules evaluated
  - log_pain_event: standalone pain event creation
  - log_pain_event: triggers pain_report routing rule
  - evaluate_routing_rules: each rule type (low_rating, pain_report, high_difficulty,
    recovery_concern, form_breakdown)
  - create_default_routing_rules: creates 5 defaults, is idempotent
  - get_feedback_history: returns ordered results
  - get_pain_history: filters by body_region

- Serializer tests:
  - SubmitFeedbackInputSerializer: valid input, invalid friction_reasons
  - PainEventInputSerializer: valid input, out-of-range pain_score
  - TrainerRoutingRuleSerializer: threshold_value must be dict

- View tests (role-based access):
  - SessionFeedbackViewSet.submit: trainee can submit, non-trainee gets 403
  - SessionFeedbackViewSet.submit: duplicate submission gets 409
  - SessionFeedbackViewSet.submit: non-completed session gets 400
  - SessionFeedbackViewSet.for_session: trainee sees own, trainer sees trainee's
  - PainEventViewSet.log: trainee can log, non-trainee gets 403
  - PainEventViewSet.list: body_region filter, invalid region gets 400
  - TrainerRoutingRuleViewSet: trainee gets 403 on all CRUD
  - TrainerRoutingRuleViewSet.initialize: creates defaults for trainer
  - TrainerRoutingRuleViewSet: trainer can't modify another trainer's rules
"""
from __future__ import annotations

import uuid
from typing import Any

from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from trainer.models import TrainerNotification
from users.models import User
from workouts.feedback_serializers import (
    PainEventInputSerializer,
    SubmitFeedbackInputSerializer,
    TrainerRoutingRuleSerializer,
)
from workouts.models import (
    ActiveSession,
    DecisionLog,
    Exercise,
    PainEvent,
    PlanSession,
    PlanSlot,
    PlanWeek,
    SessionFeedback,
    TrainerRoutingRule,
    TrainingPlan,
)
from workouts.services.feedback_service import (
    create_default_routing_rules,
    evaluate_routing_rules,
    get_feedback_history,
    get_pain_history,
    log_pain_event,
    submit_feedback,
)


# ---------------------------------------------------------------------------
# Shared setup
# ---------------------------------------------------------------------------


class FeedbackTestBase(TestCase):
    """Shared setup: trainer, trainee, exercises, plan hierarchy, completed session, API clients."""

    def setUp(self) -> None:
        # ---- Users ----
        self.trainer = User.objects.create_user(
            email="fb_trainer@test.com",
            password="testpass123",
            role="TRAINER",
            first_name="Coach",
            last_name="Smith",
        )
        self.trainee = User.objects.create_user(
            email="fb_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
            first_name="John",
            last_name="Doe",
        )
        self.other_trainer = User.objects.create_user(
            email="fb_other_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.other_trainee = User.objects.create_user(
            email="fb_other_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.other_trainer,
        )
        self.trainee_no_trainer = User.objects.create_user(
            email="fb_solo_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=None,
        )
        self.admin = User.objects.create_user(
            email="fb_admin@test.com",
            password="testpass123",
            role="ADMIN",
        )

        # ---- Exercise ----
        self.exercise = Exercise.objects.create(
            name="Bench Press",
            primary_muscle_group="chest",
            equipment_required=["barbell"],
            is_public=True,
        )

        # ---- Plan hierarchy ----
        self.plan = TrainingPlan.objects.create(
            trainee=self.trainee,
            name="Feedback Test Plan",
            goal="strength",
            status="active",
            duration_weeks=4,
            created_by=self.trainer,
        )
        self.week = PlanWeek.objects.create(
            plan=self.plan, week_number=1, is_deload=False,
        )
        self.plan_session = PlanSession.objects.create(
            week=self.week, day_of_week=0, label="Upper A", order=0,
        )
        self.slot = PlanSlot.objects.create(
            session=self.plan_session,
            exercise=self.exercise,
            order=1,
            slot_role="primary_compound",
            sets=3,
            reps_min=6,
            reps_max=8,
            rest_seconds=90,
        )

        # ---- ActiveSession (completed) ----
        self.active_session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status="completed",
            started_at=timezone.now(),
            completed_at=timezone.now(),
        )

        # ---- ActiveSession (in_progress) ----
        self.active_session_in_progress = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status="in_progress",
            started_at=timezone.now(),
        )

        # ---- Other trainee's completed session ----
        other_plan = TrainingPlan.objects.create(
            trainee=self.other_trainee,
            name="Other Plan",
            goal="hypertrophy",
            status="active",
            duration_weeks=4,
            created_by=self.other_trainer,
        )
        other_week = PlanWeek.objects.create(
            plan=other_plan, week_number=1, is_deload=False,
        )
        other_plan_session = PlanSession.objects.create(
            week=other_week, day_of_week=1, label="Other Upper", order=0,
        )
        self.other_active_session = ActiveSession.objects.create(
            trainee=self.other_trainee,
            plan_session=other_plan_session,
            status="completed",
            started_at=timezone.now(),
            completed_at=timezone.now(),
        )

        # ---- Solo trainee (no parent_trainer) completed session ----
        solo_plan = TrainingPlan.objects.create(
            trainee=self.trainee_no_trainer,
            name="Solo Plan",
            goal="general_fitness",
            status="active",
            duration_weeks=4,
            created_by=self.admin,
        )
        solo_week = PlanWeek.objects.create(
            plan=solo_plan, week_number=1, is_deload=False,
        )
        solo_plan_session = PlanSession.objects.create(
            week=solo_week, day_of_week=0, label="Solo Session", order=0,
        )
        self.solo_active_session = ActiveSession.objects.create(
            trainee=self.trainee_no_trainer,
            plan_session=solo_plan_session,
            status="completed",
            started_at=timezone.now(),
            completed_at=timezone.now(),
        )

        # ---- API clients ----
        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)

        self.other_trainer_client = APIClient()
        self.other_trainer_client.force_authenticate(user=self.other_trainer)

        self.admin_client = APIClient()
        self.admin_client.force_authenticate(user=self.admin)

        self.solo_trainee_client = APIClient()
        self.solo_trainee_client.force_authenticate(user=self.trainee_no_trainer)

    def _create_routing_rules(self, trainer: User | None = None) -> list[TrainerRoutingRule]:
        return create_default_routing_rules(trainer or self.trainer)

    def _make_feedback_payload(self, **overrides: Any) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "completion_state": "completed",
            "ratings": {"overall": 4, "difficulty": 3},
            "friction_reasons": [],
            "recovery_concern": False,
            "notes": "Great session",
            "pain_events": [],
        }
        payload.update(overrides)
        return payload

    def _make_fresh_completed_session(self, trainee: User | None = None) -> ActiveSession:
        """Create a fresh completed session (avoids OneToOne collisions)."""
        return ActiveSession.objects.create(
            trainee=trainee or self.trainee,
            plan_session=self.plan_session,
            status="completed",
            started_at=timezone.now(),
            completed_at=timezone.now(),
        )


# ===========================================================================
# SERVICE LAYER TESTS -- submit_feedback
# ===========================================================================


class TestSubmitFeedback(FeedbackTestBase):
    """Tests for feedback_service.submit_feedback()."""

    def test_creates_feedback_and_decision_log(self) -> None:
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 4, "muscle_feel": 3, "difficulty": 2},
            friction_reasons=["fatigue"],
            recovery_concern=False,
            notes="Good workout",
            pain_events_data=[],
            actor_id=self.trainee.pk,
        )

        self.assertIsNotNone(result.feedback_id)
        self.assertEqual(result.active_session_id, str(self.active_session.pk))
        self.assertEqual(result.pain_events_created, 0)

        feedback = SessionFeedback.objects.get(pk=result.feedback_id)
        self.assertEqual(feedback.rating_overall, 4)
        self.assertEqual(feedback.rating_muscle_feel, 3)
        self.assertEqual(feedback.rating_difficulty, 2)
        self.assertEqual(feedback.friction_reasons, ["fatigue"])
        self.assertFalse(feedback.recovery_concern)
        self.assertEqual(feedback.notes, "Good workout")

        dl = DecisionLog.objects.filter(decision_type="session_feedback_submitted").first()
        self.assertIsNotNone(dl)
        assert dl is not None
        self.assertEqual(dl.actor_id, self.trainee.pk)
        self.assertEqual(dl.context["session_id"], str(self.active_session.pk))

    def test_creates_pain_events(self) -> None:
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 3},
            friction_reasons=["pain"],
            recovery_concern=True,
            notes="",
            pain_events_data=[
                {
                    "body_region": "knee_left",
                    "pain_score": 6,
                    "side": "left",
                    "sensation_type": "sharp",
                    "onset_phase": "working_set",
                },
                {
                    "body_region": "lower_back",
                    "pain_score": 4,
                    "side": "midline",
                },
            ],
        )

        self.assertEqual(result.pain_events_created, 2)
        knee_pe = PainEvent.objects.filter(
            trainee=self.trainee, body_region="knee_left",
        ).first()
        self.assertIsNotNone(knee_pe)
        assert knee_pe is not None
        self.assertEqual(knee_pe.pain_score, 6)
        self.assertEqual(knee_pe.side, "left")
        self.assertEqual(knee_pe.sensation_type, "sharp")
        self.assertEqual(knee_pe.onset_phase, "working_set")
        self.assertEqual(knee_pe.active_session, self.active_session)

    def test_triggers_all_five_routing_rules(self) -> None:
        self._create_routing_rules()

        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 1, "difficulty": 5},
            friction_reasons=["form_breakdown"],
            recovery_concern=True,
            notes="",
            pain_events_data=[{"body_region": "knee_left", "pain_score": 8}],
        )

        self.assertEqual(len(result.triggered_rules), 5)
        triggered_types = {r.rule_type for r in result.triggered_rules}
        self.assertEqual(
            triggered_types,
            {"low_rating", "pain_report", "high_difficulty", "recovery_concern", "form_breakdown"},
        )

        notifications = TrainerNotification.objects.filter(trainer=self.trainer)
        self.assertEqual(notifications.count(), 5)

    def test_no_trainer_skips_routing_rules(self) -> None:
        result = submit_feedback(
            active_session=self.solo_active_session,
            trainee=self.trainee_no_trainer,
            completion_state="completed",
            ratings={"overall": 1},
            friction_reasons=[],
            recovery_concern=False,
            notes="",
            pain_events_data=[],
        )

        self.assertEqual(len(result.triggered_rules), 0)
        self.assertEqual(TrainerNotification.objects.count(), 0)

    def test_no_rules_triggers_nothing(self) -> None:
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 1},
            friction_reasons=[],
            recovery_concern=False,
            notes="",
            pain_events_data=[],
        )

        self.assertEqual(len(result.triggered_rules), 0)

    def test_inactive_rules_not_evaluated(self) -> None:
        self._create_routing_rules()
        TrainerRoutingRule.objects.filter(trainer=self.trainer).update(is_active=False)

        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 1},
            friction_reasons=["form_breakdown"],
            recovery_concern=True,
            notes="",
            pain_events_data=[{"body_region": "knee_left", "pain_score": 9}],
        )

        self.assertEqual(len(result.triggered_rules), 0)

    def test_ratings_below_threshold_no_trigger(self) -> None:
        self._create_routing_rules()

        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 5, "difficulty": 1},
            friction_reasons=[],
            recovery_concern=False,
            notes="",
            pain_events_data=[],
        )

        self.assertEqual(len(result.triggered_rules), 0)

    def test_system_actor_when_no_actor_id(self) -> None:
        submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={},
            friction_reasons=[],
            recovery_concern=False,
            notes="",
            pain_events_data=[],
            actor_id=None,
        )

        dl = DecisionLog.objects.filter(decision_type="session_feedback_submitted").first()
        self.assertIsNotNone(dl)
        assert dl is not None
        self.assertEqual(dl.actor_type, DecisionLog.ActorType.SYSTEM)

    def test_pain_event_links_exercise_id(self) -> None:
        submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={},
            friction_reasons=[],
            recovery_concern=False,
            notes="",
            pain_events_data=[
                {
                    "body_region": "shoulder_left",
                    "pain_score": 4,
                    "exercise_id": self.exercise.pk,
                },
            ],
        )

        pe = PainEvent.objects.filter(trainee=self.trainee).first()
        self.assertIsNotNone(pe)
        assert pe is not None
        self.assertEqual(pe.exercise_id, self.exercise.pk)


# ===========================================================================
# SERVICE LAYER TESTS -- evaluate_routing_rules (individual rule types)
# ===========================================================================


class TestEvaluateRoutingRules(FeedbackTestBase):
    """Direct tests for evaluate_routing_rules() -- each rule type."""

    def _make_feedback(self, **kwargs: Any) -> SessionFeedback:
        session = self._make_fresh_completed_session()
        defaults: dict[str, Any] = {
            "active_session": session,
            "trainee": self.trainee,
            "completion_state": "completed",
            "rating_overall": None,
            "rating_difficulty": None,
            "friction_reasons": [],
            "recovery_concern": False,
        }
        defaults.update(kwargs)
        return SessionFeedback.objects.create(**defaults)

    def test_low_rating_triggers_at_threshold(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_overall=2)  # default threshold = 2

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertIn("low_rating", [r.rule_type for r in triggered])

    def test_low_rating_triggers_below_threshold(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_overall=1)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertIn("low_rating", [r.rule_type for r in triggered])

    def test_low_rating_no_trigger_above_threshold(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_overall=3)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertNotIn("low_rating", [r.rule_type for r in triggered])

    def test_low_rating_no_trigger_when_none(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_overall=None)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertNotIn("low_rating", [r.rule_type for r in triggered])

    def test_pain_report_triggers_at_threshold(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback()
        pe = PainEvent.objects.create(
            trainee=self.trainee, body_region="knee_left", pain_score=7,
        )

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[pe], trainee=self.trainee,
        )

        self.assertIn("pain_report", [r.rule_type for r in triggered])

    def test_pain_report_triggers_above_threshold(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback()
        pe = PainEvent.objects.create(
            trainee=self.trainee, body_region="lower_back", pain_score=9,
        )

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[pe], trainee=self.trainee,
        )

        pain_rules = [r for r in triggered if r.rule_type == "pain_report"]
        self.assertEqual(len(pain_rules), 1)
        self.assertIn("lower_back", pain_rules[0].reason)

    def test_pain_report_no_trigger_below(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback()
        pe = PainEvent.objects.create(
            trainee=self.trainee, body_region="knee_left", pain_score=5,
        )

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[pe], trainee=self.trainee,
        )

        self.assertNotIn("pain_report", [r.rule_type for r in triggered])

    def test_high_difficulty_triggers(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_difficulty=5)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertIn("high_difficulty", [r.rule_type for r in triggered])

    def test_high_difficulty_no_trigger_below(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_difficulty=4)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertNotIn("high_difficulty", [r.rule_type for r in triggered])

    def test_high_difficulty_none_no_trigger(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_difficulty=None)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertNotIn("high_difficulty", [r.rule_type for r in triggered])

    def test_recovery_concern_triggers(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(recovery_concern=True)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertIn("recovery_concern", [r.rule_type for r in triggered])

    def test_recovery_concern_false_no_trigger(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(recovery_concern=False)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertNotIn("recovery_concern", [r.rule_type for r in triggered])

    def test_form_breakdown_triggers(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(friction_reasons=["form_breakdown", "fatigue"])

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertIn("form_breakdown", [r.rule_type for r in triggered])

    def test_form_breakdown_absent_no_trigger(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(friction_reasons=["fatigue", "too_heavy"])

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        self.assertNotIn("form_breakdown", [r.rule_type for r in triggered])

    def test_notification_data_payload(self) -> None:
        self._create_routing_rules()
        feedback = self._make_feedback(rating_overall=1)

        triggered = evaluate_routing_rules(
            feedback=feedback, pain_events=[], trainee=self.trainee,
        )

        low_rules = [r for r in triggered if r.rule_type == "low_rating"]
        self.assertEqual(len(low_rules), 1)
        self.assertIsNotNone(low_rules[0].notification_id)

        notification = TrainerNotification.objects.get(pk=low_rules[0].notification_id)
        self.assertEqual(notification.trainer, self.trainer)
        self.assertIn("John Doe", notification.title)
        self.assertEqual(notification.data["trainee_id"], self.trainee.pk)
        self.assertEqual(notification.data["feedback_id"], str(feedback.pk))
        self.assertEqual(notification.data["rule_type"], "low_rating")

    def test_multiple_pain_events_first_matching_triggers(self) -> None:
        """When multiple pain events exist, the first one >= threshold triggers."""
        self._create_routing_rules()
        feedback = self._make_feedback()
        pe_low = PainEvent.objects.create(
            trainee=self.trainee, body_region="knee_left", pain_score=3,
        )
        pe_high = PainEvent.objects.create(
            trainee=self.trainee, body_region="lower_back", pain_score=8,
        )

        triggered = evaluate_routing_rules(
            feedback=feedback,
            pain_events=[pe_low, pe_high],
            trainee=self.trainee,
        )

        pain_rules = [r for r in triggered if r.rule_type == "pain_report"]
        self.assertEqual(len(pain_rules), 1)
        self.assertIn("lower_back", pain_rules[0].reason)


# ===========================================================================
# SERVICE LAYER TESTS -- log_pain_event
# ===========================================================================


class TestLogPainEvent(FeedbackTestBase):
    """Tests for feedback_service.log_pain_event()."""

    def test_creates_pain_event(self) -> None:
        result = log_pain_event(
            trainee=self.trainee,
            body_region="lower_back",
            pain_score=5,
            side="midline",
            sensation_type="aching",
            notes="After deadlifts",
        )

        self.assertIsNotNone(result.pain_event_id)
        self.assertEqual(result.body_region, "lower_back")
        self.assertEqual(result.pain_score, 5)

        pe = PainEvent.objects.get(pk=result.pain_event_id)
        self.assertEqual(pe.sensation_type, "aching")
        self.assertEqual(pe.notes, "After deadlifts")

    def test_triggers_pain_routing_rule(self) -> None:
        self._create_routing_rules()

        result = log_pain_event(
            trainee=self.trainee,
            body_region="knee_left",
            pain_score=8,
        )

        self.assertEqual(len(result.triggered_rules), 1)
        self.assertEqual(result.triggered_rules[0].rule_type, "pain_report")
        self.assertIsNotNone(result.triggered_rules[0].notification_id)

        notification = TrainerNotification.objects.get(
            pk=result.triggered_rules[0].notification_id,
        )
        self.assertEqual(notification.trainer, self.trainer)
        self.assertIn("Pain report", notification.title)
        self.assertIn("knee_left", notification.message)

    def test_below_threshold_no_trigger(self) -> None:
        self._create_routing_rules()

        result = log_pain_event(
            trainee=self.trainee,
            body_region="knee_left",
            pain_score=5,
        )

        self.assertEqual(len(result.triggered_rules), 0)

    def test_no_trainer_no_trigger(self) -> None:
        result = log_pain_event(
            trainee=self.trainee_no_trainer,
            body_region="knee_left",
            pain_score=9,
        )

        self.assertEqual(len(result.triggered_rules), 0)

    def test_links_exercise_and_session(self) -> None:
        result = log_pain_event(
            trainee=self.trainee,
            body_region="shoulder_left",
            pain_score=4,
            active_session_id=str(self.active_session.pk),
            exercise_id=self.exercise.pk,
        )

        pe = PainEvent.objects.get(pk=result.pain_event_id)
        self.assertEqual(pe.active_session, self.active_session)
        self.assertEqual(pe.exercise, self.exercise)

    def test_inactive_pain_rule_not_triggered(self) -> None:
        self._create_routing_rules()
        TrainerRoutingRule.objects.filter(
            trainer=self.trainer, rule_type="pain_report",
        ).update(is_active=False)

        result = log_pain_event(
            trainee=self.trainee,
            body_region="knee_left",
            pain_score=9,
        )

        self.assertEqual(len(result.triggered_rules), 0)


# ===========================================================================
# SERVICE LAYER TESTS -- create_default_routing_rules
# ===========================================================================


class TestCreateDefaultRoutingRules(FeedbackTestBase):
    """Tests for feedback_service.create_default_routing_rules()."""

    def test_creates_five_defaults(self) -> None:
        created = create_default_routing_rules(self.trainer)
        self.assertEqual(len(created), 5)

        rule_types = {r.rule_type for r in created}
        expected = {"low_rating", "pain_report", "high_difficulty", "recovery_concern", "form_breakdown"}
        self.assertEqual(rule_types, expected)

    def test_idempotent_second_call_creates_zero(self) -> None:
        first = create_default_routing_rules(self.trainer)
        self.assertEqual(len(first), 5)

        second = create_default_routing_rules(self.trainer)
        self.assertEqual(len(second), 0)

        total = TrainerRoutingRule.objects.filter(trainer=self.trainer).count()
        self.assertEqual(total, 5)

    def test_partial_idempotent(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type="low_rating",
            threshold_value={"min_rating": 1},
            notification_method="in_app",
        )

        created = create_default_routing_rules(self.trainer)
        self.assertEqual(len(created), 4)
        self.assertNotIn("low_rating", {r.rule_type for r in created})

    def test_different_trainers_get_separate_rules(self) -> None:
        create_default_routing_rules(self.trainer)
        create_default_routing_rules(self.other_trainer)

        self.assertEqual(
            TrainerRoutingRule.objects.filter(trainer=self.trainer).count(), 5,
        )
        self.assertEqual(
            TrainerRoutingRule.objects.filter(trainer=self.other_trainer).count(), 5,
        )

    def test_default_rule_values(self) -> None:
        created = create_default_routing_rules(self.trainer)
        pain_rule = next(r for r in created if r.rule_type == "pain_report")
        self.assertEqual(pain_rule.threshold_value, {"min_pain_score": 7})
        self.assertEqual(pain_rule.notification_method, "both")
        self.assertTrue(pain_rule.is_active)


# ===========================================================================
# SERVICE LAYER TESTS -- history queries
# ===========================================================================


class TestHistoryQueries(FeedbackTestBase):
    """Tests for get_feedback_history() and get_pain_history()."""

    def test_feedback_history_ordered_by_created_at_desc(self) -> None:
        for _ in range(3):
            session = self._make_fresh_completed_session()
            SessionFeedback.objects.create(
                active_session=session,
                trainee=self.trainee,
                completion_state="completed",
                rating_overall=3,
            )

        history = list(get_feedback_history(self.trainee.pk, limit=10))
        self.assertEqual(len(history), 3)
        for i in range(len(history) - 1):
            self.assertGreaterEqual(history[i].created_at, history[i + 1].created_at)

    def test_feedback_history_respects_limit(self) -> None:
        for _ in range(5):
            session = self._make_fresh_completed_session()
            SessionFeedback.objects.create(
                active_session=session,
                trainee=self.trainee,
                completion_state="completed",
            )

        history = list(get_feedback_history(self.trainee.pk, limit=3))
        self.assertEqual(len(history), 3)

    def test_feedback_history_does_not_return_other_trainee(self) -> None:
        SessionFeedback.objects.create(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
        )
        SessionFeedback.objects.create(
            active_session=self.other_active_session,
            trainee=self.other_trainee,
            completion_state="completed",
        )

        history = list(get_feedback_history(self.trainee.pk))
        self.assertEqual(len(history), 1)

    def test_pain_history_all(self) -> None:
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=5)
        PainEvent.objects.create(trainee=self.trainee, body_region="lower_back", pain_score=3)
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=7)

        history = list(get_pain_history(self.trainee.pk))
        self.assertEqual(len(history), 3)

    def test_pain_history_filtered_by_region(self) -> None:
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=5)
        PainEvent.objects.create(trainee=self.trainee, body_region="lower_back", pain_score=3)
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=7)

        history = list(get_pain_history(self.trainee.pk, body_region="knee_left"))
        self.assertEqual(len(history), 2)
        for pe in history:
            self.assertEqual(pe.body_region, "knee_left")

    def test_pain_history_does_not_return_other_trainee(self) -> None:
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=5)
        PainEvent.objects.create(trainee=self.other_trainee, body_region="knee_left", pain_score=9)

        history = list(get_pain_history(self.trainee.pk))
        self.assertEqual(len(history), 1)

    def test_pain_history_respects_limit(self) -> None:
        for _ in range(10):
            PainEvent.objects.create(
                trainee=self.trainee, body_region="knee_left", pain_score=5,
            )

        history = list(get_pain_history(self.trainee.pk, limit=3))
        self.assertEqual(len(history), 3)


# ===========================================================================
# SERIALIZER TESTS
# ===========================================================================


class TestSubmitFeedbackInputSerializer(TestCase):
    """Tests for SubmitFeedbackInputSerializer."""

    def test_valid_minimal_input(self) -> None:
        data = {"completion_state": "completed"}
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_valid_full_input(self) -> None:
        data = {
            "completion_state": "completed",
            "ratings": {"overall": 5, "difficulty": 3, "muscle_feel": 4},
            "friction_reasons": ["fatigue", "time_pressure"],
            "recovery_concern": True,
            "notes": "Felt good",
            "pain_events": [
                {
                    "body_region": "knee_left",
                    "pain_score": 6,
                    "side": "left",
                    "sensation_type": "sharp",
                },
            ],
        }
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_invalid_friction_reason_rejected(self) -> None:
        data = {
            "completion_state": "completed",
            "friction_reasons": ["not_a_valid_reason"],
        }
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("friction_reasons", serializer.errors)

    def test_valid_friction_reasons_accepted(self) -> None:
        data = {
            "completion_state": "completed",
            "friction_reasons": ["too_heavy", "fatigue", "form_breakdown"],
        }
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_invalid_completion_state(self) -> None:
        data = {"completion_state": "invalid_state"}
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("completion_state", serializer.errors)

    def test_rating_above_max_rejected(self) -> None:
        data = {"completion_state": "completed", "ratings": {"overall": 6}}
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())

    def test_rating_below_min_rejected(self) -> None:
        data = {"completion_state": "completed", "ratings": {"overall": 0}}
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())

    def test_all_completion_states_valid(self) -> None:
        for state in ["completed", "partial", "abandoned"]:
            serializer = SubmitFeedbackInputSerializer(
                data={"completion_state": state},
            )
            self.assertTrue(serializer.is_valid(), f"{state} should be valid: {serializer.errors}")

    def test_empty_friction_reasons_valid(self) -> None:
        data = {"completion_state": "completed", "friction_reasons": []}
        serializer = SubmitFeedbackInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_all_valid_friction_reasons(self) -> None:
        """Every valid friction reason should be accepted individually."""
        valid = [
            "too_heavy", "too_light", "time_pressure", "pain",
            "form_breakdown", "fatigue", "equipment_unavailable", "other",
        ]
        for reason in valid:
            serializer = SubmitFeedbackInputSerializer(data={
                "completion_state": "completed",
                "friction_reasons": [reason],
            })
            self.assertTrue(
                serializer.is_valid(),
                f"Reason '{reason}' should be valid: {serializer.errors}",
            )


class TestPainEventInputSerializer(TestCase):
    """Tests for PainEventInputSerializer."""

    def test_valid_input(self) -> None:
        data = {
            "body_region": "knee_left",
            "pain_score": 7,
            "side": "left",
            "sensation_type": "sharp",
        }
        serializer = PainEventInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_minimal_valid_input(self) -> None:
        data = {"body_region": "lower_back", "pain_score": 3}
        serializer = PainEventInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_pain_score_too_high(self) -> None:
        data = {"body_region": "knee_left", "pain_score": 11}
        serializer = PainEventInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("pain_score", serializer.errors)

    def test_pain_score_too_low(self) -> None:
        data = {"body_region": "knee_left", "pain_score": 0}
        serializer = PainEventInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("pain_score", serializer.errors)

    def test_pain_score_boundary_min(self) -> None:
        data = {"body_region": "knee_left", "pain_score": 1}
        serializer = PainEventInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_pain_score_boundary_max(self) -> None:
        data = {"body_region": "knee_left", "pain_score": 10}
        serializer = PainEventInputSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_invalid_body_region(self) -> None:
        data = {"body_region": "left_pinky_toe", "pain_score": 5}
        serializer = PainEventInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("body_region", serializer.errors)

    def test_invalid_sensation_type(self) -> None:
        data = {"body_region": "knee_left", "pain_score": 5, "sensation_type": "ticklish"}
        serializer = PainEventInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("sensation_type", serializer.errors)

    def test_invalid_side(self) -> None:
        data = {"body_region": "knee_left", "pain_score": 5, "side": "top"}
        serializer = PainEventInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("side", serializer.errors)

    def test_missing_required_fields(self) -> None:
        serializer = PainEventInputSerializer(data={})
        self.assertFalse(serializer.is_valid())
        self.assertIn("body_region", serializer.errors)
        self.assertIn("pain_score", serializer.errors)

    def test_negative_pain_score(self) -> None:
        data = {"body_region": "knee_left", "pain_score": -1}
        serializer = PainEventInputSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("pain_score", serializer.errors)


class TestTrainerRoutingRuleSerializer(FeedbackTestBase):
    """Tests for TrainerRoutingRuleSerializer."""

    def test_valid_input(self) -> None:
        data = {
            "rule_type": "low_rating",
            "threshold_value": {"min_rating": 2},
            "notification_method": "in_app",
            "is_active": True,
        }
        serializer = TrainerRoutingRuleSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_threshold_value_string_rejected(self) -> None:
        data = {
            "rule_type": "low_rating",
            "threshold_value": "not_a_dict",
            "notification_method": "in_app",
        }
        serializer = TrainerRoutingRuleSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("threshold_value", serializer.errors)

    def test_threshold_value_list_rejected(self) -> None:
        data = {
            "rule_type": "low_rating",
            "threshold_value": [1, 2, 3],
            "notification_method": "in_app",
        }
        serializer = TrainerRoutingRuleSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("threshold_value", serializer.errors)

    def test_threshold_value_empty_dict_valid(self) -> None:
        data = {
            "rule_type": "recovery_concern",
            "threshold_value": {},
            "notification_method": "in_app",
        }
        serializer = TrainerRoutingRuleSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_invalid_notification_method(self) -> None:
        data = {
            "rule_type": "low_rating",
            "threshold_value": {},
            "notification_method": "sms",
        }
        serializer = TrainerRoutingRuleSerializer(data=data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("notification_method", serializer.errors)

    def test_all_notification_methods_valid(self) -> None:
        for method in ["in_app", "email", "both"]:
            serializer = TrainerRoutingRuleSerializer(data={
                "rule_type": "low_rating",
                "threshold_value": {},
                "notification_method": method,
            })
            self.assertTrue(
                serializer.is_valid(),
                f"{method} should be valid: {serializer.errors}",
            )


# ===========================================================================
# VIEW TESTS -- SessionFeedbackViewSet
# ===========================================================================


class TestSessionFeedbackSubmitView(FeedbackTestBase):
    """Tests for SessionFeedbackViewSet.submit action."""

    def test_trainee_can_submit(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        payload = self._make_feedback_payload()

        response = self.trainee_client.post(url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("feedback_id", response.data)
        self.assertIn("triggered_rules", response.data)
        self.assertEqual(response.data["pain_events_created"], 0)

    def test_trainer_gets_403(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        response = self.trainer_client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_gets_403(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        response = self.admin_client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_unauthenticated_gets_401(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        client = APIClient()
        response = client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_duplicate_submission_gets_409(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        payload = self._make_feedback_payload()

        resp1 = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(resp1.status_code, status.HTTP_201_CREATED)

        resp2 = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(resp2.status_code, status.HTTP_409_CONFLICT)

    def test_in_progress_session_gets_400(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session_in_progress.pk}/"
        response = self.trainee_client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_not_started_session_gets_400(self) -> None:
        not_started = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status="not_started",
        )
        url = f"/api/workouts/session-feedback/submit/{not_started.pk}/"
        response = self.trainee_client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_nonexistent_session_gets_404(self) -> None:
        fake_id = str(uuid.uuid4())
        url = f"/api/workouts/session-feedback/submit/{fake_id}/"
        response = self.trainee_client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_other_trainee_session_gets_404(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.other_active_session.pk}/"
        response = self.trainee_client.post(url, self._make_feedback_payload(), format="json")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_submit_with_pain_events(self) -> None:
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        payload = self._make_feedback_payload(pain_events=[
            {"body_region": "knee_left", "pain_score": 6, "sensation_type": "sharp"},
            {"body_region": "lower_back", "pain_score": 3},
        ])

        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["pain_events_created"], 2)

    def test_abandoned_session_allows_feedback(self) -> None:
        abandoned = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status="abandoned",
            started_at=timezone.now(),
            completed_at=timezone.now(),
        )
        url = f"/api/workouts/session-feedback/submit/{abandoned.pk}/"
        payload = self._make_feedback_payload(completion_state="abandoned")

        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_submit_triggers_routing_rules_in_response(self) -> None:
        self._create_routing_rules()
        url = f"/api/workouts/session-feedback/submit/{self.active_session.pk}/"
        payload = self._make_feedback_payload(
            ratings={"overall": 1},
            recovery_concern=True,
        )

        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertGreater(len(response.data["triggered_rules"]), 0)

        for rule in response.data["triggered_rules"]:
            self.assertIn("rule_id", rule)
            self.assertIn("rule_type", rule)
            self.assertIn("reason", rule)


class TestSessionFeedbackForSessionView(FeedbackTestBase):
    """Tests for SessionFeedbackViewSet.for_session action."""

    def _submit_feedback(self) -> str:
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state="completed",
            ratings={"overall": 4},
            friction_reasons=[],
            recovery_concern=False,
            notes="test",
            pain_events_data=[],
        )
        return result.feedback_id

    def test_trainee_sees_own(self) -> None:
        self._submit_feedback()
        url = f"/api/workouts/session-feedback/for-session/{self.active_session.pk}/"
        response = self.trainee_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["rating_overall"], 4)

    def test_trainer_sees_trainee_feedback(self) -> None:
        self._submit_feedback()
        url = f"/api/workouts/session-feedback/for-session/{self.active_session.pk}/"
        response = self.trainer_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["rating_overall"], 4)

    def test_other_trainer_gets_404(self) -> None:
        self._submit_feedback()
        url = f"/api/workouts/session-feedback/for-session/{self.active_session.pk}/"
        response = self.other_trainer_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_no_feedback_returns_404(self) -> None:
        fake_id = str(uuid.uuid4())
        url = f"/api/workouts/session-feedback/for-session/{fake_id}/"
        response = self.trainee_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class TestSessionFeedbackListView(FeedbackTestBase):
    """Tests for SessionFeedbackViewSet.list (GET /session-feedback/)."""

    def test_trainee_sees_only_own(self) -> None:
        submit_feedback(
            active_session=self.active_session, trainee=self.trainee,
            completion_state="completed", ratings={}, friction_reasons=[],
            recovery_concern=False, notes="", pain_events_data=[],
        )
        submit_feedback(
            active_session=self.other_active_session, trainee=self.other_trainee,
            completion_state="completed", ratings={}, friction_reasons=[],
            recovery_concern=False, notes="", pain_events_data=[],
        )

        response = self.trainee_client.get("/api/workouts/session-feedback/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)

    def test_trainer_sees_their_trainees(self) -> None:
        submit_feedback(
            active_session=self.active_session, trainee=self.trainee,
            completion_state="completed", ratings={}, friction_reasons=[],
            recovery_concern=False, notes="", pain_events_data=[],
        )

        response = self.trainer_client.get("/api/workouts/session-feedback/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)

    def test_other_trainer_does_not_see_cross_trainer_feedback(self) -> None:
        submit_feedback(
            active_session=self.active_session, trainee=self.trainee,
            completion_state="completed", ratings={}, friction_reasons=[],
            recovery_concern=False, notes="", pain_events_data=[],
        )

        response = self.other_trainer_client.get("/api/workouts/session-feedback/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 0)


# ===========================================================================
# VIEW TESTS -- PainEventViewSet
# ===========================================================================


class TestPainEventLogView(FeedbackTestBase):
    """Tests for PainEventViewSet.log action."""

    def test_trainee_can_log(self) -> None:
        url = "/api/workouts/pain-events/log/"
        payload = {
            "body_region": "lower_back",
            "pain_score": 5,
            "side": "midline",
            "sensation_type": "aching",
        }
        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("pain_event_id", response.data)
        self.assertEqual(response.data["body_region"], "lower_back")
        self.assertEqual(response.data["pain_score"], 5)

    def test_trainer_gets_403(self) -> None:
        url = "/api/workouts/pain-events/log/"
        payload = {"body_region": "lower_back", "pain_score": 5}
        response = self.trainer_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_gets_403(self) -> None:
        url = "/api/workouts/pain-events/log/"
        payload = {"body_region": "lower_back", "pain_score": 5}
        response = self.admin_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_invalid_body_region_gets_400(self) -> None:
        url = "/api/workouts/pain-events/log/"
        payload = {"body_region": "invalid_region", "pain_score": 5}
        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_pain_score_out_of_range_gets_400(self) -> None:
        url = "/api/workouts/pain-events/log/"
        payload = {"body_region": "knee_left", "pain_score": 11}
        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_log_returns_triggered_rules(self) -> None:
        self._create_routing_rules()
        url = "/api/workouts/pain-events/log/"
        payload = {"body_region": "knee_left", "pain_score": 9}

        response = self.trainee_client.post(url, payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data["triggered_rules"]), 1)
        self.assertEqual(response.data["triggered_rules"][0]["rule_type"], "pain_report")


class TestPainEventListView(FeedbackTestBase):
    """Tests for PainEventViewSet.list with body_region filter."""

    def setUp(self) -> None:
        super().setUp()
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=5)
        PainEvent.objects.create(trainee=self.trainee, body_region="lower_back", pain_score=3)
        PainEvent.objects.create(trainee=self.trainee, body_region="knee_left", pain_score=7)
        PainEvent.objects.create(trainee=self.other_trainee, body_region="knee_left", pain_score=9)

    def test_trainee_sees_only_own(self) -> None:
        response = self.trainee_client.get("/api/workouts/pain-events/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 3)

    def test_body_region_filter(self) -> None:
        response = self.trainee_client.get("/api/workouts/pain-events/?body_region=knee_left")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 2)
        for r in response.data["results"]:
            self.assertEqual(r["body_region"], "knee_left")

    def test_invalid_body_region_filter_gets_400(self) -> None:
        response = self.trainee_client.get("/api/workouts/pain-events/?body_region=left_pinky")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_trainer_sees_their_trainees_pain_events(self) -> None:
        response = self.trainer_client.get("/api/workouts/pain-events/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Trainer sees trainee's 3, NOT other_trainee's 1
        self.assertEqual(response.data["count"], 3)

    def test_other_trainer_sees_only_their_trainees(self) -> None:
        response = self.other_trainer_client.get("/api/workouts/pain-events/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)

    def test_admin_sees_all(self) -> None:
        response = self.admin_client.get("/api/workouts/pain-events/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 4)


# ===========================================================================
# VIEW TESTS -- TrainerRoutingRuleViewSet
# ===========================================================================


class TestRoutingRuleAccess(FeedbackTestBase):
    """Tests for TrainerRoutingRuleViewSet role-based access."""

    def test_trainee_gets_403_on_list(self) -> None:
        response = self.trainee_client.get("/api/workouts/routing-rules/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_gets_403_on_create(self) -> None:
        payload = {
            "rule_type": "low_rating",
            "threshold_value": {"min_rating": 2},
            "notification_method": "in_app",
        }
        response = self.trainee_client.post(
            "/api/workouts/routing-rules/", payload, format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_gets_403_on_retrieve(self) -> None:
        rules = self._create_routing_rules()
        url = f"/api/workouts/routing-rules/{rules[0].pk}/"
        response = self.trainee_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainee_gets_403_on_delete(self) -> None:
        rules = self._create_routing_rules()
        url = f"/api/workouts/routing-rules/{rules[0].pk}/"
        response = self.trainee_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_unauthenticated_gets_401(self) -> None:
        client = APIClient()
        response = client.get("/api/workouts/routing-rules/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class TestRoutingRuleCRUD(FeedbackTestBase):
    """Tests for TrainerRoutingRuleViewSet create/update/delete."""

    def test_trainer_can_list_own_rules(self) -> None:
        self._create_routing_rules()
        response = self.trainer_client.get("/api/workouts/routing-rules/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data if isinstance(response.data, list) else response.data.get("results", response.data)
        self.assertEqual(len(results), 5)

    def test_trainer_cannot_see_other_trainer_rules(self) -> None:
        self._create_routing_rules()
        create_default_routing_rules(self.other_trainer)

        response = self.trainer_client.get("/api/workouts/routing-rules/")
        results = response.data if isinstance(response.data, list) else response.data.get("results", response.data)
        self.assertEqual(len(results), 5)

    def test_trainer_can_create_rule(self) -> None:
        payload = {
            "rule_type": "low_rating",
            "threshold_value": {"min_rating": 1},
            "notification_method": "both",
        }
        response = self.trainer_client.post(
            "/api/workouts/routing-rules/", payload, format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["rule_type"], "low_rating")
        self.assertEqual(response.data["notification_method"], "both")

        rule = TrainerRoutingRule.objects.get(pk=response.data["id"])
        self.assertEqual(rule.trainer, self.trainer)

    def test_trainer_can_update_own_rule(self) -> None:
        rules = self._create_routing_rules()
        rule = rules[0]
        url = f"/api/workouts/routing-rules/{rule.pk}/"

        response = self.trainer_client.patch(
            url, {"notification_method": "email"}, format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        rule.refresh_from_db()
        self.assertEqual(rule.notification_method, "email")

    def test_trainer_cannot_update_other_trainer_rule(self) -> None:
        other_rules = create_default_routing_rules(self.other_trainer)
        rule = other_rules[0]
        url = f"/api/workouts/routing-rules/{rule.pk}/"

        response = self.trainer_client.patch(
            url, {"notification_method": "email"}, format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_trainer_can_delete_own_rule(self) -> None:
        rules = self._create_routing_rules()
        rule = rules[0]
        url = f"/api/workouts/routing-rules/{rule.pk}/"

        response = self.trainer_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(TrainerRoutingRule.objects.filter(pk=rule.pk).exists())

    def test_trainer_cannot_delete_other_trainer_rule(self) -> None:
        other_rules = create_default_routing_rules(self.other_trainer)
        rule = other_rules[0]
        url = f"/api/workouts/routing-rules/{rule.pk}/"

        response = self.trainer_client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_admin_can_see_all_rules(self) -> None:
        self._create_routing_rules()
        create_default_routing_rules(self.other_trainer)

        response = self.admin_client.get("/api/workouts/routing-rules/")
        results = response.data if isinstance(response.data, list) else response.data.get("results", response.data)
        self.assertEqual(len(results), 10)

    def test_threshold_value_must_be_dict_via_api(self) -> None:
        payload = {
            "rule_type": "low_rating",
            "threshold_value": "not_a_dict",
            "notification_method": "in_app",
        }
        response = self.trainer_client.post(
            "/api/workouts/routing-rules/", payload, format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class TestRoutingRuleInitializeView(FeedbackTestBase):
    """Tests for TrainerRoutingRuleViewSet.initialize action."""

    def test_trainer_can_initialize(self) -> None:
        url = "/api/workouts/routing-rules/initialize/"
        response = self.trainer_client.post(url)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data), 5)

    def test_initialize_idempotent(self) -> None:
        url = "/api/workouts/routing-rules/initialize/"

        self.trainer_client.post(url)
        response = self.trainer_client.post(url)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data), 0)
        self.assertEqual(
            TrainerRoutingRule.objects.filter(trainer=self.trainer).count(), 5,
        )

    def test_trainee_cannot_initialize(self) -> None:
        url = "/api/workouts/routing-rules/initialize/"
        response = self.trainee_client.post(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_cannot_initialize(self) -> None:
        url = "/api/workouts/routing-rules/initialize/"
        response = self.admin_client.post(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class TestRoutingRuleDefaultsView(FeedbackTestBase):
    """Tests for TrainerRoutingRuleViewSet.defaults action."""

    def test_trainer_can_get_defaults(self) -> None:
        url = "/api/workouts/routing-rules/defaults/"
        response = self.trainer_client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 5)
        rule_types = {r["rule_type"] for r in response.data}
        self.assertIn("low_rating", rule_types)
        self.assertIn("pain_report", rule_types)
        self.assertIn("high_difficulty", rule_types)
        self.assertIn("recovery_concern", rule_types)
        self.assertIn("form_breakdown", rule_types)
