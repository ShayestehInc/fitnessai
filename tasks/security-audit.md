# Security Audit: Trainee Workout History + Home Screen Recent Workouts

**Date:** 2026-02-14
**Auditor:** Security Engineer (Senior Application Security)
**Pipeline:** 8

**Files Audited (Backend):**
- `backend/workouts/serializers.py` — `WorkoutHistorySummarySerializer`, `WorkoutDetailSerializer`
- `backend/workouts/views.py` — `WorkoutHistoryPagination`, `workout_history` action, `workout_detail` action
- `backend/workouts/tests/test_workout_history.py` — 30 test cases covering security, filtering, serialization

**Files Audited (Mobile):**
- `mobile/lib/core/constants/api_constants.dart`
- `mobile/lib/core/router/app_router.dart`
- `mobile/lib/features/workout_log/data/models/workout_history_model.dart`
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart`
- `mobile/lib/features/workout_log/presentation/providers/workout_history_provider.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_history_screen.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_history_widgets.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_screen.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_detail_widgets.dart`
- `mobile/lib/features/home/presentation/providers/home_provider.dart`
- `mobile/lib/features/home/presentation/screens/home_screen.dart`

**Files Audited (Tasks/Docs):**
- `tasks/dev-done.md`, `tasks/next-ticket.md`, `tasks/focus.md`, `tasks/qa-report.md`, `tasks/review-findings.md`

---

## Executive Summary

This audit covers the implementation of a read-only workout history feature: a paginated backend endpoint, a workout detail endpoint, a history screen with infinite scroll, a detail screen, and a "Recent Workouts" section on the home screen. **No Critical or High issues were found.** The implementation demonstrates strong security practices: proper row-level security via `IsTrainee` + queryset filtering, restricted serializers that exclude sensitive fields, no secrets in code or docs, and no injection vectors. Two Minor issues and one Informational item are documented below.

**Issues Found:**
- 0 Critical
- 0 High
- 2 Minor
- 1 Informational

---

## Security Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (scanned entire diff from `main...HEAD`)
- [x] All user input sanitized (read-only endpoints; no user-supplied input beyond pagination params)
- [x] Authentication checked on all new endpoints (`IsTrainee` includes `is_authenticated` check)
- [x] Authorization -- correct role/permission guards (`IsTrainee` on both endpoints)
- [x] No IDOR vulnerabilities (queryset filters by `trainee=user` from `request.user`)
- [x] File uploads validated (N/A -- no file uploads in this feature)
- [x] Rate limiting on sensitive endpoints (inherited from DRF global throttling)
- [x] Error messages don't leak internals
- [x] CORS policy appropriate (inherited from existing config)

---

## Secrets Scan

### Scan Methodology

Grepped the entire `git diff main...HEAD` output (including all `.py`, `.dart`, `.md`, and test fixture files) for:
- API keys, secret keys, passwords, tokens, bearer tokens
- Hardcoded credentials in test fixtures
- AWS, OpenAI, Stripe key patterns
- Base64-encoded secrets

### Results: PASS

**Test fixtures use dummy passwords:**
```python
# test_workout_history.py
password='testpass123'  # Safe: test-only, force_authenticate() used
```

These are test-only fixtures using `force_authenticate()` for API tests, which is the correct Django REST Framework testing pattern. The passwords are never used for actual authentication and are only required by `create_user()`.

**No secrets found in any changed files**, including:
- No API keys in `.md` files or comments
- No tokens in URL constants
- No credentials in error messages or log strings
- No `.env` files modified or created

---

## Injection Vulnerabilities

### SQL Injection: PASS

All database queries use Django ORM with parameterized inputs:

```python
# views.py:409-423 — workout_history action
queryset = DailyLog.objects.filter(
    trainee=user,
).exclude(
    workout_data__isnull=True,
).exclude(
    workout_data={},
).filter(
    Q(workout_data__has_key='exercises') | Q(workout_data__has_key='sessions'),
).exclude(
    Q(workout_data__has_key='exercises') & Q(workout_data__exercises=[]),
).defer(
    'nutrition_data',
).order_by('-date')
```

**Analysis:**
- All queries use ORM methods, no raw SQL
- JSONField lookups (`has_key`, `__exercises=[]`) use PostgreSQL's native JSON operators via Django's ORM, not string concatenation
- Pagination parameters (`page`, `page_size`) are parsed by DRF's `PageNumberPagination`, which validates them as integers internally
- No user-supplied strings are interpolated into queries

### XSS: PASS (N/A)

These are read-only API endpoints returning JSON data. The mobile Flutter client renders data in native widgets (not WebView), so XSS is not applicable. The API does not serve HTML.

Workout names from `workout_data` JSON are displayed via Flutter's `Text` widget, which does not interpret HTML or JavaScript.

### Command Injection: N/A

No system commands are executed in the audited code.

### Path Traversal: N/A

No file system operations are performed. The `workoutHistoryDetail(int logId)` URL builder in Dart uses integer interpolation, which cannot produce path traversal:

```dart
static String workoutHistoryDetail(int logId) =>
    '$apiBaseUrl/workouts/daily-logs/$logId/workout-detail/';
