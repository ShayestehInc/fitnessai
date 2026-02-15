# Feature: Activate AI Food Parsing + Password Change + Invitation Emails

## Priority
High — AI food parsing is the product's core differentiator and is blocked by a misleading "coming soon" banner. Password change is basic security. Invitation emails are critical for trainer onboarding flow.

## User Stories

### Story 1: AI Food Parsing
As a **trainee**, I want to describe what I ate in natural language so that I can quickly log meals without manually entering macros.

### Story 2: Password Change
As a **user** (any role), I want to change my password from the settings screen so that I can maintain account security.

### Story 3: Invitation Emails
As a **trainer**, I want my trainee invitations to send actual emails so that trainees can find and use their invite codes.

## Acceptance Criteria

### AI Food Parsing (AC-1 through AC-6)
- [ ] AC-1: The "AI parsing coming soon" orange banner is removed from the AI Entry tab
- [ ] AC-2: User types natural language food description, taps "Log Food", sees loading spinner
- [ ] AC-3: Parsed foods display in a preview card with name, calories, protein, carbs, fat per item
- [ ] AC-4: User can select which meal number (1-4) to add parsed foods to (meal selector in AI tab)
- [ ] AC-5: User taps "Confirm" → food is saved to daily log → nutrition screen refreshes → screen pops back
- [ ] AC-6: If parsing fails (API error, no OpenAI key, empty input), user sees a clear error message with retry option

### Password Change (AC-7 through AC-11)
- [ ] AC-7: Settings → Security → Change Password calls Djoser's `POST /api/auth/users/set_password/` with `current_password` and `new_password`
- [ ] AC-8: Shows loading indicator during API call
- [ ] AC-9: On success, shows green snackbar "Password changed successfully" and pops back
- [ ] AC-10: On wrong current password (400), shows red error "Current password is incorrect"
- [ ] AC-11: On other errors (network, server), shows descriptive error message

### Invitation Emails (AC-12 through AC-17)
- [ ] AC-12: When trainer creates a new invitation, an email is sent to the invitee's email address
- [ ] AC-13: When trainer resends an invitation (resend action), the email is re-sent
- [ ] AC-14: Email contains: trainer's name, invite code, registration link, expiry date
- [ ] AC-15: Email uses Django's email system (console backend for dev, SMTP for prod — already configured)
- [ ] AC-16: Email sending failure does NOT block the invitation creation (invitation still created, error logged)
- [ ] AC-17: Backend creates the invitation email using a proper service function (not inline in the view)

## Edge Cases
1. AI: User submits empty text → disabled button prevents submission
2. AI: OpenAI API key not configured → backend returns error → mobile shows "AI food parsing is not available. Please use manual entry."
3. AI: User types only workout info, no food → AI parser returns nutrition with 0 meals → show "No food items detected. Try describing what you ate."
4. AI: Very long input (>500 chars) → API handles it, no mobile-side truncation
5. AI: User taps "Log Food" twice rapidly → guard prevents duplicate API calls (isProcessing flag)
6. AI: AI returns `needs_clarification: true` → show clarification question to user
7. Password: User enters current password wrong → 400 from Djoser → "Current password is incorrect"
8. Password: New password too short (<8 chars) → client-side validation prevents submission (already handled)
9. Password: Network error during password change → show retry-able error, keep form state
10. Invitation: Email sending fails (SMTP misconfigured) → invitation still saved, error logged server-side
11. Invitation: Invitation already expired when resending → extend expiry by 7 days, send email
12. Invitation: Invitee email is same as an existing user → invitation still created (backend handles this)

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| AI: empty input | "Log Food" button disabled | Nothing |
| AI: parse API error | Red error banner with message | Logs error |
| AI: no OpenAI key configured | "AI food parsing is not available" in error banner | Backend returns error string |
| AI: confirm/save fails | "Failed to save food entry" red snackbar | Keeps parsed preview for retry |
| AI: no foods detected | "No food items detected" message in preview area | Allows retry with new input |
| Password: wrong current password | "Current password is incorrect" inline error below field | Returns 400 |
| Password: network error | "Network error. Please try again." inline error | Keeps form state intact |
| Password: server error | "Something went wrong. Please try again." | Logs error |
| Invite: email send failure | No visible error (invitation created) | Logs email error server-side |

