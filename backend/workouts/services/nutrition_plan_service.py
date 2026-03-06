"""
Nutrition Plan Service — generates per-date NutritionDayPlans
from a trainee's active NutritionTemplateAssignment.

Supports legacy (flat NutritionGoal) and custom template rulesets.
"""
from __future__ import annotations

import datetime
from dataclasses import dataclass
from typing import TYPE_CHECKING

from django.db.models import Q

from workouts.models import (
    NutritionDayPlan,
    NutritionGoal,
    NutritionTemplate,
    NutritionTemplateAssignment,
    Program,
)

if TYPE_CHECKING:
    from users.models import User


@dataclass(frozen=True)
class MealTarget:
    """Computed per-meal macro targets."""
    meal_number: int
    name: str
    protein: int
    carbs: int
    fat: int
    calories: int

    def to_dict(self) -> dict[str, int | str]:
        return {
            'meal_number': self.meal_number,
            'name': self.name,
            'protein': self.protein,
            'carbs': self.carbs,
            'fat': self.fat,
            'calories': self.calories,
        }


class NutritionPlanService:
    """Generates and manages NutritionDayPlans for trainees."""

    # ------------------------------------------------------------------ #
    # Public API
    # ------------------------------------------------------------------ #

    def get_or_generate_day_plan(
        self,
        trainee: User,
        date: datetime.date,
    ) -> NutritionDayPlan | None:
        """Return existing day plan or generate one lazily.

        Returns None when the trainee has neither an active template
        assignment nor a legacy NutritionGoal.
        """
        existing = NutritionDayPlan.objects.filter(
            trainee=trainee,
            date=date,
        ).first()
        if existing is not None:
            return existing

        return self.generate_day_plan(trainee, date)

    def generate_day_plan(
        self,
        trainee: User,
        date: datetime.date,
    ) -> NutritionDayPlan | None:
        """Determine day type, apply ruleset, and create/update the plan."""
        assignment = self._get_active_assignment(trainee)

        if assignment is not None:
            return self._generate_from_template(assignment, trainee, date)

        # Fallback: wrap legacy NutritionGoal
        return self._generate_from_legacy(trainee, date)

    def regenerate_plans_for_range(
        self,
        trainee: User,
        start_date: datetime.date,
        end_date: datetime.date,
    ) -> list[NutritionDayPlan]:
        """Batch-regenerate day plans for a date range.

        Skips days where the plan was manually overridden.
        """
        plans: list[NutritionDayPlan] = []
        current = start_date
        while current <= end_date:
            existing = NutritionDayPlan.objects.filter(
                trainee=trainee,
                date=current,
            ).first()
            if existing is not None and existing.is_overridden:
                plans.append(existing)
            else:
                plan = self.generate_day_plan(trainee, current)
                if plan is not None:
                    plans.append(plan)
            current += datetime.timedelta(days=1)
        return plans

    # ------------------------------------------------------------------ #
    # Day-type determination
    # ------------------------------------------------------------------ #

    def determine_day_type(
        self,
        assignment: NutritionTemplateAssignment,
        trainee: User,
        date: datetime.date,
    ) -> str:
        """Resolve day type from the assignment's schedule config.

        Supports two methods:
        - ``training_based``: checks the trainee's active program schedule
        - ``weekly_rotation``: maps each weekday name to a day type
        """
        schedule = assignment.day_type_schedule
        if not schedule:
            return self._day_type_from_program(trainee, date, assignment)

        method = schedule.get('method', 'training_based')

        if method == 'weekly_rotation':
            weekday_name = date.strftime('%A').lower()  # e.g. "monday"
            return str(
                schedule.get(weekday_name, NutritionDayPlan.DayType.REST)
            )

        # Default: training_based
        return self._day_type_from_program(trainee, date, assignment)

    # ------------------------------------------------------------------ #
    # Ruleset application
    # ------------------------------------------------------------------ #

    def apply_template_ruleset(
        self,
        template: NutritionTemplate,
        parameters: dict,
        day_type: str,
    ) -> list[MealTarget]:
        """Dispatch to the correct ruleset handler based on template_type."""
        if template.template_type == NutritionTemplate.TemplateType.LEGACY:
            return self._apply_legacy_from_params(parameters)

        if template.template_type == NutritionTemplate.TemplateType.CUSTOM:
            return self._apply_custom_ruleset(
                template.ruleset, parameters, day_type,
            )

        # For shredded / massive / carb_cycling / macro_ebook
        # Phase 3+ will implement dedicated formula engines.
        # Until then, use the custom ruleset path if a ruleset exists,
        # otherwise fall back to even-split from ruleset totals.
        if template.ruleset:
            return self._apply_custom_ruleset(
                template.ruleset, parameters, day_type,
            )

        return self._apply_legacy_from_params(parameters)

    def apply_legacy_ruleset(
        self,
        nutrition_goal: NutritionGoal,
        meals_per_day: int,
    ) -> list[MealTarget]:
        """Wrap a flat NutritionGoal into per-meal MealTargets."""
        if meals_per_day < 1:
            meals_per_day = 4

        per_protein = nutrition_goal.protein_goal // meals_per_day
        per_carbs = nutrition_goal.carbs_goal // meals_per_day
        per_fat = nutrition_goal.fat_goal // meals_per_day
        per_cals = nutrition_goal.calories_goal // meals_per_day

        return [
            MealTarget(
                meal_number=i + 1,
                name=f"Meal {i + 1}",
                protein=per_protein,
                carbs=per_carbs,
                fat=per_fat,
                calories=per_cals,
            )
            for i in range(meals_per_day)
        ]

    # ------------------------------------------------------------------ #
    # Private helpers
    # ------------------------------------------------------------------ #

    def _get_active_assignment(
        self,
        trainee: User,
    ) -> NutritionTemplateAssignment | None:
        return (
            NutritionTemplateAssignment.objects
            .filter(trainee=trainee, is_active=True)
            .select_related('template')
            .first()
        )

    def _day_type_from_program(
        self,
        trainee: User,
        date: datetime.date,
        assignment: NutritionTemplateAssignment,
    ) -> str:
        """Check the trainee's active program to decide training vs rest."""
        schedule = assignment.day_type_schedule or {}
        training_day_type = str(
            schedule.get('training_days', NutritionDayPlan.DayType.TRAINING)
        )
        rest_day_type = str(
            schedule.get('rest_days', NutritionDayPlan.DayType.REST)
        )

        program = (
            Program.objects
            .filter(
                trainee=trainee,
                is_active=True,
                start_date__lte=date,
                end_date__gte=date,
            )
            .first()
        )
        if program is None:
            return rest_day_type

        weekday_name = date.strftime('%A')
        schedule_data = program.schedule
        if not isinstance(schedule_data, dict):
            return rest_day_type

        weeks = schedule_data.get('weeks', [])
        if not weeks:
            return rest_day_type

        # Determine which week number this date falls into
        days_since_start = (date - program.start_date).days
        week_index = days_since_start // 7
        if week_index >= len(weeks):
            week_index = week_index % len(weeks)

        week = weeks[week_index]
        days = week.get('days', [])
        for day in days:
            if isinstance(day, dict) and day.get('day') == weekday_name:
                exercises = day.get('exercises', [])
                if exercises:
                    return training_day_type
                break

        return rest_day_type

    def _generate_from_template(
        self,
        assignment: NutritionTemplateAssignment,
        trainee: User,
        date: datetime.date,
    ) -> NutritionDayPlan:
        template = assignment.template
        day_type = self.determine_day_type(assignment, trainee, date)
        meal_targets = self.apply_template_ruleset(
            template, assignment.parameters, day_type,
        )

        total_protein = sum(m.protein for m in meal_targets)
        total_carbs = sum(m.carbs for m in meal_targets)
        total_fat = sum(m.fat for m in meal_targets)
        total_calories = sum(m.calories for m in meal_targets)

        snapshot = {
            'template_id': template.pk,
            'template_name': template.name,
            'template_type': template.template_type,
            'parameters': assignment.parameters,
            'day_type_schedule': assignment.day_type_schedule,
        }

        plan, _ = NutritionDayPlan.objects.update_or_create(
            trainee=trainee,
            date=date,
            defaults={
                'day_type': day_type,
                'template_snapshot': snapshot,
                'total_protein': total_protein,
                'total_carbs': total_carbs,
                'total_fat': total_fat,
                'total_calories': total_calories,
                'meals': [m.to_dict() for m in meal_targets],
                'fat_mode': assignment.fat_mode,
                'is_overridden': False,
            },
        )
        return plan

    def _generate_from_legacy(
        self,
        trainee: User,
        date: datetime.date,
    ) -> NutritionDayPlan | None:
        try:
            goal = NutritionGoal.objects.get(trainee=trainee)
        except NutritionGoal.DoesNotExist:
            return None

        meals_per_day = 4
        try:
            profile = trainee.profile  # type: ignore[union-attr]
            meals_per_day = profile.meals_per_day or 4
        except Exception:
            pass

        # Determine day type from program (use training_based default)
        is_training = self._is_training_day(trainee, date)
        day_type = (
            NutritionDayPlan.DayType.TRAINING
            if is_training
            else NutritionDayPlan.DayType.REST
        )

        meal_targets = self.apply_legacy_ruleset(goal, meals_per_day)

        snapshot = {
            'template_name': 'Legacy',
            'template_type': 'legacy',
            'nutrition_goal_id': goal.pk,
        }

        plan, _ = NutritionDayPlan.objects.update_or_create(
            trainee=trainee,
            date=date,
            defaults={
                'day_type': day_type,
                'template_snapshot': snapshot,
                'total_protein': goal.protein_goal,
                'total_carbs': goal.carbs_goal,
                'total_fat': goal.fat_goal,
                'total_calories': goal.calories_goal,
                'meals': [m.to_dict() for m in meal_targets],
                'fat_mode': NutritionTemplateAssignment.FatMode.TOTAL_FAT,
                'is_overridden': False,
            },
        )
        return plan

    def _is_training_day(self, trainee: User, date: datetime.date) -> bool:
        """Quick check whether the trainee has a programmed workout on *date*."""
        program = (
            Program.objects
            .filter(
                trainee=trainee,
                is_active=True,
                start_date__lte=date,
                end_date__gte=date,
            )
            .first()
        )
        if program is None:
            return False

        weekday_name = date.strftime('%A')
        schedule_data = program.schedule
        if not isinstance(schedule_data, dict):
            return False

        weeks = schedule_data.get('weeks', [])
        if not weeks:
            return False

        days_since_start = (date - program.start_date).days
        week_index = days_since_start // 7
        if week_index >= len(weeks):
            week_index = week_index % len(weeks)

        week = weeks[week_index]
        for day in week.get('days', []):
            if isinstance(day, dict) and day.get('day') == weekday_name:
                return bool(day.get('exercises'))
        return False

    def _apply_legacy_from_params(
        self,
        parameters: dict,
    ) -> list[MealTarget]:
        """Build even-split meals from parameters dict (legacy migration)."""
        meals_per_day = int(parameters.get('meals_per_day', 4))
        if meals_per_day < 1:
            meals_per_day = 4

        total_protein = int(parameters.get('total_protein', 0))
        total_carbs = int(parameters.get('total_carbs', 0))
        total_fat = int(parameters.get('total_fat', 0))
        total_calories = int(parameters.get('total_calories', 0))

        per_protein = total_protein // meals_per_day
        per_carbs = total_carbs // meals_per_day
        per_fat = total_fat // meals_per_day
        per_cals = total_calories // meals_per_day

        return [
            MealTarget(
                meal_number=i + 1,
                name=f"Meal {i + 1}",
                protein=per_protein,
                carbs=per_carbs,
                fat=per_fat,
                calories=per_cals,
            )
            for i in range(meals_per_day)
        ]

    def _apply_custom_ruleset(
        self,
        ruleset: dict,
        parameters: dict,
        day_type: str,
    ) -> list[MealTarget]:
        """Apply a trainer-defined custom ruleset.

        Expected ruleset structure::

            {
                "day_types": {
                    "training": {
                        "meals": [
                            {"name": "Pre-Workout", "protein": 40, "carbs": 60, "fat": 10},
                            ...
                        ]
                    },
                    "rest": { "meals": [...] }
                },
                "default_meals": [...]       # fallback
            }
        """
        day_types: dict = ruleset.get('day_types', {})
        day_config = day_types.get(day_type, {})
        meals_data: list[dict] = day_config.get('meals', [])

        if not meals_data:
            meals_data = ruleset.get('default_meals', [])

        if not meals_data:
            return self._apply_legacy_from_params(parameters)

        targets: list[MealTarget] = []
        for i, meal in enumerate(meals_data):
            protein = int(meal.get('protein', 0))
            carbs = int(meal.get('carbs', 0))
            fat = int(meal.get('fat', 0))
            calories = int(
                meal.get(
                    'calories',
                    protein * 4 + carbs * 4 + fat * 9,
                )
            )
            targets.append(
                MealTarget(
                    meal_number=i + 1,
                    name=str(meal.get('name', f'Meal {i + 1}')),
                    protein=protein,
                    carbs=carbs,
                    fat=fat,
                    calories=calories,
                )
            )
        return targets
