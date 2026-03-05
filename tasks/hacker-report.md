# Hacker Report: Pipeline 42 — Notification Preferences, Reminders, Help & Support

## Date: 2026-03-04

## Files Audited
### New Screens:
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`
- `mobile/lib/features/settings/presentation/screens/reminders_screen.dart`
- `mobile/lib/features/settings/presentation/screens/help_support_screen.dart`

### Modified Screens:
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- `mobile/lib/features/settings/presentation/screens/admin_security_screen.dart`
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart`

### Data Layer:
- `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
- `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
- `mobile/lib/core/services/reminder_service.dart`

### Router:
- `mobile/lib/core/router/app_router.dart`

---

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Medium | AdminSecurityScreen | "Enable 2FA" button | Should initiate 2FA setup flow (authenticator app pairing, QR code, etc.) | Shows confirmation dialog, then displays a toast saying "2FA setup coming soon" -- no actual functionality. **FIXED**: Changed message to "2FA is not yet available. It will be enabled in a future update." for transparency. |
| 2 | Medium | AdminSecurityScreen | "Sign Out All Devices" button | Should invalidate all sessions server-side via API call | Shows confirmation dialog, shows success toast "Signed out from all other devices", but never calls any backend endpoint. Sessions are not actually revoked. |
| 3 | Low | AdminSecurityScreen | Login History section | Should show real login history from backend | Shows hardcoded mock data (iPhone 15 Pro, MacBook Pro, Chrome on Windows). Labeled "PREVIEW ONLY" which is honest, but still non-functional. |
| 4 | Low | AdminSecurityScreen | "Active Sessions" bottom sheet | Should show real active sessions from backend | Shows hardcoded single mock session (iPhone 15 Pro). |
| 5 | Medium | AdminPastDueScreen (line 325) | "Send Reminder" button | Should send a reminder email to past-due user | Has `// TODO: Send reminder email` comment and shows fake "Reminder sent" toast without calling any API. |

---

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | SettingsScreen (Trainee) lines 538-549 | "Reminders" and "Push Notifications" tiles both use `Icons.notifications_outlined` -- visually identical, making them indistinguishable at a glance. | **FIXED**: Changed Reminders icon to `Icons.alarm` to differentiate from Push Notifications. |
| 2 | Medium | AdminSecurityScreen | Extensive use of hardcoded colors (`Colors.red`, `Colors.green`, `Colors.orange`, `Colors.white`) instead of theme-based colors. Will render incorrectly with custom themes or high-contrast accessibility modes. | **PARTIALLY FIXED**: Replaced `Colors.red` with `theme.colorScheme.error` for destructive actions (3 instances on lines 127, 159, 262). The `Colors.green` and `Colors.orange` for 2FA status badges are semantic status colors and acceptable for now. |
| 3 | Low | AdminSecurityScreen line 183 | `const bool is2FAEnabled = false` with `// TODO: Implement actual 2FA status check`. Hardcoded dead state -- the 2FA card always shows "Not Enabled" regardless of actual account state. | Not fixed -- requires backend 2FA implementation. |

---

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Medium | Trainee Settings > Check-in Days | 1. Log in as trainee. 2. Go to Settings. 3. Under TRACKING, tap "Check-in Days". | Should navigate to weigh-in schedule configuration (the Reminders screen has a weight check-in day picker). | Was routing to `/edit-diet` (Diet Preferences screen), identical to the "Diet Preferences" tile in the PROFILE section above. Two different tiles going to the same screen is confusing. **FIXED**: Changed route to `/reminders` where the weight check-in day selection actually lives. |
| 2 | Low | ReminderService timezone | 1. Enable a reminder. 2. Travel to new timezone (or change device timezone). 3. Wait for reminder. | Reminder fires at the correct local time in the new timezone. | `_resolveLocalTimezone()` is called only once during `initialize()`. If the user changes timezone while the app is running, reminders use the old timezone until the next app restart. Minor edge case since app restarts are frequent. |

