# Code Review: Notification Preferences, Reminders & Dead UI Cleanup

## Review Date: 2026-03-04

## Files Reviewed
- `backend/users/models.py` (NotificationPreference model)
- `backend/users/serializers.py` (NotificationPreferenceSerializer)
- `backend/users/views.py` (NotificationPreferenceView)
- `backend/users/urls.py` (new route)
- `backend/users/migrations/0008_add_notification_preference.py`
- `backend/core/services/notification_service.py` (_check_notification_preference + category param)
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`
- `mobile/lib/features/settings/presentation/screens/reminders_screen.dart`
- `mobile/lib/features/settings/presentation/screens/help_support_screen.dart`
- `mobile/lib/core/services/reminder_service.dart`
- `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
- `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart`
- `mobile/lib/core/constants/api_constants.dart`
- ~30 additional files with dialog/widget migration changes (spot-checked)

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 1 | `notification_preferences_provider.dart:29` | **Optimistic update uses string literal key instead of variable.** The line `state = AsyncData({...previous, category: enabled});` creates a map entry with the *literal key* `"category"` instead of the *variable value* of `category`. This means all toggles overwrite the same wrong key and the UI will never reflect the actual change until the server response arrives. | Fix: `final updated = Map<String, bool>.from(previous); updated[category] = enabled; state = AsyncData(updated);` |
| 2 | `notification_service.py:59-75` | **`is_category_enabled` uses `getattr` with an unvalidated string.** The `category` parameter in `send_push_notification` flows to `getattr(self, category, True)` on the model. If a caller ever passes an unexpected attribute name (e.g., `"user"`, `"pk"`, `"delete"`), `getattr` would return arbitrary model attributes/methods, which `bool()` would cast to `True`. This is a latent injection vector and also means typos silently "enable" notifications. | Validate `category` against an allowlist. Add `VALID_CATEGORIES = frozenset({'trainee_workout', 'trainee_weight_checkin', 'trainee_started_workout', 'trainee_finished_workout', 'churn_alert', 'trainer_announcement', 'achievement_earned', 'new_message', 'community_activity'})` on the model and check membership before `getattr`. |
| 3 | `notification_service.py:124-179` | **`send_push_to_group` does not check notification preferences.** `send_push_notification` checks preferences via `_check_notification_preference`, but `send_push_to_group` skips this entirely. Trainer announcements (which use `send_push_to_group` in `community/trainer_views.py:210`) will still be sent even if a trainee has disabled `trainer_announcement`. AC-6 states "Push notification sending checks user preference before dispatching FCM." | Add a `category` parameter to `send_push_to_group` and filter `user_ids` against their notification preferences before sending. Use a single query: `NotificationPreference.objects.filter(user_id__in=user_ids, <category>=False).values_list('user_id', flat=True)` to get opt-outs, then exclude them. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 4 | `notification_service.py:59-75` | **`_check_notification_preference` silences ALL exceptions.** The `except Exception` block catches everything including `TypeError`, `AttributeError`, programming bugs. The "fail open" design is correct for operational errors (DB down), but swallowing programming errors masks bugs. | Narrow the catch to `(DatabaseError, ConnectionError)` or similar. Let programming errors propagate. |
| 5 | `reminder_service.dart:361-396` | **Timezone resolution is brittle and inaccurate.** `_resolveLocalTimezone` maps UTC offset to IANA timezone using a hardcoded table. This is fundamentally incorrect: many timezones share the same offset, offsets change with DST, and half-hour offsets (IST +5:30, Nepal +5:45) have no mapping at all, falling back to UTC. Reminders would fire at wrong times for those users. | Use the `flutter_timezone` package to get the actual IANA timezone from the platform. The comment on line 365 even acknowledges this. |
| 6 | `reminder_service.dart:130` | **`initialize()` does not pass an `onDidReceiveNotificationResponse` callback.** AC-15 requires "tapping a reminder notification opens the relevant screen." Without handling the notification tap callback, tapping a reminder notification does nothing. | Pass `onDidReceiveNotificationResponse: _onNotificationTapped` to `_plugin.initialize()` and implement routing logic. Also set `payload` on each `zonedSchedule` call (e.g., `payload: 'workout'`). |
| 7 | `reminders_screen.dart:1` | **`dart:io` import makes this file non-web-compatible.** `Platform.isIOS` is used directly on line 168, which throws on web. | Use `defaultTargetPlatform == TargetPlatform.iOS` instead of `Platform.isIOS`. Already done elsewhere in the same file (line 77). |
| 8 | `notification_preferences_screen.dart:161` | **Empty catch block silences errors.** `catch (_) {}` in `_checkOsPermission` swallows all exceptions with no logging. | At minimum log the error, or catch only the specific platform exception type. |
| 9 | `notification_preferences_repository.dart:11` | **Unsafe cast `response.data as Map`.** If the API returns an unexpected format (error HTML, null), this throws an unhandled `TypeError`. | Add type validation: `if (response.data is! Map) throw FormatException('Unexpected response format');` |
| 10 | `help_support_screen.dart:30` | **Hardcoded `_appVersion = '1.0.0'`.** AC-25 says "app version display" but this will always show 1.0.0 regardless of actual version. | Use `package_info_plus` to get the real version at runtime. |
| 11 | Callers of `send_push_notification` in `messaging_service.py:648` and `community/views.py:783` | **Existing callers don't pass `category` parameter.** This means notification preferences are never actually checked for any existing push notifications. The feature is effectively inert on the backend side. | Update callers: `messaging_service.py` -> `category='new_message'`, `community/views.py` -> `category='community_activity'`, `community/trainer_views.py` -> `category='trainer_announcement'`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 12 | `reminders_screen.dart:449` | **`InkWell` used instead of `AdaptiveTappable`** in the time row. The rest of the codebase is being migrated to `AdaptiveTappable`. | Replace `InkWell` with `AdaptiveTappable`. |
| 13 | `notification_preferences_screen.dart:2` | **Unused import: `package:flutter/foundation.dart`.** | Remove it. |
| 14 | `help_support_screen.dart:140-145` | **`_launchSupportEmail` silently fails if `canLaunchUrl` returns false.** User gets no feedback. | Show an error toast or copy the email to clipboard as fallback. |
| 15 | `reminder_service.dart:253-267` | **Daily notification scheduling lacks a `payload`.** The `zonedSchedule` calls don't set a `payload` parameter, so even if tap handling were implemented (Issue #6), the handler wouldn't know which screen to open. | Add `payload: 'workout'`, `payload: 'meal'`, `payload: 'weight'` to each `zonedSchedule` call. |
| 16 | Settings screen (trainee) | **Trainee settings missing Help & Support tile.** The trainer settings include a "Help & Support" tile navigating to `/help-support`, but the trainee settings section does not. AC-19 says it should be accessible to all users. | Add a Help & Support tile to `_buildTraineeSettings()`. |
| 17 | `notification_preferences_screen.dart:173-187` | **Error is both caught/toasted in `_onToggle` AND rethrown from the provider.** The provider rethrows, then `_onToggle` catches it and shows a toast. This works, but if anything else watches the provider's error state, they'd also react to it. Two error-handling paths could lead to double-display. | Pick one error-handling path: either catch in `_onToggle` without rethrowing from the provider, or handle errors solely via the provider's error state. |

