"""
AI Builder Service — GPT-4o powered decisions for Quick Build and Advanced Builder.

Uses the LLM to make intelligent decisions at each step of the builder pipeline:
- Split recommendation with contextual reasoning
- Exercise selection tailored to the brief
- Set/rep/rest prescription with goal-aware logic
- Natural language "why" explanations

Falls back to deterministic logic if AI is unavailable.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from typing import Any

from django.db.models import Q

from workouts.models import Exercise

logger = logging.getLogger(__name__)


@dataclass
class AIBuilderResponse:
    """Parsed response from an AI builder call."""
    data: dict[str, Any]
    raw_text: str
    used_ai: bool


def _get_llm(max_tokens: int = 2048, temperature: float = 0.5) -> Any:
    """Get the LLM optimized for builder tasks (fast model by default)."""
    from trainer.ai_config import get_builder_config, get_api_key, AIModelConfig
    from trainer.ai_chat import get_chat_model

    config = get_builder_config()
    api_key = get_api_key(config.provider)
    if not api_key:
        raise RuntimeError(f"No API key configured for {config.provider.value}.")

    gen_config = AIModelConfig(
        provider=config.provider,
        model_name=config.model_name,
        temperature=temperature,
        max_tokens=max_tokens,
    )
    return get_chat_model(gen_config)


def _call_ai(prompt: str, max_tokens: int = 2048, timeout_seconds: int = 30) -> str:
    """Call the LLM and return raw text response. Times out after timeout_seconds."""
    import concurrent.futures
    import sys
    from langchain_core.messages import HumanMessage

    # Skip AI in test environment
    if 'test' in sys.argv:
        raise RuntimeError("AI skipped in test environment")

    llm = _get_llm(max_tokens=max_tokens)

    def _invoke() -> str:
        response = llm.invoke([HumanMessage(content=prompt)])
        return str(response.content)

    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
        future = executor.submit(_invoke)
        return future.result(timeout=timeout_seconds)


def _parse_json_from_response(raw: str) -> dict[str, Any]:
    """Extract JSON from an LLM response that may contain markdown fences."""
    text = raw.strip()
    if '```json' in text:
        text = text.split('```json', 1)[1]
        text = text.split('```', 1)[0]
    elif '```' in text:
        text = text.split('```', 1)[1]
        text = text.split('```', 1)[0]
    return json.loads(text.strip())


def _build_exercise_bank(
    muscle_groups: list[str],
    difficulty: str,
    trainer_id: int | None,
    limit: int = 200,
) -> list[dict[str, Any]]:
    """Build a compact exercise bank for the AI prompt."""
    privacy_q = Q(is_public=True)
    if trainer_id:
        privacy_q |= Q(created_by_id=trainer_id)

    diff_q = Q(difficulty_level=difficulty) | Q(difficulty_level__isnull=True) | Q(difficulty_level='')

    exercises = Exercise.objects.filter(
        Q(primary_muscle_group__in=muscle_groups) & privacy_q & diff_q
    ).only(
        'id', 'name', 'primary_muscle_group', 'category',
        'equipment_required',
    )[:limit]

    return [
        {
            'id': ex.id,
            'name': ex.name,
            'muscle': ex.primary_muscle_group,
            'category': ex.category or '',
            'equipment': ex.equipment_required or [],
        }
        for ex in exercises
    ]


# ---------------------------------------------------------------------------
# Quick Build: Full AI Program Design
# ---------------------------------------------------------------------------

def ai_quick_build(brief: dict[str, Any]) -> AIBuilderResponse:
    """
    AI designs the complete program in one call.
    Returns structured JSON with split, exercises, sets/reps, and explanations.
    """
    # Gather exercise bank
    from workouts.models import SplitTemplate
    muscle_groups = _infer_muscle_groups(brief)
    exercise_bank = _build_exercise_bank(
        muscle_groups, brief.get('difficulty', 'intermediate'),
        brief.get('trainer_id'),
    )

    # Get available splits
    splits = list(
        SplitTemplate.objects.filter(
            Q(is_system=True) | Q(created_by_id=brief.get('trainer_id')),
            days_per_week=brief.get('days_per_week', 4),
        ).values('id', 'name', 'days_per_week', 'goal_type', 'session_definitions')[:10]
    )

    prompt = _build_quick_build_prompt(brief, exercise_bank, splits)

    try:
        raw = _call_ai(prompt, max_tokens=4096, timeout_seconds=10)
        data = _parse_json_from_response(raw)
        return AIBuilderResponse(data=data, raw_text=raw, used_ai=True)
    except Exception:
        logger.exception("AI quick build failed — returning empty for deterministic fallback.")
        return AIBuilderResponse(data={}, raw_text='', used_ai=False)


def _build_quick_build_prompt(
    brief: dict[str, Any],
    exercise_bank: list[dict[str, Any]],
    splits: list[dict[str, Any]],
) -> str:
    """Build the prompt for AI quick build."""
    split_names = [s['name'] for s in splits]
    equipment = brief.get('equipment', [])
    injuries = brief.get('injuries', [])
    pain = brief.get('pain_tolerances', {})
    recovery = brief.get('recovery_profile', {})

    return f"""You are an expert strength & conditioning coach designing a training program.

