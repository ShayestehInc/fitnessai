# Focus: Trainer Packet v6.5 — Step 4: Workload Engine

## Priority
Critical — Step 4 of the v6.5 build order. Aggregates per-set data (from LiftSetLog) into exercise, session, and weekly workload totals. Enables workload trending, muscle-group distribution, and progressive overload tracking.

## What to Build

### 1. WorkloadFactTemplate Model
Deterministic "cool fact" templates shown after exercise/session completion:
- `scope` (exercise/session), `template_text` with placeholders, `condition_rules` JSON, `priority`, `is_active`

### 2. Workload Aggregation Service
- `compute_exercise_workload(trainee, exercise, session_date)` → dataclass
- `compute_session_workload(trainee, session_date)` → dataclass
- `compute_weekly_workload(trainee, week_start, week_end)` → dataclass
- `compute_workload_by_muscle_group(trainee, date_range)` → dict
- `compute_workload_by_pattern(trainee, date_range)` → dict

### 3. Workload Trend Service
- `compute_acute_chronic_ratio(trainee, as_of_date)` → Decimal
- `detect_spike(trainee, threshold)` / `detect_dip(trainee, threshold)` → bool
- `get_weekly_deltas(trainee, weeks_back)` → list

### 4. Workload Fact Service
- Deterministic fact selection from template library
- Template rendering with context data

### 5. API Endpoints
- GET /api/workouts/workload/exercise/ — exercise workload for a session
- GET /api/workouts/workload/session/ — session workload summary
- GET /api/workouts/workload/weekly/ — weekly workload with breakdowns
- GET /api/workouts/workload/trends/ — trend data with ACWR
- CRUD for WorkloadFactTemplate (trainer)

## What NOT to Build
- Session runner UI (Step 8)
- Progression engine integration (Step 7)
- Set structure counting multipliers (Step 6 — modality library)
- WorkloadFormula registry (overkill — one formula exists: load × reps)
- Snapshot models for caching (can add later if performance requires it)
