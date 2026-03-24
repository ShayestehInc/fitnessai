"""
Reactive Nutrition Engine — v6.5 Nutrition Spec V1.2 §13.

Weekly decision rules:
- Adherence >= 70% + trend stalled 2 weeks → adjust calories small step
- Adherence < 70% → do NOT change targets; reduce friction first
- Losing/gaining too fast → adjust calories and/or carb distribution
- Protein stays stable; move carbs/fats more than protein
- Every decision returns: what changed, why (1 sentence), undo payload

Default step sizes (configurable):
- Fat loss: -150 to -250 kcal
- Gain: +100 to +200 kcal
"""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any

from django.db import transaction

from workouts.models import (
    DecisionLog,
    NutritionDayPlan,
    NutritionTemplateAssignment,
    WeeklyNutritionCheckIn,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

FAT_LOSS_STEP_KCAL = -200
GAIN_STEP_KCAL = 150
MIN_ADHERENCE_FOR_ADJUSTMENT = 70.0
STALL_WEEKS_THRESHOLD = 2
FAST_LOSS_THRESHOLD_KG = -1.0  # > 1 kg/week loss = too fast
FAST_GAIN_THRESHOLD_KG = 0.5   # > 0.5 kg/week gain = too fast


@dataclass(frozen=True)
class ReactiveDecision:
    """Result of the weekly reactive nutrition evaluation."""
    action: str  # 'no_change', 'adjust_calories', 'reduce_friction', 'slow_loss', 'slow_gain'
    delta_kcal: int
    new_calories: int
    new_carbs: int
    new_fat: int
    protein_unchanged: int
    why: str
    undo_payload: dict[str, Any]


def evaluate_weekly(
    *,
    trainee_id: int,
    checkin: WeeklyNutritionCheckIn,
) -> ReactiveDecision:
    """
    Evaluate a weekly check-in and decide whether to adjust nutrition targets.
    Protein stays stable; adjustments come from carbs and fats.
    """
    # Get current nutrition state
    assignment = (
        NutritionTemplateAssignment.objects
        .filter(trainee_id=trainee_id, is_active=True)
        .select_related('template')
        .first()
    )
    if assignment is None:
        return ReactiveDecision(
            action='no_change',
            delta_kcal=0,
            new_calories=0,
            new_carbs=0,
            new_fat=0,
            protein_unchanged=0,
            why='No active nutrition template assignment.',
            undo_payload={},
        )

    # Get current targets from most recent day plan
    recent_plan = (
        NutritionDayPlan.objects
        .filter(trainee_id=trainee_id)
        .order_by('-date')
        .first()
    )
    if recent_plan is None:
        return ReactiveDecision(
            action='no_change',
            delta_kcal=0,
            new_calories=0,
            new_carbs=0,
            new_fat=0,
            protein_unchanged=0,
            why='No existing day plans to adjust.',
            undo_payload={},
        )

    current_cal = recent_plan.total_calories
    current_protein = recent_plan.total_protein
    current_carbs = recent_plan.total_carbs
    current_fat = recent_plan.total_fat

    undo_payload = {
        'old_calories': current_cal,
        'old_protein': current_protein,
        'old_carbs': current_carbs,
        'old_fat': current_fat,
    }

    # Rule 1: Low adherence → don't change, reduce friction
    if checkin.adherence_pct < MIN_ADHERENCE_FOR_ADJUSTMENT:
        return ReactiveDecision(
            action='reduce_friction',
            delta_kcal=0,
            new_calories=current_cal,
            new_carbs=current_carbs,
            new_fat=current_fat,
            protein_unchanged=current_protein,
            why=(
                f"Adherence is {checkin.adherence_pct:.0f}% (below {MIN_ADHERENCE_FOR_ADJUSTMENT:.0f}%). "
                f"Focus on consistency before changing targets."
            ),
            undo_payload=undo_payload,
        )

    # Get weight trend from last few check-ins
    recent_checkins = list(
        WeeklyNutritionCheckIn.objects
        .filter(trainee_id=trainee_id)
        .order_by('-week_start')[:4]
    )

    weight_trend_kg_per_week = 0.0
    if len(recent_checkins) >= 2 and recent_checkins[0].weight_avg_kg and recent_checkins[-1].weight_avg_kg:
        weeks = len(recent_checkins) - 1
        weight_diff = recent_checkins[0].weight_avg_kg - recent_checkins[-1].weight_avg_kg
        weight_trend_kg_per_week = weight_diff / weeks if weeks > 0 else 0

    # Determine goal from template
    template_type = assignment.template.template_type
    is_fat_loss = template_type in ('shredded', 'carb_cycling') and (
        assignment.parameters.get('goal', '') == 'fat_loss'
        or template_type == 'shredded'
    )
    is_gaining = template_type == 'massive'

    # Rule 2: Losing too fast → increase calories
    if is_fat_loss and weight_trend_kg_per_week < FAST_LOSS_THRESHOLD_KG:
        delta = abs(FAT_LOSS_STEP_KCAL)  # Add back calories
        new_cal = current_cal + delta
        new_carbs = current_carbs + (delta // 4 // 2)
        new_fat = current_fat + (delta // 9 // 2)
        return ReactiveDecision(
            action='slow_loss',
            delta_kcal=delta,
            new_calories=new_cal,
            new_carbs=new_carbs,
            new_fat=new_fat,
            protein_unchanged=current_protein,
            why=(
                f"Losing {abs(weight_trend_kg_per_week):.1f} kg/week — too fast. "
                f"Adding {delta} kcal to slow the rate."
            ),
            undo_payload=undo_payload,
        )

    # Rule 3: Gaining too fast → reduce calories
    if is_gaining and weight_trend_kg_per_week > FAST_GAIN_THRESHOLD_KG:
        delta = -abs(GAIN_STEP_KCAL)
        new_cal = current_cal + delta
        new_carbs = current_carbs + (delta // 4)
        new_fat = current_fat
        return ReactiveDecision(
            action='slow_gain',
            delta_kcal=delta,
            new_calories=new_cal,
            new_carbs=max(0, new_carbs),
            new_fat=new_fat,
            protein_unchanged=current_protein,
            why=(
                f"Gaining {weight_trend_kg_per_week:.1f} kg/week — too fast. "
                f"Reducing by {abs(delta)} kcal."
            ),
            undo_payload=undo_payload,
        )

    # Rule 4: Stalled (trend near zero for 2+ weeks with good adherence)
    stall_count = sum(
        1 for c in recent_checkins
        if c.weight_avg_kg and recent_checkins[0].weight_avg_kg
        and abs((c.weight_avg_kg - recent_checkins[0].weight_avg_kg)) < 0.3
    )

    if stall_count >= STALL_WEEKS_THRESHOLD:
        if is_fat_loss:
            delta = FAT_LOSS_STEP_KCAL
        elif is_gaining:
            delta = GAIN_STEP_KCAL
        else:
            return ReactiveDecision(
                action='no_change',
                delta_kcal=0,
                new_calories=current_cal,
                new_carbs=current_carbs,
                new_fat=current_fat,
                protein_unchanged=current_protein,
                why="Weight stable and no specific fat loss/gain goal. No adjustment needed.",
                undo_payload=undo_payload,
            )

        new_cal = current_cal + delta
        # Distribute delta to carbs primarily, protein stays the same
        carb_delta = (abs(delta) * 3 // 4) // 4  # 75% from carbs
        fat_delta = (abs(delta) * 1 // 4) // 9   # 25% from fat
        sign = 1 if delta > 0 else -1

        new_carbs = max(0, current_carbs + sign * carb_delta)
        new_fat = max(0, current_fat + sign * fat_delta)

        direction = 'loss stall' if is_fat_loss else 'gain stall'
        return ReactiveDecision(
            action='adjust_calories',
            delta_kcal=delta,
            new_calories=new_cal,
            new_carbs=new_carbs,
            new_fat=new_fat,
            protein_unchanged=current_protein,
            why=(
                f"Weight stalled for {stall_count} weeks with {checkin.adherence_pct:.0f}% adherence. "
                f"Adjusting by {delta:+d} kcal ({direction})."
            ),
            undo_payload=undo_payload,
        )

    # Default: no change
    return ReactiveDecision(
        action='no_change',
        delta_kcal=0,
        new_calories=current_cal,
        new_carbs=current_carbs,
        new_fat=current_fat,
        protein_unchanged=current_protein,
        why="Progress on track. No adjustment needed this week.",
        undo_payload=undo_payload,
    )


def apply_reactive_decision(
    *,
    trainee_id: int,
    checkin: WeeklyNutritionCheckIn,
    decision: ReactiveDecision,
    actor_id: int | None = None,
) -> None:
    """
    Apply a reactive decision to the check-in record and create DecisionLog.
    Does NOT auto-regenerate day plans — that happens on next access.
    """
    with transaction.atomic():
        checkin.decision = {
            'action': decision.action,
            'delta_kcal': decision.delta_kcal,
            'new_calories': decision.new_calories,
            'new_carbs': decision.new_carbs,
            'new_fat': decision.new_fat,
            'protein_unchanged': decision.protein_unchanged,
        }
        checkin.decision_why = decision.why
        checkin.undo_payload = decision.undo_payload
        checkin.decision_applied = decision.action != 'no_change'
        checkin.save(update_fields=[
            'decision', 'decision_why', 'undo_payload', 'decision_applied',
        ])

        DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.SYSTEM if actor_id is None
                else DecisionLog.ActorType.TRAINER
            ),
            actor_id=actor_id,
            decision_type='reactive_nutrition_adjustment',
            context={
                'trainee_id': trainee_id,
                'checkin_id': str(checkin.pk),
                'week_start': str(checkin.week_start),
            },
            inputs_snapshot={
                'adherence_pct': checkin.adherence_pct,
                'weight_avg_kg': checkin.weight_avg_kg,
                'hunger': checkin.hunger,
                'sleep': checkin.sleep_quality,
                'stress': checkin.stress,
            },
            constraints_applied={
                'min_adherence': MIN_ADHERENCE_FOR_ADJUSTMENT,
                'stall_threshold': STALL_WEEKS_THRESHOLD,
            },
            options_considered=[],
            final_choice={
                'action': decision.action,
                'delta_kcal': decision.delta_kcal,
            },
            reason_codes=[
                'reactive_nutrition',
                decision.action,
            ],
        )
