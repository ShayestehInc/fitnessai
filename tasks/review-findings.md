# Code Review: Client Session Runner (Backend Only) — v6.5 Step 8

## Review Date

2026-03-09

## Files Reviewed

- `backend/workouts/models.py` (ActiveSession, ActiveSetLog additions)
- `backend/workouts/services/session_runner_service.py` (new)
- `backend/workouts/services/rest_timer_service.py` (new)
- `backend/workouts/session_serializers.py` (new)
- `backend/workouts/session_views.py` (new)
- `backend/workouts/urls.py` (modified)
- `backend/workouts/migrations/0027_add_active_session_models.py` (new)

---

## Critical Issues (must fix before merge)

| #   | File:Line                           | Issue                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Suggested Fix                                                                                                                                                                                                                                                                                                                                                                  |
| --- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| C1  | `session_runner_service.py:160-169` | **IDOR: No ownership check on PlanSession.** `start_session()` fetches the PlanSession by PK without verifying it belongs to the requesting trainee. A trainee can start a session from any other trainee's plan by guessing/knowing the UUID. The chain is `TrainingPlan.trainee -> PlanWeek -> PlanSession`, but this is never checked.                                                                                                                                                                                                 | After fetching `plan_session`, verify `plan_session.week.plan.trainee_id == trainee_id`. If not, raise `SessionError('plan_session_not_found', ...)` (opaque 404 per ticket convention). The `select_related('week__plan')` is already there on line 162, so just add the check.                                                                                               |
| C2  | `session_views.py:267-274`          | **No role enforcement on mutating endpoints.** `_resolve_trainee()` just returns `request.user` unconditionally. A TRAINER or ADMIN making a direct request (not impersonating) would have `start_session` called with their own user ID, creating an ActiveSession for a non-trainee user. The ticket says "All endpoints enforce trainee-only access (403 for trainer/admin unless impersonating)". The `get_queryset()` filters reads, but `start/log-set/skip-set/complete/abandon` all use `_resolve_trainee()` which bypasses that. | `_resolve_trainee()` must check `request.user.role`. If TRAINER/ADMIN and NOT impersonating, return 403. Check for impersonation context (likely via `request.user` already being swapped by middleware, but verify the middleware is active and confirm `request.user.role == 'TRAINEE'`). At minimum, add: `if request.user.role != 'TRAINEE': raise PermissionDenied(...)`. |
| C3  | `session_serializers.py:93-110`     | **N+1 queries in `ActiveSessionSerializer`.** `get_total_sets`, `get_completed_sets`, `get_skipped_sets`, `get_pending_sets`, and `get_progress_pct` each issue a separate DB query via `obj.set_logs.count()` and `obj.set_logs.filter(...)`. When serializing a list of sessions, this fires 5 queries PER session. Even for the detail view it's 5 unnecessary queries when set_logs are already prefetched.                                                                                                                           | Either annotate the queryset with counts (`Count('set_logs', filter=Q(...))`) and read from annotations, or compute all counts from the prefetched `set_logs` in a single pass using `all()` on the prefetched manager (which doesn't hit the DB). Example: `logs = list(obj.set_logs.all()); return sum(1 for l in logs if l.status == ...)`.                                 |
| C4  | `session_runner_service.py:719-744` | **`_auto_abandon_stale_sessions` is not atomic and has no `select_for_update`.** Multiple concurrent requests could both read the same stale session and attempt to abandon it + create LiftSetLogs simultaneously, leading to duplicate LiftSetLog entries. The function also iterates sessions one-by-one without a transaction.                                                                                                                                                                                                        | Wrap the entire function in `transaction.atomic()` and use `select_for_update()` on the stale sessions queryset.                                                                                                                                                                                                                                                               |

---

## Major Issues (should fix)

