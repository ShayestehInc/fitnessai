# Security Audit: Pipeline 60 — Max/Load Engine (LiftSetLog, LiftMax, MaxLoadService)

## Audit Date: 2026-03-09

## Files Reviewed
- `backend/workouts/services/max_load_service.py`
- `backend/workouts/views.py` (LiftSetLogViewSet, LiftMaxViewSet)
- `backend/workouts/serializers.py` (LiftSetLogSerializer, LiftMaxSerializer, LiftMaxPrescribeSerializer)
- `backend/workouts/models.py` (LiftSetLog, LiftMax)
- `backend/workouts/urls.py` (router registrations)

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git diff
- [x] All user input sanitized (serializer validation on all numeric fields)
- [x] Authentication checked on all new endpoints (IsAuthenticated on both ViewSets)
- [x] Authorization — correct role/permission guards (row-level queryset filtering by role)
- [x] No IDOR vulnerabilities (history and prescribe endpoints use role-scoped querysets)
- [x] No file uploads in this feature
- [x] Rate limiting — not applicable (read-heavy endpoints, pagination in place)
- [x] Error messages don't leak internals (generic "not found" messages)
- [x] CORS policy — no changes

## Critical Issues Found & Fixed

### 1. `standardization_pass` Writable by Client (FIXED)

**Severity:** HIGH
**File:** `backend/workouts/serializers.py:1224`
**Issue:** `standardization_pass` was NOT in `read_only_fields`, meaning a trainee could submit `{"standardization_pass": true}` on any set they create. This bypasses the server-side standardization gate — the entire point of which is to control which sets qualify for e1RM updates. A malicious trainee could force arbitrary sets to update their estimated max, inflating their numbers and corrupting the load prescription system.

**Fix applied:** Added `standardization_pass` to `read_only_fields`. The field defaults to `False` (fail-closed) and should only be set by server-side logic evaluating standardization criteria.

### 2. `workload_eligible` Writable by Client (FIXED)

**Severity:** MEDIUM
**File:** `backend/workouts/serializers.py:1219`
**Issue:** `workload_eligible` was writable by the client. A trainee could set `workload_eligible=False` to exclude valid sets from workload calculations (hiding training volume from their trainer), or set it to `True` on timed-only sets where it should be `False`, skewing workload analytics.

**Fix applied:** Added `workload_eligible` to `read_only_fields`.

## Injection Vulnerabilities

None found. All database access uses Django ORM with parameterized queries. No raw SQL. Date filters in `LiftSetLogViewSet.get_queryset()` use `datetime.strptime` with explicit format validation and return `queryset.none()` on parse failure. The `notes` free-text field is rendered as JSON by DRF — no HTML injection vector.

## Auth & Authz Assessment (No Issues)

| Endpoint | Auth | Row-Level Security | Notes |
|----------|------|--------------------|-------|
| `POST /lift-set-logs/` | IsAuthenticated + trainee-only check in `perform_create` | `trainee=user` forced server-side | Trainee cannot create sets for other users |
| `GET /lift-set-logs/` | IsAuthenticated | Role-scoped queryset (admin=all, trainer=their trainees, trainee=self) | Correct |
| `GET /lift-set-logs/?trainee_id=X` | IsAuthenticated | Filter only applied for trainer/admin roles; queryset already scoped | Trainee cannot use `trainee_id` to access others' data |
| `GET /lift-maxes/` | IsAuthenticated | Same role-scoped queryset pattern | Correct |
| `GET /lift-maxes/history/` | IsAuthenticated | Uses `self.get_queryset()` which is role-scoped | No IDOR |
| `POST /lift-maxes/prescribe/` | IsAuthenticated | Trainee prescribes for self; trainer checked via `parent_trainer_id`; admin unrestricted | Correct |

### Prescribe Endpoint `trainee_id` Handling

The prescribe endpoint correctly handles `trainee_id`:
1. If user is a trainee, `trainee_id` is ignored and `trainee = user` is used.
2. If user is a trainer/admin, `trainee_id` is required.
3. Trainer ownership is verified: `trainee.parent_trainer_id != user.id` returns 404.
4. Error message is generic ("Trainee not found") — no information leakage about whether the trainee exists under a different trainer.

## Data Exposure Assessment

| Field | Exposure Risk | Status |
|-------|--------------|--------|
| `e1rm_history` / `tm_history` | Contains `source_set_id` UUIDs | Low risk — UUIDs are non-sequential, history endpoint is role-scoped |
| `trainee` FK on responses | User ID visible | Acceptable — needed for trainer dashboard; queryset scoped |
| `notes` free-text field | User-controlled content | JSON serialized, no HTML injection vector |

## Numeric Input Validation

| Field | Validation | Status |
|-------|-----------|--------|
| `entered_load_value` | Custom validator: `>= 0` | OK |
| `rpe` | Model validators: `MinValue(1)`, `MaxValue(10)` | OK |
| `completed_reps` | `PositiveIntegerField` (>= 0) | OK |
| `set_number` | `PositiveIntegerField` (>= 0) | OK |
| `target_percentage` | `min_value=1`, `max_value=120` | OK |
| `rounding_increment` | `min_value=0` | OK — service handles `<= 0` safely (skips rounding) |
| `tm_percentage` | Model validators: `MinValue(80)`, `MaxValue(100)` | OK |

## Service Layer Security

- `MaxLoadService.update_max_from_set()` uses `select_for_update()` row lock — prevents race conditions on concurrent set submissions.
- `@transaction.atomic` ensures consistency.
- History arrays capped at 200 entries — prevents unbounded JSON growth.
- Smoothing factors prevent a single malicious set from causing extreme e1RM swings (max 15% increase, max 10% decrease per update).
- Division-by-zero in Brzycki formula handled (`denominator <= 0` returns 0).

## Summary of Fixes Applied

1. **`standardization_pass`** added to `read_only_fields` in `LiftSetLogSerializer` — HIGH severity.
2. **`workload_eligible`** added to `read_only_fields` in `LiftSetLogSerializer` — MEDIUM severity.

## Security Score: 9/10

One high-severity issue found and fixed (client-writable `standardization_pass`). Otherwise, the implementation demonstrates strong security practices: role-scoped querysets, server-side field enforcement, proper input validation, row-level locking, no raw SQL, no secrets in code.

## Recommendation: PASS

All critical and high issues have been fixed. No remaining security concerns.
