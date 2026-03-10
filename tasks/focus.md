# Focus: Trainer Packet v6.5 — Step 3: LiftSetLog + LiftMax + e1RM/TM + Load Prescription

## Priority
Critical — Step 3 of the v6.5 build order. The LiftSetLog replaces unstructured JSON workout logging with relational per-set tracking. LiftMax enables intelligent load prescription. Together they power: progression, workload engine, session runner, and analytics.

## What to Build

### 1. LiftSetLog Model
Per-set performance tracking (replaces DailyLog.workout_data JSON for structured lift data):
- `exercise` FK to Exercise
- `trainee` FK to User
- `session_date` DateField
- `set_number` PositiveIntegerField
- `exercise_id`, `weight`, `reps_completed` (or `time_seconds` for timed sets)
- `rpe` optional (Rate of Perceived Exertion, 1-10)
- `standardization_pass` BooleanField (did this set meet the exercise's standardization criteria)
- `entered_load_value`, `entered_load_unit` (what the user typed)
- `load_entry_mode` (total_load / per_hand / bodyweight_plus_external)
- `canonical_external_load_value`, `canonical_external_load_unit` (normalized for workload math)
- `workload_eligible` BooleanField (valid for workload calculations)
- `completed_reps`, `completed_time_seconds`, `completed_distance_meters` (optional)
- `set_workload_value`, `set_workload_unit`, `workload_formula_id`
- `notes` optional TextField
- Log every set via DecisionLogService when system prescribes load

### 2. LiftMax Model
Per-exercise cached strength maxes:
- `trainee` FK to User
- `exercise` FK to Exercise (unique_together with trainee)
- `e1rm_current` DecimalField — estimated 1RM from best qualifying set
- `e1rm_history` JSONField — list of {date, value, source_set_id}
- `tm_current` DecimalField — training max (typically 85-95% of e1RM)
- `tm_history` JSONField — list of {date, value, reason}
- `anchor` DecimalField — MaxGroup anchor for seeding
- `variation_ratios` JSONField — for MaxGroup seeding from anchor

### 3. MaxLoadService (in services/)
- `estimate_e1rm(weight, reps, formula)` → Decimal (Epley, Brzycki, choose conservative)
- `smooth_e1rm_update(current_e1rm, new_estimate)` → Decimal (only update if passes standardization)
- `calculate_tm(e1rm, percentage=0.90)` → Decimal
- `prescribe_load(tm, target_percent, rounding_increment=2.5)` → Decimal
- `round_to_equipment(load, increment)` → Decimal (round to nearest plate increment)
- Only sets passing standardization update e1RM

### 4. API Endpoints
- CRUD for LiftSetLog (trainees create, trainers read their trainees')
- GET /api/workouts/lift-maxes/ — trainee's current maxes
- GET /api/workouts/lift-maxes/{exercise_id}/history/ — e1RM history for charting
- POST /api/workouts/lift-maxes/prescribe/ — get recommended load for exercise+target

### 5. Migration

## What NOT to Build
- Workload engine aggregation (Step 4)
- Session runner UI (Step 8)
- Progression engine (Step 7)
- Mobile UI for lift logging (future pipeline — current workout_log screen still works with DailyLog)
