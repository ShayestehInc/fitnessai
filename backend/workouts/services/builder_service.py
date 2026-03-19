"""
Dual-Mode Program Builder Service.

Wraps the 7-step training generator pipeline to support two build modes:

1. **Quick Build** — Runs the full pipeline with an expanded brief.
   Returns the completed plan + per-step explanations.

2. **Advanced Builder** — Runs the pipeline step-by-step.
   Each step returns a recommendation, alternatives, and a "why" explanation.
   The user can accept or override at every layer.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

from django.db import transaction
from django.db.models import Q

from workouts.models import (
    DecisionLog,
    Exercise,
    PlanSession,
    PlanSlot,
    PlanWeek,
    SetStructureModality,
    SplitTemplate,
    TrainingPlan,
)
from workouts.services.training_generator_service import (
    GeneratePlanRequest,
    SlotSpec,
    _DEFAULT_DAY_INDICES,
    _DEFAULT_SCHEME,
    _GOAL_DURATION,
    _MAX_SWAP_PER_TAB,
    _SCHEME,
    _a3_build_skeleton,
    _a4_assign_slot_roles,
    _a5_set_structure,
    _a6_select_exercises,
    _a7_build_swap_recommendations,
    _log_decision,
    _prefetch_exercise_pool,
    _specs_to_plan_slots,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BUILDER_STEPS = [
    'brief',
    'length',
    'split',
    'skeleton',
    'roles',
    'structures',
    'exercises',
    'swaps',
    'progression',
    'publish',
]

_GOAL_LABELS: dict[str, str] = {
    'build_muscle': 'Build Muscle',
    'strength': 'Strength',
    'fat_loss': 'Fat Loss',
    'endurance': 'Endurance',
    'recomp': 'Recomposition',
    'general_fitness': 'General Fitness',
}

_LENGTH_EXPLANATIONS: dict[str, str] = {
    'build_muscle': (
        'Hypertrophy adaptations peak around 8 weeks before stimulus '
        'plateaus. A deload at week 4 keeps recovery on track.'
    ),
    'strength': (
        '8 weeks gives enough time to progressively overload heavy '
        'compound lifts while scheduling deload weeks for CNS recovery.'
    ),
    'fat_loss': (
        '6 weeks is the sweet spot — long enough for meaningful fat loss, '
        'short enough to maintain adherence and muscle mass.'
    ),
    'endurance': (
        '6 weeks provides a focused conditioning block without '
        'overreaching. Volume can ramp gradually before tapering.'
    ),
    'recomp': (
        '8 weeks balances the slower pace of body recomposition. '
        'Training stimulus and nutrition need consistent time to work.'
    ),
    'general_fitness': (
        '6 weeks keeps things fresh and prevents boredom while still '
        'building a solid fitness base across all qualities.'
    ),
}


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class BuilderBrief:
    """Expanded brief with lifestyle & preference context per UI/UX spec."""
    trainee_id: int
    goal: str
    days_per_week: int
    difficulty: str = 'intermediate'
    session_length_minutes: int = 60
    equipment: list[str] = field(default_factory=list)
    injuries: list[str] = field(default_factory=list)
    style: str = ''
    priorities: list[str] = field(default_factory=list)
    dislikes: list[str] = field(default_factory=list)
    duration_weeks: int | None = None
    split_template_id: str | None = None
    training_day_indices: list[int] = field(default_factory=list)
    trainer_id: int | None = None
    # Must-have expansions from UI/UX spec
    secondary_goal: str = ''
    body_part_emphasis: list[str] = field(default_factory=list)
    training_age_years: int | None = None
    skill_level: str = ''  # novice, intermediate, advanced, elite
    barbell_familiarity: str = ''  # none, basic, proficient, advanced
    recovery_profile: dict[str, Any] = field(default_factory=dict)
    # recovery_profile keys: sleep (poor/fair/good), stress (low/moderate/high),
    # soreness_tolerance (low/moderate/high), recovery_capacity (low/moderate/high),
    # neural_tolerance (low/moderate/high), simplicity_need (low/moderate/high)
    pain_tolerances: dict[str, Any] = field(default_factory=dict)
    # pain_tolerances keys: overhead (ok/limited/avoid), axial_loading (ok/limited/avoid),
    # unilateral (ok/limited/avoid), impact (ok/limited/avoid), painful_ranges (list of str)
    favorite_lifts: list[str] = field(default_factory=list)
    hated_lifts: list[str] = field(default_factory=list)
    complexity_tolerance: str = ''  # low, moderate, high


@dataclass
class StepExplanation:
    """Explanation for a single builder step."""
    step_name: str
    step_number: int
    recommendation: dict[str, Any]
    alternatives: list[dict[str, Any]]
    why: str
    is_overridden: bool = False
    override_value: dict[str, Any] | None = None


@dataclass
class QuickBuildResult:
    """Output from quick_build."""
    plan_id: str
    plan_name: str
    weeks_count: int
    sessions_count: int
    slots_count: int
    decision_log_ids: list[str]
    summary: str
    step_explanations: list[StepExplanation]


@dataclass
class BuilderStepResult:
    """Output from a single advanced builder step."""
    plan_id: str
    current_step: str
    current_step_number: int
    total_steps: int
    recommendation: dict[str, Any]
    alternatives: list[dict[str, Any]]
    why: str
    preview: dict[str, Any]
    is_complete: bool = False


# ---------------------------------------------------------------------------
# Quick Build
# ---------------------------------------------------------------------------

def quick_build(brief: BuilderBrief) -> QuickBuildResult:
    """
    Run the full pipeline with intelligence features from the UI/UX spec.
    Phases, day roles, pairing, timing, exercise tag filtering, tempo presets.
    """
    from workouts.services.plan_intelligence_service import (
        assign_pairings,
        assign_phases,
        assign_slot_roles_intelligent,
        assign_tempo_presets,
        auto_trim_session,
        classify_sessions,
        estimate_session_duration,
        filter_exercises_by_tags,
    )

    decision_log_ids: list[str] = []
    explanations: list[StepExplanation] = []

    with transaction.atomic():
        # A1: Length
        weeks_count, why_length, alts_length = _explain_length(brief)
        explanations.append(StepExplanation(
            step_name='length',
            step_number=1,
            recommendation={'weeks': weeks_count},
            alternatives=alts_length,
            why=why_length,
        ))

        # A2: Split
        split_template, why_split, alts_split, log_a2 = _explain_split(brief)
        decision_log_ids.append(str(log_a2.pk))
        explanations.append(StepExplanation(
            step_name='split',
            step_number=2,
            recommendation={
                'template_id': str(split_template.pk),
                'name': split_template.name,
                'days_per_week': split_template.days_per_week,
            },
            alternatives=alts_split,
            why=why_split,
        ))

        # Create the TrainingPlan
        plan = TrainingPlan.objects.create(
            trainee_id=brief.trainee_id,
            name=f"{split_template.name} — {brief.goal.replace('_', ' ').title()}",
            goal=brief.goal,
            status=TrainingPlan.Status.DRAFT,
            split_template=split_template,
            difficulty=brief.difficulty,
            duration_weeks=weeks_count,
            created_by_id=brief.trainer_id,
            build_mode='quick',
            builder_state={
                'brief': _brief_to_dict(brief),
                'step_explanations': [],
            },
        )

        day_indices = brief.training_day_indices
        if not day_indices:
            day_indices = _DEFAULT_DAY_INDICES.get(
                split_template.days_per_week,
                list(range(split_template.days_per_week)),
            )

        session_defs: list[dict[str, Any]] = split_template.session_definitions
        pool, all_exercises = _prefetch_exercise_pool(
            session_defs=session_defs,
            difficulty=brief.difficulty,
            trainer_id=brief.trainer_id,
        )

        # A3: Skeleton
        all_weeks, all_sessions, all_specs, log_a3 = _a3_build_skeleton(
            plan=plan,
            split_template=split_template,
            weeks_count=weeks_count,
            day_indices=day_indices,
            trainer_id=brief.trainer_id,
        )
        decision_log_ids.append(str(log_a3.pk))

        # NEW: Assign phases to weeks
        assign_phases(all_weeks, brief.goal, brief.training_age_years)
        PlanWeek.objects.bulk_update(all_weeks, ['phase', 'is_deload', 'intensity_modifier', 'volume_modifier'])

        # NEW: Classify sessions (day roles, session families, day stress)
        from collections import defaultdict
        sessions_by_week: dict[str, list[PlanSession]] = defaultdict(list)
        for s in all_sessions:
            sessions_by_week[str(s.week_id)].append(s)
        for week in all_weeks:
            week_sessions = sessions_by_week.get(str(week.pk), [])
            classify_sessions(week_sessions, session_defs, brief.goal, week.phase)
        PlanSession.objects.bulk_update(
            all_sessions, ['day_role', 'session_family', 'day_stress'],
        )

        explanations.append(StepExplanation(
            step_name='skeleton',
            step_number=3,
            recommendation={
                'weeks': len(all_weeks),
                'sessions_per_week': len(session_defs),
                'day_indices': day_indices,
                'phases': [w.phase for w in all_weeks],
            },
            alternatives=[],
            why=_explain_skeleton_why(session_defs, day_indices, weeks_count),
        ))

        # A4: Roles — NEW: intelligent role assignment based on session family
        # Group specs by session for intelligent role assignment
        session_spec_map: dict[str, list[Any]] = {}
        for spec in all_specs:
            session_spec_map.setdefault(str(spec.session.pk), []).append(spec)

        for session in all_sessions:
            session_specs = session_spec_map.get(str(session.pk), [])
            assign_slot_roles_intelligent(
                session_specs,
                session.session_family,
                brief.goal,
                brief.session_length_minutes,
            )

        log_a4 = _log_decision(
            decision_type='plan_generation_a4_slot_roles',
            actor_id=brief.trainer_id,
            context={'plan_id': str(plan.pk)},
            inputs_snapshot={'total_slots': len(all_specs), 'method': 'session_family_based'},
            constraints={},
            options=[],
            final_choice={'method': 'intelligent_session_family'},
            reason_codes=['session_family_based'],
        )
        decision_log_ids.append(str(log_a4.pk))
        explanations.append(StepExplanation(
            step_name='roles',
            step_number=4,
            recommendation={'assignment_rule': 'session_family_based'},
            alternatives=[],
            why=(
                'Slot roles are assigned based on the session family. '
                'Strength sessions protect the main lift from early fatigue. '
                'Hypertrophy sessions prioritize compound → accessory → isolation flow. '
                'Low-priority finishers are marked optional for auto-trimming.'
            ),
        ))

        # Modalities
        from workouts.services.modality_service import prefetch_system_modalities
        modality_by_slug = prefetch_system_modalities()
        deload_week_numbers: set[int] = {w.week_number for w in all_weeks if w.is_deload}

        # A5: Set structures
        log_a5 = _a5_set_structure(
            all_specs, brief.goal, brief.trainer_id, str(plan.pk),
            deload_week_numbers, modality_by_slug,
        )
        decision_log_ids.append(str(log_a5.pk))

        # NEW: Assign tempo presets
        assign_tempo_presets(all_specs, brief.goal)

        explanations.append(StepExplanation(
            step_name='structures',
            step_number=5,
            recommendation={'scheme': 'goal_based'},
            alternatives=[],
            why=_explain_structures_why(brief.goal),
        ))

        # A6: Exercises — with tag filtering
        # Apply tag-based filtering to each muscle group pool
        if brief.pain_tolerances or brief.equipment or brief.hated_lifts:
            for mg, exercises in pool.items():
                pool[mg] = filter_exercises_by_tags(
                    exercises,
                    slot_role='',
                    pain_tolerances=brief.pain_tolerances or None,
                    equipment=brief.equipment or None,
                    hated_lifts=brief.hated_lifts or None,
                )

        log_a6 = _a6_select_exercises(
            all_specs, all_sessions, session_defs, pool,
            brief.trainer_id, str(plan.pk),
        )
        decision_log_ids.append(str(log_a6.pk))
        explanations.append(StepExplanation(
            step_name='exercises',
            step_number=6,
            recommendation={'pool_size': sum(len(v) for v in pool.values())},
            alternatives=[],
            why=(
                'Exercises filtered by your equipment, pain tolerances, and preferences. '
                'Hated lifts excluded. Tag-based matching (stance, plane, ROM bias) '
                'sorts best-fit exercises to the top of each pool.'
            ),
        ))

        # A7: Swaps — with expanded buckets
        log_a7 = _a7_build_swap_recommendations(
            all_specs, all_exercises, brief.trainer_id, str(plan.pk),
        )
        decision_log_ids.append(str(log_a7.pk))
        explanations.append(StepExplanation(
            step_name='swaps',
            step_number=7,
            recommendation={'tabs': ['same_muscle', 'same_pattern', 'explore', 'pain_safe', 'equipment_limited']},
            alternatives=[],
            why=(
                'Swap alternatives include same muscle, same pattern, explore all, '
                'plus pain-safe regressions and equipment-limited fallbacks.'
            ),
        ))

        # NEW: Pairing logic
        for session in all_sessions:
            session_specs = session_spec_map.get(str(session.pk), [])
            pairings = assign_pairings(
                session_specs, session.session_family, brief.goal,
                brief.session_length_minutes,
            )
            for pd in pairings:
                for spec in session_specs:
                    if spec.order == pd.slot_order:
                        spec.pairing_group = pd.pairing_group
                        spec.pairing_type = pd.pairing_type

        explanations.append(StepExplanation(
            step_name='pairing',
            step_number=8,
            recommendation={'method': 'auto_paired'},
            alternatives=[],
            why=(
                'Exercises are paired where beneficial: antagonist supersets for '
                'efficiency, non-competing pairs to save time. Main lifts and '
                'technique work always stand alone.'
            ),
        ))

        # NEW: Session timing + auto-trim
        trimmed_total = 0
        for session in all_sessions:
            session_specs = session_spec_map.get(str(session.pk), [])
            duration = estimate_session_duration(session_specs)
            session.estimated_duration_minutes = duration

            if brief.session_length_minutes and duration > brief.session_length_minutes:
                removed = auto_trim_session(
                    session_specs, brief.session_length_minutes,
                )
                trimmed_total += len(removed)
                if removed:
                    session.estimated_duration_minutes = estimate_session_duration(session_specs)

        PlanSession.objects.bulk_update(all_sessions, ['estimated_duration_minutes'])

        explanations.append(StepExplanation(
            step_name='timing',
            step_number=9,
            recommendation={
                'target_minutes': brief.session_length_minutes,
                'slots_trimmed': trimmed_total,
            },
            alternatives=[],
            why=(
                f'Sessions estimated at target length of {brief.session_length_minutes} min. '
                f'Optional finishers trimmed to fit: {trimmed_total} slots removed. '
                'Core exercises are always protected.'
            ),
        ))

        # Create PlanSlots
        plan_slots = _specs_to_plan_slots(all_specs)
        PlanSlot.objects.bulk_create(plan_slots)

        # Save explanations to builder_state
        plan.builder_state = {
            'brief': _brief_to_dict(brief),
            'step_explanations': [
                {
                    'step_name': e.step_name,
                    'step_number': e.step_number,
                    'recommendation': e.recommendation,
                    'why': e.why,
                }
                for e in explanations
            ],
        }
        plan.save(update_fields=['builder_state'])

    summary = _build_summary(brief, split_template, weeks_count, len(all_sessions), len(plan_slots))

    return QuickBuildResult(
        plan_id=str(plan.pk),
        plan_name=plan.name,
        weeks_count=weeks_count,
        sessions_count=len(all_sessions),
        slots_count=len(plan_slots),
        decision_log_ids=decision_log_ids,
        summary=summary,
        step_explanations=explanations,
    )


# ---------------------------------------------------------------------------
# Advanced Builder
# ---------------------------------------------------------------------------

def builder_start(brief: BuilderBrief) -> BuilderStepResult:
    """
    Start an advanced builder session.
    Creates a DRAFT plan and returns the first decision step (length).
    """
    weeks_count, why_length, alts_length = _explain_length(brief)

    plan = TrainingPlan.objects.create(
        trainee_id=brief.trainee_id,
        name='(Building...)',
        goal=brief.goal,
        status=TrainingPlan.Status.DRAFT,
        difficulty=brief.difficulty,
        duration_weeks=weeks_count,
        created_by_id=brief.trainer_id,
        build_mode='advanced',
        builder_state={
            'brief': _brief_to_dict(brief),
            'current_step': 'length',
            'current_step_number': 1,
            'choices': {},
            'decision_log_ids': [],
        },
    )

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='length',
        current_step_number=1,
        total_steps=len(BUILDER_STEPS) - 1,  # exclude 'brief'
        recommendation={'weeks': weeks_count},
        alternatives=alts_length,
        why=why_length,
        preview={'goal': brief.goal, 'days_per_week': brief.days_per_week},
    )


def builder_advance(
    plan: TrainingPlan,
    override: dict[str, Any] | None = None,
) -> BuilderStepResult:
    """
    Advance the builder to the next step.
    Applies the user's override (if any) for the current step,
    executes the corresponding pipeline step, and returns the next step's info.
    """
    state = plan.builder_state or {}
    brief_data = state.get('brief', {})
    brief = _dict_to_brief(brief_data)
    current_step = state.get('current_step', 'length')
    choices = state.get('choices', {})
    decision_log_ids: list[str] = state.get('decision_log_ids', [])

    # Apply the current step's choice
    if current_step == 'length':
        return _advance_from_length(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'split':
        return _advance_from_split(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'skeleton':
        return _advance_from_skeleton(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'roles':
        return _advance_from_roles(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'structures':
        return _advance_from_structures(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'exercises':
        return _advance_from_exercises(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'swaps':
        return _advance_from_swaps(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'progression':
        return _advance_from_progression(plan, brief, override, choices, decision_log_ids)
    elif current_step == 'publish':
        return _advance_from_publish(plan, brief, override, choices, decision_log_ids)
    else:
        raise ValueError(f"Unknown builder step: {current_step}")


# ---------------------------------------------------------------------------
# Advanced Builder Step Implementations
# ---------------------------------------------------------------------------

def _advance_from_length(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed (or overrode) length. Move to split selection."""
    weeks = override.get('weeks') if override else None
    if weeks is None:
        weeks = plan.duration_weeks
    weeks = max(1, min(int(weeks), 52))

    plan.duration_weeks = weeks
    choices['length'] = {'weeks': weeks, 'overridden': override is not None}

    # Now present split options
    split_template, why_split, alts_split, log = _explain_split(brief)
    decision_log_ids.append(str(log.pk))

    _save_builder_state(plan, 'split', 2, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='split',
        current_step_number=2,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'template_id': str(split_template.pk),
            'name': split_template.name,
            'days_per_week': split_template.days_per_week,
            'session_definitions': split_template.session_definitions,
        },
        alternatives=alts_split,
        why=why_split,
        preview={
            'weeks': weeks,
            'goal': brief.goal,
            'days_per_week': brief.days_per_week,
        },
    )


