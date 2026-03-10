# Security Audit: v6.5 ExerciseCard + DecisionLog + UndoSnapshot

## Audit Date: 2026-03-09

## Files Audited
- `backend/workouts/models.py` — Exercise v6.5 fields, DecisionLog, UndoSnapshot models
- `backend/workouts/serializers.py` — ExerciseSerializer, DecisionLogSerializer, UndoSnapshotSerializer
- `backend/workouts/views.py` — ExerciseViewSet filter updates, DecisionLogViewSet + undo action
- `backend/workouts/urls.py` — Router registration for decision-logs
- `backend/workouts/services/decision_log_service.py` — DecisionLogService
- `backend/workouts/management/commands/backfill_exercise_tags.py` — Tag backfill command
- `backend/config/settings.py` — No new secrets or config changes

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history for these changes
- [x] All user input sanitized (serializer validates tags, contribution map, query params validated)
- [x] Authentication checked on all new endpoints (IsAuthenticated on both ViewSets)
- [x] Authorization — correct role/permission guards (get_queryset scoped by role, undo restricted to trainer/admin)
- [x] No IDOR vulnerabilities — **FIXED** (see Critical #1 below)
- [x] File uploads validated (no new upload endpoints)
- [x] Rate limiting on sensitive endpoints (global throttle applies)
- [x] Error messages don't leak internals (ValueError messages are user-facing, no stack traces)
- [x] CORS policy appropriate (unchanged)

## Critical Issues Found & Fixed

### 1. IDOR on DecisionLog Undo Endpoint (FIXED)

**Severity:** Critical
**File:** `backend/workouts/views.py:3361`
**Issue:** The `undo` action checked that the user is a trainer/admin but did NOT verify the decision belongs to the user's scope. A Trainer A could undo decisions belonging to Trainer B's trainees by knowing/guessing the UUID.

The `get_queryset()` method correctly scopes DecisionLog records per role (trainers only see their own + their trainees' decisions), but the `undo` action bypassed this by passing the UUID directly to `DecisionLogService.undo_decision()` without checking membership in the queryset.

**Fix applied:** Added `self.get_queryset().filter(id=decision_uuid).exists()` check before calling the service. Returns 404 if the decision is not in the user's scope. This follows the same IDOR-prevention pattern used elsewhere in the codebase.

### 2. ExerciseSerializer `is_public` and `created_by` Were Writable (FIXED)

**Severity:** High
**File:** `backend/workouts/serializers.py:57`
**Issue:** `is_public` and `created_by` were in `fields` but NOT in `read_only_fields`. While `perform_create` correctly sets these on creation, a PUT/PATCH request could override them — allowing a trainer to set `is_public=True` on their custom exercise (making it visible to all users) or change `created_by` to another user.

**Fix applied:** Added `'is_public', 'created_by'` to `read_only_fields`. These fields are now exclusively controlled by `perform_create` logic.

## No Issues Found In

| Area | Status | Notes |
|------|--------|-------|
| Secrets in code | PASS | All sensitive values loaded from env vars via `os.getenv()` |
| Injection (SQL/XSS) | PASS | Django ORM used throughout, no raw SQL. ArrayField/JSONField values validated by serializers. Query param filters use ORM lookups (not raw interpolation). |
| Auth middleware | PASS | Both ExerciseViewSet and DecisionLogViewSet use `IsAuthenticated`. DecisionLog undo further restricts to trainer/admin. |
| Data exposure | PASS | DecisionLogSerializer is fully read-only. UndoSnapshot before/after_state contains domain data (exercise slots, etc.) which is appropriate for trainers to see. No sensitive PII is stored in snapshots. |
| Input validation | PASS | Tag fields validated against TextChoices enums in serializer. `muscle_contribution_map` validated for valid keys and sum-to-1.0. Query param filters validated against choice sets with `queryset.none()` fallback for invalid values. |
| Backfill command | PASS | Management command only reads/writes Exercise model data. No external input. `--dry-run` flag supported. Uses `bulk_update` safely. |

## Security Score: 9/10
## Recommendation: PASS

Both critical/high issues were fixed inline. No remaining security concerns.
