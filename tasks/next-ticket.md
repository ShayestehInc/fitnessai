# Feature: Web Dashboard Phase 2 — Settings, Progress Charts, Actionable Notifications & Invitations

## Priority
High — Four existing dead UI surfaces and missing interactions that make the dashboard feel incomplete.

## User Stories

### Story 1: Settings Page
As a **trainer**, I want to edit my profile, change my password, and toggle between light/dark theme so that I can personalize my dashboard experience.

### Story 2: Trainee Progress Charts
As a **trainer**, I want to see weight trends, workout volume progression, and adherence data for each trainee in chart form so that I can make informed coaching decisions.

### Story 3: Notification Click-Through
As a **trainer**, I want to click a notification and be taken to the relevant trainee's detail page so that I can immediately act on the notification.

### Story 4: Invitation Row Actions
As a **trainer**, I want to resend, cancel, or copy the invitation code for pending invitations so that I can manage my outstanding invitations effectively.

## Acceptance Criteria

### Settings Page (AC-1 through AC-10)
- [ ] AC-1: Settings page shows three sections: "Profile", "Appearance", and "Security"
- [ ] AC-2: Profile section has editable fields for first name, last name, and business name. Save button calls `PATCH /api/users/me/` and shows success toast.
- [ ] AC-3: Profile section shows current email as read-only (not editable — email changes are not supported in the backend).
- [ ] AC-4: Profile section shows current profile image with upload and remove buttons. Upload calls `POST /api/users/profile-image/`, remove calls `DELETE /api/users/profile-image/`. Both update the user avatar in the header.
- [ ] AC-5: Appearance section has a theme selector with three options: Light, Dark, System. Uses `next-themes` `useTheme()` hook. Selection is immediate (no save button needed) and persists across sessions.
- [ ] AC-6: Security section has a "Change Password" form with current password, new password, and confirm new password fields. Calls `POST /api/auth/users/set_password/` (Djoser endpoint). Shows success toast and clears form on success. Shows inline error for wrong current password.
- [ ] AC-7: All form fields have proper validation: names max 150 chars, business name max 200 chars, password min 8 chars, confirm must match new.
- [ ] AC-8: Settings page shows loading skeleton while fetching current user data.
- [ ] AC-9: Settings page shows error state with retry if user data fails to load.
- [ ] AC-10: After successful profile save, the user nav dropdown (header) reflects the updated name immediately (React Query cache invalidation).

### Progress Charts (AC-11 through AC-17)
- [ ] AC-11: Progress tab fetches data from `GET /api/trainer/trainees/<id>/progress/` and shows three charts: Weight Trend, Workout Volume, and Adherence.
- [ ] AC-12: Weight Trend chart is a line chart showing weight (kg) over time. X-axis: dates, Y-axis: weight. Shows "No weight data" empty state if no check-ins.
- [ ] AC-13: Workout Volume chart is a bar chart showing daily total volume (sets × reps × weight) over last 4 weeks. Shows "No workout data" empty state if no logs.
- [ ] AC-14: Adherence chart is a stacked bar or heatmap showing daily food logged, workout logged, and protein goal hit over last 4 weeks. Three-color legend.
- [ ] AC-15: All charts are responsive and resize with the container.
- [ ] AC-16: Progress tab shows loading skeleton while chart data loads.
- [ ] AC-17: Progress tab shows error state with retry if data fetch fails.

### Notification Click-Through (AC-18 through AC-21)
- [ ] AC-18: When a notification's `data` field contains a `trainee_id`, clicking the notification navigates to `/trainees/{trainee_id}` in addition to marking it as read.
- [ ] AC-19: When a notification's `data` field does NOT contain a `trainee_id`, clicking the notification only marks it as read (no navigation — same as current behavior).
- [ ] AC-20: Click-through works in both the notification popover (header bell) and the full notifications page.
- [ ] AC-21: Backend notification creation views include `trainee_id` in the `data` JSONField for notification types: `trainee_readiness`, `workout_completed`, `workout_missed`, `goal_hit`, `check_in`.

