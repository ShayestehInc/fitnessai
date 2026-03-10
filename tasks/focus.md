# Focus: Trainer Packet v6.5 — Step 5: Training Generator Pipeline + Swap System

## Priority
Critical — Step 5 of the v6.5 build order. Replaces flat JSON Program.schedule with a relational Plan→Week→Session→Slot hierarchy. Adds a 7-step deterministic generator pipeline and 3-tab swap system.

## What to Build

### 1. New Relational Models
- TrainingPlan: top-level container replacing Program.schedule's flat JSON
- PlanWeek: week within a plan (week_number, is_deload, intensity/volume modifiers)
- PlanSession: session within a week (day_of_week, label like "Upper A")
- PlanSlot: individual exercise slot within a session (order, exercise FK, set/rep prescription, rest, role)
- SplitTemplate: reusable split definitions (Full Body, Upper/Lower, PPL, Bro Split, etc.)

### 2. 7-Step Deterministic Generator Pipeline (A1-A7)
- A1: SELECT_PROGRAM_LENGTH → pick weeks based on goal/experience
- A2: SELECT_SPLIT_TEMPLATE → pick split based on frequency/goal
- A3: BUILD_WEEKLY_SLOT_SKELETON → create empty sessions and slots per split
- A4: ASSIGN_SLOT_ROLE → tag each slot (primary_compound, secondary_compound, accessory, isolation)
- A5: SET_SET_STRUCTURE → assign sets/reps/rest per role and goal
- A6: SELECT_EXERCISE → fill slots with exercises from pool (respecting muscle/pattern/equipment)
- A7: BUILD_SWAP_RECOMMENDATIONS → pre-compute 3-tab swap candidates per slot

Each step logs a DecisionLog entry with full context.

### 3. Swap System Service
- 3 tabs: Same Muscle, Same Pattern, Explore All
- Uses Exercise.swap_seed_ids for pre-computed recommendations
- Falls back to dynamic query when seeds unavailable
- Swap execution creates DecisionLog + UndoSnapshot

### 4. API Endpoints
- CRUD for TrainingPlan (with nested weeks/sessions/slots)
- POST /generate/ — run the 7-step pipeline
- GET /slots/{id}/swap-options/ — 3-tab swap candidates
- POST /slots/{id}/swap/ — execute swap with DecisionLog
- CRUD for SplitTemplate (trainer-facing)

## What NOT to Build
- Set Structure Modalities (Step 6)
- Progression engine integration (Step 7)
- Session runner (Step 8)
- AI-powered generation alternative (use deterministic only)
