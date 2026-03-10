"""
Serializers for Active Session endpoints — v6.5 Step 8.

Separate file to keep the main serializers.py clean.
"""
from __future__ import annotations

from decimal import Decimal
from typing import Any

from rest_framework import serializers

from .models import ActiveSession, ActiveSetLog


# ---------------------------------------------------------------------------
# Model Serializers (read)
# ---------------------------------------------------------------------------

class ActiveSetLogSerializer(serializers.ModelSerializer[ActiveSetLog]):
    """Full detail serializer for a single set log."""
    exercise_name = serializers.CharField(source='exercise.name', read_only=True)
    exercise_id = serializers.IntegerField(source='exercise.pk', read_only=True)
    slot_order = serializers.IntegerField(source='plan_slot.order', read_only=True, default=0)
    slot_role = serializers.CharField(source='plan_slot.slot_role', read_only=True, default='')

    class Meta:
        model = ActiveSetLog
        fields = [
            'id',
            'plan_slot',
            'exercise_id',
            'exercise_name',
            'slot_order',
            'slot_role',
            'set_number',
            'prescribed_reps_min',
            'prescribed_reps_max',
            'prescribed_load',
            'prescribed_load_unit',
            'completed_reps',
            'completed_load_value',
            'completed_load_unit',
            'rpe',
            'rest_prescribed_seconds',
            'rest_actual_seconds',
            'set_started_at',
            'set_completed_at',
            'status',
            'skip_reason',
            'notes',
            'created_at',
        ]
        read_only_fields = fields


class ActiveSessionSerializer(serializers.ModelSerializer[ActiveSession]):
    """Full detail serializer for an active session, with nested set logs."""
    set_logs = ActiveSetLogSerializer(many=True, read_only=True)
    plan_session_label = serializers.CharField(
        source='plan_session.label', read_only=True, default='Unknown',
    )
    total_sets = serializers.SerializerMethodField()
    completed_sets = serializers.SerializerMethodField()
    skipped_sets = serializers.SerializerMethodField()
    pending_sets = serializers.SerializerMethodField()
    progress_pct = serializers.SerializerMethodField()

    class Meta:
        model = ActiveSession
        fields = [
            'id',
            'trainee',
            'plan_session',
            'plan_session_label',
            'status',
            'started_at',
            'completed_at',
            'abandon_reason',
            'current_slot_index',
            'notes',
            'created_at',
            'updated_at',
            'set_logs',
            'total_sets',
            'completed_sets',
            'skipped_sets',
            'pending_sets',
            'progress_pct',
        ]
        read_only_fields = fields

    def get_total_sets(self, obj: ActiveSession) -> int:
        return obj.set_logs.count()

    def get_completed_sets(self, obj: ActiveSession) -> int:
        return obj.set_logs.filter(status=ActiveSetLog.Status.COMPLETED).count()

    def get_skipped_sets(self, obj: ActiveSession) -> int:
        return obj.set_logs.filter(status=ActiveSetLog.Status.SKIPPED).count()

    def get_pending_sets(self, obj: ActiveSession) -> int:
        return obj.set_logs.filter(status=ActiveSetLog.Status.PENDING).count()

    def get_progress_pct(self, obj: ActiveSession) -> float:
        total = obj.set_logs.count()
        if total == 0:
            return 0.0
        done = obj.set_logs.exclude(status=ActiveSetLog.Status.PENDING).count()
        return round(done / total * 100, 1)


class ActiveSessionListSerializer(serializers.ModelSerializer[ActiveSession]):
    """Lightweight serializer for session list views."""
    plan_session_label = serializers.CharField(
        source='plan_session.label', read_only=True, default='Unknown',
    )

    class Meta:
        model = ActiveSession
        fields = [
            'id',
            'plan_session',
            'plan_session_label',
            'status',
            'started_at',
            'completed_at',
            'current_slot_index',
            'created_at',
        ]
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Input Serializers
# ---------------------------------------------------------------------------

class StartSessionInputSerializer(serializers.Serializer[Any]):
    """Input for starting a new session."""
    plan_session_id = serializers.UUIDField(required=True)


