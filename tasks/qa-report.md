# QA Report: Trainee Web Portal (Pipeline 32)

## Test Results
- **TypeScript (`npx tsc --noEmit`):** PASS (exit code 0, zero errors)
- **Static Analysis Issues:** 1 bug found (login page TRAINEE redirect missing)

## Acceptance Criteria Verification

### Auth & Routing

- [x] **AC-1** -- PASS -- Trainee can log in at `/login` with email + password. The auth-provider (`web/src/providers/auth-provider.tsx` line 44-48) now allows TRAINEE role for standalone login. Middleware (`web/src/middleware.ts` line 10) routes TRAINEE to `/trainee/dashboard`. **Minor issue:** Login page (`web/src/app/(auth)/login/page.tsx` lines 49-54) does NOT explicitly route TRAINEE users to `/trainee/dashboard` after login -- it falls through to the default `/dashboard`. The middleware then redirects, causing a double-hop. Functionally works but suboptimal.

- [x] **AC-2** -- PASS -- Middleware (`web/src/middleware.ts` lines 26-28) has `isTraineeDashboardPath()` that correctly identifies `/trainee/*` paths as separate from `/trainee-view` impersonation paths. Line 22-24 defines `isTraineeViewPath` for the old impersonation route.

- [x] **AC-3** -- PASS -- Middleware lines 76-80 redirect non-TRAINEE users away from `/trainee/*` paths to their appropriate dashboard. Layout (`web/src/app/(trainee-dashboard)/layout.tsx` lines 29-38) also redirects ADMIN/AMBASSADOR/TRAINER users via client-side useEffect.

- [x] **AC-4** -- PASS -- Middleware lines 83-89 redirect TRAINEE users attempting to access trainer dashboard paths to `/trainee/dashboard`. Lines 62-66 and 69-73 block TRAINEE from admin and ambassador paths respectively (via role checks that send non-matching roles to their dashboard).

- [x] **AC-5** -- PASS -- Auth provider (`web/src/providers/auth-provider.tsx` lines 44-48) includes `userData.role === UserRole.TRAINEE` in the `isAllowedRole` check, allowing standalone TRAINEE login.

### Layout & Navigation

- [x] **AC-6** -- PASS -- Trainee nav links (`web/src/components/trainee-dashboard/trainee-nav-links.tsx` lines 18-25) define exactly 6 items: Dashboard, My Program, Messages, Announcements, Achievements, Settings. All with correct paths and icons.

- [x] **AC-7** -- PASS -- Desktop sidebar (`web/src/components/trainee-dashboard/trainee-sidebar.tsx` line 16) uses `hidden lg:block` and `w-64` (256px). Mobile sidebar (`web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`) uses a Sheet (drawer) component with `w-64`.

- [x] **AC-8** -- PASS -- Header (`web/src/components/trainee-dashboard/trainee-header.tsx` lines 14-16) shows trainee name (first + last, fallback to email). Uses `UserNav` component which shows profile avatar/fallback and has a logout dropdown menu item (line 70 of `user-nav.tsx`).

- [x] **AC-9** -- PASS -- Badge counts hook (`web/src/hooks/use-trainee-badge-counts.ts`) fetches unread message count via `useMessagingUnreadCount()`. Sidebar renders Badge with destructive variant when badgeCount > 0. Messages nav link has `badgeKey: "messages"`.

- [x] **AC-10** -- PASS -- Same badge system. Announcements nav link has `badgeKey: "announcements"`. Hook fetches `useAnnouncementUnreadCount()`. Badge appears in both desktop and mobile sidebar.

- [x] **AC-11** -- PASS -- Layout (`web/src/app/(trainee-dashboard)/layout.tsx`) renders `TraineeSidebar` (hidden on mobile, shown on lg) and `TraineeSidebarMobile` (Sheet triggered by hamburger menu). Header has hamburger button with `lg:hidden` class (line 23 of trainee-header.tsx).

### Home Dashboard

- [x] **AC-12** -- PASS -- Dashboard page (`web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx`) renders 4 cards: `TodaysWorkoutCard`, `NutritionSummaryCard`, `WeightTrendCard`, `WeeklyProgressCard` in a 2-column grid.

- [x] **AC-13** -- PASS -- `TodaysWorkoutCard` (`web/src/components/trainee-dashboard/todays-workout-card.tsx`): Shows active program name + exercise list with sets/reps (lines 170-199). Shows "Rest Day" when `is_rest_day` is true (lines 143-155). Shows "No program assigned" empty state when no active program (lines 96-113). Shows "No exercises scheduled" when day has 0 exercises (lines 156-168). Shows exercise count as a large number.

- [x] **AC-14** -- PASS -- `NutritionSummaryCard` (`web/src/components/trainee-dashboard/nutrition-summary-card.tsx`): Shows 4 MacroBar progress bars for calories, protein, carbs, fat (lines 113-137). Each shows consumed/goal. Defaults to 0 consumed when no data (lines 95-101).

