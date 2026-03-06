# Feature: Wire FCM Push Notifications End-to-End for Community Events

## Priority
High

## User Story
As a **trainee**, I want to receive push notifications when my trainer creates events, when events I RSVP'd to are updated or cancelled, and a reminder before events start, so that I never miss a community event.

As a **trainer**, I want my trainees to be automatically notified when I create or update events, so I don't have to manually remind them.

## Context: What Already Exists
- **Backend**: Full `notification_service.py` with `send_push_notification()` and `send_push_to_group()`, DeviceToken model, NotificationPreference model with category-based opt-out, device token registration endpoint (`POST/DELETE /api/users/device-token/`), notification preferences endpoint (`GET/PATCH /api/users/notification-preferences/`)
- **Mobile**: `PushNotificationService` with Firebase init, token registration, token refresh, foreground handler (stub), background handler (stub), `deactivateToken()` on logout. Notification preferences screen with toggle UI. Dependencies installed (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`).
- **Pattern**: `_notify_trainees_announcement()` in `trainer_views.py` already sends push notifications on announcement creation — follow this exact pattern for events.

## What's Missing (Gaps to Fill)

### Backend
1. No `community_event` notification category on NotificationPreference model
2. No notification triggers when events are created, updated, cancelled, or go live
3. No scheduled reminder notification (15 min before event starts)

### Mobile
1. `PushNotificationService.initialize()` is never called — not in `main.dart`, not after login
2. Foreground message handler (`_handleForegroundMessage`) is a no-op stub
3. Message opened handler (`_handleMessageOpenedApp`) is a no-op stub — no deep linking
4. `deactivateToken()` is never called on logout
5. No `community_event` category in notification preferences UI

## Acceptance Criteria
- [ ] AC1: Backend adds `community_event` boolean field to NotificationPreference model with migration
- [ ] AC2: Backend sends push notification to all trainer's trainees when a new event is created
- [ ] AC3: Backend sends push notification to RSVP'd users (going/maybe) when an event is cancelled
- [ ] AC4: Backend sends push notification to RSVP'd users (going/maybe) when event time/location changes
- [ ] AC5: Backend sends push notification to RSVP'd users (going) 15 minutes before event starts via management command
- [ ] AC6: Mobile calls `PushNotificationService.initialize()` after successful login
- [ ] AC7: Mobile calls `PushNotificationService.deactivateToken()` on logout
- [ ] AC8: Mobile foreground handler displays a local notification (flutter_local_notifications) for incoming push messages
- [ ] AC9: Mobile notification tap navigates to the relevant screen (event detail for community_event notifications)
- [ ] AC10: Mobile notification preferences screen includes "Community Events" toggle for trainees
- [ ] AC11: All push notification data payloads include `type` key for routing and relevant entity ID
- [ ] AC12: Push notifications respect user's category opt-out preferences

## Edge Cases
1. **No device tokens registered**: User hasn't opened the app or denied permissions — notification service handles this gracefully (returns 0/False), no error raised.
2. **Firebase not configured**: `FIREBASE_CREDENTIALS_PATH` not set — service logs warning and silently skips. App still works.
3. **Token expired/invalid**: FCM returns `UnregisteredError` — existing service deactivates the token automatically.
4. **User opts out of community_event**: The preference check in `send_push_to_group` filters them out before sending.
5. **Event reminder for cancelled event**: Management command must skip cancelled/completed events.
6. **Event created then immediately cancelled**: Cancel notification should still fire for anyone who RSVP'd between creation and cancellation.
7. **Multiple rapid updates to same event**: Each update triggers a notification — this is acceptable; not deduped.
8. **User logs out then back in**: Old token deactivated on logout, new token registered on login.
9. **Foreground notification when user is on the event detail screen**: Should still show local notification banner (they may be on a different event).
10. **Deep link to event that was deleted**: Event detail screen already handles "not found" with error state.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| FCM send fails (network) | Nothing — push is best-effort | Logs warning, returns False |
| Device token invalid | Nothing | Marks token `is_active=False` |
| User denied OS notification permission | Banner on notification preferences screen | Doesn't call FCM at all |
| Firebase not initialized (missing credentials) | Nothing | Logs once, disables push |
| Deep link target not found | "Event not found" error state | 404 from API handled in existing screen |

## UX Requirements
- **Foreground notification**: Show a local notification with event title as body. Tapping it navigates to event detail.
- **Background/terminated notification**: FCM handles display automatically. Tapping navigates to event detail.
- **Notification content**: Title = "New Event" / "Event Updated" / "Event Cancelled" / "Event Reminder". Body = event title. Data payload has `type` and `event_id`.
- **Preferences UI**: Add "Community Events" toggle under the trainee "Updates" section, between "Achievements" and the Communication section.

## Technical Approach

### Backend Changes

**Files to modify:**
- `backend/users/models.py` — Add `community_event` field to NotificationPreference, add to VALID_CATEGORIES
- `backend/community/services/event_service.py` — Add notification dispatch methods for event lifecycle
- `backend/community/trainer_views.py` — Call notification dispatch after event create/update/cancel
- `backend/example.env` — Add FIREBASE_CREDENTIALS_PATH entry

**Files to create:**
- `backend/users/migrations/NNNN_add_community_event_notification_pref.py` — Migration for new field
- `backend/community/management/commands/send_event_reminders.py` — Management command for 15-min reminders (designed for cron: `*/5 * * * *`)

**Pattern to follow:** `_notify_trainees_announcement()` in trainer_views.py — try/except with logging, never raises, calls `send_push_to_group()`.

### Mobile Changes

**Files to modify:**
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` — Call PushNotificationService.initialize() after successful login/register
- `mobile/lib/core/services/push_notification_service.dart` — Wire foreground handler (local notification), wire message opened handler (deep link via go_router), add notification channel setup
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart` — Add community_event toggle to trainee sections

**Files to create:**
- None — all integration points exist, just need wiring.

### Data Payload Contract
```json
{
  "type": "community_event_created",
  "event_id": "123"
}
```
Types: `community_event_created`, `community_event_updated`, `community_event_cancelled`, `community_event_reminder`

## Out of Scope
- Web push notifications
- Celery/task queue for async notification dispatch (use synchronous calls like existing announcement pattern)
- Notification grouping/collapsing
- Badge count management (iOS badge number)
- Rich notification images
- Apple Watch notifications
