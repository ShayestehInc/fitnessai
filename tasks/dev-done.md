# Dev Done: Nutrition Phase 2 — FoodItem, MealLog, Fat Mode

## Date: 2026-03-05

## Files Changed

### Backend (New)
- `workouts/migrations/0016_fooditem_meallog.py` — Migration creating FoodItem, MealLog, MealLogEntry tables

### Backend (Modified)
- `workouts/models.py` — Added FoodItem, MealLog, MealLogEntry models
- `workouts/serializers.py` — Added FoodItemSerializer, FoodItemCreateSerializer, MealLogSerializer, MealLogEntrySerializer, MealLogSummarySerializer, QuickAddEntrySerializer
- `workouts/views.py` — Added FoodItemViewSet (search, barcode lookup, recent, CRUD), MealLogViewSet (date filter, summary, quick-add, delete entry), active_assignment action on NutritionTemplateAssignmentViewSet
- `workouts/urls.py` — Registered food-items and meal-logs routes

### Mobile (New)
- `features/nutrition/data/repositories/food_item_repository.dart` — FoodItem API repository (search, barcode, recent, create)
- `features/nutrition/data/repositories/meal_log_repository.dart` — MealLog API repository (meals, summary, quick-add, delete, active assignment)
- `features/nutrition/presentation/providers/food_item_provider.dart` — Riverpod state management for food item search with debounce
- `features/nutrition/presentation/providers/meal_log_provider.dart` — Riverpod state management for meal logs
- `features/nutrition/presentation/widgets/meal_card.dart` — Expandable meal card with entries, macro subtotals, swipe-to-delete
- `features/nutrition/presentation/widgets/fat_mode_badge.dart` — Fat mode indicator badge with tooltip explanation

### Mobile (Modified)
- `features/nutrition/data/models/nutrition_models.dart` — Updated FoodItemModel (added full fields), added MealLogModel, MealLogEntryModel, MealLogSummaryModel
- `core/constants/api_constants.dart` — Added food-items, meal-logs, active assignment endpoints

## Key Decisions
1. **FoodItem follows Exercise pattern** — `is_public` + `created_by` for visibility scoping
2. **MealLogEntry supports both structured (food_item FK) and freeform (custom_name)** entries
3. **Quick-add endpoint auto-creates MealLog** containers — simplifies client logic
4. **FoodItem.calories auto-calculated from macros** if set to 0 — prevents data inconsistency
5. **Optimistic deletes with rollback** in MealLogNotifier
6. **Fat mode badge uses tooltip** to explain total_fat vs added_fat difference
7. **Barcode lookup uses URL path param** not query param — cleaner REST semantics
8. **Recent foods uses entry log ordering** — most recently used appears first, deduplicated

## Deviations from Ticket
- Did not wire food search into AddFoodScreen's Search tab yet (needs UI integration in existing screen)
- Did not restructure NutritionScreen to show MealCards yet (needs careful integration with existing meal display)
- These UI integrations will be addressed during the review/fix cycle

## How to Test
1. **Backend**: `python manage.py migrate` then test endpoints:
   - `POST /api/workouts/food-items/` — create custom food (as trainer)
   - `GET /api/workouts/food-items/?search=chicken` — search
   - `GET /api/workouts/food-items/barcode/12345/` — barcode lookup
   - `POST /api/workouts/meal-logs/quick-add/` — add food entry
   - `GET /api/workouts/meal-logs/?date=2026-03-05` — list meals
   - `GET /api/workouts/meal-logs/summary/?date=2026-03-05` — daily totals
   - `DELETE /api/workouts/meal-logs/entries/1/` — delete entry
   - `GET /api/workouts/nutrition-template-assignments/active/` — active assignment
2. **Mobile**: Build and verify models compile, widgets render correctly
