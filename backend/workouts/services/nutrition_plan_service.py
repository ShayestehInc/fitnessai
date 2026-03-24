"""
Nutrition Plan Service — generates per-date NutritionDayPlans
from a trainee's active NutritionTemplateAssignment.

Supports legacy (flat NutritionGoal), SHREDDED, MASSIVE, CARB_CYCLING,
and custom template rulesets.
"""
from __future__ import annotations

import datetime
import logging
from dataclasses import dataclass, field
from typing import Any, TYPE_CHECKING

from django.db import transaction
from django.db.models import Avg, Count, Q
from django.utils import timezone

from workouts.models import (
    DecisionLog,
    MealLog,
    NutritionDayPlan,
    NutritionGoal,
    NutritionTemplate,
    NutritionTemplateAssignment,
    Program,
    TrainingPlan,
    WeightCheckIn,
)

logger = logging.getLogger(__name__)

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
        max_days = 90
        range_days = (end_date - start_date).days
        if range_days > max_days:
            raise ValueError(
                f"Date range too large: {range_days} days (max {max_days})."
            )

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

        if template.template_type == NutritionTemplate.TemplateType.SHREDDED:
            return self._apply_shredded_ruleset(parameters, day_type)

        if template.template_type == NutritionTemplate.TemplateType.MASSIVE:
            return self._apply_massive_ruleset(parameters, day_type)

        if template.template_type == NutritionTemplate.TemplateType.CARB_CYCLING:
            return self._apply_carb_cycling_ruleset(parameters, day_type)

        if template.template_type == NutritionTemplate.TemplateType.MACRO_EBOOK:
            return self._apply_macro_ebook_ruleset(parameters, day_type)

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

        # Enrich parameters with profile data for LBM-based templates
        parameters = dict(assignment.parameters)
        if template.template_type in (
            NutritionTemplate.TemplateType.SHREDDED,
            NutritionTemplate.TemplateType.MASSIVE,
        ):
            parameters = self._enrich_with_profile(trainee, parameters)

        meal_targets = self.apply_template_ruleset(
            template, parameters, day_type,
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

        plan, created = NutritionDayPlan.objects.update_or_create(
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

        # Log the decision
        if created:
            self._log_nutrition_decision(
                trainee=trainee,
                date=date,
                template=template,
                day_type=day_type,
                parameters=parameters,
                totals={
                    'protein': total_protein,
                    'carbs': total_carbs,
                    'fat': total_fat,
                    'calories': total_calories,
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
        except AttributeError:
            pass  # No profile relation on this user

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

    @staticmethod
    def _enrich_with_profile(trainee: User, parameters: dict) -> dict:
        """Merge UserProfile fields into parameters for LBM-based templates.

        Assignment parameters take precedence over profile values.
        """
        import logging
        logger = logging.getLogger(__name__)
        try:
            profile = trainee.profile  # type: ignore[union-attr]
        except AttributeError:
            logger.debug("No profile for trainee %s, skipping enrichment", trainee.pk)
            return parameters

        defaults: dict[str, float | str | int] = {}
        if profile.sex:
            defaults['sex'] = profile.sex
        if profile.height_cm:
            defaults['height_cm'] = float(profile.height_cm)
        if profile.age:
            defaults['age'] = profile.age
        if profile.activity_level:
            defaults['activity_level'] = profile.activity_level
        if profile.body_fat_percentage:
            defaults['body_fat_pct'] = float(profile.body_fat_percentage)
        if profile.weight_kg and 'body_weight_kg' not in parameters and 'body_weight_lbs' not in parameters:
            defaults['body_weight_kg'] = float(profile.weight_kg)

        # Parameters from assignment override profile defaults
        merged = {**defaults, **parameters}
        return merged

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

    def _apply_shredded_ruleset(
        self,
        parameters: dict,
        day_type: str,
    ) -> list[MealTarget]:
        """Apply the SHREDDED (fat-loss) formula engine.

        Uses LBM-based macro calculation with day-type-specific carb cycling.
        """
        import logging

        from workouts.services.macro_calculator import MacroCalculatorService

        logger = logging.getLogger(__name__)
        calc = MacroCalculatorService()

        sex = str(parameters.get('sex', 'male'))
        height_cm = float(parameters.get('height_cm', 175.0))
        age = int(parameters.get('age', 30))
        activity_level = str(
            parameters.get('activity_level', 'moderately_active')
        )
        meals_per_day = int(parameters.get('meals_per_day', 6))

        # Map day types: SHREDDED uses low/medium/high carb
        # If the incoming day_type is training/rest, map it
        shredded_day_type = day_type
        if day_type in ('training', 'training_day'):
            shredded_day_type = 'high_carb'
        elif day_type in ('rest', 'rest_day'):
            shredded_day_type = 'low_carb'
        elif day_type not in ('low_carb', 'medium_carb', 'high_carb'):
            shredded_day_type = 'medium_carb'

        try:
            result = calc.calculate_shredded_macros(
                parameters=parameters,
                day_type=shredded_day_type,
                sex=sex,
                height_cm=height_cm,
                age=age,
                activity_level=activity_level,
                meals_per_day=meals_per_day,
            )
        except ValueError as exc:
            logger.warning("SHREDDED calculation failed: %s", exc)
            return self._apply_legacy_from_params(parameters)

        return [
            MealTarget(
                meal_number=m.meal_number,
                name=m.name,
                protein=m.protein,
                carbs=m.carbs,
                fat=m.fat,
                calories=m.calories,
            )
            for m in result.meals
        ]

    def _apply_massive_ruleset(
        self,
        parameters: dict,
        day_type: str,
    ) -> list[MealTarget]:
        """Apply the MASSIVE (muscle-gain) formula engine.

        Uses LBM-based macro calculation with training/rest day splits.
        """
        import logging

        from workouts.services.macro_calculator import MacroCalculatorService

        logger = logging.getLogger(__name__)
        calc = MacroCalculatorService()

        sex = str(parameters.get('sex', 'male'))
        height_cm = float(parameters.get('height_cm', 175.0))
        age = int(parameters.get('age', 30))
        activity_level = str(
            parameters.get('activity_level', 'moderately_active')
        )
        meals_per_day = int(parameters.get('meals_per_day', 6))

        # Map day types: MASSIVE uses training/rest
        massive_day_type = day_type
        if day_type in ('high_carb', 'medium_carb'):
            massive_day_type = 'training_day'
        elif day_type in ('low_carb',):
            massive_day_type = 'rest_day'
        elif day_type not in ('training', 'training_day', 'rest', 'rest_day'):
            massive_day_type = 'rest_day'

        try:
            result = calc.calculate_massive_macros(
                parameters=parameters,
                day_type=massive_day_type,
                sex=sex,
                height_cm=height_cm,
                age=age,
                activity_level=activity_level,
                meals_per_day=meals_per_day,
            )
        except ValueError as exc:
            logger.warning("MASSIVE calculation failed: %s", exc)
            return self._apply_legacy_from_params(parameters)

        return [
            MealTarget(
                meal_number=m.meal_number,
                name=m.name,
                protein=m.protein,
                carbs=m.carbs,
                fat=m.fat,
                calories=m.calories,
            )
            for m in result.meals
        ]

    def _apply_carb_cycling_ruleset(
        self,
        parameters: dict,
        day_type: str,
    ) -> list[MealTarget]:
        """Apply the CARB_CYCLING formula engine.

        Day-type macro splits:
        - high_carb / training: 40P / 40C / 20F
        - medium_carb:          40P / 30C / 30F
        - low_carb / rest:      45P / 15C / 40F

        Uses body weight to compute total calories via activity multiplier.
        """
        bw_kg = float(parameters.get('body_weight_kg', 0))
        bw_lbs = float(parameters.get('body_weight_lbs', 0))
        if bw_kg <= 0 and bw_lbs > 0:
            bw_kg = bw_lbs / 2.205
        if bw_kg <= 0:
            bw_kg = 75.0  # fallback

        activity_level = str(parameters.get('activity_level', 'moderately_active'))
        meals_per_day = int(parameters.get('meals_per_day', 4))
        if meals_per_day < 1:
            meals_per_day = 4

        # BMR estimate (Mifflin-St Jeor simplified)
        sex = str(parameters.get('sex', 'male'))
        height_cm = float(parameters.get('height_cm', 175.0))
        age = int(parameters.get('age', 30))

        if sex == 'female':
            bmr = 10 * bw_kg + 6.25 * height_cm - 5 * age - 161
        else:
            bmr = 10 * bw_kg + 6.25 * height_cm - 5 * age + 5

        # Activity multiplier
        multipliers = {
            'sedentary': 1.2,
            'lightly_active': 1.375,
            'moderately_active': 1.55,
            'very_active': 1.725,
            'extremely_active': 1.9,
        }
        tdee = bmr * multipliers.get(activity_level, 1.55)

        # Carb cycling day-type ratios
        carb_day = day_type
        if day_type in ('training', 'training_day'):
            carb_day = 'high_carb'
        elif day_type in ('rest', 'rest_day'):
            carb_day = 'low_carb'
        elif day_type not in ('low_carb', 'medium_carb', 'high_carb'):
            carb_day = 'medium_carb'

        if carb_day == 'high_carb':
            p_pct, c_pct, f_pct = 0.40, 0.40, 0.20
            cal_adjust = 1.05  # slight surplus on high days
        elif carb_day == 'medium_carb':
            p_pct, c_pct, f_pct = 0.40, 0.30, 0.30
            cal_adjust = 1.0
        else:  # low_carb
            p_pct, c_pct, f_pct = 0.45, 0.15, 0.40
            cal_adjust = 0.90  # slight deficit on low days

        total_calories = int(tdee * cal_adjust)
        total_protein = int((total_calories * p_pct) / 4)
        total_carbs = int((total_calories * c_pct) / 4)
        total_fat = int((total_calories * f_pct) / 9)

        # Distribute evenly across meals
        per_p = total_protein // meals_per_day
        per_c = total_carbs // meals_per_day
        per_f = total_fat // meals_per_day
        per_cal = total_calories // meals_per_day

        return [
            MealTarget(
                meal_number=i + 1,
                name=f"Meal {i + 1}",
                protein=per_p,
                carbs=per_c,
                fat=per_f,
                calories=per_cal,
            )
            for i in range(meals_per_day)
        ]

    def _apply_macro_ebook_ruleset(
        self,
        parameters: dict,
        day_type: str,
    ) -> list[MealTarget]:
        """
        Macro Ebook: steady macros with smart timing (Nutrition Spec V1.2 §8).

        - 4-8 meals per day, 3-6 hours apart
        - Pre-workout fat cap: 10-15g
        - Intra-workout only if training > 60 min
        - Carb-to-fat swap math: fat_g = (carb_g × 4) / 9
        - Phase guardrails: 0.5-1% BW/week loss, 6-16 week phases
        """
        from workouts.services.macro_calculator import MacroCalculatorService

        calc = MacroCalculatorService()

        sex = parameters.get('sex', 'male')
        weight_kg = float(parameters.get('body_weight_kg', 80))
        height_cm = float(parameters.get('height_cm', 175))
        age = int(parameters.get('age', 30))
        activity_level = parameters.get('activity_level', 'moderately_active')
        meals_per_day = int(parameters.get('meals_per_day', 5))
        goal = parameters.get('goal', 'recomp')

        bmr = calc.compute_bmr(sex=sex, weight_kg=weight_kg, height_cm=height_cm, age=age)
        tdee = calc.compute_tdee(bmr=bmr, activity_level=activity_level)

        # Goal adjustment
        if goal == 'fat_loss':
            total_cal = int(tdee * 0.82)  # 18% deficit
        elif goal == 'build_muscle':
            total_cal = int(tdee * 1.10)  # 10% surplus
        else:
            total_cal = int(tdee)

        # Protein: 0.9 g/lb of body weight
        weight_lbs = weight_kg * 2.20462
        protein_g = int(weight_lbs * 0.9)

        # Day-type carb/fat split
        protein_cal = protein_g * 4
        remaining_cal = total_cal - protein_cal

        if day_type in ('training', 'high_carb'):
            carb_pct = 0.55
        elif day_type in ('rest', 'low_carb'):
            carb_pct = 0.30
        else:
            carb_pct = 0.42

        carb_cal = int(remaining_cal * carb_pct)
        fat_cal = remaining_cal - carb_cal

        carb_g = carb_cal // 4
        fat_g = fat_cal // 9

        # Distribute evenly across meals
        per_p = protein_g // meals_per_day
        per_c = carb_g // meals_per_day
        per_f = fat_g // meals_per_day
        per_cal = (per_p * 4) + (per_c * 4) + (per_f * 9)

        # Pre-workout fat cap (meal before workout = lower fat)
        meals = []
        for i in range(meals_per_day):
            meal_fat = per_f
            meal_carbs = per_c
            # If this is the pre-workout meal (typically meal 2 or 3), cap fat at 15g
            is_pre_workout = (i == (meals_per_day // 2 - 1)) and day_type in ('training', 'high_carb')
            if is_pre_workout and meal_fat > 15:
                excess_fat_cal = (meal_fat - 15) * 9
                meal_fat = 15
                # Convert excess fat calories to carbs
                meal_carbs += excess_fat_cal // 4

            meal_cal = (per_p * 4) + (meal_carbs * 4) + (meal_fat * 9)

            meal_names = ['Breakfast', 'Mid-Morning', 'Lunch', 'Afternoon', 'Dinner',
                          'Evening', 'Late Night', 'Snack']
            meals.append(MealTarget(
                meal_number=i + 1,
                name=meal_names[i] if i < len(meal_names) else f'Meal {i + 1}',
                protein=per_p,
                carbs=meal_carbs,
                fat=meal_fat,
                calories=meal_cal,
            ))

        return meals

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

    @staticmethod
    def _log_nutrition_decision(
        *,
        trainee: User,
        date: datetime.date,
        template: NutritionTemplate,
        day_type: str,
        parameters: dict,
        totals: dict[str, int],
    ) -> None:
        """Log nutrition day plan generation to DecisionLog."""
        try:
            DecisionLog.objects.create(
                actor_type=DecisionLog.ActorType.SYSTEM,
                decision_type='nutrition_day_plan_generated',
                context={
                    'trainee_id': trainee.pk,
                    'date': str(date),
                },
                inputs_snapshot={
                    'template_id': template.pk,
                    'template_type': template.template_type,
                    'day_type': day_type,
                    'parameters': {
                        k: v for k, v in parameters.items()
                        if isinstance(v, (int, float, str, bool))
                    },
                },
                constraints_applied={
                    'template_type': template.template_type,
                    'day_type': day_type,
                },
                options_considered=[],
                final_choice=totals,
                reason_codes=['nutrition_plan_generated'],
            )
        except Exception:
            logger.exception(
                "Failed to log nutrition decision for trainee %s on %s",
                trainee.pk, date,
            )


# ---------------------------------------------------------------------------
# AI-Curated Nutrition Assignment (v6.5 Nutrition Spec V1.2)
# ---------------------------------------------------------------------------

@dataclass(frozen=True)
class NutritionContext:
    """Full trainee context gathered for AI-curated nutrition plan generation."""
    # Profile
    age: int | None = None
    sex: str = ''
    weight_kg: float | None = None
    weight_lbs: float | None = None
    height_cm: float | None = None
    body_fat_pct: float | None = None
    lbm_lbs: float | None = None
    activity_level: str = ''
    goal: str = ''
    diet_type: str = ''
    # Current nutrition state
    current_template_type: str = ''
    current_template_name: str = ''
    current_calories: int = 0
    current_protein: int = 0
    current_carbs: int = 0
    current_fat: int = 0
    current_fat_mode: str = 'total_fat'
    # Training schedule
    training_days_per_week: int = 0
    training_day_names: list[str] = field(default_factory=list)
    # Weight trend
    weight_history: list[dict[str, Any]] = field(default_factory=list)
    weight_trend: str = ''  # losing, gaining, stable
    weight_rate_per_week_kg: float = 0.0
    # Adherence (last 14 days)
    meals_logged_14d: int = 0
    meals_planned_14d: int = 0
    adherence_pct: float = 0.0
    # Preferences
    meals_per_day: int = 4
    trainer_notes: str = ''


@dataclass(frozen=True)
class CuratedNutritionResult:
    """Result of AI-curated nutrition plan generation."""
    assignment_id: str
    template_type: str
    template_name: str
    weekly_preview: list[dict[str, Any]]
    reasoning: str
    decision_log_id: str


def gather_nutrition_context(trainee_id: int) -> NutritionContext:
    """
    Gather comprehensive trainee context for AI-curated nutrition assignment.
    Queries profile, current nutrition, training schedule, weight trends, adherence.
    """
    from users.models import User

    trainee = User.objects.select_related('profile').get(pk=trainee_id)
    profile = getattr(trainee, 'profile', None)

    # Profile data
    age = getattr(profile, 'age', None)
    sex = getattr(profile, 'sex', '')
    weight_kg = getattr(profile, 'weight_kg', None)
    height_cm = getattr(profile, 'height_cm', None)
    body_fat_pct = getattr(profile, 'body_fat_percentage', None)
    activity_level = getattr(profile, 'activity_level', '')
    goal = getattr(profile, 'goal', '')
    diet_type = getattr(profile, 'diet_type', '')
    meals_per_day = getattr(profile, 'meals_per_day', 4) or 4

    # Compute weight in lbs and LBM
    weight_lbs = round(weight_kg * 2.20462, 1) if weight_kg else None
    lbm_lbs: float | None = None
    if weight_lbs and body_fat_pct:
        lbm_lbs = round(weight_lbs * (1 - body_fat_pct / 100), 1)

    # Current nutrition assignment
    current_template_type = ''
    current_template_name = ''
    current_calories = 0
    current_protein = 0
    current_carbs = 0
    current_fat = 0
    current_fat_mode = 'total_fat'

    active_assignment = (
        NutritionTemplateAssignment.objects
        .filter(trainee_id=trainee_id, is_active=True)
        .select_related('template')
        .first()
    )
    if active_assignment:
        current_template_type = active_assignment.template.template_type
        current_template_name = active_assignment.template.name
        current_fat_mode = active_assignment.fat_mode

        # Get most recent day plan for current macros
        recent_plan = (
            NutritionDayPlan.objects
            .filter(trainee_id=trainee_id)
            .order_by('-date')
            .first()
        )
        if recent_plan:
            current_calories = recent_plan.total_calories
            current_protein = recent_plan.total_protein
            current_carbs = recent_plan.total_carbs
            current_fat = recent_plan.total_fat

    # Training schedule from active plan
    training_days_per_week = 0
    training_day_names: list[str] = []
    active_plan = (
        TrainingPlan.objects
        .filter(trainee_id=trainee_id, status='active')
        .select_related('split_template')
        .first()
    )
    if active_plan and active_plan.split_template:
        training_days_per_week = active_plan.split_template.days_per_week
        # Get session day names from first week
        from workouts.models import PlanSession
        sessions = list(
            PlanSession.objects
            .filter(week__plan=active_plan, week__week_number=1)
            .values_list('day_of_week', flat=True)
        )
        day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        training_day_names = [day_names[d] for d in sessions if 0 <= d < 7]

    # Weight trend (last 4 check-ins)
    weight_records = list(
        WeightCheckIn.objects
        .filter(trainee_id=trainee_id)
        .order_by('-date')[:4]
    )
    weight_history: list[dict[str, Any]] = [
        {'date': str(w.date), 'weight_kg': w.weight_kg}
        for w in weight_records
    ]

    weight_trend = 'stable'
    weight_rate = 0.0
    if len(weight_records) >= 2:
        first = weight_records[-1]  # oldest
        last = weight_records[0]    # newest
        days_diff = (last.date - first.date).days
        if days_diff > 0:
            kg_diff = last.weight_kg - first.weight_kg
            weight_rate = round(kg_diff / (days_diff / 7), 2)  # kg/week
            if weight_rate < -0.1:
                weight_trend = 'losing'
            elif weight_rate > 0.1:
                weight_trend = 'gaining'

    # Adherence (last 14 days)
    fourteen_days_ago = datetime.date.today() - datetime.timedelta(days=14)
    meals_logged = MealLog.objects.filter(
        trainee_id=trainee_id,
        date__gte=fourteen_days_ago,
    ).count()
    meals_planned = meals_per_day * 14
    adherence = round((meals_logged / meals_planned * 100), 1) if meals_planned > 0 else 0.0

    return NutritionContext(
        age=age,
        sex=sex,
        weight_kg=float(weight_kg) if weight_kg else None,
        weight_lbs=weight_lbs,
        height_cm=float(height_cm) if height_cm else None,
        body_fat_pct=float(body_fat_pct) if body_fat_pct else None,
        lbm_lbs=lbm_lbs,
        activity_level=activity_level,
        goal=goal,
        diet_type=diet_type,
        current_template_type=current_template_type,
        current_template_name=current_template_name,
        current_calories=current_calories,
        current_protein=current_protein,
        current_carbs=current_carbs,
        current_fat=current_fat,
        current_fat_mode=current_fat_mode,
        training_days_per_week=training_days_per_week,
        training_day_names=training_day_names,
        weight_history=weight_history,
        weight_trend=weight_trend,
        weight_rate_per_week_kg=weight_rate,
        meals_logged_14d=meals_logged,
        meals_planned_14d=meals_planned,
        adherence_pct=adherence,
        meals_per_day=meals_per_day,
    )


def curated_nutrition_build(
    *,
    trainee_id: int,
    trainer_id: int,
    trainer_notes: str = '',
    override_template_type: str = '',
    override_goal: str = '',
    progress_callback: Any | None = None,
) -> CuratedNutritionResult:
    """
    Generate a personalized nutrition plan for a trainee using AI.
    Gathers trainee context, calls AI for template selection, creates assignment,
    generates 7-day preview.
    """
    from users.models import User

    def _progress(step: str) -> None:
        if progress_callback and callable(progress_callback):
            progress_callback(step)

    _progress('Gathering trainee nutrition data...')
    ctx = gather_nutrition_context(trainee_id)

    _progress('Analyzing profile and selecting nutrition template...')

    # Deterministic template selection based on goal + context
    # AI enrichment can be added later; for now use rule-based logic
    template_type = override_template_type or _select_template_type(ctx, override_goal)

    # Find the system template
    template = NutritionTemplate.objects.filter(
        template_type=template_type,
        is_system=True,
    ).first()
    if template is None:
        # Fallback to any template of that type
        template = NutritionTemplate.objects.filter(
            template_type=template_type,
        ).first()
    if template is None:
        # Ultimate fallback: CARB_CYCLING
        template = NutritionTemplate.objects.filter(
            template_type='carb_cycling',
            is_system=True,
        ).first()
    if template is None:
        raise ValueError(f"No nutrition template found for type '{template_type}'.")

    _progress(f'Applying {template.name} template...')

    # Build parameters from trainee context
    parameters: dict[str, Any] = {
        'body_weight_kg': ctx.weight_kg or 80,
        'body_weight_lbs': ctx.weight_lbs or 176,
        'body_fat_pct': ctx.body_fat_pct or 20,
        'lbm_lbs': ctx.lbm_lbs or 141,
        'meals_per_day': ctx.meals_per_day,
        'sex': ctx.sex or 'male',
        'height_cm': ctx.height_cm or 175,
        'age': ctx.age or 30,
        'activity_level': ctx.activity_level or 'moderately_active',
    }

    # Determine day type schedule
    day_type_schedule = _build_day_type_schedule(ctx, template_type)

    # Determine fat mode
    fat_mode = 'added_fat' if template_type in ('shredded', 'massive') else 'total_fat'

    _progress('Creating nutrition assignment...')

    with transaction.atomic():
        # Deactivate existing assignment
        NutritionTemplateAssignment.objects.filter(
            trainee_id=trainee_id,
            is_active=True,
        ).update(is_active=False)

        # Create new assignment
        assignment = NutritionTemplateAssignment.objects.create(
            trainee_id=trainee_id,
            template=template,
            parameters=parameters,
            day_type_schedule=day_type_schedule,
            fat_mode=fat_mode,
            is_active=True,
        )

    _progress('Generating 7-day preview...')

    # Generate 7-day preview
    service = NutritionPlanService()
    trainee = User.objects.get(pk=trainee_id)
    today = datetime.date.today()
    # Start from next Monday for clean week view
    days_until_monday = (7 - today.weekday()) % 7
    if days_until_monday == 0:
        days_until_monday = 7
    start_date = today + datetime.timedelta(days=days_until_monday)

    weekly_preview: list[dict[str, Any]] = []
    for i in range(7):
        plan_date = start_date + datetime.timedelta(days=i)
        day_plan = service.get_or_generate_day_plan(trainee, plan_date)
        if day_plan:
            weekly_preview.append({
                'date': str(plan_date),
                'day_name': plan_date.strftime('%A'),
                'day_type': day_plan.day_type,
                'protein': day_plan.total_protein,
                'carbs': day_plan.total_carbs,
                'fat': day_plan.total_fat,
                'calories': day_plan.total_calories,
                'meals_count': len(day_plan.meals) if day_plan.meals else 0,
            })

    # Build reasoning
    reasoning = _build_reasoning(ctx, template_type, template.name, fat_mode, day_type_schedule)

    # Log decision
    decision_log = DecisionLog.objects.create(
        actor_type=DecisionLog.ActorType.SYSTEM,
        actor_id=trainer_id,
        decision_type='curated_nutrition_assigned',
        context={
            'trainee_id': trainee_id,
            'template_id': str(template.pk),
        },
        inputs_snapshot={
            'weight_kg': ctx.weight_kg,
            'body_fat_pct': ctx.body_fat_pct,
            'goal': ctx.goal,
            'activity_level': ctx.activity_level,
            'training_days': ctx.training_days_per_week,
            'weight_trend': ctx.weight_trend,
            'adherence_pct': ctx.adherence_pct,
            'trainer_notes': trainer_notes,
        },
        constraints_applied={
            'override_template_type': override_template_type,
            'override_goal': override_goal,
        },
        options_considered=[
            {'template_type': 'shredded', 'suitable_for': 'fat_loss'},
            {'template_type': 'massive', 'suitable_for': 'build_muscle'},
            {'template_type': 'carb_cycling', 'suitable_for': 'flexible'},
        ],
        final_choice={
            'template_type': template_type,
            'template_name': template.name,
            'fat_mode': fat_mode,
            'assignment_id': str(assignment.pk),
        },
        reason_codes=['curated_nutrition', f'template_{template_type}'],
    )

    return CuratedNutritionResult(
        assignment_id=str(assignment.pk),
        template_type=template_type,
        template_name=template.name,
        weekly_preview=weekly_preview,
        reasoning=reasoning,
        decision_log_id=str(decision_log.pk),
    )


def _select_template_type(ctx: NutritionContext, override_goal: str) -> str:
    """Select the best template type based on trainee context and goal."""
    goal = override_goal or ctx.goal

    if goal == 'fat_loss':
        # SHREDDED if body fat data available, otherwise carb cycling
        if ctx.body_fat_pct and ctx.lbm_lbs:
            return 'shredded'
        return 'carb_cycling'
    elif goal == 'build_muscle':
        # MASSIVE if body fat data available
        if ctx.body_fat_pct and ctx.lbm_lbs:
            return 'massive'
        return 'carb_cycling'
    elif goal == 'recomp':
        return 'carb_cycling'
    else:
        # General fitness / endurance / unknown
        return 'carb_cycling'


def _build_day_type_schedule(ctx: NutritionContext, template_type: str) -> dict[str, Any]:
    """Build day type schedule based on training schedule and template type."""
    if ctx.training_day_names:
        # Training-based scheduling
        if template_type == 'shredded':
            return {
                'method': 'training_based',
                'training_days': 'high_carb',
                'rest_days': 'low_carb',
            }
        elif template_type == 'massive':
            return {
                'method': 'training_based',
                'training_days': 'high_carb',
                'rest_days': 'medium_carb',
            }
        else:
            return {
                'method': 'training_based',
                'training_days': 'high_carb',
                'rest_days': 'low_carb',
            }
    else:
        # Default weekly rotation
        return {
            'method': 'weekly_rotation',
            'monday': 'high_carb',
            'tuesday': 'medium_carb',
            'wednesday': 'low_carb',
            'thursday': 'high_carb',
            'friday': 'medium_carb',
            'saturday': 'low_carb',
            'sunday': 'low_carb',
        }


def _build_reasoning(
    ctx: NutritionContext,
    template_type: str,
    template_name: str,
    fat_mode: str,
    schedule: dict[str, Any],
) -> str:
    """Build a human-readable reasoning string for the AI nutrition decision."""
    parts: list[str] = []

    parts.append(f"Selected {template_name} ({template_type.upper()}) template.")

    if template_type == 'shredded':
        parts.append(
            f"This is an LBM-based fat loss plan with a 22% caloric deficit. "
            f"Based on {ctx.weight_lbs or '?'} lbs body weight and "
            f"{ctx.body_fat_pct or '?'}% body fat (LBM: {ctx.lbm_lbs or '?'} lbs)."
        )
    elif template_type == 'massive':
        parts.append(
            f"This is an LBM-based muscle gain plan with a 12% caloric surplus. "
            f"Based on {ctx.weight_lbs or '?'} lbs body weight and "
            f"{ctx.body_fat_pct or '?'}% body fat."
        )
    elif template_type == 'carb_cycling':
        parts.append("Flexible carb cycling with day-type-specific macro ratios.")

    if ctx.training_days_per_week > 0:
        parts.append(
            f"Training {ctx.training_days_per_week}x/week "
            f"({', '.join(ctx.training_day_names[:3])}{'...' if len(ctx.training_day_names) > 3 else ''})."
        )

    if ctx.weight_trend != 'stable':
        direction = 'losing' if ctx.weight_trend == 'losing' else 'gaining'
        parts.append(
            f"Current weight trend: {direction} "
            f"at {abs(ctx.weight_rate_per_week_kg)} kg/week."
        )

    fat_label = 'Added Fats Only' if fat_mode == 'added_fat' else 'Total Fat'
    parts.append(f"Fat tracking mode: {fat_label}.")

    return ' '.join(parts)
