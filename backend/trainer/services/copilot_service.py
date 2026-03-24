"""
Trainer Copilot Service — v6.5 §16.1.

AI-powered assistant that explains decisions, summarizes check-ins,
proposes plan edits, and drafts responses in the trainer's style.
Learns only from explicit trainer settings and repeated edits.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any

from django.utils import timezone

from users.models import User
from workouts.models import DecisionLog

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class DecisionExplanation:
    """Human-readable explanation of a DecisionLog entry."""
    decision_log_id: str
    decision_type: str
    summary: str
    inputs_explained: str
    alternatives_explained: str
    final_choice_explained: str
    reason_codes: list[str]


@dataclass(frozen=True)
class CheckInSummary:
    """Aggregated summary of trainee check-in data."""
    trainee_id: int
    trainee_name: str
    period: str
    total_checkins: int
    highlights: list[str]
    concerns: list[str]
    trends: dict[str, str]


@dataclass(frozen=True)
class PlanEditProposal:
    """AI-suggested plan modification."""
    plan_id: str
    instruction: str
    proposed_changes: list[dict[str, Any]]
    rationale: str
    confidence: str


@dataclass(frozen=True)
class DraftedResponse:
    """AI-drafted message for a trainee."""
    trainee_id: int
    context: str
    draft_text: str
    alternatives: list[str]
    tone: str


# ---------------------------------------------------------------------------
# Decision Explanation
# ---------------------------------------------------------------------------

def explain_decision(decision_log_id: str) -> DecisionExplanation:
    """
    Convert a DecisionLog entry into a plain-English explanation.
    No AI needed — this is deterministic formatting.
    """
    log = DecisionLog.objects.get(pk=decision_log_id)

    inputs = log.inputs_snapshot or {}
    options = log.options_considered or []
    choice = log.final_choice or {}
    reasons = log.reason_codes or []

    # Format inputs
    inputs_lines: list[str] = []
    for key, value in inputs.items():
        inputs_lines.append(f"  - {_humanize_key(key)}: {_humanize_value(value)}")
    inputs_text = '\n'.join(inputs_lines) if inputs_lines else 'No inputs recorded.'

    # Format alternatives
    alt_lines: list[str] = []
    for i, opt in enumerate(options[:5], 1):
        if isinstance(opt, dict):
            name = opt.get('name', opt.get('exercise_name', f'Option {i}'))
            score = opt.get('score', opt.get('total_score', '?'))
            alt_lines.append(f"  {i}. {name} (score: {score})")
    alternatives_text = '\n'.join(alt_lines) if alt_lines else 'No alternatives recorded.'

    # Format final choice
    choice_lines: list[str] = []
    for key, value in choice.items():
        choice_lines.append(f"  - {_humanize_key(key)}: {_humanize_value(value)}")
    choice_text = '\n'.join(choice_lines) if choice_lines else 'No choice details recorded.'

    # Summary
    actor = log.get_actor_type_display()
    summary = (
        f"A {log.decision_type.replace('_', ' ')} decision was made by the {actor}. "
        f"Reason: {', '.join(reasons) if reasons else 'unspecified'}."
    )

    return DecisionExplanation(
        decision_log_id=str(log.pk),
        decision_type=log.decision_type,
        summary=summary,
        inputs_explained=inputs_text,
        alternatives_explained=alternatives_text,
        final_choice_explained=choice_text,
        reason_codes=reasons,
    )


# ---------------------------------------------------------------------------
# Check-In Summary
# ---------------------------------------------------------------------------

def summarize_trainee_checkins(
    *,
    trainer: User,
    trainee_id: int,
    days: int = 30,
) -> CheckInSummary:
    """
    Aggregate recent check-in responses for a trainee.
    Produces highlights, concerns, and simple trends.
    """
    from workouts.models import CheckInResponse

    trainee = User.objects.get(pk=trainee_id)
    since = timezone.now() - timedelta(days=days)

    responses = list(
        CheckInResponse.objects.filter(
            trainee=trainee,
            submitted_at__gte=since,
        )
        .select_related('template')
        .order_by('-submitted_at')
    )

    highlights: list[str] = []
    concerns: list[str] = []
    trends: dict[str, str] = {}

    total = len(responses)

    if total == 0:
        concerns.append(f"No check-ins submitted in the last {days} days.")
    else:
        highlights.append(f"{total} check-in{'s' if total > 1 else ''} submitted.")

        # Analyze responses for common patterns
        for resp in responses[:5]:
            data = resp.responses if isinstance(resp.responses, dict) else {}
            for key, value in data.items():
                if isinstance(value, (int, float)):
                    if value <= 2:
                        concerns.append(
                            f"Low score for '{_humanize_key(key)}' on {resp.submitted_at.strftime('%b %d')}."
                        )
                    elif value >= 4:
                        highlights.append(
                            f"Strong '{_humanize_key(key)}' on {resp.submitted_at.strftime('%b %d')}."
                        )

    trainee_name = trainee.get_full_name() or trainee.email

    return CheckInSummary(
        trainee_id=trainee_id,
        trainee_name=trainee_name,
        period=f"Last {days} days",
        total_checkins=total,
        highlights=highlights[:5],
        concerns=concerns[:5],
        trends=trends,
    )


# ---------------------------------------------------------------------------
# Plan Edit Proposal (stub — requires AI in production)
# ---------------------------------------------------------------------------

def propose_plan_edit(
    *,
    trainer: User,
    plan_id: str,
    instruction: str,
) -> PlanEditProposal:
    """
    Generate a plan edit proposal based on trainer instruction.
    In production, this calls GPT-4o with plan context.
    For now, returns a structured stub that the AI prompt system will fill.
    """
    return PlanEditProposal(
        plan_id=plan_id,
        instruction=instruction,
        proposed_changes=[
            {
                'type': 'note',
                'message': (
                    'AI plan edit proposals require the copilot AI prompt to be '
                    'configured. This is a placeholder response.'
                ),
            },
        ],
        rationale='Awaiting AI integration for detailed proposals.',
        confidence='low',
    )


# ---------------------------------------------------------------------------
# Draft Response
# ---------------------------------------------------------------------------

def draft_response(
    *,
    trainer: User,
    trainee_id: int,
    context: str,
) -> DraftedResponse:
    """
    Draft a message for a trainee based on context.
    Offers alternatives in different tones.
    """
    trainee = User.objects.get(pk=trainee_id)
    trainee_name = trainee.first_name or trainee.email.split('@')[0]

    # Deterministic template-based drafts (AI integration comes later)
    if 'pain' in context.lower():
        draft = (
            f"Hey {trainee_name}, I saw your session had some pain notes. "
            f"Let's keep an eye on it — if it persists next session, "
            f"we'll modify the program. How are you feeling now?"
        )
        tone = 'empathetic'
    elif 'missed' in context.lower() or 'skipped' in context.lower():
        draft = (
            f"Hey {trainee_name}, no worries about missing the session. "
            f"Life happens! When you're ready to get back at it, "
            f"your next workout is waiting."
        )
        tone = 'encouraging'
    elif 'great' in context.lower() or 'strong' in context.lower():
        draft = (
            f"Amazing work {trainee_name}! Your consistency is showing. "
            f"Keep pushing — we're building on solid progress."
        )
        tone = 'celebratory'
    else:
        draft = (
            f"Hey {trainee_name}, just checking in! "
            f"How's everything going with the current plan?"
        )
        tone = 'neutral'

    return DraftedResponse(
        trainee_id=trainee_id,
        context=context,
        draft_text=draft,
        alternatives=[
            f"Quick check-in, {trainee_name} — how's the plan feeling?",
            f"{trainee_name}, any feedback on this week's sessions?",
        ],
        tone=tone,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _humanize_key(key: str) -> str:
    """Convert snake_case to Title Case."""
    return key.replace('_', ' ').title()


def _humanize_value(value: Any) -> str:
    """Format a value for display."""
    if isinstance(value, list):
        return ', '.join(str(v) for v in value[:5])
    if isinstance(value, dict):
        return json.dumps(value, default=str)[:100]
    return str(value)
