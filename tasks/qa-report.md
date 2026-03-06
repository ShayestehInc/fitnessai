# QA Report: Wire FCM Push Notifications End-to-End for Community Events

## Date: 2026-03-05

## Test Method
Code-review-style QA. All 12 acceptance criteria verified by reading actual implementation code paths across backend and mobile. No runtime tests executed.

## Test Results
- Total acceptance criteria: 12
- Passed: 10
- Failed: 2

## Acceptance Criteria Verification

- [x] **AC1**: Backend adds `community_event` boolean field to NotificationPreference model with migration -- **PASS**
  - Field added at `backend/users/models.py:343-346` with `default=True` and descriptive `help_text`.
  - Added to `VALID_CATEGORIES` frozenset at line 369.
  - Migration at `backend/users/migrations/0010_add_community_event_notification_pref.py` is correct: `AddField` with `BooleanField(default=True)`, depends on `0009_add_body_fat_percentage`.

- [x] **AC2**: Backend sends push notification to all trainer's trainees when a new event is created -- **PASS**
  - `TrainerEventListCreateView.create()` (trainer_views.py:510-511) calls `EventService.notify_event_created(event)` after event creation.
  - `notify_event_created()` (event_service.py:144-164) fetches non-banned trainee IDs via `_get_non_banned_trainee_ids()`, sends via `send_push_to_group()` with title="New Event", body=event.title, correct data payload.
  - Fire-and-forget pattern with try/except + logging matches existing announcement pattern.

- [x] **AC3**: Backend sends push notification to RSVP'd users (going/maybe) when an event is cancelled -- **PASS**
  - `TrainerEventDetailView.delete()` (trainer_views.py:588-589) calls `notify_event_cancelled()` after status transition to CANCELLED.
  - `TrainerEventStatusView.patch()` (trainer_views.py:621-622) also calls `notify_event_cancelled()` when new_status is CANCELLED.
  - `notify_event_cancelled()` (event_service.py:201-221) queries going/maybe RSVPs via `_get_rsvpd_user_ids()`, sends with title="Event Cancelled".
  - Both cancellation paths covered.

- [x] **AC4**: Backend sends push notification to RSVP'd users (going/maybe) when event time/location changes -- **PASS**
  - `TrainerEventDetailView._update()` (trainer_views.py:556-572) tracks `notify_fields = {'starts_at', 'ends_at', 'meeting_url'}`, checks intersection with validated data keys.
  - Only notifies when `should_notify and event.status == SCHEDULED`. Correct: no notification for description-only changes or non-scheduled events.
  - `notify_event_updated()` (event_service.py:166-198) builds a descriptive body ("time changed", "meeting link updated") and sends to RSVP'd users.

- [ ] **AC5**: Backend sends push notification to RSVP'd users (going) 15 minutes before event starts via management command -- **FAIL**
  - **BUG**: The reminder window in `send_event_reminders()` (event_service.py:238) uses `now + timedelta(minutes=5)`, NOT 15 minutes. Events starting in 0-5 minutes from the cron run get reminders. Users receive notifications at most ~5 minutes before, not 15 minutes before as the ticket specifies.
  - The docstring (line 227) says "5 minutes" which contradicts the management command's help text saying "15 minutes".
  - Correct implementation should query events starting between `now + 10min` and `now + 15min` so that with a `*/5 * * * *` cron, reminders arrive ~10-15 minutes before.
  - Everything else in the method is correct: filters by SCHEDULED status only (skips cancelled/completed), queries only GOING RSVPs, batches RSVP queries efficiently, fire-and-forget per event with try/except.

- [x] **AC6**: Mobile calls `PushNotificationService.initialize()` after successful login -- **PASS**
  - Called in `login()` (auth_provider.dart:62), `register()` (auth_provider.dart:91), `loginWithGoogle()` (auth_provider.dart:190), `loginWithApple()` (auth_provider.dart:210), and `setTokensAndLoadUser()` (auth_provider.dart:159).
  - All calls use `unawaited()` to avoid blocking the UI. Correct.
  - `initialize()` is guarded by `_initialized` flag so repeated calls are safe.

- [x] **AC7**: Mobile calls `PushNotificationService.deactivateToken()` on logout -- **PASS**
  - Called in `logout()` (auth_provider.dart:101) with `await`, before clearing auth state. Correct sequencing.

- [x] **AC8**: Mobile foreground handler displays a local notification for incoming push messages -- **PASS**
  - `_handleForegroundMessage()` (push_notification_service.dart:154-175) creates a local notification with title/body from the FCM `RemoteMessage.notification`, high importance, and passes the data map as a JSON-encoded payload.
  - Android notification channel created in `_initLocalNotifications()` with `Importance.high`.
  - Guards against null notification payload (line 156).

- [ ] **AC9**: Mobile notification tap navigates to the relevant screen (event detail for community_event notifications) -- **FAIL**
  - **BUG**: `_navigateFromNotification()` (push_notification_service.dart:206) calls `router.push('/community-event-detail/$eventId')`, but the actual GoRouter path is `/community/events/:id` (app_router.dart:846). The string `community-event-detail` is the route NAME, not the path. `router.push()` expects a path. This will result in a route-not-found error on every notification tap for community events.
  - The fix is either `router.push('/community/events/$eventId')` (path-based) or `router.pushNamed('community-event-detail', pathParameters: {'id': eventId})` (name-based).
  - Local notification taps (`_onLocalNotificationTap`) also flow through the same `_navigateFromNotification`, so both foreground and background taps are broken.
  - `getInitialMessage()` taps (terminated state) are also broken for the same reason.