def _advance_from_split(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed split. Move to skeleton preview."""
    template_id = override.get('template_id') if override else None
    if template_id:
        # Ownership check: only system templates or trainer's own templates
        privacy_q = Q(is_system=True)
        if brief.trainer_id:
            privacy_q |= Q(created_by_id=brief.trainer_id)
        try:
            template = SplitTemplate.objects.get(privacy_q, pk=template_id)
        except SplitTemplate.DoesNotExist:
            raise ValueError("Split template not found or not accessible.")
    else:
        template, _, _, _ = _explain_split(brief)

    plan.split_template = template
    plan.name = f"{template.name} — {brief.goal.replace('_', ' ').title()}"
    choices['split'] = {
        'template_id': str(template.pk),
        'name': template.name,
        'overridden': override is not None,
    }

    session_defs = template.session_definitions
    day_indices = brief.training_day_indices
    if not day_indices:
        day_indices = _DEFAULT_DAY_INDICES.get(
            template.days_per_week,
            list(range(template.days_per_week)),
        )

    # Build skeleton preview (the sessions that will be created)
    skeleton_preview: list[dict[str, Any]] = []
    day_names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    for i, sdef in enumerate(session_defs):
        day_idx = day_indices[i % len(day_indices)]
        skeleton_preview.append({
            'day_index': day_idx,
            'day_name': day_names[day_idx],
            'label': sdef.get('label', f'Session {i + 1}'),
            'muscle_groups': sdef.get('muscle_groups', []),
        })

    _save_builder_state(plan, 'skeleton', 3, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='skeleton',
        current_step_number=3,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'sessions': skeleton_preview,
            'day_indices': day_indices,
        },
        alternatives=[],
        why=_explain_skeleton_why(session_defs, day_indices, plan.duration_weeks),
        preview={
            'split_name': template.name,
            'weeks': plan.duration_weeks,
        },
    )


def _advance_from_skeleton(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed skeleton. Create DB records and show role assignments."""
    day_indices = override.get('day_indices') if override else None
    if not day_indices:
        day_indices = brief.training_day_indices
    if not day_indices and plan.split_template:
        day_indices = _DEFAULT_DAY_INDICES.get(
            plan.split_template.days_per_week,
            list(range(plan.split_template.days_per_week)),
        )

    choices['skeleton'] = {
        'day_indices': day_indices,
        'overridden': override is not None,
    }

    from collections import defaultdict
    from workouts.services.plan_intelligence_service import (
        assign_phases,
        classify_sessions,
    )

    with transaction.atomic():
        # Delete existing weeks/sessions if re-running (inside transaction)
        PlanWeek.objects.filter(plan=plan).delete()

        all_weeks, all_sessions, all_specs, log_a3 = _a3_build_skeleton(
            plan=plan,
            split_template=plan.split_template,
            weeks_count=plan.duration_weeks,
            day_indices=day_indices,
            trainer_id=brief.trainer_id,
        )
        decision_log_ids.append(str(log_a3.pk))

        # Assign phases to weeks
        assign_phases(all_weeks, brief.goal, brief.training_age_years)
        PlanWeek.objects.bulk_update(all_weeks, ['phase', 'is_deload', 'intensity_modifier', 'volume_modifier'])

        # Classify sessions (day roles, session families, day stress)
        session_defs = plan.split_template.session_definitions
        sessions_by_week: dict[str, list[PlanSession]] = defaultdict(list)
        for s in all_sessions:
            sessions_by_week[str(s.week_id)].append(s)
        for week in all_weeks:
            week_sessions = sessions_by_week.get(str(week.pk), [])
            classify_sessions(week_sessions, session_defs, brief.goal, week.phase)
        PlanSession.objects.bulk_update(
            all_sessions, ['day_role', 'session_family', 'day_stress'],
        )

        # Store specs in builder_state for subsequent steps
        specs_data = _specs_to_state(all_specs)
        choices['_specs'] = specs_data
        choices['_sessions_count'] = len(all_sessions)

        # Show role assignments preview
        role_preview = _build_role_preview(all_specs)

        _save_builder_state(plan, 'roles', 4, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='roles',
        current_step_number=4,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'assignment_rule': 'session_family_based',
            'roles': role_preview,
            'phases': [w.phase for w in all_weeks],
        },
        alternatives=[
            {'rule': 'compound_first', 'description': 'All compounds before isolations'},
            {'rule': 'superset_pairs', 'description': 'Pair agonist/antagonist movements'},
        ],
        why=(
            'Roles assigned based on session family. Strength sessions protect the main lift. '
            'Hypertrophy sessions flow compound → accessory → isolation. '
            'Phases assigned to weeks: ' + ', '.join(f'W{w.week_number}={w.phase}' for w in all_weeks[:4]) + '...'
        ),
        preview={
            'weeks': len(all_weeks),
            'sessions': len(all_sessions),
            'total_slots': len(all_specs),
        },
    )