## Client Brief
- **Primary goal**: {brief.get('goal', 'build_muscle')}
- **Secondary goal**: {brief.get('secondary_goal', 'none')}
- **Days per week**: {brief.get('days_per_week', 4)}
- **Session length**: {brief.get('session_length_minutes', 60)} minutes
- **Difficulty**: {brief.get('difficulty', 'intermediate')}
- **Equipment**: {', '.join(equipment) if equipment else 'full gym'}
- **Body part emphasis**: {', '.join(brief.get('body_part_emphasis', [])) or 'balanced'}
- **Training age**: {brief.get('training_age_years', 'unknown')} years
- **Skill level**: {brief.get('skill_level', 'intermediate')}
- **Injuries/pain**: {', '.join(injuries) if injuries else 'none'}
- **Pain tolerances**: overhead={pain.get('overhead', 'ok')}, axial={pain.get('axial_loading', 'ok')}, unilateral={pain.get('unilateral', 'ok')}
- **Recovery**: sleep={recovery.get('sleep', 'fair')}, stress={recovery.get('stress', 'moderate')}, soreness tolerance={recovery.get('soreness_tolerance', 'moderate')}
- **Style preference**: {brief.get('style', 'no preference')}
- **Hated lifts**: {', '.join(brief.get('hated_lifts', [])) or 'none'}
- **Complexity tolerance**: {brief.get('complexity_tolerance', 'moderate')}

## Available Splits
{json.dumps(split_names, indent=2)}

## Available Exercises (use ONLY these IDs)
{json.dumps(exercise_bank[:100], indent=2)}

## Instructions
Design a complete Week 1 training program. Return ONLY valid JSON with this structure:
{{
  "plan_name": "descriptive name",
  "split_name": "chosen split from available list",
  "duration_weeks": recommended weeks (4-16),
  "why_this_split": "2-3 sentence explanation of why this split fits the client",
  "week_1": {{
    "days": [
      {{
        "day_name": "Monday",
        "label": "session label e.g. Upper Strength",
        "session_family": "strength|hypertrophy|power_athletic|conditioning|mixed_hybrid",
        "exercises": [
          {{
            "exercise_id": id from bank,
            "exercise_name": "name",
            "slot_role": "primary_compound|secondary_compound|accessory|isolation|trunk",
            "sets": 4,
            "reps_min": 6,
            "reps_max": 10,
            "rest_seconds": 120,
            "why": "brief reason this exercise was chosen"
          }}
        ]
      }}
    ]
  }},
  "step_explanations": {{
    "length": "why this duration",
    "split": "why this split",
    "exercises": "overall exercise selection rationale",
    "structures": "why these set/rep schemes"
  }}
}}

