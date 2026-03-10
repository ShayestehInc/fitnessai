# Architecture Review: Progression Engine (v6.5 Step 7)

## Review Date: 2026-03-09

## Files Reviewed

- `backend/workouts/services/progression_engine_service.py` (new, ~920 lines)
- `backend/workouts/models.py` (ProgressionProfile, ProgressionEvent)
- `backend/workouts/views.py` (ProgressionProfileViewSet, PlanSlotViewSet progression actions)
- `backend/workouts/serializers.py` (4 new serializers)
- `backend/workouts/urls.py` (route registration)
- `backend/workouts/migrations/0025_progression_engine.py`

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in views -- all computation in `progression_engine_service.py`
- [x] Consistent with existing patterns (DecisionLog integration, UUID PKs, JSONField for config)
- [x] Service returns frozen dataclasses, not dicts (per project rules)
- [x] ViewSet follows established RBAC pattern (Admin > Trainer > Trainee)

### Strengths

1. **Clean layering.** Views are thin -- they call service functions and serialize results. All progression logic lives in the service module. This is exactly right.
2. **Frozen dataclasses for return types.** `NextPrescription`, `ProgressionReadiness`, `ProgressionEventResult` are immutable. This prevents accidental mutation and makes the API contract clear.
3. **Evaluator dispatch pattern.** The `_EVALUATORS` dict maps progression type to evaluator function. Adding a 6th progression type is a one-function, one-dict-entry change. Excellent extensibility.
4. **DecisionLog integration.** Every `apply_progression` creates both a `ProgressionEvent` and a `DecisionLog` entry inside a transaction. Full audit trail from day one.
5. **Slot override > plan default resolution.** `_get_effective_profile()` is a clean, single-responsibility function. The FK chain is well-modeled with `SET_NULL` cascades.
6. **Proper `select_related` in ViewSet.** `PlanSlotViewSet.get_queryset()` prefetches `progression_profile`, `session__week__plan__trainee`, and `session__week__plan__default_progression_profile`. This covers the FK chain traversed by `_get_effective_profile`.

## Data Model Assessment

| Concern                            | Status           | Notes                                                                                                                                        |
| ---------------------------------- | ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Schema changes backward-compatible | PASS             | New FKs are nullable (`SET_NULL`), existing tables gain optional columns only                                                                |
| Migrations reversible              | PASS             | `AddField` and `CreateModel` are auto-reversible in Django                                                                                   |
| Indexes added for new queries      | PASS (after fix) | `ProgressionEvent` has `(trainee, exercise)` and `(plan_slot, -created_at)`. Added missing `(is_system, created_by)` on `ProgressionProfile` |
| No N+1 query patterns              | PASS             | View `select_related` covers service FK traversals. `_get_recent_sets` uses a single bounded query                                           |
| UUID PKs consistent                | PASS             | Both new models use `UUIDField(primary_key=True)`, matching `LiftSetLog`, `DecisionLog`, etc.                                                |

## Issues Found and Fixed

### 1. Bug: `_evaluate_wave_by_month` hardcodes `load_unit = 'lb'` (MAJOR)

**File:** `progression_engine_service.py:624`

Line 605 correctly calls `_resolve_load_unit(lift_max, sessions)` and assigns to `load_unit`, but line 624 overwrote it with `load_unit = 'lb'`. This means kg-based users always get `'lb'` as their unit in wave-by-month prescriptions.

**Fix applied:** Removed the erroneous `load_unit = 'lb'` reassignment.

### 2. Dead field: `reason` in `ApplyProgressionInputSerializer` (MAJOR)

**File:** `serializers.py:1666`, `views.py:4360`

The serializer accepts a `reason` field but the view never passed it to the service. Trainer overrides should have a reason logged in the audit trail.

**Fix applied:** Added `reason` parameter to `apply_progression()` service function. View now passes `reason=overrides.get('reason', '')`. Reason is stored in the `DecisionLog.context` dict.

### 3. Missing index on `ProgressionProfile.is_system` + `created_by` (MINOR)

**File:** `models.py:2729`

The ViewSet queries `Q(is_system=True) | Q(created_by=user)` but there was no composite index.

