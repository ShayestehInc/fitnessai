# Security Audit: Progression Engine (v6.5 Step 7)

## Audit Date: 2026-03-09

## Files Audited

- `backend/workouts/models.py` (ProgressionProfile, ProgressionEvent, PlanSlot FK, TrainingPlan FK)
- `backend/workouts/views.py` (ProgressionProfileViewSet, PlanSlotViewSet new actions)
- `backend/workouts/serializers.py` (ProgressionProfileSerializer, ApplyProgressionInputSerializer, ProgressionEventSerializer)
- `backend/workouts/services/progression_engine_service.py` (full service)
- `backend/workouts/urls.py` (route registration)
- `backend/workouts/management/commands/seed_progression_profiles.py`
- `backend/workouts/migrations/0025_progression_engine.py`
- `backend/workouts/tests/test_progression_engine.py`

## Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (only `testpass123` in test fixtures — standard practice)
- [x] All user input sanitized (serializer validation on all inputs, JSONField validated as dict)
- [x] Authentication checked on all new endpoints (IsAuthenticated on both ViewSets)
- [x] Authorization — correct role/permission guards (see details below)
- [x] No IDOR vulnerabilities (get_queryset scopes by role on both ViewSets)
- [N/A] File uploads validated — no file uploads in this feature
- [ ] Rate limiting on sensitive endpoints (apply-progression has no rate limit — see Minor #1)
- [x] Error messages don't leak internals (responses use structured dataclass fields)
- [x] CORS policy appropriate (no changes to CORS config)

## Secrets Scan

Grepped entire diff for: `password`, `secret`, `token`, `api_key`, `private_key`, `bearer`, `sk_live`, `pk_live`, `sk_test`, `pk_test`, `AKIA`, `credentials`.

**Result:** Only `password="testpass123"` in test fixtures. No real secrets found.

## Injection Vulnerabilities

| #   | Type | File:Line | Issue      | Fix |
| --- | ---- | --------- | ---------- | --- |
| —   | —    | —         | None found | —   |

All database access uses Django ORM (`filter()`, `get()`, `create()`, `update_or_create()`). No raw SQL. No string interpolation in queries. JSONField values are consumed via `.get()` with safe type conversions (`int()`, `Decimal(str(...))`). No command execution or path traversal vectors.

## Auth & Authz Issues

| #   | Severity | Endpoint | Issue      | Fix |
| --- | -------- | -------- | ---------- | --- |
| —   | —        | —        | None found | —   |

**Detailed AuthZ Analysis:**

1. **ProgressionProfileViewSet:**
   - `get_queryset()` scopes by role: ADMIN sees all, TRAINER sees system + own, TRAINEE sees system + their trainer's. Correct.
   - `perform_create()` blocks trainees. Admins get `is_system=True`, trainers get `is_system=False`. Correct.
   - `perform_update()` blocks trainees. Blocks non-admin from modifying system profiles. `is_system` and `created_by` are read-only in the serializer, preventing privilege elevation. Correct.
   - `perform_destroy()` blocks trainees. Blocks non-admin from deleting system profiles. Correct.
   - IDOR protection: `get_object()` goes through `get_queryset()`, so Trainer A cannot access Trainer B's custom profiles. Correct.

2. **PlanSlotViewSet new actions:**
   - `get_queryset()` filters: ADMIN sees all, TRAINER sees their trainees' slots (`session__week__plan__trainee__parent_trainer=user`), TRAINEE sees only own slots (`session__week__plan__trainee=user`). Correct.
   - `next-prescription` (GET): read-only, uses `get_object()` which enforces queryset scoping. Correct.
   - `apply-progression` (POST): explicitly blocks TRAINEE role with `PermissionDenied`. Uses `get_object()`. Correct.
   - `progression-history` (GET): read-only, uses `get_object()`. Correct.
   - `progression-readiness` (GET): read-only, uses `get_object()`. Correct.

3. **Service layer:** No direct auth checks needed — all access goes through view layer's `get_object()` which enforces queryset scoping. Service functions accept `trainee_id` and `actor_id` as parameters, never reading from request directly.

## Data Exposure Assessment

API responses return:

- `next-prescription`: exercise name, sets/reps/load, reason codes, confidence. No sensitive user data.
- `apply-progression`: event ID, old/new prescription, reason codes, decision log ID. No sensitive user data.
- `progression-history`: serialized events with exercise name, profile name, timestamps. No sensitive user data.
- `progression-readiness`: readiness status, blockers, session count, avg RPE, completion rate. No sensitive user data.
- `ProgressionProfileSerializer`: exposes `created_by` as FK integer ID. Acceptable — no PII exposed, just an integer ID used for ownership.

## Minor Issues (informational, not blocking)

| #   | Severity | Area             | Issue                                                                                                                                                                                                                                            | Recommendation                                                                                                                |
| --- | -------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| 1   | Low      | Rate limiting    | `apply-progression` endpoint has no rate limit. Rapid-fire calls could create many ProgressionEvents and DecisionLog entries.                                                                                                                    | Add throttling (e.g., 10/min per user) on the apply-progression action. Not exploitable — more of a DoS hardening measure.    |
| 2   | Low      | Input validation | JSONField contents (`rules`, `deload_rules`, `failure_rules`) are validated as dicts but not schema-validated per progression type. A trainer could submit `{"consecutive_failures_for_deload": 0}` causing every computation to trigger deload. | Add per-type schema validation in the serializer's `validate()` method. Data integrity concern, not a security vulnerability. |
| 3   | Low      | Error handling   | If a trainer provides an invalid value in `rules` JSON (e.g., `{"step_pct": "not_a_number"}`), the `Decimal(str(...))` conversion raises an unhandled exception, returning a 500.                                                                | Wrap evaluator rule parsing in try/except with a descriptive 400 error.                                                       |

## Dependencies

No new dependencies were added in this feature. No `requirements.txt` changes.

## Security Score: 9/10

**Deductions:**

- -1 for lack of rate limiting on the state-mutating `apply-progression` endpoint and missing JSON schema validation on profile rules. These are hardening measures, not exploitable vulnerabilities.

## Recommendation: PASS

No Critical or High severity issues found. All endpoints have proper authentication and role-based authorization. Row-level security is enforced via `get_queryset()` scoping on both ViewSets. No secrets leaked. No injection vectors. No IDOR vulnerabilities. The three minor issues are informational and relate to robustness rather than exploitable security flaws.
