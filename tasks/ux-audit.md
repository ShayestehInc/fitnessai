# UX Audit: FCM Push Notifications (Mobile)

## Audit Date: 2026-03-05

## Files Reviewed
- `mobile/lib/core/services/push_notification_service.dart`
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`
- `mobile/lib/features/auth/presentation/providers/auth_provider.dart`
- `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
- `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
- `mobile/lib/core/router/app_router.dart` (deep link routes)

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Major | `_OsPermissionBanner` | Button said "Enable" and called `requestPermission()`, but on iOS once a user denies, the system dialog never re-appears. The button silently did nothing. | Changed to "Open Settings" with `url_launcher` to open device settings. Added `WidgetsBindingObserver` lifecycle observer to re-check permission when user returns from settings. | FIXED |
| 2 | Medium | `PushNotificationService.initialize()` | Permission prompt fires immediately after login with zero context. iOS shows a cold system dialog with no pre-permission explanation. Industry best practice is a "warm ask" with rationale first. | Requires a new pre-permission screen design. Documented for future work. | DOCUMENTED |
| 3 | Medium | `_handleForegroundMessage` | Blank notifications shown to the user when both title and body are empty/null. | Added guard: skip display when both are empty. | FIXED |
| 4 | Minor | `_handleForegroundMessage` | iOS foreground notifications had no explicit `presentAlert`/`presentBadge`/`presentSound` settings, relying on defaults that may be silent depending on device configuration. | Added `presentAlert: true, presentBadge: true, presentSound: true` to `DarwinNotificationDetails`. | FIXED |
| 5 | Minor | `_ErrorCard` | Displayed raw `error.toString()` which could expose internal exception details (e.g., `DioException: 500 Internal Server Error`) to the user. | Removed the error message parameter. Error card now shows a fixed human-friendly message. Raw error logged via `debugPrint`. | FIXED |
| 6 | Minor | `_navigateFromNotification` | Silent catch-all `catch (_)` swallowed all navigation errors with no logging, making deep-link debugging impossible. | Changed to `catch (e)` with `debugPrint` for diagnostics. | FIXED |
| 7 | Minor | `PushNotificationService` | Stream subscriptions for `onTokenRefresh`, `onMessage`, and `onMessageOpenedApp` were never cancelled. On logout then re-login, duplicate listeners would accumulate, causing double notifications or double navigation. | Subscriptions are now stored in fields and cancelled in `deactivateToken()`. Previous subscriptions are also cancelled before re-subscribing in `initialize()`. | FIXED |

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | AA | `_OsPermissionBanner` icon had no `semanticLabel` -- screen readers announced nothing for the notification-off icon. | Added `semanticLabel: 'Notifications disabled'` to the icon. | FIXED |
| 2 | AA | `SwitchListTile` toggles relied solely on default semantics which may not convey the notification category clearly to assistive technology users. | Wrapped each toggle in `Semantics(toggled:, label:, hint:)` with descriptive text like "Workout Logged notifications". | FIXED |
| 3 | A | Banner button semantic label said "Enable notifications" but the action now opens system settings, which is a different action. | Updated to "Open notification settings". | FIXED |

## Missing States

- [x] Loading / skeleton -- shimmer skeleton present, matches toggle layout shape (icon + text + switch)
- [x] Empty / zero data -- defaults to `true` for all categories if key is missing from API response (sensible default; new users get all notifications)
- [x] Error / failure -- error card with retry button for load failure, plus toast on toggle failure with optimistic rollback
- [x] Success / confirmation -- optimistic toggle update provides instant visual feedback
- [x] Offline / degraded -- error state with retry covers network failures
- [x] Permission denied -- OS banner displayed when notifications are off at system level; banner now auto-refreshes when user returns from settings

## Deep Linking Evaluation

| Notification Type | Route | Natural? | Notes |
|-------------------|-------|----------|-------|
| `community_event_created` | `/community/events/:id` | Yes | Goes directly to the event detail -- user sees what was created |
| `community_event_updated` | `/community/events/:id` | Yes | Same screen; user sees the latest state of the event |
| `community_event_cancelled` | `/community/events/:id` | Acceptable | Event detail should show cancelled state; consider adding a transient banner |
| `community_event_reminder` | `/community/events/:id` | Yes | Correct destination for a "starting soon" reminder |
| `announcement` | `/announcements` | Yes | Goes to announcements list |
| `community_comment` / `community_activity` | `/community` | Acceptable | Could deep link to specific post if `post_id` were in payload |
| Unknown `type` | No navigation | Correct | Silent no-op; logged for debugging |

## Notification Content Clarity

The notification content is defined server-side. The mobile service correctly passes through `title` and `body` from FCM. The data payload contract (`type` + `event_id`) is clean and sufficient for routing. Data-only messages (no `notification` block) are correctly ignored by the foreground handler since they are intended for background processing only.

## Notification Preferences Toggle UI

The toggle UI is well-structured:
- Role-based sections (trainer vs trainee) are clearly separated with uppercase section headers
- Labels and subtitles are descriptive and use plain language
- Icons provide quick visual scanning (e.g., fitness_center for workouts, campaign for announcements)
- Optimistic updates with rollback on failure give immediate feedback without waiting for the API
- Error toast on toggle failure uses clear, actionable copy ("Failed to update preference. Please try again.")
- The `community_event` toggle is correctly placed in the trainee "Updates" section

## Auth Lifecycle Integration

- `initialize()` is called via `unawaited()` after every login path (email, Google, Apple, impersonation, registration) -- correct; doesn't block the login flow
- `deactivateToken()` is called in both `logout()` and `deleteAccount()` -- correct; cleans up subscriptions and server-side token
- Stream subscriptions are cancelled on deactivation, preventing duplicate listeners on re-login -- correct

## Remaining Recommendations (Not Fixed -- Require Design Decisions)

1. **Pre-permission screen (High impact)**: Add an in-app screen before the iOS system permission dialog that explains why notifications matter (e.g., "Never miss an event, announcement, or message from your trainer"). This converts the cold ask into a warm ask and significantly improves opt-in rates (industry data shows 2-3x improvement). Requires a new screen design.

2. **Master toggle (Medium impact)**: Consider adding a "Pause all notifications" toggle at the top of the preferences screen. Common pattern in Slack, Discord, and other notification-heavy apps. Gives users a quick escape valve without toggling each category individually.

3. **Deep link to specific post (Low impact)**: `community_comment` and `community_activity` notifications navigate to `/community` (feed root). If the payload included a `post_id`, the user could land directly on the relevant post.

4. **Notification permission in onboarding (Medium impact)**: During the 4-step onboarding wizard, consider adding notification opt-in as a final step or post-onboarding prompt. This is the highest-intent moment to ask for permission.

---

## Overall UX Score: 8/10

The implementation covers all critical states (loading, error, empty, success, permission denied), has solid accessibility with semantic labels on all interactive elements, and the deep linking routes map correctly to existing screens. The auth lifecycle integration is thorough -- all login/logout paths are covered. The main gap is the cold permission ask with no pre-permission rationale, which is a design-level decision. With the seven fixes applied in this audit (OS settings redirect, blank notification guard, iOS sound/badge/alert, error message sanitization, debug logging, accessibility labels, and lifecycle observer), the notification UX is production-ready.
