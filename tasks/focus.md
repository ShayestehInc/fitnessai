# Focus: Trainer Packet v6.5 — Step 10: Food Swap Engine + Nutrition DecisionLog

## Priority

Critical — Step 10 of the v6.5 build order. Most nutrition infrastructure already exists (templates, fat toggle, meal logging). This step completes the food swap recommendation system and wires DecisionLog into nutrition decisions.

## What to Build

### 1. Food Swap Service

- `get_food_swaps(food_item_id, mode, limit)` → returns ranked food alternatives
- Three modes: `same_category` (same food group), `same_macros` (similar P/C/F ratio), `explore` (discover new foods)
- Similarity scoring based on macro profile (calorie-normalized P/C/F distance)
- DecisionLog for every swap recommendation
- UndoSnapshot for executed swaps

### 2. Food Swap API Endpoints

- GET /food-items/{id}/swaps/?mode=same_macros&limit=10
- POST /meal-logs/{id}/entries/{entry_id}/swap/ — execute a food swap in a meal log

### 3. CARB_CYCLING Ruleset

- Implement the carb cycling formula in nutrition_plan_service
- High-carb days (training), low-carb days (rest), medium days (light training)
- Macro ratios shift based on day type

### 4. Nutrition DecisionLog Integration

- Wire DecisionLog into day plan generation (nutrition_plan_service)
- Log macro calculations with inputs (BW, BF%, template, day_type) and outputs (P/C/F targets)

## What NOT to Build

- System food database seed (separate effort)
- Mobile UI for food swaps (separate step)
- Natural language food parsing improvements
- MACRO_EBOOK ruleset (not yet specified)
