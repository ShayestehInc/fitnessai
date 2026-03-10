"""
Tests for Food Swap Engine + Nutrition DecisionLog — v6.5 Step 10.

Covers:
- Food swap recommendations: same_macros, same_category, explore modes
- Macro similarity scoring
- Swap execution with UndoSnapshot
- DecisionLog creation for swaps
- CARB_CYCLING ruleset
- Nutrition DecisionLog on plan generation
- API endpoints: swap recommendations, swap execution
"""
from __future__ import annotations

from datetime import date
from unittest.mock import patch

from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from users.models import User
from workouts.models import (
    DecisionLog,
    FoodItem,
    MealLog,
    MealLogEntry,
    NutritionDayPlan,
    NutritionTemplate,
    NutritionTemplateAssignment,
    UndoSnapshot,
)
from workouts.services.food_swap_service import (
    execute_food_swap,
    get_food_swaps,
    _macro_distance,
    _similarity_score,
)
from workouts.services.nutrition_plan_service import NutritionPlanService


# ---------------------------------------------------------------------------
# Shared setup
# ---------------------------------------------------------------------------


class FoodSwapTestBase(TestCase):

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email="fs_trainer@test.com",
            password="testpass123",
            role="TRAINER",
        )
        self.trainee = User.objects.create_user(
            email="fs_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
            parent_trainer=self.trainer,
        )

        # Create food items with known macro profiles
        self.chicken_breast = FoodItem.objects.create(
            name="Chicken Breast",
            calories=165,
            protein=31.0,
            carbs=0.0,
            fat=3.6,
            is_public=True,
        )
        self.chicken_thigh = FoodItem.objects.create(
            name="Chicken Thigh",
            calories=209,
            protein=26.0,
            carbs=0.0,
            fat=10.9,
            is_public=True,
        )
        self.turkey_breast = FoodItem.objects.create(
            name="Turkey Breast",
            calories=135,
            protein=30.0,
            carbs=0.0,
            fat=1.0,
            is_public=True,
        )
        self.salmon = FoodItem.objects.create(
            name="Salmon Fillet",
            calories=208,
            protein=20.0,
            carbs=0.0,
            fat=13.0,
            is_public=True,
        )
        self.brown_rice = FoodItem.objects.create(
            name="Brown Rice",
            calories=216,
            protein=5.0,
            carbs=45.0,
            fat=1.8,
            is_public=True,
        )
        self.white_rice = FoodItem.objects.create(
            name="White Rice",
            calories=206,
            protein=4.3,
            carbs=45.0,
            fat=0.4,
            is_public=True,
        )

        self.trainee_client = APIClient()
        self.trainee_client.force_authenticate(user=self.trainee)

        self.trainer_client = APIClient()
        self.trainer_client.force_authenticate(user=self.trainer)


# ---------------------------------------------------------------------------
# Macro similarity scoring
# ---------------------------------------------------------------------------


class MacroSimilarityTest(FoodSwapTestBase):

    def test_identical_food_zero_distance(self) -> None:
        dist = _macro_distance(self.chicken_breast, self.chicken_breast)
        self.assertAlmostEqual(dist, 0.0)

    def test_similar_foods_low_distance(self) -> None:
        dist = _macro_distance(self.chicken_breast, self.turkey_breast)
        self.assertLess(dist, 0.3)

    def test_different_macro_profile_higher_distance(self) -> None:
        dist_similar = _macro_distance(self.chicken_breast, self.turkey_breast)
        dist_different = _macro_distance(self.chicken_breast, self.brown_rice)
        self.assertGreater(dist_different, dist_similar)

    def test_similarity_score_range(self) -> None:
        score = _similarity_score(0.0, 0.0)
        self.assertEqual(score, 1.0)
        score = _similarity_score(1.0, 1.0)
        self.assertEqual(score, 0.0)


# ---------------------------------------------------------------------------
# Service: get_food_swaps
# ---------------------------------------------------------------------------


