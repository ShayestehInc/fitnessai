"""Unit tests for LBM-based macro calculation (Phase 3).

These tests verify the SHREDDED and MASSIVE formula engines with
known reference values. No database required.
"""
from unittest import TestCase

from workouts.services.macro_calculator import (
    MacroCalculatorService,
    MealMacros,
    MassiveMacroResult,
    ShreddedMacroResult,
)


class TestEstimateBodyFat(TestCase):
    """Tests for Boer formula body fat estimation."""

    def setUp(self) -> None:
        self.svc = MacroCalculatorService()

    def test_male_normal(self) -> None:
        """80kg male, 175cm → reasonable estimate around 15-25%."""
        bf = self.svc.estimate_body_fat('male', 80.0, 175.0)
        self.assertGreater(bf, 10.0)
        self.assertLess(bf, 30.0)

    def test_female_normal(self) -> None:
        """65kg female, 165cm → reasonable estimate around 20-35%."""
        bf = self.svc.estimate_body_fat('female', 65.0, 165.0)
        self.assertGreater(bf, 15.0)
        self.assertLess(bf, 40.0)

    def test_extreme_weight_fallback(self) -> None:
        """Very low weight should trigger LBM sanity check and fallback."""
        bf = self.svc.estimate_body_fat('male', 30.0, 175.0)
        # Should fallback to 20% for male when LBM > weight
        self.assertEqual(bf, 20.0)

    def test_female_fallback(self) -> None:
        """Tall, light female triggers LBM >= weight fallback."""
        # lbm = (0.252 * 40) + (0.473 * 200) - 48.3 = 10.08 + 94.6 - 48.3 = 56.38
        # 56.38 >= 40 → fallback to 28%
        bf = self.svc.estimate_body_fat('female', 40.0, 200.0)
        self.assertEqual(bf, 28.0)


class TestResolveLbmInputs(TestCase):
    """Tests for parameter resolution and LBM computation."""

    def setUp(self) -> None:
        self.svc = MacroCalculatorService()

    def test_weight_lbs_conversion(self) -> None:
        """body_weight_lbs should be converted to kg."""
        params = {'body_weight_lbs': 176.0, 'body_fat_pct': 15.0}
        weight_kg, bf, lbm = self.svc._resolve_lbm_inputs(params)
        self.assertAlmostEqual(weight_kg, 79.8, delta=0.5)
        self.assertEqual(bf, 15.0)
        self.assertAlmostEqual(lbm, 67.9, delta=0.5)

    def test_weight_kg_direct(self) -> None:
        """body_weight_kg should be used directly."""
        params = {'body_weight_kg': 80.0, 'body_fat_pct': 20.0}
        weight_kg, bf, lbm = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(weight_kg, 80.0)
        self.assertEqual(bf, 20.0)
        self.assertEqual(lbm, 64.0)  # 80 * (1 - 0.20)

    def test_missing_weight_raises(self) -> None:
        """No weight should raise ValueError."""
        with self.assertRaises(ValueError) as ctx:
            self.svc._resolve_lbm_inputs({})
        self.assertIn("Weight is required", str(ctx.exception))

    def test_missing_body_fat_uses_boer(self) -> None:
        """Missing body_fat_pct should fall back to Boer estimate."""
        params = {'body_weight_kg': 80.0}
        weight_kg, bf, lbm = self.svc._resolve_lbm_inputs(
            params, sex='male', height_cm=175.0,
        )
        self.assertGreater(bf, 5.0)
        self.assertLess(bf, 40.0)
        self.assertGreater(lbm, 0)

    def test_weight_clamp_low(self) -> None:
        """Weight below 40kg should clamp to 40kg."""
        params = {'body_weight_kg': 30.0, 'body_fat_pct': 15.0}
        weight_kg, _, _ = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(weight_kg, 40.0)

    def test_weight_clamp_high(self) -> None:
        """Weight above 180kg should clamp to 180kg."""
        params = {'body_weight_kg': 250.0, 'body_fat_pct': 15.0}
        weight_kg, _, _ = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(weight_kg, 180.0)

    def test_body_fat_clamp_low(self) -> None:
        """Body fat below 3% should clamp to 3%."""
        params = {'body_weight_kg': 80.0, 'body_fat_pct': 1.0}
        _, bf, _ = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(bf, 3.0)

    def test_body_fat_clamp_high(self) -> None:
        """Body fat above 60% should clamp to 60%."""
        params = {'body_weight_kg': 80.0, 'body_fat_pct': 75.0}
        _, bf, _ = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(bf, 60.0)

    def test_boundary_body_fat_3(self) -> None:
        """Body fat exactly 3% should pass without error."""
        params = {'body_weight_kg': 80.0, 'body_fat_pct': 3.0}
        _, bf, lbm = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(bf, 3.0)
        self.assertAlmostEqual(lbm, 77.6, delta=0.1)

    def test_boundary_body_fat_60(self) -> None:
        """Body fat exactly 60% should pass without error."""
        params = {'body_weight_kg': 80.0, 'body_fat_pct': 60.0}
        _, bf, lbm = self.svc._resolve_lbm_inputs(params)
        self.assertEqual(bf, 60.0)
        self.assertEqual(lbm, 32.0)


