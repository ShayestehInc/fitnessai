"""
Macro Calculator Service for calculating personalized nutrition goals.
Uses the Mifflin-St Jeor equation for BMR calculation.
"""
from __future__ import annotations

from typing import Any, Optional, TYPE_CHECKING
from dataclasses import dataclass

if TYPE_CHECKING:
    from accounts.models import UserProfile


@dataclass
class MacroGoals:
    """Data class for macro nutrition goals."""
    protein: int
    carbs: int
    fat: int
    calories: int
    per_meal_protein: int
    per_meal_carbs: int
    per_meal_fat: int


class MacroCalculatorService:
    """
    Service for calculating personalized macro nutrition goals.

    Uses Mifflin-St Jeor equation:
    - Male BMR: (10 × weight in kg) + (6.25 × height in cm) − (5 × age) + 5
    - Female BMR: (10 × weight in kg) + (6.25 × height in cm) − (5 × age) − 161

    Activity multipliers:
    - Sedentary: 1.2
    - Lightly Active: 1.375
    - Moderately Active: 1.55
    - Very Active: 1.725
    - Extremely Active: 1.9

    Goal adjustments:
    - Build Muscle: +300 calories
    - Fat Loss: -500 calories
    - Recomp: 0 calories

    Macro distribution by diet type:
    - Low Carb: 35% protein, 25% carbs, 40% fat
    - Balanced: 30% protein, 40% carbs, 30% fat
    - High Carb: 25% protein, 50% carbs, 25% fat
    """

    # Activity level multipliers
    ACTIVITY_MULTIPLIERS = {
        'sedentary': 1.2,
        'lightly_active': 1.375,
        'moderately_active': 1.55,
        'very_active': 1.725,
        'extremely_active': 1.9,
    }

    # Goal calorie adjustments
    GOAL_ADJUSTMENTS = {
        'build_muscle': 300,
        'fat_loss': -500,
        'recomp': 0,
    }

    # Macro distribution percentages by diet type
    MACRO_DISTRIBUTIONS = {
        'low_carb': {
            'protein_pct': 0.35,
            'carbs_pct': 0.25,
            'fat_pct': 0.40,
        },
        'balanced': {
            'protein_pct': 0.30,
            'carbs_pct': 0.40,
            'fat_pct': 0.30,
        },
        'high_carb': {
            'protein_pct': 0.25,
            'carbs_pct': 0.50,
            'fat_pct': 0.25,
        },
    }

    # Calories per gram
    PROTEIN_CALS_PER_GRAM = 4
    CARBS_CALS_PER_GRAM = 4
    FAT_CALS_PER_GRAM = 9

    def calculate_bmr(
        self,
        sex: str,
        weight_kg: float,
        height_cm: float,
        age: int
    ) -> float:
        """
        Calculate Basal Metabolic Rate using Mifflin-St Jeor equation.

        Args:
            sex: 'male' or 'female'
            weight_kg: Weight in kilograms
            height_cm: Height in centimeters
            age: Age in years

        Returns:
            BMR in calories
        """
        base = (10 * weight_kg) + (6.25 * height_cm) - (5 * age)

        if sex == 'male':
            return base + 5
        else:
            return base - 161

    def calculate_tdee(
        self,
        bmr: float,
        activity_level: str
    ) -> float:
        """
        Calculate Total Daily Energy Expenditure.

        Args:
            bmr: Basal Metabolic Rate
            activity_level: Activity level key

        Returns:
            TDEE in calories
        """
        multiplier = self.ACTIVITY_MULTIPLIERS.get(activity_level, 1.55)
        return bmr * multiplier

    def calculate_target_calories(
        self,
        tdee: float,
        goal: str
    ) -> int:
        """
        Calculate target calories based on goal.

        Args:
            tdee: Total Daily Energy Expenditure
            goal: Goal key (build_muscle, fat_loss, recomp)

        Returns:
            Target daily calories
        """
        adjustment = self.GOAL_ADJUSTMENTS.get(goal, 0)
        return int(round(tdee + adjustment))

    def calculate_macros(
        self,
        calories: int,
        diet_type: str
    ) -> tuple[int, int, int]:
        """
        Calculate macro grams from calorie target and diet type.

        Args:
            calories: Target daily calories
            diet_type: Diet type key (low_carb, balanced, high_carb)

        Returns:
            Tuple of (protein_g, carbs_g, fat_g)
        """
        distribution = self.MACRO_DISTRIBUTIONS.get(diet_type, self.MACRO_DISTRIBUTIONS['balanced'])

        protein_cals = calories * distribution['protein_pct']
        carbs_cals = calories * distribution['carbs_pct']
        fat_cals = calories * distribution['fat_pct']

        protein_g = int(round(protein_cals / self.PROTEIN_CALS_PER_GRAM))
        carbs_g = int(round(carbs_cals / self.CARBS_CALS_PER_GRAM))
        fat_g = int(round(fat_cals / self.FAT_CALS_PER_GRAM))

        return protein_g, carbs_g, fat_g

    def calculate_goals(
        self,
        sex: str,
        weight_kg: float,
        height_cm: float,
        age: int,
        activity_level: str,
        goal: str,
        diet_type: str,
        meals_per_day: int = 4
    ) -> MacroGoals:
        """
        Calculate complete macro goals from profile data.

        Args:
            sex: 'male' or 'female'
            weight_kg: Weight in kilograms
            height_cm: Height in centimeters
            age: Age in years
            activity_level: Activity level key
            goal: Goal key
            diet_type: Diet type key
            meals_per_day: Number of meals per day (2-6)

        Returns:
            MacroGoals dataclass with all calculated values
        """
        # Calculate BMR → TDEE → Target Calories
        bmr = self.calculate_bmr(sex, weight_kg, height_cm, age)
        tdee = self.calculate_tdee(bmr, activity_level)
        calories = self.calculate_target_calories(tdee, goal)

        # Calculate macros
        protein, carbs, fat = self.calculate_macros(calories, diet_type)

        # Calculate per-meal targets
        per_meal_protein = int(round(protein / meals_per_day))
        per_meal_carbs = int(round(carbs / meals_per_day))
        per_meal_fat = int(round(fat / meals_per_day))

        return MacroGoals(
            protein=protein,
            carbs=carbs,
            fat=fat,
            calories=calories,
            per_meal_protein=per_meal_protein,
            per_meal_carbs=per_meal_carbs,
            per_meal_fat=per_meal_fat,
        )

    def calculate_goals_from_profile(self, profile: UserProfile) -> MacroGoals | None:
        """
        Calculate macro goals from a UserProfile instance.

        Args:
            profile: UserProfile model instance

        Returns:
            MacroGoals if all required fields are present, None otherwise
        """
        # Check required fields
        if not all([
            profile.sex,
            profile.weight_kg,
            profile.height_cm,
            profile.age
        ]):
            return None

        return self.calculate_goals(
            sex=profile.sex,
            weight_kg=profile.weight_kg,
            height_cm=profile.height_cm,
            age=profile.age,
            activity_level=profile.activity_level,
            goal=profile.goal,
            diet_type=profile.diet_type,
            meals_per_day=profile.meals_per_day,
        )
