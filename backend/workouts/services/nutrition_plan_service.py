"""
Nutrition Plan Service — generates per-date NutritionDayPlans
from a trainee's active NutritionTemplateAssignment.

Supports legacy (flat NutritionGoal), SHREDDED, MASSIVE, CARB_CYCLING,
and custom template rulesets.
"""
from __future__ import annotations

import datetime
import logging
from dataclasses import dataclass
from typing import TYPE_CHECKING

from django.db.models import Q

from workouts.models import (
    DecisionLog,
    NutritionDayPlan,
    NutritionGoal,
    NutritionTemplate,
    NutritionTemplateAssignment,
    Program,
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
