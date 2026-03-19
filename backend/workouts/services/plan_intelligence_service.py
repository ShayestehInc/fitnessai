"""
Plan Intelligence Service — v6.5 UI/UX spec alignment.

Provides the decision logic for:
- Program phase assignment per week
- Day role + session family + day stress classification
- Pairing logic (supersets, contrast pairs, etc.)
- Session timing estimation + auto-trim
- Exercise tag filtering (stance, plane, ROM bias)
- Expanded swap buckets (pain-safe, equipment-limited)
- Tempo preset assignment
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from workouts.models import (
    Exercise,
    PlanSession,
    PlanSlot,
    PlanWeek,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# 1. Program Phase Assignment
# ---------------------------------------------------------------------------

# Phase plans by goal and duration
_PHASE_PLANS: dict[str, dict[int, list[str]]] = {
    # build_muscle: accumulation-heavy with periodic deloads
    'build_muscle': {
        4: ['accumulation', 'accumulation', 'intensification', 'deload'],
        6: ['accumulation', 'accumulation', 'accumulation', 'deload', 'intensification', 'deload'],
        8: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'accumulation', 'intensification', 'intensification', 'deload'],
        12: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'accumulation', 'accumulation', 'deload', 'intensification', 'intensification', 'deload', 'realization', 'deload'],
    },
    'strength': {
        4: ['accumulation', 'intensification', 'realization', 'deload'],
        6: ['accumulation', 'accumulation', 'intensification', 'deload', 'realization', 'deload'],
        8: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'intensification', 'intensification', 'realization', 'deload'],
        12: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'intensification', 'intensification', 'deload', 'realization', 'realization', 'deload', 'realization', 'deload'],
    },
    'fat_loss': {
        4: ['accumulation', 'accumulation', 'intensification', 'deload'],
        6: ['accumulation', 'accumulation', 'accumulation', 'deload', 'intensification', 'deload'],
        8: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'accumulation', 'intensification', 'intensification', 'deload'],
    },
    'endurance': {
        4: ['accumulation', 'accumulation', 'intensification', 'deload'],
        6: ['on_ramp', 'accumulation', 'accumulation', 'intensification', 'intensification', 'deload'],
    },
    'recomp': {
        6: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'intensification', 'deload'],
        8: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'accumulation', 'intensification', 'intensification', 'deload'],
    },
    'general_fitness': {
        4: ['accumulation', 'accumulation', 'intensification', 'deload'],
        6: ['on_ramp', 'accumulation', 'accumulation', 'deload', 'intensification', 'deload'],
    },
}

# Phase → intensity/volume modifier defaults
_PHASE_MODIFIERS: dict[str, tuple[Decimal, Decimal]] = {
    'on_ramp': (Decimal('0.70'), Decimal('0.60')),
    'accumulation': (Decimal('0.80'), Decimal('1.00')),
    'intensification': (Decimal('0.90'), Decimal('0.85')),
    'realization': (Decimal('1.00'), Decimal('0.70')),
    'deload': (Decimal('0.60'), Decimal('0.50')),
    'bridge': (Decimal('0.75'), Decimal('0.80')),
}


def assign_phases(
    weeks: list[PlanWeek],
    goal: str,
    training_age_years: int | None = None,
) -> None:
    """Assign training phases to each week based on goal and duration."""
    duration = len(weeks)
    goal_plans = _PHASE_PLANS.get(goal, _PHASE_PLANS.get('general_fitness', {}))

    # Find the closest plan for this duration
    plan: list[str] | None = goal_plans.get(duration)
    if plan is None:
        # Find nearest shorter plan and extend, or nearest longer and truncate
        available = sorted(goal_plans.keys())
        if not available:
            # Fallback: accumulation with deload every 4th
            plan = []
            for i in range(1, duration + 1):
                if i % 4 == 0:
                    plan.append('deload')
                else:
                    plan.append('accumulation')
        else:
            closest = min(available, key=lambda x: abs(x - duration))
            base = goal_plans[closest]
            if duration <= len(base):
                plan = base[:duration]
            else:
                # Extend by repeating the accumulation/deload pattern
                plan = list(base)
                while len(plan) < duration:
                    cycle_pos = (len(plan) - len(base)) % 4
                    if cycle_pos == 3:
                        plan.append('deload')
                    else:
                        plan.append('accumulation')

    # New/detrained users start with on-ramp
    if training_age_years is not None and training_age_years < 1 and plan and plan[0] != 'on_ramp':
        plan[0] = 'on_ramp'

    for week, phase_name in zip(weeks, plan):
        week.phase = phase_name
        week.is_deload = (phase_name == 'deload')
        intensity, volume = _PHASE_MODIFIERS.get(phase_name, (Decimal('1.00'), Decimal('1.00')))
        week.intensity_modifier = intensity
        week.volume_modifier = volume


# ---------------------------------------------------------------------------
# 2. Day Role + Session Family + Day Stress Classification
# ---------------------------------------------------------------------------

# Maps muscle group patterns to day roles and session families
_SESSION_DEF_TO_ROLE: dict[str, tuple[str, str, str]] = {
    # (day_role, session_family, day_stress)
    'chest_shoulders_triceps': ('push', 'hypertrophy', 'medium_mixed'),
    'back_biceps': ('pull', 'hypertrophy', 'medium_mixed'),
    'quadriceps_hamstrings_glutes': ('legs', 'strength', 'high_neural'),
    'chest_back_shoulders': ('upper_strength', 'strength', 'high_neural'),
    'quadriceps_hamstrings_glutes_calves': ('lower_strength', 'strength', 'high_neural'),
    'chest_back': ('upper_hypertrophy', 'hypertrophy', 'medium_mixed'),
    'shoulders_arms': ('arms_shoulders', 'hypertrophy', 'low_neural'),
}

# Goal → default session family
_GOAL_SESSION_FAMILY: dict[str, str] = {
    'build_muscle': 'hypertrophy',
    'strength': 'strength',
    'fat_loss': 'conditioning',
    'endurance': 'conditioning',
    'recomp': 'mixed_hybrid',
    'general_fitness': 'mixed_hybrid',
}

# Session family → day stress mapping
_FAMILY_STRESS: dict[str, str] = {
    'strength': 'high_neural',
    'hypertrophy': 'medium_mixed',
    'power_athletic': 'high_neural',
    'conditioning': 'aerobic',
    'technique': 'low_neural',
    'rehab_tolerance': 'low_neural',
    'mixed_hybrid': 'medium_mixed',
}


def classify_sessions(
    sessions: list[PlanSession],
    session_defs: list[dict[str, Any]],
    goal: str,
    phase: str = 'accumulation',
) -> None:
    """Classify each session with day_role, session_family, and day_stress."""
    default_family = _GOAL_SESSION_FAMILY.get(goal, 'mixed_hybrid')

    for session in sessions:
        sdef = session_defs[session.order % len(session_defs)]
        muscle_groups: list[str] = sdef.get('muscle_groups', [])
        mg_key = '_'.join(sorted(muscle_groups))

        role_info = _SESSION_DEF_TO_ROLE.get(mg_key)
        if role_info:
            session.day_role, session.session_family, session.day_stress = role_info
        else:
            # Infer from muscle count and goal
            if len(muscle_groups) <= 2:
                session.day_role = sdef.get('label', 'training').lower().replace(' ', '_')
                session.session_family = default_family
            elif len(muscle_groups) >= 4:
                session.day_role = 'full_body'
                session.session_family = default_family
            else:
                session.day_role = sdef.get('label', 'training').lower().replace(' ', '_')
                session.session_family = default_family

            session.day_stress = _FAMILY_STRESS.get(session.session_family, 'medium_mixed')

        # Phase adjustments
        if phase == 'deload':
            session.day_stress = 'low_neural'
        elif phase == 'on_ramp':
            session.day_stress = 'low_neural' if session.day_stress == 'high_neural' else session.day_stress
        elif phase in ('realization',):
            if session.session_family in ('strength', 'power_athletic'):
                session.day_stress = 'high_neural'


# ---------------------------------------------------------------------------
# 3. Pairing Logic
# ---------------------------------------------------------------------------

@dataclass
class PairingDecision:
    """Result of deciding how to pair slots in a session."""
    slot_order: int
    pairing_group: int | None
    pairing_type: str


# Antagonist muscle pairs for superset detection
_ANTAGONIST_PAIRS: set[frozenset[str]] = {
    frozenset({'chest', 'back'}),
    frozenset({'biceps', 'triceps'}),
    frozenset({'quadriceps', 'hamstrings'}),
    frozenset({'shoulders', 'back'}),
    frozenset({'chest', 'rear_delts'}),
}


def assign_pairings(
    specs: list[Any],  # list of SlotSpec
    session_family: str,
    goal: str,
    session_length_minutes: int = 60,
) -> list[PairingDecision]:
    """Decide how slots should be paired within a session.

    Rules from the UI/UX spec:
    - Main lifts, max effort, sprints, jumps: stand alone (straight sequencing)
    - If slot can be paired: check antagonist, non-competing, agonist, or contrast
    - Don't pair if it turns the session into chaos
    - Higher-fatigue pump work can use denser structures
    """
    decisions: list[PairingDecision] = []
    group_counter = 1
    used: set[int] = set()

    for i, spec in enumerate(specs):
        if i in used:
            continue

        # Primary compounds and technique/power slots stand alone
        if spec.slot_role in ('primary_compound', 'main_strength', 'technique', 'prep', 'cooldown', 'conditioning'):
            decisions.append(PairingDecision(
                slot_order=spec.order,
                pairing_group=None,
                pairing_type='straight',
            ))
            continue

        # Look for a pairing partner among remaining slots
        partner_idx = _find_pairing_partner(specs, i, used)
        if partner_idx is not None:
            partner = specs[partner_idx]
            pairing_type = _determine_pairing_type(spec, partner)

            decisions.append(PairingDecision(
                slot_order=spec.order,
                pairing_group=group_counter,
                pairing_type=pairing_type,
            ))
            decisions.append(PairingDecision(
                slot_order=partner.order,
                pairing_group=group_counter,
                pairing_type=pairing_type,
            ))
            used.add(i)
            used.add(partner_idx)
            group_counter += 1
        else:
            decisions.append(PairingDecision(
                slot_order=spec.order,
                pairing_group=None,
                pairing_type='straight',
            ))

    return decisions


def _find_pairing_partner(
    specs: list[Any],
    current_idx: int,
    used: set[int],
) -> int | None:
    """Find the best pairing partner for a slot."""
    current = specs[current_idx]
    if not current.exercise:
        return None

    current_mg = current.exercise.primary_muscle_group or ''

    for j in range(current_idx + 1, len(specs)):
        if j in used:
            continue
        candidate = specs[j]
        if not candidate.exercise:
            continue
        # Don't pair with primary compounds
        if candidate.slot_role in ('primary_compound', 'main_strength', 'technique', 'prep', 'cooldown'):
            continue

        candidate_mg = candidate.exercise.primary_muscle_group or ''

        # Check for antagonist pairing
        if frozenset({current_mg, candidate_mg}) in _ANTAGONIST_PAIRS:
            return j

        # Check for non-competing (different muscle groups)
        if current_mg and candidate_mg and current_mg != candidate_mg:
            return j

    return None


def _determine_pairing_type(spec_a: Any, spec_b: Any) -> str:
    """Determine the pairing type between two specs."""
    mg_a = spec_a.exercise.primary_muscle_group or '' if spec_a.exercise else ''
    mg_b = spec_b.exercise.primary_muscle_group or '' if spec_b.exercise else ''

    if frozenset({mg_a, mg_b}) in _ANTAGONIST_PAIRS:
        return 'superset_antagonist'

    if mg_a == mg_b:
        return 'superset_agonist'

    return 'superset_non_competing'


# ---------------------------------------------------------------------------
# 4. Session Timing Estimation
# ---------------------------------------------------------------------------

# Time estimates in seconds per component
_WARM_UP_SECONDS = 300  # 5 min default warm-up
_TRANSITION_SECONDS_PER_EXERCISE = 30  # Setup time between exercises
_LOG_SECONDS_PER_SET = 10  # Time to log a set
_COOLDOWN_SECONDS = 120  # 2 min cooldown

# Work time per rep by slot role (seconds)
_SECONDS_PER_REP: dict[str, float] = {
    'primary_compound': 4.0,
    'secondary_compound': 3.5,
    'main_strength': 4.0,
    'hypertrophy_compound': 3.0,
    'accessory': 3.0,
    'isolation': 2.5,
    'hypertrophy_isolation': 2.5,
    'technique': 3.0,
    'prep': 2.0,
    'trunk': 2.5,
    'carry': 5.0,
    'conditioning': 2.0,
    'cooldown': 2.0,
    'unilateral_support': 3.0,
}


def estimate_session_duration(
    specs: list[Any],  # list of SlotSpec
    pairings: list[PairingDecision] | None = None,
) -> int:
    """Estimate total session duration in minutes.

    Components: warm-up + (work_time + rest_time + transition_time + log_time) per slot + cooldown.
    Paired slots share rest time.
    """
    total_seconds = _WARM_UP_SECONDS

    pairing_groups: dict[int, list[int]] = {}
    if pairings:
        for p in pairings:
            if p.pairing_group is not None:
                pairing_groups.setdefault(p.pairing_group, []).append(p.slot_order)

    paired_orders: set[int] = set()
    for orders in pairing_groups.values():
        paired_orders.update(orders)

    for spec in specs:
        sec_per_rep = _SECONDS_PER_REP.get(spec.slot_role, 3.0)
        avg_reps = (spec.reps_min + spec.reps_max) / 2
        work_per_set = sec_per_rep * avg_reps
        work_time = work_per_set * spec.sets

        # Rest time: paired slots share rest (only count once per pair)
        if spec.order in paired_orders:
            rest_time = spec.rest_seconds * spec.sets * 0.5  # Shared rest
        else:
            rest_time = spec.rest_seconds * (spec.sets - 1)  # No rest after last set

        transition_time = _TRANSITION_SECONDS_PER_EXERCISE
        log_time = _LOG_SECONDS_PER_SET * spec.sets

        total_seconds += work_time + rest_time + transition_time + log_time

    total_seconds += _COOLDOWN_SECONDS
    return max(1, round(total_seconds / 60))


def auto_trim_session(
    specs: list[Any],  # list of SlotSpec (mutable)
    target_minutes: int,
    pairings: list[PairingDecision] | None = None,
) -> list[int]:
    """Remove optional/low-priority slots if session exceeds time target.

    Returns list of removed slot orders.
    Trim order: optional finishers first, then low-priority support, then isolation.
    Never trim primary compounds.
    """
    removed: list[int] = []
    current_duration = estimate_session_duration(specs, pairings)

    if current_duration <= target_minutes:
        return removed

    # Priority for trimming (first to cut → last to cut)
    trim_priority = [
        'cooldown', 'conditioning', 'carry', 'trunk',
        'unilateral_support', 'isolation', 'hypertrophy_isolation',
        'accessory',
    ]

    # First pass: remove optional slots
    for role in trim_priority:
        if current_duration <= target_minutes:
            break
        for spec in reversed(list(specs)):
            if spec.is_optional and spec.slot_role == role:
                removed.append(spec.order)
                specs.remove(spec)
                current_duration = estimate_session_duration(specs, pairings)
                if current_duration <= target_minutes:
                    break

    # Second pass: remove non-optional low-priority if still over
    if current_duration > target_minutes:
        for role in trim_priority:
            if current_duration <= target_minutes:
                break
            for spec in reversed(list(specs)):
                if spec.slot_role == role and spec.order not in removed:
                    removed.append(spec.order)
                    specs.remove(spec)
                    current_duration = estimate_session_duration(specs, pairings)
                    if current_duration <= target_minutes:
                        break

    return removed


# ---------------------------------------------------------------------------
# 5. Exercise Tag Filtering
# ---------------------------------------------------------------------------

def filter_exercises_by_tags(
    pool: list[Exercise],
    slot_role: str,
    pain_tolerances: dict[str, Any] | None = None,
    equipment: list[str] | None = None,
    hated_lifts: list[str] | None = None,
    preferred_stance: str | None = None,
    preferred_plane: str | None = None,
    preferred_rom_bias: str | None = None,
) -> list[Exercise]:
    """Filter exercise pool using v6.5 tag fields.

    Applies filters in priority order:
    1. Equipment availability
    2. Pain tolerance restrictions
    3. Hated lifts exclusion
    4. Stance/plane/ROM bias preferences (soft filter — prefer but don't exclude)
    """
    filtered = list(pool)

    # Hard filter: equipment
    if equipment:
        eq_set = set(e.lower() for e in equipment)
        eq_set.add('bodyweight')  # Always available
        eq_set.add('')  # Allow exercises with no equipment specified
        filtered = [
            ex for ex in filtered
            if not ex.equipment_required
            or any(e.lower() in eq_set for e in (ex.equipment_required if isinstance(ex.equipment_required, list) else [ex.equipment_required]))
        ]

    # Hard filter: pain tolerances
    if pain_tolerances:
        overhead = pain_tolerances.get('overhead', 'ok')
        axial = pain_tolerances.get('axial_loading', 'ok')

        if overhead == 'avoid':
            filtered = [ex for ex in filtered if 'overhead' not in (ex.name or '').lower()]
        if axial == 'avoid':
            filtered = [
                ex for ex in filtered
                if not any(kw in (ex.name or '').lower() for kw in ('squat', 'deadlift', 'press'))
                or 'leg press' in (ex.name or '').lower()
            ]

    # Hard filter: hated lifts
    if hated_lifts:
        hated_lower = {h.lower() for h in hated_lifts}
        filtered = [
            ex for ex in filtered
            if ex.name.lower() not in hated_lower
        ]

    # Soft filter: sort by tag preference match (best matches first)
    if preferred_stance or preferred_plane or preferred_rom_bias:
        def _tag_score(ex: Exercise) -> int:
            score = 0
            if preferred_stance and hasattr(ex, 'stance') and ex.stance == preferred_stance:
                score += 1
            if preferred_plane and hasattr(ex, 'plane') and ex.plane == preferred_plane:
                score += 1
            if preferred_rom_bias and hasattr(ex, 'rom_bias') and ex.rom_bias == preferred_rom_bias:
                score += 1
            return score

        filtered.sort(key=_tag_score, reverse=True)

    return filtered


# ---------------------------------------------------------------------------
# 6. Expanded Swap Buckets
# ---------------------------------------------------------------------------

def build_expanded_swap_cache(
    exercise: Exercise,
    all_exercises: list[Exercise],
    plan_exercise_ids: set[int],
    pain_tolerances: dict[str, Any] | None = None,
    equipment: list[str] | None = None,
    max_per_tab: int = 10,
) -> dict[str, list[int]]:
    """Build swap options with expanded buckets per UI/UX spec.

    Buckets: same_muscle, same_pattern, explore, pain_safe, equipment_limited.
    """
    by_muscle: dict[str, list[int]] = {}
    by_pattern: dict[str, list[int]] = {}

    for ex in all_exercises:
        if ex.id == exercise.id:
            continue
        if ex.primary_muscle_group:
            by_muscle.setdefault(ex.primary_muscle_group, []).append(ex.id)
        for tag in (ex.pattern_tags or []):
            by_pattern.setdefault(tag, []).append(ex.id)

    # Same muscle
    same_muscle = [
        eid for eid in by_muscle.get(exercise.primary_muscle_group or '', [])
        if eid not in plan_exercise_ids
    ][:max_per_tab]

    # Same pattern
    same_pattern_ids: list[int] = []
    seen: set[int] = set()
    for tag in (exercise.pattern_tags or []):
        for eid in by_pattern.get(tag, []):
            if eid not in plan_exercise_ids and eid not in seen:
                same_pattern_ids.append(eid)
                seen.add(eid)
    same_pattern = same_pattern_ids[:max_per_tab]

    # Explore all
    explore = [
        ex.id for ex in all_exercises
        if ex.id != exercise.id and ex.id not in plan_exercise_ids
    ][:max_per_tab]

    # Pain-safe regression: filter by pain tolerances
    pain_safe: list[int] = []
    if pain_tolerances:
        safe_pool = filter_exercises_by_tags(
            [ex for ex in all_exercises if ex.id != exercise.id and ex.primary_muscle_group == exercise.primary_muscle_group],
            slot_role='',
            pain_tolerances=pain_tolerances,
        )
        pain_safe = [ex.id for ex in safe_pool if ex.id not in plan_exercise_ids][:max_per_tab]

    # Equipment-limited fallback: filter by available equipment
    equipment_limited: list[int] = []
    if equipment:
        eq_pool = filter_exercises_by_tags(
            [ex for ex in all_exercises if ex.id != exercise.id and ex.primary_muscle_group == exercise.primary_muscle_group],
            slot_role='',
            equipment=equipment,
        )
        equipment_limited = [ex.id for ex in eq_pool if ex.id not in plan_exercise_ids][:max_per_tab]

    return {
        'same_muscle': same_muscle,
        'same_pattern': same_pattern,
        'explore': explore,
        'pain_safe': pain_safe,
        'equipment_limited': equipment_limited,
    }


# ---------------------------------------------------------------------------
# 7. Tempo Preset Assignment
# ---------------------------------------------------------------------------

# Slot role → default tempo preset
_ROLE_TEMPO_MAP: dict[str, str] = {
    'primary_compound': 'general_strength',
    'main_strength': 'general_strength',
    'secondary_compound': 'general_strength',
    'hypertrophy_compound': 'lengthened_hypertrophy',
    'accessory': 'lengthened_hypertrophy',
    'isolation': 'lengthened_hypertrophy',
    'hypertrophy_isolation': 'lengthened_hypertrophy',
    'technique': 'technique_preset',
    'prep': 'joint_friendly',
    'trunk': 'general_strength',
    'carry': 'general_strength',
    'unilateral_support': 'joint_friendly',
    'conditioning': 'power_speed',
    'cooldown': 'joint_friendly',
}

# Goal adjustments
_GOAL_TEMPO_OVERRIDE: dict[str, dict[str, str]] = {
    'strength': {
        'primary_compound': 'pause_strength',
        'main_strength': 'pause_strength',
    },
    'fat_loss': {
        'accessory': 'general_strength',
        'isolation': 'general_strength',
    },
}


def assign_tempo_presets(
    specs: list[Any],  # list of SlotSpec or similar
    goal: str,
) -> None:
    """Assign tempo presets to each slot based on role and goal."""
    goal_overrides = _GOAL_TEMPO_OVERRIDE.get(goal, {})

    for spec in specs:
        override = goal_overrides.get(spec.slot_role)
        if override:
            spec.tempo_preset = override
        else:
            spec.tempo_preset = _ROLE_TEMPO_MAP.get(spec.slot_role, 'general_strength')


# ---------------------------------------------------------------------------
# 8. Slot Role Assignment (expanded from simple position-based)
# ---------------------------------------------------------------------------

def assign_slot_roles_intelligent(
    specs: list[Any],  # list of SlotSpec
    session_family: str,
    goal: str,
    session_length_minutes: int = 60,
) -> None:
    """Assign slot roles based on session family and goal, not just position.

    Rules from UI/UX spec:
    - Strength sessions: protect the main lift slot from early fatigue
    - Hypertrophy sessions: main compound → secondary → accessories → isolation
    - Conditioning sessions: different slot mix entirely
    - Power sessions: technique/power → main strength → support
    """
    slot_count = len(specs)
    if slot_count == 0:
        return

    if session_family == 'strength':
        _assign_strength_roles(specs)
    elif session_family == 'hypertrophy':
        _assign_hypertrophy_roles(specs)
    elif session_family == 'power_athletic':
        _assign_power_roles(specs)
    elif session_family == 'conditioning':
        _assign_conditioning_roles(specs)
    else:
        _assign_mixed_roles(specs, goal)

    # Mark last slot(s) as optional if session is short
    if session_length_minutes <= 45 and slot_count >= 5:
        specs[-1].is_optional = True
    if session_length_minutes <= 30 and slot_count >= 4:
        specs[-1].is_optional = True
        if slot_count >= 5:
            specs[-2].is_optional = True


def _assign_strength_roles(specs: list[Any]) -> None:
    """Strength session: main lift → secondary → accessories → support."""
    for i, spec in enumerate(specs):
        if i == 0:
            spec.slot_role = 'main_strength'
        elif i == 1:
            spec.slot_role = 'secondary_compound'
        elif i <= 3:
            spec.slot_role = 'accessory'
        elif i == len(specs) - 1:
            spec.slot_role = 'trunk'
            spec.is_optional = True
        else:
            spec.slot_role = 'unilateral_support'


def _assign_hypertrophy_roles(specs: list[Any]) -> None:
    """Hypertrophy session: compound → secondary → accessories → isolation."""
    for i, spec in enumerate(specs):
        if i == 0:
            spec.slot_role = 'hypertrophy_compound'
        elif i == 1:
            spec.slot_role = 'secondary_compound'
        elif i <= 3:
            spec.slot_role = 'accessory'
        else:
            spec.slot_role = 'hypertrophy_isolation'
            if i >= len(specs) - 2:
                spec.is_optional = True


def _assign_power_roles(specs: list[Any]) -> None:
    """Power/athletic session: technique → main strength → support."""
    for i, spec in enumerate(specs):
        if i == 0:
            spec.slot_role = 'technique'
        elif i == 1:
            spec.slot_role = 'main_strength'
        elif i == 2:
            spec.slot_role = 'secondary_compound'
        elif i <= 4:
            spec.slot_role = 'accessory'
        else:
            spec.slot_role = 'trunk'
            spec.is_optional = True


def _assign_conditioning_roles(specs: list[Any]) -> None:
    """Conditioning session: prep → conditioning blocks → cooldown."""
    for i, spec in enumerate(specs):
        if i == 0:
            spec.slot_role = 'prep'
        elif i == len(specs) - 1:
            spec.slot_role = 'cooldown'
            spec.is_optional = True
        else:
            spec.slot_role = 'conditioning'


def _assign_mixed_roles(specs: list[Any], goal: str) -> None:
    """Fallback mixed assignment (similar to original position-based but with expanded roles)."""
    for i, spec in enumerate(specs):
        if i == 0:
            spec.slot_role = 'primary_compound'
        elif i == 1:
            spec.slot_role = 'secondary_compound'
        elif i <= 3:
            spec.slot_role = 'accessory'
        elif i == len(specs) - 1 and len(specs) >= 6:
            spec.slot_role = 'trunk'
            spec.is_optional = True
        else:
            spec.slot_role = 'isolation'
