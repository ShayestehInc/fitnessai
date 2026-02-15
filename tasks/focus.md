# Pipeline 7 Focus: Activate Dead Features + Security Settings

## Priority: HIGH

## What
Three high-impact features that currently show "coming soon" or have TODO placeholders:
1. **Activate AI Food Parsing** — The AI Entry tab on Add Food screen shows "AI parsing coming soon" even though the backend endpoint, service, and mobile provider are FULLY WIRED. Just need to remove the misleading banner and add meal selector context.
2. **Wire Password Change** — Settings → Security → Change Password has full UI but the `_changePassword()` method is a TODO with `await Future.delayed()`. Djoser provides `POST /api/auth/users/set_password/`.
3. **Send Invitation Emails** — Trainer → Invitations → resend has `# TODO: Send email notification`. Django email is already configured (Pipeline 6). Need to send actual invite emails.

## Why
- **AI Food Parsing**: The product's core value prop is "AI-powered logging." The tab exists, the backend works, but users see "coming soon." This is embarrassing.
- **Password Change**: Users can reset passwords from login screen (Pipeline 6) but can't change passwords while logged in. Basic security.
- **Invitation Emails**: Trainers create invitations but trainees never receive them. The onboarding flow is broken at step 1.

## Who Benefits
- **Trainees**: Can use AI to log food (core feature), can change password (security)
- **Trainers**: Can actually invite trainees via email (onboarding)
- **Platform**: Core AI feature activated, security hardened, onboarding funnel fixed

## Success Metric
- User types "2 eggs and toast" in AI Entry tab → sees parsed foods with macros → confirms → saved to daily log
- User changes password from Settings → Security → logs in with new password
- Trainer creates invitation → trainee receives email with invite code + registration link
