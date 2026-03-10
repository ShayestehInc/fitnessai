"""
Food Swap Service — v6.5 Step 10.

Recommends food alternatives based on macro similarity, category matching,
or exploration. Logs all swap decisions via DecisionLog.
"""
from __future__ import annotations

import logging
import math
from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from django.db import transaction
from django.db.models import Q, QuerySet

from workouts.models import (
    DecisionLog,
    FoodItem,
    MealLogEntry,
    UndoSnapshot,
)

if TYPE_CHECKING:
    from users.models import User

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Dataclasses
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class FoodSwapCandidate:
    """A food item recommended as a swap alternative."""
    food_item_id: int
    name: str
    brand: str
    calories: int
    protein: float
    carbs: float
    fat: float
    serving_size: float
    serving_unit: str
    similarity_score: float  # 0.0 (worst) to 1.0 (best)
    match_reason: str


@dataclass(frozen=True)
class FoodSwapResult:
    """Result of a food swap recommendation request."""
    source_food_id: int
    source_food_name: str
    mode: str
    candidates: list[FoodSwapCandidate]
    decision_log_id: str | None


@dataclass(frozen=True)
class SwapExecutionResult:
    """Result of executing a food swap in a meal log entry."""
    entry_id: int
    old_food_name: str
    new_food_name: str
    old_macros: dict[str, float]
    new_macros: dict[str, float]
    undo_snapshot_id: str | None


# ---------------------------------------------------------------------------
# Swap recommendations
# ---------------------------------------------------------------------------

SWAP_MODES = ('same_macros', 'same_category', 'explore')


def get_food_swaps(
    *,
    food_item_id: int,
    mode: str = 'same_macros',
    limit: int = 10,
    user: User,
    actor_id: int | None = None,
) -> FoodSwapResult:
    """
    Get food swap recommendations for a given food item.

    Modes:
    - same_macros: closest calorie-normalized P/C/F profile
    - same_category: similar name/brand prefix (e.g., "chicken" → other chicken)
    - explore: diverse options with decent macro match
    """
    if mode not in SWAP_MODES:
        raise ValueError(f"Invalid swap mode: '{mode}'. Valid: {', '.join(SWAP_MODES)}")

    try:
        source = FoodItem.objects.get(pk=food_item_id)
    except FoodItem.DoesNotExist:
        raise ValueError(f"Food item {food_item_id} not found.")

    # Build candidate pool (visible foods, excluding source)
    pool = _build_candidate_pool(user, exclude_id=food_item_id)

    if mode == 'same_macros':
        candidates = _rank_by_macro_similarity(source, pool, limit)
    elif mode == 'same_category':
        candidates = _rank_by_category(source, pool, limit)
    else:  # explore
        candidates = _rank_by_exploration(source, pool, limit)

    # Log the swap recommendation
    decision_log_id = _log_swap_decision(
        source=source,
        mode=mode,
        candidates=candidates,
        actor_id=actor_id,
    )

    return FoodSwapResult(
        source_food_id=source.pk,
        source_food_name=source.name,
        mode=mode,
        candidates=candidates,
        decision_log_id=decision_log_id,
    )


def execute_food_swap(
    *,
    entry_id: int,
    new_food_item_id: int,
    quantity: float | None = None,
    user: User,
    actor_id: int | None = None,
) -> SwapExecutionResult:
    """
    Execute a food swap: replace a MealLogEntry's food item with a new one.
    Creates UndoSnapshot for reversal.
    """
    try:
        entry = (
            MealLogEntry.objects
            .select_related('food_item', 'meal_log')
            .get(pk=entry_id, meal_log__trainee=user)
        )
    except MealLogEntry.DoesNotExist:
        raise ValueError(f"Meal log entry {entry_id} not found.")

    try:
        new_food = FoodItem.objects.get(pk=new_food_item_id)
    except FoodItem.DoesNotExist:
        raise ValueError(f"Food item {new_food_item_id} not found.")

    old_food_name = entry.display_name
    old_macros = {
        'calories': float(entry.calories),
        'protein': entry.protein,
        'carbs': entry.carbs,
        'fat': entry.fat,
    }

    # Compute new macros
    new_quantity = quantity if quantity is not None else entry.quantity
    new_calories = int(new_food.calories * new_quantity)
    new_protein = new_food.protein * new_quantity
    new_carbs = new_food.carbs * new_quantity
    new_fat = new_food.fat * new_quantity

    with transaction.atomic():
        # Create UndoSnapshot before modifying
        before_state = {
            'food_item_id': entry.food_item_id,
            'custom_name': entry.custom_name,
            'quantity': entry.quantity,
            'serving_unit': entry.serving_unit,
            'calories': entry.calories,
            'protein': entry.protein,
            'carbs': entry.carbs,
            'fat': entry.fat,
        }

        # Update the entry
        entry.food_item = new_food
        entry.custom_name = ''
        entry.quantity = new_quantity
        entry.serving_unit = new_food.serving_unit
        entry.calories = new_calories
        entry.protein = new_protein
        entry.carbs = new_carbs
        entry.fat = new_fat
        entry.save()

        after_state = {
            'food_item_id': new_food.pk,
            'custom_name': '',
            'quantity': new_quantity,
            'serving_unit': new_food.serving_unit,
            'calories': new_calories,
            'protein': new_protein,
            'carbs': new_carbs,
            'fat': new_fat,
        }

        # Create DecisionLog
        decision_log = DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.USER if actor_id
                else DecisionLog.ActorType.SYSTEM
            ),
            actor_id=actor_id,
            decision_type='food_swap_executed',
            context={
                'entry_id': entry.pk,
                'meal_log_id': entry.meal_log_id,
                'trainee_id': user.pk,
            },
            inputs_snapshot={
                'old_food': old_food_name,
                'new_food': new_food.name,
                'quantity': new_quantity,
            },
            constraints_applied={},
            options_considered=[],
            final_choice={
                'new_food_item_id': new_food.pk,
                'new_food_name': new_food.name,
            },
            reason_codes=['food_swap_executed'],
        )

        # Create UndoSnapshot
        snapshot = UndoSnapshot.objects.create(
            decision_log=decision_log,
            scope=UndoSnapshot.Scope.NUTRITION_DAY,
            before_state=before_state,
            after_state=after_state,
        )

    new_macros = {
        'calories': float(new_calories),
        'protein': new_protein,
        'carbs': new_carbs,
        'fat': new_fat,
    }

    return SwapExecutionResult(
        entry_id=entry.pk,
        old_food_name=old_food_name,
        new_food_name=new_food.name,
        old_macros=old_macros,
        new_macros=new_macros,
        undo_snapshot_id=str(snapshot.pk) if snapshot else None,
    )


