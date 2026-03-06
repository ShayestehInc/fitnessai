# Dev Done: Nutrition Phase 3 — LBM Formula Engine & SHREDDED/MASSIVE Templates

## Date: 2026-03-05

## Files Changed

### Backend (Modified)
- `workouts/services/macro_calculator.py` — Added `ShreddedMacroResult`, `MassiveMacroResult`, `MealMacros` dataclasses. Added `estimate_body_fat()` (Boer formula), `calculate_shredded_macros()`, `calculate_massive_macros()`, `_distribute_meals()`, `_resolve_lbm_inputs()`.
- `workouts/services/nutrition_plan_service.py` — Added `_apply_shredded_ruleset()`, `_apply_massive_ruleset()`, `_enrich_with_profile()`. Updated dispatch in `apply_template_ruleset()`.
- `workouts/views.py` — Added `recalculate` action on `NutritionTemplateAssignmentViewSet`.

### Backend (New)
- `workouts/migrations/0017_update_shredded_massive_rulesets.py` — Update system template rulesets.

### Mobile (New)
- `features/nutrition/presentation/screens/day_plan_screen.dart` — Day plan with date nav, totals, meals.
- `features/nutrition/presentation/screens/week_plan_screen.dart` — Week view with day type badges.
- `features/nutrition/presentation/widgets/day_type_badge.dart` — Color-coded day type badge.
- `features/nutrition/presentation/widgets/meal_plan_card.dart` — Per-meal macro card.

### Mobile (Modified)
- `core/constants/api_constants.dart` — Added recalculate endpoint.
- `core/router/app_router.dart` — Added day-plan and week-plan routes.

## Key Decisions
1. SHREDDED: 1.3g protein/lb LBM, 22% deficit, 3 carb day types
2. MASSIVE: 1.1g protein/lb LBM, 12% surplus, training/rest day types
3. Front-loaded carb distribution across meals
4. Boer formula fallback when body fat % is missing
5. Profile enrichment for LBM-based templates
6. Recalculate endpoint regenerates 7 days, skips overridden
