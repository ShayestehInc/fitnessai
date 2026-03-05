# Feature: Notification Preferences, Workout/Meal Reminders & Dead UI Cleanup

## Priority
High

## User Story
As a trainer/trainee, I want to configure my notification preferences and set workout/meal reminders so that I receive relevant alerts without being overwhelmed, and I want all settings buttons to actually work instead of showing "Coming Soon."

## Acceptance Criteria

### Notification Preferences Screen (Trainer + Trainee)
- [ ] AC-1: New `NotificationPreferencesScreen` accessible from Settings > Push Notifications
- [ ] AC-2: Toggle switches for each notification category:
  - **Trainer categories:** New trainee workout, New trainee weight check-in, Trainee started workout, Trainee finished workout, At-risk trainee alert, New message, Community activity
  - **Trainee categories:** Trainer announcement, Achievement earned, New message, Community activity
- [ ] AC-3: Preferences saved to backend via new API endpoint `PATCH /api/users/notification-preferences/`
- [ ] AC-4: Preferences loaded from backend on screen open with shimmer loading
- [ ] AC-5: Backend `NotificationPreference` model stores per-user category toggles (default all enabled)
- [ ] AC-6: Push notification sending checks user preference before dispatching FCM
- [ ] AC-7: Changes save immediately on toggle (optimistic update with rollback on error)

### Workout & Meal Reminders (Trainee only)
- [ ] AC-8: New `RemindersScreen` accessible from Settings > Reminders
- [ ] AC-9: Toggle to enable/disable workout reminder with time picker (default 8:00 AM)
- [ ] AC-10: Toggle to enable/disable meal logging reminder with time picker (default 12:00 PM)
- [ ] AC-11: Toggle to enable/disable weight check-in reminder with day picker (default Monday) and time picker (default 7:00 AM)
- [ ] AC-12: Reminders use `flutter_local_notifications` package for scheduled local notifications
- [ ] AC-13: Reminder settings persisted in SharedPreferences (local-only, no backend needed)
- [ ] AC-14: Reminders fire daily/weekly at configured times even when app is closed
- [ ] AC-15: Tapping a reminder notification opens the relevant screen (workout → home, meal → nutrition, weight → weight check-in)

### Dead UI Cleanup
- [ ] AC-16: Settings > Analytics (trainer) → navigates to `/trainer/analytics` instead of "Coming Soon"
- [ ] AC-17: Settings > Push Notifications → navigates to new NotificationPreferencesScreen
- [ ] AC-18: Settings > Email Notifications → removed (no email notification system exists)
- [ ] AC-19: Settings > Help & Support → navigates to in-app support screen with FAQ and contact info
- [ ] AC-20: Settings > Reminders (trainee) → navigates to new RemindersScreen
- [ ] AC-21: Trainee Detail > Message button → navigates to messaging conversation with that trainee (messaging already exists)
- [ ] AC-22: Trainee Detail > Schedule button → navigates to trainee's program view

### Help & Support Screen
- [ ] AC-23: New `HelpSupportScreen` with FAQ accordion and contact email link
- [ ] AC-24: FAQ sections: Getting Started, Workouts, Nutrition, Account, Billing (trainer only)
- [ ] AC-25: Contact section with mailto link and app version display

### Code Cleanup
- [ ] AC-26: Remove all `print()` debug statements from `api_client.dart`
- [ ] AC-27: Remove all `print()` debug statements from `admin_repository.dart`
- [ ] AC-28: Replace broken `widget_test.dart` with a basic smoke test that matches the actual app

## Edge Cases
1. What if user denies notification permission at OS level? → Show explanation and link to device settings
2. What if user sets reminder time to current time? → Schedule for next occurrence (tomorrow/next week)
3. What if user has notifications disabled at OS level but enabled in-app? → Show banner on preferences screen
4. What if backend is unreachable when saving notification preferences? → Rollback toggle with error toast
5. What if user switches timezone? → Local notifications use local time, so they adjust automatically
6. What if reminder fires while app is in foreground? → Show in-app notification banner instead
7. What if user uninstalls and reinstalls? → Reminder settings lost (SharedPreferences cleared), notification preferences restored from backend

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Failed to load notification prefs | Error card with retry button | Shows error, retry fetches again |
| Failed to save notification pref | Toggle reverts with error toast | Rollback optimistic update |
| Notification permission denied | Banner: "Notifications disabled" + settings link | Opens device settings on tap |
| Failed to schedule local notification | Error toast "Could not set reminder" | Log error, don't crash |

## UX Requirements
- **Loading state:** Shimmer skeleton for notification preferences list
- **Empty state:** N/A (always shows all categories)
- **Error state:** Error card with retry for load failures, toast for save failures
- **Success feedback:** Toggle animates smoothly, no extra confirmation needed
- **Mobile behavior:** Standard scrollable list, adaptive time pickers (Cupertino on iOS)

## Technical Approach

### Backend (Django)
- **New model:** `NotificationPreference` in `users/models.py` — JSONField storing category:bool map, OneToOne to User, auto-create on first access
- **New view:** `NotificationPreferenceView` in `users/views.py` — GET/PATCH with `[IsAuthenticated]`
- **New URL:** `path('notification-preferences/', ...)` in `users/urls.py`
- **Modify:** `trainer/services/notification_service.py` — check user preference before `send_push_notification()`
- **Modify:** `community/services/push_service.py` — same preference check

### Mobile (Flutter)
- **New screen:** `mobile/lib/features/settings/presentation/screens/notification_preferences_screen.dart`
- **New screen:** `mobile/lib/features/settings/presentation/screens/reminders_screen.dart`
- **New screen:** `mobile/lib/features/settings/presentation/screens/help_support_screen.dart`
- **New service:** `mobile/lib/core/services/reminder_service.dart` — wraps flutter_local_notifications
- **New provider:** `mobile/lib/features/settings/data/providers/notification_preferences_provider.dart`
- **New repository:** `mobile/lib/features/settings/data/repositories/notification_preferences_repository.dart`
- **Modify:** `mobile/lib/features/settings/presentation/screens/settings_screen.dart` — wire up dead buttons
- **Modify:** `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — wire Message + Schedule buttons
- **Modify:** `mobile/lib/core/router/app_router.dart` — add new routes
- **Modify:** `mobile/lib/core/api/api_client.dart` — remove debug prints
- **Modify:** `mobile/pubspec.yaml` — add `flutter_local_notifications` dependency
- **New route:** `/notification-preferences`
- **New route:** `/reminders`
- **New route:** `/help-support`

### Dependencies
- `flutter_local_notifications: ^18.0.1` (latest stable)

## Out of Scope
- Email notification preferences (no email notification infrastructure exists)
- Notification sound/vibration customization
- Custom reminder messages
- Recurring notification batching/digest
- Push notification preferences on web dashboard
