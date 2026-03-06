# Ship Decision: Wire FCM Push Notifications End-to-End for Community Events

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 9/10

## Summary
All 12 acceptance criteria are met. The implementation wires FCM push notifications end-to-end: backend sends notifications on event create/update/cancel with a cron-based reminder system, mobile initializes Firebase on login, displays foreground notifications via flutter_local_notifications, and deep links to event detail on tap. Notification preferences are fully integrated with a new "Community Events" toggle.

## Acceptance Criteria Verification
- AC1: community_event field + migration + VALID_CATEGORIES + serializer -- PASS
- AC2: notify_event_created() called after event creation, excludes banned users -- PASS
- AC3: notify_event_cancelled() called on DELETE and status PATCH to cancelled -- PASS
- AC4: notify_event_updated() called only when time/location actually changes, with descriptive body -- PASS
- AC5: send_event_reminders() with 10-15 min window, batched RSVP queries, management command -- PASS
- AC6: initialize() called after login/register/social/impersonation with unawaited() -- PASS
- AC7: deactivateToken() called on logout (with stream cleanup and _initialized reset) -- PASS
- AC8: Foreground handler shows local notification with title/body, iOS presentAlert -- PASS
- AC9: Deep links to /community/events/$eventId (verified route exists at app_router.dart:846) -- PASS
- AC10: "Community Events" toggle in trainee Updates section -- PASS
- AC11: All payloads include type + event_id as strings -- PASS
- AC12: category='community_event' passed to send_push_to_group, preferences respected -- PASS

## Issues Fixed During Pipeline
- Duplicate reminders (narrowed window to 10-15 min matching cron interval)
- Fragile payload encoding (switched to JSON)
- Firebase init error handling (graceful degradation)
- Logout/re-login token re-registration (reset _initialized + cancel stream subscriptions)
- Deep link path (corrected from route name to actual path)
- Banned users receiving notifications (excluded via UserBan query)
- N+1 queries in reminders (batched RSVP fetch)
- False-positive update notifications (compare old vs new values)
- Impersonation token leak (deactivate before switching identity)
- Event status state machine (valid transitions enforced, ValueError on invalid)
- Serializer missing community_event field (security audit fix)
- iOS foreground notification display flags
- Stream subscription leak on login/logout cycles
- Announcement deep link path (/community/announcements)

## Remaining Concerns
- Synchronous notification dispatch in request cycle (acceptable at current scale, documented for future async migration)
- No notification debouncing for rapid event updates (documented, acceptable)
- No TTL on reminder notifications (FCM handles expiry, acceptable default)

## What Was Built
FCM push notifications wired end-to-end for community events:
- Backend: 4 notification dispatch methods in EventService, management command for scheduled reminders, community_event preference category, state machine for event status transitions
- Mobile: Full PushNotificationService with Firebase init, local notification display, deep link navigation, stream subscription lifecycle management
- Auth integration: Token registration on all login paths, token deactivation on logout/delete/impersonation
- Preferences: Community Events toggle in notification preferences screen