class GetFoodSwapsTest(FoodSwapTestBase):

    def test_same_macros_mode(self) -> None:
        result = get_food_swaps(
            food_item_id=self.chicken_breast.pk,
            mode='same_macros',
            limit=5,
            user=self.trainee,
        )
        self.assertEqual(result.source_food_id, self.chicken_breast.pk)
        self.assertEqual(result.mode, 'same_macros')
        self.assertGreater(len(result.candidates), 0)
        # Turkey breast should rank high (similar protein-dominant profile)
        names = [c.name for c in result.candidates]
        self.assertIn('Turkey Breast', names)

    def test_same_category_mode(self) -> None:
        result = get_food_swaps(
            food_item_id=self.chicken_breast.pk,
            mode='same_category',
            limit=5,
            user=self.trainee,
        )
        names = [c.name for c in result.candidates]
        # Should find "Chicken Thigh" via name similarity
        self.assertIn('Chicken Thigh', names)

    def test_explore_mode(self) -> None:
        result = get_food_swaps(
            food_item_id=self.chicken_breast.pk,
            mode='explore',
            limit=5,
            user=self.trainee,
        )
        # Should NOT include other chicken items
        names = [c.name for c in result.candidates]
        self.assertNotIn('Chicken Thigh', names)

    def test_invalid_mode(self) -> None:
        with self.assertRaises(ValueError):
            get_food_swaps(
                food_item_id=self.chicken_breast.pk,
                mode='invalid',
                limit=5,
                user=self.trainee,
            )

    def test_invalid_food_item(self) -> None:
        with self.assertRaises(ValueError):
            get_food_swaps(
                food_item_id=99999,
                mode='same_macros',
                limit=5,
                user=self.trainee,
            )

    def test_creates_decision_log(self) -> None:
        result = get_food_swaps(
            food_item_id=self.chicken_breast.pk,
            mode='same_macros',
            limit=5,
            user=self.trainee,
            actor_id=self.trainee.pk,
        )
        self.assertIsNotNone(result.decision_log_id)
        log = DecisionLog.objects.get(pk=result.decision_log_id)
        self.assertEqual(log.decision_type, 'food_swap_recommendation')

    def test_source_excluded_from_results(self) -> None:
        result = get_food_swaps(
            food_item_id=self.chicken_breast.pk,
            mode='same_macros',
            limit=50,
            user=self.trainee,
        )
        ids = [c.food_item_id for c in result.candidates]
        self.assertNotIn(self.chicken_breast.pk, ids)


# ---------------------------------------------------------------------------
# Service: execute_food_swap
# ---------------------------------------------------------------------------


class ExecuteFoodSwapTest(FoodSwapTestBase):

    def setUp(self) -> None:
        super().setUp()
        self.meal_log = MealLog.objects.create(
            trainee=self.trainee,
            date=date(2026, 3, 10),
            meal_number=1,
        )
        self.entry = MealLogEntry.objects.create(
            meal_log=self.meal_log,
            food_item=self.chicken_breast,
            quantity=1.0,
            calories=165,
            protein=31.0,
            carbs=0.0,
            fat=3.6,
        )

    def test_swap_updates_entry(self) -> None:
        result = execute_food_swap(
            entry_id=self.entry.pk,
            new_food_item_id=self.turkey_breast.pk,
            user=self.trainee,
            actor_id=self.trainee.pk,
        )
        self.assertEqual(result.old_food_name, 'Chicken Breast')
        self.assertEqual(result.new_food_name, 'Turkey Breast')

        # Verify DB updated
        self.entry.refresh_from_db()
        self.assertEqual(self.entry.food_item_id, self.turkey_breast.pk)

    def test_swap_creates_undo_snapshot(self) -> None:
        result = execute_food_swap(
            entry_id=self.entry.pk,
            new_food_item_id=self.turkey_breast.pk,
            user=self.trainee,
            actor_id=self.trainee.pk,
        )
        self.assertIsNotNone(result.undo_snapshot_id)
        snapshot = UndoSnapshot.objects.get(pk=result.undo_snapshot_id)
        self.assertEqual(snapshot.before_state['food_item_id'], self.chicken_breast.pk)
        self.assertEqual(snapshot.after_state['food_item_id'], self.turkey_breast.pk)

    def test_swap_with_custom_quantity(self) -> None:
        result = execute_food_swap(
            entry_id=self.entry.pk,
            new_food_item_id=self.turkey_breast.pk,
            quantity=2.0,
            user=self.trainee,
        )
        self.entry.refresh_from_db()
        self.assertEqual(self.entry.quantity, 2.0)
        self.assertEqual(self.entry.calories, 270)  # 135 * 2

    def test_swap_other_trainees_entry_fails(self) -> None:
        other = User.objects.create_user(
            email="other_trainee@test.com",
            password="testpass123",
            role="TRAINEE",
        )
        with self.assertRaises(ValueError):
            execute_food_swap(
                entry_id=self.entry.pk,
                new_food_item_id=self.turkey_breast.pk,
                user=other,
            )


# ---------------------------------------------------------------------------
# CARB_CYCLING ruleset
# ---------------------------------------------------------------------------