- [x] **AC10**: Mobile notification preferences screen includes "Community Events" toggle for trainees -- **PASS**
  - Added in `_traineeSections` (notification_preferences_screen.dart:111-116) with key `community_event`, label "Community Events", subtitle "New events, updates, cancellations, and reminders", icon `Icons.event_outlined`.
  - Positioned between "Achievements" and "Communication" section as specified in ticket UX requirements.

- [x] **AC11**: All push notification data payloads include `type` key for routing and relevant entity ID -- **PASS**
  - All four notification methods include `'type': 'community_event_*'` and `'event_id': str(event.id)` in the data dict.
  - Types: `community_event_created`, `community_event_updated`, `community_event_cancelled`, `community_event_reminder`. Matches the contract in the ticket.

- [x] **AC12**: Push notifications respect user's category opt-out preferences -- **PASS**
  - All four notification methods pass `category='community_event'` to `send_push_to_group()`.
  - `send_push_to_group()` (notification_service.py:153-181) validates `community_event` is in `VALID_CATEGORIES`, queries users who opted out (`community_event=False`), and filters them from the recipient list before sending.
  - Fail-open behavior: if preference check fails (DB error), notifications are still sent. This matches the existing pattern.

## Bugs Found Outside Acceptance Criteria

| # | Severity | Description | Details |
|---|----------|-------------|---------|
| 1 | **Critical** | Deep link navigation uses wrong path | `push_notification_service.dart:206` uses `router.push('/community-event-detail/$eventId')` but the GoRouter path is `/community/events/:id`. Every community event notification tap silently fails to navigate. Affects foreground taps, background taps, and terminated-state taps. |
| 2 | **Major** | Reminder window is 5 minutes instead of 15 | `event_service.py:238` uses `timedelta(minutes=5)`. Reminders arrive 0-5 min before events, not ~15 min. Fix: query `starts_at__gt=now + 10min, starts_at__lte=now + 15min`. |
| 3 | **Major** | Push notifications break after logout/re-login cycle | `deactivateToken()` clears `_currentToken` but does not reset `_initialized`. On re-login, `initialize()` returns immediately (line 37), so the FCM token is never re-registered on the backend. The backend has the token marked inactive, but the mobile never re-registers it. Push notifications stop working until a full app restart. |
| 4 | **Minor** | `deleteAccount()` does not deactivate push token | `auth_provider.dart:125-140` calls `_repository.deleteAccount()` without first calling `_pushService.deactivateToken()`. Inconsistent with the `logout()` pattern. Not a security issue if backend cascade-deletes user data, but leaves orphan tokens if cascade is missing. |
| 5 | **Minor** | PUT updates trigger false-positive notifications | `trainer_views.py:557` computes `changed_fields` from `serializer.validated_data.keys()`, which for a full PUT includes ALL fields even if values are unchanged. A PUT that keeps the same time will still trigger an "Event Updated -- time changed" notification. Fix: compare old values with new before deciding to notify. |
| 6 | **Minor** | `send_event_reminders()` lacks top-level error handling | `event_service.py:224` -- the `CommunityEvent.objects.filter()` query is not wrapped in try/except. If the DB query itself fails, the management command crashes with an unhandled exception. Per-event sends have try/except, but the outer query does not. |

## Recommended Fixes

**Bug #1 (Critical)** -- In `push_notification_service.dart:206`, change:
```dart
router.push('/community-event-detail/$eventId');
```
to:
```dart
router.push('/community/events/$eventId');
```

**Bug #2 (Major)** -- In `event_service.py:237-238`, change the window to target 15 minutes before:
```python
reminder_window_start = now + timezone.timedelta(minutes=10)
reminder_window_end = now + timezone.timedelta(minutes=15)
```
Update filter to: `starts_at__gt=reminder_window_start, starts_at__lte=reminder_window_end`. Update docstring.

**Bug #3 (Major)** -- In `push_notification_service.dart`, add `_initialized = false;` at the end of `deactivateToken()`:
```dart
Future<void> deactivateToken() async {
    // ... existing code ...
    _currentToken = null;
    _initialized = false;  // Allow re-initialization on next login
}
```

**Bug #4 (Minor)** -- Add `await _pushService.deactivateToken();` at the top of `deleteAccount()`.

**Bug #5 (Minor)** -- Compare old and new field values in `_update()` before setting `should_notify`.

**Bug #6 (Minor)** -- Wrap the outer query in `send_event_reminders()` in try/except with logging.

## Confidence Level: LOW

Two acceptance criteria fail (AC5: wrong reminder window, AC9: broken deep linking). Three additional bugs found: the logout/re-login token re-registration bug (#3) is particularly impactful as it silently breaks push notifications for any user who logs out and back in. Bug #1 (wrong deep link path) is critical -- it means notification taps never navigate to the event detail screen.