## UX Requirements
- **AI Entry tab**: Remove orange "coming soon" banner. Add meal selector (1-4) matching manual tab's style. Existing loading/error/preview/confirm flow remains. After successful confirm, refresh nutrition and pop screen.
- **Password change**: Show inline error under "Current Password" field for wrong password. Keep loading spinner on submit button. Don't clear form fields on error so user can fix and retry.
- **Invitation email**: No mobile UI changes — email sending happens silently in backend on create/resend.
- **Loading states**: All already exist (AI tab has isProcessing, password has isLoading).
- **Success feedback**: Green snackbar for password change, screen pop + nutrition refresh for AI food confirm.

## Technical Approach

### AI Food Parsing (Mobile only — backend already works)
- **Modify**: `mobile/lib/features/nutrition/presentation/screens/add_food_screen.dart`
  - Remove the orange "AI parsing coming soon" banner container (lines 490-512)
  - Add meal selector widget (1-4) above the text input, identical to manual entry tab
  - Pass meal context when calling confirmAndSave (prepend "Meal N - " to food names)
  - After successful confirm: call `ref.read(nutritionStateProvider.notifier).refreshDailySummary()` then `context.pop()`
  - Add guard for empty parsed nutrition (no meals detected)

### Password Change (Mobile + existing Djoser endpoint)
- **Modify**: `mobile/lib/core/constants/api_constants.dart` — Add `setPassword` endpoint: `$apiBaseUrl/auth/users/set_password/`
- **Modify**: `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Add `changePassword({currentPassword, newPassword})` method calling Djoser endpoint
- **Modify**: `mobile/lib/features/settings/presentation/screens/admin_security_screen.dart`
  - Replace `// TODO: Implement actual password change API call` + `Future.delayed` with actual API call
  - Add error state variable and inline error display
  - Use auth repository provider (import from auth providers)
  - Handle 400 (wrong password), network errors, and success

### Invitation Emails (Backend)
- **Create**: `backend/trainer/services/invitation_service.py`
  - `send_invitation_email(invitation: TraineeInvitation) -> None` function
  - Uses `django.core.mail.send_mail()` with HTML + text
  - Includes trainer name, invite code, registration link, expiry date
  - Raises on failure (caller wraps in try/except)
- **Modify**: `backend/trainer/views.py`
  - In `TraineeInvitationViewSet.perform_create()` or create action: call `send_invitation_email()` wrapped in try/except
  - In resend action (the one with the TODO): call `send_invitation_email()` wrapped in try/except
  - Log errors but don't fail the response

### Files to Create
- `backend/trainer/services/__init__.py` (if not exists)
- `backend/trainer/services/invitation_service.py`

### Files to Modify
- `mobile/lib/features/nutrition/presentation/screens/add_food_screen.dart` — Remove banner, add meal selector
- `mobile/lib/core/constants/api_constants.dart` — Add setPassword endpoint
- `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Add changePassword method
- `mobile/lib/features/settings/presentation/screens/admin_security_screen.dart` — Wire password change API
- `backend/trainer/views.py` — Send invitation emails on create/resend

## Out of Scope
- 2FA implementation (needs backend TOTP/SMS — separate ticket)
- Social auth wiring (Apple/Google — separate ticket)
- Messaging between trainer/trainee (separate ticket)
- Scheduling feature (separate ticket)
- Active sessions management (needs backend session tracking)
- Admin reminder emails for past-due subscriptions
- Invitation email HTML template styling (plain text is fine for MVP)
