# Feature: Trainee Home Experience + Password Reset

## Priority
High — Password reset is security-critical (locked-out users have zero recovery). Home screen progress and food edit/delete are daily-use UX gaps that erode trust.

## User Stories
1. As a **trainee**, I want to reset my password via email so that I can recover my account when I forget my login.
2. As a **trainee**, I want to see my weekly workout progress on the home screen so that I feel motivated to stay on track.
3. As a **trainee**, I want to edit or delete food entries in my nutrition log so that I can correct mistakes.
4. As a **trainee**, I want the notification button on the home screen to do something useful instead of being dead.

## Acceptance Criteria

### Password Reset (AC-1 through AC-7)
- [ ] AC-1: Backend email is configured (console backend for dev, SMTP for prod via env vars)
- [ ] AC-2: Djoser `DOMAIN` and `SITE_NAME` are configured for password reset email links
- [ ] AC-3: `POST /api/auth/users/reset_password/` with `{"email": "user@example.com"}` sends a reset email (or returns 204 silently if email not found — no email enumeration)
- [ ] AC-4: Mobile "Forgot password?" button navigates to a new `ForgotPasswordScreen` with email input
- [ ] AC-5: After submitting email, user sees confirmation screen: "Check your email for a reset link"
- [ ] AC-6: `POST /api/auth/users/reset_password_confirm/` with `{uid, token, new_password}` resets the password
- [ ] AC-7: Mobile has a `ResetPasswordScreen` accessible via deep link that accepts uid/token and lets user set new password

### Home Screen Progress (AC-8 through AC-11)
- [ ] AC-8: Backend endpoint `GET /api/workouts/weekly-progress/` returns `{total_days, completed_days, percentage}` for the current week (Mon-Sun)
- [ ] AC-9: A "completed day" is any day with non-empty `DailyLog.workout_data` for the trainee
- [ ] AC-10: Home screen progress bar shows real percentage from the API instead of hardcoded 0%
- [ ] AC-11: Progress refreshes on pull-to-refresh and screen focus

### Food Entry Edit/Delete (AC-12 through AC-16)
- [ ] AC-12: Tapping the edit icon on a food entry opens an edit bottom sheet with pre-filled fields (name, protein, carbs, fat, calories)
- [ ] AC-13: User can update any field and save — updates `DailyLog.nutrition_data` on the backend
- [ ] AC-14: User can delete a food entry — removes it from `DailyLog.nutrition_data` meals array
- [ ] AC-15: After edit/delete, macro totals recalculate automatically
- [ ] AC-16: Optimistic UI update with revert on failure

### Dead Button Fix (AC-17)
- [ ] AC-17: Home screen notification button navigates to a relevant screen (settings, or shows "No notifications" if trainee has no notification system yet)

