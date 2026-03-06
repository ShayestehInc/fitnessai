# Security Audit: FCM Push Notification Implementation

## Audit Date: 2026-03-05

## Files Reviewed
- `backend/users/models.py` (lines 258-397 -- DeviceToken, NotificationPreference)
- `backend/users/views.py` (lines 419-543 -- DeviceTokenView, NotificationPreferenceView)
- `backend/users/serializers.py` (NotificationPreferenceSerializer)
- `backend/users/migrations/0010_add_community_event_notification_pref.py`
- `backend/core/services/notification_service.py` (FCM service layer)
- `backend/community/services/event_service.py` (event notification methods)
- `backend/community/trainer_views.py` (event views, lines 460-628)
- `backend/community/management/commands/send_event_reminders.py`
- `backend/example.env`
- `mobile/lib/core/services/push_notification_service.dart`
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart`
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized
- [x] Authentication checked on all endpoints
- [x] Authorization -- correct role/permission guards
- [x] No IDOR vulnerabilities
- [x] File uploads validated (N/A)
- [ ] Rate limiting on sensitive endpoints (see Issue #5)
- [x] Error messages don't leak internals
- [x] CORS policy appropriate (no changes)

---

## Critical Issues (must fix before merge)

None found.

## High Issues

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 1 | **High** | `backend/users/serializers.py:138-148` | **`community_event` field missing from NotificationPreferenceSerializer.** The `community_event` BooleanField was added to the model and migration but never added to the serializer's `fields` list. Users cannot view or toggle this preference via the API -- the PATCH endpoint silently ignores it. This means all community event notification preferences are permanently locked to the default (`True`) with no user override possible, violating the user's notification opt-out right. | **FIXED.** Added `'community_event'` to the serializer `fields` list. |

## Medium Issues

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 2 | **Medium** | `backend/core/services/notification_service.py:54,76,178` | **Fail-open on preference check errors.** When `_check_notification_preference()` or the group filter hits a `DatabaseError` or `ConnectionError`, the code defaults to sending the notification anyway (`return True` / continues without filtering). While this prevents notification loss during DB outages, it means users who opted out may still receive notifications during transient DB failures. This is a deliberate design choice documented in comments but should be noted as a privacy trade-off. | No code fix -- acceptable trade-off, but should be documented in operational runbook. If compliance requirements tighten, flip to fail-closed. |
| 3 | **Medium** | `backend/community/services/event_service.py:163,197,221,282` | **Silent exception swallowing in notification methods.** All four `notify_event_*` methods catch `Exception` broadly and only log at `WARNING` level. If notifications systematically fail (e.g., Firebase credentials misconfigured), these failures will be buried in logs and never surface to the trainer or admin. | No code fix needed -- this is fire-and-forget by design. Recommend adding alerting on repeated `WARNING`-level log patterns in production monitoring. |
| 4 | **Medium** | `mobile/lib/core/services/push_notification_service.dart:44,134,152` | **`debugPrint` for error conditions.** Three places use `debugPrint()` for error logging (Firebase init failure, token registration failure, token deactivation failure). In release builds `debugPrint` is compiled out, so these errors become completely invisible. | Recommend replacing with proper logging framework or at minimum `FlutterError.reportError` for critical failures. Low security risk but high operational risk. |

## Low Issues

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 5 | **Low** | `backend/users/views.py:431` | **No rate limiting on DeviceTokenView POST.** An authenticated user could spam token registrations. The `unique_user_device_token` constraint prevents duplicate entries but `update_or_create` still hits the DB on every call. | Low risk since authentication is required. Consider adding DRF throttling (e.g., `UserRateThrottle` at 10/min). |
| 6 | **Low** | `backend/users/models.py:273` | **DeviceToken.token max_length=512.** FCM tokens are typically ~163 characters. The 512-char limit is generous but acceptable. Input is validated in the view (`len(token) > 512` check). | No fix needed. |
| 7 | **Low** | `mobile/lib/core/services/push_notification_service.dart:211` | **Deep link path injection.** The `event_id` from notification data is interpolated directly into a route path (`/community/events/$eventId`). If a malicious FCM payload contained a crafted `event_id` like `../../admin`, go_router would attempt to navigate there. However, go_router validates routes against registered paths, so invalid routes would simply fail to match. Additionally, crafting malicious FCM payloads requires access to the Firebase project's server key. | No fix needed -- risk is mitigated by go_router route validation and Firebase server key requirement. |
| 8 | **Low** | `backend/core/services/notification_service.py:17-18` | **Global mutable state for Firebase init.** `_firebase_app` and `_firebase_init_attempted` are module-level globals, which is not thread-safe in theory. However, Django typically runs in a forked process model (gunicorn workers), so each process gets its own copy. In async/threaded deployments this could cause double-init. | Low risk given standard Django deployment. |

---

## Detailed Security Analysis

### 1. Secrets Audit

| Location | Finding |
|----------|---------|
| `backend/example.env` | All values are placeholder strings (`your-*-here`). No real credentials. Firebase credentials path is commented out. **PASS** |
| `backend/core/services/notification_service.py` | Credentials loaded from `settings.FIREBASE_CREDENTIALS_PATH` env var, not hardcoded. **PASS** |
| All `.dart` files | No API keys, tokens, or secrets embedded. **PASS** |
| Notification payloads | Only contain `type` (string enum) and `event_id` (integer as string). No PII, no tokens. **PASS** |

### 2. Input Sanitization

| Endpoint | Validation | Status |
|----------|-----------|--------|
| POST /api/users/device-token/ | Token: `.strip()`, non-empty check, max 512 chars. Platform: whitelist (`ios`, `android`, `web`). | **PASS** |
| DELETE /api/users/device-token/ | Token: `.strip()`, non-empty check. Scoped to `user=user`. | **PASS** |
| PATCH /api/users/notification-preferences/ | DRF `ModelSerializer` with `BooleanField` -- only accepts boolean values. Extra fields silently ignored by DRF. | **PASS** |
| Notification category validation | `VALID_CATEGORIES` frozenset in model + service-layer validation. | **PASS** |

### 3. Auth/Authz on All Endpoints

| Endpoint | Auth | Permission | Scoping | Status |
|----------|------|------------|---------|--------|
| POST /api/users/device-token/ | IsAuthenticated | -- | `user=request.user` | **PASS** |
| DELETE /api/users/device-token/ | IsAuthenticated | -- | `user=request.user, token=token` | **PASS** |
| GET/PATCH /api/users/notification-preferences/ | IsAuthenticated | -- | `user=request.user` (via `get_or_create_for_user`) | **PASS** |
| POST /api/trainer/events/ (triggers notification) | IsAuthenticated | IsTrainer | `trainer=user` | **PASS** |
| PUT/PATCH /api/trainer/events/:id/ | IsAuthenticated | IsTrainer | `trainer=user` | **PASS** |
| DELETE /api/trainer/events/:id/ | IsAuthenticated | IsTrainer | `trainer=user` | **PASS** |
| Management command `send_event_reminders` | N/A (cron) | N/A | Fetches from DB with status/time filters | **PASS** |

### 4. No IDOR Vulnerabilities

- **DeviceTokenView:** Both POST and DELETE scope queries to `user=request.user`. A user cannot register/deactivate another user's tokens.
- **NotificationPreferenceView:** Uses `get_or_create_for_user(request.user)`. A user can only access their own preferences.
- **Event notification methods:** `notify_event_created` targets `event.trainer`'s trainees. `notify_event_updated/cancelled` targets RSVP'd users only. No user ID parameter is taken from request input.
- **send_event_reminders:** Fetches events from DB by status/time, then fetches RSVPs. No external input.

### 5. Notification Payload Data Exposure

Push notification payloads contain:
```python
{
    'type': 'community_event_created',  # string enum
    'event_id': str(event.id),          # integer as string
}
```

The notification `title` and `body` contain only the event title (user-created content from the trainer). **No PII, no tokens, no internal IDs beyond event_id are exposed.**

The `event.title` in the notification body is trainer-authored content displayed to their own trainees -- this is by design and not a data leak.

### 6. Token Management Security

| Aspect | Finding |
|--------|---------|
| Token storage | DB column, max 512 chars, unique per user+token pair. **OK** |
| Token lifecycle | Registered on login, deactivated on logout/account deletion. **OK** |
| Stale token cleanup | `_send_to_tokens_batch` auto-deactivates `UnregisteredError` and `SenderIdMismatchError` tokens. **OK** |
| Token refresh | Mobile client listens to `onTokenRefresh` and re-registers. **OK** |
| Cross-user token theft | Not possible -- `update_or_create` uses `user=request.user`. If a token is somehow shared between users, the unique constraint prevents duplicate registration for the same user, and `update_or_create` will reassign ownership to the last registrant. This is standard FCM behavior. **OK** |

### 7. Batch Processing Security

The `send_event_reminders` management command:
- Uses a 5-minute time window to prevent duplicate sends -- **OK**
- Batch-fetches RSVPs in a single query (no N+1) -- **OK**
- Catches exceptions per-event so one failure doesn't block others -- **OK**
- No external input (cron-triggered) -- **OK**

---

## Code Fix Applied

**File:** `/Users/rezashayesteh/Desktop/shayestehinc/fitnessai/backend/users/serializers.py`
**Change:** Added `'community_event'` to `NotificationPreferenceSerializer.Meta.fields`.

This was the only code fix required. Without this fix, the `community_event` preference would be permanently invisible to the API, meaning users could never opt out of community event notifications despite the model and migration supporting it.

---

## Positive Security Findings

1. **Firebase credentials loaded from file path, not env var value.** The `FIREBASE_CREDENTIALS_PATH` points to a file, not an inline JSON string, reducing risk of credential exposure in environment variable dumps.
2. **Token deactivation on logout and account deletion.** Both `logout()` and `deleteAccount()` call `deactivateToken()` before clearing auth state.
3. **Automatic stale token cleanup.** The batch send function proactively deactivates tokens that FCM reports as unregistered.
4. **Category validation with frozenset.** `VALID_CATEGORIES` is immutable and checked both in the model (`is_category_enabled`) and service layer (`send_push_to_group`).
5. **Notification preference opt-out respected at send time.** Both `send_push_notification` (single user) and `send_push_to_group` (batch) check preferences before sending.
6. **No sensitive data in push payloads.** Only type enum and event ID are included in data payload.
7. **UniqueConstraint on user+token prevents token flooding.** The DB constraint limits one entry per user+token combination.

## Security Score: 8/10

Deductions: -1 for the missing serializer field (High, now fixed), -1 for fail-open preference checks and lack of rate limiting (Medium/Low, acceptable trade-offs).

## Recommendation: PASS

All Critical and High issues have been resolved. The FCM push notification implementation follows security best practices for token management, input validation, auth/authz, data exposure, and payload safety. Remaining Medium/Low items are documented trade-offs appropriate for the current threat model.
