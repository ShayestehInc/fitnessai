# Architecture Review: Session Runner v6.5 Step 8

## Review Date

2026-03-09

## Files Reviewed

- `backend/workouts/services/session_runner_service.py`
- `backend/workouts/services/rest_timer_service.py`
- `backend/workouts/session_views.py`
- `backend/workouts/session_serializers.py`
- `backend/workouts/models.py` (ActiveSession, ActiveSetLog)

## Architectural Alignment

- [x] Follows existing layered architecture (service layer holds all business logic)
- [x] Models/schemas in correct locations
- [x] No business logic in views -- views are thin dispatchers to service functions
- [x] Consistent with existing patterns (dataclass returns from services, DRF serializers for wire format)
- [x] Service functions return frozen dataclasses, not dicts
- [x] DecisionLog audit trail on every state transition
- [x] Row-level security enforced in ViewSet `get_queryset()` and `_resolve_trainee()`

### Strengths

1. **Transaction discipline.** Every mutation uses `transaction.atomic()` with `select_for_update()`. The partial unique constraint at the DB level (`unique_active_session_per_trainee` WHERE `status='in_progress'`) is the right approach for preventing concurrent active sessions -- application-level checks alone are insufficient under concurrency.
2. **IDOR protection.** `start_session` verifies `plan_session.week.plan.trainee_id` matches the caller. The ViewSet `get_queryset()` enforces role-based row filtering. The error message intentionally returns "not found" rather than "forbidden" to avoid information leakage.
3. **Graceful degradation.** Progression engine failures are caught, logged to DecisionLog, and returned as error results rather than crashing the session. The fallback prescription in `_get_prescription_for_slot` ensures sessions can always start.
4. **Stale session auto-abandonment.** Practical solution for sessions left open. Completed sets from stale sessions are preserved in LiftSetLog -- partial data is real data.
5. **Clean layering.** Views are 100% thin. Serializers handle validation only. All state machine logic, set lookup, slot advancement, LiftSetLog creation, and progression evaluation live in the service module.
6. **Denormalized exercise on ActiveSetLog.** Smart trade-off documented in help_text. Avoids a join through PlanSlot on every set read.

## Data Model Assessment

| Concern                            | Status | Notes                                                                                                            |
| ---------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------- |
| Schema changes backward-compatible | PASS   | UUID PKs, SET_NULL on plan references -- sessions survive plan deletion                                          |
| Partial unique constraint          | PASS   | `unique_active_session_per_trainee` on `(trainee)` WHERE `status='in_progress'` prevents dual-active at DB level |
| Indexes for hot paths              | PASS   | `(trainee, status)` and `(trainee, -created_at)` on ActiveSession; `(active_session, status)` on ActiveSetLog    |
| Unique set constraint              | PASS   | `(active_session, plan_slot, set_number)` prevents duplicate set logging                                         |
| No N+1 query patterns              | FIXED  | See issue #1 below                                                                                               |

## Issues Found and Fixed

### 1. FIXED -- Stale data / redundant query in `_build_session_status` (Major)

**Files:** `session_runner_service.py` (log_set, skip_set, \_build_session_status)

`log_set()` and `skip_set()` both fetched all set logs with `select_for_update()` inside a transaction, mutated them, then called `_build_session_status(session)` **outside** the transaction. That function called `session.set_logs.all()` which had no prefetch cache on the session object, causing:

- A redundant DB round-trip on every set log/skip (the hottest path in the system)
- Potential for reading stale data if another request interleaved between the transaction commit and the re-fetch

The code comments claimed "Build status from in-memory data instead of re-fetching (M8 fix)" but the implementation did not actually do this.

**Fix:** Added an optional `set_logs: list[ActiveSetLog] | None` parameter to `_build_session_status()`. When provided, uses the list directly instead of querying `session.set_logs.all()`. Both `log_set` and `skip_set` now pass their in-memory `all_set_logs` list. This eliminates the extra query and guarantees data consistency.

### 2. FIXED -- Duplicated set-log lookup logic (Minor)

**Files:** `session_runner_service.py` (log_set, skip_set)

Both `log_set()` and `skip_set()` contained identical 25-line blocks for: fetching all set logs with `select_for_update`, scanning for a matching `(slot_id, set_number)`, and validating the set is pending. This violates DRY and increases the surface area for divergent bugs.

**Fix:** Extracted `_fetch_and_find_pending_set(session, slot_id, set_number)` helper that returns `(target_set_log, all_set_logs)`. Both callers now use a single function call.