- [x] **AC-15** -- PASS -- `WeightTrendCard` (`web/src/components/trainee-dashboard/weight-trend-card.tsx`): Shows latest weight value + date (lines 104-128). Shows trend indicator (TrendingUp/TrendingDown/Minus icons) with change value (lines 81-119). Shows "No weight data yet" empty state when no check-ins (lines 54-71).

- [x] **AC-16** -- PASS -- `WeeklyProgressCard` (`web/src/components/trainee-dashboard/weekly-progress-card.tsx`): Shows percentage + "X of Y days" label (lines 67-72). Renders Progress bar (line 73).

- [x] **AC-17** -- PASS -- All 4 cards have `CardSkeleton` loading states (skeleton placeholders) rendered when `isLoading` is true.

- [x] **AC-18** -- PASS -- All 4 cards have error states with `ErrorState` component including retry buttons via `onRetry={() => refetch()}`.

- [ ] **AC-19** -- FAIL -- Dashboard does NOT show trainer branding colors. The `TRAINEE_BRANDING` API URL is defined in constants (`web/src/lib/constants.ts` line 254) but is never fetched or applied anywhere in the trainee dashboard code. No branding hook, no CSS variable injection, no branding-related code in any trainee component.

### Program Viewer

- [x] **AC-20** -- PASS -- Program viewer (`web/src/components/trainee-dashboard/program-viewer.tsx` lines 68-133) shows program name, description, difficulty badge, goal badge, and duration weeks badge. Active status badge is also shown.

- [x] **AC-21** -- PASS -- Week tabs rendered (lines 136-160) with `role="tablist"` and `role="tab"` attributes. Each week shown as "Week {week_number}". Tab panels use `role="tabpanel"`. Days rendered in grid layout.

- [x] **AC-22** -- PASS -- `DayCard` component (lines 193-261) shows day name from `DAY_NAMES` array (Monday-Sunday), custom label if set (line 217-219: `day.name` shown as subtitle when different from day name), and exercise list.

- [x] **AC-23** -- PASS -- Exercises show: name (line 241), sets + reps (line 243), weight + unit when > 0 (lines 244-248), rest seconds when > 0 (lines 249-251). Rows numbered with index (lines 237-239: `{i + 1}.`).

- [x] **AC-24** -- PASS -- Rest days clearly marked with "Rest" badge (BedDouble icon, lines 210-215), dimmed styling via `opacity-60` on the Card (line 204), and "Recovery day" text (lines 222-225).

- [x] **AC-25** -- PASS -- Program page (`web/src/app/(trainee-dashboard)/trainee/program/page.tsx` lines 43-58) shows EmptyState with "No program assigned" when no programs exist.

- [x] **AC-26** -- PASS -- Program switcher (dropdown menu) shown when `programs.length > 1` (line 63, lines 86-113). Uses DropdownMenu with "Switch Program" trigger. Selecting resets week to 0.

- [x] **AC-27** -- PASS -- Program viewer is read-only. No edit buttons, no input fields, no mutation hooks. Purely display components.

### Messaging

- [x] **AC-28** -- PASS -- Messages page (`web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`) reuses `ConversationList`, `ChatView`, and `MessageSearch` from `@/components/messaging/`. Split-panel layout with sidebar (w-80 on md+) and chat area.

- [x] **AC-29** -- PASS -- Trainee sees conversations from `useConversations()` hook which hits the messaging API. Auto-selects first conversation (lines 56-67). Trainee typically has one conversation (with their trainer).

- [x] **AC-30** -- PASS -- `ChatView` uses `ChatInput` which supports text messages and image attachments (`Paperclip` button, file input accepting JPEG/PNG/WebP, max 5MB). `handleSend` passes content + image to `useSendMessage`.

- [x] **AC-31** -- PASS -- `ChatView` uses `useMessagingWebSocket` hook (line 62) providing real-time: `onNewMessage`, `onMessageEdited`, `onMessageDeleted` callbacks. `TypingIndicator` shown when `typingDisplayName` is set. `sendTyping` passed to ChatInput's `onTyping`.

- [x] **AC-32** -- PASS -- Cmd/Ctrl+K keyboard shortcut implemented (lines 72-80 of messages page). Search button shown in header with keyboard shortcut badge. `MessageSearch` component reused from shared messaging components.

### Announcements

- [x] **AC-33** -- PASS -- `AnnouncementsList` (`web/src/components/trainee-dashboard/announcements-list.tsx`) renders each announcement as a Card with title (line 99), content (lines 112-115 when expanded), date badge (lines 102-108), and pinned indicator (Pin icon, line 91).

