"""
Tests for Session Feedback + Trainer Routing Rules — v6.5 Step 9.

Covers:
- submit_feedback: normal flow, creates DecisionLog, triggers routing rules
- submit_feedback: no trainer = no routing evaluation
- log_pain_event: standalone creation, triggers pain_report rule
- evaluate_routing_rules: all 5 rule types
- create_default_routing_rules: creates defaults, idempotent
- get_feedback_history, get_pain_history
- Serializer validation: friction_reasons, pain_score bounds, threshold_value
- API endpoints: role enforcement, duplicate prevention, body_region filter
"""
from __future__ import annotations

import uuid
from unittest.mock import patch

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User
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
    """Shared setup: trainer, trainee, exercise, plan hierarchy, active session."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="fb_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee = User.objects.create_user(
            email="fb_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )
        self.exercise = Exercise.objects.create(
            name="Bench Press",
            equipment_required=["barbell"],
            created_by=self.trainer,
        )
        self.plan = TrainingPlan.objects.create(
            trainee=self.trainee,
            name="Test Plan",
            goal="strength",
            status="active",
        )
        self.week = PlanWeek.objects.create(
            plan=self.plan,
            week_number=1,
        )
        self.plan_session = PlanSession.objects.create(
            week=self.week,
            day_of_week=1,
            label="Day 1",
            order=1,
        )
        self.active_session = ActiveSession.objects.create(
            trainee=self.trainee,
            plan_session=self.plan_session,
            status='completed',
        )

        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)


# ---------------------------------------------------------------------------
# Service: submit_feedback
# ---------------------------------------------------------------------------


class SubmitFeedbackServiceTest(FeedbackTestBase):

    def test_creates_feedback_and_pain_events(self) -> None:
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={'overall': 4, 'difficulty': 3},
            friction_reasons=[],
            recovery_concern=False,
            notes='Great session',
            pain_events_data=[
                {'body_region': 'knee_left', 'pain_score': 5, 'side': 'left'},
            ],
            actor_id=self.trainee.pk,
        )
        self.assertIsNotNone(result.feedback_id)
        self.assertEqual(result.pain_events_created, 1)
        self.assertTrue(SessionFeedback.objects.filter(pk=result.feedback_id).exists())
        self.assertEqual(PainEvent.objects.filter(trainee=self.trainee).count(), 1)

    def test_creates_decision_log(self) -> None:
        submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
            actor_id=self.trainee.pk,
        )
        log = DecisionLog.objects.filter(decision_type='session_feedback_submitted').first()
        self.assertIsNotNone(log)
        self.assertEqual(log.context['trainee_id'], self.trainee.pk)

    def test_no_trainer_no_routing_rules(self) -> None:
        orphan = User.objects.create_user(
            email="orphan@test.com",
            password="testpass123",
            role="TRAINEE",
        )
        session = ActiveSession.objects.create(
            trainee=orphan,
            status='completed',
        )
        result = submit_feedback(
            active_session=session,
            trainee=orphan,
            completion_state='completed',
            ratings={'overall': 1},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(result.triggered_rules, [])

    def test_triggers_low_rating_rule(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='low_rating',
            threshold_value={'min_rating': 2},
            notification_method='in_app',
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={'overall': 1},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(len(result.triggered_rules), 1)
        self.assertEqual(result.triggered_rules[0].rule_type, 'low_rating')

    def test_triggers_pain_report_rule(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='pain_report',
            threshold_value={'min_pain_score': 7},
            notification_method='both',
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[
                {'body_region': 'lower_back', 'pain_score': 8},
            ],
        )
        self.assertEqual(len(result.triggered_rules), 1)
        self.assertEqual(result.triggered_rules[0].rule_type, 'pain_report')

    def test_triggers_recovery_concern_rule(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='recovery_concern',
            threshold_value={},
            notification_method='in_app',
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={},
            friction_reasons=[],
            recovery_concern=True,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(len(result.triggered_rules), 1)
        self.assertEqual(result.triggered_rules[0].rule_type, 'recovery_concern')

    def test_triggers_form_breakdown_rule(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='form_breakdown',
            threshold_value={},
            notification_method='in_app',
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='partial',
            ratings={},
            friction_reasons=['form_breakdown'],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(len(result.triggered_rules), 1)
        self.assertEqual(result.triggered_rules[0].rule_type, 'form_breakdown')

    def test_triggers_high_difficulty_rule(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='high_difficulty',
            threshold_value={'min_difficulty': 5},
            notification_method='in_app',
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={'difficulty': 5},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(len(result.triggered_rules), 1)
        self.assertEqual(result.triggered_rules[0].rule_type, 'high_difficulty')

    def test_no_trigger_when_below_threshold(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='low_rating',
            threshold_value={'min_rating': 2},
            notification_method='in_app',
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={'overall': 4},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(len(result.triggered_rules), 0)

    def test_inactive_rule_not_evaluated(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='low_rating',
            threshold_value={'min_rating': 2},
            notification_method='in_app',
            is_active=False,
        )
        result = submit_feedback(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            ratings={'overall': 1},
            friction_reasons=[],
            recovery_concern=False,
            notes='',
            pain_events_data=[],
        )
        self.assertEqual(len(result.triggered_rules), 0)


# ---------------------------------------------------------------------------
# Service: log_pain_event
# ---------------------------------------------------------------------------


class LogPainEventServiceTest(FeedbackTestBase):

    def test_creates_pain_event(self) -> None:
        result = log_pain_event(
            trainee=self.trainee,
            body_region='knee_left',
            pain_score=6,
            side='left',
        )
        self.assertIsNotNone(result.pain_event_id)
        self.assertEqual(result.body_region, 'knee_left')
        self.assertEqual(result.pain_score, 6)

    def test_triggers_pain_rule(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='pain_report',
            threshold_value={'min_pain_score': 7},
            notification_method='both',
        )
        result = log_pain_event(
            trainee=self.trainee,
            body_region='lower_back',
            pain_score=8,
        )
        self.assertEqual(len(result.triggered_rules), 1)
        self.assertIsNotNone(result.triggered_rules[0].notification_id)

    def test_no_trigger_below_threshold(self) -> None:
        TrainerRoutingRule.objects.create(
            trainer=self.trainer,
            rule_type='pain_report',
            threshold_value={'min_pain_score': 7},
            notification_method='both',
        )
        result = log_pain_event(
            trainee=self.trainee,
            body_region='lower_back',
            pain_score=5,
        )
        self.assertEqual(len(result.triggered_rules), 0)


# ---------------------------------------------------------------------------
# Service: create_default_routing_rules
# ---------------------------------------------------------------------------


class DefaultRoutingRulesTest(FeedbackTestBase):

    def test_creates_five_defaults(self) -> None:
        created = create_default_routing_rules(trainer=self.trainer)
        self.assertEqual(len(created), 5)
        types = {r.rule_type for r in created}
        self.assertEqual(types, {'low_rating', 'pain_report', 'high_difficulty', 'recovery_concern', 'form_breakdown'})

    def test_idempotent(self) -> None:
        create_default_routing_rules(trainer=self.trainer)
        created_again = create_default_routing_rules(trainer=self.trainer)
        self.assertEqual(len(created_again), 0)
        self.assertEqual(TrainerRoutingRule.objects.filter(trainer=self.trainer).count(), 5)


# ---------------------------------------------------------------------------
# Service: history queries
# ---------------------------------------------------------------------------


class HistoryQueryTest(FeedbackTestBase):

    def test_feedback_history(self) -> None:
        SessionFeedback.objects.create(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
        )
        qs = get_feedback_history(self.trainee.pk)
        self.assertEqual(qs.count(), 1)

    def test_pain_history_with_filter(self) -> None:
        PainEvent.objects.create(trainee=self.trainee, body_region='knee_left', pain_score=5)
        PainEvent.objects.create(trainee=self.trainee, body_region='lower_back', pain_score=3)
        qs = get_pain_history(self.trainee.pk, body_region='knee_left')
        self.assertEqual(qs.count(), 1)


# ---------------------------------------------------------------------------
# API: SessionFeedbackViewSet
# ---------------------------------------------------------------------------


class SessionFeedbackAPITest(FeedbackTestBase):

    def test_submit_feedback_trainee(self) -> None:
        resp = self.trainee_client.post(
            f'/api/workouts/session-feedback/submit/{self.active_session.pk}/',
            data={
                'completion_state': 'completed',
                'ratings': {'overall': 4},
                'friction_reasons': [],
                'recovery_concern': False,
                'notes': 'Good',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('feedback_id', resp.data)

    def test_submit_feedback_trainer_forbidden(self) -> None:
        resp = self.trainer_client.post(
            f'/api/workouts/session-feedback/submit/{self.active_session.pk}/',
            data={'completion_state': 'completed'},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_submit_duplicate_409(self) -> None:
        SessionFeedback.objects.create(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
        )
        resp = self.trainee_client.post(
            f'/api/workouts/session-feedback/submit/{self.active_session.pk}/',
            data={'completion_state': 'completed'},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_409_CONFLICT)

    def test_submit_non_completed_session_400(self) -> None:
        in_progress = ActiveSession.objects.create(
            trainee=self.trainee,
            status='in_progress',
        )
        resp = self.trainee_client.post(
            f'/api/workouts/session-feedback/submit/{in_progress.pk}/',
            data={'completion_state': 'completed'},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_submit_other_trainee_session_404(self) -> None:
        other_trainee = User.objects.create_user(
            email="other@test.com",
            password="testpass123",
            role="TRAINEE",
        )
        other_session = ActiveSession.objects.create(
            trainee=other_trainee,
            status='completed',
        )
        resp = self.trainee_client.post(
            f'/api/workouts/session-feedback/submit/{other_session.pk}/',
            data={'completion_state': 'completed'},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_for_session_returns_feedback(self) -> None:
        SessionFeedback.objects.create(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
            rating_overall=4,
        )
        resp = self.trainee_client.get(
            f'/api/workouts/session-feedback/for-session/{self.active_session.pk}/',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['rating_overall'], 4)

    def test_list_role_filtering(self) -> None:
        SessionFeedback.objects.create(
            active_session=self.active_session,
            trainee=self.trainee,
            completion_state='completed',
        )
        resp = self.trainee_client.get('/api/workouts/session-feedback/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['count'], 1)

        resp = self.trainer_client.get('/api/workouts/session-feedback/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['count'], 1)


# ---------------------------------------------------------------------------
# API: PainEventViewSet
# ---------------------------------------------------------------------------


class PainEventAPITest(FeedbackTestBase):

    def test_log_pain_event_trainee(self) -> None:
        resp = self.trainee_client.post(
            '/api/workouts/pain-events/log/',
            data={
                'body_region': 'knee_left',
                'pain_score': 6,
                'side': 'left',
                'sensation_type': 'sharp',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn('pain_event_id', resp.data)

    def test_log_pain_event_trainer_forbidden(self) -> None:
        resp = self.trainer_client.post(
            '/api/workouts/pain-events/log/',
            data={'body_region': 'knee_left', 'pain_score': 6},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_list_with_body_region_filter(self) -> None:
        PainEvent.objects.create(trainee=self.trainee, body_region='knee_left', pain_score=5)
        PainEvent.objects.create(trainee=self.trainee, body_region='lower_back', pain_score=3)
        resp = self.trainee_client.get('/api/workouts/pain-events/?body_region=knee_left')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['count'], 1)

    def test_list_invalid_body_region_400(self) -> None:
        resp = self.trainee_client.get('/api/workouts/pain-events/?body_region=invalid_region')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_pain_score_out_of_range(self) -> None:
        resp = self.trainee_client.post(
            '/api/workouts/pain-events/log/',
            data={'body_region': 'knee_left', 'pain_score': 11},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# API: TrainerRoutingRuleViewSet
# ---------------------------------------------------------------------------


class RoutingRuleAPITest(FeedbackTestBase):

    def test_trainee_cannot_access(self) -> None:
        resp = self.trainee_client.get('/api/workouts/routing-rules/')
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_trainer_can_list(self) -> None:
        create_default_routing_rules(trainer=self.trainer)
        resp = self.trainer_client.get('/api/workouts/routing-rules/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 5)

    def test_trainer_can_create(self) -> None:
        resp = self.trainer_client.post(
            '/api/workouts/routing-rules/',
            data={
                'rule_type': 'low_rating',
                'threshold_value': {'min_rating': 3},
                'notification_method': 'in_app',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_initialize_defaults(self) -> None:
        resp = self.trainer_client.post('/api/workouts/routing-rules/initialize/')
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(resp.data), 5)

    def test_defaults_endpoint(self) -> None:
        resp = self.trainer_client.get('/api/workouts/routing-rules/defaults/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp.data), 5)

    def test_trainer_cannot_modify_other_trainers_rule(self) -> None:
        other_trainer = User.objects.create_user(
            email="other_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        rule = TrainerRoutingRule.objects.create(
            trainer=other_trainer,
            rule_type='low_rating',
            threshold_value={'min_rating': 2},
        )
        resp = self.trainer_client.patch(
            f'/api/workouts/routing-rules/{rule.pk}/',
            data={'is_active': False},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)

    def test_threshold_value_must_be_dict(self) -> None:
        resp = self.trainer_client.post(
            '/api/workouts/routing-rules/',
            data={
                'rule_type': 'low_rating',
                'threshold_value': 'not_a_dict',
                'notification_method': 'in_app',
            },
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# Serializer validation
# ---------------------------------------------------------------------------


class SerializerValidationTest(TestCase):

    def test_invalid_friction_reason(self) -> None:
        from workouts.feedback_serializers import SubmitFeedbackInputSerializer
        s = SubmitFeedbackInputSerializer(data={
            'completion_state': 'completed',
            'friction_reasons': ['invalid_reason'],
        })
        self.assertFalse(s.is_valid())
        self.assertIn('friction_reasons', s.errors)

    def test_valid_friction_reasons(self) -> None:
        from workouts.feedback_serializers import SubmitFeedbackInputSerializer
        s = SubmitFeedbackInputSerializer(data={
            'completion_state': 'completed',
            'friction_reasons': ['too_heavy', 'fatigue'],
        })
        self.assertTrue(s.is_valid())
