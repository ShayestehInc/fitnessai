# Dev Done: Trainee Web Portal — Home Dashboard & Program Viewer

## Date
2026-02-21

## Files Changed

### Web — New Files (Components)
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx` — Nav link definitions for trainee sidebar (6 links with badge keys)
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` — Sidebar navigation with unread badges for messages and announcements
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` — Mobile sheet drawer sidebar (matching trainer pattern)
- `web/src/components/trainee-dashboard/trainee-header.tsx` — Header with hamburger menu and user nav
- `web/src/components/trainee-dashboard/todays-workout-card.tsx` — Today's workout card with rest day handling, exercise list
- `web/src/components/trainee-dashboard/nutrition-summary-card.tsx` — Macro progress bars (calories, protein, carbs, fat)
- `web/src/components/trainee-dashboard/weight-trend-card.tsx` — Latest weight with trend indicator (up/down arrow, kg/lbs)
- `web/src/components/trainee-dashboard/weekly-progress-card.tsx` — Weekly progress bar with percentage
- `web/src/components/trainee-dashboard/program-viewer.tsx` — Full program schedule viewer with tabbed week view, day cards, exercise details, program switcher
- `web/src/components/trainee-dashboard/announcements-list.tsx` — Announcements list with pinned sorting, date badges
- `web/src/components/trainee-dashboard/achievements-grid.tsx` — Achievement badge grid with earned/locked states, progress bars
- `web/src/components/ui/progress.tsx` — Shared Progress bar component (was missing from UI library)

### Web — New Files (Pages)
- `web/src/app/(trainee-dashboard)/layout.tsx` — Trainee dashboard layout with role guard, sidebar, header
- `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx` — Home dashboard with 4 stat cards
- `web/src/app/(trainee-dashboard)/trainee/program/page.tsx` — Program viewer page
- `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx` — Messages page (reusing existing messaging components)
- `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx` — Announcements page with mark-all-read
- `web/src/app/(trainee-dashboard)/trainee/achievements/page.tsx` — Achievements page with summary stats
- `web/src/app/(trainee-dashboard)/trainee/settings/page.tsx` — Settings page (reusing ProfileSection, AppearanceSection, SecuritySection)

### Web — New Files (Hooks & Types)
- `web/src/hooks/use-trainee-dashboard.ts` — React Query hooks for dashboard data (programs, nutrition, weight, weekly progress)
- `web/src/hooks/use-trainee-announcements.ts` — Hooks for announcements (list, unread count, mark read mutation)
- `web/src/hooks/use-trainee-achievements.ts` — Hook for achievements list
- `web/src/types/trainee-dashboard.ts` — TypeScript types (WeeklyProgress, LatestWeightCheckIn, Announcement, Achievement, WorkoutSummary)

### Web — Modified Files
- `web/src/middleware.ts` — Added `isTraineeDashboardPath()` for `/trainee/*` routing; TRAINEE role now routes to `/trainee/dashboard` instead of `/trainee-view`; added non-trainee guard for `/trainee/*` paths
- `web/src/providers/auth-provider.tsx` — Removed TRAINEE role rejection; now allows standalone TRAINEE login (not just impersonation)
- `web/src/lib/constants.ts` — Added 8 trainee API URL constants (weight latest, weekly progress, workout summary, announcements, achievements, branding)
- `web/src/components/layout/user-nav.tsx` — Settings link now routes to `/trainee/settings` for TRAINEE role
- `web/src/app/(dashboard)/layout.tsx` — TRAINEE redirect updated from `/trainee-view` to `/trainee/dashboard`

## Key Decisions
1. **Separate route group `(trainee-dashboard)`** — Keeps trainee concerns isolated from trainer/admin/ambassador dashboards
2. **No backend changes** — All trainee-facing API endpoints already exist with proper permissions
3. **Reuse existing components** — Messaging (ConversationList, ChatView, MessageSearch), Settings (ProfileSection, AppearanceSection, SecuritySection), Layout (UserNav, shared UI components)
4. **New Progress UI component** — Created `web/src/components/ui/progress.tsx` since it was missing from the shadcn/ui setup
5. **Impersonation preserved** — `/trainee-view` route still works for trainer impersonation; the new `/trainee/*` routes are for standalone trainee login
6. **Program viewer is read-only** — Trainee can view schedule but cannot edit

## How to Test
1. Log in as a trainee user at `/login` — should redirect to `/trainee/dashboard`
2. Dashboard: verify 4 cards load (Today's Workout, Nutrition, Weight, Weekly Progress)
3. My Program: verify program schedule displays with week tabs and exercise details
4. Messages: verify messaging works (send/receive, WebSocket, search)
5. Announcements: verify list loads, mark-all-read works
6. Achievements: verify grid shows earned/locked states
7. Settings: verify profile edit, theme toggle, password change work
8. Navigation: verify sidebar links, unread badges, responsive hamburger menu
9. Auth: verify non-trainee users can't access `/trainee/*` paths
10. TypeScript: `npx tsc --noEmit` passes with zero errors