## Security Concerns

1. **`getattr` on model with unvalidated string (Issue #2):** While `category` is not directly user-controlled today, the pattern is unsafe. `is_category_enabled('user')` would return the User object, `bool(user)` returns `True`, masking the invalid category. Validate against an explicit allowlist.

2. **No rate limiting on notification preference PATCH endpoint:** A malicious client could spam the PATCH endpoint to create excessive DB writes. Consider adding throttling (`UserRateThrottle`).

3. **No secrets or credentials found in the diff.** Good.

4. **Auth is correctly applied:** `NotificationPreferenceView` uses `[IsAuthenticated]`, and `get_or_create_for_user` scopes to the requesting user. No IDOR risk.

## Performance Concerns

1. **`_check_notification_preference` issues a DB query on every notification send.** For high-volume scenarios (trainer with 100 trainees all active), this adds one query per notification. Consider brief in-process caching or batch-loading preferences.

2. **`send_push_to_group` (once fixed for Issue #3) should batch preference checks.** Use a single `NotificationPreference.objects.filter(user_id__in=user_ids)` query rather than N individual queries.

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | NotificationPreferencesScreen exists and is routed from Settings |
| AC-2 | PASS | Toggle switches for all categories, role-based sections |
| AC-3 | PASS | PATCH endpoint exists and works correctly |
| AC-4 | PASS | Shimmer loading skeleton implemented |
| AC-5 | PASS | NotificationPreference model with per-category boolean fields |
| AC-6 | **FAIL** | Preference check exists but no callers pass `category`; `send_push_to_group` skips checks entirely |
| AC-7 | **FAIL** | Optimistic update has a bug — uses literal key "category" instead of variable value |
| AC-8 | PASS | RemindersScreen exists and is routed |
| AC-9 | PASS | Workout reminder toggle with time picker |
| AC-10 | PASS | Meal reminder toggle with time picker |
| AC-11 | PASS | Weight reminder with day + time picker |
| AC-12 | PASS | flutter_local_notifications used correctly |
| AC-13 | PASS | SharedPreferences persistence implemented |
| AC-14 | PARTIAL | Scheduling works but timezone resolution is fragile for non-US users |
| AC-15 | **FAIL** | No notification tap handler — tapping a reminder does nothing |
| AC-16 | PASS | Analytics navigates to `/trainer/retention` |
| AC-17 | PASS | Push Notifications navigates to NotificationPreferencesScreen |
| AC-18 | PASS | Email Notifications tile removed |
| AC-19 | PARTIAL | Help & Support exists for trainer but missing for trainee |
| AC-20 | PASS | Reminders tile navigates to RemindersScreen |
| AC-21 | PASS | Message button opens conversation |
| AC-22 | PASS | Schedule button navigates to assign program |
| AC-23 | PASS | HelpSupportScreen with FAQ accordion and contact card |
| AC-24 | PASS | All FAQ sections present, billing for trainer only |
| AC-25 | PARTIAL | Version displayed but hardcoded "1.0.0" |
| AC-26 | PASS | print() removed from api_client.dart |
| AC-27 | PASS | print() removed from admin_repository.dart |
| AC-28 | PASS | widget_test.dart replaced with smoke test |

## Quality Score: 5/10

The feature structure is well-organized and follows existing codebase patterns nicely. The new screens have proper loading/error/empty states. The Dead UI cleanup is well-executed with Message and Schedule buttons properly wired. However, there are three critical bugs that make the core notification preferences feature non-functional: (1) the optimistic update Dart map key bug means the UI doesn't reflect toggles correctly, (2) no existing callers pass the `category` parameter so preferences are never actually checked, and (3) `send_push_to_group` bypasses preference checks entirely. Additionally, AC-15 (notification tap routing) is completely unimplemented. These are not edge cases — they affect the primary value proposition of the feature.

## Recommendation: REQUEST CHANGES

---

## Round 2 Review

**Review Date:** 2026-03-04

**Files Reviewed in Round 2:**
- `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
- `backend/users/models.py`
- `backend/core/services/notification_service.py`
- `mobile/lib/core/services/reminder_service.dart`
- `mobile/lib/features/settings/presentation/screens/reminders_screen.dart`
- `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`
- `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
- `mobile/lib/features/settings/presentation/screens/help_support_screen.dart`
- `backend/messaging/services/messaging_service.py` (diff)
- `backend/community/views.py` (diff)
- `backend/community/trainer_views.py` (diff)
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`

### Verified Fixes

- [x] **Critical #1:** Optimistic update map key bug fixed. Lines 28-30 of `notification_preferences_provider.dart` now use `Map<String, bool>.from(previous)` and `optimistic[category] = enabled` -- correctly uses the variable, not a string literal. Verified correct.
- [x] **Critical #2:** `VALID_CATEGORIES` frozenset added to `NotificationPreference` model (lines 347-357 of `users/models.py`). `is_category_enabled()` validates against the allowlist and raises `ValueError` for invalid categories (lines 371-381). Verified correct.
- [x] **Critical #3:** `send_push_to_group` now accepts a `category` parameter (line 130 of `notification_service.py`). It filters opted-out users with a single batch query using `**{category: False}` (lines 153-177). Also validates category against `VALID_CATEGORIES` before querying. Uses `(DatabaseError, ConnectionError)` catch with fail-open. Verified correct.
- [x] **Major #4:** Exception catch in `_check_notification_preference` narrowed from `except Exception` to `except (DatabaseError, ConnectionError)` (line 74). Programming errors now propagate. Verified correct.
- [x] **Major #5:** Timezone resolution replaced with `flutter_timezone` package (line 3 import, lines 385-393 of `reminder_service.dart`). Uses `FlutterTimezone.getLocalTimezone()` to get the actual platform IANA timezone name. Falls back to UTC on failure with `debugPrint` logging. Verified correct.
- [x] **Major #6:** `onDidReceiveNotificationResponse` callback added to `_plugin.initialize()` (line 139). `_onNotificationResponse` method delegates to the `onNotificationTapped` callback hook (lines 145-150). All `zonedSchedule` calls now include `payload` parameter ('workout', 'meal', 'weight'). Verified correct.
- [x] **Major #7:** `dart:io` import removed from `reminders_screen.dart`. `Platform.isIOS` replaced with `defaultTargetPlatform == TargetPlatform.iOS` (line 168 uses `Theme.of(context).platform == TargetPlatform.iOS`). Verified correct.
- [x] **Major #8:** Empty catch block in `_checkOsPermission` now logs with `debugPrint('Failed to check OS notification permission: $e')` (line 161 of `notification_preferences_screen.dart`). Verified correct.
- [x] **Major #9:** Type validation added to `notification_preferences_repository.dart`. Both `getPreferences()` (line 12) and `updatePreference()` (line 25) now check `if (data is! Map) throw FormatException(...)` before casting. Verified correct.
- [x] **Major #10:** Hardcoded version replaced with `package_info_plus`. `HelpSupportScreen` converted to `ConsumerStatefulWidget` with `_loadVersion()` in `initState()` (lines 50-63). Displays "..." while loading, actual version with build number on success, "Unknown" on failure. Error is logged via `debugPrint`. Verified correct.
- [x] **Major #11:** All three callers now pass `category` parameter: `messaging_service.py` passes `category='new_message'`, `community/views.py` passes `category='community_activity'`, `community/trainer_views.py` passes `category='trainer_announcement'`. Verified via git diff -- all correct.
- [x] **Minor #12:** `InkWell` replaced with `AdaptiveTappable` in `_buildTimeRow` (line 449 of `reminders_screen.dart`). Verified correct.
- [x] **Minor #13:** `flutter/foundation.dart` import kept since `debugPrint` is used (from fix #8). This is acceptable -- `debugPrint` is re-exported from `material.dart` but having the explicit import is not harmful. Verified acceptable.
- [x] **Minor #14:** `_launchSupportEmail` now copies email to clipboard and shows toast when `canLaunchUrl` returns false (lines 176-184 of `help_support_screen.dart`). Uses `Clipboard.setData` and `showAdaptiveToast` with `ToastType.info`. Verified correct.
- [x] **Minor #15:** Covered by fix #6. All `zonedSchedule` calls now have `payload` parameters. Verified correct.
- [x] **Minor #16:** Help & Support tile added to `_buildTraineeSettings()` under a new "SUPPORT" section (lines 555-564 of `settings_screen.dart`). Routes to `/help-support`. Verified correct.
- [x] **Minor #17:** Provider comment clarified (lines 37-40 of `notification_preferences_provider.dart`). The pattern is sound: state is set to `AsyncData(previous)` on rollback (not `AsyncError`), so watchers only see the rollback. The rethrow allows the caller's try/catch to show a toast. No double-display risk. Verified acceptable.

### New Issues Found

| # | Severity | File:Line | Issue | Suggested Fix |
|---|----------|-----------|-------|---------------|
| - | - | - | No new issues found. | - |

### Acceptance Criteria Re-Verification (previously failing items)

| AC | Status | Notes |
|----|--------|-------|
| AC-6 | **PASS** | All callers now pass `category`; `send_push_to_group` filters opted-out users with batch query |
| AC-7 | **PASS** | Optimistic update correctly uses variable key via `Map.from` + bracket assignment |
| AC-14 | **PASS** | `flutter_timezone` package resolves actual platform IANA timezone |
| AC-15 | **PASS** | `onDidReceiveNotificationResponse` callback wired; payloads set; `onNotificationTapped` hook exposed |
| AC-19 | **PASS** | Help & Support tile added to trainee settings |
| AC-25 | **PASS** | `package_info_plus` reads real version at runtime |

### Flutter Analyze

No errors. 201 issues found (all pre-existing warnings and infos unrelated to this feature). Zero new issues introduced.

### Quality Score: 9/10

All 17 issues from Round 1 have been fixed correctly and thoroughly. The fixes are clean, follow existing codebase patterns, and introduce no regressions. The notification preference check is now end-to-end functional: model validation with `VALID_CATEGORIES`, batch filtering in `send_push_to_group`, and all callers passing the `category` parameter. The mobile fixes are equally solid: proper timezone resolution via `flutter_timezone`, notification tap handling with payloads, real app version via `package_info_plus`, and type-safe response validation. The one point deducted is for the existing performance concern (per-notification DB query in `_check_notification_preference`) which is acceptable for current scale but worth monitoring.

### Recommendation: APPROVE
