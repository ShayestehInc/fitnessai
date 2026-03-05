# Security Audit: Notification Preferences, Reminders & Dead UI Cleanup (Pipeline 42)

## Audit Date: 2026-03-04

## Files Audited

### Backend
1. `backend/users/models.py` -- NotificationPreference model with VALID_CATEGORIES frozenset
2. `backend/users/views.py` -- NotificationPreferenceView (GET/PATCH)
3. `backend/users/serializers.py` -- NotificationPreferenceSerializer
4. `backend/core/services/notification_service.py` -- `_check_notification_preference`, `send_push_to_group` category filtering
5. `backend/users/urls.py` -- New route for notification-preferences
6. `backend/users/migrations/0008_add_notification_preference.py`
7. `backend/users/tests/test_notification_preferences.py`
8. `backend/community/views.py` -- Added `category='community_activity'`
9. `backend/community/trainer_views.py` -- Added `category='trainer_announcement'`
10. `backend/messaging/services/messaging_service.py` -- Added `category='new_message'`

### Mobile
11. `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
12. `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
13. `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`
14. `mobile/lib/features/settings/presentation/screens/reminders_screen.dart`
15. `mobile/lib/features/settings/presentation/screens/help_support_screen.dart`
16. `mobile/lib/core/services/reminder_service.dart`
17. Full diff of ~78 changed files scanned for secrets

---

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (grepped entire diff for api_key, secret, password, token, credential, aws_, OPENAI, STRIPE, firebase -- all matches are test fixtures with dummy values or code references)
- [x] All user input sanitized -- DRF ModelSerializer enforces BooleanField validation; rejects non-boolean values (tested)
- [x] Authentication checked on all new endpoints -- `NotificationPreferenceView` uses `IsAuthenticated` permission
- [x] Authorization -- correct role/permission guards (see detailed analysis below)
- [x] No IDOR vulnerabilities -- preferences scoped to `request.user` via `get_or_create_for_user(user)`, never accept user_id from request
- [N/A] File uploads validated -- no new file uploads in this feature
- [ ] Rate limiting on sensitive endpoints -- not present, but LOW risk (toggle preferences, not sensitive data)
- [x] Error messages don't leak internals -- error responses use generic messages
- [x] CORS policy appropriate -- no CORS changes in this feature

---

## Secrets Scan

Grepped entire `git diff HEAD~3` for: `api_key`, `secret`, `password`, `token`, `credential`, `aws_`, `OPENAI`, `STRIPE`, `firebase`.

**Result: CLEAN.** All matches are:
- Test fixture passwords (`testpass123`, `pass123`) -- dummy values, not real credentials
- Code references to DeviceToken model, firebase_messaging imports -- not leaked secrets
- `pubspec.lock` entries pointing to `https://pub.dev` -- expected package registry URLs
- No secrets in any `.dart`, `.py`, or `.md` file

---

## Detailed Analysis

### 1. Authentication & Authorization

**`NotificationPreferenceView` (GET/PATCH):**

| Endpoint | Method | Permission Classes | Data Scoping |
|----------|--------|-------------------|--------------|
| `GET /api/users/notification-preferences/` | GET | IsAuthenticated | `get_or_create_for_user(cast(User, request.user))` |
| `PATCH /api/users/notification-preferences/` | PATCH | IsAuthenticated | `get_or_create_for_user(cast(User, request.user))` |

- Requires valid JWT token -- unauthenticated requests return 401/403 (confirmed by tests)
- Both GET and PATCH scope to authenticated user only
- No user_id parameter accepted from request body or URL -- eliminates IDOR
- **Verdict: SECURE**

### 2. IDOR Analysis

**Scenario: User A tries to modify User B's notification preferences.**
- The view calls `NotificationPreference.get_or_create_for_user(cast(User, request.user))` -- always uses the authenticated user object
- No `pk`, `user_id`, or any identifier is taken from the URL or request body
- `NotificationPreference` has a `OneToOneField` to `User` -- a user can only have one record
- **Verdict: No IDOR vulnerabilities. SAFE.**

### 3. Mass Assignment Protection

**`NotificationPreferenceSerializer` fields:**
```python
fields = [
    'trainee_workout', 'trainee_weight_checkin', 'trainee_started_workout',
    'trainee_finished_workout', 'churn_alert', 'trainer_announcement',
    'achievement_earned', 'new_message', 'community_activity',
]
```

- Explicit `fields` list containing only the 9 boolean category fields
- Does NOT include `id`, `user`, `created_at`, `updated_at` -- these cannot be modified via API
- DRF `BooleanField` rejects non-boolean values (test `test_patch_rejects_non_boolean_value` confirms 400 response)
- Unknown fields in PATCH are silently ignored by DRF (test `test_patch_ignores_unknown_fields` confirms)
- Test `test_get_does_not_return_extra_fields` explicitly verifies `id`, `user`, `created_at`, `updated_at` are absent from GET response
- **Verdict: SECURE**

### 4. `getattr` Pattern Analysis

