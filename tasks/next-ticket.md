# Feature: Trainee Web Portal — Home Dashboard & Program Viewer

## Priority
Critical

## User Story
As a **trainee**, I want to access my fitness dashboard from a web browser so that I can view my assigned program, check today's workout, track my nutrition and weight, and message my trainer — without needing the mobile app.

## Context
All four user roles (Admin, Trainer, Ambassador, Trainee) have web dashboards EXCEPT trainees. Trainees currently have zero standalone web access — only a read-only impersonation view exists at `/trainee-view` (used when trainers impersonate trainees). This is the single biggest product gap. Building a trainee web portal:
- Enables desktop-first users (people who work at computers all day)
- Provides accessibility for users who can't install mobile apps
- Increases engagement by reducing friction (log from anywhere)
- Completes the platform (every role has web access)

## Scope (Pipeline 32 — Phase 1 of Trainee Web Portal)
This ticket covers the **foundation + home dashboard + program viewer**. Active workout logging, nutrition logging, and community features will follow in subsequent pipelines.

### What's IN scope:
1. Auth system updates (allow TRAINEE login on web)
2. Trainee dashboard layout (sidebar, header, responsive)
3. Home page (today's workout, nutrition summary, weight, weekly progress)
4. Program viewer (assigned programs, weekly schedule, exercise details)
5. Messaging (reuse existing messaging infrastructure)
6. Settings (profile, password change, theme toggle)
7. Announcements viewer (read-only)
8. Achievements viewer (badge grid)

### What's OUT of scope (future pipelines):
- Active workout logging (sets/reps tracking during workout)
- Nutrition food logging (food search + AI parsing)
- Community feed (posts, reactions, comments)
- Feature requests
- Leaderboard
- Calendar integration
- Weight check-in form (view-only for now)

## Acceptance Criteria

### Auth & Routing
- [ ] AC-1: Trainee can log in at `/login` with email + password and is routed to `/trainee/dashboard`
- [ ] AC-2: Middleware routes TRAINEE role to `/trainee/*` paths (separate from `/trainee-view` impersonation)
- [ ] AC-3: Non-trainee users cannot access `/trainee/*` paths (redirect to their appropriate dashboard)
- [ ] AC-4: Trainee cannot access `/dashboard/*`, `/admin/*`, `/ambassador/*` paths
- [ ] AC-5: Auth provider allows TRAINEE role for standalone login (not just impersonation)

### Layout & Navigation
- [ ] AC-6: Trainee dashboard has a sidebar with navigation: Dashboard, My Program, Messages, Announcements, Achievements, Settings
- [ ] AC-7: Sidebar is fixed 256px on desktop, sheet drawer on mobile (matching trainer dashboard pattern)
- [ ] AC-8: Header shows trainee name, profile image placeholder, and logout button
- [ ] AC-9: Unread message count badge appears on Messages nav link
- [ ] AC-10: Unread announcement count badge appears on Announcements nav link
- [ ] AC-11: Layout is fully responsive (sidebar collapses to hamburger on < lg breakpoint)

### Home Dashboard
- [ ] AC-12: Dashboard shows 4 stat cards: Today's Workout (exercise count), Nutrition (calories consumed/goal), Weight (latest check-in), Weekly Progress (X/Y days completed)
- [ ] AC-13: "Today's Workout" card shows the program name + list of exercises for today (day name, exercise names with sets/reps). If no workout today, show "Rest Day" message. If no program assigned, show "No program assigned" empty state.
- [ ] AC-14: "Nutrition Summary" card shows 4 macro progress bars (calories, protein, carbs, fat) with consumed/goal values. If no nutrition data for today, shows goal with 0 consumed.
- [ ] AC-15: "Weight Trend" card shows latest weight check-in value + date, and a small trend indicator (up/down arrow + change from previous). If no check-ins, show "No weight data yet" empty state.
- [ ] AC-16: "Weekly Progress" card shows animated progress bar (X of Y training days completed this week). Percentage + fraction label.
- [ ] AC-17: All 4 cards have skeleton loading states while data fetches
- [ ] AC-18: All 4 cards have error states with retry buttons
- [ ] AC-19: Dashboard shows trainer branding (colors) if configured

### Program Viewer
- [ ] AC-20: "My Program" page shows the trainee's active program with name, description, difficulty badge, goal badge, and duration
- [ ] AC-21: Program schedule renders as a tabbed week view (Week 1, Week 2, etc.) with 7 days per week
- [ ] AC-22: Each day shows day name (Monday, Tuesday, etc.), a custom label if set (e.g., "Push Day"), and a list of exercises
- [ ] AC-23: Each exercise shows: name, sets, reps, weight + unit, rest seconds. Rows are numbered.
- [ ] AC-24: Rest days are clearly marked with a "Rest Day" badge and dimmed/muted styling
- [ ] AC-25: If trainee has no active program, show "No program assigned" empty state with helpful message
- [ ] AC-26: If trainee has multiple programs, show the active one with a program switcher (dropdown or tabs)
- [ ] AC-27: Program viewer is read-only (no editing capability)

### Messaging
- [ ] AC-28: Messages page reuses the existing split-panel messaging UI from the trainer dashboard
- [ ] AC-29: Trainee sees only their conversation with their trainer
- [ ] AC-30: Trainee can send text messages and image attachments
- [ ] AC-31: Real-time updates via WebSocket (typing indicators, read receipts, new messages)
- [ ] AC-32: Message search works (Cmd/Ctrl+K)

### Announcements
- [ ] AC-33: Announcements page shows a list of trainer announcements with title, content, date, pinned indicator
- [ ] AC-34: Pinned announcements appear first, then sorted by date descending
- [ ] AC-35: Unread announcements have visual distinction (bold title or unread dot)
- [ ] AC-36: Opening an announcement marks it as read (POST mark-read)
- [ ] AC-37: "Mark all as read" button in page header

### Achievements
- [ ] AC-38: Achievements page shows a grid of all achievements with earned/locked visual states
- [ ] AC-39: Earned achievements show the badge icon, name, earned date, and description
- [ ] AC-40: Locked achievements show a grayed-out/muted version with progress toward unlocking (e.g., "3/5 workouts")
- [ ] AC-41: Summary at top: "X of Y achievements earned"

### Settings
- [ ] AC-42: Settings page with Profile section (name edit, profile image upload/remove)
- [ ] AC-43: Settings page with Appearance section (Light/Dark/System theme toggle)
- [ ] AC-44: Settings page with Security section (password change with current + new + confirm fields)
- [ ] AC-45: Profile changes save immediately with success toast
- [ ] AC-46: Password change validates: current password required, new password min 8 chars, confirm must match

## Edge Cases
1. **Trainee with no trainer**: Should never happen (FK constraint), but if somehow orphaned, show "Contact support" message instead of empty data
2. **Trainee with expired subscription**: Still allow login and viewing, but show a banner "Your subscription has expired. Contact your trainer."
3. **Trainee not onboarded**: If `onboarding_completed` is false, redirect to a simple onboarding prompt or show partial dashboard with "Complete your profile" CTA
4. **Multiple active programs**: Show program switcher. Default to the most recently assigned active program.
5. **Program with 0 exercises on a day**: Show the day with "No exercises" message (not a rest day — rest days are explicitly marked)
6. **Program with 52 weeks**: Week tabs should be horizontally scrollable (don't overflow)
7. **Weight in kg vs lbs**: Display weight in the unit recorded. Show conversion only if both exist.
8. **Network failure mid-page**: Each card independently handles errors — one card failing doesn't crash the others
9. **Concurrent sessions (mobile + web)**: JWT tokens work independently — both sessions can be active
10. **Trainer impersonation while trainee is logged in**: Both sessions are independent (different JWTs)

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| API call fails (network) | Card shows error icon + "Failed to load" + Retry button | Logs error, shows toast |
| 401 Unauthorized | Redirect to login page | Clear tokens, redirect |
| No program assigned | "No program assigned yet" empty state with trainer icon | Show empty state |
| No nutrition data today | Macro bars at 0, goal values shown | Normal render with zeros |
| No weight check-ins | "No weight data yet" with scale icon | Show empty state |
| No announcements | "No announcements yet" with megaphone icon | Show empty state |
| No achievements earned | All badges shown as locked | Show full grid, all locked |
| Message send fails | Toast "Failed to send message" + message stays in input | Error toast, preserve draft |

## UX Requirements
- **Loading state:** Skeleton placeholders matching content shape for every card/section (per existing pattern)
- **Empty state:** Contextual icon + title + description for each empty state (per existing EmptyState component)
- **Error state:** Error icon + message + Retry button (per existing ErrorState component)
- **Success feedback:** Toast notifications for profile save, password change, mark-all-read
- **Mobile behavior:** Sidebar collapses to hamburger menu. Cards stack vertically. Program tabs scroll horizontally.
- **Dark mode:** Full dark mode support via existing CSS variables + next-themes
- **Accessibility:** ARIA labels on all nav links, skip-to-content link, keyboard navigation for program tabs, semantic HTML (nav, main, article, section), focus-visible rings on all interactive elements
- **Branding:** Trainee sees their trainer's branding colors (primary/secondary) if configured

## Technical Approach

### New Files to Create
| File | Purpose |
|------|---------|
| `web/src/app/(trainee-dashboard)/layout.tsx` | Trainee dashboard layout with sidebar + header |
| `web/src/app/(trainee-dashboard)/dashboard/page.tsx` | Home dashboard page |
| `web/src/app/(trainee-dashboard)/program/page.tsx` | Program viewer page |
| `web/src/app/(trainee-dashboard)/messages/page.tsx` | Messages page (wraps existing messaging components) |
| `web/src/app/(trainee-dashboard)/announcements/page.tsx` | Announcements page |
| `web/src/app/(trainee-dashboard)/achievements/page.tsx` | Achievements page |
| `web/src/app/(trainee-dashboard)/settings/page.tsx` | Settings page |
| `web/src/components/trainee-dashboard/trainee-sidebar.tsx` | Sidebar navigation |
| `web/src/components/trainee-dashboard/trainee-nav-links.tsx` | Nav link definitions |
| `web/src/components/trainee-dashboard/dashboard-stats.tsx` | 4-stat cards component |
| `web/src/components/trainee-dashboard/todays-workout-card.tsx` | Today's workout card |
| `web/src/components/trainee-dashboard/nutrition-summary-card.tsx` | Nutrition card with macro bars |
| `web/src/components/trainee-dashboard/weight-trend-card.tsx` | Weight trend card |
| `web/src/components/trainee-dashboard/weekly-progress-card.tsx` | Weekly progress card |
| `web/src/components/trainee-dashboard/program-viewer.tsx` | Full program schedule viewer |
| `web/src/components/trainee-dashboard/announcements-list.tsx` | Announcements list component |
| `web/src/components/trainee-dashboard/achievements-grid.tsx` | Achievement badge grid |
| `web/src/hooks/use-trainee-dashboard.ts` | Hooks for trainee dashboard data |
| `web/src/hooks/use-trainee-announcements.ts` | Hooks for announcements |
| `web/src/hooks/use-trainee-achievements.ts` | Hooks for achievements |
| `web/src/types/trainee-dashboard.ts` | TypeScript types for trainee dashboard |

### Files to Modify
| File | Change |
|------|--------|
| `web/src/middleware.ts` | Add `/trainee/*` routing for TRAINEE role |
| `web/src/providers/auth-provider.tsx` | Allow standalone TRAINEE login (not just impersonation) |
| `web/src/lib/constants.ts` | Add trainee dashboard API URL constants |

### Existing Components to Reuse
| Component | From | Usage |
|-----------|------|-------|
| `Sidebar` pattern | `components/layout/sidebar.tsx` | Clone for trainee sidebar |
| `Header` pattern | `components/layout/header.tsx` | Clone for trainee header |
| Messages components | `app/(dashboard)/messages/` | Reuse messaging components |
| `ErrorState` | `components/shared/error-state.tsx` | All error states |
| `EmptyState` | `components/shared/empty-state.tsx` | All empty states |
| `Skeleton` | `components/ui/skeleton.tsx` | All loading states |
| `Badge` | `components/ui/badge.tsx` | Difficulty, goal badges |
| `Card` | `components/ui/card.tsx` | Dashboard cards |
| `Progress` | `components/ui/progress.tsx` | Macro bars, weekly progress |
| Settings components | `app/(dashboard)/settings/page.tsx` | Reuse profile/appearance/security sections |

### API Endpoints Used (all existing, no backend changes)
| Endpoint | Purpose |
|----------|---------|
| `GET /api/workouts/programs/` | List trainee's programs |
| `GET /api/workouts/daily-logs/nutrition-summary/?date=` | Today's nutrition |
| `GET /api/workouts/daily-logs/weekly-progress/` | Weekly completion |
| `GET /api/workouts/weight-checkins/` | Weight history |
| `GET /api/workouts/weight-checkins/latest/` | Latest weight |
| `GET /api/community/announcements/` | Trainer announcements |
| `GET /api/community/announcements/unread-count/` | Unread count |
| `POST /api/community/announcements/mark-read/` | Mark read |
| `GET /api/community/achievements/` | All achievements |
| `GET /api/messaging/conversations/` | Conversations |
| `GET /api/messaging/unread-count/` | Unread messages |
| `GET /api/auth/users/me/` | Current user |
| `PATCH /api/auth/users/me/` | Update profile |
| `POST /api/auth/users/set_password/` | Change password |

### Key Design Decisions
1. **Separate route group** `(trainee-dashboard)` — not sharing with `(dashboard)` to keep trainer/trainee concerns separated
2. **No backend changes** — all endpoints already exist and have proper trainee permissions
3. **Reuse messaging infrastructure** — same WebSocket, same components, just different layout wrapper
4. **Program viewer is read-only** — trainee sees schedule but can't edit (editing is trainer-only)
5. **Settings reuse** — clone the trainer settings page structure, remove trainer-specific sections (business name, subscription)

## Out of Scope
- Active workout logging (tracking sets/reps during a workout session)
- Nutrition food logging (adding meals, AI parsing)
- Community feed (posts, reactions, comments)
- Feature request board
- Leaderboard
- Calendar integration
- Weight check-in entry form
- Onboarding wizard on web
- Stripe subscription management UI
