# Architecture Review: FCM Push Notification Implementation

## Review Date
2026-03-05

## Files Reviewed
- `backend/users/models.py` (lines 258-397) -- DeviceToken, NotificationPreference models
- `backend/community/services/event_service.py` -- notification dispatch methods
- `backend/community/trainer_views.py` (lines 460-632) -- event CRUD views
- `backend/community/management/commands/send_event_reminders.py` -- cron command
- `backend/core/services/notification_service.py` -- FCM service layer
- `mobile/lib/core/services/push_notification_service.dart` -- Flutter FCM client
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` -- auth + push init

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in views (notification dispatch delegated to EventService)
- [x] Consistent with existing patterns (service layer, management commands)

**Positive observations:**
1. Clean separation: `notification_service.py` in `core/services/` is a shared utility; `event_service.py` in `community/services/` handles domain-specific notification logic. Correct layering.
2. `NotificationPreference` model uses a clean `get_or_create_for_user` pattern with `VALID_CATEGORIES` frozenset for compile-time category validation.
3. `send_push_to_group` efficiently batches FCM calls (500-message batches) and bulk-deactivates stale tokens.
4. The reminder cron command batches RSVP queries across events in a single DB query -- avoids N+1.
5. Mobile side correctly uses `unawaited()` for push init (non-blocking) and deactivates tokens on logout/delete.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | `DeviceToken` and `NotificationPreference` are additive tables, no existing columns altered |
| Migrations reversible | PASS | New tables can be dropped without data loss to existing tables |
| Indexes added for new queries | PASS | `DeviceToken` has index on `(user, is_active)` and unique constraint on `(user, token)` |
| No N+1 query patterns | PASS | `send_push_to_group` fetches all tokens for all users in one query; reminder command batches RSVP lookups |

**Note:** `NotificationPreference` is queried via `filter(user_id__in=..., **{category: False})` in `send_push_to_group`. This dynamic field lookup is efficient because it translates to a single SQL query with a WHERE clause on the boolean column. No index needed on individual boolean columns given the expected table size (one row per user).

---

## Issues Found and Fixed

### 1. FIXED -- Missing state machine validation on `transition_status` (Major)

**Before:** `EventService.transition_status()` accepted any status string and blindly saved it. A cancelled or completed event could be transitioned back to "scheduled" or "live" -- data integrity violation.

**Fix:** Added `_VALID_TRANSITIONS` dict defining the state machine:
- `scheduled` -> `{live, cancelled}`
- `live` -> `{completed, cancelled}`
- `completed` -> terminal (no transitions)
- `cancelled` -> terminal (no transitions)

`transition_status()` now raises `ValueError` for invalid transitions. Both calling views (`TrainerEventDetailView.delete` and `TrainerEventStatusView.patch`) now catch `ValueError` and return `409 Conflict`.

### 2. FIXED -- Bare `except Exception` with warning-level logging (Minor)

**Before:** Three notification methods in `event_service.py` caught `Exception` and logged at `warning` level. This made FCM failures hard to detect in monitoring.

**Fix:** Upgraded all three to `logger.error()` with the event ID in the message for traceability.

---

## Issues Noted (Not Fixed -- Require Discussion)

### 3. Synchronous notification dispatch in request cycle (Medium)

`notify_event_created`, `notify_event_updated`, and `notify_event_cancelled` are called synchronously within the HTTP request/response cycle in `trainer_views.py`. Each call:
1. Queries `NotificationPreference` to filter opted-out users
2. Queries `DeviceToken` for all matching tokens
3. Makes FCM API calls in batches of 500

For a trainer with hundreds of trainees, this could add 1-3 seconds to the response time. The `try/except` prevents it from breaking the response, but the trainer waits for it.

**Recommendation:** When the project adds Celery or Django-Q (or any task queue), move these calls to async tasks. For now, the current approach is acceptable for the user base size, but this should be tracked as tech debt. The architecture is already well-positioned for this -- the service methods are stateless and take simple arguments, making them trivially wrappable as Celery tasks.

### 4. Mobile `_navigateFromNotification` silently catches all exceptions (Low)

```dart
} catch (_) {
  // Navigation may fail if router not ready; ignore
}
```

This is defensible because notification tap handling is best-effort -- crashing the app because the router isn't ready would be worse. However, it would benefit from a `debugPrint` so developers can see navigation failures during development.

### 5. `notification_service.py` "never raises" contract vs. project rules (Informational)

The module docstring says "All errors are handled gracefully -- this service never raises." This conflicts with the project rule of no exception silencing. However, for a fire-and-forget notification service, this is the correct architectural decision. A failed push notification should never break the primary operation (event creation, status update, etc.). The service logs errors internally, which is sufficient observability.

**Verdict:** The "never raises" contract is architecturally correct for this service. No change needed.

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Synchronous FCM dispatch | Blocks HTTP response for duration of FCM API calls | Move to task queue when available (see issue #3 above) |
| 2 | Reminder window precision | 5-minute cron with 5-minute window works well; no overlap risk | No action needed |
| 3 | Token cleanup | Stale tokens auto-deactivated on FCM error response | Good -- no unbounded growth concern |

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Synchronous notification dispatch should eventually be async | Low | Wrap in Celery task when task queue is added |
| 2 | No retry logic for transient FCM failures | Low | Add exponential backoff when task queue is available |

---

## Technical Debt Reduced

1. **State machine enforcement** -- `transition_status` now prevents invalid state transitions, closing a data integrity gap.
2. **Notification preference filtering** -- Users can opt out of categories, reducing unwanted notifications without backend changes per category.

---

## Architecture Score: 8/10

The implementation follows clean layered architecture. Business logic is in services. Data model is additive and backward-compatible. Indexes are in place. The main deduction is for synchronous notification dispatch in the request cycle, which is acceptable at current scale but should be tracked.

## Recommendation: APPROVE

The architecture is sound. The synchronous dispatch is a known tradeoff that's acceptable for the current user base and can be migrated to async when a task queue is introduced. The state machine fix and error logging improvements have been applied.
