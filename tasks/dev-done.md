# Dev Done: Wire FCM Push Notifications End-to-End for Community Events

## Date: 2026-03-05

## Files Created
- `backend/users/migrations/0010_add_community_event_notification_pref.py` — Migration adding `community_event` boolean field to NotificationPreference model
- `backend/community/management/commands/send_event_reminders.py` — Management command for sending 15-min reminders to RSVP'd users. Run via cron: `*/5 * * * *`

## Files Modified

### Backend
- `backend/users/models.py` — Added `community_event` field to NotificationPreference model and added it to VALID_CATEGORIES frozenset
- `backend/community/services/event_service.py` — Added 4 notification methods to EventService:
  - `notify_event_created()` — Pushes to all trainer's trainees
  - `notify_event_updated()` — Pushes to RSVP'd users (going/maybe)
  - `notify_event_cancelled()` — Pushes to RSVP'd users (going/maybe)
  - `send_event_reminders()` — Class method for cron, finds events starting within 15 min, pushes to going users
- `backend/community/trainer_views.py` — Wired notification triggers:
  - `TrainerEventListCreateView.create()` — Calls `notify_event_created()` after event creation
  - `TrainerEventDetailView._update()` — Calls `notify_event_updated()` when time/location changes on scheduled events
  - `TrainerEventDetailView.delete()` — Calls `notify_event_cancelled()` after status transition
  - `TrainerEventStatusView.patch()` — Calls `notify_event_cancelled()` when status set to CANCELLED
- `backend/example.env` — Added `FIREBASE_CREDENTIALS_PATH` entry

### Mobile
- `mobile/lib/core/services/push_notification_service.dart` — Full rewrite:
  - Added `flutter_local_notifications` integration for foreground message display
  - Android notification channel creation on init
  - Foreground handler shows local notification with title/body
  - Notification tap handler (both local and FCM) navigates via go_router
  - Deep link routing: community_event_* → event detail, announcement → announcements, community_* → community feed
  - `getInitialMessage()` check for terminated-state notification taps
  - Payload encoding/decoding for local notification payloads
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` — Wired push notifications into auth lifecycle:
  - `login()`, `register()`, `loginWithGoogle()`, `loginWithApple()`, `setTokensAndLoadUser()` — All call `_pushService.initialize()` after success
  - `logout()` — Calls `_pushService.deactivateToken()` before clearing auth state
  - AuthNotifier now takes PushNotificationService as a dependency
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart` — Added "Community Events" toggle in trainee Updates section

## Key Decisions
1. **Fire-and-forget notifications** — All notification dispatch follows the existing `_notify_trainees_announcement()` pattern: try/except with logging, never raises, never blocks the response
2. **Update notifications only for time/location changes** — Description-only edits don't trigger push notifications to avoid spam. Checks intersection of changed fields with `{starts_at, ends_at, meeting_url}`
3. **Reminder window is 15 minutes** — Management command queries events with `starts_at > now AND starts_at <= now + 15min`, only for `going` RSVP status
4. **Local notifications for foreground** — Used `flutter_local_notifications` to show a banner when FCM message arrives while app is open. Tapping navigates to event detail.
5. **Deep linking via go_router** — PushNotificationService reads the `routerProvider` to navigate. Routes to `/community-event-detail/{id}` for event notifications.
6. **Push init on every auth success** — `PushNotificationService.initialize()` is idempotent (guarded by `_initialized` flag), so calling it on login/register/social/impersonation is safe.

## How to Manually Test
1. Set `FIREBASE_CREDENTIALS_PATH` in `.env` to a valid Firebase service account JSON
2. Login on mobile → should request notification permission and register device token
3. As trainer, create an event → trainee should receive "New Event" push notification
4. Tap the notification → should navigate to event detail screen
5. As trainee, RSVP "Going" to an event
6. As trainer, update the event time → trainee should receive "Event Updated" notification
7. As trainer, cancel the event → trainee should receive "Event Cancelled" notification
8. Run `python manage.py send_event_reminders` with an event starting within 15 min → going users get "Event Reminder"
9. Open notification preferences → "Community Events" toggle should appear for trainees
10. Toggle it off → no more event push notifications for that user
11. Logout → device token should be deactivated
