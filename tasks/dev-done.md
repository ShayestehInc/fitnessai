# Dev Done: Web Dashboard Phase 2 — Settings, Progress Charts, Actionable Notifications & Invitations

## Date
2026-02-15

## Summary
Implemented four features that replace placeholder/dead UI surfaces in the web trainer dashboard with fully functional production-ready components: Settings page (profile, appearance, security), trainee progress charts, notification click-through navigation, and invitation row actions.

## Files Created
| File | Purpose |
|------|---------|
| `web/src/types/progress.ts` | TypeScript types for trainee progress API response |
| `web/src/hooks/use-progress.ts` | React Query hook for fetching trainee progress data |
| `web/src/hooks/use-settings.ts` | Mutation hooks for profile update, image upload/delete, password change |
| `web/src/components/settings/profile-section.tsx` | Profile form with name, email (read-only), image upload/remove |
| `web/src/components/settings/appearance-section.tsx` | Theme toggle (Light/Dark/System) using next-themes |
| `web/src/components/settings/security-section.tsx` | Password change form with validation and Djoser error handling |
| `web/src/components/trainees/progress-charts.tsx` | Three chart components: WeightChart (line), VolumeChart (bar), AdherenceChart (stacked bar) |
| `web/src/components/invitations/invitation-actions.tsx` | Dropdown menu with Copy Code, Resend, Cancel actions + confirmation dialog |

## Files Modified
| File | Changes |
|------|---------|
| `web/src/lib/constants.ts` | Added API endpoints for profile, image, password, progress, invitation actions |
| `web/src/lib/api-client.ts` | Added `postFormData()` method; fixed Content-Type header to skip for FormData |
| `web/src/hooks/use-invitations.ts` | Added `useResendInvitation()` and `useCancelInvitation()` mutations |
| `web/src/app/(dashboard)/settings/page.tsx` | Replaced placeholder with ProfileSection + AppearanceSection + SecuritySection |
| `web/src/components/trainees/trainee-progress-tab.tsx` | Replaced placeholder with chart components; now accepts `traineeId` prop |
| `web/src/app/(dashboard)/trainees/[id]/page.tsx` | Passes `trainee.id` to `TraineeProgressTab` |
| `web/src/components/notifications/notification-item.tsx` | Added `getNotificationTraineeId()` helper; ChevronRight visual indicator for navigable notifications |
| `web/src/components/notifications/notification-popover.tsx` | Added click-through navigation to trainee detail; accepts `onClose` prop for popover dismissal |
| `web/src/components/notifications/notification-bell.tsx` | Controlled Popover state to support closing on navigation |
| `web/src/app/(dashboard)/notifications/page.tsx` | Added click-through navigation via `useRouter` when `trainee_id` exists in notification data |
| `web/src/components/invitations/invitation-columns.tsx` | Added actions column with `InvitationActions` component |

## Dependencies Added
| Package | Version | Purpose |
|---------|---------|---------|
| `recharts` | ^2.15.3 | Chart library for progress visualization |

## Key Decisions
1. **recharts over chart.js** — Most popular React charting library, tree-shakeable, works with Next.js SSR without configuration.
2. **Controlled Popover for notification bell** — Needed to programmatically close the popover when navigating from a notification click.
3. **`getNotificationTraineeId()` as exported helper** — Shared between notification-item (visual indicator) and parent components (navigation logic). Handles both number and string `trainee_id` values from the API.
4. **FormData Content-Type fix in api-client** — Modified `buildHeaders()` to skip `Content-Type: application/json` when body is FormData, letting the browser set the correct `multipart/form-data` boundary.
5. **Djoser password endpoint** — Used `POST /api/auth/users/set_password/` which requires `current_password` + `new_password` fields. Error responses parsed for inline field errors.
6. **No backend changes** — All required backend APIs already exist. Notification `trainee_id` is already sent in the `data` field by `survey_views.py`.

## Deviations from Ticket
- None. All 28 acceptance criteria addressed.

## How to Test
1. **Settings Page** (`/settings`):
   - Edit first name, last name, business name → save → verify toast + values persist on reload
   - Upload profile image (valid JPEG/PNG) → verify preview updates
   - Upload invalid file (>5MB or wrong type) → verify error toast
   - Remove profile image → verify placeholder returns
   - Toggle theme (Light/Dark/System) → verify colors change immediately
   - Change password with correct current password → verify success toast, fields clear
   - Change password with wrong current password → verify inline error
   - Submit with password mismatch → verify inline error

2. **Progress Charts** (`/trainees/{id}` → Progress tab):
   - View weight trend line chart with proper axis labels
   - View volume bar chart
   - View adherence stacked bar chart with Food/Workout/Protein legend
   - Test with trainee that has no data → verify empty states with icons

3. **Notification Click-Through** (`/notifications` and bell popover):
   - Click notification with `trainee_id` → navigates to `/trainees/{id}`
   - Click notification without `trainee_id` → marks as read, no navigation
   - Verify ChevronRight icon appears only on navigable notifications
   - Verify popover closes after navigation click

4. **Invitation Actions** (`/invitations`):
   - Click three-dot menu → verify Copy Code, Resend, Cancel options appear
   - Copy Code → verify clipboard toast
   - Resend → verify success/error toast
   - Cancel → verify confirmation dialog appears
   - Confirm cancel → verify invitation status updates
   - Verify ACCEPTED invitations don't show Resend/Cancel options

## Build & Lint Status
- `npm run build` — Compiled successfully, 0 errors
- `npm run lint` — 0 errors, 0 warnings
- Backend tests — Not runnable (no venv available, no backend changes made)
