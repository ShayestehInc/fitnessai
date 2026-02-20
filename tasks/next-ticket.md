# Feature: Full Trainer→Trainee Impersonation Token Swap (Web Dashboard)

## Priority
High

## User Story
As a **trainer**, I want to **click "View as Trainee" and actually see my trainee's data as they would see it** so that I can **verify program assignments, debug trainee-reported issues, and understand my trainee's experience**.

## Acceptance Criteria

### Token Swap (ImpersonateTraineeButton)
- [ ] AC-1: Clicking "Start Impersonation" saves the trainer's current access + refresh tokens to sessionStorage (key: `fitnessai_trainer_impersonation`)
- [ ] AC-2: Trainee JWT tokens from the API response are set via `setTokens(access, refresh)`
- [ ] AC-3: Role cookie is set to `TRAINEE`
- [ ] AC-4: The trainee ID and name are saved to sessionStorage alongside the trainer tokens (needed for the banner display and return navigation)
- [ ] AC-5: After token swap, the page hard-navigates to `/trainee-view` (not `router.push` — hard navigate to clear React Query cache)
- [ ] AC-6: If the API call fails, the trainer stays on their current page (existing error toast behavior)

### Trainer Impersonation Banner
- [ ] AC-7: New `TrainerImpersonationBanner` component displayed at the top of the trainee view layout
- [ ] AC-8: Banner shows "Viewing as {traineeName}" with a warning icon, matching the admin impersonation banner style (amber background)
- [ ] AC-9: "End Impersonation" button calls `POST /api/trainer/impersonate/end/`, restores trainer tokens from sessionStorage, sets role cookie back to `TRAINER`, clears impersonation state
- [ ] AC-10: After ending impersonation, hard-navigates back to `/trainees/{traineeId}` (the trainee detail page the trainer came from)
- [ ] AC-11: If the end-impersonation API call fails, tokens are still restored and the trainer is redirected (same pattern as admin banner)

### Trainee View Page
- [ ] AC-12: New `(trainee-view)` route group at `/trainee-view` with a minimal layout (impersonation banner + content, no sidebar)
- [ ] AC-13: The page shows 4 read-only sections: Profile Summary, Active Program, Today's Nutrition, Recent Weight
- [ ] AC-14: **Profile Summary card** — trainee name, email, and goals from `/api/auth/users/me/` and `/api/users/me/`
- [ ] AC-15: **Active Program card** — current program name, today's scheduled exercises from `/api/workouts/programs/`
- [ ] AC-16: **Today's Nutrition card** — today's logged macros vs targets from `/api/workouts/daily-logs/` (filtered to today) and `/api/workouts/nutrition-goals/`
- [ ] AC-17: **Recent Weight card** — last 5 weight check-ins from `/api/workouts/weight-checkins/`
- [ ] AC-18: All sections have loading skeletons, empty states, and error handling
- [ ] AC-19: Page title: "Trainee View — {traineeName}"
- [ ] AC-20: A subtle "Read-Only" badge or indicator to remind the trainer this is view-only

### Middleware
- [ ] AC-21: Middleware routes users with `TRAINEE` role cookie to `/trainee-view` when they try to access trainer/admin/ambassador paths
- [ ] AC-22: Users with `TRAINEE` role cookie accessing `/login` while authenticated are redirected to `/trainee-view`

### Hooks & Types
- [ ] AC-23: New hooks in a `use-trainee-view.ts` file for the trainee-facing API calls (programs, daily logs, nutrition goals, weight check-ins)
- [ ] AC-24: Reuse existing types where possible (`Program`, `DailyLog`, `NutritionGoal`, `WeightCheckIn`)

## Edge Cases
1. **Trainer has no trainees** — Impersonate button is only shown on the trainee detail page, which requires a trainee. Not an issue.
2. **Trainee token expires during impersonation** — Token refresh uses the trainee's refresh token, which should work. If it fails, the trainer is logged out and must log back in as themselves.
3. **Trainer closes browser during impersonation** — sessionStorage is cleared. On next visit, trainer logs in normally with their own credentials. The impersonation session record remains in the backend audit log.
4. **Trainee has no program assigned** — Active Program card shows "No program assigned" empty state.
5. **Trainee has no daily log for today** — Nutrition card shows "No data logged today" empty state.
6. **Trainee has no weight check-ins** — Weight card shows "No weight data" empty state.
7. **Rapid impersonate/end cycles** — sessionStorage is cleared on end, so starting a new impersonation always starts fresh.
8. **Network failure during end-impersonation** — Trainer tokens are still restored from sessionStorage even if the API call fails.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Impersonation API fails | Toast error on trainee detail page | Trainer stays on current page |
| End-impersonation API fails | Toast warning, still redirects | Restores trainer tokens, navigates back |
| Trainee-facing API fails | Error state per card with retry | Individual card-level error handling |
| Token refresh fails | Redirect to login | clearTokens() + redirect |
| No impersonation state in sessionStorage | Redirect to trainer dashboard | Guard in layout detects missing state |

## UX Requirements
- **Impersonation banner:** Fixed at top, amber background, matches admin impersonation banner styling
- **Trainee view layout:** Minimal — no sidebar, just banner + centered content with max-width
- **Loading state:** Skeleton cards for each section
- **Empty state:** Contextual message per card (e.g., "No program assigned")
- **Error state:** ErrorState with retry per card
- **Read-only indicator:** Badge in the page header or banner text
- **Mobile behavior:** Responsive grid — 1 column on mobile, 2 columns on desktop
- **Transition:** Hard navigate (window.location.href) for both start and end to clear stale cache

## Technical Approach

### Web — Token Swap
- **Modify:** `web/src/components/trainees/impersonate-trainee-button.tsx` — Replace the `onSuccess` handler to save trainer tokens, swap to trainee tokens, set role cookie, navigate to `/trainee-view`
- **Pattern:** Follow `web/src/components/layout/impersonation-banner.tsx` (admin impersonation) — same sessionStorage pattern with a different key (`fitnessai_trainer_impersonation`)

### Web — Banner
- **New file:** `web/src/components/layout/trainer-impersonation-banner.tsx` — Clone of `impersonation-banner.tsx` adapted for trainer→trainee: different sessionStorage key, calls `TRAINER_IMPERSONATE_END` instead of `ADMIN_IMPERSONATE_END`, restores `TRAINER` role, navigates to `/trainees/{id}`

### Web — Trainee View
- **New file:** `web/src/app/(trainee-view)/layout.tsx` — Minimal layout with `TrainerImpersonationBanner` + centered content
- **New file:** `web/src/app/(trainee-view)/trainee-view/page.tsx` — Read-only trainee dashboard with 4 data cards
- **New file:** `web/src/hooks/use-trainee-view.ts` — Hooks for trainee-facing APIs
- **New file:** `web/src/components/trainee-view/profile-card.tsx` — Profile summary
- **New file:** `web/src/components/trainee-view/program-card.tsx` — Active program display
- **New file:** `web/src/components/trainee-view/nutrition-card.tsx` — Today's nutrition vs targets
- **New file:** `web/src/components/trainee-view/weight-card.tsx` — Recent weight check-ins

### Web — Middleware
- **Modify:** `web/src/middleware.ts` — Add TRAINEE routing to `/trainee-view`

## Out of Scope
- Full trainee web experience (workout logging, food logging, etc.)
- Write/edit capabilities in the trainee view
- Admin→trainee impersonation (admin only impersonates trainers)
- Mobile impersonation changes
- New backend endpoints