---

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Trainee Settings | The TRACKING section has 3 tiles: "Check-in Days", "Reminders", and "Push Notifications". "Check-in Days" now routes to Reminders (after fix), making it redundant. Consider removing the "Check-in Days" tile entirely, or adding a deep-link parameter to scroll directly to the weight check-in section of the Reminders screen. | Reduces redundancy and user confusion. Three notification/reminder tiles in a row is overwhelming. |
| 2 | Medium | Reminders Screen | Add a "Test Notification" button for each reminder type so users can verify notifications work before waiting until the scheduled time. | Users often wonder "will this actually work?" -- immediate feedback builds trust in the feature. |
| 3 | Medium | Help & Support Screen | Add a search/filter bar at the top to filter FAQ items by keyword. As more sections are added over time, scrolling through all FAQs becomes tedious. | Better UX scalability as content grows. |
| 4 | Medium | Admin Security | Add "PREVIEW ONLY" badges to the 2FA section and Active Sessions, matching the existing Login History badge. Currently only Login History is honest about being non-functional. | Consistency in communicating real vs. preview features. Users should not have to discover functionality is fake by tapping buttons. |
| 5 | Low | Reminders Screen | When all 3 reminders are disabled (the default state), the screen shows 3 collapsed cards with no encouragement. Consider adding a brief prompt at the top like "Enable reminders to stay on track with your fitness goals." | Empty states should guide the user toward engagement. |
| 6 | Low | Trainer Settings | Trainer settings has a "Push Notifications" tile but no "Reminders" tile. Trainers might benefit from scheduled reminders too (e.g., "Review trainee check-ins" or "Post weekly update"). | Feature parity consideration for future. |
| 7 | Low | Notification Preferences | The provider correctly does optimistic update + rollback on failure, but the screen catches the error silently except for the toast. Consider adding structured error logging (not just debugPrint) for production observability. | Helps debug notification preference sync issues in production. |

---

## Items Not Fixed (Need Backend / Design Decisions)
| # | Issue | Why Not Fixed | Suggested Approach |
|---|-------|---------------|-------------------|
| 1 | Admin Security: 2FA is fully non-functional | Requires backend 2FA implementation (TOTP setup, QR code generation, verification endpoint) | Implement TOTP-based 2FA on backend, then wire up the existing UI to call real endpoints. |
| 2 | Admin Security: "Sign Out All Devices" does nothing | Requires backend endpoint to invalidate JWT tokens for all sessions | Add `POST /api/auth/logout-all/` endpoint that blacklists all refresh tokens for the user. |
| 3 | Admin Security: Login History and Active Sessions are mock data | Requires backend session tracking | Track login events and active sessions in the database, expose via API. |
| 4 | Admin Past Due: "Send Reminder" button is fake | Requires backend email sending integration | Wire button to `POST /api/admin/users/{id}/send-reminder/` endpoint. |

---

## Summary
- Dead UI elements found: 5 (2FA button, Sign Out All, Login History, Active Sessions, Send Reminder)
- Visual bugs found: 3 (duplicate icon, hardcoded colors, hardcoded 2FA state)
- Logic bugs found: 2 (Check-in Days wrong route, timezone edge case)
- Improvements suggested: 7
- Items fixed by hacker: 4

### Files Changed by Hacker
1. **`mobile/lib/features/settings/presentation/screens/settings_screen.dart`** -- Changed Reminders icon from `Icons.notifications_outlined` to `Icons.alarm`; changed "Check-in Days" route from `/edit-diet` to `/reminders`.
2. **`mobile/lib/features/settings/presentation/screens/admin_security_screen.dart`** -- Replaced 3 instances of `Colors.red` with `theme.colorScheme.error` for destructive actions; changed "2FA setup coming soon" toast to more transparent wording.

## Chaos Score: 7/10

The three new screens (Notification Preferences, Reminders, Help & Support) are well-built. They have proper loading/error/success states, correct use of adaptive widgets, good accessibility with Semantics wrappers, and sensible architecture (repository pattern for notification prefs, service singleton for reminders). The notification preferences provider correctly implements optimistic updates with rollback. The reminder service properly handles timezone resolution, daily vs. weekly scheduling, and iOS permission requests.

The main issues are in the *adjacent* code -- the Admin Security screen has multiple non-functional features disguised as real ones (2FA, session management, login history), and the settings screen had a routing bug where two tiles went to the same destination. The fixes applied address the most user-facing issues: visual differentiation of settings tiles, correct routing for check-in days, theme-consistent colors for destructive actions, and honest messaging for unimplemented features.
