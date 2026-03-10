# Dev Done: Workload Engine — Aggregation, Trends, and Facts

## Date: 2026-03-09

## Files Changed

### Modified
- `backend/workouts/models.py` — Added WorkloadFactTemplate model
- `backend/workouts/serializers.py` — Added WorkloadFactTemplateSerializer
- `backend/workouts/views.py` — Added WorkloadFactTemplateViewSet (CRUD) and WorkloadViewSet (aggregation + trends)
- `backend/workouts/urls.py` — Registered `workload-facts` and `workload` routes

### Created
- `backend/workouts/services/workload_service.py` — WorkloadAggregationService, WorkloadTrendService, WorkloadFactService
- `backend/workouts/migrations/0022_workloadfacttemplate.py` — Migration

## Key Decisions
1. No snapshot/cache models — compute on read for simplicity. Can optimize later if needed.
2. No WorkloadFormula registry — only one formula exists (load × reps), already computed on LiftSetLog.save()
3. Muscle distribution uses Exercise.muscle_contribution_map; falls back to primary_muscle_group if no map; "unclassified" if neither
4. Pattern distribution splits workload evenly across all pattern_tags for multi-tagged exercises
5. Week boundary: Monday-Sunday (ISO standard)
6. ACWR requires ≥28 days of data — returns null otherwise
7. Spike/dip detection uses configurable thresholds (ACWR > 1.3 = spike, < 0.8 = dip)
8. Fact selection is deterministic: templates sorted by priority, first match wins
9. SafeFormatDict for template rendering — missing placeholders become empty strings
10. All service methods return frozen dataclasses

## New API Endpoints
- `GET /api/workouts/workload/exercise/?exercise_id=&session_date=&trainee_id=` — exercise workload
- `GET /api/workouts/workload/session/?session_date=&trainee_id=` — session workload summary
- `GET /api/workouts/workload/weekly/?week_start=&trainee_id=` — weekly with muscle/pattern breakdowns
- `GET /api/workouts/workload/trends/?trainee_id=&weeks_back=` — ACWR, spike/dip flags, weekly deltas
- CRUD `/api/workouts/workload-facts/` — fact template management (trainer/admin)

## How to Test
1. `python manage.py migrate`
2. Create trainee, log sets via lift-set-logs endpoint
3. `GET /api/workouts/workload/exercise/?exercise_id=1&session_date=2026-03-09` — verify aggregation
4. `GET /api/workouts/workload/session/?session_date=2026-03-09` — verify session total + top exercises
5. `GET /api/workouts/workload/weekly/` — verify muscle/pattern breakdowns
6. `GET /api/workouts/workload/trends/` — verify ACWR, trend direction
7. Create WorkloadFactTemplate, verify fact selection in exercise/session responses
