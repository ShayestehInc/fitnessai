"""
Serializers for session feedback, pain events, and trainer routing rules (v6.5 Step 9).
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any

from rest_framework import serializers

from .models import (
    PainEvent,
    PainInterventionStep,
    PainTriageResponse,
    SessionFeedback,
    TrainerRoutingRule,
)


# ---------------------------------------------------------------------------
# Pain Event serializers
# ---------------------------------------------------------------------------

class PainEventInputSerializer(serializers.Serializer[None]):
    """Input for logging a pain event (standalone or within feedback)."""
    body_region = serializers.ChoiceField(choices=PainEvent.BodyRegion.choices)
    side = serializers.ChoiceField(choices=PainEvent.Side.choices, default='midline')
    pain_score = serializers.IntegerField(min_value=1, max_value=10)
    sensation_type = serializers.ChoiceField(
        choices=PainEvent.SensationType.choices, default='other',
    )
    onset_phase = serializers.ChoiceField(
        choices=PainEvent.OnsetPhase.choices, required=False, default='',
    )
    warmup_effect = serializers.ChoiceField(
        choices=PainEvent.WarmupEffect.choices, required=False, default='',
    )
    exercise_id = serializers.IntegerField(required=False)
    active_session_id = serializers.UUIDField(required=False)
    notes = serializers.CharField(required=False, default='', max_length=1000)


class PainEventSerializer(serializers.ModelSerializer[PainEvent]):
    """Read serializer for PainEvent."""
    exercise_name = serializers.CharField(
        source='exercise.name', read_only=True, default=None,
    )

    class Meta:
        model = PainEvent
        fields = [
            'id', 'trainee', 'active_session', 'exercise', 'exercise_name',
            'body_region', 'side', 'pain_score', 'sensation_type',
            'onset_phase', 'warmup_effect', 'notes', 'created_at',
        ]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Session Feedback serializers
# ---------------------------------------------------------------------------

class FeedbackRatingsSerializer(serializers.Serializer[None]):
    """Ratings sub-object for feedback submission."""
    overall = serializers.IntegerField(min_value=1, max_value=5, required=False)
    muscle_feel = serializers.IntegerField(min_value=1, max_value=5, required=False)
    energy = serializers.IntegerField(min_value=1, max_value=5, required=False)
    confidence = serializers.IntegerField(min_value=1, max_value=5, required=False)
    enjoyment = serializers.IntegerField(min_value=1, max_value=5, required=False)
    difficulty = serializers.IntegerField(min_value=1, max_value=5, required=False)


class SubmitFeedbackInputSerializer(serializers.Serializer[None]):
    """Input serializer for submitting end-of-session feedback."""
    completion_state = serializers.ChoiceField(
        choices=SessionFeedback.CompletionState.choices,
    )
    ratings = FeedbackRatingsSerializer(required=False, default=dict)
    friction_reasons = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        default=list,
    )
    recovery_concern = serializers.BooleanField(default=False)

    # v6.5 §25: Wins, context, and action rows
    win_reasons = serializers.ListField(
        child=serializers.CharField(max_length=50),
        required=False,
        default=list,
    )
    session_volume_perception = serializers.ChoiceField(
        choices=[('', '')] + list(SessionFeedback.VolumePerception.choices),
        required=False,
        default='',
    )
    requested_action = serializers.ChoiceField(
        choices=[('', '')] + list(SessionFeedback.RequestedAction.choices),
        required=False,
        default='',
    )

    notes = serializers.CharField(required=False, default='', max_length=2000)
    pain_events = PainEventInputSerializer(many=True, required=False, default=list)

    def validate_friction_reasons(self, value: list[str]) -> list[str]:
        valid_reasons = {
            'too_heavy', 'too_light', 'time_pressure', 'pain',
            'form_breakdown', 'fatigue', 'equipment_unavailable', 'other',
        }
        for reason in value:
            if reason not in valid_reasons:
                raise serializers.ValidationError(
                    f"Invalid friction reason: '{reason}'. "
                    f"Valid: {', '.join(sorted(valid_reasons))}"
                )
        return value

    def validate_win_reasons(self, value: list[str]) -> list[str]:
        valid_wins = {
            'strong_performance', 'great_pump', 'smoother_technique',
            'pain_free', 'confidence_boost', 'efficient_session',
        }
        for reason in value:
            if reason not in valid_wins:
                raise serializers.ValidationError(
                    f"Invalid win reason: '{reason}'. "
                    f"Valid: {', '.join(sorted(valid_wins))}"
                )
        return value


class SessionFeedbackSerializer(serializers.ModelSerializer[SessionFeedback]):
    """Read serializer for SessionFeedback."""

    class Meta:
        model = SessionFeedback
        fields = [
            'id', 'active_session', 'trainee', 'completion_state',
            'rating_overall', 'rating_muscle_feel', 'rating_energy',
            'rating_confidence', 'rating_enjoyment', 'rating_difficulty',
            'friction_reasons', 'recovery_concern',
            'win_reasons', 'session_volume_perception', 'requested_action',
            'notes', 'created_at',
        ]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Pain Triage serializers (v6.5 §24)
# ---------------------------------------------------------------------------

class PainTriageStartSerializer(serializers.Serializer[None]):
    """Input for starting a pain triage flow."""
    pain_event_id = serializers.UUIDField()
    active_session_id = serializers.UUIDField()
    active_set_log_id = serializers.UUIDField(required=False)


class Round2InputSerializer(serializers.Serializer[None]):
    """Input for round 2 of pain triage (movement sensitivity)."""
    SENSITIVITY_CHOICES = [('better', 'Better'), ('same', 'Same'), ('worse', 'Worse')]

    load_sensitivity = serializers.ChoiceField(choices=SENSITIVITY_CHOICES)
    rom_sensitivity = serializers.ChoiceField(choices=SENSITIVITY_CHOICES)
    tempo_sensitivity = serializers.ChoiceField(choices=SENSITIVITY_CHOICES)
    support_helps = serializers.BooleanField(default=False)
    previous_trigger = serializers.CharField(required=False, default='', max_length=500)


class InterventionStepInputSerializer(serializers.Serializer[None]):
    """Input for recording an intervention step result."""
    step_order = serializers.IntegerField(min_value=1)
    applied = serializers.BooleanField()
    result = serializers.ChoiceField(
        choices=PainInterventionStep.StepResult.choices,
    )


class FinalizeProceedSerializer(serializers.Serializer[None]):
    """Input for finalizing a triage with a proceed decision."""
    proceed_decision = serializers.ChoiceField(
        choices=PainTriageResponse.ProceedDecision.choices,
    )


class PainInterventionStepSerializer(serializers.ModelSerializer[PainInterventionStep]):
    """Read serializer for PainInterventionStep."""

    class Meta:
        model = PainInterventionStep
        fields = [
            'id', 'order', 'intervention_type', 'description',
            'applied', 'result', 'details', 'created_at',
        ]
        read_only_fields = fields


class PainTriageResponseSerializer(serializers.ModelSerializer[PainTriageResponse]):
    """Read serializer for PainTriageResponse."""
    steps = PainInterventionStepSerializer(many=True, read_only=True)

    class Meta:
        model = PainTriageResponse
        fields = [
            'id', 'pain_event', 'active_session', 'active_set_log',
            'trainee', 'round_1_answers', 'round_2_answers',
            'ai_suggestion', 'ai_confidence', 'proceed_decision',
            'trainer_notified', 'steps', 'created_at',
        ]
        read_only_fields = fields


class RemedySuggestionSerializer(serializers.Serializer[None]):
    """Output serializer for a remedy ladder step."""
    order = serializers.IntegerField()
    intervention_type = serializers.CharField()
    description = serializers.CharField()
    applicable = serializers.BooleanField()
    details = serializers.DictField(default=dict)


# ---------------------------------------------------------------------------
# Trainer Routing Rule serializers
# ---------------------------------------------------------------------------

class TrainerRoutingRuleSerializer(serializers.ModelSerializer[TrainerRoutingRule]):
    """CRUD serializer for TrainerRoutingRule."""

    class Meta:
        model = TrainerRoutingRule
        fields = [
            'id', 'trainer', 'rule_type', 'threshold_value',
            'notification_method', 'is_active', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'trainer', 'created_at', 'updated_at']

    def validate_threshold_value(self, value: Any) -> Any:
        if not isinstance(value, dict):
            raise serializers.ValidationError("threshold_value must be a JSON object.")
        return value


class TrainerRoutingRuleListSerializer(serializers.ModelSerializer[TrainerRoutingRule]):
    """Lightweight list serializer."""

    class Meta:
        model = TrainerRoutingRule
        fields = [
            'id', 'rule_type', 'notification_method', 'is_active',
        ]
