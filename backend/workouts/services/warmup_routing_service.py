"""
Warmup Routing Service — v6.5 §10.3.

Pre-exercise assessment:
- Hurts → Pump drills (1-2 pump/prehab movements for the affected joint/muscle)
- Stiff → Stretch (1-2 mobility drills, often position-specific)
- Technique → Strategy (tempo/pauses or a regression teaching the intended pattern)
- Ready → Proceed directly to working sets
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from django.utils import timezone

from workouts.models import (
    Exercise,
    PainEvent,
    SessionFeedback,
)


@dataclass(frozen=True)
class WarmupSuggestion:
    """A single warm-up drill or cue."""
    category: str  # 'pump', 'stretch', 'strategy'
    title: str
    description: str
    duration_seconds: int = 60


@dataclass(frozen=True)
class WarmupAssessment:
    """Result of assessing a trainee's warm-up need for an exercise."""
    assessment_type: str  # 'hurts', 'stiff', 'technique', 'ready'
    body_region: str | None  # e.g., 'knee_left' if pain-based
    suggestions: list[WarmupSuggestion]
    reason: str


def assess_warmup_need(
    *,
    trainee_id: int,
    exercise: Exercise,
) -> WarmupAssessment:
    """
    Check recent pain and feedback history to determine if the trainee
    needs warm-up routing before this exercise.
    """
    seven_days_ago = timezone.now() - timezone.timedelta(days=7)

    # Check for recent pain in muscle groups related to this exercise
    primary_muscle = getattr(exercise, 'primary_muscle_group', '')
    pattern_tags: list[str] = list(exercise.pattern_tags) if hasattr(exercise, 'pattern_tags') and exercise.pattern_tags else []

    # Find pain events in the last 7 days for this trainee
    recent_pain = list(
        PainEvent.objects.filter(
            trainee_id=trainee_id,
            created_at__gte=seven_days_ago,
            pain_score__gte=3,
        )
        .order_by('-created_at')[:5]
    )

    # Check if any recent pain maps to this exercise's region
    exercise_regions = _exercise_to_body_regions(exercise)
    for pain in recent_pain:
        if pain.body_region in exercise_regions:
            return WarmupAssessment(
                assessment_type='hurts',
                body_region=pain.body_region,
                suggestions=_get_pump_suggestions(pain.body_region, exercise),
                reason=f"Recent pain ({pain.pain_score}/10) in {pain.get_body_region_display()}",
            )

    # Check for stiffness/form feedback in recent sessions
    recent_feedback = list(
        SessionFeedback.objects.filter(
            trainee_id=trainee_id,
            created_at__gte=seven_days_ago,
        )
        .order_by('-created_at')
        .values_list('friction_reasons', flat=True)[:3]
    )

    for reasons in recent_feedback:
        if isinstance(reasons, list) and 'form_breakdown' in reasons:
            return WarmupAssessment(
                assessment_type='technique',
                body_region=None,
                suggestions=_get_strategy_suggestions(exercise),
                reason="Recent form breakdown feedback detected.",
            )

    # Default: ready
    return WarmupAssessment(
        assessment_type='ready',
        body_region=None,
        suggestions=[],
        reason="No recent issues detected.",
    )


def get_warmup_suggestions(
    assessment_type: str,
    exercise: Exercise,
) -> list[WarmupSuggestion]:
    """Get warm-up suggestions for a specific assessment type."""
    if assessment_type == 'hurts':
        return _get_pump_suggestions('', exercise)
    elif assessment_type == 'stiff':
        return _get_stretch_suggestions(exercise)
    elif assessment_type == 'technique':
        return _get_strategy_suggestions(exercise)
    return []


def _exercise_to_body_regions(exercise: Exercise) -> set[str]:
    """Map an exercise's muscle groups to potential pain body regions."""
    muscle = getattr(exercise, 'primary_muscle_group', '') or ''
    region_map: dict[str, list[str]] = {
        'quads': ['knee_left', 'knee_right', 'hip_left', 'hip_right'],
        'hamstrings': ['knee_left', 'knee_right', 'hip_left', 'hip_right'],
        'glutes': ['hip_left', 'hip_right', 'lower_back'],
        'calves': ['ankle_left', 'ankle_right'],
        'chest': ['chest', 'shoulder_left', 'shoulder_right'],
        'lats': ['shoulder_left', 'shoulder_right', 'upper_back'],
        'mid_back': ['upper_back'],
        'upper_traps': ['neck', 'upper_back'],
        'front_delts': ['shoulder_left', 'shoulder_right'],
        'side_delts': ['shoulder_left', 'shoulder_right'],
        'rear_delts': ['shoulder_left', 'shoulder_right'],
        'triceps': ['elbow_left', 'elbow_right'],
        'biceps': ['elbow_left', 'elbow_right'],
        'forearms_and_grip': ['wrist_left', 'wrist_right'],
        'spinal_erectors': ['lower_back', 'upper_back'],
        'abs_rectus': ['lower_back'],
        'obliques': ['lower_back'],
        'deep_core': ['lower_back'],
    }
    return set(region_map.get(muscle, []))


def _get_pump_suggestions(body_region: str, exercise: Exercise) -> list[WarmupSuggestion]:
    """Pump/prehab drills for pain-affected region."""
    return [
        WarmupSuggestion(
            category='pump',
            title='Light Activation Set',
            description=(
                f'Perform 1-2 light sets of the same movement at 30-40% load, '
                f'focusing on controlled tempo and pain-free range.'
            ),
            duration_seconds=90,
        ),
        WarmupSuggestion(
            category='pump',
            title='Banded Warm-up',
            description=(
                'Use a light resistance band for 10-15 reps of the target '
                'movement pattern. Focus on blood flow and joint readiness.'
            ),
            duration_seconds=60,
        ),
    ]


def _get_stretch_suggestions(exercise: Exercise) -> list[WarmupSuggestion]:
    """Mobility drills for stiffness."""
    return [
        WarmupSuggestion(
            category='stretch',
            title='Dynamic Mobility',
            description=(
                'Perform 8-10 reps of a dynamic stretch matching this movement '
                'pattern. Move through full range slowly.'
            ),
            duration_seconds=60,
        ),
        WarmupSuggestion(
            category='stretch',
            title='Position-Specific Hold',
            description=(
                'Hold the bottom position of this exercise for 15-20 seconds '
                'with light or no load. Breathe deeply.'
            ),
            duration_seconds=30,
        ),
    ]


def _get_strategy_suggestions(exercise: Exercise) -> list[WarmupSuggestion]:
    """Technique cues and strategy for form issues."""
    cues: list[str] = []
    standardization = getattr(exercise, 'standardization_block', None)
    if standardization and isinstance(standardization, dict):
        feel_checks: list[str] = standardization.get('feel_checks', [])
        cues = feel_checks[:2] if feel_checks else []

    cue_text = ' '.join(cues) if cues else 'Focus on controlled movement and proper body position.'

    return [
        WarmupSuggestion(
            category='strategy',
            title='Tempo Warm-up',
            description=(
                'Perform 2 sets of 5 reps at 50% load with a 3-1-2 tempo. '
                f'Cues: {cue_text}'
            ),
            duration_seconds=120,
        ),
    ]
