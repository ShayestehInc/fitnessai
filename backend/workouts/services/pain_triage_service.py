"""
Pain Triage Service — v6.5 §24.

Manages the guided triage workflow when a trainee reports pain mid-session.
Deterministic remedy ladder: cue → tempo → load → ROM → support → regression → swap → stop.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Any

from django.db import transaction

from workouts.models import (
    ActiveSession,
    ActiveSetLog,
    DecisionLog,
    Exercise,
    PainEvent,
    PainInterventionStep,
    PainTriageResponse,
    UndoSnapshot,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class RemedySuggestion:
    """A single step in the deterministic remedy ladder."""
    order: int
    intervention_type: str
    description: str
    applicable: bool
    details: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class TriageStartResult:
    """Result of starting a triage flow."""
    triage_response_id: str
    pain_event_id: str
    round_1_answers: dict[str, Any]


@dataclass(frozen=True)
class RemedyLadderResult:
    """Result after submitting round 2 — the remedy ladder."""
    triage_response_id: str
    suggestions: list[RemedySuggestion]


@dataclass(frozen=True)
class InterventionResult:
    """Result of recording an intervention step."""
    step_id: str
    intervention_type: str
    applied: bool
    result: str


@dataclass(frozen=True)
class TriageFinalResult:
    """Result of finalizing the triage with a proceed decision."""
    triage_response_id: str
    proceed_decision: str
    trainer_notified: bool
    decision_log_id: str


# ---------------------------------------------------------------------------
# Start triage
# ---------------------------------------------------------------------------

def start_triage(
    *,
    pain_event: PainEvent,
    active_session: ActiveSession,
    trainee_id: int,
    active_set_log_id: str | None = None,
) -> TriageStartResult:
    """
    Create a PainTriageResponse from an existing PainEvent.
    Populates round_1_answers from the PainEvent fields.
    """
    round_1 = {
        'body_region': pain_event.body_region,
        'side': pain_event.side,
        'pain_score': pain_event.pain_score,
        'sensation_type': pain_event.sensation_type,
        'onset_phase': pain_event.onset_phase,
        'warmup_effect': pain_event.warmup_effect,
    }

    triage = PainTriageResponse.objects.create(
        pain_event=pain_event,
        active_session=active_session,
        active_set_log_id=active_set_log_id,
        trainee_id=trainee_id,
        round_1_answers=round_1,
    )

    return TriageStartResult(
        triage_response_id=str(triage.pk),
        pain_event_id=str(pain_event.pk),
        round_1_answers=round_1,
    )


# ---------------------------------------------------------------------------
# Round 2 + Remedy Ladder
# ---------------------------------------------------------------------------

def submit_round_2(
    *,
    triage_response_id: str,
    round_2_answers: dict[str, Any],
) -> RemedyLadderResult:
    """
    Save round 2 answers and generate the deterministic remedy ladder.
    """
    triage = PainTriageResponse.objects.select_related(
        'pain_event', 'pain_event__exercise',
    ).get(pk=triage_response_id)

    triage.round_2_answers = round_2_answers
    triage.save(update_fields=['round_2_answers'])

    suggestions = generate_remedy_ladder(triage)

    # Pre-create intervention steps (unpopulated) for the UI to fill
    with transaction.atomic():
        for suggestion in suggestions:
            PainInterventionStep.objects.create(
                triage_response=triage,
                order=suggestion.order,
                intervention_type=suggestion.intervention_type,
                description=suggestion.description,
                details=suggestion.details,
            )

    return RemedyLadderResult(
        triage_response_id=str(triage.pk),
        suggestions=suggestions,
    )


def generate_remedy_ladder(triage: PainTriageResponse) -> list[RemedySuggestion]:
    """
    Generate the deterministic ordered remedy ladder based on triage data.

    Ladder order (per v6.5 §10.6):
    1. Cue change
    2. Tempo/pause modification
    3. Reduce load
    4. Reduce ROM
    5. Add support / change stance
    6. Regression to simpler variation
    7. Swap exercise (same muscle or same pattern)
    8. Stop the slot

    Items are filtered based on pain severity and sensitivity answers.
    """
    r1 = triage.round_1_answers
    r2 = triage.round_2_answers
    pain_score: int = r1.get('pain_score', 5)
    load_sens: str = r2.get('load_sensitivity', 'same')
    rom_sens: str = r2.get('rom_sensitivity', 'same')
    tempo_sens: str = r2.get('tempo_sensitivity', 'same')

    suggestions: list[RemedySuggestion] = []
    order = 1

    # 1. Cue change — always applicable for mild-moderate pain
    if pain_score <= 7:
        suggestions.append(RemedySuggestion(
            order=order,
            intervention_type='cue_change',
            description=(
                "Focus on movement cue: engage target muscles, "
                "control the eccentric, keep neutral spine."
            ),
            applicable=True,
        ))
        order += 1

    # 2. Tempo/pause — especially if tempo_sensitivity is 'better'
    if pain_score <= 8:
        suggestions.append(RemedySuggestion(
            order=order,
            intervention_type='tempo_pause',
            description=(
                "Slow the tempo (3-1-2-0) or add a pause at the bottom "
                "to reduce peak forces."
            ),
            applicable=True,
            details={'suggested_tempo': '3-1-2-0'},
        ))
        order += 1

    # 3. Load reduction — especially if load_sensitivity is 'better'
    if load_sens == 'better' or pain_score >= 4:
        reduction_pct = 20 if pain_score >= 6 else 10
        suggestions.append(RemedySuggestion(
            order=order,
            intervention_type='load_reduction',
            description=f"Reduce load by {reduction_pct}% and reassess.",
            applicable=True,
            details={'reduction_pct': reduction_pct},
        ))
        order += 1

    # 4. ROM reduction — especially if rom_sensitivity is 'better'
    if rom_sens == 'better' or pain_score >= 5:
        suggestions.append(RemedySuggestion(
            order=order,
            intervention_type='rom_reduction',
            description=(
                "Shorten the range of motion to stay in the pain-free zone."
            ),
            applicable=True,
        ))
        order += 1

    # 5. Stance change / add support
    suggestions.append(RemedySuggestion(
        order=order,
        intervention_type='add_support',
        description=(
            "Change stance, add support (belt, wraps, elevated heels), "
            "or switch from free to machine."
        ),
        applicable=True,
    ))
    order += 1

    # 6. Regression — always available
    suggestions.append(RemedySuggestion(
        order=order,
        intervention_type='regression',
        description=(
            "Regress to a simpler variation of the same movement pattern."
        ),
        applicable=True,
    ))
    order += 1

    # 7. Swap exercise — always available
    suggestions.append(RemedySuggestion(
        order=order,
        intervention_type='swap',
        description=(
            "Swap to a same-muscle or same-pattern alternative that "
            "avoids the painful range/position."
        ),
        applicable=True,
    ))
    order += 1

    # 8. Stop — always available, emphasized for high pain
    suggestions.append(RemedySuggestion(
        order=order,
        intervention_type='stop',
        description=(
            "Stop this exercise. Skip remaining sets and move to the next slot."
        ),
        applicable=True,
    ))

    return suggestions


# ---------------------------------------------------------------------------
# Record intervention result
# ---------------------------------------------------------------------------

def record_intervention_result(
    *,
    triage_response_id: str,
    step_order: int,
    applied: bool,
    result: str,
) -> InterventionResult:
    """Record whether an intervention was tried and what happened."""
    step = PainInterventionStep.objects.get(
        triage_response_id=triage_response_id,
        order=step_order,
    )
    step.applied = applied
    step.result = result
    step.save(update_fields=['applied', 'result'])

    return InterventionResult(
        step_id=str(step.pk),
        intervention_type=step.intervention_type,
        applied=applied,
        result=result,
    )


# ---------------------------------------------------------------------------
# Finalize triage
# ---------------------------------------------------------------------------

def finalize_triage(
    *,
    triage_response_id: str,
    proceed_decision: str,
    actor_id: int | None = None,
) -> TriageFinalResult:
    """
    Save the proceed decision, create DecisionLog, and fire routing rules
    for high-severity or clinical-review decisions.
    """
    triage = PainTriageResponse.objects.select_related(
        'pain_event', 'active_session', 'trainee',
    ).get(pk=triage_response_id)

    with transaction.atomic():
        triage.proceed_decision = proceed_decision
        should_notify = (
            proceed_decision in ('stop_session', 'seek_clinical_review')
            or triage.round_1_answers.get('pain_score', 0) >= 7
        )
        triage.trainer_notified = should_notify
        triage.save(update_fields=['proceed_decision', 'trainer_notified'])

        # Collect intervention steps for the log
        steps = list(
            triage.steps.order_by('order').values(
                'order', 'intervention_type', 'applied', 'result',
            )
        )

        decision_log = DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.USER if actor_id
                else DecisionLog.ActorType.SYSTEM
            ),
            actor_id=actor_id,
            decision_type='pain_triage_finalized',
            context={
                'triage_response_id': str(triage.pk),
                'pain_event_id': str(triage.pain_event_id),
                'session_id': str(triage.active_session_id) if triage.active_session_id else None,
            },
            inputs_snapshot={
                'round_1': triage.round_1_answers,
                'round_2': triage.round_2_answers,
                'pain_score': triage.round_1_answers.get('pain_score'),
            },
            constraints_applied={},
            options_considered=[
                {'intervention': s['intervention_type'], 'applied': s['applied'], 'result': s['result']}
                for s in steps
            ],
            final_choice={
                'proceed_decision': proceed_decision,
                'trainer_notified': should_notify,
            },
            reason_codes=[
                'pain_triage',
                f'decision_{proceed_decision}',
            ],
        )

    # Fire trainer notification if needed
    if should_notify:
        _notify_trainer_of_pain_triage(triage)

    return TriageFinalResult(
        triage_response_id=str(triage.pk),
        proceed_decision=proceed_decision,
        trainer_notified=should_notify,
        decision_log_id=str(decision_log.pk),
    )


def _notify_trainer_of_pain_triage(triage: PainTriageResponse) -> None:
    """Create a trainer notification for a finalized pain triage."""
    from trainer.models import TrainerNotification

    trainee = triage.trainee
    trainer = trainee.parent_trainer
    if trainer is None:
        return

    pain_score = triage.round_1_answers.get('pain_score', '?')
    body_region = triage.round_1_answers.get('body_region', 'unknown')
    trainee_name = trainee.get_full_name() or trainee.email

    try:
        TrainerNotification.objects.create(
            trainer=trainer,
            notification_type='general',
            title=f"Pain triage: {trainee_name} — {body_region}",
            message=(
                f"Pain score {pain_score}/10 in {body_region}. "
                f"Decision: {triage.get_proceed_decision_display()}."
            ),
            data={
                'trainee_id': trainee.pk,
                'triage_response_id': str(triage.pk),
                'pain_event_id': str(triage.pain_event_id),
                'proceed_decision': triage.proceed_decision,
            },
        )
    except Exception:
        logger.exception(
            "Failed to create pain triage notification (triage=%s)",
            triage.pk,
        )