**`is_category_enabled()` method (models.py:371-381):**
```python
def is_category_enabled(self, category: str) -> bool:
    if category not in self.VALID_CATEGORIES:
        raise ValueError(...)
    return bool(getattr(self, category, True))
```

- `VALID_CATEGORIES` is a `frozenset` of 9 known field names -- immutable at class level
- Category is validated against the allowlist BEFORE `getattr` is called
- Invalid categories raise `ValueError`, which propagates (not silenced)
- Cannot be used to access `__dict__`, `user`, `pk`, `delete`, or any other attribute
- **Verdict: SECURE** -- The allowlist prevents arbitrary attribute access

### 5. Notification Service Security

**`_check_notification_preference()` (notification_service.py:59-76):**
- Catches only `(DatabaseError, ConnectionError)` -- programming errors propagate (narrowed from generic `Exception` in review round 1)
- Fails open (returns True) on DB errors -- documented design decision, acceptable for notifications
- Uses `user_id` (integer) directly in ORM filter -- no injection risk

**`send_push_to_group()` category filtering (notification_service.py:153-168):**
- Validates `category` against `VALID_CATEGORIES` before using in ORM `**{category: False}` kwargs
- Invalid categories log a warning and skip filtering (notifications still sent) -- safe behavior
- The `**{category: False}` pattern with a validated field name is safe -- Django ORM parameterizes the value, and the field name is from a known allowlist
- **Verdict: SECURE**

### 6. Injection Analysis

- **SQL Injection:** No raw SQL used. All queries go through Django ORM with parameterized values. The `**{category: False}` dynamic kwarg is safe because `category` is validated against `VALID_CATEGORIES`.
- **XSS:** Backend is API-only (DRF JSON responses). Mobile renders data through Flutter `Text()` widgets, which auto-escape.
- **Command Injection:** No shell commands or subprocess calls in changed code.
- **Path Traversal:** No file path operations.

### 7. Mobile Security

- **No hardcoded secrets:** All API calls go through `ApiClient` using centralized `ApiConstants` URLs. No API keys, tokens, or secrets in mobile code.
- **Reminders (local-only):** `ReminderService` stores data in `SharedPreferences` (on-device). No sensitive data stored -- only boolean toggles and time integers.
- **Help screen:** Support email (`support@shayestehinc.com`) is a public contact address, not a secret.
- **Error display:** Error messages shown to users are generic ("Failed to update preference. Please try again.") -- no server internals leaked.
- **No debug prints in production code:** All debug output uses `debugPrint` which is stripped in release builds.

### 8. Data Exposure

- GET `/api/users/notification-preferences/` returns only boolean category fields -- no user ID, email, or timestamps
- Test `test_get_does_not_return_extra_fields` explicitly verifies `id`, `user`, `created_at`, `updated_at` are absent
- **Verdict: SECURE**

---

## Injection Vulnerabilities
| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

## Auth & Authz Issues
| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

## Critical Issues
None found.

## High Issues
None found.

## Medium Issues
None found.

## Low Issues (Informational, not blocking)

| # | Severity | File | Issue | Recommendation |
|---|----------|------|-------|----------------|
| 1 | Low | `views.py` (NotificationPreferenceView) | No rate limiting on PATCH endpoint. A malicious authenticated user could rapidly toggle preferences. | Risk is LOW: no sensitive data exposed, no expensive operations triggered, endpoint is behind JWT auth. Add rate limiting if abuse is observed. |
| 2 | Low | `notification_service.py` (_check_notification_preference) | Fail-open behavior on database errors. | Correct design choice for notifications -- better to over-notify than silently drop messages. Already documented. |

---

## Positive Security Findings

1. **VALID_CATEGORIES frozenset:** Immutable allowlist prevents arbitrary attribute access via `getattr`. Cannot be modified at runtime.
2. **Narrow exception handling:** `_check_notification_preference` catches only `(DatabaseError, ConnectionError)` -- programming errors like `ValueError` propagate correctly.
3. **Explicit serializer fields:** No `__all__` or `exclude` pattern -- only the 9 boolean fields are exposed.
4. **No user-provided identifiers:** The view uses `request.user` exclusively -- no opportunity for IDOR.
5. **Test coverage for security properties:** Tests verify unauthenticated access denied, non-boolean input rejected, extra fields not exposed, invalid categories raise errors.
6. **OneToOne constraint:** Database enforces one preference record per user -- tested in `test_one_to_one_constraint`.

---

## Fixes Applied
No code changes required. No Critical or High security issues found.

---

## Security Score: 9/10
## Recommendation: PASS

**Rationale:** No secrets leaked. All endpoints properly authenticated. IDOR prevented by scoping to `request.user`. Mass assignment protected by explicit serializer field list. `getattr` guarded by immutable `VALID_CATEGORIES` frozenset. Django ORM prevents SQL injection. No XSS vectors. Test coverage validates security properties (auth enforcement, input validation, data exposure). The only minor gap is lack of per-endpoint rate limiting, which is informational and not blocking given the global DRF throttle and the low-risk nature of the endpoint.