## Edge Cases
1. **Email not found**: Password reset returns 204 regardless (Djoser default) — no email enumeration
2. **Expired token**: Reset confirm returns 400 with clear error — user can request a new email
3. **Weak password**: Django validators reject it — show validation errors on the mobile screen
4. **Zero workout days this week**: Progress shows 0% with encouraging copy ("Start your first workout!")
5. **No program assigned**: Progress section hidden entirely (no misleading 0%)
6. **Delete last food entry in a meal**: Meal section becomes empty — show empty state or remove meal header
7. **Edit food entry with zero values**: Allow zeros for partial entries (e.g., "black coffee" = 0 carbs)
8. **Network failure during food edit**: Optimistic update reverts, shows error snackbar
9. **Multiple quick edits**: Each edit is independent — no race conditions
10. **Password reset on already-logged-in user**: Still works — useful for proactive password changes

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Password reset email fails to send | "Check your email" (don't reveal failure) | Log error server-side |
| Invalid/expired reset token | "This link has expired. Request a new one." | Return 400 |
| Weak password on reset | Inline validation errors below password field | Return 400 with field errors |
| Network failure on progress load | Progress section shows last cached value or skeleton | Retry on pull-to-refresh |
| Network failure on food edit | Reverts to original values, shows error snackbar | Logs error |
| Food edit returns 404 (deleted log) | "Entry no longer exists" snackbar | Refreshes nutrition data |

## UX Requirements
- **Forgot Password Screen**: Email input, "Send Reset Link" button, loading state, success confirmation with "Back to Login" button
- **Reset Password Screen**: New password + confirm password fields, strength indicator, submit button
- **Progress Bar**: Animated fill, percentage text, encouraging copy when low/zero
- **Food Edit Bottom Sheet**: Pre-filled form fields, save/cancel buttons, delete button (red, with confirmation)
- **Loading states**: Skeleton shimmer for progress section, button loading indicator for password reset
- **Empty states**: "No workouts this week" for zero progress, "Start your first workout!" CTA
- **Success feedback**: Snackbar after food edit/delete, confirmation screen after password reset request

## Technical Approach

### Backend
1. **Email Configuration** (`config/settings.py`):
   - Add `EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'` for dev
   - Add env-var overrides for prod: `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `EMAIL_USE_TLS`, `DEFAULT_FROM_EMAIL`
   - Configure `DJOSER['DOMAIN']` and `DJOSER['SITE_NAME']` for reset email links

2. **Weekly Progress Endpoint** (`workouts/views.py`):
   - New `@action` on `DailyLogViewSet` or standalone `APIView`
   - `GET /api/workouts/weekly-progress/`
   - Query: `DailyLog.objects.filter(trainee=user, date__range=(monday, sunday), workout_data__isnull=False).exclude(workout_data={})` count
   - Calculate total expected days from active program schedule
   - Return `{total_days, completed_days, percentage, week_start, week_end}`

3. **Food Entry Edit/Delete** (`workouts/views.py`):
   - New actions on `DailyLogViewSet`: `edit-meal-entry` and `delete-meal-entry`
   - `PUT /api/workouts/daily-logs/<id>/edit-meal-entry/` with `{meal_index, entry_index, data}`
   - `DELETE /api/workouts/daily-logs/<id>/delete-meal-entry/` with `{meal_index, entry_index}`
   - Both modify `nutrition_data` JSON, recalculate totals, save with `update_fields=['nutrition_data']`

### Mobile
1. **Password Reset Screens**:
   - Create `forgot_password_screen.dart` — email input + submit
   - Create `reset_password_screen.dart` — new password + confirm + submit (for deep link)
   - Add API constants for reset endpoints
   - Add repository methods
   - Add routes to `app_router.dart`
   - Wire "Forgot password?" button on login screen

2. **Home Screen Progress**:
   - Add `weeklyProgressProvider` in home_provider.dart
   - Replace hardcoded 0% with real API data
   - Add API constant and repository method
   - Handle no-program state (hide progress section)

3. **Food Entry Edit/Delete**:
   - Create `edit_food_entry_sheet.dart` — bottom sheet with pre-filled form
   - Add edit/delete methods to nutrition repository
   - Wire the existing edit icon button on nutrition screen
   - Add delete with confirmation dialog
   - Optimistic update with revert

4. **Dead Notification Button**:
   - Replace TODO with navigation to settings or a simple "Notifications coming soon" info dialog (not a dead button)

### Files to Create
- `mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `mobile/lib/features/auth/presentation/screens/reset_password_screen.dart`
- `mobile/lib/features/nutrition/presentation/widgets/edit_food_entry_sheet.dart`

### Files to Modify
- `backend/config/settings.py` — Email config, Djoser domain/site
- `backend/workouts/views.py` — Weekly progress endpoint, food edit/delete actions
- `mobile/lib/features/auth/presentation/screens/login_screen.dart` — Wire forgot password
- `mobile/lib/features/home/presentation/providers/home_provider.dart` — Real progress
- `mobile/lib/features/home/presentation/screens/home_screen.dart` — Wire notification button, progress
- `mobile/lib/features/nutrition/presentation/screens/nutrition_screen.dart` — Wire food edit/delete
- `mobile/lib/core/constants/api_constants.dart` — New endpoints
- `mobile/lib/core/router/app_router.dart` — New routes
- `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Password reset methods (or create if doesn't exist)
- `mobile/lib/features/nutrition/data/repositories/nutrition_repository.dart` — Edit/delete methods

## Out of Scope
- Custom password reset email templates (use Djoser defaults)
- Real-time push notifications for trainees (separate feature)
- AI food parsing integration (separate feature)
- 2FA setup (separate feature)
- Deep link handling for password reset (mobile deep link infra needed — for now, user copies uid/token manually or we provide a simple web page)
