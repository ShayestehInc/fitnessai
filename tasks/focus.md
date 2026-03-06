# Focus: Nutrition Phase 2 — FoodItem Model, Structured MealLog, Fat Mode Toggle

## Priority
Build the foundational data layer for structured nutrition tracking:

1. **FoodItem model** — A proper food database with name, brand, macros per serving, serving sizes, barcode, and public/trainer-custom visibility (mirrors Exercise model pattern).

2. **MealLog model** — Replace the unstructured `DailyLog.nutrition_data` JSON blob with a proper relational model: `MealLog` → `MealLogEntry` → `FoodItem`. Each entry tracks quantity, serving unit, and computed macros. Backward-compatible with existing JSON data.

3. **Fat Mode toggle** — The `NutritionTemplateAssignment.fat_mode` field already exists (`total_fat` vs `added_fat`). Wire it into the mobile UI so trainees can see which fat tracking mode they're on, and trainers can toggle it during template assignment. Display contextual help explaining the difference.

## Constraints
- Must not break existing nutrition logging (JSON-based `nutrition_data` stays as fallback)
- FoodItem follows the Exercise model pattern: `is_public` for system foods, trainer-custom for private
- MealLog entries must support both FoodItem-linked and freeform (AI-parsed) entries
- All new endpoints need proper row-level security (trainer sees only their trainees' data)
- Mobile screens must handle loading/empty/error states
