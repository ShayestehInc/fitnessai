"""
Macro Calculator Service for calculating personalized nutrition goals.
Uses the Mifflin-St Jeor equation for BMR calculation.
"""
from __future__ import annotations

from typing import TYPE_CHECKING
from dataclasses import dataclass

if TYPE_CHECKING:
    from accounts.models import UserProfile


@dataclass(frozen=True)
class MealMacros:
    """Per-meal macro targets."""
    meal_number: int
    name: str
    protein: int
    carbs: int
    fat: int
    calories: int


@dataclass(frozen=True)
class ShreddedMacroResult:
    """Result of SHREDDED (fat-loss) macro calculation."""
    total_calories: int
    total_protein: int
    total_carbs: int
    total_fat: int
    tdee: int
    deficit_pct: int
    lbm_kg: float
    lbm_lbs: float
    body_fat_pct: float
    day_type: str
    meals: list[MealMacros]


@dataclass(frozen=True)
class MassiveMacroResult:
    """Result of MASSIVE (muscle-gain) macro calculation."""
    total_calories: int
    total_protein: int
    total_carbs: int
    total_fat: int
    tdee: int
    surplus_pct: int
    lbm_kg: float
    lbm_lbs: float
    body_fat_pct: float
    day_type: str
    meals: list[MealMacros]


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

    @staticmethod
    def calculate_lbm(weight_kg: float, body_fat_pct: float) -> float:
        """Calculate Lean Body Mass in kg.

        Args:
            weight_kg: Total body weight in kilograms.
            body_fat_pct: Body fat percentage (e.g. 15.0 for 15%).

        Returns:
            Lean body mass in kilograms.

        Raises:
            ValueError: If body_fat_pct is outside 0-100.
        """
        if body_fat_pct < 0 or body_fat_pct > 100:
            raise ValueError(
                f"body_fat_pct must be between 0 and 100, got {body_fat_pct}"
            )
        return weight_kg * (1 - body_fat_pct / 100.0)

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

    # ------------------------------------------------------------------ #
    # LBM-based template engines (Phase 3)
    # ------------------------------------------------------------------ #

    # Weight bounds (kg)
    _MIN_WEIGHT_KG = 40.0   # ~88 lbs
    _MAX_WEIGHT_KG = 180.0  # ~396 lbs

    @staticmethod
    def estimate_body_fat(sex: str, weight_kg: float, height_cm: float) -> float:
        """Estimate body fat % using the Boer formula when not measured.

        Returns a conservative estimate used as a fallback.
        """
        if sex == 'male':
            lbm = (0.407 * weight_kg) + (0.267 * height_cm) - 19.2
        else:
            lbm = (0.252 * weight_kg) + (0.473 * height_cm) - 48.3

        if lbm <= 0 or lbm >= weight_kg:
            # Fallback: assume 20% male / 28% female
            return 20.0 if sex == 'male' else 28.0

        return round(((weight_kg - lbm) / weight_kg) * 100.0, 1)

    def _resolve_lbm_inputs(
        self,
        parameters: dict,
        sex: str = 'male',
        height_cm: float = 175.0,
        age: int = 30,
        activity_level: str = 'moderately_active',
    ) -> tuple[float, float, float]:
        """Extract and compute weight_kg, body_fat_pct, lbm_kg from params.

        Returns:
            (weight_kg, body_fat_pct, lbm_kg) — all in metric.

        Raises:
            ValueError: When weight is missing or LBM is non-positive.
        """
        # Accept lbs or kg
        weight_lbs = parameters.get('body_weight_lbs', 0)
        weight_kg = parameters.get('body_weight_kg', 0)
        if weight_lbs:
            weight_kg = float(weight_lbs) / 2.20462
        weight_kg = float(weight_kg)

        if weight_kg <= 0:
            raise ValueError("Weight is required for LBM-based templates.")

        # Clamp to safe range
        weight_kg = max(self._MIN_WEIGHT_KG, min(self._MAX_WEIGHT_KG, weight_kg))

        body_fat_pct = parameters.get('body_fat_pct')
        if body_fat_pct is None:
            body_fat_pct = self.estimate_body_fat(sex, weight_kg, height_cm)
        body_fat_pct = float(body_fat_pct)
        body_fat_pct = max(3.0, min(60.0, body_fat_pct))

        lbm_kg = self.calculate_lbm(weight_kg, body_fat_pct)
        if lbm_kg <= 0:
            raise ValueError(
                f"Invalid LBM result: {lbm_kg:.1f} kg. "
                "Check weight and body fat % values."
            )

        return weight_kg, body_fat_pct, lbm_kg

    def calculate_shredded_macros(
        self,
        parameters: dict,
        day_type: str,
        sex: str = 'male',
        height_cm: float = 175.0,
        age: int = 30,
        activity_level: str = 'moderately_active',
        meals_per_day: int = 6,
    ) -> ShreddedMacroResult:
        """Calculate SHREDDED (fat-loss) macros based on LBM.

        Protein: 1.3g per lb of LBM (high to preserve muscle in deficit)
        Deficit: 22% below TDEE
        Day types control carb/fat split (of remaining cals after protein):
          - low_carb:    25% carbs / 75% fat
          - medium_carb: 40% carbs / 60% fat
          - high_carb:   55% carbs / 45% fat
        """
        weight_kg, body_fat_pct, lbm_kg = self._resolve_lbm_inputs(
            parameters, sex, height_cm, age, activity_level,
        )
        lbm_lbs = lbm_kg * 2.20462

        # TDEE
        bmr = self.calculate_bmr(sex, weight_kg, height_cm, age)
        tdee = self.calculate_tdee(bmr, activity_level)

        # 22% deficit
        target_calories = int(round(tdee * 0.78))

        # Protein: 1.3g/lb LBM
        protein_g = int(round(lbm_lbs * 1.3))
        protein_cals = protein_g * self.PROTEIN_CALS_PER_GRAM

        # Remaining calories for carbs + fat
        remaining_cals = max(0, target_calories - protein_cals)

        # Day-type carb ratios (of remaining calories)
        carb_ratios = {
            'low_carb': 0.25,
            'medium_carb': 0.40,
            'high_carb': 0.55,
        }
        carb_ratio = carb_ratios.get(day_type, carb_ratios['medium_carb'])

        carbs_cals = remaining_cals * carb_ratio
        fat_cals = remaining_cals * (1 - carb_ratio)

        carbs_g = int(round(carbs_cals / self.CARBS_CALS_PER_GRAM))
        fat_g = int(round(fat_cals / self.FAT_CALS_PER_GRAM))

        # Recalculate actual calories
        actual_calories = (
            protein_g * self.PROTEIN_CALS_PER_GRAM
            + carbs_g * self.CARBS_CALS_PER_GRAM
            + fat_g * self.FAT_CALS_PER_GRAM
        )

        # Per-meal distribution
        meal_targets = self._distribute_meals(
            protein_g, carbs_g, fat_g, meals_per_day, front_load_carbs=True,
        )

        return ShreddedMacroResult(
            total_calories=actual_calories,
            total_protein=protein_g,
            total_carbs=carbs_g,
            total_fat=fat_g,
            tdee=int(round(tdee)),
            deficit_pct=22,
            lbm_kg=round(lbm_kg, 1),
            lbm_lbs=round(lbm_lbs, 1),
            body_fat_pct=body_fat_pct,
            day_type=day_type,
            meals=meal_targets,
        )

    def calculate_massive_macros(
        self,
        parameters: dict,
        day_type: str,
        sex: str = 'male',
        height_cm: float = 175.0,
        age: int = 30,
        activity_level: str = 'moderately_active',
        meals_per_day: int = 6,
    ) -> MassiveMacroResult:
        """Calculate MASSIVE (muscle-gain) macros based on LBM.

        Protein: 1.1g per lb of LBM
        Surplus: 12% above TDEE
        Day types (of remaining cals after protein):
          - training_day: 60% carbs / 40% fat
          - rest_day:     45% carbs / 55% fat
        """
        weight_kg, body_fat_pct, lbm_kg = self._resolve_lbm_inputs(
            parameters, sex, height_cm, age, activity_level,
        )
        lbm_lbs = lbm_kg * 2.20462

        # TDEE
        bmr = self.calculate_bmr(sex, weight_kg, height_cm, age)
        tdee = self.calculate_tdee(bmr, activity_level)

        # 12% surplus
        target_calories = int(round(tdee * 1.12))

        # Protein: 1.1g/lb LBM
        protein_g = int(round(lbm_lbs * 1.1))
        protein_cals = protein_g * self.PROTEIN_CALS_PER_GRAM

        remaining_cals = max(0, target_calories - protein_cals)

        # Day-type specific splits
        if day_type in ('training', 'training_day'):
            carb_ratio = 0.60
        else:
            carb_ratio = 0.45

        carbs_cals = remaining_cals * carb_ratio
        fat_cals = remaining_cals * (1 - carb_ratio)

        carbs_g = int(round(carbs_cals / self.CARBS_CALS_PER_GRAM))
        fat_g = int(round(fat_cals / self.FAT_CALS_PER_GRAM))

        actual_calories = (
            protein_g * self.PROTEIN_CALS_PER_GRAM
            + carbs_g * self.CARBS_CALS_PER_GRAM
            + fat_g * self.FAT_CALS_PER_GRAM
        )

        meal_targets = self._distribute_meals(
            protein_g, carbs_g, fat_g, meals_per_day, front_load_carbs=True,
        )

        return MassiveMacroResult(
            total_calories=actual_calories,
            total_protein=protein_g,
            total_carbs=carbs_g,
            total_fat=fat_g,
            tdee=int(round(tdee)),
            surplus_pct=12,
            lbm_kg=round(lbm_kg, 1),
            lbm_lbs=round(lbm_lbs, 1),
            body_fat_pct=body_fat_pct,
            day_type=day_type,
            meals=meal_targets,
        )

    def _distribute_meals(
        self,
        protein_g: int,
        carbs_g: int,
        fat_g: int,
        meals_per_day: int,
        front_load_carbs: bool = False,
    ) -> list[MealMacros]:
        """Distribute macros across meals.

        Protein is split evenly. If front_load_carbs is True,
        earlier meals get slightly more carbs (peri-workout focus).
        Fat is distributed to fill remaining calories.
        """
        if meals_per_day < 2:
            meals_per_day = 2
        if meals_per_day > 8:
            meals_per_day = 8

        per_protein = protein_g // meals_per_day
        protein_remainder = protein_g % meals_per_day
        per_fat = fat_g // meals_per_day
        fat_remainder = fat_g % meals_per_day

        meals: list[MealMacros] = []
        meal_names = self._get_meal_names(meals_per_day)

        if front_load_carbs and meals_per_day >= 3:
            # Front-load: first third of meals get 40% of carbs,
            # middle third gets 35%, last third gets 25%
            front_count = max(1, meals_per_day // 3)
            mid_count = max(1, meals_per_day // 3)
            back_count = meals_per_day - front_count - mid_count

            front_total = int(round(carbs_g * 0.40))
            mid_total = int(round(carbs_g * 0.35))
            back_total = carbs_g - front_total - mid_total

            front_per = front_total // front_count if front_count else 0
            front_rem = front_total % front_count if front_count else 0
            mid_per = mid_total // mid_count if mid_count else 0
            mid_rem = mid_total % mid_count if mid_count else 0
            back_per = back_total // back_count if back_count else 0
            back_rem = back_total % back_count if back_count else 0

            carb_idx_front = 0
            carb_idx_mid = 0
            carb_idx_back = 0

            for i in range(meals_per_day):
                mp = per_protein + (1 if i < protein_remainder else 0)
                mf = per_fat + (1 if i < fat_remainder else 0)

                if i < front_count:
                    mc = front_per + (1 if carb_idx_front < front_rem else 0)
                    carb_idx_front += 1
                elif i < front_count + mid_count:
                    mc = mid_per + (1 if carb_idx_mid < mid_rem else 0)
                    carb_idx_mid += 1
                else:
                    mc = back_per + (1 if carb_idx_back < back_rem else 0)
                    carb_idx_back += 1

                cals = (
                    mp * self.PROTEIN_CALS_PER_GRAM
                    + mc * self.CARBS_CALS_PER_GRAM
                    + mf * self.FAT_CALS_PER_GRAM
                )
                meals.append(MealMacros(
                    meal_number=i + 1,
                    name=meal_names[i],
                    protein=mp,
                    carbs=mc,
                    fat=mf,
                    calories=cals,
                ))
        else:
            per_carbs = carbs_g // meals_per_day
            carbs_remainder = carbs_g % meals_per_day
            for i in range(meals_per_day):
                mp = per_protein + (1 if i < protein_remainder else 0)
                mc = per_carbs + (1 if i < carbs_remainder else 0)
                mf = per_fat + (1 if i < fat_remainder else 0)
                cals = (
                    mp * self.PROTEIN_CALS_PER_GRAM
                    + mc * self.CARBS_CALS_PER_GRAM
                    + mf * self.FAT_CALS_PER_GRAM
                )
                meals.append(MealMacros(
                    meal_number=i + 1,
                    name=meal_names[i],
                    protein=mp,
                    carbs=mc,
                    fat=mf,
                    calories=cals,
                ))

        return meals

    @staticmethod
    def _get_meal_names(meals_per_day: int) -> list[str]:
        """Return contextual meal names based on count."""
        if meals_per_day <= 3:
            names = ['Breakfast', 'Lunch', 'Dinner']
        elif meals_per_day == 4:
            names = ['Breakfast', 'Lunch', 'Snack', 'Dinner']
        elif meals_per_day == 5:
            names = ['Breakfast', 'Mid-Morning', 'Lunch', 'Snack', 'Dinner']
        else:
            names = [
                'Breakfast', 'Mid-Morning', 'Lunch',
                'Afternoon Snack', 'Dinner', 'Evening Snack',
            ]
        # Pad if needed
        while len(names) < meals_per_day:
            names.append(f'Meal {len(names) + 1}')
        return names[:meals_per_day]

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