### 3. FIXED -- `_resolve_trainee` returned `Any` (Minor)

**File:** `session_views.py` line 284

The return type was `Any` instead of `User`, violating the project's strict typing rules.

**Fix:** Changed return type to `User`, added `from users.models import User` import.

## Issues Documented (Not Fixed -- Require Design Decisions)

### 4. Rest timer sentinel value design (Low)

**File:** `rest_timer_service.py` line 59-60

The M7 comment documents a known limitation: if a trainer intentionally sets rest to exactly 90s, it is indistinguishable from "not explicitly set." A proper fix requires a schema change (`rest_seconds_override` nullable field or a boolean flag on PlanSlot). This is acceptable tech debt for now but should be tracked.

### 5. `SessionSummary.progression_results` typed as `list[dict[str, Any]]` (Low)

**File:** `session_runner_service.py` line 113

This violates the project rule "never return dict from services." The progression results should use a frozen dataclass. The blast radius is contained (only constructed in `_run_progression_evaluation` and serialized immediately by `ProgressionResultSerializer`). Recommend converting to a `ProgressionResult` dataclass in a future pass.

## Scalability Concerns

| #   | Area                           | Issue                                                                                                                                                                                                                                  | Status     |
| --- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| 1   | Set log scan                   | `_fetch_and_find_pending_set` does a linear scan over all set logs to find a match. For typical sessions (5-8 exercises x 3-5 sets = 15-40 rows) this is negligible. Would only matter at >1000 sets which is not a realistic workout. | Acceptable |
| 2   | `_auto_abandon_stale_sessions` | Runs on every `start_session` and `get_active_session` call. Queries with `select_for_update` which acquires row locks. For a single trainee the lock contention is minimal. No cross-trainee impact.                                  | Acceptable |
| 3   | `_create_lift_set_logs`        | Calls `MaxLoadService.update_max_from_set()` in a per-row loop after `bulk_create`. This is O(n) DB calls for n completed sets. Acceptable for session completion (happens once per session, typical n=15-40).                         | Acceptable |
| 4   | Progression evaluation         | Calls `compute_next_prescription` + `apply_progression` per slot on completion. O(slots) with typical count 5-8.                                                                                                                       | Acceptable |

## Technical Debt Introduced

| #   | Description                                                | Severity | Suggested Resolution                             |
| --- | ---------------------------------------------------------- | -------- | ------------------------------------------------ |
| 1   | `progression_results` as `list[dict]` instead of dataclass | Low      | Create `ProgressionResult` frozen dataclass      |
| 2   | Rest timer sentinel value (90s ambiguity)                  | Low      | Add nullable `rest_seconds_override` to PlanSlot |

## Pattern Consistency

| Pattern                               | This Implementation                                                              | Verdict    |
| ------------------------------------- | -------------------------------------------------------------------------------- | ---------- |
| UUID PKs                              | Both new models                                                                  | Consistent |
| Frozen dataclasses from services      | `SessionStatus`, `SessionSummary`, `SetStatus`, `SlotStatus`, `RestPrescription` | Consistent |
| Service layer for business logic      | All public functions + helpers in service module                                 | Consistent |
| DRF serializer validation             | Input serializers validate before hitting service                                | Consistent |
| `select_related` / `prefetch_related` | Used correctly in ViewSet queryset and service functions                         | Consistent |
| Row-level security in `get_queryset`  | Role-based filtering (Admin/Trainer/Trainee)                                     | Consistent |
| `transaction.atomic()`                | Every state mutation is transactional with `select_for_update`                   | Consistent |
| DecisionLog audit trail               | Session start, complete, abandon, and progression failures all logged            | Consistent |
| Error handling via domain exceptions  | `SessionError` with error codes, mapped to HTTP status in views                  | Consistent |

## Architecture Score: 8/10

The Session Runner is well-architected. Clean service/view/serializer layering. Strong transaction safety with both application-level and DB-level concurrency controls. Solid data model with appropriate constraints, indexes, and FK cascade behaviors. The REST API design is consistent and RESTful with proper error code mapping. Three issues were found and fixed: a redundant query / stale data bug on the hottest code path (`log_set`/`skip_set`), duplicated lookup logic, and a missing type annotation. The remaining items (sentinel rest value, dict return type for progression results) are low-severity and can be addressed in future iterations without architectural risk.

## Recommendation: APPROVE
