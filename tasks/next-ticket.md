# Feature: Workload Engine — Aggregation, Trends, and Facts

## Priority
Critical — Step 4 of v6.5 build order. Foundation for progression engine, session feedback, and trainer analytics.

## User Story
As a **trainee**, I want to see how much total work I did per exercise, per session, and per week so I can track progressive overload and understand my training volume.

As a **trainer**, I want to see workload trends, spikes/dips, and muscle-group breakdowns across my trainees so I can make informed programming decisions.

## Acceptance Criteria
- [ ] WorkloadFactTemplate model for deterministic cool facts
- [ ] WorkloadAggregationService with exercise/session/weekly workload computation
- [ ] Workload-by-muscle-group distribution using Exercise.muscle_contribution_map
- [ ] Workload-by-pattern distribution using Exercise.pattern_tags
- [ ] WorkloadTrendService with acute:chronic workload ratio (7d/28d)
- [ ] Spike/dip detection with configurable thresholds
- [ ] Week-over-week delta computation
- [ ] WorkloadFactService with deterministic template selection and rendering
- [ ] Comparable session/exercise matching for delta comparisons
- [ ] API: exercise workload endpoint with comparison to last exposure
- [ ] API: session workload summary with top exercises and week-to-date
- [ ] API: weekly workload with muscle-group and pattern breakdowns
- [ ] API: trends endpoint with ACWR, spike/dip flags
- [ ] API: CRUD for WorkloadFactTemplate (trainer-facing)
- [ ] Row-level security on all endpoints
- [ ] All service methods return dataclasses, not dicts
- [ ] Only workload_eligible sets included in aggregations

## Edge Cases
1. No sets logged for session_date — return zero workload with empty breakdowns
2. All sets have workload_eligible=False — return zero with reason
3. Mixed units (lb_reps and kg_reps in same session) — aggregate separately by unit, flag mixed
4. Exercise with no muscle_contribution_map — attribute 100% to primary_muscle_group
5. Exercise with no pattern_tags — skip pattern attribution, don't error
6. No prior comparable session — comparison delta = null
7. < 28 days of data — ACWR = null (insufficient data)
8. Week boundary: use Monday-Sunday by default
9. Trainee with zero history — all endpoints return empty/null, not errors

## Technical Approach
- Create `backend/workouts/models.py` — add WorkloadFactTemplate model
- Create `backend/workouts/services/workload_service.py` — aggregation + trends + facts
- Add serializers and views
- Register routes
- No snapshot/cache models for now — compute on read (optimize later if needed)