Rules:
- Use ONLY exercise IDs from the provided bank
- Never include exercises the client hates
- Respect pain/injury restrictions
- Stay within the session time limit
- Prioritize compound movements for primary slots
- Match set/rep schemes to the goal
- Keep it practical and coachable"""


# ---------------------------------------------------------------------------
# Advanced Builder: Per-Step AI Recommendations
# ---------------------------------------------------------------------------

def ai_step_recommendation(
    step_name: str,
    brief: dict[str, Any],
    context: dict[str, Any],
) -> AIBuilderResponse:
    """Get AI recommendation for a specific builder step."""
    prompt = _build_step_prompt(step_name, brief, context)

    try:
        raw = _call_ai(prompt, max_tokens=1024)
        data = _parse_json_from_response(raw)
        return AIBuilderResponse(data=data, raw_text=raw, used_ai=True)
    except Exception:
        logger.exception("AI step recommendation failed for step '%s'.", step_name)
        return AIBuilderResponse(data={}, raw_text='', used_ai=False)


def _build_step_prompt(
    step_name: str,
    brief: dict[str, Any],
    context: dict[str, Any],
) -> str:
    """Build a step-specific prompt for the advanced builder.

    Includes the decision tree from the UI/UX Master Packet §12 so the AI
    follows structured reasoning at each step.
    """
    from workouts.ai_prompts import get_builder_decision_tree_prompt

    pain_tol = brief.get('pain_tolerances') or {}
    brief_summary = f"""Client: goal={brief.get('goal')}, {brief.get('days_per_week')} days/week, {brief.get('session_length_minutes', 60)}min sessions, difficulty={brief.get('difficulty')}, equipment={brief.get('equipment', [])}, injuries={brief.get('injuries', [])}, pain_tolerances={pain_tol}, style={brief.get('style', 'none')}, body_part_emphasis={brief.get('body_part_emphasis', [])}"""

    # Map builder step names to decision tree names
    _step_to_tree: dict[str, str] = {
        'split': 'choose_split',
        'length': 'choose_split',  # length uses split tree context
        'roles': 'choose_day_role',
        'skeleton': 'choose_slot_roles',
        'structures': 'choose_set_structure',
        'exercises': 'choose_exercise',
        'swaps': 'build_swaps',
        'progression': 'choose_progression',
        'publish': 'timing_check',
    }

    tree_name = _step_to_tree.get(step_name, '')
    decision_tree = ''
    if tree_name:
        decision_tree = get_builder_decision_tree_prompt(tree_name, {
            'goal': brief.get('goal', ''),
            'days_per_week': brief.get('days_per_week', 0),
            'difficulty': brief.get('difficulty', ''),
            'equipment': str(brief.get('equipment', [])),
            'injuries': str(brief.get('injuries', [])),
        })

    if step_name == 'length':
        return f"""{brief_summary}

Recommend program duration in weeks. Return JSON:
{{"weeks": number, "why": "2-3 sentence explanation", "alternatives": [{{"weeks": n, "description": "why this could work"}}]}}"""

    elif step_name == 'split':
        splits = context.get('available_splits', [])
        return f"""{brief_summary}

Available splits: {json.dumps(splits)}

Recommend the best split. Return JSON:
{{"split_name": "name", "why": "2-3 sentence explanation", "alternatives": [{{"name": "alt name", "description": "why this could work"}}]}}"""

    elif step_name == 'roles':
        sessions = context.get('sessions', [])
        return f"""{brief_summary}

Sessions in the plan: {json.dumps(sessions)}

For each session, recommend session_family and day_stress. Return JSON:
{{"sessions": [{{"label": "session label", "session_family": "strength|hypertrophy|power_athletic|conditioning|mixed_hybrid", "day_stress": "high_neural|medium_mixed|low_neural", "why": "reason"}}], "overall_why": "explanation"}}"""

    elif step_name == 'structures':
        return f"""{brief_summary}

Recommend sets, reps, and rest for each slot role given the goal. Return JSON:
{{"structures": {{"primary_compound": {{"sets": 4, "reps_min": 6, "reps_max": 10, "rest": 120}}, "secondary_compound": {{}}, "accessory": {{}}, "isolation": {{}}}}, "why": "explanation"}}"""

    elif step_name == 'progression':
        return f"""{brief_summary}

Recommend a progression strategy. Return JSON:
{{"profile": "double_progression|staircase_percent|rep_staircase|wave_by_month|linear", "why": "2-3 sentence explanation", "alternatives": [{{"profile": "name", "description": "why"}}]}}"""

    else:
        return f"""{brief_summary}
Step: {step_name}
Context: {json.dumps(context)}
{decision_tree}
Provide a recommendation for this step. Return JSON with "recommendation" and "why" keys."""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _infer_muscle_groups(brief: dict[str, Any]) -> list[str]:
    """Infer all relevant muscle groups from the brief."""
    base = [
        'chest', 'back', 'shoulders', 'biceps', 'triceps',
        'quadriceps', 'hamstrings', 'glutes',
    ]
    emphasis = brief.get('body_part_emphasis', [])
    if emphasis:
        for mg in emphasis:
            if mg not in base:
                base.append(mg)
    return base
