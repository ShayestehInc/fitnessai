# Code Review: Trainee Web Portal (Pipeline 32)

## Review Date: 2026-02-21

## Files Reviewed: 31 files

### Modified Files
1. `web/src/middleware.ts`
2. `web/src/providers/auth-provider.tsx`
3. `web/src/lib/constants.ts`
4. `web/src/components/layout/user-nav.tsx`
5. `web/src/app/(dashboard)/layout.tsx`

### New Files
6. `web/src/app/(trainee-dashboard)/layout.tsx`
7. `web/src/components/trainee-dashboard/trainee-nav-links.tsx`
8. `web/src/components/trainee-dashboard/trainee-sidebar.tsx`
9. `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`
10. `web/src/components/trainee-dashboard/trainee-header.tsx`
11. `web/src/components/trainee-dashboard/todays-workout-card.tsx`
12. `web/src/components/trainee-dashboard/nutrition-summary-card.tsx`
13. `web/src/components/trainee-dashboard/weight-trend-card.tsx`
14. `web/src/components/trainee-dashboard/weekly-progress-card.tsx`
15. `web/src/components/trainee-dashboard/program-viewer.tsx`
16. `web/src/components/trainee-dashboard/announcements-list.tsx`
17. `web/src/components/trainee-dashboard/achievements-grid.tsx`
18. `web/src/components/ui/progress.tsx`
19. `web/src/hooks/use-trainee-dashboard.ts`
20. `web/src/hooks/use-trainee-announcements.ts`
21. `web/src/hooks/use-trainee-achievements.ts`
22. `web/src/types/trainee-dashboard.ts`
23. `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx`
24. `web/src/app/(trainee-dashboard)/trainee/program/page.tsx`
25. `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`
26. `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx`
27. `web/src/app/(trainee-dashboard)/trainee/achievements/page.tsx`
28. `web/src/app/(trainee-dashboard)/trainee/settings/page.tsx`

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `middleware.ts:47` | **Stale comment referencing old behavior.** Comment says "AC-22: TRAINEE role users accessing /login are redirected to /trainee-view" but the actual code now redirects to `/trainee/dashboard` via `getDashboardPath()`. Stale comments are dangerous in security-sensitive routing code -- future developers may trust the comment and miss the actual behavior. | Delete or update the comment to accurately reflect: "Authenticated users accessing /login are redirected to their role-appropriate dashboard." |
| C2 | `nutrition-summary-card.tsx:57-59` | **`--progress-color` CSS variable is set but never consumed by the Progress component.** The `MacroBar` component passes `style={{ "--progress-color": color }}` to the `<Progress>` element, but the Progress component (`progress.tsx:28`) hardcodes `bg-primary` for the indicator bar. All 4 macro bars will render with the same primary color instead of distinct colors per macro. This is a visible correctness bug that makes the nutrition card significantly less useful. | Update `progress.tsx` to use the CSS variable: change `bg-primary` to something like `[background-color:var(--progress-color,hsl(var(--primary)))]` on the inner div. Alternatively, add a `color` prop to the Progress component that applies inline style. |
| C3 | `announcements-list.tsx` / `trainee-dashboard.ts` | **AC-35 (Unread visual distinction) is NOT implemented.** The `Announcement` type has no `is_read` / `read_at` field, and the `AnnouncementsList` component renders all announcements identically -- no bold title, no unread dot, no visual differentiation between read and unread items. The ticket explicitly requires: "Unread announcements have visual distinction (bold title or unread dot)." | Add `is_read: boolean` field to the `Announcement` type. In `AnnouncementsList`, apply conditional styling: bold title + unread indicator dot for `!is_read` items. |
| C4 | `announcements-list.tsx` / `use-trainee-announcements.ts` | **AC-36 (Mark individual announcement as read on open) is NOT implemented.** The ticket requires "Opening an announcement marks it as read (POST mark-read)." There is no per-announcement read endpoint, no click handler on individual announcements, and no expand/open interaction at all. Announcements are rendered fully expanded with no open/close mechanism that could trigger a read action. | Either: (a) Add a click-to-expand pattern where clicking an announcement sends `POST /api/community/announcements/{id}/mark-read/` and expands the content, or (b) use an IntersectionObserver to mark announcements read when they scroll into view. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `todays-workout-card.tsx:24-25` | **`eslint-disable @typescript-eslint/no-explicit-any` on the `schedule` parameter.** The `findTodaysWorkout` function accepts `any` for schedule, which defeats type safety. The type `TraineeViewSchedule` already exists and describes the exact shape. | Type the parameter as `TraineeViewSchedule | null` instead of `any`. |
| M2 | `todays-workout-card.tsx:29-37` | **Fragile day-matching logic with multiple fallback strategies.** The function tries `d.day === String(todayNum)`, then `d.day === getDayName(todayNum)`, then falls back to `week.days[todayNum - 1]`. This triple-fallback suggests uncertainty about the data shape. If `day` is "1" vs "Monday" vs an index, only one pattern will match. The index fallback `week.days[todayNum - 1]` is dangerous -- if the program has fewer than 7 days (e.g., 5-day program), `todayNum = 6` or `7` could return `undefined` or the wrong day entirely. | Determine the canonical `day` format from the backend (it's a string per `TraineeViewScheduleDay`). Match against that single format. Remove the index-based fallback, or add a bounds check. |
| M3 | `todays-workout-card.tsx:118-121` | **Conflation of "no exercises" with "rest day".** `isRestDay` is true when `exercises.length === 0 && todaysDay !== null`, but the ticket (edge case #5) says: "Program with 0 exercises on a day: Show the day with 'No exercises' message (not a rest day -- rest days are explicitly marked)." The current code shows "Rest Day" for both explicitly marked rest days AND days with zero exercises. | Only set `isRestDay = todaysDay?.is_rest_day === true`. For days with `exercises.length === 0 && !is_rest_day`, show a distinct "No exercises scheduled" message. |
| M4 | `(dashboard)/layout.tsx:34` | **Uses `window.location.href` for TRAINEE redirect instead of `router.replace`.** All other role redirects in this layout use Next.js `router.replace()`, but TRAINEE uses a full page navigation. This is inconsistent and causes a full page reload, which is slower and flashes the loading spinner. | Use `router.replace("/trainee/dashboard")` for consistency with the ADMIN and AMBASSADOR redirects. |
| M5 | `messages/page.tsx:63` | **Suppressed `react-hooks/exhaustive-deps` warning.** The `useEffect` depends on `conversations` and `conversationIdParam` but deliberately excludes `selectedConversation` from the dependency array via eslint-disable. This can cause stale closures. When the conversation list updates but `selectedConversation` hasn't changed in the closure, the `else` branch at line 54 reads a stale `selectedConversation.id`. | Use a ref to track selectedConversation.id, or restructure the logic using a reducer pattern to eliminate the stale closure. |
| M6 | `weight-trend-card.tsx:87-92` | **Hardcoded color semantics: weight gain is amber, weight loss is green.** This assumes the user's goal is to lose weight. For users trying to gain weight (bulking), gaining weight is positive and should be green. The current implementation lacks user-goal awareness. | Either: (a) Make the colors neutral (both use foreground color), or (b) accept a `goal` prop to determine color semantics, or (c) at minimum, use a neutral indicator and let the trend direction speak for itself. |
| M7 | `weight-trend-card.tsx:95` | **Hardcoded kg-to-lbs conversion always shows both units.** The ticket says "Display weight in the unit recorded. Show conversion only if both exist." The current code always converts to lbs and shows both, even though the backend only stores `weight_kg`. | Show kg only by default. Only show lbs conversion if the user's preference is lbs (check profile or system locale), or if the backend provides a unit field. |
| M8 | `program-viewer.tsx:46-47` | **Component returns `null` when `selectedProgram` is null.** If programs exist but none are active and none match the default selection logic, this silently renders nothing. This is confusing -- the user sees a blank page with a page header but no content below it. | Show an explicit empty/error state instead of returning `null`. At minimum show "No program selected." |
| M9 | `trainee-dashboard/layout.tsx:29-38` + `middleware.ts:76-81` | **Double redirect for non-trainee users.** Both the middleware and the layout check roles and redirect non-trainee users. If the middleware guard fails (cookie manipulation), the layout catches it. But the layout uses `router.replace` which triggers a client-side navigation, briefly flashing trainee dashboard UI before redirecting. | This is defense-in-depth, which is fine, but add a guard in the layout's render: if `user?.role !== UserRole.TRAINEE`, show the loading spinner instead of rendering children. Currently it only checks `!isAuthenticated`, not role. |
| M10 | `trainee-sidebar.tsx` + `trainee-sidebar-mobile.tsx` | **Duplicated badge count logic.** Both sidebar components independently define `getBadgeCount()` and duplicate the unread count fetching hooks. This is a DRY violation that means any change to badge logic must be made in two places. | Extract badge count logic into a shared hook like `useTraineeBadgeCounts()` that returns `{ messages: number, announcements: number }`. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `nutrition-summary-card.tsx:66-68` | The `today` date string is memoized with an empty dependency array. If the user keeps the tab open past midnight, the date never updates. | Add a refetch/invalidation on window focus, or compute date inside the hook. |
| m2 | `trainee-header.tsx:13-28` | Header component does not show the trainee's name per AC-8 ("Header shows trainee name"). It only shows the `UserNav` dropdown. The trainer Header shows a page title and user info. | Add the user name display to the header, or clarify that the name is only in the dropdown. |
| m3 | `achievements-grid.tsx:37-38` | The icon badge circle uses string concatenation for className instead of the `cn()` utility used everywhere else. | Use `cn("flex h-12 w-12 ...", achievement.earned ? "bg-primary/10 text-primary" : "bg-muted text-muted-foreground")`. |
| m4 | `program-viewer.tsx:137` | Week tab buttons use string concatenation for conditional classes instead of `cn()`. | Use `cn(baseClasses, selectedWeek === idx ? activeClasses : inactiveClasses)`. |
| m5 | `use-trainee-dashboard.ts:50-56` | The 404 retry check uses a type assertion `(error as { status: number }).status === 404`. This is fragile. | Create a type guard function `isApiError(error): error is ApiError` for reuse. |
| m6 | `announcements/page.tsx:82-83` | Redundant `unreadCount > 0` check -- the outer condition at line 72 already gates on `unreadCount > 0`, so the inner badge always renders. | Remove the inner conditional. |
| m7 | `weight-trend-card.tsx:128` | Date formatting uses `undefined` locale, which is correct (browser default), but is inconsistent with announcements-list.tsx which also uses `undefined` but with `year: "numeric"`. Weight card omits year. | Add `year: "numeric"` for consistency, or explicitly omit it on both. |
| m8 | `messages/page.tsx:164` | `navigator.userAgent` check for Mac runs on every render. | Memoize the platform check or use a constant. |
| m9 | `types/trainee-dashboard.ts:44-62` | `WorkoutSummary` and `WorkoutSummaryExercise` types are defined but never used anywhere in the codebase. The `TodaysWorkoutCard` uses `TraineeViewScheduleDay` from `trainee-view.ts` instead. | Remove unused types or use them in `TodaysWorkoutCard` if they match the API response. |
| m10 | `use-trainee-dashboard.ts:69-78` | `useTraineeWorkoutSummary` hook is defined but never called anywhere. | Remove if unused, or wire it up if it was intended for `TodaysWorkoutCard`. |

---

## Security Concerns

1. **Middleware guard is cookie-based (by design).** The `ROLE_COOKIE` is client-writable, so a user could manually set `user_role=TRAINEE` and access the trainee dashboard layout. This is documented in the middleware comment ("convenience guard only") and true authorization happens server-side via API 403 responses + layout-level user object verification. This is acceptable **as long as** the layout also verifies the role. Currently, the trainee layout (`(trainee-dashboard)/layout.tsx`) redirects non-trainee roles but still renders children briefly before the redirect fires (see M9 above).

2. **No XSS vectors found.** Announcement content and achievement descriptions are rendered via React's default escaping (`{announcement.content}`). No `dangerouslySetInnerHTML` usage detected.

3. **No secrets in code.** All API URLs use environment variable base. No hardcoded tokens or credentials.

4. **API endpoints are all existing and server-protected.** No new backend endpoints = no new attack surface.

5. **Message search URL param.** The `conversationIdParam` from `useSearchParams()` is parsed with `parseInt()` before use. No injection risk.

---

## Performance Concerns

1. **C2 (Progress color)** means 4 identical-looking progress bars render, each doing unnecessary CSS variable work that is never consumed.

2. **Weight history hook fetches ALL check-ins** (`useTraineeWeightHistory` calls `TRAINEE_WEIGHT_CHECKINS` with no pagination). For a trainee with years of data, this could return hundreds of records just to show the latest 2. The `useTraineeLatestWeight` hook exists but is unused. The `WeightTrendCard` should use the latest endpoint plus one previous, not the full history.

3. **Sidebar unread count polling.** Both `useMessagingUnreadCount` (30s interval) and `useAnnouncementUnreadCount` (30s staleTime) are called in both the desktop sidebar AND mobile sidebar simultaneously. When on desktop, the mobile sidebar is hidden but still mounted (it's a Sheet component that renders regardless of `open` state). This means 4 polling queries instead of 2.

4. **Programs fetched twice on dashboard.** The dashboard page loads `TodaysWorkoutCard` which calls `useTraineeDashboardPrograms()`. If the user navigates to the Program page, it calls the same hook. React Query caching handles this well (5-min staleTime), so this is fine.

---

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | Trainee can log in, auth-provider allows TRAINEE role, `getDashboardPath` routes to `/trainee/dashboard` |
| AC-2 | PASS | Middleware `isTraineeDashboardPath` handles `/trainee/*` routing |
| AC-3 | PASS | Middleware redirects non-trainee users from `/trainee/*` paths |
| AC-4 | PASS | Middleware + layout redirect TRAINEE from trainer/admin/ambassador paths |
| AC-5 | PASS | Auth provider includes `UserRole.TRAINEE` in `isAllowedRole` |
| AC-6 | PASS | Sidebar has all 6 nav links: Dashboard, My Program, Messages, Announcements, Achievements, Settings |
| AC-7 | PASS | Desktop: 256px fixed sidebar. Mobile: Sheet drawer |
| AC-8 | PARTIAL | Header shows UserNav dropdown with name, but does not display name directly in header bar (see m2) |
| AC-9 | PASS | Messages badge with unread count in sidebar |
| AC-10 | PASS | Announcements badge with unread count in sidebar |
| AC-11 | PASS | Responsive layout, hamburger on < lg |
| AC-12 | PASS | 4 stat cards present |
| AC-13 | PASS | Today's workout shows exercises, rest day, and no-program states (but see M3 re: empty-day conflation) |
| AC-14 | PASS with bug | 4 macro bars rendered, but all same color due to C2 |
| AC-15 | PASS | Weight card with latest value, trend, and empty state |
| AC-16 | PASS | Weekly progress with percentage bar |
| AC-17 | PASS | All 4 cards have skeleton loading states |
| AC-18 | PASS | All 4 cards have error states with retry |
| AC-19 | FAIL | **No trainer branding integration.** `TRAINEE_BRANDING` constant exists but is never fetched or applied. No branding colors used anywhere in trainee dashboard. |
| AC-20 | PASS | Program viewer shows name, description, badges |
| AC-21 | PASS | Tabbed week view with horizontal scrolling |
| AC-22 | PASS | Day name, custom label, exercise list |
| AC-23 | PASS | Exercise rows numbered, show sets/reps/weight/rest |
| AC-24 | PASS | Rest days marked with badge and dimmed opacity |
| AC-25 | PASS | Empty state when no programs |
| AC-26 | PASS | Program switcher dropdown when multiple programs |
| AC-27 | PASS | Read-only, no edit controls |
| AC-28 | PASS | Messages page reuses ConversationList, ChatView, MessageSearch |
| AC-29 | PASS | Auto-selects first (usually only) conversation |
| AC-30 | PASS | ChatView component supports text and attachments |
| AC-31 | PASS | WebSocket via existing ChatView infrastructure |
| AC-32 | PASS | Cmd/Ctrl+K search with MessageSearch component |
| AC-33 | PASS | Announcements list with title, content, date, pinned |
| AC-34 | PASS | Sorted pinned-first, then by date descending |
| AC-35 | **FAIL** | No unread visual distinction (C3) |
| AC-36 | **FAIL** | No per-announcement mark-read on open (C4) |
| AC-37 | PASS | Mark all read button present |
| AC-38 | PASS | Grid with earned/locked visual states |
| AC-39 | PASS | Earned: trophy icon, name, date, description |
| AC-40 | PASS | Locked: lock icon, muted, progress bar |
| AC-41 | PASS | Summary "X of Y achievements earned" in page header |
| AC-42 | PASS | ProfileSection reused |
| AC-43 | PASS | AppearanceSection reused |
| AC-44 | PASS | SecuritySection reused |
| AC-45 | PASS | Handled by existing ProfileSection |
| AC-46 | PASS | Handled by existing SecuritySection |

**Summary:** 3 FAIL, 1 PARTIAL, 42 PASS out of 46 criteria.

---

## Quality Score: 7/10

**Strengths:**
- Solid architecture: separate route group, proper layout structure, follows existing patterns closely
- Excellent accessibility: ARIA labels, roles, skip-to-content, focus-visible rings, semantic HTML throughout
- Good error handling: every card has independent error/loading/empty states (edge case #8 covered)
- Proper use of React Query with staleTime, query key structure, and mutation invalidation
- Clean code: readable, well-organized, good component decomposition
- Reuses existing components (ErrorState, EmptyState, ProfileSection, etc.) instead of reinventing

**Weaknesses:**
- 3 acceptance criteria not met (AC-19 branding, AC-35 unread distinction, AC-36 per-announcement mark-read)
- Progress color bug makes nutrition card significantly less useful (C2)
- Some fragile logic (day matching, weight unit assumptions)
- Minor DRY violations in sidebar badge logic

---

## Recommendation: REQUEST CHANGES

Three acceptance criteria are unmet (AC-19, AC-35, AC-36), and the nutrition progress bar color bug (C2) is a visible correctness issue. Fix the 4 critical issues and the major issues M1-M4 before approving. The overall quality is good and the architecture is sound -- these are fixable issues, not fundamental design problems.
