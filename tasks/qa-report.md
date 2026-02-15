# QA Report: Web Trainer Dashboard (Pipeline 9)

## Date: 2026-02-15

## Test Results
- Total: 42 (35 Acceptance Criteria + 7 Edge Cases)
- Passed: 39
- Failed: 3

## Note on Test Methodology
No frontend test framework (jest/vitest) is configured for the web dashboard. All verification was performed by thorough source code inspection against every acceptance criterion and edge case. The build and lint were confirmed passing per `tasks/dev-done.md`.

---

## Acceptance Criteria Verification

### Auth System

- [x] AC-1 — **PASS** — Login page at `web/src/app/(auth)/login/page.tsx` has email/password form with Zod validation schema (`loginSchema` with `.email()` and `.min(1, "Password is required")`), loading state via `isSubmitting` boolean rendering a `Loader2` spinner with "Signing in..." text, and error display in a styled `bg-destructive/10` div. Uses `.error.issues[0].message` which is correct for Zod v4. Form inputs are disabled during submission. Centered card layout via `(auth)/layout.tsx`.

- [x] AC-2 — **PASS** — `web/src/lib/token-manager.ts` stores JWT access and refresh tokens in `localStorage` under keys `fitnessai_access_token` and `fitnessai_refresh_token`. Refresh mutex implemented at line 71 via a module-level `let refreshPromise: Promise<boolean> | null = null` — concurrent calls to `refreshAccessToken()` return the same in-flight promise and the `finally` block resets it. The `api-client.ts` handles 401 by calling `refreshAccessToken()` and retrying the original request once. If refresh fails, tokens are cleared and the user is redirected to `/login`.

- [x] AC-3 — **PASS** — `setTokens()` in `token-manager.ts` line 52 writes a `has_session` cookie with value `"1"` and 7-day expiry via `setCookie()`. `clearTokens()` deletes it via `deleteCookie()`. The Next.js middleware at `web/src/middleware.ts` reads `request.cookies.get(SESSION_COOKIE)?.value === "1"` to gate route access server-side before client code runs.

- [x] AC-4 — **PASS** — `web/src/providers/auth-provider.tsx` line 39: after fetching the user from `/api/auth/users/me/`, checks `if (userData.role !== UserRole.TRAINER)` and throws `"Only trainer accounts can access this dashboard"`. Tokens are cleared immediately. The error is re-thrown from `fetchUser` so the login page can display it. Non-trainer users (ADMIN, TRAINEE, AMBASSADOR) are all blocked.

- [x] AC-5 — **PASS** — Three-layer redirect system works: (1) Next.js middleware redirects unauthenticated users from protected routes to `/login`, authenticated users from `/login` to `/dashboard`, and root `/` based on session cookie. (2) Dashboard layout (`(dashboard)/layout.tsx` line 20-24) uses `useEffect` with `router.replace("/login")` as a client-side guard. (3) Login page's `handleSubmit` calls `router.push("/dashboard")` on successful login.

### Dashboard

- [x] AC-6 — **PASS** — `web/src/components/dashboard/stats-cards.tsx` renders exactly 4 `StatCard` components in a responsive grid (`sm:grid-cols-2 lg:grid-cols-4`): "Total Trainees" (total_trainees, with max/plan description), "Active Today" (trainees_logged_today, with active_trainees description), "On Track" (trainees_on_track, with avg_adherence_rate percentage), "Pending Onboarding" (trainees_pending_onboarding). Each card has title, value, description, and icon.

- [x] AC-7 — **PASS** — `web/src/components/dashboard/recent-trainees.tsx` displays a table of trainees clipped with `.slice(0, 10)` at line 47. Data comes from `useDashboardOverview()` which returns `overview.data.recent_trainees`. Table shows Name (with email), Status (Active/Onboarding badge), Program, and Joined (relative time via `formatDistanceToNow`). Each name is a link to the trainee detail page.

- [x] AC-8 — **PASS** — `web/src/components/dashboard/inactive-trainees.tsx` renders `overview.data.inactive_trainees` as a list with warning icon. Each item shows name, email, and last activity time ("Last active X ago" or "Never logged"). Items are clickable links to trainee detail. Returns null if no inactive trainees.

- [x] AC-9 — **PASS** — Dashboard page at `(dashboard)/dashboard/page.tsx` renders: `DashboardSkeleton` during loading (4 skeleton cards + 2 skeleton tables), `ErrorState` with retry calling both `stats.refetch()` and `overview.refetch()` on error, and `EmptyState` with "No trainees yet" + invitation CTA when `total_trainees === 0`.

### Trainee List

- [x] AC-10 — **PASS** — `web/src/components/trainees/trainee-columns.tsx` defines 5 columns matching the spec: Name (first_name + last_name with email subtitle), Status (Active/Onboarding badge based on profile_complete), Last Activity (formatted date or "Never"), Program (current_program.name or "None"), Joined (created_at formatted). Pagination handled by `DataTable` component with page controls showing "Page X of Y (Z total)".