def _advance_from_roles(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed roles. Run A4 + A5 and show set structure assignments."""
    # Reconstruct specs from state
    all_specs = _reconstruct_specs(plan, choices)

    from workouts.services.plan_intelligence_service import (
        assign_slot_roles_intelligent,
        assign_tempo_presets,
    )

    # Apply role overrides if provided
    if override and 'role_overrides' in override:
        for ro in override['role_overrides']:
            for spec in all_specs:
                if spec.order == ro.get('slot_order') and str(spec.session.pk) == ro.get('session_id'):
                    spec.slot_role = ro['role']
        choices['roles'] = {'overridden': True, 'overrides': override['role_overrides']}
    else:
        # Use intelligent role assignment based on session family
        all_sessions = list(
            PlanSession.objects.filter(week__plan=plan).select_related('week').order_by('week__week_number', 'order')
        )
        session_spec_map: dict[str, list[Any]] = {}
        for spec in all_specs:
            session_spec_map.setdefault(str(spec.session.pk), []).append(spec)
        for session in all_sessions:
            session_specs = session_spec_map.get(str(session.pk), [])
            assign_slot_roles_intelligent(
                session_specs, session.session_family, brief.goal,
                brief.session_length_minutes,
            )
        choices['roles'] = {'overridden': False, 'method': 'session_family_based'}

    # Run A5: Set structures
    from workouts.services.modality_service import prefetch_system_modalities
    modality_by_slug = prefetch_system_modalities()
    all_weeks = list(PlanWeek.objects.filter(plan=plan))
    deload_week_numbers: set[int] = {w.week_number for w in all_weeks if w.is_deload}

    log_a5 = _a5_set_structure(
        all_specs, brief.goal, brief.trainer_id, str(plan.pk),
        deload_week_numbers, modality_by_slug,
    )
    decision_log_ids.append(str(log_a5.pk))

    # Assign tempo presets
    assign_tempo_presets(all_specs, brief.goal)

    # Save updated specs
    choices['_specs'] = _specs_to_state(all_specs)

    # Build structure preview
    structure_preview = _build_structure_preview(all_specs)

    _save_builder_state(plan, 'structures', 5, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='structures',
        current_step_number=5,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'scheme': 'goal_based',
            'structures': structure_preview[:20],
        },
        alternatives=[
            {'scheme': 'strength_bias', 'description': 'Lower reps, heavier loads across all slots'},
            {'scheme': 'volume_bias', 'description': 'Higher reps, more total volume'},
        ],
        why=_explain_structures_why(brief.goal),
        preview={'goal': brief.goal},
    )


def _advance_from_structures(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed structures. Run A6 and show exercise selections."""
    all_specs = _reconstruct_specs(plan, choices)
    session_defs = plan.split_template.session_definitions
    all_sessions = list(
        PlanSession.objects.filter(week__plan=plan).select_related('week').order_by('week__week_number', 'order')
    )

    from workouts.services.plan_intelligence_service import filter_exercises_by_tags

    pool, all_exercises = _prefetch_exercise_pool(
        session_defs=session_defs,
        difficulty=brief.difficulty,
        trainer_id=brief.trainer_id,
    )

    # Apply exercise tag filtering from brief
    if brief.pain_tolerances or brief.equipment or brief.hated_lifts:
        for mg, exercises in pool.items():
            pool[mg] = filter_exercises_by_tags(
                exercises,
                slot_role='',
                pain_tolerances=brief.pain_tolerances or None,
                equipment=brief.equipment or None,
                hated_lifts=brief.hated_lifts or None,
            )

    log_a6 = _a6_select_exercises(
        all_specs, all_sessions, session_defs, pool,
        brief.trainer_id, str(plan.pk),
    )
    decision_log_ids.append(str(log_a6.pk))

    choices['structures'] = {'overridden': override is not None}
    choices['_specs'] = _specs_to_state(all_specs)
    choices['_all_exercise_ids'] = [ex.id for ex in all_exercises]

    # Build exercise preview (unique exercises for week 1 only)
    exercise_preview = _build_exercise_preview(all_specs, all_sessions)

    _save_builder_state(plan, 'exercises', 6, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='exercises',
        current_step_number=6,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'exercises': exercise_preview,
            'pool_size': sum(len(v) for v in pool.values()),
        },
        alternatives=[],
        why=(
            'Exercises were selected from your exercise pool matching difficulty '
            'and muscle group targets. Compounds fill the heavy slots, '
            'isolations fill the detail slots. Each exercise is unique within a week.'
        ),
        preview={'total_exercises': len(exercise_preview)},
    )