class TestShreddedMacros(TestCase):
    """Tests for SHREDDED formula with known reference values."""

    def setUp(self) -> None:
        self.svc = MacroCalculatorService()
        # Reference subject: 80kg male, 15% BF, 175cm, 30yo, moderate
        self.params = {
            'body_weight_kg': 80.0,
            'body_fat_pct': 15.0,
        }
        # LBM = 80 * 0.85 = 68kg = 149.9 lbs
        # Protein = 149.9 * 1.3 ≈ 195g
        # BMR (Mifflin-St Jeor male) = (10 * 80) + (6.25 * 175) - (5 * 30) - 5
        #   = 800 + 1093.75 - 150 - 5 = 1738.75
        # TDEE = 1738.75 * 1.55 ≈ 2695
        # Target = 2695 * 0.78 ≈ 2102
        # Protein cals = 195 * 4 = 780
        # Remaining = 2102 - 780 = 1322

    def test_returns_shredded_result(self) -> None:
        result = self.svc.calculate_shredded_macros(
            self.params, 'medium_carb',
        )
        self.assertIsInstance(result, ShreddedMacroResult)

    def test_deficit_applied(self) -> None:
        result = self.svc.calculate_shredded_macros(
            self.params, 'medium_carb',
        )
        self.assertEqual(result.deficit_pct, 22)
        self.assertLess(result.total_calories, result.tdee)
        # Should be roughly 22% less
        actual_deficit = 1 - result.total_calories / result.tdee
        self.assertAlmostEqual(actual_deficit, 0.22, delta=0.05)

    def test_protein_target(self) -> None:
        result = self.svc.calculate_shredded_macros(
            self.params, 'medium_carb',
        )
        # 68kg LBM = 149.9 lbs * 1.3 ≈ 195g
        self.assertAlmostEqual(result.total_protein, 195, delta=5)

    def test_low_carb_less_carbs(self) -> None:
        low = self.svc.calculate_shredded_macros(self.params, 'low_carb')
        high = self.svc.calculate_shredded_macros(self.params, 'high_carb')
        self.assertLess(low.total_carbs, high.total_carbs)
        self.assertGreater(low.total_fat, high.total_fat)

    def test_medium_carb_between(self) -> None:
        low = self.svc.calculate_shredded_macros(self.params, 'low_carb')
        med = self.svc.calculate_shredded_macros(self.params, 'medium_carb')
        high = self.svc.calculate_shredded_macros(self.params, 'high_carb')
        self.assertLess(low.total_carbs, med.total_carbs)
        self.assertLess(med.total_carbs, high.total_carbs)

    def test_lbm_values(self) -> None:
        result = self.svc.calculate_shredded_macros(
            self.params, 'medium_carb',
        )
        self.assertAlmostEqual(result.lbm_kg, 68.0, delta=0.1)
        self.assertEqual(result.body_fat_pct, 15.0)

    def test_meals_count(self) -> None:
        result = self.svc.calculate_shredded_macros(
            self.params, 'medium_carb', meals_per_day=4,
        )
        self.assertEqual(len(result.meals), 4)

    def test_meal_macros_sum_to_totals(self) -> None:
        """Per-meal macros must sum exactly to daily totals."""
        result = self.svc.calculate_shredded_macros(
            self.params, 'high_carb', meals_per_day=6,
        )
        total_p = sum(m.protein for m in result.meals)
        total_c = sum(m.carbs for m in result.meals)
        total_f = sum(m.fat for m in result.meals)
        self.assertEqual(total_p, result.total_protein)
        self.assertEqual(total_c, result.total_carbs)
        self.assertEqual(total_f, result.total_fat)

    def test_unknown_day_type_defaults_to_medium(self) -> None:
        """Unknown day type should default to medium_carb."""
        med = self.svc.calculate_shredded_macros(self.params, 'medium_carb')
        unk = self.svc.calculate_shredded_macros(self.params, 'unknown_type')
        self.assertEqual(med.total_carbs, unk.total_carbs)


