"""
Feedback Service — v6.5 Step 9.

Processes end-of-session feedback, evaluates trainer routing rules,
and creates notifications when thresholds are exceeded.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

from django.db import transaction
from django.db.models import QuerySet

from trainer.models import TrainerNotification
from users.models import User
from workouts.models import (
    ActiveSession,
    DecisionLog,
    PainEvent,
    SessionFeedback,
    TrainerRoutingRule,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class TriggeredRule:
    """A routing rule that was triggered by feedback."""
    rule_id: str
    rule_type: str
    notification_method: str
    reason: str
    notification_id: str | None  # None if notification creation failed


@dataclass(frozen=True)
class FeedbackResult:
    """Result of submitting session feedback."""
    feedback_id: str
    active_session_id: str
    triggered_rules: list[TriggeredRule]
    pain_events_created: int


@dataclass(frozen=True)
class PainEventResult:
    """Result of logging a pain event."""
    pain_event_id: str
    body_region: str
    pain_score: int
    triggered_rules: list[TriggeredRule]


# ---------------------------------------------------------------------------
# Feedback submission
# ---------------------------------------------------------------------------

def submit_feedback(
    *,
    active_session: ActiveSession,
    trainee: User,
    completion_state: str,
    ratings: dict[str, int | None],
    friction_reasons: list[str],
    recovery_concern: bool,
    win_reasons: list[str] | None = None,
    session_volume_perception: str = '',
    requested_action: str = '',
    notes: str,
    pain_events_data: list[dict[str, Any]],
    actor_id: int | None = None,
) -> FeedbackResult:
    """
    Submit end-of-session feedback for an active session.

    Creates SessionFeedback, optional PainEvents, evaluates routing rules
    (including pattern-based rules), and creates TrainerNotifications.
    """
    with transaction.atomic():
        # Create feedback
        feedback = SessionFeedback.objects.create(
            active_session=active_session,
            trainee=trainee,
            completion_state=completion_state,
            rating_overall=ratings.get('overall'),
            rating_muscle_feel=ratings.get('muscle_feel'),
            rating_energy=ratings.get('energy'),
            rating_confidence=ratings.get('confidence'),
            rating_enjoyment=ratings.get('enjoyment'),
            rating_difficulty=ratings.get('difficulty'),
            friction_reasons=friction_reasons,
            recovery_concern=recovery_concern,
            win_reasons=win_reasons or [],
            session_volume_perception=session_volume_perception,
            requested_action=requested_action,
            notes=notes,
        )

        # Create pain events
        pain_events: list[PainEvent] = []
        for pe_data in pain_events_data:
            pain_event = PainEvent.objects.create(
                trainee=trainee,
                active_session=active_session,
                exercise_id=pe_data.get('exercise_id'),
                body_region=pe_data['body_region'],
                side=pe_data.get('side', 'midline'),
                pain_score=pe_data['pain_score'],
                sensation_type=pe_data.get('sensation_type', 'other'),
                onset_phase=pe_data.get('onset_phase', ''),
                warmup_effect=pe_data.get('warmup_effect', ''),
                notes=pe_data.get('notes', ''),
            )
            pain_events.append(pain_event)

        # Create DecisionLog
        DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.USER if actor_id
                else DecisionLog.ActorType.SYSTEM
            ),
            actor_id=actor_id,
            decision_type='session_feedback_submitted',
            context={
                'session_id': str(active_session.pk),
                'trainee_id': trainee.pk,
            },
            inputs_snapshot={
                'completion_state': completion_state,
                'ratings': ratings,
                'friction_reasons': friction_reasons,
                'recovery_concern': recovery_concern,
                'win_reasons': win_reasons or [],
                'session_volume_perception': session_volume_perception,
                'requested_action': requested_action,
                'pain_events_count': len(pain_events),
            },
            constraints_applied={},
            options_considered=[],
            final_choice={'feedback_id': str(feedback.pk)},
            reason_codes=['feedback_submitted'],
        )

    # Evaluate routing rules (outside transaction for notification side effects)
    triggered_rules = evaluate_routing_rules(
        feedback=feedback,
        pain_events=pain_events,
        trainee=trainee,
    )

    return FeedbackResult(
        feedback_id=str(feedback.pk),
        active_session_id=str(active_session.pk),
        triggered_rules=triggered_rules,
        pain_events_created=len(pain_events),
    )


# ---------------------------------------------------------------------------
# Routing rule evaluation
# ---------------------------------------------------------------------------

def evaluate_routing_rules(
    *,
    feedback: SessionFeedback,
    pain_events: list[PainEvent],
    trainee: User,
) -> list[TriggeredRule]:
    """
    Evaluate trainer routing rules against feedback/pain events.
    Creates TrainerNotification for each triggered rule.
    """
    trainer = trainee.parent_trainer
    if trainer is None:
        return []

    rules = list(
        TrainerRoutingRule.objects.filter(
            trainer=trainer,
            is_active=True,
        )
    )

    triggered: list[TriggeredRule] = []

    for rule in rules:
        reason = _check_rule(rule, feedback, pain_events)
        if reason is None:
            continue

        # Create notification
        notification = _create_notification(
            trainer=trainer,
            trainee=trainee,
            rule=rule,
            feedback=feedback,
            reason=reason,
        )

        triggered.append(TriggeredRule(
            rule_id=str(rule.pk),
            rule_type=rule.rule_type,
            notification_method=rule.notification_method,
            reason=reason,
            notification_id=str(notification.pk) if notification else None,
        ))

    return triggered


def _check_rule(
    rule: TrainerRoutingRule,
    feedback: SessionFeedback,
    pain_events: list[PainEvent],
) -> str | None:
    """Check if a single routing rule is triggered. Returns reason string or None."""
    threshold = rule.threshold_value
    rule_type = rule.rule_type

    if rule_type == 'low_rating':
        min_rating = int(threshold.get('min_rating', 2))
        if feedback.rating_overall is not None and feedback.rating_overall <= min_rating:
            return f"Overall rating {feedback.rating_overall} ≤ threshold {min_rating}"

    elif rule_type == 'pain_report':
        min_pain = int(threshold.get('min_pain_score', 7))
        for pe in pain_events:
            if pe.pain_score >= min_pain:
                return f"Pain score {pe.pain_score} ≥ threshold {min_pain} ({pe.body_region})"

    elif rule_type == 'high_difficulty':
        min_difficulty = int(threshold.get('min_difficulty', 5))
        if feedback.rating_difficulty is not None and feedback.rating_difficulty >= min_difficulty:
            return f"Difficulty rating {feedback.rating_difficulty} ≥ threshold {min_difficulty}"

    elif rule_type == 'recovery_concern':
        if feedback.recovery_concern:
            return "Trainee flagged recovery concern"

    elif rule_type == 'form_breakdown':
        if 'form_breakdown' in feedback.friction_reasons:
            return "Trainee reported form breakdown"

    elif rule_type == 'pattern_fit_issue':
        return _check_pattern_fit_issue(feedback)

    elif rule_type == 'pattern_confidence_drop':
        return _check_pattern_confidence_drop(feedback)

    return None


def _check_pattern_fit_issue(feedback: SessionFeedback) -> str | None:
    """Check if trainee has repeated exercise-fit friction across recent sessions."""
    fit_friction = {'equipment_unavailable', 'other'}
    if not fit_friction.intersection(feedback.friction_reasons):
        return None

    recent = list(
        SessionFeedback.objects.filter(
            trainee=feedback.trainee,
            created_at__lt=feedback.created_at,
        )
        .order_by('-created_at')
        .values_list('friction_reasons', flat=True)[:4]
    )
    fit_count = sum(
        1 for reasons in recent
        if isinstance(reasons, list) and fit_friction.intersection(reasons)
    )
    if fit_count >= 2:
        return f"Exercise-fit friction in {fit_count + 1} of last {len(recent) + 1} sessions"
    return None


def _check_pattern_confidence_drop(feedback: SessionFeedback) -> str | None:
    """Check if trainee confidence has been trending down over recent sessions."""
    if feedback.rating_confidence is None or feedback.rating_confidence > 2:
        return None

    recent = list(
        SessionFeedback.objects.filter(
            trainee=feedback.trainee,
            created_at__lt=feedback.created_at,
            rating_confidence__isnull=False,
        )
        .order_by('-created_at')
        .values_list('rating_confidence', flat=True)[:4]
    )
    low_count = sum(1 for r in recent if r <= 2)
    if low_count >= 2:
        return f"Confidence ≤ 2 in {low_count + 1} of last {len(recent) + 1} sessions"
    return None


def _create_notification(
    *,
    trainer: User,
    trainee: User,
    rule: TrainerRoutingRule,
    feedback: SessionFeedback,
    reason: str,
) -> TrainerNotification | None:
    """Create a TrainerNotification for a triggered routing rule."""
    # Map rule types to notification types
    type_map = {
        'low_rating': 'general',
        'pain_report': 'general',
        'high_difficulty': 'general',
        'recovery_concern': 'general',
        'form_breakdown': 'general',
        'missed_sessions': 'workout_missed',
        'pattern_fit_issue': 'general',
        'pattern_confidence_drop': 'general',
    }
    notification_type = type_map.get(rule.rule_type, 'general')

    trainee_name = trainee.get_full_name() or trainee.email

    title_map = {
        'low_rating': f"Low session rating from {trainee_name}",
        'pain_report': f"Pain report from {trainee_name}",
        'high_difficulty': f"High difficulty reported by {trainee_name}",
        'recovery_concern': f"Recovery concern from {trainee_name}",
        'form_breakdown': f"Form breakdown reported by {trainee_name}",
        'missed_sessions': f"Missed sessions alert for {trainee_name}",
        'pattern_fit_issue': f"Repeated exercise-fit issues for {trainee_name}",
        'pattern_confidence_drop': f"Falling confidence pattern for {trainee_name}",
    }

    try:
        return TrainerNotification.objects.create(
            trainer=trainer,
            notification_type=notification_type,
            title=title_map.get(rule.rule_type, f"Alert for {trainee_name}"),
            message=reason,
            data={
                'trainee_id': trainee.pk,
                'feedback_id': str(feedback.pk),
                'session_id': str(feedback.active_session_id),
                'rule_type': rule.rule_type,
                'rule_id': str(rule.pk),
            },
        )
    except Exception:
        logger.exception(
            "Failed to create notification for rule %s (trainer=%s, trainee=%s)",
            rule.pk, trainer.pk, trainee.pk,
        )
        return None


# ---------------------------------------------------------------------------
# Pain event logging (standalone)
# ---------------------------------------------------------------------------

def log_pain_event(
    *,
    trainee: User,
    body_region: str,
    pain_score: int,
    side: str = 'midline',
    sensation_type: str = 'other',
    onset_phase: str = '',
    warmup_effect: str = '',
    active_session_id: str | None = None,
    exercise_id: int | None = None,
    notes: str = '',
) -> PainEventResult:
    """Log a standalone pain event and evaluate routing rules."""
    pain_event = PainEvent.objects.create(
        trainee=trainee,
        active_session_id=active_session_id,
        exercise_id=exercise_id,
        body_region=body_region,
        side=side,
        pain_score=pain_score,
        sensation_type=sensation_type,
        onset_phase=onset_phase,
        warmup_effect=warmup_effect,
        notes=notes,
    )

    # Check pain routing rules
    triggered_rules: list[TriggeredRule] = []
    trainer = trainee.parent_trainer
    if trainer:
        rules = list(
            TrainerRoutingRule.objects.filter(
                trainer=trainer,
                rule_type='pain_report',
                is_active=True,
            )
        )
        for rule in rules:
            min_pain = int(rule.threshold_value.get('min_pain_score', 7))
            if pain_score >= min_pain:
                trainee_name = trainee.get_full_name() or trainee.email
                notification_id: str | None = None
                try:
                    notification = TrainerNotification.objects.create(
                        trainer=trainer,
                        notification_type='general',
                        title=f"Pain report from {trainee_name}",
                        message=f"Pain score {pain_score}/10 in {body_region}",
                        data={
                            'trainee_id': trainee.pk,
                            'pain_event_id': str(pain_event.pk),
                            'rule_type': 'pain_report',
                            'rule_id': str(rule.pk),
                        },
                    )
                    notification_id = str(notification.pk)
                except Exception:
                    logger.exception(
                        "Failed to create pain notification for rule %s",
                        rule.pk,
                    )
                triggered_rules.append(TriggeredRule(
                    rule_id=str(rule.pk),
                    rule_type='pain_report',
                    notification_method=rule.notification_method,
                    reason=f"Pain score {pain_score} ≥ {min_pain} ({body_region})",
                    notification_id=notification_id,
                ))

    return PainEventResult(
        pain_event_id=str(pain_event.pk),
        body_region=body_region,
        pain_score=pain_score,
        triggered_rules=triggered_rules,
    )


# ---------------------------------------------------------------------------
# History queries
# ---------------------------------------------------------------------------

def get_feedback_history(
    trainee_id: int,
    limit: int = 20,
) -> QuerySet[SessionFeedback]:
    """Get recent feedback for a trainee."""
    return (
        SessionFeedback.objects
        .filter(trainee_id=trainee_id)
        .select_related('active_session')
        .order_by('-created_at')[:limit]
    )


def get_pain_history(
    trainee_id: int,
    body_region: str | None = None,
    limit: int = 50,
) -> QuerySet[PainEvent]:
    """Get pain event history for a trainee, optionally filtered by body region."""
    qs = PainEvent.objects.filter(trainee_id=trainee_id)
    if body_region:
        qs = qs.filter(body_region=body_region)
    return qs.select_related('exercise', 'active_session').order_by('-created_at')[:limit]


# ---------------------------------------------------------------------------
# Default routing rules
# ---------------------------------------------------------------------------

DEFAULT_ROUTING_RULES: list[dict[str, Any]] = [
    {
        'rule_type': 'low_rating',
        'threshold_value': {'min_rating': 2},
        'notification_method': 'in_app',
    },
    {
        'rule_type': 'pain_report',
        'threshold_value': {'min_pain_score': 7},
        'notification_method': 'both',
    },
    {
        'rule_type': 'high_difficulty',
        'threshold_value': {'min_difficulty': 5},
        'notification_method': 'in_app',
    },
    {
        'rule_type': 'recovery_concern',
        'threshold_value': {},
        'notification_method': 'in_app',
    },
    {
        'rule_type': 'form_breakdown',
        'threshold_value': {},
        'notification_method': 'in_app',
    },
    {
        'rule_type': 'pattern_fit_issue',
        'threshold_value': {'lookback_sessions': 5},
        'notification_method': 'in_app',
    },
    {
        'rule_type': 'pattern_confidence_drop',
        'threshold_value': {'lookback_sessions': 5},
        'notification_method': 'in_app',
    },
]


def create_default_routing_rules(trainer: User) -> list[TrainerRoutingRule]:
    """Create default routing rules for a trainer. Skips existing rule types."""
    existing_types = set(
        TrainerRoutingRule.objects.filter(trainer=trainer)
        .values_list('rule_type', flat=True)
    )
    created: list[TrainerRoutingRule] = []
    for rule_data in DEFAULT_ROUTING_RULES:
        if rule_data['rule_type'] in existing_types:
            continue
        rule = TrainerRoutingRule.objects.create(
            trainer=trainer,
            rule_type=rule_data['rule_type'],
            threshold_value=rule_data['threshold_value'],
            notification_method=rule_data['notification_method'],
        )
        created.append(rule)
    return created
