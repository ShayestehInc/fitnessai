# Hacker Report: FCM Push Notification Implementation

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | push_notification_service.dart | Announcement deep-link | Tapping an announcement notification should open the announcements screen | Pushed `/announcements` which does not exist -- the actual route is `/community/announcements`. Navigation silently failed. **FIXED.** |
| 2 | Low | notification_preferences_screen.dart | Toggle tiles when OS notifications are off | Toggles should be visually dimmed/disabled to indicate they have no effect until OS permissions are granted | Toggles are fully interactive even when the OS-level banner says notifications are disabled, giving a false sense of control |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| - | - | - | No visual bugs found in these files | - |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Login -> Logout -> Login (rapid cycle) | Log in, log out, log in again. Repeat several times. | Each login should have exactly one set of FCM stream listeners | `deactivateToken()` reset `_initialized` to false but never cancelled the `onTokenRefresh`, `onMessage`, or `onMessageOpenedApp` stream subscriptions. Each login cycle created additional duplicate listeners. After 5 login/logout cycles, 5 copies of every foreground notification would be shown, and `_registerToken` would fire 5 times on each token refresh. **FIXED** -- added `StreamSubscription` fields, cancel them in `deactivateToken()`, and cancel-before-listen in `initialize()`. |
| 2 | Critical | Impersonation push token leak | Trainer impersonates trainee via `setTokensAndLoadUser`. Ends impersonation later. | Device token should only be registered for the current authenticated user | `setTokensAndLoadUser` called `_pushService.initialize()` without first deactivating the previous user's token. The device FCM token was now registered for BOTH the trainer AND the impersonated trainee. After ending impersonation, the trainer's device would continue receiving the trainee's push notifications indefinitely (until the token expires or is manually deactivated). **FIXED** -- added `await _pushService.deactivateToken()` before switching identity in `setTokensAndLoadUser`. |
| 3 | Major | Event update while cancelled/completed | Trainer creates event, cancels it, then sends PUT/PATCH to update the cancelled event | Should return an error -- cancelled events should not be editable | The `_update` method had no guard against editing terminal-state events. A trainer could change the time of a cancelled event, and update notifications would be silently suppressed (because the notification check requires `status == SCHEDULED`) but the data would be corrupted. **FIXED** -- added a 409 Conflict guard in `_update` for cancelled/completed events. |
| 4 | Medium | Rapid event updates (10 times in 1 minute) | Trainer rapidly updates an event's start time 10 times | Users should receive a reasonable number of notifications, not 10 | Each update that changes `starts_at`, `ends_at`, or `meeting_url` fires `notify_event_updated` synchronously. 10 rapid updates = 10 separate push notifications to every RSVP'd user. No debouncing or coalescing. **NOT FIXED** -- requires backend-side debounce mechanism (e.g., Celery delay/dedup or a `last_notified_at` timestamp). Noted for future work. |
| 5 | Medium | 100 events created in rapid succession | Trainer creates 100 events via the API in quick succession | System should handle gracefully with reasonable notification delivery | Each event creation calls `notify_event_created` which calls `send_push_to_group` synchronously in the request/response cycle. 100 rapid creations = 100 synchronous Firebase calls, each of which could take 100-500ms. The HTTP responses would be extremely slow (10-50 seconds each). **NOT FIXED** -- requires moving notification sends to a background task queue (Celery). Currently fire-and-forget but still synchronous within the request. |
| 6 | Low | FCM token refresh during deactivation | Token refreshes via `onTokenRefresh` while `deactivateToken()` is in-flight | Should not register the new token after deactivation | After the stream subscription fix, this is mitigated because `deactivateToken()` now cancels `_tokenRefreshSub` before proceeding with the API call. Race condition is resolved. **FIXED** (as part of fix #1). |
| 7 | Low | Phone offline when notification sent | User's phone is offline during push send | Notification should be delivered when phone comes back online | FCM handles this natively -- messages are queued for up to 28 days by default. No bug here, but worth noting that no custom TTL is set. Very old notifications (e.g., "event starts soon" from 2 weeks ago) could still be delivered. Consider setting `android.ttl` and `apns.expiration` for time-sensitive notifications like reminders. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Event notifications | Add notification debouncing for event updates | Trainers editing an event multiple times in quick succession (fixing typos, adjusting time) spam users with redundant notifications. A 60-second debounce window using Celery countdown would coalesce rapid updates into a single notification. |
| 2 | High | Event notifications | Move notification sends to background task queue | All `notify_event_*` and `_notify_trainees_announcement` calls are synchronous in the request cycle. For trainers with 500+ trainees, this adds significant latency to every create/update/cancel API call. Move to Celery tasks. |
| 3 | Medium | Notification preferences screen | Disable toggle tiles when OS notifications are off | When the OS permission banner is showing, the category toggles below should use `onChanged: null` (which renders them as disabled/grayed out). This makes it visually clear that changing preferences is pointless until OS permissions are enabled. |
| 4 | Medium | Event reminders | Add TTL to time-sensitive notifications | Event reminders ("starts soon") should have a 15-minute TTL so they are not delivered hours/days later if the user's device was offline. Set `messaging.AndroidConfig(ttl=timedelta(minutes=15))` and equivalent APNS config. |
| 5 | Low | Deep linking | Add deep link for `community_event_cancelled` type | Currently, tapping a "cancelled event" notification navigates to the event detail screen, which is correct. But the user might see stale data if the screen does not refresh. Consider adding a `?refresh=true` query param or using `pushReplacement`. |
| 6 | Low | Push notification service | Use deterministic notification IDs | `message.hashCode` for local notification IDs could collide between different messages, causing one notification to silently replace another. Consider using a hash of `message.messageId` or a monotonically increasing counter. |

## Summary
- Dead UI elements found: 1 (broken announcement deep-link route)
- Visual bugs found: 0
- Logic bugs found: 7 (3 fixed, 4 noted)
- Improvements suggested: 6
- Items fixed by hacker: 4

## Files Changed
- `mobile/lib/core/services/push_notification_service.dart` -- Fixed stream subscription leak (login/logout cycles creating duplicate listeners), fixed broken `/announcements` deep-link route to `/community/announcements`.
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart` -- Fixed impersonation push token leak by deactivating the current token before switching identity in `setTokensAndLoadUser`.
- `backend/community/trainer_views.py` -- Added 409 Conflict guard in `_update` to prevent editing cancelled/completed events.

## Chaos Score: 7/10
The core push notification flow works, but the stream subscription leak would cause escalating duplicate notifications on every login/logout cycle -- a progressively worsening UX bug. The impersonation token leak is a privacy/security concern (trainer receiving trainee's notifications). The broken deep-link is embarrassing but low-severity. The lack of notification debouncing and background task processing are architectural gaps that will become painful at scale.
