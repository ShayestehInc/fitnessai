# Feature: Nutrition Phase 2 — FoodItem Model, Structured MealLog, Fat Mode Toggle

## Priority
High

## User Story
As a trainee, I want to log meals using a structured food database with per-item tracking so that my nutrition data is accurate, searchable, and reusable. As a trainer, I want to create custom food items for my trainees and toggle their fat tracking mode so I can tailor their nutrition approach.

## Acceptance Criteria

### FoodItem Model (Backend)
- [ ] AC-1: New `FoodItem` model with fields: `name`, `brand`, `serving_size`, `serving_unit`, `calories`, `protein`, `carbs`, `fat`, `fiber`, `sugar`, `sodium`, `barcode`, `is_public`, `created_by`, timestamps
- [ ] AC-2: `is_public=True` for system foods (seeded), `is_public=False` for trainer-created custom foods
- [ ] AC-3: `created_by` FK to User (null for system foods, trainer for custom)
- [ ] AC-4: Full CRUD API at `/api/workouts/food-items/` with role-based access:
  - Trainee: read system + their trainer's custom items
  - Trainer: read all system + CRUD their own custom items
  - Admin: full access
- [ ] AC-5: Search endpoint with `?search=` query param filtering on `name` and `brand` (case-insensitive)
- [ ] AC-6: Barcode lookup endpoint at `/api/workouts/food-items/barcode/<barcode>/` returning matching FoodItem or 404
- [ ] AC-7: Pagination on list endpoint (20 items per page)

### MealLog Model (Backend)
- [ ] AC-8: New `MealLog` model: `trainee` FK, `date`, `meal_number` (1-6), `meal_name` (e.g., "Breakfast"), `logged_at` timestamp
- [ ] AC-9: New `MealLogEntry` model: `meal_log` FK, `food_item` FK (nullable for freeform), `custom_name` (for freeform entries without a FoodItem), `quantity`, `serving_unit`, `protein`, `carbs`, `fat`, `calories`, `fat_mode` (total_fat or added_fat)
- [ ] AC-10: Full CRUD API at `/api/workouts/meal-logs/` — trainee creates meals, entries nested
- [ ] AC-11: `GET /api/workouts/meal-logs/?date=YYYY-MM-DD` returns all meals for that date with entries nested
- [ ] AC-12: `GET /api/workouts/meal-logs/summary/?date=YYYY-MM-DD` returns aggregated daily macro totals from MealLog entries
- [ ] AC-13: `POST /api/workouts/meal-logs/quick-add/` accepts a flat entry (food_item_id + quantity or freeform macros), auto-creates MealLog if none exists for that meal_number+date
- [ ] AC-14: `DELETE /api/workouts/meal-logs/entries/<id>/` deletes a single entry
- [ ] AC-15: Backward compatibility — existing `DailyLog.nutrition_data` JSON continues working; new MealLog is the preferred path

### Fat Mode Toggle (Mobile + Backend)
- [ ] AC-16: Template assignment screen shows fat mode selector with explanation tooltip
- [ ] AC-17: Trainee nutrition screen displays current fat mode badge ("Total Fat" or "Added Fat Only")
- [ ] AC-18: When fat_mode is `added_fat`, the fat column in meal entries shows "Added Fat" label and the day plan adjusts display accordingly
- [ ] AC-19: `GET /api/workouts/nutrition-template-assignments/active/` endpoint returns trainee's active assignment (including fat_mode)

### FoodItem Mobile (Flutter)
- [ ] AC-20: New `FoodItemModel` Freezed class matching backend fields
- [ ] AC-21: `FoodItemRepository` with methods: `search(query)`, `getByBarcode(barcode)`, `create(item)`, `getRecent()`
- [ ] AC-22: Food search integrated into AddFoodScreen's Search tab — type-ahead search with debounce (300ms)
- [ ] AC-23: Barcode scan result resolves to FoodItem from database (existing barcode scanner wired to new endpoint)
- [ ] AC-24: Tapping a search result pre-fills the manual entry form with FoodItem macros and allows quantity adjustment
- [ ] AC-25: Recently used foods shown when search is empty (last 20 unique items)