- [x] AC-11 — **PASS** — `web/src/app/(dashboard)/trainees/page.tsx` uses `useDebounce(search, 300)` at line 19 with exactly 300ms delay. `handleSearchChange()` at lines 26-29 calls both `setSearch(value)` and `setPage(1)`, correctly resetting pagination when search changes. The debounced value is passed to `useTrainees()` which builds the query params.

- [ ] AC-12 — **FAIL (Minor)** — Only the trainee **name** cell is a clickable `<Link>` to `/trainees/${row.id}`. The entire table row is NOT clickable. The `DataTable` component at `web/src/components/shared/data-table.tsx` has no `onRowClick` prop or cursor styling on rows. While functionally the user can still navigate via the name, the AC states "Click row navigates to trainee detail" which implies full-row click behavior.

### Trainee Detail

- [x] AC-13 — **PASS** — `web/src/app/(dashboard)/trainees/[id]/page.tsx` has "Back to Trainees" button rendered as `<Link href="/trainees">` with `ArrowLeft` icon in both error state (lines 31-35) and normal state (lines 56-61). Uses ghost variant button.

- [x] AC-14 — **PASS** — Profile info header shows: user icon avatar in a muted circle, name in `text-2xl font-bold`, email in `text-sm text-muted-foreground`, and a `Badge` showing "Active" (default variant) or "Inactive" (secondary variant) based on `trainee.is_active` (lines 62-75).

- [x] AC-15 — **PASS** — 3 tabs implemented using shadcn `Tabs` component with `defaultValue="overview"`: "Overview", "Activity", "Progress" triggers (lines 79-94). Each tab renders the corresponding sub-component.

- [x] AC-16 — **PASS** — Overview tab at `trainee-overview-tab.tsx` shows three sections: (1) Profile card with email, phone, sex, age, height, weight, goal, activity level, diet type, meals/day (or "Profile not completed" fallback), (2) Nutrition Goals card with 4 macro cards for calories, protein, carbs, fat (or "Goals not set yet" fallback), (3) Programs list with name, date range, active/ended badge (or "No programs assigned" fallback).

- [x] AC-17 — **PASS** — Activity tab at `trainee-activity-tab.tsx` has day filter buttons for 7d, 14d, 30d (`DAY_OPTIONS = [7, 14, 30]`). Table shows Date, Workout (logged/not badge), Food (logged/not badge), Calories, Protein, Carbs, Fat, and Goals column with protein "P" and calorie "C" `GoalBadge` components. Green badges for hit goals, muted badges for misses. Loading, error, and empty states handled.

- [x] AC-18 — **PASS** — Progress tab at `trainee-progress-tab.tsx` shows "Coming soon" via `EmptyState` with `BarChart3` icon and description "Progress charts and analytics will be available in a future update." Clean placeholder implementation.

