# Focus: Trainer Packet v6.5 — Step 16: Full Audit UI + Exports

## Priority

Critical — Step 16 (final step) of the v6.5 build order. Completes the audit trail with summary endpoints and comprehensive data exports.

## What to Build

### 1. Audit Trail Summary API

- GET /audit/summary/ — Decision counts by type, by actor_type, recent activity count
- GET /audit/timeline/ — Paginated timeline of recent decisions with human-readable descriptions
- Both endpoints trainer-scoped (trainer sees own + trainee decisions)

### 2. Audit Data Export

- GET /export/decision-logs/ — CSV export of DecisionLog entries (filtered by date range)
- Include: timestamp, actor, decision_type, context summary, final_choice summary

### 3. Comprehensive Trainee Data Exports

- GET /export/trainee/{id}/workout-history/ — CSV of all workout sessions (sets, reps, weights, RPE)
- GET /export/trainee/{id}/nutrition-history/ — CSV of daily nutrition logs
- GET /export/trainee/{id}/progress/ — CSV of weight check-ins + e1RM history

### 4. Data Sources (already exist)

- DecisionLog + UndoSnapshot: audit trail
- LiftSetLog: per-set workout data
- TraineeActivitySummary: daily nutrition/workout/sleep
- WeightCheckIn: weight history
- LiftMax: e1RM history
- Existing exports: payments, subscribers, trainees (in trainer/export_views.py)

## What NOT to Build

- Web dashboard UI (backend API only)
- Mobile UI
- Admin-level exports (trainer-scoped only)