# ---------------------------------------------------------------------------
# Candidate pool & ranking
# ---------------------------------------------------------------------------

def _build_candidate_pool(user: User, exclude_id: int) -> QuerySet[FoodItem]:
    """Build the pool of food items visible to the user, excluding the source."""
    if user.role == 'ADMIN':
        return FoodItem.objects.exclude(pk=exclude_id)
    elif user.role == 'TRAINER':
        return FoodItem.objects.filter(
            Q(is_public=True) | Q(created_by=user)
        ).exclude(pk=exclude_id)
    else:
        # Trainee: public + their trainer's foods
        trainer_id = getattr(user, 'parent_trainer_id', None)
        filters = Q(is_public=True)
        if trainer_id:
            filters |= Q(created_by_id=trainer_id)
        return FoodItem.objects.filter(filters).exclude(pk=exclude_id)


def _macro_distance(source: FoodItem, candidate: FoodItem) -> float:
    """
    Compute calorie-normalized macro distance between two food items.
    Lower is more similar. Returns euclidean distance in P/C/F ratio space.
    """
    src_cals = max(source.calories, 1)
    cand_cals = max(candidate.calories, 1)

    # Normalize macros to percentage of calories
    src_p_pct = (source.protein * 4) / src_cals
    src_c_pct = (source.carbs * 4) / src_cals
    src_f_pct = (source.fat * 9) / src_cals

    cand_p_pct = (candidate.protein * 4) / cand_cals
    cand_c_pct = (candidate.carbs * 4) / cand_cals
    cand_f_pct = (candidate.fat * 9) / cand_cals

    return math.sqrt(
        (src_p_pct - cand_p_pct) ** 2
        + (src_c_pct - cand_c_pct) ** 2
        + (src_f_pct - cand_f_pct) ** 2
    )


def _calorie_distance(source: FoodItem, candidate: FoodItem) -> float:
    """Relative calorie difference (0.0 = same, 1.0 = 100% different)."""
    src_cals = max(source.calories, 1)
    return abs(source.calories - candidate.calories) / src_cals


def _similarity_score(macro_dist: float, cal_dist: float) -> float:
    """Convert distances to a 0-1 similarity score (1 = best match)."""
    # macro_dist ranges ~0 to ~1.7 (sqrt(3)), cal_dist ~0 to inf
    macro_sim = max(0.0, 1.0 - macro_dist)
    cal_sim = max(0.0, 1.0 - cal_dist)
    # Weight: 60% macro profile, 40% calorie proximity
    return round(0.6 * macro_sim + 0.4 * cal_sim, 3)


