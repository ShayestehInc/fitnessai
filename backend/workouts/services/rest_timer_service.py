"""
Rest Timer Service — v6.5 Step 8.

Computes prescribed rest durations for workout sets based on:
1. Trainer override (PlanSlot.rest_seconds if explicitly set)
2. Modality rules (e.g., myo-reps, drop sets have shorter rest)
3. Slot role defaults (primary_compound=180s, secondary_compound=120s, etc.)
4. Between-exercise bonus (+30s when transitioning between slots)
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from workouts.models import PlanSlot


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class RestPrescription:
    """Computed rest duration and its source."""
    rest_seconds: int
    source: str  # slot_role_default | modality_override | trainer_override
    is_between_exercises: bool


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_SLOT_ROLE_DEFAULTS: dict[str, int] = {
    'primary_compound': 180,
    'secondary_compound': 120,
    'isolation': 90,
    'accessory': 60,
}

# Modality slugs that override default rest times
_MODALITY_REST_OVERRIDES: dict[str, int] = {
    'myo_reps': 20,
    'drop_sets': 10,
    'giant_sets': 30,
    'supersets': 30,
    'cluster_sets': 30,
}

_DEFAULT_REST_SECONDS = 90
_BETWEEN_EXERCISE_BONUS = 30

# The default rest_seconds on PlanSlot — if it matches this value we treat it
# as "not explicitly set by the trainer" and fall through to role/modality defaults.
# KNOWN LIMITATION (M7): If a trainer intentionally sets rest to exactly 90s,
# it will be treated as "not explicitly set" and may be overridden by modality/role
# defaults. A proper fix would require a nullable rest_seconds_override field or a
# boolean flag on PlanSlot. For now, this edge case is accepted and documented.
_PLAN_SLOT_DEFAULT_REST = 90


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def get_rest_duration(
    plan_slot: PlanSlot,
    set_number: int,
    is_last_set_of_slot: bool = False,
) -> RestPrescription:
    """
    Compute rest duration for a given set within a slot.

    Priority:
    1. If PlanSlot.rest_seconds differs from the default (90), the trainer
       explicitly set it → use as trainer override.
    2. If the slot has a set_structure_modality with a known slug, use
       the modality-specific rest.
    3. Fall back to the slot role default.

    If ``is_last_set_of_slot`` is True, adds a 30-second bonus for
    transitioning to the next exercise.
    """
    rest_seconds: int
    source: str

    # 1. Trainer override — explicit rest_seconds on the slot
    if plan_slot.rest_seconds != _PLAN_SLOT_DEFAULT_REST:
        rest_seconds = plan_slot.rest_seconds
        source = 'trainer_override'
    # 2. Modality override
    elif (
        plan_slot.set_structure_modality_id is not None
        and plan_slot.set_structure_modality is not None
    ):
        slug = plan_slot.set_structure_modality.slug
        if slug in _MODALITY_REST_OVERRIDES:
            rest_seconds = _MODALITY_REST_OVERRIDES[slug]
            source = 'modality_override'
        else:
            rest_seconds = _SLOT_ROLE_DEFAULTS.get(
                plan_slot.slot_role, _DEFAULT_REST_SECONDS,
            )
            source = 'slot_role_default'
    # 3. Slot role default
    else:
        rest_seconds = _SLOT_ROLE_DEFAULTS.get(
            plan_slot.slot_role, _DEFAULT_REST_SECONDS,
        )
        source = 'slot_role_default'

    # Between-exercise bonus
    is_between = is_last_set_of_slot
    if is_between:
        rest_seconds += _BETWEEN_EXERCISE_BONUS

    return RestPrescription(
        rest_seconds=rest_seconds,
        source=source,
        is_between_exercises=is_between,
    )