### Invitation Row Actions (AC-22 through AC-28)
- [ ] AC-22: Each invitation row has a "..." dropdown menu (DropdownMenu) with context-sensitive actions.
- [ ] AC-23: PENDING invitations show actions: "Copy Code", "Resend", "Cancel".
- [ ] AC-24: EXPIRED invitations show actions: "Copy Code", "Resend".
- [ ] AC-25: ACCEPTED and CANCELLED invitations show action: "Copy Code" only.
- [ ] AC-26: "Copy Code" copies `invitation_code` to clipboard and shows success toast.
- [ ] AC-27: "Resend" calls `POST /api/trainer/invitations/<id>/resend/`, shows success toast, and refreshes the table.
- [ ] AC-28: "Cancel" shows a confirmation dialog, then calls `DELETE /api/trainer/invitations/<id>/`, shows success toast, and refreshes the table.

## Edge Cases
1. Settings: Profile save with no changes — should still succeed (PATCH is idempotent).
2. Settings: Upload very large image (>5MB) — backend returns 400, frontend shows "Image must be under 5MB" error.
3. Settings: Upload non-image file — backend returns 400, frontend shows "Only JPEG, PNG, GIF, and WebP are allowed" error.
4. Settings: Change password with wrong current password — Djoser returns 400 with field error, shown inline.
5. Settings: Change password where new password is too common — Djoser returns validation errors, shown inline.
6. Settings: Profile update fails (network) — error toast, form state preserved for retry.
7. Progress: Trainee with zero weight check-ins — weight chart shows "No weight data" empty state.
8. Progress: Trainee with zero workouts — volume chart shows "No workout data" empty state.
9. Progress: Trainee with zero activity summaries — adherence chart shows "No activity data" empty state.
10. Progress: All three charts empty — each shows individual empty state (not one global empty state).
11. Notifications: `data` field is empty object `{}` — no navigation, just marks as read.
12. Notifications: `data.trainee_id` points to a trainee that was removed — navigation leads to trainee detail "not found" error state (existing handling).
13. Invitations: Resend on an invitation that was cancelled between page load and action click — backend returns 400, show error toast.
14. Invitations: Cancel last remaining invitation — table shows empty state after refresh.
15. Invitations: Rapid double-click on resend or cancel — mutation `isPending` disables button.

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Profile save fails | Red error toast "Failed to update profile" | Form state preserved |
| Password change wrong current | Inline error under current password field | Clear password fields |
| Password change validation fail | Inline errors per field | Keep form state |
| Image upload fails | Red error toast "Failed to upload image" | Remove preview |
| Image too large / wrong type | Red error toast with specific message | Nothing changes |
| Progress data fails to load | ErrorState with retry in Progress tab | Each chart independent |
| Invitation resend fails | Red error toast "Failed to resend invitation" | Table unchanged |
| Invitation cancel fails | Red error toast "Failed to cancel invitation" | Table unchanged |
| Notification navigate to deleted trainee | Trainee detail ErrorState "not found" | Existing behavior |

## UX Requirements
- **Loading state (settings):** Skeleton cards for profile and security sections
- **Loading state (progress):** Skeleton rectangles where charts will appear
- **Empty state (progress charts):** Per-chart empty state with relevant icon and message
- **Error state:** ErrorState component with retry (consistent with rest of dashboard)
- **Success feedback:** Toast notifications for all mutations (save, upload, password change, resend, cancel, copy)
- **Theme toggle:** Immediate visual feedback — no page reload needed
- **Mobile behavior:** Settings cards stack vertically. Charts resize responsively. Action dropdown accessible on touch.

## Technical Approach

### Chart Library
Install `recharts` — the most popular React charting library, works natively with Next.js and supports responsive containers.

### Settings Page
**Modify:** `web/src/app/(dashboard)/settings/page.tsx`
- Replace placeholder with three Card sections: Profile, Appearance, Security
- Profile: controlled form with `useAuth()` for initial values, `useUpdateProfile()` mutation
- Appearance: `useTheme()` from `next-themes` with three-option RadioGroup or SegmentedControl
- Security: password change form with Zod validation