class CarbCyclingRulesetTest(TestCase):

    def setUp(self) -> None:
        self.service = NutritionPlanService()

    def test_high_carb_day(self) -> None:
        params = {
            'body_weight_kg': 80,
            'sex': 'male',
            'height_cm': 180,
            'age': 30,
            'activity_level': 'moderately_active',
            'meals_per_day': 4,
        }
        meals = self.service._apply_carb_cycling_ruleset(params, 'high_carb')
        self.assertEqual(len(meals), 4)
        total_p = sum(m.protein for m in meals)
        total_c = sum(m.carbs for m in meals)
        total_f = sum(m.fat for m in meals)
        # High carb: carbs should be significant
        self.assertGreater(total_c, total_f)
        self.assertGreater(total_p, 0)

    def test_low_carb_day(self) -> None:
        params = {
            'body_weight_kg': 80,
            'sex': 'male',
            'height_cm': 180,
            'age': 30,
            'activity_level': 'moderately_active',
            'meals_per_day': 4,
        }
        meals = self.service._apply_carb_cycling_ruleset(params, 'low_carb')
        total_c = sum(m.carbs for m in meals)
        total_f = sum(m.fat for m in meals)
        # Low carb: fat should exceed carbs
        self.assertGreater(total_f, total_c)

    def test_training_day_maps_to_high_carb(self) -> None:
        params = {
            'body_weight_kg': 80,
            'sex': 'male',
            'height_cm': 180,
            'age': 30,
            'meals_per_day': 4,
        }
        high = self.service._apply_carb_cycling_ruleset(params, 'high_carb')
        training = self.service._apply_carb_cycling_ruleset(params, 'training')
        # Should produce same macros
        self.assertEqual(
            sum(m.carbs for m in high),
            sum(m.carbs for m in training),
        )

    def test_rest_day_maps_to_low_carb(self) -> None:
        params = {
            'body_weight_kg': 80,
            'sex': 'male',
            'height_cm': 180,
            'age': 30,
            'meals_per_day': 4,
        }
        low = self.service._apply_carb_cycling_ruleset(params, 'low_carb')
        rest = self.service._apply_carb_cycling_ruleset(params, 'rest')
        self.assertEqual(
            sum(m.carbs for m in low),
            sum(m.carbs for m in rest),
        )


# ---------------------------------------------------------------------------
# API: food swap endpoints
# ---------------------------------------------------------------------------


class FoodSwapAPITest(FoodSwapTestBase):

    def test_get_swaps_endpoint(self) -> None:
        resp = self.trainee_client.get(
            f'/api/workouts/food-items/{self.chicken_breast.pk}/swaps/?mode=same_macros&limit=5',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('candidates', resp.data)
        self.assertEqual(resp.data['source_food_name'], 'Chicken Breast')

    def test_get_swaps_invalid_mode(self) -> None:
        resp = self.trainee_client.get(
            f'/api/workouts/food-items/{self.chicken_breast.pk}/swaps/?mode=invalid',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_swap_entry_endpoint(self) -> None:
        meal_log = MealLog.objects.create(
            trainee=self.trainee,
            date=date(2026, 3, 10),
            meal_number=1,
        )
        entry = MealLogEntry.objects.create(
            meal_log=meal_log,
            food_item=self.chicken_breast,
            quantity=1.0,
            calories=165,
            protein=31.0,
            carbs=0.0,
            fat=3.6,
        )
        resp = self.trainee_client.post(
            f'/api/workouts/meal-logs/entries/{entry.pk}/swap/',
            data={'new_food_item_id': self.turkey_breast.pk},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['new_food_name'], 'Turkey Breast')
        self.assertIn('undo_snapshot_id', resp.data)

    def test_swap_entry_trainer_forbidden(self) -> None:
        meal_log = MealLog.objects.create(
            trainee=self.trainee,
            date=date(2026, 3, 10),
            meal_number=2,
        )
        entry = MealLogEntry.objects.create(
            meal_log=meal_log,
            food_item=self.chicken_breast,
            quantity=1.0,
            calories=165,
            protein=31.0,
            carbs=0.0,
            fat=3.6,
        )
        resp = self.trainer_client.post(
            f'/api/workouts/meal-logs/entries/{entry.pk}/swap/',
            data={'new_food_item_id': self.turkey_breast.pk},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_swap_entry_missing_food_id(self) -> None:
        meal_log = MealLog.objects.create(
            trainee=self.trainee,
            date=date(2026, 3, 10),
            meal_number=3,
        )
        entry = MealLogEntry.objects.create(
            meal_log=meal_log,
            food_item=self.chicken_breast,
            quantity=1.0,
            calories=165,
            protein=31.0,
            carbs=0.0,
            fat=3.6,
        )
        resp = self.trainee_client.post(
            f'/api/workouts/meal-logs/entries/{entry.pk}/swap/',
            data={},
            format='json',
        )
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