```

The `int` type constraint makes injection impossible at the Dart level.

---

## Auth & Authz Issues

### Authentication: PASS

Both new endpoints require authentication via `IsTrainee`, which checks `is_authenticated`:

```python
# core/permissions.py:19-27
class IsTrainee(permissions.BasePermission):
    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and  # <-- Auth check
            request.user.is_trainee()
        )
```

**Verified Endpoints:**

| Endpoint | Permission Class | Auth Check | Role Check |
|----------|-----------------|------------|------------|
| `GET /api/workouts/daily-logs/workout-history/` | `IsTrainee` | `is_authenticated` | `is_trainee()` |
| `GET /api/workouts/daily-logs/{id}/workout-detail/` | `IsTrainee` | `is_authenticated` | `is_trainee()` |

**Test Coverage:**
- `test_unauthenticated_user_rejected` -- verifies 401 for unauthenticated requests
- `test_trainer_cannot_access_endpoint` -- verifies 403 for trainers
- `test_admin_cannot_access_endpoint` -- verifies 403 for admins
- `test_detail_trainer_forbidden` -- verifies 403 for trainer on detail endpoint
- `test_detail_unauthenticated_rejected` -- verifies 401 for unauthenticated on detail

### Authorization (IDOR Prevention): PASS

Row-level security is enforced through the queryset:

**Workout History (list):**
```python
# views.py:409 — direct filter by trainee=user
queryset = DailyLog.objects.filter(
    trainee=user,  # <-- user from request.user, not URL params
)
```

**Workout Detail (single object):**
```python
# views.py:446 — uses get_object(), which goes through get_queryset()
daily_log = self.get_object()
```

`DailyLogViewSet.get_queryset()` filters by `trainee=user` for trainees (line 371), so `get_object()` will only find objects belonging to the authenticated user. Attempting to access another user's log returns 404 (not 403), which prevents enumeration.

**Test Coverage:**
- `test_trainee_sees_own_logs_only` -- creates logs for 2 trainees, verifies isolation
- `test_trainee_cannot_see_other_trainees_logs` -- verifies cross-trainee isolation
- `test_detail_for_other_users_log_returns_404` -- verifies 404 (not 403) for IDOR attempt

---

## Data Exposure

### API Response Analysis: PASS

**WorkoutHistorySummarySerializer (list endpoint):**
```python
class Meta:
    model = DailyLog
    fields = [
        'id', 'date', 'workout_name', 'exercise_count',
        'total_sets', 'total_volume_lbs', 'duration_display',
    ]
    read_only_fields = ['id', 'date']
```

Fields that are explicitly **NOT** exposed:
- `trainee` (FK to User) -- no user ID leaked
- `trainee_email` -- no email leaked
- `nutrition_data` -- private dietary data not exposed
- `workout_data` (full JSON) -- only computed summaries returned in list
- `steps`, `sleep_hours`, `resting_heart_rate`, `recovery_score` -- health metrics hidden
- `created_at`, `updated_at` -- timestamps hidden

Compare with the main `DailyLogSerializer`, which exposes `trainee`, `trainee_email`, and `nutrition_data`. The new serializers are correctly restricted.

**WorkoutDetailSerializer (detail endpoint):**
```python
class Meta:
    model = DailyLog
    fields = ['id', 'date', 'workout_data', 'notes']
    read_only_fields = ['id', 'date', 'workout_data', 'notes']
```

The detail endpoint returns `workout_data` (needed for the detail screen) but correctly excludes `nutrition_data`, `trainee`, and all health metrics.

Additionally, the `workout_history` queryset uses `.defer('nutrition_data')` to avoid even loading the large nutrition blob from the database -- this is good defense-in-depth.

**Test Coverage:**
- `test_no_extra_sensitive_fields_exposed` -- verifies `trainee_email`, `nutrition_data`, `trainee` not in history response
- `test_detail_returns_restricted_fields_only` -- verifies detail response has exactly `{id, date, workout_data, notes}`
- `test_detail_does_not_leak_nutrition_data` -- verifies `nutrition_data`, `trainee_email`, `trainee` not in detail response

### Error Messages: PASS

Error messages are generic and do not leak internals:

```python
# 404 for non-existent or other user's log
# Handled by DRF's get_object() returning standard 404