def _rank_by_macro_similarity(
    source: FoodItem,
    pool: QuerySet[FoodItem],
    limit: int,
) -> list[FoodSwapCandidate]:
    """Rank candidates by closest calorie-normalized macro profile."""
    # Pre-filter: within 3x calorie range
    min_cals = max(1, source.calories // 3)
    max_cals = source.calories * 3
    filtered = pool.filter(calories__gte=min_cals, calories__lte=max_cals)

    scored: list[tuple[float, FoodItem]] = []
    for item in filtered[:500]:  # Cap to prevent unbounded iteration
        macro_dist = _macro_distance(source, item)
        cal_dist = _calorie_distance(source, item)
        score = _similarity_score(macro_dist, cal_dist)
        scored.append((score, item))

    scored.sort(key=lambda x: x[0], reverse=True)

    return [
        FoodSwapCandidate(
            food_item_id=item.pk,
            name=item.name,
            brand=item.brand,
            calories=item.calories,
            protein=item.protein,
            carbs=item.carbs,
            fat=item.fat,
            serving_size=item.serving_size,
            serving_unit=item.serving_unit,
            similarity_score=score,
            match_reason='Similar macro profile',
        )
        for score, item in scored[:limit]
    ]


def _rank_by_category(
    source: FoodItem,
    pool: QuerySet[FoodItem],
    limit: int,
) -> list[FoodSwapCandidate]:
    """Rank candidates by name/brand similarity (same food category)."""
    # Extract first word as category hint (e.g., "Chicken" from "Chicken Breast")
    category_words = source.name.lower().split()[:2]

    category_filter = Q()
    for word in category_words:
        if len(word) >= 3:  # Skip short words like "of", "in"
            category_filter |= Q(name__icontains=word)

    if source.brand:
        category_filter |= Q(brand__iexact=source.brand)

    candidates = pool.filter(category_filter)

    scored: list[tuple[float, FoodItem]] = []
    for item in candidates[:200]:
        macro_dist = _macro_distance(source, item)
        cal_dist = _calorie_distance(source, item)
        score = _similarity_score(macro_dist, cal_dist)
        scored.append((score, item))

    scored.sort(key=lambda x: x[0], reverse=True)

    return [
        FoodSwapCandidate(
            food_item_id=item.pk,
            name=item.name,
            brand=item.brand,
            calories=item.calories,
            protein=item.protein,
            carbs=item.carbs,
            fat=item.fat,
            serving_size=item.serving_size,
            serving_unit=item.serving_unit,
            similarity_score=score,
            match_reason='Same food category',
        )
        for score, item in scored[:limit]
    ]


def _rank_by_exploration(
    source: FoodItem,
    pool: QuerySet[FoodItem],
    limit: int,
) -> list[FoodSwapCandidate]:
    """
    Explore diverse options: reasonable macro match but different foods.
    Filters out same-category items to surface new options.
    """
    # Exclude items with similar names (opposite of category mode)
    category_words = source.name.lower().split()[:2]
    exclude_filter = Q()
    for word in category_words:
        if len(word) >= 3:
            exclude_filter |= Q(name__icontains=word)

    candidates = pool.exclude(exclude_filter) if exclude_filter else pool

    # Filter to reasonable calorie range
    min_cals = max(1, source.calories // 2)
    max_cals = source.calories * 2
    candidates = candidates.filter(calories__gte=min_cals, calories__lte=max_cals)

    scored: list[tuple[float, FoodItem]] = []
    for item in candidates[:300]:
        macro_dist = _macro_distance(source, item)
        cal_dist = _calorie_distance(source, item)
        score = _similarity_score(macro_dist, cal_dist)
        scored.append((score, item))

    scored.sort(key=lambda x: x[0], reverse=True)

    return [
        FoodSwapCandidate(
            food_item_id=item.pk,
            name=item.name,
            brand=item.brand,
            calories=item.calories,
            protein=item.protein,
            carbs=item.carbs,
            fat=item.fat,
            serving_size=item.serving_size,
            serving_unit=item.serving_unit,
            similarity_score=score,
            match_reason='Explore new options',
        )
        for score, item in scored[:limit]
    ]


# ---------------------------------------------------------------------------
# DecisionLog
# ---------------------------------------------------------------------------

def _log_swap_decision(
    *,
    source: FoodItem,
    mode: str,
    candidates: list[FoodSwapCandidate],
    actor_id: int | None,
) -> str | None:
    """Log the swap recommendation to DecisionLog."""
    try:
        log = DecisionLog.objects.create(
            actor_type=(
                DecisionLog.ActorType.USER if actor_id
                else DecisionLog.ActorType.SYSTEM
            ),
            actor_id=actor_id,
            decision_type='food_swap_recommendation',
            context={
                'source_food_id': source.pk,
                'source_food_name': source.name,
            },
            inputs_snapshot={
                'mode': mode,
                'source_macros': {
                    'calories': source.calories,
                    'protein': source.protein,
                    'carbs': source.carbs,
                    'fat': source.fat,
                },
            },
            constraints_applied={'mode': mode},
            options_considered=[
                {
                    'food_item_id': c.food_item_id,
                    'name': c.name,
                    'score': c.similarity_score,
                }
                for c in candidates[:5]
            ],
            final_choice={
                'candidates_returned': len(candidates),
                'top_match': candidates[0].name if candidates else None,
            },
            reason_codes=['food_swap_recommendation'],
        )
        return str(log.pk)
    except Exception:
        logger.exception("Failed to log food swap decision")
        return None
