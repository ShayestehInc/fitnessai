"""
Auto-tagging Service — v6.5 Step 13.

AI-powered exercise tagging with draft/edit/retry/version workflow:
1. Trainer requests auto-tag → AI generates tag suggestions → draft created
2. Trainer reviews/edits draft → apply (tags written to exercise) or reject
3. Retry = new AI attempt with incremented retry_count

Every apply creates a DecisionLog + UndoSnapshot for auditability.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from typing import Any

from django.db import transaction
from django.utils import timezone

from users.models import User
from workouts.ai_prompts import get_exercise_auto_tag_prompt
from workouts.models import (
    DecisionLog,
    Exercise,
    ExerciseTagDraft,
    UndoSnapshot,
)

logger = logging.getLogger(__name__)

# Fields that get copied from draft to exercise
TAG_FIELDS = (
    'pattern_tags',
    'athletic_skill_tags',
    'athletic_attribute_tags',
    'primary_muscle_group',
    'secondary_muscle_groups',
    'muscle_contribution_map',
    'stance',
    'plane',
    'rom_bias',
    'equipment_required',
    'equipment_optional',
)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class AutoTagResult:
    """Result of requesting auto-tagging."""
    draft_id: str
    exercise_id: int
    status: str
    confidence_scores: dict[str, float]
    retry_count: int


@dataclass(frozen=True)
class ApplyResult:
    """Result of applying a tag draft."""
    draft_id: str
    exercise_id: int
    new_version: int
    fields_updated: list[str]


# ---------------------------------------------------------------------------
# Request Auto-Tag
# ---------------------------------------------------------------------------

def request_auto_tag(
    *,
    exercise_id: int,
    user: User,
) -> AutoTagResult:
    """
    Request AI auto-tagging for an exercise.
    Creates an ExerciseTagDraft with AI-generated suggestions.
    """
    try:
        exercise = Exercise.objects.get(pk=exercise_id)
    except Exercise.DoesNotExist:
        raise ValueError(f"Exercise {exercise_id} not found.")

    # Check permissions: public exercises need admin, private need owner
    if not exercise.is_public and exercise.created_by_id != user.pk:
        if user.role != 'ADMIN':
            raise ValueError("You don't have permission to tag this exercise.")

    # Build existing tags for context
    existing_tags = _get_existing_tags(exercise)

    # Call AI
    ai_response = _call_ai_for_tags(
        exercise_name=exercise.name,
        description=exercise.description,
        category=exercise.category,
        muscle_group=exercise.muscle_group,
        existing_tags=existing_tags,
    )

    # Create draft
    draft = ExerciseTagDraft.objects.create(
        exercise=exercise,
        requested_by=user,
        status=ExerciseTagDraft.Status.DRAFT,
        pattern_tags=ai_response.get('pattern_tags', []),
        athletic_skill_tags=ai_response.get('athletic_skill_tags', []),
        athletic_attribute_tags=ai_response.get('athletic_attribute_tags', []),
        primary_muscle_group=ai_response.get('primary_muscle_group', ''),
        secondary_muscle_groups=ai_response.get('secondary_muscle_groups', []),
        muscle_contribution_map=ai_response.get('muscle_contribution_map', {}),
        stance=ai_response.get('stance', ''),
        plane=ai_response.get('plane', ''),
        rom_bias=ai_response.get('rom_bias', ''),
        equipment_required=ai_response.get('equipment_required', []),
        equipment_optional=ai_response.get('equipment_optional', []),
        confidence_scores=ai_response.get('confidence', {}),
        ai_reasoning=ai_response.get('reasoning', {}),
        exercise_version_at_creation=exercise.version,
    )

    return AutoTagResult(
        draft_id=str(draft.pk),
        exercise_id=exercise.pk,
        status=draft.status,
        confidence_scores=draft.confidence_scores,
        retry_count=draft.retry_count,
    )


def retry_auto_tag(
    *,
    draft_id: str,
    user: User,
) -> AutoTagResult:
    """
    Retry AI auto-tagging. Creates a new draft with incremented retry_count.
    Only works on drafts in 'draft' status.
    """
    draft = _get_draft(draft_id, user)
    if draft.status != ExerciseTagDraft.Status.DRAFT:
        raise ValueError(f"Draft is not editable (status: {draft.status}).")

    # Mark old draft as rejected
    draft.status = ExerciseTagDraft.Status.REJECTED
    draft.save(update_fields=['status'])

    exercise = draft.exercise
    existing_tags = _get_existing_tags(exercise)

    ai_response = _call_ai_for_tags(
        exercise_name=exercise.name,
        description=exercise.description,
        category=exercise.category,
        muscle_group=exercise.muscle_group,
        existing_tags=existing_tags,
    )

    new_draft = ExerciseTagDraft.objects.create(
        exercise=exercise,
        requested_by=user,
        status=ExerciseTagDraft.Status.DRAFT,
        pattern_tags=ai_response.get('pattern_tags', []),
        athletic_skill_tags=ai_response.get('athletic_skill_tags', []),
        athletic_attribute_tags=ai_response.get('athletic_attribute_tags', []),
        primary_muscle_group=ai_response.get('primary_muscle_group', ''),
        secondary_muscle_groups=ai_response.get('secondary_muscle_groups', []),
        muscle_contribution_map=ai_response.get('muscle_contribution_map', {}),
        stance=ai_response.get('stance', ''),
        plane=ai_response.get('plane', ''),
        rom_bias=ai_response.get('rom_bias', ''),
        equipment_required=ai_response.get('equipment_required', []),
        equipment_optional=ai_response.get('equipment_optional', []),
        confidence_scores=ai_response.get('confidence', {}),
        ai_reasoning=ai_response.get('reasoning', {}),
        retry_count=draft.retry_count + 1,
        exercise_version_at_creation=exercise.version,
    )

    return AutoTagResult(
        draft_id=str(new_draft.pk),
        exercise_id=exercise.pk,
        status=new_draft.status,
        confidence_scores=new_draft.confidence_scores,
        retry_count=new_draft.retry_count,
    )


# ---------------------------------------------------------------------------
# Apply / Reject Draft
# ---------------------------------------------------------------------------

def apply_draft(
    *,
    draft_id: str,
    user: User,
) -> ApplyResult:
    """
    Apply a tag draft to its exercise.
    Increments exercise version, creates DecisionLog + UndoSnapshot.
    """
    draft = _get_draft(draft_id, user)
    if draft.status != ExerciseTagDraft.Status.DRAFT:
        raise ValueError(f"Draft is not applicable (status: {draft.status}).")

    exercise = draft.exercise

    with transaction.atomic():
        # Capture before state
        before_state = _get_existing_tags(exercise)
        before_version = exercise.version

        # Apply tag fields
        fields_updated: list[str] = []
        for field_name in TAG_FIELDS:
            new_value = getattr(draft, field_name)
            old_value = getattr(exercise, field_name)
            if new_value != old_value:
                setattr(exercise, field_name, new_value)
                fields_updated.append(field_name)

        # Increment version
        exercise.version = before_version + 1
        update_fields = fields_updated + ['version']
        exercise.save(update_fields=update_fields)

        # Update draft
        draft.status = ExerciseTagDraft.Status.APPLIED
        draft.applied_at = timezone.now()
        draft.save(update_fields=['status', 'applied_at'])

        # After state
        after_state = _get_existing_tags(exercise)

        # DecisionLog
        decision = DecisionLog.objects.create(
            actor_type=DecisionLog.ActorType.AI,
            actor_id=user.pk,
            decision_type='exercise_auto_tag_applied',
            context={
                'exercise_id': exercise.pk,
                'exercise_name': exercise.name,
                'draft_id': str(draft.pk),
            },
            inputs_snapshot={
                'exercise_name': exercise.name,
                'ai_confidence': draft.confidence_scores,
                'retry_count': draft.retry_count,
            },
            constraints_applied={},
            options_considered=[],
            final_choice={
                'fields_updated': fields_updated,
                'new_version': exercise.version,
            },
            reason_codes=['auto_tag_applied'],
        )

        # UndoSnapshot
        UndoSnapshot.objects.create(
            scope=UndoSnapshot.Scope.EXERCISE,
            before_state={
                'version': before_version,
                'tags': before_state,
            },
            after_state={
                'version': exercise.version,
                'tags': after_state,
            },
        )

    return ApplyResult(
        draft_id=str(draft.pk),
        exercise_id=exercise.pk,
        new_version=exercise.version,
        fields_updated=fields_updated,
    )


def reject_draft(
    *,
    draft_id: str,
    user: User,
) -> None:
    """Reject a tag draft."""
    draft = _get_draft(draft_id, user)
    if draft.status != ExerciseTagDraft.Status.DRAFT:
        raise ValueError(f"Draft is not rejectable (status: {draft.status}).")

    draft.status = ExerciseTagDraft.Status.REJECTED
    draft.save(update_fields=['status'])


def update_draft(
    *,
    draft_id: str,
    user: User,
    updates: dict[str, Any],
) -> ExerciseTagDraft:
    """
    Edit a draft's tag values before applying.
    Only tag fields and AI metadata fields are editable.
    """
    draft = _get_draft(draft_id, user)
    if draft.status != ExerciseTagDraft.Status.DRAFT:
        raise ValueError(f"Draft is not editable (status: {draft.status}).")

    editable_fields = set(TAG_FIELDS)
    changed: list[str] = []
    for key, value in updates.items():
        if key in editable_fields:
            setattr(draft, key, value)
            changed.append(key)

    if changed:
        draft.save(update_fields=changed)

    return draft


# ---------------------------------------------------------------------------
# Read helpers
# ---------------------------------------------------------------------------

def get_current_draft(
    *,
    exercise_id: int,
    user: User,
) -> ExerciseTagDraft | None:
    """Get the most recent draft-status tag draft for an exercise."""
    return (
        ExerciseTagDraft.objects.filter(
            exercise_id=exercise_id,
            status=ExerciseTagDraft.Status.DRAFT,
        )
        .select_related('exercise', 'requested_by')
        .order_by('-created_at')
        .first()
    )


def get_tag_history(
    *,
    exercise_id: int,
    limit: int = 20,
) -> list[ExerciseTagDraft]:
    """Get tag draft history for an exercise (all statuses)."""
    return list(
        ExerciseTagDraft.objects.filter(exercise_id=exercise_id)
        .select_related('requested_by')
        .order_by('-created_at')[:limit]
    )


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _get_draft(draft_id: str, user: User) -> ExerciseTagDraft:
    """Fetch a draft, verifying ownership."""
    try:
        draft = ExerciseTagDraft.objects.select_related('exercise').get(pk=draft_id)
    except ExerciseTagDraft.DoesNotExist:
        raise ValueError("Tag draft not found.")

    # Trainers can only manage their own drafts; admins can manage any
    if user.role != 'ADMIN' and draft.requested_by_id != user.pk:
        raise ValueError("You don't have permission to manage this draft.")

    return draft


def _get_existing_tags(exercise: Exercise) -> dict[str, Any]:
    """Extract current tag values from an exercise."""
    return {
        field_name: getattr(exercise, field_name)
        for field_name in TAG_FIELDS
    }


def _call_ai_for_tags(
    *,
    exercise_name: str,
    description: str,
    category: str,
    muscle_group: str,
    existing_tags: dict[str, Any],
) -> dict[str, Any]:
    """
    Call OpenAI to generate auto-tag suggestions.
    Returns parsed JSON dict. Falls back to empty tags on failure.
    """
    from workouts.services.natural_language_parser import get_openai_client

    client = get_openai_client()
    if client is None:
        logger.warning("OpenAI client not available, returning empty tags")
        return _empty_tag_response()

    prompt = get_exercise_auto_tag_prompt(
        exercise_name=exercise_name,
        description=description,
        category=category,
        muscle_group=muscle_group,
        existing_tags=existing_tags if any(existing_tags.values()) else None,
    )

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3,
            max_tokens=2000,
            response_format={"type": "json_object"},
        )

        content = response.choices[0].message.content
        if not content:
            logger.error("Empty AI response for exercise auto-tag")
            return _empty_tag_response()

        parsed = json.loads(content)
        return _validate_ai_response(parsed)

    except json.JSONDecodeError as exc:
        logger.error("Failed to parse AI auto-tag response: %s", exc)
        return _empty_tag_response()
    except Exception as exc:
        logger.error("AI auto-tag call failed: %s", exc, exc_info=True)
        raise ValueError(f"AI tagging failed: {exc}") from exc


def _validate_ai_response(data: dict[str, Any]) -> dict[str, Any]:
    """Validate and sanitize AI response against known tag values."""
    from workouts.models import Exercise

    valid_pattern = {c.value for c in Exercise.PatternTag}
    valid_athletic_skill = {c.value for c in Exercise.AthleticSkillTag}
    valid_athletic_attr = {c.value for c in Exercise.AthleticAttributeTag}
    valid_muscle = {c.value for c in Exercise.DetailedMuscleGroup}
    valid_stance = {c.value for c in Exercise.Stance}
    valid_plane = {c.value for c in Exercise.Plane}
    valid_rom = {c.value for c in Exercise.RomBias}

    # Filter invalid values
    data['pattern_tags'] = [
        t for t in data.get('pattern_tags', []) if t in valid_pattern
    ]
    data['athletic_skill_tags'] = [
        t for t in data.get('athletic_skill_tags', []) if t in valid_athletic_skill
    ]
    data['athletic_attribute_tags'] = [
        t for t in data.get('athletic_attribute_tags', []) if t in valid_athletic_attr
    ]
    data['secondary_muscle_groups'] = [
        m for m in data.get('secondary_muscle_groups', []) if m in valid_muscle
    ]

    primary = data.get('primary_muscle_group', '')
    if primary not in valid_muscle:
        data['primary_muscle_group'] = ''

    stance = data.get('stance', '')
    if stance not in valid_stance:
        data['stance'] = ''

    plane = data.get('plane', '')
    if plane not in valid_plane:
        data['plane'] = ''

    rom = data.get('rom_bias', '')
    if rom not in valid_rom:
        data['rom_bias'] = ''

    # Validate muscle_contribution_map
    mcm = data.get('muscle_contribution_map', {})
    if isinstance(mcm, dict):
        # Filter to valid muscles and ensure weights are floats
        clean_mcm: dict[str, float] = {}
        for muscle, weight in mcm.items():
            if muscle in valid_muscle:
                try:
                    clean_mcm[muscle] = round(float(weight), 3)
                except (ValueError, TypeError):
                    pass
        # Normalize to sum to 1.0
        total = sum(clean_mcm.values())
        if total > 0 and abs(total - 1.0) > 0.01:
            clean_mcm = {k: round(v / total, 3) for k, v in clean_mcm.items()}
        data['muscle_contribution_map'] = clean_mcm
    else:
        data['muscle_contribution_map'] = {}

    # Ensure confidence is a dict with float values
    conf = data.get('confidence', {})
    if not isinstance(conf, dict):
        conf = {}
    data['confidence'] = {
        k: min(1.0, max(0.0, float(v)))
        for k, v in conf.items()
        if isinstance(v, (int, float))
    }

    # Ensure reasoning is a dict with string values
    reasoning = data.get('reasoning', {})
    if not isinstance(reasoning, dict):
        reasoning = {}
    data['reasoning'] = {
        k: str(v) for k, v in reasoning.items()
    }

    return data


def _empty_tag_response() -> dict[str, Any]:
    """Return an empty tag response for fallback."""
    return {
        'pattern_tags': [],
        'athletic_skill_tags': [],
        'athletic_attribute_tags': [],
        'primary_muscle_group': '',
        'secondary_muscle_groups': [],
        'muscle_contribution_map': {},
        'stance': '',
        'plane': '',
        'rom_bias': '',
        'equipment_required': [],
        'equipment_optional': [],
        'confidence': {},
        'reasoning': {},
    }
