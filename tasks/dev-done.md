# Dev Done: LiftSetLog + LiftMax + Max/Load Engine

## Date: 2026-03-09

## Files Changed

### Modified
- `backend/workouts/models.py` — Added LiftSetLog and LiftMax models with UUID PKs, proper indexes, unique constraints, and auto-computed canonical load/workload on save
- `backend/workouts/serializers.py` — Added LiftSetLogSerializer (create/read), LiftMaxSerializer (read-only), LiftMaxPrescribeSerializer (input validation)
- `backend/workouts/views.py` — Added LiftSetLogViewSet (full CRUD with row-level security) and LiftMaxViewSet (read-only with history + prescribe actions)
- `backend/workouts/urls.py` — Registered `lift-set-logs` and `lift-maxes` routes

### Created
- `backend/workouts/services/max_load_service.py` — MaxLoadService with e1RM estimation (Epley/Brzycki conservative), smoothing, TM calculation, load prescription with equipment rounding, auto-update from qualifying sets
- `backend/workouts/migrations/0020_liftmax_liftsetlog.py` — Migration for new models

## Key Decisions
1. LiftSetLog.save() auto-computes canonical_external_load_value (per-hand entries doubled) and set_workload_value (load × reps)
2. MaxLoadService.estimate_e1rm() takes conservative approach: lower of Epley/Brzycki formulas
3. e1RM smoothing: max 15% increase, max 10% decrease per update — prevents wild swings from bad data
4. Reps capped at 15 for e1RM estimation — formulas unreliable above that
5. RPE=10 with 1 rep → weight IS the 1RM (no formula needed)
6. update_max_from_set() auto-creates LiftMax on first qualifying set via get_or_create
7. Only standardization-passing sets with >0 reps and >0 load update e1RM
8. Prescribe endpoint returns null with reason when no LiftMax exists (not an error)
9. All service methods return frozen dataclasses (E1RMEstimate, LoadPrescription), not dicts
10. Row-level security: trainees see own data, trainers see their trainees', admins see all

## New API Endpoints
- `GET/POST /api/workouts/lift-set-logs/` — List/create set logs
- `GET/PUT/PATCH/DELETE /api/workouts/lift-set-logs/{id}/` — Set log detail
- `GET /api/workouts/lift-maxes/` — List trainee's current maxes
- `GET /api/workouts/lift-maxes/{id}/` — Max detail
- `GET /api/workouts/lift-maxes/{id}/history/` — e1RM + TM history for charting
- `POST /api/workouts/lift-maxes/prescribe/` — Load prescription

### Filters
- LiftSetLog: `?exercise_id=`, `?session_date=`, `?date_from=`, `?date_to=`, `?trainee_id=` (trainer/admin)
- LiftMax: `?trainee_id=` (trainer/admin)

## How to Test
1. `python manage.py migrate`
2. Create a trainee user
3. `POST /api/workouts/lift-set-logs/` with exercise, reps, load
4. Verify canonical_external_load and workload are auto-computed
5. Verify LiftMax was auto-created with e1RM and TM
6. `GET /api/workouts/lift-maxes/` — check current maxes
7. `GET /api/workouts/lift-maxes/{id}/history/` — check history arrays
8. `POST /api/workouts/lift-maxes/prescribe/` — verify load prescription
9. Log a per-hand set — verify canonical load is doubled
10. Log a set with standardization_pass=False — verify e1RM not updated
