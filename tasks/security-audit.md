# Security Audit: Session Runner (v6.5 Step 8)

## Audit Date

2026-03-09

## Files Audited

- `backend/workouts/services/session_runner_service.py`
- `backend/workouts/services/rest_timer_service.py`
- `backend/workouts/session_views.py`
- `backend/workouts/session_serializers.py`
- `backend/workouts/models.py` (ActiveSession, ActiveSetLog additions)
- `backend/workouts/migrations/0027_add_active_session_models.py`
- `backend/workouts/urls.py`

## Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (audited full diff)
- [x] All user input sanitized (DRF serializers validate all inputs)
- [x] Authentication checked on all new endpoints (`permission_classes = [IsAuthenticated]`)
- [x] Authorization -- correct role/permission guards (`_resolve_trainee` enforces TRAINEE role; `get_queryset` enforces row-level security)
- [x] No IDOR vulnerabilities (PlanSession ownership verified in `start_session`; `get_queryset` filters by trainee/trainer/admin; opaque 404 on unauthorized access)
- [x] File uploads validated (N/A -- no file uploads in this feature)
- [ ] Rate limiting on sensitive endpoints (see Low issue L1 below)
- [x] Error messages don't leak internals (opaque 404 for IDOR, generic error codes, no stack traces)
- [x] CORS policy appropriate (no changes to CORS config)

## Secrets Scan

No secrets, API keys, passwords, tokens, or credentials found in any new or modified files, including code comments, docstrings, and test fixtures.

## Injection Vulnerabilities

| #   | Type | File:Line | Issue      | Fix |
| --- | ---- | --------- | ---------- | --- |
| --  | --   | --        | None found | --  |

All database access uses Django ORM (no raw SQL). All user inputs are validated via DRF serializers with explicit field types, min/max values, and choice constraints. UUIDs are validated as UUIDs. No string interpolation into queries. `notes` and `reason` fields are stored as-is in the DB but never rendered as HTML or used in queries -- XSS protection is a frontend concern handled by Flutter (not rendering HTML).

## Auth & Authz Issues

| #   | Severity | Endpoint | Issue      | Fix |
| --- | -------- | -------- | ---------- | --- |
| --  | --       | --       | None found | --  |

### Detailed Auth/Authz Analysis

**IDOR on PlanSession (previously C1):**
VERIFIED FIXED. `start_session()` at line 173 checks `plan_session.week.plan.trainee_id != trainee_id` and returns an opaque "Plan session not found" 404 -- does not reveal whether the session exists for other users.

**Role enforcement (previously C2):**
VERIFIED FIXED. `_resolve_trainee()` at line 294 checks `user.role != 'TRAINEE'` and raises `PermissionDenied(403)`. Impersonation works because JWT is swapped to the trainee user. Trainers and admins cannot directly call session endpoints without impersonation.

**Row-level security in `get_queryset()`:**
VERIFIED. Lines 117-134: Admin sees all, Trainer sees `trainee__parent_trainer=user`, Trainee sees `trainee=user`. This correctly filters all list/retrieve/detail-action operations because `get_object()` is scoped by `get_queryset()`.

**Service-layer ownership:**
All mutating service functions (`log_set`, `skip_set`, `complete_session`, `abandon_session`) receive `active_session_id` which was already filtered through `get_queryset()` in the view layer via `self.get_object()`. No bypass possible.

## Race Condition Analysis

**1. One-active-session constraint:**
SAFE. Dual defense: (a) Python-level check at line 150-159, (b) DB-level partial unique constraint `unique_active_session_per_trainee` with `IntegrityError` catch at line 202-207. Even under concurrent requests, the DB constraint prevents duplicates.

**2. Set logging (`log_set`, `skip_set`):**
SAFE. Both functions use `transaction.atomic()` with `select_for_update()` on the session (line 307) and all set logs (line 315). This prevents concurrent requests from double-logging the same set.

**3. Session completion/abandonment:**
SAFE. `complete_session` and `abandon_session` both use `transaction.atomic()` + `select_for_update()` on the session. Status transition is guarded by `_validate_session_mutable()`.