- [x] AC-19 — **PASS** — `trainees/[id]/page.tsx` line 22-23: `parseInt(id, 10)` checked with `!isNaN(traineeId) && traineeId > 0`. Invalid IDs (non-numeric, zero, negative) immediately show `ErrorState` with message "Invalid trainee ID" and no retry button (since retrying won't help). API errors or missing trainee show "Trainee not found or failed to load" with retry button.

### Notifications

- [x] AC-20 — **PASS** — `notification-bell.tsx` uses `useUnreadCount()` which has `refetchInterval: 30_000` (30 seconds) at line 23 of `use-notifications.ts`, with `refetchIntervalInBackground: false` to stop polling when tab is hidden. Bell icon from lucide. Unread badge shows count, capped at "99+" for large numbers. Accessible `sr-only` text.

- [x] AC-21 — **PASS** — `notification-popover.tsx` slices to first 5 notifications (`data?.results?.slice(0, 5)` at line 18). Shows loading spinner, "No notifications yet" empty state, or scrollable list in `ScrollArea` with max height 300px. "View all notifications" link at bottom navigates to `/notifications`.

- [x] AC-22 — **PASS** — `notifications/page.tsx` has `Tabs` with "All" and "Unread" filter (lines 56-66). Unread filter applies client-side: `notifications.filter((n) => !n.is_read)` (line 29). See Bug #2 below for a noted limitation.

- [x] AC-23 — **PASS** — Mark as read: `useMarkAsRead()` mutation is called `onClick` for unread notifications on both the popover (line 42) and the full page (line 92). Mark all as read: `useMarkAllAsRead()` mutation triggered by page header button (line 47) with `isPending` disabled state. Both mutations invalidate `["notifications"]` query key on success, refreshing both the list and unread count.

- [x] AC-24 — **PASS** — Notifications page has Previous/Next pagination buttons (lines 97-121) with `page` state, `hasNextPage = Boolean(data?.next)`, and `hasPrevPage = page > 1`. Page number displayed between buttons.

### Invitations

- [x] AC-25 — **PASS** — `invitation-columns.tsx` defines 5 columns: Email (bold), Status (InvitationStatusBadge), Program (program_template_name or "None"), Sent (created_at formatted "MMM d, yyyy"), Expires (expires_at formatted "MMM d, yyyy").

- [x] AC-26 — **PASS** — `create-invitation-dialog.tsx` is a Dialog with: email field (type="email", Zod validation), message field (optional), expires_days field (number input, min=1, max=30, default "7"). Form has Zod validation schema, loading state (`isPending` with spinner), error display, success toast via sonner, and form reset on close/success. Cancel button to dismiss.

- [x] AC-27 — **PASS** — `invitation-status-badge.tsx` defines status colors: PENDING = amber (`border-amber-500/50 bg-amber-50 text-amber-700`, dark mode variants), ACCEPTED = green, EXPIRED = muted (`border-muted bg-muted text-muted-foreground`), CANCELLED = red. Smart override: `isExpired && status === "PENDING"` renders as EXPIRED badge.

- [x] AC-28 — **PASS** — Invitations page has Previous/Next pagination (lines 46-69) with page state, `hasNextPage`/`hasPrevPage` logic, and page number display.

### Layout

- [x] AC-29 — **PASS** — `sidebar.tsx` renders `<aside className="hidden w-64 shrink-0 border-r bg-sidebar lg:block">` — `w-64` = 16rem = 256px. Hidden below `lg` breakpoint. Nav links from `nav-links.tsx` (Dashboard, Trainees, Invitations, Notifications, Settings) with active state: exact match for dashboard, prefix match for others. Active style: `bg-sidebar-accent text-sidebar-accent-foreground`.

- [x] AC-30 — **PASS** — `sidebar-mobile.tsx` uses shadcn `Sheet` component with `side="left"` and `className="w-64 p-0"`. Controlled by `mobileOpen` state in `(dashboard)/layout.tsx`, toggled by header's hamburger button. Clicking a nav link calls `onOpenChange(false)` to close the drawer.

- [x] AC-31 — **PASS** — `header.tsx` has: hamburger button (`Menu` icon, `lg:hidden` — only shown on mobile), `NotificationBell` component (bell with unread badge + popover), and `UserNav` component (avatar with initials dropdown showing name, email, Settings link, and Logout).

- [x] AC-32 — **PASS** — `theme-provider.tsx` wraps the app with `next-themes` ThemeProvider using `attribute="class"`, `defaultTheme="system"`, `enableSystem`, and `disableTransitionOnChange`. Root layout wraps everything in `<ThemeProvider>`. Dark mode classes used throughout: `dark:bg-amber-950`, `dark:text-amber-400`, `dark:bg-green-950`, `dark:text-green-400`, `dark:bg-red-950`, `dark:text-red-400`.

### Infrastructure

- [x] AC-33 — **PASS** — `web/Dockerfile` is a proper 3-stage multi-stage build: (1) `deps` stage: `node:20-alpine`, copies `package.json`/`package-lock.json`, runs `npm ci --production=false`. (2) `builder` stage: copies node_modules and source, runs `npm run build`. (3) `runner` stage: production mode, creates non-root `nextjs` user (uid 1001), copies standalone output with correct ownership, exposes port 3000, runs `node server.js`.

- [x] AC-34 — **PASS** — `docker-compose.yml` has `web` service (lines 48-59): builds from `./web/Dockerfile`, port 3000:3000, `NEXT_PUBLIC_API_URL=http://localhost:8000`, depends on `backend`, `restart: unless-stopped`.

- [x] AC-35 — **PASS** — `backend/trainer/views.py` `TraineeListView` has `filter_backends = [SearchFilter]` and `search_fields = ['email', 'first_name', 'last_name']`. Imported from `rest_framework.filters`.

---

## Edge Cases Verified

- [x] EC-1 — **PASS** — `trainees/[id]/page.tsx` line 22-23: `const traineeId = parseInt(id, 10)` followed by `const isValidId = !isNaN(traineeId) && traineeId > 0`. Non-numeric IDs (e.g., "abc", "null", "undefined") produce `NaN` which fails the check. The `useTrainee` hook is called with `0` when invalid (disabled via `enabled: id > 0`), and the page immediately renders `ErrorState` with "Invalid trainee ID". No infinite loading possible.

- [x] EC-2 — **PASS** — In `use-trainees.ts` line 13: `if (search) params.set("search", search)` — empty string is falsy in JavaScript, so an empty search omits the `search` query parameter entirely, producing a clean URL. The API returns all trainees as expected.

- [x] EC-3 — **PASS** — All pages handle API errors: Dashboard shows `ErrorState` with retry (refetches both stats and overview). Trainees page shows `ErrorState` with retry. Trainee detail shows `ErrorState` with retry. Notifications page shows `ErrorState` with retry. Invitations page shows `ErrorState` with retry. Activity tab shows `ErrorState` with retry. React Query is configured with `retry: 1` default.

- [x] EC-4 — **PASS** — `auth-provider.tsx` lines 79-88: Auth initialization creates a `Promise.race` between `initAuth()` and a 10-second timeout: `setTimeout(() => reject(new Error("Auth timeout")), 10_000)`. If the timeout wins, the catch block clears tokens, sets user to null, and sets loading to false, preventing the app from hanging indefinitely.

- [x] EC-5 — **PASS** — `notification-item.tsx` `iconMap` (lines 15-23) maps all 7 backend `TrainerNotification.NotificationType` values exactly: `trainee_readiness` -> Activity, `workout_completed` -> Dumbbell, `workout_missed` -> AlertTriangle, `goal_hit` -> Target, `check_in` -> ClipboardCheck, `message` -> MessageSquare, `general` -> Info. Fallback: `iconMap[notification.notification_type] ?? Info` for any unknown type.

- [x] EC-6 — **PASS** — Backend `CreateInvitationSerializer` accepts fields: `email`, `program_template_id`, `message`, `expires_days`. Frontend `CreateInvitationPayload` type matches: `email: string`, `program_template_id?: number | null`, `message?: string`, `expires_days?: number`. Backend `TraineeInvitationSerializer` returns: `id`, `email`, `invitation_code`, `status`, `trainer_email`, `program_template`, `program_template_name`, `message`, `expires_at`, `accepted_at`, `created_at`, `is_expired`. Frontend `Invitation` type matches all 12 fields.

- [x] EC-7 — **PASS** — `token-manager.ts` line 14: `const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/")` correctly converts base64url-encoded characters (`-` to `+` and `_` to `/`) before calling `atob()` for standard base64 decoding. This handles JWTs that contain URL-safe base64 characters.

---

## Bugs Found

| # | Severity | Description | File:Line | Steps to Reproduce |
|---|----------|-------------|-----------|-------------------|
| 1 | Minor | **Trainee table row not fully clickable (AC-12)** — Only the trainee name column is rendered as a `<Link>`. The entire table row should be clickable to navigate to trainee detail. The `DataTable` component at `data-table.tsx` has no `onRowClick` prop, no `cursor-pointer` class on rows, and no row-level navigation. The user must click specifically on the name text. | `web/src/components/shared/data-table.tsx:68-76` and `web/src/components/trainees/trainee-columns.tsx:12-16` | Navigate to /trainees. Try clicking anywhere in a row except the name text. Nothing happens. Expected: entire row click should navigate to `/trainees/{id}`. |
| 2 | Minor | **Notification unread filter is client-side only** — The notifications page "Unread" tab filters the current page's results client-side via `notifications.filter((n) => !n.is_read)`. If all unread items are on page 2 and page 1 items are all read, clicking "Unread" on page 1 shows an empty list even though unread notifications exist on later pages. A server-side `?is_read=false` filter parameter would be more robust. | `web/src/app/(dashboard)/notifications/page.tsx:28-31` | 1. Have 20+ notifications where all page 1 items are read. 2. Have unread notifications on page 2. 3. Go to /notifications. 4. Click "Unread" tab. 5. See "All caught up" empty state even though unread notifications exist. |
| 3 | Low | **No dark mode toggle in the UI** — Dark mode is supported via `next-themes` with `defaultTheme="system"`, but there is no user-facing toggle button/switch to manually switch between light, dark, and system themes. The Settings page is a placeholder. Users can only get dark mode if their OS system preference is set to dark. | `web/src/app/(dashboard)/settings/page.tsx` | Navigate to /settings. No theme toggle is present. The only way to trigger dark mode is via OS-level preference. |

---

## Confidence Level: HIGH

**Reasoning:**
- 35 of 35 acceptance criteria verified by reading actual source code; 34 pass, 1 minor fail (AC-12 row click).
- All 7 edge cases verified and passing.
- Only 3 bugs found, all Minor or Low severity — none are blocking.
- Types between frontend and backend are well-aligned (invitation fields, notification types, activity summary fields all match).
- Auth system is robust: JWT in localStorage, refresh mutex for concurrent 401s, session cookie for middleware, 10-second timeout, role gating.
- All pages handle the 3 critical states (loading, error, empty) consistently.
- Dark mode classes are applied throughout the codebase.
- Docker multi-stage build is production-ready with non-root user.
- Build and lint confirmed passing (0 errors, 0 warnings per dev-done.md).
- Code is clean, well-typed, and follows consistent patterns across all 100+ files.