**Fix applied:** Added `Index(fields=['is_system', 'created_by'])` to model Meta. Generated migration `0026_progression_profile_index`.

### 4. Inline import of `dataclasses.replace` (MINOR)

**File:** `views.py:4347`

`from dataclasses import replace` was imported inline inside the `apply_progression` action method.

**Fix applied:** Import moved to module-level imports at top of file.

## Remaining Observations (No Fix Needed Now)

### 5. No pagination on `progression-history` endpoint

The `get_progression_history` function hardcodes `[:50]`. This is acceptable for now (50 events per slot is a reasonable upper bound for months of training), but should be converted to cursor pagination if event volume grows significantly.

### 6. `_get_recent_sets` index coverage

The query filters on `(trainee_id, exercise_id, session_date__gte)` but the index is `(trainee, exercise)`. A 3-column index `(trainee, exercise, session_date)` would allow an index-only range scan. However, the current 2-column index will still be used with a filter on session_date, and the `[:500]` limit bounds the scan. Fine for current scale.

### 7. `_LOWER_BODY_MUSCLES` set defined inside evaluator

The `_evaluate_rep_staircase` function defines `_LOWER_BODY_MUSCLES` as a local set on every call. Micro-optimization opportunity (move to module constant) but zero practical impact.

## Scalability Concerns

| #   | Area                 | Issue                                                                                    | Recommendation                                                                                                             |
| --- | -------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 1   | Query bounds         | `_get_recent_sets` limits to 500 rows, `get_progression_history` limits to 50            | Acceptable for current scale. Add pagination if needed later                                                               |
| 2   | Event table growth   | `ProgressionEvent` will grow linearly with applied progressions                          | Indexed correctly for the two access patterns (by trainee+exercise, by slot+time). No concern                              |
| 3   | JSONField validation | `rules`, `deload_rules`, `failure_rules` are loosely validated (just `isinstance(dict)`) | Consider adding per-type JSON schema validation as the system matures, but current approach is pragmatic for 5 known types |

## Technical Debt Introduced

| #   | Description                                                               | Severity | Suggested Resolution                                                                                                                          |
| --- | ------------------------------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Response dicts constructed manually in views instead of using serializers | Low      | Consider adding `NextPrescriptionSerializer` and `ProgressionReadinessSerializer` for consistency. Current approach works but is more fragile |
| 2   | Magic numbers in evaluators (e.g., `Decimal('100')`, `Decimal('0.90')`)   | Low      | These are domain constants. Could extract to named constants but readability is already good with surrounding context                         |

## Pattern Consistency

| Pattern                               | This Implementation                                                  | Verdict    |
| ------------------------------------- | -------------------------------------------------------------------- | ---------- |
| UUID PKs                              | Both new models                                                      | Consistent |
| Frozen dataclasses from services      | `NextPrescription`, `ProgressionReadiness`, `ProgressionEventResult` | Consistent |
| Service layer for business logic      | All 5 evaluators + 4 public API functions in service module          | Consistent |
| DRF serializer validation             | `ApplyProgressionInputSerializer` validates before hitting service   | Consistent |
| `select_related` / `prefetch_related` | Used correctly in ViewSet queryset                                   | Consistent |
| Row-level security in `get_queryset`  | Both new ViewSets implement role-based filtering                     | Consistent |
| `transaction.atomic()`                | `apply_progression` is transactional                                 | Consistent |
| DecisionLog audit trail               | Every applied progression creates a log entry                        | Consistent |

## Architecture Score: 8/10

The Progression Engine is well-architected and fits cleanly into the existing codebase patterns. The evaluator dispatch design makes the system easy to extend. The data model is sound with proper FK cascades, UUID PKs, and audit trail integration. The service layer is clean -- views contain zero business logic. Four issues were found: a unit-hardcoding bug in the wave evaluator, a dead serializer field, a missing index, and an inline import. All have been fixed. The one-point deduction from the prior review's 9/10 is for the manual response dict construction in views (instead of serializers) and the loosely validated JSONField configs, which add minor fragility.

## Recommendation: APPROVE
