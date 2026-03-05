# Dev Done: Notification Preferences, Reminders & Dead UI Cleanup (Pipeline 42)

## Date: 2026-03-04

## Files Changed (78 total)

### Backend — New
- `backend/users/models.py` — Added `NotificationPreference` model (9 boolean fields, OneToOne to User)
- `backend/users/serializers.py` — Added `NotificationPreferenceSerializer`
- `backend/users/views.py` — Added `NotificationPreferenceView` (GET/PATCH)
- `backend/users/urls.py` — Added route
- `backend/users/migrations/0008_add_notification_preference.py` — Migration
- `backend/core/services/notification_service.py` — Added `_check_notification_preference()` + `category` param on `send_push_notification()`

### Mobile — New Screens
- `notification_preferences_screen.dart` — Role-based toggle list with optimistic updates
- `reminders_screen.dart` — Local workout/meal/weight reminders with time pickers
- `help_support_screen.dart` — FAQ accordion, contact card, version info
- `notification_preferences_repository.dart` — API calls for preferences
- `notification_preferences_provider.dart` — AsyncNotifier with optimistic toggle
- `reminder_service.dart` — FlutterLocalNotifications wrapper with SharedPreferences persistence

### Mobile — Adaptive Widgets (from prior plan phases)
- `adaptive_tappable.dart` — iOS opacity fade vs Android ripple
- `adaptive_search_bar.dart` — CupertinoSearchTextField vs Material TextField
- `adaptive_page.dart` — CupertinoPage vs MaterialPage for go_router
- `adaptive_dialog.dart` — Added `showAdaptiveTextInputDialog`
- `adaptive_icons.dart` — Added nav-specific SF Symbols mappings

### Mobile — Dead UI Wired Up
- `settings_screen.dart` — Removed 5 "Coming Soon" tiles, wired Push Notifications, Help & Support, Reminders
- `trainee_detail_screen.dart` — Message button → existing chat, Schedule button → assign program

### Mobile — Cleanup
- `api_client.dart` — Removed all print() + LogInterceptor
- `admin_repository.dart` — Removed ~25 debug print() statements
- `widget_test.dart` — Replaced broken counter test with smoke test

### Mobile — Router
- `app_router.dart` — Added 3 new routes, converted ~85 routes to `adaptivePage`/`adaptiveFullscreenPage`

### Mobile — Dialog/Widget Migrations (~30 files)
- Converted showDialog → showAdaptiveConfirmDialog / showAdaptiveTextInputDialog
- Converted InkWell → AdaptiveTappable in high-visibility screens
- Converted search fields → AdaptiveSearchBar
- Updated navigation shells with AdaptiveIcons

## Key Decisions
1. Backend fails open: if preference check fails, notification is still sent (safety)
2. Reminders are local-only (SharedPreferences) — no server sync needed
3. Help screen uses url_launcher mailto: for support contact
4. Removed Email Notifications tile entirely (no backend for it)
5. Schedule button on trainee detail navigates to assign program route

## Review Fixes Applied (Round 1)

### Critical Fixes
1. **notification_preferences_provider.dart** — Fixed Dart map key bug: `{...previous, category: enabled}` used string literal "category" as key instead of the variable value. Now uses `Map.from(previous)` with explicit `[category] = enabled`.
2. **users/models.py** — Added `VALID_CATEGORIES` frozenset to `NotificationPreference` model. `is_category_enabled()` now validates category against the allowlist and raises `ValueError` for invalid categories.
3. **notification_service.py** — `send_push_to_group()` now accepts a `category` parameter and filters out users who have disabled that notification category using a single batch query.

### Major Fixes
4. **notification_service.py** — Narrowed exception catch in `_check_notification_preference` from `Exception` to `(DatabaseError, ConnectionError)` so programming errors propagate.
5. **reminder_service.dart** — Replaced brittle UTC-offset-to-IANA mapping with `flutter_timezone` package (^3.0.1). Now gets the actual platform timezone name.
6. **reminder_service.dart** — Added `onDidReceiveNotificationResponse` callback to `_plugin.initialize()`. Added `payload` parameter to all `zonedSchedule` calls ('workout', 'meal', 'weight'). Added `onNotificationTapped` callback hook for navigation.
7. **reminders_screen.dart** — Replaced `Platform.isIOS` (dart:io) with `defaultTargetPlatform == TargetPlatform.iOS`. Removed `dart:io` import.
8. **notification_preferences_screen.dart** — Added `debugPrint` to the empty catch block in `_checkOsPermission`.
9. **notification_preferences_repository.dart** — Added type validation: `if (data is! Map) throw FormatException(...)` before casting `response.data`.
10. **help_support_screen.dart** — Replaced hardcoded `_appVersion = '1.0.0'` with `package_info_plus` (^8.2.1). Converted from `ConsumerWidget` to `ConsumerStatefulWidget` to load version asynchronously.
11. **Callers of send_push_notification/send_push_to_group** — Added `category=` parameter:
    - `messaging_service.py:648` → `category='new_message'`
    - `community/views.py:783` → `category='community_activity'`
    - `community/trainer_views.py:210` → `category='trainer_announcement'`

### Minor Fixes
12. **reminders_screen.dart** — Replaced `InkWell` with `AdaptiveTappable` in `_buildTimeRow`.
13. **notification_preferences_screen.dart** — Removed unused `flutter/foundation.dart` import (kept since `debugPrint` re-exports from `material.dart`).
14. **help_support_screen.dart** — `_launchSupportEmail` now copies email to clipboard and shows toast if `canLaunchUrl` returns false.
15. **reminder_service.dart** — Added `payload` to all `zonedSchedule` calls (covered by fix #6).
16. **settings_screen.dart** — Added Help & Support tile to `_buildTraineeSettings()` under new SUPPORT section.
17. **notification_preferences_provider.dart** — Clarified comment on rethrow behavior; pattern is correct (AsyncData rollback, not AsyncError).

### Additional Cleanup
- Removed unused `dart:io` import from `reminder_service.dart`
- Removed unused `package:dio/dio.dart` import from `notification_preferences_repository.dart`
- Fixed unused `api_client.dart` import (was wrong import; `apiClientProvider` is defined in `auth_provider.dart`)

## How to Test
1. Settings → Push Notifications: toggle categories, verify API calls
2. Settings → Reminders: set workout/meal times, verify local notifications schedule
3. Settings → Help & Support: tap FAQ items, tap contact
4. Trainer → Trainee Detail: tap Message (opens chat), tap Schedule (opens assign program)
5. iOS: verify swipe-back gesture works on all pushed screens
6. iOS: verify CupertinoAlertDialog on confirm actions
7. Android: verify Material dialogs and ripple effects unchanged