def _advance_from_exercises(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed exercises. Run A7 and show swap recommendations."""
    all_specs = _reconstruct_specs(plan, choices)
    exercise_ids = choices.get('_all_exercise_ids', [])
    all_exercises = list(
        Exercise.objects.filter(id__in=exercise_ids).only(
            'id', 'name', 'primary_muscle_group', 'category',
            'pattern_tags', 'swap_seed_ids',
        )
    ) if exercise_ids else []

    if not all_exercises:
        session_defs = plan.split_template.session_definitions
        _, all_exercises = _prefetch_exercise_pool(
            session_defs=session_defs,
            difficulty=brief.difficulty,
            trainer_id=brief.trainer_id,
        )

    log_a7 = _a7_build_swap_recommendations(
        all_specs, all_exercises, brief.trainer_id, str(plan.pk),
    )
    decision_log_ids.append(str(log_a7.pk))

    # Apply pairing logic
    from workouts.services.plan_intelligence_service import assign_pairings
    all_sessions_for_pairing = list(
        PlanSession.objects.filter(week__plan=plan).select_related('week').order_by('week__week_number', 'order')
    )
    session_spec_map: dict[str, list[Any]] = {}
    for spec in all_specs:
        session_spec_map.setdefault(str(spec.session.pk), []).append(spec)
    for session in all_sessions_for_pairing:
        session_specs = session_spec_map.get(str(session.pk), [])
        pairings = assign_pairings(
            session_specs, session.session_family, brief.goal,
            brief.session_length_minutes,
        )
        for pd in pairings:
            for spec in session_specs:
                if spec.order == pd.slot_order:
                    spec.pairing_group = pd.pairing_group
                    spec.pairing_type = pd.pairing_type

    choices['exercises'] = {'overridden': override is not None}
    choices['_specs'] = _specs_to_state(all_specs)

    _save_builder_state(plan, 'swaps', 7, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='swaps',
        current_step_number=7,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'tabs': ['same_muscle', 'same_pattern', 'explore', 'pain_safe', 'equipment_limited'],
            'swaps_per_tab': _MAX_SWAP_PER_TAB,
        },
        alternatives=[],
        why=(
            'Each exercise has swap alternatives: same muscle, same pattern, explore, '
            'plus pain-safe regressions and equipment-limited fallbacks. '
            'Exercises are paired where beneficial (antagonist supersets, non-competing pairs).'
        ),
        preview={},
    )


def _advance_from_swaps(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed swaps. Estimate timing, auto-trim, show progression."""
    from workouts.services.plan_intelligence_service import (
        auto_trim_session,
        estimate_session_duration,
    )

    # Estimate session timing and auto-trim if needed
    all_specs = _reconstruct_specs(plan, choices)
    all_sessions = list(
        PlanSession.objects.filter(week__plan=plan).select_related('week').order_by('week__week_number', 'order')
    )
    session_spec_map: dict[str, list[Any]] = {}
    for spec in all_specs:
        session_spec_map.setdefault(str(spec.session.pk), []).append(spec)

    trimmed_total = 0
    for session in all_sessions:
        session_specs = session_spec_map.get(str(session.pk), [])
        duration = estimate_session_duration(session_specs)
        session.estimated_duration_minutes = duration

        if brief.session_length_minutes and duration > brief.session_length_minutes:
            removed = auto_trim_session(session_specs, brief.session_length_minutes)
            trimmed_total += len(removed)
            if removed:
                session.estimated_duration_minutes = estimate_session_duration(session_specs)

    PlanSession.objects.bulk_update(all_sessions, ['estimated_duration_minutes'])
    choices['swaps'] = {'overridden': override is not None}
    choices['_specs'] = _specs_to_state(all_specs)  # Save trimmed specs
    _save_builder_state(plan, 'progression', 8, choices, decision_log_ids)

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='progression',
        current_step_number=8,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={
            'profile': 'double_progression',
            'description': 'Earn reps first, then increase load. Safest default for most lifters.',
            'timing': {
                'target_minutes': brief.session_length_minutes,
                'slots_trimmed': trimmed_total,
            },
        },
        alternatives=[
            {
                'profile': 'staircase_percent',
                'description': 'Increase load by a fixed % each week. Best for intermediates with known maxes.',
            },
            {
                'profile': 'rep_staircase',
                'description': 'Keep load stable, add reps each week. Good for beginners.',
            },
            {
                'profile': 'wave_by_month',
                'description': 'Monthly wave: build up, peak, deload. Good for advanced lifters.',
            },
            {
                'profile': 'linear',
                'description': 'Add weight every session. Best for true beginners.',
            },
        ],
        why=(
            'Progression determines how load and volume increase week to week. '
            'Double progression is the safest default — you earn your reps before '
            'adding weight, which prevents premature loading and reduces injury risk.'
        ),
        preview={},
    )


