# Focus: Trainer Packet v6.5 — Step 15: Analytics + Correlations + Dashboards

## Priority

Critical — Step 15 of the v6.5 build order. Builds correlation engine on top of existing analytics infrastructure.

## What to Build

### 1. Correlation Analytics Service

- Protein adherence ↔ strength gains (e1RM progression rate)
- Sleep hours ↔ volume tolerance (next-day workout volume)
- Calorie adherence ↔ weight change trend
- Workout consistency ↔ nutrition logging adherence
- Exercise-specific progression patterns (fastest/slowest gaining exercises)

### 2. Pattern Detection

- Trainee-level pattern detection: what's working, what's stalling
- Cohort comparison: high-adherence vs low-adherence outcome differences
- Alerts: plateaus, overtraining risk, deload effectiveness

### 3. API Endpoints

- GET /analytics/correlations/ — Overview correlations for trainer's trainees
- GET /analytics/trainee/{id}/patterns/ — Per-trainee insights
- GET /analytics/cohort/ — Cohort comparison (high vs low adherence)

### 4. Data Sources (already exist)

- TraineeActivitySummary: daily nutrition/workout/sleep
- LiftSetLog + LiftMax: per-set performance + e1RM history
- WeightCheckIn: weight trends
- Existing analytics: adherence, retention, revenue

## What NOT to Build

- Web dashboard UI (backend API only)
- Mobile UI
- Nightly batch jobs (compute on demand)