### MealLog Mobile (Flutter)
- [ ] AC-26: New `MealLogModel` and `MealLogEntryModel` Freezed classes
- [ ] AC-27: `MealLogRepository` with methods: `getMeals(date)`, `getSummary(date)`, `quickAdd(entry)`, `deleteEntry(id)`
- [ ] AC-28: Nutrition screen shows structured meal cards (Meal 1, Meal 2, etc.) with entries listed under each
- [ ] AC-29: Each meal card shows per-meal macro subtotals
- [ ] AC-30: Swipe-to-delete on individual food entries with undo snackbar
- [ ] AC-31: "Add Food" FAB on nutrition screen opens AddFoodScreen with meal_number context
- [ ] AC-32: After adding food via any method (manual, AI, search, scan), entry saved as MealLogEntry

## Edge Cases
1. What if trainee searches for food and no results found? → Show "No results" with option to add custom entry
2. What if two trainers create foods with the same name? → Both visible to their own trainees only (scoped by created_by)
3. What if barcode not found in database? → Return 404, mobile shows "Food not found — add manually" with barcode pre-filled
4. What if trainee logs 0 quantity? → Validation error, minimum quantity is 0.01
5. What if trainee deletes the last entry in a meal? → MealLog stays (empty meal is valid, can be deleted separately)
6. What if trainee has both old JSON nutrition_data and new MealLog entries for same date? → Summary endpoint merges both sources, MealLog entries take precedence
7. What if food item is deleted after being used in a MealLogEntry? → PROTECT — cannot delete food items that have been logged
8. What if search query is very short (1 char)? → Require minimum 2 characters for search
9. What if trainee switches fat mode mid-day? → Existing entries keep their logged values; only new entries use new mode
10. What if trainer creates food item with 0 calories but non-zero macros? → Auto-calculate calories from macros (P*4 + C*4 + F*9)

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Food search fails | "Search unavailable" with retry | Show error, retry on tap |
| Barcode lookup fails | "Could not look up barcode" toast | Fall back to manual entry |
| Save meal entry fails | "Failed to save" toast with retry | Retry with exponential backoff |
| Delete entry fails | Entry reappears with error toast | Rollback optimistic delete |
| Load meals for date fails | Error card with retry | Show error state, retry button |

## UX Requirements
- **Loading state:** Shimmer skeletons for meal cards and food search results
- **Empty state:** "No meals logged yet — tap + to add your first food" with illustration
- **Error state:** Error card with retry button for load failures, toast for action failures
- **Success feedback:** Entry appears in meal card immediately (optimistic), subtle slide-in animation
- **Mobile behavior:** Swipe-to-delete with undo, pull-to-refresh on meal list, debounced search

## Technical Approach

### Backend (Django)
- **New models in `workouts/models.py`:**
  - `FoodItem` — follows Exercise pattern (is_public, created_by)
  - `MealLog` — per-meal container (trainee, date, meal_number)
  - `MealLogEntry` — individual food entries within a meal
- **New migration:** `workouts/migrations/0016_fooditem_meallog.py`
- **New serializers in `workouts/serializers.py`:**
  - `FoodItemSerializer`, `FoodItemCreateSerializer`
  - `MealLogSerializer` (nested entries), `MealLogEntrySerializer`
  - `MealLogSummarySerializer`, `QuickAddSerializer`
- **New views in `workouts/views.py`:**
  - `FoodItemViewSet` — ModelViewSet with search, barcode lookup
  - `MealLogViewSet` — ModelViewSet with date filtering, summary action, quick-add
- **New URLs in `workouts/urls.py`:**
  - `food-items/` (router)
  - `meal-logs/` (router)
- **Modify `NutritionTemplateAssignmentViewSet`:** Add `active` action

### Mobile (Flutter)
- **New models:** `food_item_model.dart`, `meal_log_model.dart`
- **New repositories:** `food_item_repository.dart`, `meal_log_repository.dart`
- **New providers:** `food_search_provider.dart`, `meal_log_provider.dart`
- **Modify screens:**
  - `nutrition_screen.dart` — restructure to show meal cards with entries
  - `add_food_screen.dart` — wire Search tab to FoodItem API, wire barcode to new endpoint
- **New widgets:**
  - `meal_card.dart` — expandable meal card with entries and subtotals
  - `food_search_delegate.dart` — search bar with debounced results
  - `fat_mode_badge.dart` — displays current fat tracking mode
- **New API constants** for food-items and meal-logs endpoints

### Dependencies
- No new packages needed (barcode scanner already installed)

## Out of Scope
- Recipe system (Phase 5)
- Copy-yesterday / plan-ahead (Phase 5)
- Food swap suggestions (Phase 6)
- Photo food logging (Phase 7)
- Seeding a large system food database (separate task — start with empty, trainer creates custom)
- Offline meal logging (existing Drift infrastructure can be extended later)