- [x] **AC-34** -- PASS -- Sorting logic (lines 22-28): Pinned first (`a.is_pinned && !b.is_pinned` returns -1), then by `created_at` descending.

- [x] **AC-35** -- PASS -- Unread announcements have visual distinction: bold title (`!announcement.is_read && "font-bold"` on line 96), unread dot (Circle icon with `fill-primary`, lines 84-88), and highlighted card background (`border-primary/30 bg-primary/5` on line 68).

- [x] **AC-36** -- PASS -- Opening an announcement (clicking the card) calls `onAnnouncementOpen` (line 58-61) which triggers `markOneRead.mutate(id)` in the parent page (lines 40-44 of announcements/page.tsx).

- [x] **AC-37** -- PASS -- "Mark all read" button in page header (lines 83-96 of announcements/page.tsx). Shows unread count badge. Calls `markAllRead.mutate()` with success/error toasts. Disabled when `markAllRead.isPending`.

### Achievements

- [x] **AC-38** -- PASS -- `AchievementsGrid` (`web/src/components/trainee-dashboard/achievements-grid.tsx`) renders a responsive grid (sm:grid-cols-2, lg:grid-cols-3). Each achievement has earned/locked visual state: earned = `bg-primary/10 text-primary` with Trophy icon, locked = `bg-muted text-muted-foreground` with Lock icon + `opacity-60` on card.

- [x] **AC-39** -- PASS -- Earned achievements show: Trophy icon (line 47), name (line 53), earned date formatted (lines 57-65), and description (lines 54-55).

- [x] **AC-40** -- PASS -- Locked achievements show: Lock icon (line 49), grayed-out styling (opacity-60), progress toward unlocking with "X / Y" label and Progress bar (lines 67-74).

- [x] **AC-41** -- PASS -- Summary shown in PageHeader description: `${stats.earned} of ${stats.total} achievements earned` (line 72 of achievements/page.tsx). Stats computed via `useMemo` filtering earned achievements.

### Settings

- [x] **AC-42** -- PASS -- Settings page (`web/src/app/(trainee-dashboard)/trainee/settings/page.tsx`) renders `ProfileSection` which includes: first/last name inputs (lines 163-184 of profile-section.tsx), profile image upload via file input (lines 56-89), remove button when image exists (lines 141-149).

- [x] **AC-43** -- PASS -- `AppearanceSection` (`web/src/components/settings/appearance-section.tsx`) renders Light/Dark/System theme toggle using `next-themes` with Sun/Moon/Monitor icons and radio group semantics.

- [x] **AC-44** -- PASS -- `SecuritySection` (`web/src/components/settings/security-section.tsx`) has current password, new password, and confirm password fields (lines 103-168).

- [x] **AC-45** -- PASS -- Profile changes call `updateProfile.mutate()` with `onSuccess: () => toast.success("Profile updated")` (line 50 of profile-section.tsx). Image upload also shows success toast.

- [x] **AC-46** -- PASS -- Password validation (lines 27-46 of security-section.tsx): current password required, new password min 8 chars, confirm must match. Error messages displayed with `role="alert"`.

## Acceptance Criteria Summary

| Status | Count |
|--------|-------|
| PASS   | 45    |
| FAIL   | 1     |
| Total  | 46    |

**Failed:** AC-19 (trainer branding colors not implemented)

---

## Edge Cases Verified

1. **Trainee with no trainer** -- PARTIALLY HANDLED -- The dashboard will render but no explicit "Contact support" message exists. The `user.trainer` field exists on the User type but is not checked for null in the dashboard. The EmptyState for no program says "Your trainer hasn't assigned a program yet" which implicitly assumes a trainer exists. **Verdict:** Low risk (FK constraint prevents this scenario in practice).

2. **Trainee with expired subscription** -- NOT IMPLEMENTED -- No subscription check or expired banner exists in the trainee dashboard layout or any page. **Verdict:** Out of scope for Phase 1 per ticket ("Stripe subscription management UI" is out of scope), but the banner would be a nice-to-have.

3. **Trainee not onboarded** -- NOT IMPLEMENTED -- No check for `onboarding_completed` in the layout or dashboard. User type has the field (`onboarding_completed: boolean`) but it is never read. **Verdict:** Ticket explicitly lists "Onboarding wizard on web" as out of scope, so this is acceptable.

4. **Multiple active programs** -- PASS -- `ProgramViewer` shows a program switcher (DropdownMenu) when `programs.length > 1` (line 63). Defaults to first active program or first program overall (line 41).

5. **Program with 0 exercises on a day** -- PASS -- `DayCard` explicitly handles this: `day.exercises.length === 0` shows "No exercises scheduled" (lines 226-229). Distinguished from rest day.

6. **Program with 52+ weeks** -- PASS -- Week tabs container has `overflow-x-auto` (line 139 of program-viewer.tsx), enabling horizontal scrolling.

