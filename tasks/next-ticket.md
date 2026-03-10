# Feature: LiftSetLog + LiftMax + Max/Load Engine

## Priority
Critical — Step 3 of v6.5 build order. Foundation for workload engine, progression, and session runner.

## User Story
As a **trainee**, I want every set I perform to be tracked as a structured record (weight, reps, RPE, standardization pass) so the app can calculate my estimated 1RM, prescribe intelligent loads, and track my strength over time.

As a **trainer**, I want to see my trainees' per-set performance data and estimated maxes so I can make informed programming decisions.

## Acceptance Criteria
- [ ] LiftSetLog model with all v6.5 fields (exercise FK, weight, reps, RPE, standardization_pass, load entry modes, canonical load, workload fields)
- [ ] LiftMax model (per exercise per trainee) with e1RM, TM, history arrays
- [ ] MaxLoadService with e1RM estimation (Epley + Brzycki, conservative), TM calculation, load prescription with equipment rounding
- [ ] Only standardization-passing sets update e1RM
- [ ] LiftSetLog CRUD API (trainees create, trainers read their trainees')
- [ ] LiftMax read API with history endpoint
- [ ] Load prescription endpoint
- [ ] Row-level security on all endpoints
- [ ] Proper indexes for performance
- [ ] All service methods return dataclasses, not dicts

## Edge Cases
1. Set with 0 reps — should not update e1RM
2. Set with RPE=10 (true max) — e1RM = weight (no formula needed)
3. Very high reps (>15) — e1RM formulas less accurate, cap at 15 for estimation
4. Bodyweight exercise — canonical_external_load_value may be 0
5. Per-hand entry (dumbbells) — canonical load = entered_load * 2
6. No existing LiftMax for exercise — create one on first qualifying set
7. e1RM going DOWN — smoothing should allow decrease but not wild swings
8. Load prescription with no LiftMax — return null with reason

## Technical Approach
- Add models to `backend/workouts/models.py`
- Create `backend/workouts/services/max_load_service.py`
- Add serializers and viewsets
- Register routes
