# Feature: LBM Formula Engine & SHREDDED/MASSIVE Nutrition Templates

## Priority
High

## User Story
As a trainer, I want to assign SHREDDED or MASSIVE nutrition templates to my trainees so that their daily macro targets are automatically calculated based on lean body mass, with per-meal breakdowns that vary by day type (training/rest/low carb/high carb).

## Acceptance Criteria
- [ ] AC-1: `calculate_shredded_macros()` returns accurate daily + per-meal macro targets based on LBM
- [ ] AC-2: SHREDDED template produces a 20-25% caloric deficit with protein at 1.2-1.4g/lb LBM
- [ ] AC-3: MASSIVE template produces a 10-15% caloric surplus with protein at 1.0-1.2g/lb LBM
- [ ] AC-4: SHREDDED supports 3 day types: low_carb, medium_carb, high_carb — each with different carb/fat ratios
- [ ] AC-5: MASSIVE supports 2 day types: training_day, rest_day — training days get more carbs
- [ ] AC-6: Per-meal macro splitting distributes protein evenly but front-loads carbs around training
- [ ] AC-7: `_apply_shredded_ruleset()` in NutritionPlanService generates correct NutritionDayPlan with per-meal MealTargets
- [ ] AC-8: `_apply_massive_ruleset()` in NutritionPlanService generates correct NutritionDayPlan with per-meal MealTargets
- [ ] AC-9: When body_fat_pct is missing, fall back to estimated body fat from sex/weight (Boer formula)
- [ ] AC-10: Seed migration updates SHREDDED and MASSIVE templates with actual rulesets (replacing placeholders)
- [ ] AC-11: Mobile day plan screen shows per-meal macro breakdown with day type indicator
- [ ] AC-12: Mobile week view shows 7-day plan with day types color-coded
- [ ] AC-13: Recalculate day plans when assignment parameters change (weight, body fat %)
- [ ] AC-14: All formula calculations have unit tests with known reference values

## Edge Cases
1. Body fat % is 0 or not provided — fall back to Boer formula estimate
2. Weight is extremely low (<90 lbs / 40kg) or high (>400 lbs / 180kg) — clamp to safe ranges
3. LBM calculation produces negative or zero — return error, don't generate plan
4. Meals per day is 2 vs 6 — macro splitting must work correctly for any count
5. Template assignment has no parameters — use UserProfile defaults
6. Day plan already exists and is manually overridden — don't regenerate
7. Trainee has no active program — default all days to rest_day type for MASSIVE, medium_carb for SHREDDED
8. Body fat % is exactly at boundary (3% or 60%) — handle without error

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Missing weight in parameters | "Weight is required for this template" | Return 400 |
| LBM calculation fails | "Unable to calculate — check body metrics" | Log error, return 400 |
| No active assignment | Empty state on day plan screen | Show "No template assigned" |
| API error loading day plan | Error banner with retry | Preserve last known state |

## UX Requirements
- **Loading state:** Shimmer skeleton on day plan and week view
- **Empty state:** "No nutrition plan assigned" with CTA to contact trainer
- **Error state:** Error banner with retry button, preserves last-loaded data
- **Success feedback:** Day plan renders immediately on navigation
- **Mobile behavior:** Day plan is scrollable list of meal cards, week view is horizontal date selector

## Technical Approach

### Backend Changes
- **`workouts/services/macro_calculator.py`**: Add `calculate_shredded_macros()` and `calculate_massive_macros()` functions. Each returns a dataclass with total daily macros + per-meal breakdown. Add `estimate_body_fat()` using Boer formula for fallback.
- **`workouts/services/nutrition_plan_service.py`**: Implement `_apply_shredded_ruleset()` and `_apply_massive_ruleset()` replacing the placeholder blocks. These call the new macro_calculator functions and format results as MealTarget lists.
- **`workouts/migrations/0017_update_shredded_massive_rulesets.py`**: Update seed data for SHREDDED and MASSIVE templates with actual ruleset configurations.

### Mobile Changes
- **`features/nutrition/presentation/screens/day_plan_screen.dart`**: New screen showing daily nutrition plan with meal cards, day type badge, and macro totals.
- **`features/nutrition/presentation/screens/week_plan_screen.dart`**: New screen showing 7-day horizontal view with day type indicators and daily totals.
- **`features/nutrition/presentation/widgets/meal_plan_card.dart`**: Widget for individual meal showing target macros.
- **`features/nutrition/presentation/widgets/day_type_badge.dart`**: Badge showing day type with color coding.
- Wire day plan into existing nutrition navigation.

## Out of Scope
- Carb cycling calendar UI (Phase 4)
- Recipe system (Phase 5)
- Food swap suggestions (Phase 6)
- Custom per-meal overrides by trainer (future)