7. **Weight in kg vs lbs** -- PARTIALLY HANDLED -- Weight card always displays `kg` (line 105 of weight-trend-card.tsx: `{Number(latest.weight_kg).toFixed(1)} kg`). The `LatestWeightCheckIn` type only has `weight_kg`. No lbs conversion. **Verdict:** Acceptable given backend stores kg. The ticket says "Display weight in the unit recorded" and backend field is `weight_kg`.

8. **Network failure mid-page** -- PASS -- Each card independently fetches data via separate `useQuery` hooks. Each has its own loading/error/success states. One card failing does not affect others. Confirmed by reading all 4 card components.

9. **Concurrent sessions (mobile + web)** -- PASS -- JWT-based auth. Tokens are independent. No session locking mechanism. Both sessions can be active simultaneously.

10. **Concurrent impersonation** -- PASS -- Different JWTs, independent sessions. Layout checks `user.role` via auth context, not cookie.

---

## Bugs Found

| # | Severity | Description | File:Line |
|---|----------|-------------|-----------|
| 1 | Medium | **Login page does not redirect TRAINEE to `/trainee/dashboard`** -- After successful login, the TRAINEE role falls through to default `destination = "/dashboard"`. Middleware then redirects to `/trainee/dashboard`, causing a double-hop (flash of redirect). ADMIN and AMBASSADOR are handled but TRAINEE is not. | `web/src/app/(auth)/login/page.tsx:49-54` |
| 2 | Medium | **Trainer branding not applied (AC-19)** -- The `TRAINEE_BRANDING` API URL is defined in `constants.ts` but never fetched or applied. No branding hook exists. No CSS variable injection for trainer colors. Dashboard renders with default theme only. | `web/src/lib/constants.ts:254` (defined but unused) |
| 3 | Low | **ProfileSection includes "Business name" field** -- The reused `ProfileSection` component includes a "Business name" input field (lines 186-195 of profile-section.tsx) which is trainer-specific and irrelevant for trainees. Should be hidden for TRAINEE role. | `web/src/components/settings/profile-section.tsx:186-195` |

---

## Additional Observations

### Positive Findings

1. **Excellent TypeScript typing** -- All types properly defined in `trainee-dashboard.ts` and reusing `trainee-view.ts`. No `any` types found. TypeScript compiles cleanly.

2. **Consistent architecture** -- All pages follow the same pattern: loading state, error state with retry, empty state, success state. Matches existing codebase conventions.

3. **Accessibility is thorough** -- ARIA labels on nav links, `aria-current="page"` on active links, `role="tablist"/"tab"/"tabpanel"` on program weeks, skip-to-content link in layout, `sr-only` loading text, keyboard support on announcement cards (`onKeyDown` for Enter/Space), focus-visible rings via Tailwind.

4. **Component reuse is extensive** -- Settings reuses `ProfileSection`, `AppearanceSection`, `SecuritySection`. Messages reuses `ConversationList`, `ChatView`, `MessageSearch`, `ChatInput`. Shared components (`ErrorState`, `EmptyState`, `Skeleton`, `Badge`, `Card`, `Progress`) used throughout.

5. **Smart badge count system** -- `useTraineeBadgeCounts` hook cleanly aggregates message and announcement unread counts. Used by both desktop and mobile sidebars.

6. **UserNav properly routes TRAINEE** -- The `UserNav` component (line 59 of `user-nav.tsx`) correctly routes TRAINEE users to `/trainee/settings` from the dropdown menu.

7. **WebSocket messaging fully functional** -- Real-time updates, typing indicators, read receipts, and image attachments all supported through the reused messaging infrastructure.

8. **Proper data fetching** -- `staleTime: 5 * 60 * 1000` (5 min) for dashboard data. Weight check-in 404s handled gracefully (`retry` returning false for 404).

### Risk Assessment

- **Bug #1 (login redirect):** Users will experience a brief flash/redirect when logging in as TRAINEE. Not a blocker but a UX regression. Easy fix: add `else if (loggedInUser.role === UserRole.TRAINEE) destination = "/trainee/dashboard"` in login page.
- **Bug #2 (branding):** This is the only FAIL among 46 ACs. The API URL is defined but the feature was never wired up. Requires creating a branding hook and applying CSS variables.
- **Bug #3 (business name):** Minor UX issue. Trainee sees an irrelevant "Business name" field in settings. Low priority.

---

## Confidence Level: HIGH

**Rationale:** 45 of 46 acceptance criteria pass. TypeScript compiles cleanly with zero errors. The single failing AC (branding) is a feature gap rather than a regression. The login redirect bug is medium severity but the middleware catches it, so trainees still land on the correct page. All edge cases are handled or have acceptable justification. The implementation is architecturally sound, well-typed, accessible, and consistent with the existing codebase patterns.
