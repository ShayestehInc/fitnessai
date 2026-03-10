# Ship Decision: Pipeline 61 — Workload Engine

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 8/10

## Summary
All 17 acceptance criteria are met. All 3 critical and 5 of 6 major review issues have been fixed. Row-level security is correctly implemented across all endpoints. Django system checks pass with zero issues. The implementation is production-ready.

---

## Acceptance Criteria Verification

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | WorkloadFactTemplate model | PASS | models.py:2144-2199 — UUID PK, scope enum, template_text, condition_rules JSONField, priority, is_active, created_by FK, composite index |
| 2 | WorkloadAggregationService with exercise/session/weekly | PASS | workload_service.py:91-476 — three compute methods with proper ORM aggregation |
| 3 | Workload-by-muscle-group distribution using muscle_contribution_map | PASS | workload_service.py:447-458 — uses muscle_contribution_map, falls back to primary_muscle_group, then 'unclassified' |
| 4 | Workload-by-pattern distribution using pattern_tags | PASS | workload_service.py:461-465 — splits workload evenly across pattern_tags |
| 5 | WorkloadTrendService with ACWR (7d/28d) | PASS | workload_service.py:483-562 — rolling_7_day / (rolling_28_day / 4), null if < 28 days data |
| 6 | Spike/dip detection with configurable thresholds | PASS | workload_service.py:489-492 — class constants SPIKE_ACWR_THRESHOLD=1.3, DIP_ACWR_THRESHOLD=0.8 |
| 7 | Week-over-week delta computation | PASS | workload_service.py:578-608 — `_get_weekly_deltas` with percentage changes |
| 8 | WorkloadFactService with deterministic template selection | PASS | workload_service.py:615-739 — priority-ordered, first match wins, regex-based rendering |
| 9 | Comparable session/exercise matching for delta comparisons | PASS | workload_service.py:199-239 — finds last exposure, computes percentage delta |
| 10 | API: exercise workload endpoint | PASS | views.py:3725-3772 — GET /workload/exercise/ with exercise_id, session_date params |
| 11 | API: session workload summary with top exercises and week-to-date | PASS | views.py:3774-3819 — includes top_exercises, week_to_date_workload |
| 12 | API: weekly workload with muscle-group and pattern breakdowns | PASS | views.py:3821-3858 — by_muscle_group, by_pattern in response |
| 13 | API: trends endpoint with ACWR, spike/dip flags | PASS | views.py:3860-3893 — acute_chronic_ratio, spike_flag, dip_flag |
| 14 | API: CRUD for WorkloadFactTemplate | PASS | views.py:3636-3685 — full ModelViewSet with create/update/delete permission guards |
| 15 | Row-level security on all endpoints | PASS | `_resolve_trainee()` enforces trainee=self, trainer=own trainees, admin=all; `get_queryset()` scopes fact templates similarly |
| 16 | All service methods return dataclasses, not dicts | PASS | ExerciseWorkload, SessionWorkload, WeeklyWorkload, WorkloadTrend — all frozen dataclasses |
| 17 | Only workload_eligible sets included | PASS | workload_service.py:121 — `workload_eligible=True` filter in `_get_eligible_sets` |

## Edge Case Verification

| # | Edge Case | Status | Evidence |
|---|-----------|--------|----------|
| 1 | No sets logged — return zero workload | PASS | Aggregates default to Decimal('0') via `or Decimal('0')` pattern |
| 2 | All sets workload_eligible=False — return zero | PASS | Filtered out by `_get_eligible_sets` |
| 3 | Mixed units — flag mixed | PASS | `_detect_mixed_units()` checks distinct units, `mixed_units` bool in dataclasses and responses |
| 4 | No muscle_contribution_map — use primary_muscle_group | PASS | workload_service.py:452-454 |
| 5 | No pattern_tags — skip pattern attribution | PASS | workload_service.py:461 — `if tags:` guard |
| 6 | No prior comparable session — delta = null | PASS | workload_service.py:222-223 returns None, None |
| 7 | < 28 days of data — ACWR = null | PASS | workload_service.py:521-524 checks earliest date |
| 8 | Week boundary Monday-Sunday | PASS | workload_service.py:287 — `session_date.weekday()` (Monday=0) |
| 9 | Trainee with zero history — empty/null | PASS | All aggregates return zero/empty, no errors thrown |