class TestMassiveMacros(TestCase):
    """Tests for MASSIVE formula with known reference values."""

    def setUp(self) -> None:
        self.svc = MacroCalculatorService()
        self.params = {
            'body_weight_kg': 80.0,
            'body_fat_pct': 15.0,
        }

    def test_returns_massive_result(self) -> None:
        result = self.svc.calculate_massive_macros(
            self.params, 'training_day',
        )
        self.assertIsInstance(result, MassiveMacroResult)

    def test_surplus_applied(self) -> None:
        result = self.svc.calculate_massive_macros(
            self.params, 'training_day',
        )
        self.assertEqual(result.surplus_pct, 12)
        self.assertGreater(result.total_calories, result.tdee)
        actual_surplus = result.total_calories / result.tdee - 1
        self.assertAlmostEqual(actual_surplus, 0.12, delta=0.05)

    def test_protein_target(self) -> None:
        result = self.svc.calculate_massive_macros(
            self.params, 'training_day',
        )
        # 68kg LBM = 149.9 lbs * 1.1 ≈ 165g
        self.assertAlmostEqual(result.total_protein, 165, delta=5)

    def test_training_day_more_carbs(self) -> None:
        training = self.svc.calculate_massive_macros(
            self.params, 'training_day',
        )
        rest = self.svc.calculate_massive_macros(self.params, 'rest_day')
        self.assertGreater(training.total_carbs, rest.total_carbs)
        self.assertLess(training.total_fat, rest.total_fat)

    def test_meal_macros_sum_to_totals(self) -> None:
        result = self.svc.calculate_massive_macros(
            self.params, 'rest_day', meals_per_day=6,
        )
        total_p = sum(m.protein for m in result.meals)
        total_c = sum(m.carbs for m in result.meals)
        total_f = sum(m.fat for m in result.meals)
        self.assertEqual(total_p, result.total_protein)
        self.assertEqual(total_c, result.total_carbs)
        self.assertEqual(total_f, result.total_fat)

    def test_meals_count_default(self) -> None:
        result = self.svc.calculate_massive_macros(
            self.params, 'training_day',
        )
        self.assertEqual(len(result.meals), 6)


class TestDistributeMeals(TestCase):
    """Tests for meal distribution logic."""

    def setUp(self) -> None:
        self.svc = MacroCalculatorService()

    def test_even_distribution(self) -> None:
        """Evenly divisible macros should produce equal meals."""
        meals = self.svc._distribute_meals(120, 120, 60, 6)
        for m in meals:
            self.assertEqual(m.protein, 20)
            self.assertEqual(m.carbs, 20)
            self.assertEqual(m.fat, 10)

    def test_remainder_distribution(self) -> None:
        """Non-divisible macros should distribute remainders."""
        meals = self.svc._distribute_meals(125, 125, 65, 6)
        total_p = sum(m.protein for m in meals)
        total_c = sum(m.carbs for m in meals)
        total_f = sum(m.fat for m in meals)
        self.assertEqual(total_p, 125)
        self.assertEqual(total_c, 125)
        self.assertEqual(total_f, 65)

    def test_two_meals(self) -> None:
        """2 meals should work without front-loading."""
        meals = self.svc._distribute_meals(100, 100, 50, 2)
        self.assertEqual(len(meals), 2)
        self.assertEqual(sum(m.protein for m in meals), 100)

    def test_front_load_carbs(self) -> None:
        """Front-loaded carbs: first meals should have more carbs."""
        meals = self.svc._distribute_meals(
            120, 120, 60, 6, front_load_carbs=True,
        )
        front_carbs = meals[0].carbs + meals[1].carbs
        back_carbs = meals[4].carbs + meals[5].carbs
        self.assertGreater(front_carbs, back_carbs)

    def test_meal_names(self) -> None:
        meals = self.svc._distribute_meals(120, 120, 60, 3)
        self.assertEqual(meals[0].name, 'Breakfast')
        self.assertEqual(meals[1].name, 'Lunch')
        self.assertEqual(meals[2].name, 'Dinner')

    def test_clamp_meals_min(self) -> None:
        """meals_per_day < 2 should clamp to 2."""
        meals = self.svc._distribute_meals(100, 100, 50, 1)
        self.assertEqual(len(meals), 2)

    def test_clamp_meals_max(self) -> None:
        """meals_per_day > 8 should clamp to 8."""
        meals = self.svc._distribute_meals(100, 100, 50, 10)
        self.assertEqual(len(meals), 8)

    def test_all_meals_are_meal_macros(self) -> None:
        meals = self.svc._distribute_meals(100, 100, 50, 4)
        for m in meals:
            self.assertIsInstance(m, MealMacros)
            self.assertGreater(m.calories, 0)
            self.assertGreater(m.meal_number, 0)


class TestMealNames(TestCase):
    def setUp(self) -> None:
        self.svc = MacroCalculatorService()

    def test_three_meals(self) -> None:
        names = self.svc._get_meal_names(3)
        self.assertEqual(names, ['Breakfast', 'Lunch', 'Dinner'])

    def test_six_meals(self) -> None:
        names = self.svc._get_meal_names(6)
        self.assertEqual(len(names), 6)
        self.assertEqual(names[0], 'Breakfast')
        self.assertEqual(names[-1], 'Evening Snack')

    def test_eight_meals(self) -> None:
        """More than 6 meals should pad with 'Meal N'."""
        names = self.svc._get_meal_names(8)
        self.assertEqual(len(names), 8)
        self.assertEqual(names[6], 'Meal 7')
        self.assertEqual(names[7], 'Meal 8')