| #   | File:Line                           | Issue                                                                                                                                                                                                                                                                                                                                                                           | Suggested Fix                                                                                                                                                                          |
| --- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| M1  | `session_runner_service.py:205-207` | **`is_last_set_map` logic is confusingly written.** `is_last_set_map = {slot.sets: True}` creates a dict `{N: True}`, then `is_last = set_num in is_last_set_map` checks if `set_num` is a KEY. This happens to produce correct behavior (only set number N maps to True), but the code is a one-entry-dict hack.                                                               | Replace with: `is_last = (set_num == slot.sets)`. Clear, correct, and obvious.                                                                                                         |
| M2  | `session_runner_service.py:752-793` | **`_maybe_advance_slot_index` fires an extra DB query for set_logs inside an already-open transaction.** Both `log_set()` and `skip_set()` already have the session locked via `select_for_update`, but `_maybe_advance_slot_index` re-fetches ALL set_logs from the DB (line 757-762). This is unnecessary overhead inside a critical path.                                    | Pass the set_logs (or at least the current slot's logs) into `_maybe_advance_slot_index` to avoid the redundant query.                                                                 |
| M3  | `session_runner_service.py:808-832` | **`_create_lift_set_logs` saves LiftSetLog entries one-by-one in a loop** (`lsl.save()` on line 826) instead of using `bulk_create`. For a session with 20+ sets, this is 20+ INSERT statements plus 20+ `MaxLoadService.update_max_from_set` calls.                                                                                                                            | Use `bulk_create` for the LiftSetLog entries, then loop only for `MaxLoadService.update_max_from_set` calls. This reduces INSERT queries from N to 1.                                  |
| M4  | `session_runner_service.py:868-893` | **`_run_progression_evaluation` silently swallows exceptions** (line 888: `except Exception`). If progression evaluation fails for a slot, it logs a warning and continues. Failed progressions are not logged to DecisionLog, so there is no audit trail of the failure.                                                                                                       | At minimum, create a DecisionLog entry for failed progression evaluations. Consider narrowing the exception type. The user should see in the `progression_results` that a slot failed. |
| M5  | `session_runner_service.py:693-716` | **`_get_prescription_for_slot` catches bare `Exception`** (line 695). This hides bugs in the progression engine. If `compute_next_prescription` raises `TypeError` or `AttributeError` due to a coding error, it will be silently swallowed and the trainee gets a fallback prescription with no notification.                                                                  | Narrow the exception to expected types (e.g., `ValueError`, `LookupError`) or at minimum log at ERROR level rather than WARNING.                                                       |
| M6  | `session_views.py:128-143`          | **List endpoint has no default pagination.** If a trainee has hundreds of historical sessions, `GET /sessions/` returns them all unbounded. `paginate_queryset` on line 137 only paginates if `pagination_class` is set on the viewset, but it isn't.                                                                                                                           | Add `pagination_class = ...` to the viewset using the project's standard paginator.                                                                                                    |
| M7  | `rest_timer_service.py:85`          | **Fragile trainer override detection.** The code treats `plan_slot.rest_seconds != 90` as "trainer explicitly set it." But 90 is both the PlanSlot field default AND a legitimate value a trainer might intentionally set. If a trainer sets rest to 90, it falls through to modality/role logic instead of being honored as an override.                                       | Consider adding a nullable `rest_seconds_override` field or a boolean flag. As a less invasive fix, document this limitation clearly.                                                  |
| M8  | `session_runner_service.py:297-347` | **`log_set` and `skip_set` re-fetch session from DB for `get_session_status` after the transaction.** Lines 347 and 397 call `get_session_status(active_session_id)` which issues a fresh query with `select_related` and `prefetch_related`. The entire session+set_logs were just fetched inside the transaction. This doubles the query cost of every log-set/skip-set call. | Build the `SessionStatus` from the data already in memory, or accept the tradeoff and document it.                                                                                     |

---

## Minor Issues (nice to fix)

| #   | File:Line                                           | Issue                                                                                                                                                                                                                                                                                                                                                       | Suggested Fix                                                                                                                              |
| --- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| m1  | `session_serializers.py:20-25`                      | **Serializers use `ModelSerializer` instead of `rest_framework_dataclasses`** as required by project convention (`.claude/rules/datatypes.md` says "For api responses, always use rest_framework_dataclasses, not normal serializer"). The service already returns dataclasses; the response serializers at lines 229-295 should use `DataclassSerializer`. | Refactor to use `rest_framework_dataclasses.DataclassSerializer` for the response serializers, or document why the deviation is justified. |
| m2  | `session_runner_service.py:799`                     | **`session_date` parameter typed as `Any`** instead of `datetime.date`. Project rules say type hints on everything, no `Any` unless unavoidable.                                                                                                                                                                                                            | Change to `session_date: date` (import `date` from `datetime`).                                                                            |
| m3  | `session_runner_service.py:112`                     | **`progression_results` in `SessionSummary` typed as `list[dict[str, Any]]`** — project rules prefer dataclasses/Pydantic over dicts for return types.                                                                                                                                                                                                      | Create a `ProgressionResultSummary` frozen dataclass instead of using raw dicts.                                                           |
| m4  | `session_views.py:132-134`                          | **Status filter on list endpoint accepts arbitrary strings.** `request.query_params.get('status')` is passed directly to `qs.filter(status=status_filter)` without validating it's a valid `ActiveSession.Status` choice. Invalid values return empty results silently.                                                                                     | Validate against `ActiveSession.Status.values` and return 400 if invalid.                                                                  |
| m5  | `models.py` (ActiveSetLog Meta)                     | **Default ordering `['plan_slot__order', 'set_number']` forces a JOIN with PlanSlot on every query.** This adds overhead to simple counts/filters.                                                                                                                                                                                                          | Consider removing the default ordering or adding a denormalized `slot_order` field on ActiveSetLog.                                        |
| m6  | `session_runner_service.py:438, 509, 731, 785, 793` | **`update_fields` includes `'updated_at'` but this is an `auto_now` field.** Django automatically includes `auto_now` fields in updates. Including it explicitly is harmless but misleading.                                                                                                                                                                | Remove `'updated_at'` from `update_fields` for clarity across all occurrences.                                                             |
| m7  | `session_runner_service.py:582`                     | \*\*`slot_map` uses `str                                                                                                                                                                                                                                                                                                                                    | None`as key type.** If`plan_slot_id`is None for multiple set logs (after slot deletion), they all collapse into one group under`None`.     | Add a comment explaining the None-key grouping behavior. |

---

## Security Concerns

1. **IDOR on PlanSession (C1):** A trainee can start a session from any PlanSession in the system. The PlanSession lookup on line 162 uses only PK, not filtering by trainee ownership through the `PlanSession -> PlanWeek -> TrainingPlan.trainee` chain. This is the most serious security issue.

2. **No role guard on write endpoints (C2):** A trainer or admin can hit `POST /sessions/start/` and create an ActiveSession for themselves. The DB `limit_choices_to={'role': 'TRAINEE'}` only applies in Django admin/forms, NOT in programmatic API usage.

3. **Stale session auto-abandon race (C4):** Without atomicity, concurrent requests can create duplicate LiftSetLog entries from the same stale session's completed sets.

---

## Performance Concerns

1. **5x N+1 in `ActiveSessionSerializer` (C3):** Each serialized session triggers 5 extra queries for counts.
2. **Double-fetch on every log_set/skip_set (M8):** Session + all set_logs fetched twice per call.
3. **Per-row INSERT for LiftSetLog (M3):** N individual INSERTs instead of 1 bulk_create.
4. **`_maybe_advance_slot_index` re-fetches all set_logs (M2):** Unnecessary additional query within transaction.
5. **Default ordering with JOIN on ActiveSetLog (m5):** Every query on ActiveSetLog joins PlanSlot.

---

## Acceptance Criteria Verification

| Criterion                                       | Status             | Notes                                                                                          |
| ----------------------------------------------- | ------------------ | ---------------------------------------------------------------------------------------------- |
| ActiveSession model fields                      | PASS               | All required fields present, correct types                                                     |
| ActiveSetLog model fields                       | PASS               | All required fields present                                                                    |
| One active session constraint                   | PASS               | Partial unique constraint + service-level check                                                |
| `start_session` creates session + pre-populates | PASS               | Works correctly                                                                                |
| `get_current_prescription`                      | PARTIAL            | No standalone function — embedded in `get_session_status`. Ticket asked for a separate method. |
| `log_set`                                       | PASS               | Validates, updates, auto-advances                                                              |
| `skip_set`                                      | PASS               | Works correctly                                                                                |
| `complete_session`                              | PASS               | Validates all done, creates LiftSetLogs, triggers progression                                  |
| `abandon_session`                               | PASS               | Saves completed sets, no progression eval                                                      |
| `get_session_status`                            | PASS               | Returns full state                                                                             |
| `get_active_session`                            | PASS               | Auto-abandons stale first                                                                      |
| Row-level security in service                   | FAIL               | No ownership check on PlanSession in `start_session` (C1)                                      |
| DecisionLog for all transitions                 | PASS               | start, complete, abandon all logged                                                            |
| Rest timer defaults                             | PASS               | Correct values                                                                                 |
| Rest timer trainer override                     | PASS (with caveat) | Works but fragile for rest_seconds=90 (M7)                                                     |
| Rest timer modality override                    | PASS               | Implemented                                                                                    |
| Between-exercise bonus                          | PASS               | +30s on last set                                                                               |
| All API endpoints                               | PASS               | All 8 endpoints registered                                                                     |
| JWT auth required                               | PASS               | `IsAuthenticated` permission                                                                   |
| Trainee-only access                             | FAIL               | No role check (C2)                                                                             |
| 409 on active session conflict                  | PASS               | Correct error code + active_session_id                                                         |
| 400 on completed/abandoned session              | PASS               | Correct error codes                                                                            |
| 404 for different trainee's session             | PASS               | via `get_queryset` filtering                                                                   |
| Integration with progression engine             | PASS               | Both compute and apply called                                                                  |
| Serializers present                             | PASS               | All required serializers created                                                               |
| Error responses include code + message          | PASS               | Consistent format                                                                              |

### Edge Cases

| #   | Edge Case                        | Status                                                                        |
| --- | -------------------------------- | ----------------------------------------------------------------------------- |
| 1   | Active session conflict (409)    | PASS                                                                          |
| 2   | Log on completed/abandoned (400) | PASS                                                                          |
| 3   | All sets skipped for slot        | PASS — no LiftSetLog, no progression                                          |
| 4   | Zero-slot PlanSession            | PASS                                                                          |
| 5   | No progression profile           | PASS — fallback prescription                                                  |
| 6   | Abandon with partial data        | PASS                                                                          |
| 7   | Stale session auto-abandon       | PASS (race condition concern: C4)                                             |
| 8   | Concurrent API calls             | PARTIAL — `select_for_update` on session/set_log but stale cleanup not atomic |
| 9   | Superset modality interleaving   | OUT OF SCOPE per ticket                                                       |
| 10  | Zero reps logged                 | PASS — `min_value=0` on serializer                                            |
| 11  | Plan deleted mid-session         | PASS — `SET_NULL` on FKs                                                      |

---

## Quality Score: 5/10

The core business logic is well-structured and the overall architecture is solid — service layer separation, frozen dataclasses, DecisionLog integration, proper `select_for_update` on the happy path, and correct edge case handling for most scenarios. However, two critical security issues (IDOR on PlanSession and missing role enforcement) make this unshippable. The N+1 query issues in the serializer and the race condition in stale session cleanup compound the concern. The code demonstrates strong architectural thinking but needs a security and performance pass before merge.

## Recommendation: BLOCK

**Blocking reasons:**

1. **C1 (IDOR):** Any trainee can start a session from any other trainee's plan — data privacy violation.
2. **C2 (No role guard):** Trainers and admins can create sessions for themselves, bypassing the trainee-only intent.
3. **C3 (N+1):** 5 unnecessary queries per serialized session will cause performance degradation at scale.
4. **C4 (Race in stale cleanup):** Potential for duplicate LiftSetLog entries from concurrent requests.
