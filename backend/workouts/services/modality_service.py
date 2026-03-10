"""
Modality Library Service — v6.5 Step 6.

Provides:
- Guardrail validation for modality assignments
- Default modality selection during plan generation (A5 enhancement)
- Volume contribution computation with modality multipliers
- Session-level volume summaries per muscle group
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from decimal import Decimal
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from workouts.services.training_generator_service import SlotSpec

from django.db import transaction
from django.db.models import QuerySet

from workouts.models import (
    DecisionLog,
    Exercise,
    ModalityGuardrail,
    PlanSession,
    PlanSlot,
    SetStructureModality,
    UndoSnapshot,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class GuardrailViolation:
    """A single guardrail violation."""
    guardrail_id: str
    rule_type: str
    condition_field: str
    condition_operator: str
    condition_value: Any
    error_message: str


@dataclass(frozen=True)
class ModalityRecommendation:
    """A recommended modality for a slot with its score and violations."""
    modality_id: str
    modality_name: str
    modality_slug: str
    volume_multiplier: str  # Decimal as string for JSON serialization
    score: int  # Higher = better match
    violations: list[GuardrailViolation]
    is_valid: bool  # No violations


@dataclass(frozen=True)
class ApplyModalityResult:
    """Result of applying a modality to a slot."""
    slot_id: str
    modality_id: str
    modality_name: str
    volume_contribution: str  # Decimal as string
    decision_log_id: str
    guardrails_overridden: list[str]


@dataclass(frozen=True)
class MuscleVolumeEntry:
    """Volume contribution for a single muscle group in a session."""
    muscle_group: str
    raw_sets: int
    adjusted_volume: str  # Decimal as string (sets × multiplier)
    slot_count: int


@dataclass(frozen=True)
class SessionVolumeSummary:
    """Per-muscle volume summary for a session, accounting for modality multipliers."""
    session_id: str
    session_label: str
    total_raw_sets: int
    total_adjusted_volume: str  # Decimal as string
    by_muscle: list[MuscleVolumeEntry]


# ---------------------------------------------------------------------------
# Default modality assignment table: (goal, slot_role) → modality slug
# ---------------------------------------------------------------------------

_DEFAULT_MODALITY: dict[tuple[str, str], str] = {
    # Build Muscle — compounds straight, accessories varied
    ('build_muscle', 'primary_compound'): 'straight-sets',
    ('build_muscle', 'secondary_compound'): 'straight-sets',
    ('build_muscle', 'accessory'): 'straight-sets',
    ('build_muscle', 'isolation'): 'straight-sets',
    # Strength — always straight sets for control
    ('strength', 'primary_compound'): 'straight-sets',
    ('strength', 'secondary_compound'): 'straight-sets',
    ('strength', 'accessory'): 'down-sets',
    ('strength', 'isolation'): 'straight-sets',
    # Fat Loss — metabolite-friendly modalities for accessories/isolation
    ('fat_loss', 'primary_compound'): 'straight-sets',
    ('fat_loss', 'secondary_compound'): 'straight-sets',
    ('fat_loss', 'accessory'): 'straight-sets',
    ('fat_loss', 'isolation'): 'drop-sets',
    # Endurance
    ('endurance', 'primary_compound'): 'straight-sets',
    ('endurance', 'secondary_compound'): 'straight-sets',
    ('endurance', 'accessory'): 'straight-sets',
    ('endurance', 'isolation'): 'straight-sets',
    # Recomp
    ('recomp', 'primary_compound'): 'straight-sets',
    ('recomp', 'secondary_compound'): 'straight-sets',
    ('recomp', 'accessory'): 'straight-sets',
    ('recomp', 'isolation'): 'straight-sets',
    # General Fitness
    ('general_fitness', 'primary_compound'): 'straight-sets',
    ('general_fitness', 'secondary_compound'): 'straight-sets',
    ('general_fitness', 'accessory'): 'straight-sets',
    ('general_fitness', 'isolation'): 'straight-sets',
}

# Deload always uses straight sets
_DELOAD_MODALITY_SLUG = 'straight-sets'

# Modality scoring: how well does a modality fit a (goal, slot_role)?
# Higher score = better recommendation. 0 = not recommended.
_MODALITY_SCORES: dict[str, dict[tuple[str, str], int]] = {
    'straight-sets': {
        ('build_muscle', 'primary_compound'): 10,
        ('build_muscle', 'secondary_compound'): 9,
        ('build_muscle', 'accessory'): 7,
        ('build_muscle', 'isolation'): 6,
        ('strength', 'primary_compound'): 10,
        ('strength', 'secondary_compound'): 10,
        ('strength', 'accessory'): 8,
        ('strength', 'isolation'): 7,
        ('fat_loss', 'primary_compound'): 8,
        ('fat_loss', 'secondary_compound'): 7,
        ('fat_loss', 'accessory'): 5,
        ('fat_loss', 'isolation'): 4,
        ('endurance', 'primary_compound'): 8,
        ('endurance', 'secondary_compound'): 8,
        ('endurance', 'accessory'): 7,
        ('endurance', 'isolation'): 7,
        ('recomp', 'primary_compound'): 9,
        ('recomp', 'secondary_compound'): 8,
        ('recomp', 'accessory'): 7,
        ('recomp', 'isolation'): 6,
        ('general_fitness', 'primary_compound'): 9,
        ('general_fitness', 'secondary_compound'): 9,
        ('general_fitness', 'accessory'): 8,
        ('general_fitness', 'isolation'): 7,
    },
    'down-sets': {
        ('strength', 'accessory'): 8,
        ('strength', 'isolation'): 6,
        ('build_muscle', 'accessory'): 6,
        ('build_muscle', 'isolation'): 5,
    },
    'controlled-eccentrics': {
        ('build_muscle', 'accessory'): 7,
        ('build_muscle', 'isolation'): 8,
        ('recomp', 'accessory'): 6,
    },
    'giant-sets': {
        ('build_muscle', 'accessory'): 5,
        ('build_muscle', 'isolation'): 6,
        ('fat_loss', 'accessory'): 7,
        ('fat_loss', 'isolation'): 8,
    },
    'myo-reps': {
        ('build_muscle', 'isolation'): 7,
        ('fat_loss', 'isolation'): 8,
        ('recomp', 'isolation'): 6,
    },
    'drop-sets': {
        ('build_muscle', 'isolation'): 7,
        ('fat_loss', 'isolation'): 9,
        ('fat_loss', 'accessory'): 7,
        ('recomp', 'isolation'): 6,
    },
    'supersets': {
        ('build_muscle', 'accessory'): 6,
        ('fat_loss', 'accessory'): 8,
        ('fat_loss', 'isolation'): 7,
        ('endurance', 'accessory'): 6,
    },
    'occlusion': {
        ('build_muscle', 'isolation'): 6,
        ('fat_loss', 'isolation'): 5,
    },
}


# ---------------------------------------------------------------------------
# Guardrail evaluation
# ---------------------------------------------------------------------------

def _resolve_field_value(
    condition_field: str,
    exercise: Exercise,
    slot_role: str,
    reps_min: int,
    reps_max: int,
) -> Any:
    """Resolve a condition_field to its actual value from exercise/slot context."""
    if condition_field == 'exercise.athletic_skill_tags':
        return exercise.athletic_skill_tags or []
    elif condition_field == 'exercise.athletic_attribute_tags':
        return exercise.athletic_attribute_tags or []
    elif condition_field == 'exercise.pattern_tags':
        return exercise.pattern_tags or []
    elif condition_field == 'exercise.primary_muscle_group':
        return exercise.primary_muscle_group or ''
    elif condition_field == 'exercise.category':
        return (exercise.category or '').lower()
    elif condition_field == 'slot.slot_role':
        return slot_role
    elif condition_field == 'slot.reps_max':
        return reps_max
    elif condition_field == 'slot.reps_min':
        return reps_min
    else:
        logger.warning("Unknown guardrail condition_field: %s", condition_field)
        return None


def _evaluate_condition(
    actual_value: Any,
    operator: str,
    condition_value: Any,
) -> bool:
    """Evaluate a guardrail condition. Returns True if condition IS met."""
    if actual_value is None:
        return False

    if operator == ModalityGuardrail.ConditionOperator.HAS_ANY:
        # actual_value is a list, condition_value is a list — check overlap
        if isinstance(actual_value, list) and isinstance(condition_value, list):
            return bool(set(actual_value) & set(condition_value))
        return False

    elif operator == ModalityGuardrail.ConditionOperator.HAS_NONE:
        # actual_value is a list, condition_value is a list — check NO overlap
        if isinstance(actual_value, list) and isinstance(condition_value, list):
            return not bool(set(actual_value) & set(condition_value))
        return True

    elif operator == ModalityGuardrail.ConditionOperator.GT:
        return actual_value > condition_value

    elif operator == ModalityGuardrail.ConditionOperator.LT:
        return actual_value < condition_value

    elif operator == ModalityGuardrail.ConditionOperator.EQ:
        return actual_value == condition_value

    elif operator == ModalityGuardrail.ConditionOperator.IN:
        if isinstance(condition_value, list):
            return actual_value in condition_value
        return False

    logger.warning("Unknown guardrail operator: %s", operator)
    return False


def validate_modality_for_slot(
    modality: SetStructureModality,
    exercise: Exercise,
    slot_role: str,
    reps_min: int,
    reps_max: int,
) -> list[GuardrailViolation]:
    """
    Check all active guardrails for a modality against an exercise/slot context.
    Returns list of violations (empty = modality is valid).
    """
    violations: list[GuardrailViolation] = []
    # Use .all() to leverage prefetch_related, then filter in Python
    # This avoids re-hitting the DB when guardrails are already prefetched
    all_guardrails = modality.guardrails.all()
    active_guardrails = [g for g in all_guardrails if g.is_active]

    for guardrail in active_guardrails:
        actual_value = _resolve_field_value(
            condition_field=guardrail.condition_field,
            exercise=exercise,
            slot_role=slot_role,
            reps_min=reps_min,
            reps_max=reps_max,
        )

        condition_met = _evaluate_condition(
            actual_value=actual_value,
            operator=guardrail.condition_operator,
            condition_value=guardrail.condition_value,
        )

        # For 'avoid' rules: if condition is met, it's a violation
        # For 'require' rules: if condition is NOT met, it's a violation
        is_violation = (
            (guardrail.rule_type == ModalityGuardrail.RuleType.AVOID and condition_met)
            or (guardrail.rule_type == ModalityGuardrail.RuleType.REQUIRE and not condition_met)
        )

        if is_violation:
            violations.append(GuardrailViolation(
                guardrail_id=str(guardrail.pk),
                rule_type=guardrail.rule_type,
                condition_field=guardrail.condition_field,
                condition_operator=guardrail.condition_operator,
                condition_value=guardrail.condition_value,
                error_message=guardrail.error_message,
            ))

    return violations


# ---------------------------------------------------------------------------
# Modality recommendations
# ---------------------------------------------------------------------------

def get_modality_recommendations(
    slot_role: str,
    goal: str,
    exercise: Exercise,
    reps_min: int,
    reps_max: int,
) -> list[ModalityRecommendation]:
    """
    Return ranked list of modalities for a slot, with guardrail violations.
    Sorted by: valid first, then by score descending.
    """
    from django.db.models import Prefetch
    modalities = list(
        SetStructureModality.objects.prefetch_related(
            Prefetch(
                'guardrails',
                queryset=ModalityGuardrail.objects.filter(is_active=True),
            ),
        ).all()
    )

    recommendations: list[ModalityRecommendation] = []
    key = (goal, slot_role)

    for modality in modalities:
        score_table = _MODALITY_SCORES.get(modality.slug, {})
        score = score_table.get(key, 1)  # Default score 1 for unlisted combos

        violations = validate_modality_for_slot(
            modality=modality,
            exercise=exercise,
            slot_role=slot_role,
            reps_min=reps_min,
            reps_max=reps_max,
        )

        recommendations.append(ModalityRecommendation(
            modality_id=str(modality.pk),
            modality_name=modality.name,
            modality_slug=modality.slug,
            volume_multiplier=str(modality.volume_multiplier),
            score=score,
            violations=violations,
            is_valid=len(violations) == 0,
        ))

    # Sort: valid first, then by score descending
    recommendations.sort(key=lambda r: (-int(r.is_valid), -r.score))
    return recommendations


# ---------------------------------------------------------------------------
# Volume computation
# ---------------------------------------------------------------------------

def compute_volume_contribution(sets: int, volume_multiplier: Decimal) -> Decimal:
    """Compute volume contribution: sets × volume_multiplier."""
    return Decimal(str(sets)) * volume_multiplier


def get_session_volume_summary(
    session: PlanSession,
) -> SessionVolumeSummary:
    """
    Compute per-muscle volume summary for a session, accounting for
    modality multipliers. Slots without a modality default to 1.0x.
    """
    slots = list(
        PlanSlot.objects.filter(session_id=session.pk)
        .select_related('exercise', 'set_structure_modality')
        .order_by('order')
    )

    muscle_data: dict[str, dict[str, Any]] = {}
    total_raw_sets = 0
    total_adjusted = Decimal('0.00')

    for slot in slots:
        multiplier = (
            slot.set_structure_modality.volume_multiplier
            if slot.set_structure_modality
            else Decimal('1.00')
        )
        muscle = slot.exercise.primary_muscle_group or slot.exercise.muscle_group or 'unknown'
        adjusted = compute_volume_contribution(slot.sets, multiplier)
        total_raw_sets += slot.sets
        total_adjusted += adjusted

        if muscle not in muscle_data:
            muscle_data[muscle] = {'raw_sets': 0, 'adjusted': Decimal('0.00'), 'count': 0}

        muscle_data[muscle]['raw_sets'] += slot.sets
        muscle_data[muscle]['adjusted'] += adjusted
        muscle_data[muscle]['count'] += 1

    by_muscle = [
        MuscleVolumeEntry(
            muscle_group=mg,
            raw_sets=data['raw_sets'],
            adjusted_volume=str(data['adjusted']),
            slot_count=data['count'],
        )
        for mg, data in sorted(muscle_data.items())
    ]

    return SessionVolumeSummary(
        session_id=str(session.pk),
        session_label=session.label,
        total_raw_sets=total_raw_sets,
        total_adjusted_volume=str(total_adjusted),
        by_muscle=by_muscle,
    )


# ---------------------------------------------------------------------------
# Apply modality to slot
# ---------------------------------------------------------------------------

def apply_modality_to_slot(
    *,
    slot: PlanSlot,
    modality: SetStructureModality,
    actor_id: int | None = None,
    override_guardrails: bool = False,
    modality_details: dict[str, Any] | None = None,
    reason: str = '',
) -> ApplyModalityResult:
    """
    Apply a modality to a PlanSlot. Validates guardrails unless override=True.
    Creates DecisionLog + UndoSnapshot.

    Raises ValueError if guardrails are violated and override is False.
    """
    exercise = slot.exercise
    # Count total active guardrails for audit trail
    total_guardrails = len([g for g in modality.guardrails.all() if g.is_active])
    violations = validate_modality_for_slot(
        modality=modality,
        exercise=exercise,
        slot_role=slot.slot_role,
        reps_min=slot.reps_min,
        reps_max=slot.reps_max,
    )

    if violations and not override_guardrails:
        messages = [v.error_message for v in violations]
        raise ValueError(
            f"Modality '{modality.name}' cannot be applied to this slot. "
            f"Guardrail violations: {'; '.join(messages)}. "
            "Set override_guardrails=True to override."
        )

    with transaction.atomic():
        # Create undo snapshot before changing
        before_state = {
            'set_structure_modality_id': str(slot.set_structure_modality_id) if slot.set_structure_modality_id else None,
            'modality_details': slot.modality_details,
            'modality_volume_contribution': str(slot.modality_volume_contribution),
        }

        # Compute new volume contribution
        volume_contribution = compute_volume_contribution(slot.sets, modality.volume_multiplier)

        # Apply changes
        slot.set_structure_modality = modality
        slot.modality_details = modality_details or {}
        slot.modality_volume_contribution = volume_contribution
        slot.save(update_fields=[
            'set_structure_modality',
            'modality_details',
            'modality_volume_contribution',
            'updated_at',
        ])

        after_state = {
            'set_structure_modality_id': str(modality.pk),
            'modality_details': slot.modality_details,
            'modality_volume_contribution': str(volume_contribution),
        }

        # Create UndoSnapshot
        UndoSnapshot.objects.create(
            scope='plan_slot_modality',
            entity_type='PlanSlot',
            entity_id=str(slot.pk),
            before_state=before_state,
            after_state=after_state,
        )

        guardrails_overridden = [v.guardrail_id for v in violations] if override_guardrails else []

        # Create DecisionLog
        log = DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.USER if actor_id else DecisionLog.ActorType.SYSTEM
            ),
            actor_id=actor_id,
            decision_type='modality_assignment',
            context={
                'slot_id': str(slot.pk),
                'exercise_id': slot.exercise_id,
                'exercise_name': exercise.name,
            },
            inputs_snapshot={
                'modality_id': str(modality.pk),
                'modality_name': modality.name,
                'modality_details': modality_details or {},
                'override_guardrails': override_guardrails,
                'reason': reason,
            },
            constraints_applied={
                'guardrails_checked': total_guardrails,
                'guardrails_violated': len(violations),
                'guardrails_overridden': guardrails_overridden,
            },
            options_considered=[],
            final_choice={
                'modality_id': str(modality.pk),
                'modality_name': modality.name,
                'volume_multiplier': str(modality.volume_multiplier),
                'volume_contribution': str(volume_contribution),
            },
            reason_codes=['modality_applied', *(
                ['guardrail_override'] if guardrails_overridden else []
            )],
        )

    return ApplyModalityResult(
        slot_id=str(slot.pk),
        modality_id=str(modality.pk),
        modality_name=modality.name,
        volume_contribution=str(volume_contribution),
        decision_log_id=str(log.pk),
        guardrails_overridden=guardrails_overridden,
    )


# ---------------------------------------------------------------------------
# Default modality assignment (used by A5 enhancement)
# ---------------------------------------------------------------------------

def get_default_modality_slug(goal: str, slot_role: str, is_deload: bool) -> str:
    """Return the default modality slug for a goal/slot_role combination."""
    if is_deload:
        return _DELOAD_MODALITY_SLUG
    return _DEFAULT_MODALITY.get((goal, slot_role), 'straight-sets')


def prefetch_system_modalities() -> dict[str, SetStructureModality]:
    """
    Load all system modalities into a dict keyed by slug.
    Called once at pipeline start to avoid per-slot queries.
    """
    modalities = SetStructureModality.objects.filter(is_system=True)
    return {m.slug: m for m in modalities}


def assign_default_modality_to_specs(
    all_specs: list[SlotSpec],
    goal: str,
    deload_week_numbers: set[int],
    modality_by_slug: dict[str, SetStructureModality],
) -> None:
    """
    Assign default modality to each SlotSpec based on goal and slot_role.
    Mutates specs in place (adds modality and volume_contribution).
    """
    straight_sets = modality_by_slug.get('straight-sets')

    for spec in all_specs:
        # session.week is always set by A3 — no defensive checks needed
        is_deload = spec.session.week.week_number in deload_week_numbers

        slug = get_default_modality_slug(goal, spec.slot_role, is_deload)
        modality = modality_by_slug.get(slug, straight_sets)

        if modality is not None:
            spec.set_structure_modality = modality
            spec.modality_volume_contribution = compute_volume_contribution(
                spec.sets, modality.volume_multiplier,
            )
        else:
            spec.set_structure_modality = None
            spec.modality_volume_contribution = Decimal(str(spec.sets))
