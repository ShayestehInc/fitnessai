from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Any

from django.db.models import Count, Q, Sum

from users.models import User
from workouts.models import FoodItem, MealLog, MealLogEntry


class MealLogError(Exception):
    """Base exception for meal log service errors."""


class FoodItemNotFoundError(MealLogError):
    pass


class PermissionDeniedError(MealLogError):
    pass


@dataclass(frozen=True)
class DailySummary:
    date: str
    total_calories: int
    total_protein: float
    total_carbs: float
    total_fat: float
    meal_count: int
    entry_count: int


@dataclass(frozen=True)
class QuickAddResult:
    meal_log: MealLog
    entry: MealLogEntry


def get_daily_summary(trainee: User, target_date: date) -> DailySummary:
    """Aggregate daily nutrition totals for a trainee."""
    aggregation = MealLogEntry.objects.filter(
        meal_log__trainee=trainee,
        meal_log__date=target_date,
    ).aggregate(
        total_calories=Sum('calories'),
        total_protein=Sum('protein'),
        total_carbs=Sum('carbs'),
        total_fat=Sum('fat'),
        entry_count=Count('id'),
    )

    meal_count = MealLog.objects.filter(
        trainee=trainee, date=target_date,
    ).count()

    return DailySummary(
        date=target_date.isoformat(),
        total_calories=aggregation['total_calories'] or 0,
        total_protein=round(aggregation['total_protein'] or 0, 1),
        total_carbs=round(aggregation['total_carbs'] or 0, 1),
        total_fat=round(aggregation['total_fat'] or 0, 1),
        meal_count=meal_count,
        entry_count=aggregation['entry_count'] or 0,
    )


def quick_add_entry(
    trainee: User,
    target_date: date,
    meal_number: int,
    meal_name: str = '',
    food_item_id: int | None = None,
    custom_name: str = '',
    quantity: float = 1.0,
    serving_unit: str = FoodItem.ServingUnit.SERVING,
    calories: int = 0,
    protein: float = 0,
    carbs: float = 0,
    fat: float = 0,
    fat_mode: str = MealLogEntry.FatMode.TOTAL_FAT,
) -> QuickAddResult:
    """Quick-add a food entry to a meal slot. Auto-creates MealLog if needed.

    Raises:
        FoodItemNotFoundError: If food_item_id doesn't exist or is inaccessible.
    """
    meal_log, _ = MealLog.objects.get_or_create(
        trainee=trainee,
        date=target_date,
        meal_number=meal_number,
        defaults={'meal_name': meal_name},
    )

    food_item: FoodItem | None = None
    if food_item_id:
        try:
            food_item = FoodItem.objects.get(
                Q(is_public=True) | Q(created_by=trainee.parent_trainer),
                pk=food_item_id,
            )
        except FoodItem.DoesNotExist:
            raise FoodItemNotFoundError('Food item not found.')

    if food_item:
        entry_calories = int(food_item.calories * quantity)
        entry_protein = round(food_item.protein * quantity, 1)
        entry_carbs = round(food_item.carbs * quantity, 1)
        entry_fat = round(food_item.fat * quantity, 1)
        entry_custom_name = ''
    else:
        entry_calories = calories
        entry_protein = protein
        entry_carbs = carbs
        entry_fat = fat
        entry_custom_name = custom_name

    entry = MealLogEntry.objects.create(
        meal_log=meal_log,
        food_item=food_item,
        custom_name=entry_custom_name,
        quantity=quantity,
        serving_unit=serving_unit,
        calories=entry_calories,
        protein=entry_protein,
        carbs=entry_carbs,
        fat=entry_fat,
        fat_mode=fat_mode,
    )

    return QuickAddResult(meal_log=meal_log, entry=entry)


def get_recent_food_item_ids(trainee: User, limit: int = 20) -> list[int]:
    """Return deduplicated food item IDs from trainee's recent meal log entries."""
    recent_entries = (
        MealLogEntry.objects.filter(
            meal_log__trainee=trainee,
            food_item__isnull=False,
        )
        .order_by('-created_at')
        .values_list('food_item_id', flat=True)[:50]
    )

    seen: set[int] = set()
    unique_ids: list[int] = []
    for fid in recent_entries:
        if fid not in seen:
            seen.add(fid)
            unique_ids.append(fid)
            if len(unique_ids) >= limit:
                break

    return unique_ids