def _advance_from_progression(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """User confirmed progression. Show publish preview."""
    choices['progression'] = {
        'profile': override.get('profile', 'double_progression') if override else 'double_progression',
        'overridden': override is not None,
    }
    _save_builder_state(plan, 'publish', 9, choices, decision_log_ids)

    # Build a full plan preview
    all_weeks = list(PlanWeek.objects.filter(plan=plan).order_by('week_number'))
    all_sessions = list(
        PlanSession.objects.filter(week__plan=plan)
        .select_related('week')
        .order_by('week__week_number', 'order')
    )

    week_previews: list[dict[str, Any]] = []
    for week in all_weeks:
        week_sessions = [s for s in all_sessions if s.week_id == week.pk]
        week_previews.append({
            'week_number': week.week_number,
            'is_deload': week.is_deload,
            'sessions': [
                {'day_of_week': s.day_of_week, 'label': s.label}
                for s in week_sessions
            ],
        })

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='publish',
        current_step_number=9,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={'action': 'publish'},
        alternatives=[
            {'action': 'save_draft', 'description': 'Save as draft to review later'},
        ],
        why=(
            'Your plan is fully configured and ready to publish. '
            'Publishing creates all exercise slots and makes the plan available to the trainee. '
            'You can still edit any slot after publishing.'
        ),
        preview={
            'plan_name': plan.name,
            'weeks': week_previews,
            'total_weeks': len(all_weeks),
            'total_sessions': len(all_sessions),
        },
        is_complete=True,
    )


