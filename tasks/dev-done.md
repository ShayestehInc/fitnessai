# Dev Done: Trainee Home Experience + Password Reset

## Date: 2026-02-14

## Summary
Implemented all 4 user stories: password reset flow, weekly workout progress, food entry edit/delete, and dead notification button fix. Both backend endpoints and mobile UI are complete.

## Files Created
1. `mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart` — Email input screen with loading/success states
2. `mobile/lib/features/auth/presentation/screens/reset_password_screen.dart` — New password screen with uid/token params, validation, success state
3. `mobile/lib/features/nutrition/presentation/widgets/edit_food_entry_sheet.dart` — Bottom sheet for editing/deleting food entries with confirmation dialog

## Files Modified

### Backend
4. `backend/config/settings.py` — Added EMAIL_BACKEND (console for dev, SMTP via env vars for prod), Djoser DOMAIN/SITE_NAME/PASSWORD_RESET_CONFIRM_URL
5. `backend/workouts/views.py` — Added 3 new actions on DailyLogViewSet:
   - `weekly_progress` (GET): Returns total_days, completed_days, percentage, has_program for current Mon-Sun week
   - `edit_meal_entry` (PUT): Edits a food entry in DailyLog.nutrition_data by meal/entry index, recalculates totals
   - `delete_meal_entry` (DELETE): Removes a food entry, recalculates totals
   - Added `_count_weekly_workout_days` and `_recalculate_nutrition_totals` helper methods

### Mobile
6. `mobile/lib/core/constants/api_constants.dart` — Added resetPassword, resetPasswordConfirm, weeklyProgress, editMealEntry(logId), deleteMealEntry(logId)
7. `mobile/lib/core/router/app_router.dart` — Added /forgot-password and /reset-password/:uid/:token routes, updated redirect guard for unauthenticated access
8. `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Added requestPasswordReset and confirmPasswordReset methods
9. `mobile/lib/features/auth/presentation/screens/login_screen.dart` — Wired "Forgot password?" button to navigate to /forgot-password (was showing "Coming soon!" snackbar)
10. `mobile/lib/features/home/presentation/providers/home_provider.dart` — Added WeeklyProgressData class, weeklyProgress field to HomeState, parallel fetch in loadDashboardData
11. `mobile/lib/features/home/presentation/screens/home_screen.dart` — Added weekly progress section with animated progress bar (visible only when trainee has a program), fixed dead notification button with info dialog
12. `mobile/lib/features/nutrition/data/repositories/nutrition_repository.dart` — Added editMealEntry, deleteMealEntry, getWeeklyProgress, getDailyLogForDate methods
13. `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` — Wired edit/delete on food entries via bottom sheet, tracks entry indices in flat meals array
14. `mobile/lib/features/nutrition/presentation/providers/nutrition_provider.dart` — Added getDailyLogId method for fetching log ID by date

## Key Decisions
- **Password reset uses Djoser's built-in endpoints** — No custom views needed. Djoser handles email sending, token generation, validation.
- **Weekly progress endpoint is an @action on DailyLogViewSet** — Keeps workout-related endpoints together. Uses `daily-logs/weekly-progress/` path.
- **Food edit/delete use meal_index + entry_index** — The nutrition_data JSON stores meals as a flat list. We identify entries by their position in the array. This matches how the mobile client already groups and indexes entries.
- **Totals recalculation on edit/delete** — Backend recalculates `daily_totals` from all entries after modification to prevent inconsistency.
- **Notification button shows info dialog** — Since trainees don't have a notification system yet (only trainers do), showing an info dialog is the honest approach vs faking a screen.
- **No optimistic UI** — Given the complexity of index-based mutations and potential race conditions, we do synchronous API calls with loading state. The refresh after success ensures data consistency.

## Deviations from Ticket
- AC-16 (Optimistic UI update with revert on failure): Not implemented. The complexity of reverting index-based mutations in a shared JSON structure makes optimistic updates error-prone. Instead, we show a loading indicator and refresh data after success. This is more reliable.
- AC-8 path: Ticket said `/api/workouts/weekly-progress/` but endpoint is at `/api/workouts/daily-logs/weekly-progress/` (as an @action on DailyLogViewSet)

## How to Manually Test

### Password Reset
1. Go to login screen
2. Tap "Forgot password?" — should navigate to ForgotPasswordScreen
3. Enter email, tap "Send Reset Link" — should show success confirmation
4. Check console for email output (dev mode)
5. The reset link contains uid/token for the ResetPasswordScreen

### Weekly Progress
1. Log in as a trainee with an active program
2. Home screen should show progress bar with percentage
3. If no program, progress section should be hidden
4. Pull to refresh to reload progress

### Food Edit/Delete
1. Go to Nutrition screen
2. Add some food entries via AI logging
3. Tap the edit icon on any food entry — should open edit bottom sheet
4. Modify values and save — should update entry and refresh totals
5. Tap delete in bottom sheet — should show confirmation, then remove entry

### Notification Button
1. On home screen, tap the notification bell icon
2. Should show info dialog saying "Notifications are coming soon!"

## Test Results
- Backend: 186 total tests, 184 passed, 2 pre-existing MCP module errors (not our code)
- Flutter analyze: No errors in our modified files (only pre-existing info-level warnings)