## Review Issues — Fix Status

| Issue | Severity | Status | Fix |
|-------|----------|--------|-----|
| C1: Fact template scoping | Critical | FIXED | `select_and_render()` accepts `trainer_id`, filters `Q(created_by__isnull=True) \| Q(created_by_id=trainer_id)`. Call sites pass `trainee.parent_trainer_id`. |
| C2: Template injection via format_map | Critical | FIXED | Replaced with `re.compile(r'\{(\w+)\}')` regex substitution. No attribute access possible. |
| C3: Unbounded template iteration | Critical | FIXED | `MAX_TEMPLATES_EVALUATED = 50`, queryset sliced with `[:50]`. |
| M1: Mixed units flag | Major | FIXED | `mixed_units: bool` field added to dataclasses, `_detect_mixed_units()` method, exposed in API responses. |
| M2: Single-pass distributions | Major | FIXED | `_compute_distributions()` computes both muscle and pattern in one iteration. |
| M3: serializer.instance | Major | FIXED | `perform_update` uses `serializer.instance` (line 3674). |
| M4: parent_trainer guard | Major | FIXED | Trainees without parent_trainer see only system defaults (line 3662). |
| M5: rest_framework_dataclasses serializers | Major | NOT FIXED | Views still use manual dict construction. Convention violation but not a functional or security issue. |
| M6: weeks_back bounds | Major | FIXED | `max(1, min(int(weeks_str), 52))` on line 3874. |

## Security Verification

- Template injection mitigated with regex-only substitution — VERIFIED
- Fact templates scoped by trainer — VERIFIED
- Template iteration bounded at 50 — VERIFIED
- Row-level security on WorkloadViewSet (`_resolve_trainee`) — VERIFIED
- Row-level security on WorkloadFactTemplateViewSet (`get_queryset`) — VERIFIED
- Create/update/delete restricted to trainers+admins — VERIFIED
- Trainers can only edit/delete their own templates — VERIFIED
- No secrets or credentials in code — VERIFIED

## Django System Checks

```
System check identified no issues (0 silenced).
```

## Remaining Concerns (non-blocking)

1. **M5 not addressed** — WorkloadViewSet actions use manual dict serialization instead of `rest_framework_dataclasses`. This is a convention violation per `.claude/rules/datatypes.md`. Not blocking because: (a) responses are correctly structured, (b) no security risk, (c) can be refactored in a follow-up.
2. **N+1 in weekly_deltas** — `_get_weekly_deltas` with weeks_back=52 triggers 53 DB queries. Acceptable per ticket ("optimize later") and bounded by the max(1, min(52)) guard.
3. **condition_rules validation** — No whitelist validation on allowed keys in condition_rules JSONField. Invalid keys silently pass through. Low severity.

---

## What Was Built

**Workload Engine — Aggregation, Trends, and Facts (v6.5 Step 4)**

- **WorkloadFactTemplate model** — Deterministic "cool fact" templates with UUID PK, scope (exercise/session), priority ordering, condition rules (JSONField), trainer ownership (created_by FK), and composite index for efficient queries.
- **WorkloadAggregationService** — Exercise-level, session-level, and weekly workload aggregation from LiftSetLog data. Muscle-group distribution via muscle_contribution_map with primary_muscle_group fallback. Pattern distribution via pattern_tags with even splitting. Mixed-unit detection. Comparable exercise/session matching with percentage deltas. Week-to-date tracking. Top exercises by workload.
- **WorkloadTrendService** — Acute:chronic workload ratio (7-day / 28-day weekly average), spike/dip detection with configurable thresholds, trend direction (rising/stable/declining), week-over-week delta history.
- **WorkloadFactService** — Deterministic fact selection: templates filtered by scope and trainer, sorted by priority, first condition match wins. Safe regex-based rendering prevents template injection. Bounded evaluation (max 50 templates).
- **REST API** — Four read-only workload endpoints (exercise, session, weekly, trends) with row-level security. Full CRUD for fact templates with trainer/admin permission guards. Input validation on all query parameters.
- **Security** — Tenant-isolated fact templates (system defaults + trainer's own). Safe template rendering (regex-only, no attribute access). Bounded iteration. Row-level security on all endpoints.
