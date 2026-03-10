# Focus: Trainer Packet v6.5 — Step 7: Progression Engine (Staircase + Wave + Deload)

## Priority

Critical — Step 7 of the v6.5 build order. Powers automatic load/rep adjustments session-to-session. Foundation for session runner and feedback loop.

## What to Build

### 1. ProgressionProfile Model

- Selectable template defining HOW progression works for a plan/exercise
- Supports: Staircase Percent, Rep Staircase, Wave-by-Month, Double Progression, Linear, DUP, WUP, Block, Concurrent
- Each profile stores: progression_type, rules JSON (step size, deload rules, failure rules, TM adjustment), is_system, created_by
- Pinned to TrainingPlan (plan-level default) and overrideable per PlanSlot

### 2. ProgressionRule Engine

- evaluate_progression(trainee, exercise, plan_slot, session_history) → ProgressionSuggestion
- Reads LiftSetLog history + LiftMax to determine next session prescription
- Auto-progression gated by: completion, effort (RIR ±1), symptom flags
- Failure rules: repeat week, reduce load, micro-reset
- Deload rules: drop volume 30-50%, drop intensity 5-10%

### 3. Integration Points

- PlanSlot gets progression_profile FK (nullable, falls back to plan default)
- TrainingPlan gets default_progression_profile FK
- compute_next_session_prescription(slot) → sets/reps/load for next session
- All suggestions logged via DecisionLog

### 4. API Endpoints

- CRUD for ProgressionProfile (system + trainer-created)
- GET /plan-slots/{id}/next-prescription/ — compute next session
- POST /plan-slots/{id}/apply-progression/ — apply suggestion

## What NOT to Build

- Session runner UI (Step 8)
- End-of-session feedback (Step 9)
- AI-powered progression selection