**4. Stale session cleanup (previously C4):**
VERIFIED FIXED. `_auto_abandon_stale_sessions()` at line 749 uses `transaction.atomic()` + `select_for_update()` to prevent concurrent cleanup from creating duplicate `LiftSetLog` entries.

**5. `_build_session_status` outside transaction (log_set/skip_set):**
LOW RISK. After the transaction commits, `_build_session_status` re-reads set logs. A concurrent request could see slightly stale data in the response, but this is a display-only consistency issue, not a security vulnerability. The DB state is correct.

## Data Exposure Assessment

**Response payloads:**

- `trainee_id` (integer PK) is exposed in `SessionStatusResponseSerializer`. This is the user's own ID, visible only to themselves or their authorized trainer/admin. Acceptable -- not an enumeration vector since the endpoint is scoped by `get_queryset()`.
- No email, password hash, or PII fields are exposed.
- `plan_session_id`, `slot_id`, `set_log_id` are UUIDs -- not enumerable.
- Error messages use generic codes (`plan_session_not_found`, `set_not_found`) -- do not reveal whether a resource exists for other users.

**DecisionLog entries:**
Contain `trainee_id`, `actor_id`, slot/session IDs, and set counts. These are internal audit records not exposed via API. Acceptable.

## Issues Found and Fixed

### High Issues

| #   | Severity | File:Line                    | Issue                                                                                                                                                                                                                              | Status                                                  |
| --- | -------- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| H1  | High     | `session_serializers.py:199` | `notes` field in `LogSetInputSerializer` had no `max_length` -- allows unbounded input. An attacker could send multi-megabyte payloads in the notes field, causing memory/storage abuse. The model uses `TextField` with no limit. | **FIXED** -- Added `max_length=1000` to the serializer. |

### Low Issues

| #   | Severity | File:Line                       | Issue                                                                                                                                                                                                                                 | Status                                                                       |
| --- | -------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| L1  | Low      | `session_views.py`              | No explicit rate limiting on POST endpoints (`start`, `log-set`, `skip-set`, `complete`, `abandon`). A malicious user could spam session creation or set logging. DRF throttling may be configured globally but is not verified here. | Noted -- recommend verifying global throttle settings cover these endpoints. |
| L2  | Low      | `session_runner_service.py:333` | Error message in `log_set`/`skip_set` includes `slot_id` in the message: `f'Set {set_number} for slot {slot_id} not found.'`. The slot_id comes from the user's own request input, so this is not information leakage.                | Acceptable -- no fix needed.                                                 |
| L3  | Low      | `session_serializers.py:73`     | `ActiveSessionSerializer` exposes the `trainee` FK field (integer PK) in list/detail responses. Acceptable since responses are scoped to authorized users only.                                                                       | Acceptable -- no fix needed.                                                 |

## Positive Security Patterns Observed

1. **Opaque error responses for IDOR:** Plan session not found returns same 404 regardless of whether the resource exists or belongs to another user.
2. **UUID primary keys:** ActiveSession and ActiveSetLog use UUIDs, preventing enumeration attacks.
3. **DB-level constraints:** Partial unique constraint on active sessions is a strong defense-in-depth layer.
4. **select_for_update everywhere:** All state mutations are properly locked.
5. **Serializer-based input validation:** All inputs go through DRF serializers with explicit types, ranges, and choices.
6. **Service layer separation:** Views handle auth/authz, services handle business logic. No direct model manipulation in views.
7. **Audit trail:** DecisionLog entries created for all session lifecycle events.

## Security Score: 9/10

**Deductions:**

- -1 for the unbounded `notes` input field (H1, now fixed) and lack of explicit rate limiting on session endpoints (L1).

## Recommendation: PASS

No Critical issues. One High issue (unbounded notes input) was found and fixed in-place. Auth/authz is solid with defense-in-depth (view-layer queryset scoping + service-layer ownership checks + DB constraints). Race conditions are properly handled via `select_for_update` and DB-level unique constraints. No secrets, no injection vectors, no IDOR vulnerabilities. The low issues are hardening recommendations, not exploitable flaws.