**Create:** `web/src/hooks/use-settings.ts`
- `useUpdateProfile()` — `PATCH /api/users/me/` mutation, invalidates `CURRENT_USER` query
- `useUploadProfileImage()` — `POST /api/users/profile-image/` mutation with FormData
- `useDeleteProfileImage()` — `DELETE /api/users/profile-image/` mutation
- `useChangePassword()` — `POST /api/auth/users/set_password/` mutation

**Create:** `web/src/components/settings/profile-section.tsx`
- Name/business name form fields, email read-only, profile image upload/remove

**Create:** `web/src/components/settings/appearance-section.tsx`
- Theme toggle (Light/Dark/System) using `next-themes`

**Create:** `web/src/components/settings/security-section.tsx`
- Password change form with validation

### Progress Charts
**Modify:** `web/src/components/trainees/trainee-progress-tab.tsx`
- Replace placeholder with three chart cards
- Pass `traineeId` prop for data fetching

**Create:** `web/src/hooks/use-progress.ts`
- `useTraineeProgress(id: number)` — `GET /api/trainer/trainees/<id>/progress/`

**Create:** `web/src/types/progress.ts`
- `WeightEntry`, `VolumeEntry`, `AdherenceEntry`, `TraineeProgress`

**Create:** `web/src/components/trainees/progress-charts.tsx`
- `WeightChart`, `VolumeChart`, `AdherenceChart` components using recharts

### Notification Click-Through
**Modify:** `web/src/components/notifications/notification-item.tsx`
- Add `useRouter()` and check `notification.data.trainee_id`
- On click: mark as read + navigate to `/trainees/{trainee_id}` if ID present

**Modify:** `web/src/components/notifications/notification-popover.tsx`
- Pass navigation-aware onClick to NotificationItem

**Modify:** `web/src/app/(dashboard)/notifications/page.tsx`
- Pass navigation-aware onClick to NotificationItem

**Modify (Backend):** `backend/trainer/views.py` and `backend/workouts/survey_views.py`
- Ensure `TrainerNotification.objects.create()` calls include `data={'trainee_id': trainee.id}` for relevant notification types

### Invitation Row Actions
**Modify:** `web/src/components/invitations/invitation-columns.tsx`
- Add actions column with DropdownMenu

**Create:** `web/src/components/invitations/invitation-actions.tsx`
- Action dropdown component with Copy/Resend/Cancel logic

**Modify:** `web/src/hooks/use-invitations.ts`
- Add `useResendInvitation()` and `useCancelInvitation()` mutations

**Add to:** `web/src/lib/constants.ts`
- `invitationDetail: (id: number) => ...`
- `invitationResend: (id: number) => ...`
- `CHANGE_PASSWORD`, `UPDATE_PROFILE`, `PROFILE_IMAGE` endpoints

### Files to Create
- `web/src/hooks/use-settings.ts`
- `web/src/hooks/use-progress.ts`
- `web/src/types/progress.ts`
- `web/src/components/settings/profile-section.tsx`
- `web/src/components/settings/appearance-section.tsx`
- `web/src/components/settings/security-section.tsx`
- `web/src/components/trainees/progress-charts.tsx`
- `web/src/components/invitations/invitation-actions.tsx`

### Files to Modify
- `web/src/app/(dashboard)/settings/page.tsx`
- `web/src/components/trainees/trainee-progress-tab.tsx`
- `web/src/components/notifications/notification-item.tsx`
- `web/src/components/notifications/notification-popover.tsx`
- `web/src/app/(dashboard)/notifications/page.tsx`
- `web/src/components/invitations/invitation-columns.tsx`
- `web/src/hooks/use-invitations.ts`
- `web/src/lib/constants.ts`
- `web/src/types/notification.ts` (if needed for data typing)
- `web/package.json` (add recharts)
- `backend/trainer/views.py` (notification data field)
- `backend/workouts/survey_views.py` (notification data field)

## Out of Scope
- Email change (backend doesn't support it through custom views)
- Notification preferences (enable/disable types) — no backend support yet
- Bulk invitation actions (select multiple, cancel all)
- Program builder on web — separate future pipeline
- Admin dashboard — separate future pipeline
- Trainee nutrition goal editing from web — separate ticket
- Export progress data as CSV/PDF — separate ticket
