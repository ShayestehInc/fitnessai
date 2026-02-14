# Pipeline 6 Focus: Trainee Home Experience + Password Reset

## Priority: HIGH

## What
Fix the most impactful dead UI and incomplete features affecting the trainee daily experience:
1. **Password Reset Flow** — "Forgot password?" button shows "Coming soon!" snackbar. Users locked out permanently. Djoser backend supports this but mobile isn't wired.
2. **Home Screen Progress Tracking** — Weekly workout completion progress hardcoded to 0%. No motivation feedback.
3. **Dead Notification Button** — Trainee home screen has a notifications icon that does nothing (TODO comment). Wire it up or replace with something useful.
4. **Food Entry Edit/Delete** — Edit/delete icons visible on food entries but non-functional. Users can't correct meal logging mistakes.

## Why
- **Password Reset**: Security-critical infrastructure. Users who forget passwords are permanently locked out. This is the #1 gap in auth flow.
- **Progress Tracking**: The home screen is the first thing trainees see daily. Showing 0% progress kills motivation. Real data exists in DailyLog.
- **Dead UI**: Dead buttons erode user trust. The notification icon and food edit/delete buttons look interactive but do nothing.

## Who Benefits
- **Trainees**: Can recover accounts, see real progress, correct nutrition mistakes
- **Platform**: Reduced support tickets (password resets), better engagement (progress), better data quality (food editing)

## Success Metric
- User taps "Forgot password?" → receives reset email → can set new password → logs in
- Home screen shows real weekly workout completion percentage from DailyLog data
- Food entries can be edited and deleted from the nutrition log