class LogSetInputSerializer(serializers.Serializer[Any]):
    """Input for logging a completed set."""
    slot_id = serializers.UUIDField(
        required=True,
        help_text="The PlanSlot ID this set belongs to.",
    )
    set_number = serializers.IntegerField(
        required=True,
        min_value=1,
        help_text="1-based set number within the slot.",
    )
    completed_reps = serializers.IntegerField(
        required=True,
        min_value=0,
        help_text="Reps completed (0 for failed attempt).",
    )
    load_value = serializers.DecimalField(
        max_digits=8,
        decimal_places=2,
        required=False,
        allow_null=True,
        default=None,
        help_text="Actual load used.",
    )
    load_unit = serializers.ChoiceField(
        choices=[('lb', 'Pounds'), ('kg', 'Kilograms')],
        default='lb',
        required=False,
    )
    rpe = serializers.DecimalField(
        max_digits=3,
        decimal_places=1,
        required=False,
        allow_null=True,
        default=None,
        min_value=Decimal('1'),
        max_value=Decimal('10'),
        help_text="Rate of Perceived Exertion (1-10).",
    )
    rest_actual_seconds = serializers.IntegerField(
        required=False,
        allow_null=True,
        default=None,
        min_value=0,
        help_text="Actual rest time taken in seconds.",
    )
    notes = serializers.CharField(
        required=False,
        default='',
        allow_blank=True,
    )


class SkipSetInputSerializer(serializers.Serializer[Any]):
    """Input for skipping a set."""
    slot_id = serializers.UUIDField(
        required=True,
        help_text="The PlanSlot ID this set belongs to.",
    )
    set_number = serializers.IntegerField(
        required=True,
        min_value=1,
        help_text="1-based set number within the slot.",
    )
    reason = serializers.CharField(
        required=False,
        default='',
        allow_blank=True,
        max_length=255,
    )


class AbandonSessionInputSerializer(serializers.Serializer[Any]):
    """Input for abandoning a session."""
    reason = serializers.CharField(
        required=False,
        default='',
        allow_blank=True,
        max_length=255,
    )


# ---------------------------------------------------------------------------
# Response Serializers (for service dataclasses)
# ---------------------------------------------------------------------------

class SetStatusResponseSerializer(serializers.Serializer[Any]):
    """Serializer for SetStatus dataclass."""
    set_log_id = serializers.CharField()
    set_number = serializers.IntegerField()
    status = serializers.CharField()
    prescribed_reps_min = serializers.IntegerField()
    prescribed_reps_max = serializers.IntegerField()
    prescribed_load = serializers.DecimalField(max_digits=8, decimal_places=2, allow_null=True)
    prescribed_load_unit = serializers.CharField()
    completed_reps = serializers.IntegerField(allow_null=True)
    completed_load_value = serializers.DecimalField(max_digits=8, decimal_places=2, allow_null=True)
    completed_load_unit = serializers.CharField()
    rpe = serializers.DecimalField(max_digits=3, decimal_places=1, allow_null=True)
    rest_prescribed_seconds = serializers.IntegerField()
    rest_actual_seconds = serializers.IntegerField(allow_null=True)
    notes = serializers.CharField()


class SlotStatusResponseSerializer(serializers.Serializer[Any]):
    """Serializer for SlotStatus dataclass."""
    slot_id = serializers.CharField()
    exercise_name = serializers.CharField()
    exercise_id = serializers.IntegerField()
    order = serializers.IntegerField()
    slot_role = serializers.CharField()
    is_current = serializers.BooleanField()
    sets = SetStatusResponseSerializer(many=True)


class SessionStatusResponseSerializer(serializers.Serializer[Any]):
    """Serializer for SessionStatus dataclass."""
    active_session_id = serializers.CharField()
    status = serializers.CharField()
    trainee_id = serializers.IntegerField()
    plan_session_id = serializers.CharField(allow_null=True)
    plan_session_label = serializers.CharField()
    current_slot_index = serializers.IntegerField()
    total_slots = serializers.IntegerField()
    slots = SlotStatusResponseSerializer(many=True)
    started_at = serializers.CharField(allow_null=True)
    completed_at = serializers.CharField(allow_null=True)
    progress_pct = serializers.FloatField()
    total_sets = serializers.IntegerField()
    completed_sets = serializers.IntegerField()
    skipped_sets = serializers.IntegerField()
    pending_sets = serializers.IntegerField()
    elapsed_seconds = serializers.IntegerField(allow_null=True)


class ProgressionResultSerializer(serializers.Serializer[Any]):
    """Serializer for a single progression result dict."""
    slot_id = serializers.CharField()
    event_type = serializers.CharField()
    old_prescription = serializers.DictField()
    new_prescription = serializers.DictField()
    reason_codes = serializers.ListField(child=serializers.CharField())


class SessionSummaryResponseSerializer(serializers.Serializer[Any]):
    """Serializer for SessionSummary dataclass (complete/abandon responses)."""
    active_session_id = serializers.CharField()
    status = serializers.CharField()
    total_sets = serializers.IntegerField()
    completed_sets = serializers.IntegerField()
    skipped_sets = serializers.IntegerField()
    duration_seconds = serializers.IntegerField(allow_null=True)
    progression_results = ProgressionResultSerializer(many=True)
