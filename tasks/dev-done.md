# Dev Done: Activate AI Food Parsing + Password Change + Invitation Emails

## Date: 2026-02-14

## Summary
Implemented all 3 features: activated the already-wired AI food parsing (removed misleading "coming soon" banner, added meal selector and proper confirm flow), wired password change to Djoser's set_password endpoint, and created invitation email service with HTML/text templates.

## Files Created
1. `backend/trainer/services/invitation_service.py` — Service function `send_invitation_email()` with HTML + plain text email, trainer name display, invite code, registration link, expiry date

## Files Modified

### Backend
2. `backend/trainer/views.py` — Added import for `send_invitation_email`, added logger, wrapped `send_invitation_email()` calls in try/except in both `create()` and resend `post()` methods. Email failures are logged but don't block invitation creation.

### Mobile
3. `mobile/lib/features/nutrition/presentation/screens/add_food_screen.dart` — Removed "AI parsing coming soon" orange banner. Added meal selector (1-4) to AI Entry tab. Added `_confirmAiEntry()` method that checks for empty meals, refreshes nutrition data after confirm, shows success/error snackbars. Changed from Spacer to SingleChildScrollView for scrollability. Added `onChanged` for text field reactivity. Added clarification question UI for AI `needs_clarification` flow.
4. `mobile/lib/core/constants/api_constants.dart` — Added `setPassword` endpoint constant
5. `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Added `changePassword({currentPassword, newPassword})` method calling Djoser's `set_password` endpoint with proper error handling (wrong password detection, field errors, network errors)
6. `mobile/lib/features/settings/presentation/screens/admin_security_screen.dart` — Imported auth provider. Added `_errorMessage` state variable. Replaced TODO `_changePassword()` with actual API call via `authRepositoryProvider`. Added inline error display under "Current Password" field. Error clears on new submission attempt.

## Key Decisions
- **AI food parsing was already wired** — The backend `parse-natural-language` endpoint, mobile logging repository, logging provider, and UI parsing/confirm flow all existed. The only blocker was a misleading "coming soon" banner and missing meal context.
- **Djoser's set_password endpoint used as-is** — No custom view needed. Djoser handles current password verification and Django's password validators.
- **Invitation emails use send_mail()** — Not a custom email class. `fail_silently=False` so failures raise exceptions, which the caller logs and swallows.
- **Email service in trainer/services/** — Following the established pattern from `branding_service.py`.
- **HTML email included** — Clean, inline-styled HTML for email clients that support it, with plain text fallback.

## Deviations from Ticket
- None. All 17 acceptance criteria are addressed.

## How to Manually Test

### AI Food Parsing
1. Log in as a trainee
2. Go to Nutrition → "+" button → AI Entry tab
3. The "AI parsing coming soon" banner should NOT be visible
4. Select a meal number (1-4)
5. Type "I had 2 eggs and a piece of toast with butter"
6. Tap "Log Food" → should show loading spinner
7. If OpenAI key is configured: see parsed preview with food items and macros
8. Tap "Confirm" → food saved, nutrition refreshed, screen pops back
9. If OpenAI key is NOT configured: see error message about AI not being available

### Password Change
1. Log in as any user
2. Go to Settings → Security → Change Password
3. Enter current password, new password (8+ chars), confirm new password
4. Tap "Change Password" → loading spinner
5. If correct: green snackbar, pops back
6. If wrong current password: inline error "Current password is incorrect" under the field

### Invitation Emails
1. Log in as a trainer
2. Go to Trainees → Invite
3. Create a new invitation with an email
4. In dev mode: check Django console output for the email
5. Email should contain trainer name, invite code, registration link, expiry
6. Try "Resend" on a pending invitation → email sent again

## Test Results
- Backend: 186 total tests, 184 passed, 2 pre-existing MCP module errors (not our code)
- Flutter analyze: No new errors in our modified files (only pre-existing info-level warnings)