def _advance_from_publish(
    plan: TrainingPlan,
    brief: BuilderBrief,
    override: dict[str, Any] | None,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> BuilderStepResult:
    """Finalize: create PlanSlots and publish."""
    all_specs = _reconstruct_specs(plan, choices)

    with transaction.atomic():
        # Delete any existing slots (in case of re-publish)
        PlanSlot.objects.filter(session__week__plan=plan).delete()

        plan_slots = _specs_to_plan_slots(all_specs)
        PlanSlot.objects.bulk_create(plan_slots)

        save_draft = override.get('action') == 'save_draft' if override else False
        if not save_draft:
            # Complete other active plans
            TrainingPlan.objects.filter(
                trainee=plan.trainee,
                status=TrainingPlan.Status.ACTIVE,
            ).exclude(pk=plan.pk).update(status=TrainingPlan.Status.COMPLETED)
            plan.status = TrainingPlan.Status.ACTIVE
        else:
            plan.status = TrainingPlan.Status.DRAFT

        choices['publish'] = {'action': 'save_draft' if save_draft else 'publish'}
        # Reassign builder_state to trigger Django JSONField change detection
        plan.builder_state = {
            **plan.builder_state,
            'choices': choices,
            'current_step': 'complete',
            'current_step_number': 10,
        }
        plan.save(update_fields=['status', 'builder_state', 'updated_at'])

    return BuilderStepResult(
        plan_id=str(plan.pk),
        current_step='complete',
        current_step_number=10,
        total_steps=len(BUILDER_STEPS) - 1,
        recommendation={},
        alternatives=[],
        why='Plan published successfully.' if not save_draft else 'Plan saved as draft.',
        preview={
            'status': plan.status,
            'slots_created': len(plan_slots),
        },
        is_complete=True,
    )


# ---------------------------------------------------------------------------
# Explanation Helpers
# ---------------------------------------------------------------------------

def _explain_length(brief: BuilderBrief) -> tuple[int, str, list[dict[str, Any]]]:
    """Generate length recommendation with explanation and alternatives."""
    if brief.duration_weeks is not None:
        weeks = max(1, min(brief.duration_weeks, 52))
        why = f'You specified {weeks} weeks. '
    else:
        weeks = _GOAL_DURATION.get(brief.goal, 6)
        why = ''

    why += _LENGTH_EXPLANATIONS.get(brief.goal, 'This duration balances progress with recovery.')

    alternatives: list[dict[str, Any]] = []
    for alt_weeks in [4, 6, 8, 12, 16]:
        if alt_weeks != weeks:
            label = f'{alt_weeks} weeks'
            if alt_weeks <= 4:
                desc = 'Short cycle — quick results, less adaptation'
            elif alt_weeks <= 6:
                desc = 'Standard block — good for fat loss or conditioning'
            elif alt_weeks <= 8:
                desc = 'Full mesocycle — optimal for muscle/strength'
            elif alt_weeks <= 12:
                desc = 'Extended block — suits advanced periodization'
            else:
                desc = 'Long program — for peaking cycles or marathon prep'
            alternatives.append({'weeks': alt_weeks, 'label': label, 'description': desc})

    return weeks, why, alternatives


def _explain_split(
    brief: BuilderBrief,
) -> tuple[SplitTemplate, str, list[dict[str, Any]], DecisionLog]:
    """Generate split recommendation with explanation and alternatives."""
    privacy_q = Q(is_system=True)
    if brief.trainer_id:
        privacy_q |= Q(created_by_id=brief.trainer_id)

    candidates = list(
        SplitTemplate.objects.filter(
            privacy_q,
            days_per_week=brief.days_per_week,
        ).order_by('-is_system', 'name')[:20]
    )

    if not candidates:
        raise ValueError(
            f"No SplitTemplate found for {brief.days_per_week} days/week. "
            "Seed system templates first."
        )

    goal_match = [c for c in candidates if c.goal_type == brief.goal]
    selected = goal_match[0] if goal_match else candidates[0]

    why = (
        f"'{selected.name}' is the best match for {brief.days_per_week} days/week "
        f"with a {_GOAL_LABELS.get(brief.goal, brief.goal)} goal. "
    )
    if selected in goal_match:
        why += "This split is specifically designed for your goal type."
    else:
        why += (
            "No split specifically targets your goal at this frequency, "
            "so we picked the most versatile option."
        )

    alternatives: list[dict[str, Any]] = []
    for c in candidates:
        if c.pk != selected.pk:
            alternatives.append({
                'template_id': str(c.pk),
                'name': c.name,
                'days_per_week': c.days_per_week,
                'goal_match': c.goal_type == brief.goal,
                'session_definitions': c.session_definitions,
            })

    log = _log_decision(
        decision_type='builder_split_selection',
        actor_id=brief.trainer_id,
        context={'trainee_id': brief.trainee_id},
        inputs_snapshot={
            'days_per_week': brief.days_per_week,
            'goal': brief.goal,
        },
        constraints={'days_per_week': brief.days_per_week},
        options=[
            {'template_id': str(c.pk), 'name': c.name}
            for c in candidates[:10]
        ],
        final_choice={'template_id': str(selected.pk), 'name': selected.name},
        reason_codes=['goal_match' if selected in goal_match else 'default_selection'],
        total_options_count=len(candidates),
    )

    return selected, why, alternatives, log


def _explain_skeleton_why(
    session_defs: list[dict[str, Any]],
    day_indices: list[int],
    weeks_count: int,
) -> str:
    day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    days = [day_names[i] for i in day_indices if i < 7]
    return (
        f"Your {len(session_defs)} training days land on {', '.join(days)}. "
        f"Over {weeks_count} weeks, every 4th week is a deload at 60% intensity/volume "
        f"to prevent overreaching and promote supercompensation."
    )


def _explain_structures_why(goal: str) -> str:
    schemes: dict[str, str] = {
        'build_muscle': (
            'Primary compounds: 4 sets of 6-10 reps with 2 min rest for mechanical tension. '
            'Accessories: 3 sets of 10-15 reps at 60s rest for metabolic stress. '
            'Isolations: 3 sets of 12-15 reps at 45s rest for pump and detail.'
        ),
        'strength': (
            'Primary compounds: 5 sets of 3-5 reps with 3 min rest for maximal force development. '
            'Secondary compounds: 4 sets of 4-6 reps at 2.5 min rest. '
            'Accessories kept lighter to manage CNS fatigue.'
        ),
        'fat_loss': (
            'All slots use moderate-to-high reps (10-20) with short rest (30-45s) to '
            'maximize caloric expenditure and metabolic demand. '
            'Lower total sets to match recovery capacity in a deficit.'
        ),
        'endurance': (
            'High rep ranges (15-25) with minimal rest (30s) across all slots. '
            'Emphasis on muscular endurance and cardiovascular conditioning.'
        ),
        'recomp': (
            'Balanced approach: moderate reps (8-15) with moderate rest (60-90s). '
            'Enough intensity to preserve/build muscle while supporting the deficit.'
        ),
        'general_fitness': (
            'Moderate rep ranges (8-15) with moderate rest (45-75s). '
            'A balanced approach that builds strength, muscle, and work capacity.'
        ),
    }
    return schemes.get(goal, 'Set structures optimized for your goal.')


def _build_summary(
    brief: BuilderBrief,
    split_template: SplitTemplate,
    weeks_count: int,
    sessions_count: int,
    slots_count: int,
) -> str:
    """Build a human-readable summary for Quick Build."""
    goal_label = _GOAL_LABELS.get(brief.goal, brief.goal)
    return (
        f"Built a {weeks_count}-week {split_template.name} plan for {goal_label}. "
        f"{sessions_count} total sessions across {weeks_count} weeks with "
        f"{slots_count} exercise slots. "
        f"Every 4th week is a deload. "
        f"Exercises matched to {brief.difficulty} difficulty level. "
        f"Tap any exercise to swap it, or adjust sets/reps in the plan detail."
    )


# ---------------------------------------------------------------------------
# State Management Helpers
# ---------------------------------------------------------------------------

def _brief_to_dict(brief: BuilderBrief) -> dict[str, Any]:
    return {
        'trainee_id': brief.trainee_id,
        'goal': brief.goal,
        'days_per_week': brief.days_per_week,
        'difficulty': brief.difficulty,
        'session_length_minutes': brief.session_length_minutes,
        'equipment': brief.equipment,
        'injuries': brief.injuries,
        'style': brief.style,
        'priorities': brief.priorities,
        'dislikes': brief.dislikes,
        'duration_weeks': brief.duration_weeks,
        'split_template_id': brief.split_template_id,
        'training_day_indices': brief.training_day_indices,
        'trainer_id': brief.trainer_id,
        'secondary_goal': brief.secondary_goal,
        'body_part_emphasis': brief.body_part_emphasis,
        'training_age_years': brief.training_age_years,
        'skill_level': brief.skill_level,
        'barbell_familiarity': brief.barbell_familiarity,
        'recovery_profile': brief.recovery_profile,
        'pain_tolerances': brief.pain_tolerances,
        'favorite_lifts': brief.favorite_lifts,
        'hated_lifts': brief.hated_lifts,
        'complexity_tolerance': brief.complexity_tolerance,
    }


def _dict_to_brief(data: dict[str, Any]) -> BuilderBrief:
    if 'trainee_id' not in data:
        raise ValueError("builder_state.brief.trainee_id is missing")
    return BuilderBrief(
        trainee_id=data['trainee_id'],
        goal=data.get('goal', 'general_fitness'),
        days_per_week=data.get('days_per_week', 4),
        difficulty=data.get('difficulty', 'intermediate'),
        session_length_minutes=data.get('session_length_minutes', 60),
        equipment=data.get('equipment', []),
        injuries=data.get('injuries', []),
        style=data.get('style', ''),
        priorities=data.get('priorities', []),
        dislikes=data.get('dislikes', []),
        duration_weeks=data.get('duration_weeks'),
        split_template_id=data.get('split_template_id'),
        training_day_indices=data.get('training_day_indices', []),
        trainer_id=data.get('trainer_id'),
        secondary_goal=data.get('secondary_goal', ''),
        body_part_emphasis=data.get('body_part_emphasis', []),
        training_age_years=data.get('training_age_years'),
        skill_level=data.get('skill_level', ''),
        barbell_familiarity=data.get('barbell_familiarity', ''),
        recovery_profile=data.get('recovery_profile', {}),
        pain_tolerances=data.get('pain_tolerances', {}),
        favorite_lifts=data.get('favorite_lifts', []),
        hated_lifts=data.get('hated_lifts', []),
        complexity_tolerance=data.get('complexity_tolerance', ''),
    )


def _save_builder_state(
    plan: TrainingPlan,
    next_step: str,
    next_step_number: int,
    choices: dict[str, Any],
    decision_log_ids: list[str],
) -> None:
    """Persist builder state to the plan's JSONField."""
    state = plan.builder_state or {}
    state['current_step'] = next_step
    state['current_step_number'] = next_step_number
    state['choices'] = choices
    state['decision_log_ids'] = decision_log_ids
    plan.builder_state = state
    plan.save(update_fields=['builder_state', 'duration_weeks', 'name', 'split_template', 'updated_at'])


def _specs_to_state(all_specs: list[SlotSpec]) -> list[dict[str, Any]]:
    """Serialize SlotSpecs to JSON-safe dicts for builder_state storage."""
    result: list[dict[str, Any]] = []
    for spec in all_specs:
        result.append({
            'session_id': str(spec.session.pk),
            'order': spec.order,
            'slot_role': spec.slot_role,
            'sets': spec.sets,
            'reps_min': spec.reps_min,
            'reps_max': spec.reps_max,
            'rest_seconds': spec.rest_seconds,
            'exercise_id': spec.exercise.id if spec.exercise else None,
            'exercise_name': spec.exercise.name if spec.exercise else None,
            'modality_slug': spec.set_structure_modality.slug if spec.set_structure_modality else None,
            'modality_volume': str(spec.modality_volume_contribution),
            'swap_options_cache': spec.swap_options_cache,
            'pairing_group': spec.pairing_group,
            'pairing_type': spec.pairing_type,
            'tempo_preset': spec.tempo_preset,
            'is_optional': spec.is_optional,
        })
    return result


def _reconstruct_specs(plan: TrainingPlan, choices: dict[str, Any]) -> list[SlotSpec]:
    """Reconstruct SlotSpecs from builder_state."""
    from decimal import Decimal

    specs_data = choices.get('_specs', [])
    if not specs_data:
        return []

    # Prefetch sessions and exercises
    session_ids = {s['session_id'] for s in specs_data}
    sessions_by_id = {
        str(s.pk): s
        for s in PlanSession.objects.filter(pk__in=session_ids).select_related('week')
    }

    exercise_ids = {s['exercise_id'] for s in specs_data if s.get('exercise_id')}
    exercises_by_id = {
        ex.id: ex
        for ex in Exercise.objects.filter(id__in=exercise_ids).only(
            'id', 'name', 'primary_muscle_group', 'category',
            'pattern_tags', 'swap_seed_ids', 'equipment_required',
        )
    } if exercise_ids else {}

    modality_slugs = {s['modality_slug'] for s in specs_data if s.get('modality_slug')}
    modalities_by_slug = {
        m.slug: m
        for m in SetStructureModality.objects.filter(slug__in=modality_slugs)
    } if modality_slugs else {}

    result: list[SlotSpec] = []
    for s in specs_data:
        session = sessions_by_id.get(s['session_id'])
        if not session:
            continue
        result.append(SlotSpec(
            session=session,
            order=s['order'],
            slot_role=s['slot_role'],
            sets=s['sets'],
            reps_min=s['reps_min'],
            reps_max=s['reps_max'],
            rest_seconds=s['rest_seconds'],
            exercise=exercises_by_id.get(s.get('exercise_id')),
            set_structure_modality=modalities_by_slug.get(s.get('modality_slug', '')),
            modality_volume_contribution=Decimal(s.get('modality_volume', '0.00')),
            swap_options_cache=s.get('swap_options_cache', {}),
            pairing_group=s.get('pairing_group'),
            pairing_type=s.get('pairing_type', 'straight'),
            tempo_preset=s.get('tempo_preset'),
            is_optional=s.get('is_optional', False),
        ))
    return result


def _build_role_preview(all_specs: list[SlotSpec]) -> list[dict[str, Any]]:
    """Build a preview of slot role assignments for the first week."""
    from collections import defaultdict

    # Pre-group specs by session to avoid O(N^2)
    specs_by_session: dict[str, list[SlotSpec]] = defaultdict(list)
    session_order: list[str] = []
    for spec in all_specs:
        session_key = str(spec.session.pk)
        if session_key not in specs_by_session:
            session_order.append(session_key)
        specs_by_session[session_key].append(spec)

    preview: list[dict[str, Any]] = []
    for session_key in session_order:
        session_specs = specs_by_session[session_key]
        first_spec = session_specs[0]
        preview.append({
            'session_label': first_spec.session.label,
            'day_of_week': first_spec.session.day_of_week,
            'slots': [
                {'order': s.order, 'role': s.slot_role}
                for s in session_specs
            ],
        })
        if len(preview) >= 7:
            break
    return preview


def _build_structure_preview(all_specs: list[SlotSpec]) -> list[dict[str, Any]]:
    """Build a preview of set structures for the first session's slots."""
    if not all_specs:
        return []
    first_session = all_specs[0].session
    return [
        {
            'order': s.order,
            'role': s.slot_role,
            'sets': s.sets,
            'reps': f'{s.reps_min}-{s.reps_max}',
            'rest_seconds': s.rest_seconds,
            'modality': s.set_structure_modality.slug if s.set_structure_modality else 'straight-sets',
        }
        for s in all_specs
        if str(s.session.pk) == str(first_session.pk)
    ]


def _build_exercise_preview(
    all_specs: list[SlotSpec],
    all_sessions: list[PlanSession],
) -> list[dict[str, Any]]:
    """Build exercise selection preview (week 1 only)."""
    # Get week 1 sessions
    week1_session_ids: set[str] = set()
    for session in all_sessions:
        if session.week.week_number == 1:
            week1_session_ids.add(str(session.pk))

    preview: list[dict[str, Any]] = []
    for spec in all_specs:
        if str(spec.session.pk) not in week1_session_ids:
            continue
        if spec.exercise:
            preview.append({
                'session_label': spec.session.label,
                'slot_order': spec.order,
                'slot_role': spec.slot_role,
                'exercise_id': spec.exercise.id,
                'exercise_name': spec.exercise.name,
                'sets': spec.sets,
                'reps': f'{spec.reps_min}-{spec.reps_max}',
                'rest_seconds': spec.rest_seconds,
            })
    return preview