# Mobile error messages:
'Unable to load workout history'  # Generic
'Failed to load workout detail'   # Generic
"Couldn't load recent workouts"   # Generic
```

No stack traces, SQL errors, or file paths are exposed.

---

## CORS/CSRF

### CORS: PASS (Inherited)

CORS configuration is unchanged and follows best practices:
- Development: `CORS_ALLOW_ALL_ORIGINS = True` (acceptable for local dev)
- Production: Restricted to `CORS_ALLOWED_ORIGINS` from environment variable
- `CORS_ALLOW_CREDENTIALS = True` (required for JWT auth)

### CSRF: PASS (N/A for API)

Both new endpoints are GET requests using JWT authentication (not session/cookie auth). Django REST Framework disables CSRF for API views using JWT, which is correct behavior. No state-changing operations are exposed by these endpoints.

---

## Minor Issues

### 1. Pagination `page_size` Not Validated as Positive Integer on Client Side

**Severity:** Minor
**File:** `mobile/lib/features/workout_log/data/repositories/workout_repository.dart:117-128`
**Status:** ACCEPTABLE

**Analysis:**
The `page_size` parameter is passed as a query parameter. While DRF's `PageNumberPagination` enforces `max_page_size = 50` on the server side, the client does not validate that `pageSize` is positive. However, this is a client-side concern only -- a negative or zero `pageSize` would result in DRF using its default page size (20).

**Risk:** None. Server-side validation is in place (`max_page_size = 50` in `WorkoutHistoryPagination`). The client always passes valid values (default 20, or 3 for recent workouts).

### 2. Test Passwords Are Identical Across All Test Users

**Severity:** Minor
**File:** `backend/workouts/tests/test_workout_history.py:33-48`
**Status:** ACCEPTABLE

**Analysis:**
All test users use `password='testpass123'`. This is irrelevant for security because:
- Tests use `force_authenticate()`, not actual password authentication
- Test database is ephemeral and destroyed after test runs
- This is standard Django testing practice

**Risk:** None.

---

## Informational

### 1. Pre-Existing Debug Endpoint on ProgramViewSet

**File:** `backend/workouts/views.py:319-347`
**Status:** PRE-EXISTING (not introduced by this PR)

The `ProgramViewSet` has a `debug` action that exposes user details (email, role, parent_trainer). This endpoint existed before this PR and is not part of the audited changes. However, it should be removed or restricted before production:

```python
@action(detail=False, methods=['get'])
def debug(self, request: Request) -> Response:
    """Debug endpoint to diagnose program visibility issues."""
    user = cast(User, request.user)
    return Response({
        'user': {
            'id': user.id,
            'email': user.email,  # <-- Exposes email
            'role': user.role,
            'parent_trainer_id': user.parent_trainer_id,
            'parent_trainer_email': user.parent_trainer.email if user.parent_trainer else None,
        },
        # ...
    })
```

**Recommendation:** This is outside the scope of this PR but should be tracked as a separate cleanup item. The endpoint is protected by `IsAuthenticated` so it only exposes data to the authenticated user, but debug endpoints should not exist in production.

---

## Security Strengths

1. **Explicit `fields` lists in serializers** -- Both new serializers use explicit `fields` lists (not `'__all__'`), preventing accidental exposure of new model fields in the future.

2. **`.defer('nutrition_data')`** -- The history queryset defers loading of `nutrition_data`, providing defense-in-depth even though the serializer doesn't include it.

3. **`read_only_fields` on all exposed fields** -- Both serializers mark all fields as read-only, preventing any write operations through these endpoints.

4. **404 for IDOR attempts** -- Accessing another user's log returns 404 (not 403), preventing object enumeration attacks.

5. **Comprehensive test coverage** -- 30 tests covering authentication, authorization, IDOR, data filtering, and data exposure. Specific tests verify that sensitive fields are not leaked.

6. **`max_page_size = 50`** -- Pagination is capped, preventing resource exhaustion via large page requests.

7. **Type-safe URL construction on mobile** -- `workoutHistoryDetail(int logId)` uses Dart's type system to prevent injection via the URL.

---

## Security Score: 9.5/10

**Breakdown:**
- **Authentication:** 10/10 (Both endpoints require `IsTrainee` with auth check)
- **Authorization:** 10/10 (Row-level security via queryset, IDOR returns 404)
- **Input Validation:** 9/10 (Server-side pagination limits, no user input accepted beyond params)
- **Output Encoding:** 10/10 (Restricted serializers, no sensitive data exposed)
- **Secrets Management:** 10/10 (No hardcoded secrets in any file)
- **Error Handling:** 9/10 (Generic error messages, no internal leaks)
- **Data Exposure:** 10/10 (Explicit field lists, `.defer()` for unused blobs, tested)
- **Test Coverage:** 10/10 (30 security-relevant tests including IDOR, auth, data leakage)

**Deductions:**
- -0.5: Pre-existing debug endpoint in ProgramViewSet (not introduced by this PR, but noted)

---

## Recommendation: PASS

**Verdict:** The implementation is **secure for production**. No Critical or High issues found. The code demonstrates strong security practices with proper authentication, authorization, data exposure controls, and comprehensive test coverage. No fixes were required.

**Ship Blockers:** None.

---

**Audit Completed:** 2026-02-14
**Next Review:** Standard review cycle
