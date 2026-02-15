# Code Review: Web Trainer Dashboard (Pipeline 9)

## Review Date
2026-02-15

## Files Reviewed

### Types (6)
- `web/src/types/user.ts`
- `web/src/types/trainer.ts`
- `web/src/types/notification.ts`
- `web/src/types/invitation.ts`
- `web/src/types/activity.ts`
- `web/src/types/api.ts`

### Lib (4)
- `web/src/lib/constants.ts`
- `web/src/lib/token-manager.ts`
- `web/src/lib/api-client.ts`
- `web/src/lib/utils.ts`

### Providers (3)
- `web/src/providers/auth-provider.tsx`
- `web/src/providers/query-provider.tsx`
- `web/src/providers/theme-provider.tsx`

### Hooks (6)
- `web/src/hooks/use-auth.ts`
- `web/src/hooks/use-dashboard.ts`
- `web/src/hooks/use-trainees.ts`
- `web/src/hooks/use-notifications.ts`
- `web/src/hooks/use-invitations.ts`
- `web/src/hooks/use-debounce.ts`

### Layout Components (5)
- `web/src/components/layout/sidebar.tsx`
- `web/src/components/layout/sidebar-mobile.tsx`
- `web/src/components/layout/header.tsx`
- `web/src/components/layout/nav-links.tsx`
- `web/src/components/layout/user-nav.tsx`

### Shared Components (5)
- `web/src/components/shared/page-header.tsx`
- `web/src/components/shared/empty-state.tsx`
- `web/src/components/shared/error-state.tsx`
- `web/src/components/shared/data-table.tsx`
- `web/src/components/shared/loading-spinner.tsx`

### Dashboard Components (5)
- `web/src/components/dashboard/stats-cards.tsx`
- `web/src/components/dashboard/stat-card.tsx`
- `web/src/components/dashboard/recent-trainees.tsx`
- `web/src/components/dashboard/inactive-trainees.tsx`
- `web/src/components/dashboard/dashboard-skeleton.tsx`

### Trainee Components (8)
- `web/src/components/trainees/trainee-table.tsx`
- `web/src/components/trainees/trainee-columns.tsx`
- `web/src/components/trainees/trainee-search.tsx`
- `web/src/components/trainees/trainee-overview-tab.tsx`
- `web/src/components/trainees/trainee-activity-tab.tsx`
- `web/src/components/trainees/trainee-progress-tab.tsx`
- `web/src/components/trainees/trainee-detail-skeleton.tsx`
- `web/src/components/trainees/trainee-table-skeleton.tsx`

### Notification Components (3)
- `web/src/components/notifications/notification-bell.tsx`
- `web/src/components/notifications/notification-popover.tsx`
- `web/src/components/notifications/notification-item.tsx`

### Invitation Components (4)
- `web/src/components/invitations/create-invitation-dialog.tsx`
- `web/src/components/invitations/invitation-table.tsx`
- `web/src/components/invitations/invitation-columns.tsx`
- `web/src/components/invitations/invitation-status-badge.tsx`

### Pages (12)
- `web/src/app/page.tsx`
- `web/src/app/not-found.tsx`
- `web/src/app/layout.tsx`
- `web/src/app/(auth)/layout.tsx`
- `web/src/app/(auth)/login/page.tsx`
- `web/src/app/(dashboard)/layout.tsx`
- `web/src/app/(dashboard)/dashboard/page.tsx`
- `web/src/app/(dashboard)/trainees/page.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/app/(dashboard)/notifications/page.tsx`
- `web/src/app/(dashboard)/invitations/page.tsx`
- `web/src/app/(dashboard)/settings/page.tsx`

### Config/Infra
- `web/src/middleware.ts`
- `web/src/app/globals.css`
- `web/next.config.ts`
- `web/tsconfig.json`
- `web/package.json`
- `web/Dockerfile`
- `web/.env.example`
- `docker-compose.yml`

### Backend (contract verification)
- `backend/trainer/views.py` (TraineeListView at line 166-180)
- `backend/trainer/serializers.py` (all serializers)
- `backend/trainer/notification_views.py` (all views)
- `backend/trainer/notification_serializers.py` (TrainerNotificationSerializer)
- `backend/trainer/models.py` (TrainerNotification model at line 205-256)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `web/src/types/notification.ts:13-21` | **API contract mismatch: Notification type has `trainee` field that does not exist in backend serializer.** The frontend `Notification` interface includes `trainee: number \| null` but the backend `TrainerNotificationSerializer` (notification_serializers.py:16-25) serializes fields `['id', 'notification_type', 'title', 'message', 'data', 'is_read', 'read_at', 'created_at']` -- no `trainee` field. The backend model `TrainerNotification` has no `trainee` FK either. Additionally, the backend returns `data` (JSONField) and `read_at` fields which the frontend type omits entirely. At runtime, `notification.trainee` will always be `undefined` (not even `null`), and any backend data or read_at info is silently discarded by the frontend. | Update `web/src/types/notification.ts` Notification interface: remove `trainee`, add `data: Record<string, unknown>` and `read_at: string \| null`. |
| C2 | `web/src/types/notification.ts:1-8` + `web/src/components/notifications/notification-item.tsx:6-13` | **Notification type enum values have zero overlap with backend model choices.** Frontend defines: `trainee_joined`, `trainee_completed_onboarding`, `trainee_logged_workout`, `trainee_logged_food`, `trainee_inactive`, `system`. Backend `TrainerNotification.NotificationType` (models.py:211-218) defines: `trainee_readiness`, `workout_completed`, `workout_missed`, `goal_hit`, `check_in`, `message`, `general`. Not a single value matches. This means the `iconMap` in `notification-item.tsx` will never match any real notification type, always falling back to the generic `Info` icon. Every single notification will display the wrong icon. | Align the frontend `NotificationType` const with backend values: `trainee_readiness`, `workout_completed`, `workout_missed`, `goal_hit`, `check_in`, `message`, `general`. Update `iconMap` accordingly with appropriate icons for each type. |
| C3 | `web/src/components/invitations/create-invitation-dialog.tsx:52-56` + `web/src/types/invitation.ts:26-31` | **API contract mismatch: Invitation creation sends wrong field names.** The frontend Zod schema uses `expires_in_days` and the `CreateInvitationPayload` type uses `program_template`. But the backend `CreateInvitationSerializer` (serializers.py:157-162) expects `expires_days` and `program_template_id`. The field name mismatch for `expires_in_days` vs `expires_days` means the backend will ignore the frontend's expiry value and silently use the default of 7 days regardless of what the user enters. Similarly, sending `program_template` instead of `program_template_id` means the backend ignores that field too. | In `create-invitation-dialog.tsx`, change the Zod schema field from `expires_in_days` to `expires_days`. In `web/src/types/invitation.ts`, change `CreateInvitationPayload.program_template` to `program_template_id`. |
| C4 | `web/src/lib/token-manager.ts:13` | **JWT decode uses `atob()` which does not handle URL-safe base64.** JWT tokens use base64url encoding (with `-` and `_` instead of `+` and `/`, and no padding). `atob()` only handles standard base64. Any JWT token containing URL-safe characters will cause `atob()` to throw, making `isAccessTokenExpired()` return `true`, triggering an unnecessary token refresh on every single API request. Depending on the JWT library used by Django Simple JWT, this may occur frequently. | Replace `atob(parts[1])` with proper base64url decoding: `atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'))`. |
| C5 | `web/src/providers/auth-provider.tsx:39-48` | **Non-trainer login silently fails with a blank page.** When a TRAINEE or ADMIN logs in: (1) `login()` calls `setTokens()` successfully (line 89), (2) `fetchUser()` is called (line 90), (3) inside `fetchUser`, the role check on line 39 correctly rejects with `throw new Error("Only trainer accounts can access this dashboard")`, (4) the `catch` block on line 45-48 silently swallows this error -- clears tokens and sets user to null, (5) back in `login()`, since `fetchUser()` did not re-throw, `login()` resolves successfully, (6) `router.push("/dashboard")` executes (login page line 45), (7) the dashboard layout sees `!isAuthenticated` and returns `null` -- a blank white page. The user successfully "logged in" but sees nothing, with no error message. | In `fetchUser()`, after the role check throws on line 43, the catch block should re-throw errors that are not API/network errors: `catch (error) { clearTokens(); setUser(null); if (error instanceof Error && error.message.includes("Only trainer")) throw error; }`. This allows the login page to catch and display the message. |
| C6 | `docker-compose.yml:56` | **`NEXT_PUBLIC_API_URL=http://backend:8000` is completely broken for browser requests.** `NEXT_PUBLIC_` environment variables in Next.js are embedded into client-side JavaScript at build time. The browser cannot resolve Docker's internal hostname `backend`. Every API call from the browser will fail with `ERR_NAME_NOT_RESOLVED`. The Docker-based deployment is non-functional. | Change to `NEXT_PUBLIC_API_URL=http://localhost:8000`. The `backend` hostname is only resolvable within the Docker network; the browser runs on the host machine and needs `localhost`. If server-side API calls are ever needed, use a separate non-NEXT_PUBLIC env var for those. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `web/src/lib/token-manager.ts:20-22` | **Session cookie lacks `Secure` flag.** The `has_session` cookie is set with `SameSite=Lax` but no `Secure` flag. In production over HTTPS, this cookie can be sent over unencrypted HTTP connections. | Add `Secure` flag conditionally: append `${window.location.protocol === 'https:' ? ';Secure' : ''}` to the cookie string. |
| M2 | `web/src/lib/api-client.ts:19-37` + `55-81` | **Triple refresh race condition.** `getAuthHeaders()` proactively checks token expiry and calls `refreshAccessToken()`. Then `request()` calls `getAuthHeaders()`, makes the request, and if a 401 comes back, calls `refreshAccessToken()` again (line 56). If that succeeds, it calls `getAuthHeaders()` again (line 58), which may trigger yet another refresh. This is 3 potential refresh attempts per single API request. The mutex in `refreshAccessToken` mitigates concurrent calls but doesn't prevent the sequential triple-attempt pattern. | Remove the proactive refresh from `getAuthHeaders`. Have it simply return the current token. Let the 401 retry in `request()` be the sole refresh mechanism. This simplifies the flow to: try with current token -> 401 -> refresh -> retry once -> fail. |
| M3 | `web/src/lib/api-client.ts:47-48` | **Content-Type always set to `application/json` even for GET/DELETE requests without a body.** While most servers tolerate this, some CORS preflight configurations may reject requests with unnecessary Content-Type headers on simple requests, and it is technically incorrect per HTTP semantics. | Only set `Content-Type: application/json` when a body is present. Move header setting into `post`/`patch` methods, or conditionally set it: `...(options.body ? { "Content-Type": "application/json" } : {})`. |
| M4 | `web/src/app/(dashboard)/trainees/[id]/page.tsx:22` | **No NaN validation on `parseInt` for trainee ID.** If the URL contains a non-numeric ID (e.g., `/trainees/abc`), `parseInt("abc", 10)` returns `NaN`. The `useTrainee` hook has `enabled: id > 0`, and since `NaN > 0` is `false`, the query is permanently disabled. The component stays in the `isLoading` state forever -- the user sees an infinite loading skeleton with no way to recover. | Add NaN check immediately after parsing: `if (isNaN(traineeId)) return <ErrorState message="Invalid trainee ID" />;` with a back button. |
| M5 | `web/src/app/(dashboard)/layout.tsx:26-28` | **Unauthenticated dashboard returns blank page with no redirect.** When `!isAuthenticated`, the layout returns `null`. This happens when tokens expire and refresh fails: the auth provider clears tokens (including the cookie), but the user is already on a dashboard route. They see a blank white page until `api-client.ts` eventually triggers `window.location.href = "/login"` on a failed request. But if no request is made (e.g., they're on the settings page which makes no API calls), they're stuck on a blank page permanently. | Add explicit redirect: `if (!isAuthenticated) { if (typeof window !== "undefined") window.location.href = "/login"; return null; }`. |
| M6 | `web/src/hooks/use-notifications.ts:9-15` | **Notifications hook has no pagination -- always fetches only first page.** The backend `NotificationListView` paginates at 20 per page. The frontend's `useNotifications()` calls the endpoint without page params and has no mechanism to load more. Trainers with more than 20 notifications will never see older ones. The full notifications page at `/notifications` renders `data?.results` which is capped at 20 items with no "load more" or pagination controls. | Add pagination parameters to the hook (similar to `useTrainees`), or add infinite scroll / "load more" button to the notifications page. |
| M7 | `web/src/hooks/use-invitations.ts:9-15` | **Invitations hook has no pagination -- same issue as M6.** Only the first page of invitations is fetched. A trainer who has sent more than 20 invitations will never see the older ones in the invitations table. | Add pagination support matching the trainee list pattern. |
| M8 | `web/src/lib/api-client.ts:73` + `89` | **Unsafe cast of `undefined as T` for 204 responses.** When the server returns 204 No Content, the function returns `undefined as T`. This is a type lie -- callers believe they're getting `T` but get `undefined`. Currently this affects `markAsRead` (returns serialized notification, not 204), `markAllAsRead` (returns JSON body), and `delete` (returns 204). The delete case will return `undefined` cast to whatever `T` is. If any caller destructures the return value, it will crash. | Change the function signature to return `Promise<T | undefined>` for 204 cases, or better: have `delete` return `Promise<void>` and remove the generic. |
| M9 | `web/src/app/globals.css:119-127` | **Duplicate CSS declarations.** Lines 121 and 122 are identical (`@apply border-border outline-ring/50;`). Lines 125 and 126 are identical (`@apply bg-background text-foreground;`). Each rule is applied twice. | Remove the duplicate lines 122 and 126. |
| M10 | `web/src/providers/auth-provider.tsx:51-71` | **Auth initialization has no timeout.** If the backend is unreachable (DNS failure, server down, extremely slow response), `fetchUser()` will hang indefinitely. The user sees the dashboard layout's loading spinner (`Loader2` on line 21) forever with no error state and no way to recover. | Add an AbortController with a timeout (e.g., 10 seconds) to the auth init fetch. On timeout, set `isLoading = false` and show an error or redirect to login. |
| M11 | `backend/trainer/serializers.py:32-53` | **N+1 queries in TraineeListSerializer triggered by frontend.** `get_profile_complete` accesses `obj.profile` (1 query per row), `get_last_activity` accesses `obj.daily_logs.order_by('-date').first()` (1 query per row), `get_current_program` accesses `obj.programs.filter(is_active=True).first()` (1 query per row). The `TraineeListView.get_queryset()` at views.py:175-180 has no `select_related('profile')` or `prefetch_related('daily_logs', 'programs')`. With 20 trainees per page, this is 60+ extra DB queries. | Add to `TraineeListView.get_queryset()`: `.select_related('profile').prefetch_related(Prefetch('daily_logs', queryset=DailyLog.objects.order_by('-date')[:1]), Prefetch('programs', queryset=Program.objects.filter(is_active=True)[:1]))`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `web/src/lib/token-manager.ts:14` | `payload as TokenPayload` is an unsafe type assertion with no runtime validation. If the JWT payload has an unexpected shape, all subsequent code using `payload.exp` could crash. | Add minimal runtime checks: `if (typeof payload?.exp !== 'number') return null;` |
| m2 | `web/src/components/shared/data-table.tsx:17` | Uses `React.ReactNode` without explicit React import. Relies on global types from tsconfig `jsx: "react-jsx"`. Inconsistent with other files that import `type { ReactNode }`. | Add `import type { ReactNode } from "react"` and use `ReactNode`. |
| m3 | `web/src/app/(auth)/layout.tsx:3` | Same as m2 -- uses `React.ReactNode` without React import in server component. | Add explicit type import. |
| m4 | `web/src/components/layout/user-nav.tsx:19-21` | **Empty avatar when user has empty first/last name.** If `user.first_name` and `user.last_name` are both empty strings, `initials` becomes an empty string and the avatar shows nothing. | Fall back to first char of email: ``const initials = `${user.first_name.charAt(0)}${user.last_name.charAt(0)}`.toUpperCase() \|\| user?.email?.charAt(0)?.toUpperCase() \|\| "?";`` |
| m5 | `web/src/components/notifications/notification-item.tsx:6` | `iconMap` is typed as `Record<string, typeof UserPlus>`. Should be `Record<string, LucideIcon>` for semantic clarity. | Import `LucideIcon` and change the type annotation. |
| m6 | `web/src/components/dashboard/recent-trainees.tsx:67-69` | `new Date(t.created_at)` can produce `Invalid Date` if the string is malformed, causing `formatDistanceToNow` to throw. Same pattern in `inactive-trainees.tsx:49`, `notification-item.tsx:55`, `trainee-columns.tsx:38,57`. | Add a safe date formatting utility that catches invalid dates, or validate date strings before passing to `new Date()`. |
| m7 | `web/src/app/(dashboard)/notifications/page.tsx:55` | `onValueChange={(v) => setFilter(v as Filter)}` -- unsafe cast of arbitrary string to `Filter` union type. | Use a type guard: `if (v === "all" \|\| v === "unread") setFilter(v);` |
| m8 | `web/src/components/trainees/trainee-search.tsx:15-19` | No `aria-label` on the search input. Screen readers cannot identify the purpose of this input. The decorative search icon provides no accessible hint. | Add `aria-label="Search trainees"` to the `Input` component. |
| m9 | `web/src/components/layout/sidebar.tsx:23-25` + `sidebar-mobile.tsx:32-34` | Active link detection logic is duplicated between sidebar and sidebar-mobile. | Extract to a shared utility function: `isNavLinkActive(pathname: string, href: string): boolean`. |
| m10 | `web/src/app/page.tsx:1-5` | Root page uses server-side `redirect()` to `/dashboard`, but the middleware (middleware.ts:22-27) already handles root path redirection. Double redirect logic. | Remove one. The middleware approach is more appropriate since it handles auth state (redirects to login vs dashboard based on session). The page redirect always goes to dashboard regardless of auth. |
| m11 | `web/package.json:30` | Both `"radix-ui": "^1.4.3"` (meta-package) and individual `@radix-ui/*` packages are listed as dependencies. This is redundant and may cause version conflicts or increased bundle size. | Remove either the individual `@radix-ui/*` packages or the `radix-ui` meta-package. |
| m12 | `web/src/hooks/use-notifications.ts:17-24` | `useUnreadCount` polls every 30 seconds. By default, React Query continues polling when the tab is in the background (`refetchIntervalInBackground: true`). This wastes bandwidth and server resources when the user isn't looking. | Add `refetchIntervalInBackground: false` to the query options. |
| m13 | `web/src/components/invitations/create-invitation-dialog.tsx:111-118` | Invitation email input has no `autoComplete` attribute. Browser may auto-fill with the trainer's own email, which is not the intended use case. | Add `autoComplete="off"` to the email input. |

---

## Security Concerns

### Token Storage in localStorage
Tokens are stored in `localStorage`, which is accessible to any JavaScript running on the page. An XSS vulnerability anywhere in the app (even from a third-party dependency) would allow complete token exfiltration. This is a known architectural trade-off documented in `dev-done.md` -- the backend returns JWT in a JSON body rather than HttpOnly cookies. HttpOnly cookies with `SameSite=Strict` would be significantly more secure, but would require backend changes to the auth flow.

**Risk level:** Medium. Mitigated by React's automatic JSX escaping (no `dangerouslySetInnerHTML` usage found), but remains a concern if any dependency introduces XSS.

### Session Cookie Security (M1)
The `has_session` cookie used by middleware for route protection lacks the `Secure` flag. In a production HTTPS environment, this cookie could leak over HTTP redirects or mixed-content scenarios.

### No Rate Limiting on Login
The login form has no client-side rate limiting (no lockout after N failures, no CAPTCHA, no progressive delay). While the backend should implement rate limiting on `/api/auth/jwt/create/`, the frontend provides no protection against automated brute-force attempts.

### No CSRF Concerns
The API uses JWT bearer tokens in Authorization headers, not cookies for API auth. CSRF is not applicable for the API calls. The `has_session` cookie is used only for client-side route decisions in middleware, not for API authentication. Low risk.

### XSS Surface Review
All user-generated content (trainee names, notification messages, invitation messages, search queries) is rendered through JSX's automatic escaping. No use of `dangerouslySetInnerHTML` found anywhere. Search input values are properly encoded via `URLSearchParams`. **Solid -- no XSS vectors identified.**

### IDOR Protection
Trainee IDs in URLs (`/trainees/[id]`) are validated on the backend via `get_queryset()` filtering by `parent_trainer`. The frontend correctly delegates all authorization to the backend. No client-side authorization bypass possible.

### Secrets Check
No API keys, passwords, tokens, or secrets found in any source file, config file, or comment. `.env.example` contains only a placeholder URL. Docker-compose uses environment variable references with safe defaults (the `SECRET_KEY` default is explicitly marked as insecure). **Clean.**

---

## Performance Concerns

### N+1 Queries (M11)
The most significant performance issue is the N+1 query pattern in `TraineeListSerializer`. Each trainee in the list triggers 3 extra database queries (profile, daily_logs, programs). With 20 trainees per page, that's 60 extra queries. This will cause noticeable latency as the trainee count grows.

### Notification Polling
`useUnreadCount` polls every 30 seconds, generating 2 requests/minute per open tab. With `refetchIntervalInBackground: true` (default), this continues even when the tab is backgrounded. For a trainer with multiple tabs open, this compounds quickly.

### No Data Prefetching
When navigating from the trainee list to trainee detail, data is fetched fresh. No `queryClient.prefetchQuery` on hover. This adds perceived latency to every navigation.

### Client-Side Rendering Only
All pages are client-rendered (no SSR). This means every page load shows a loading spinner while data is fetched. For SEO this doesn't matter (dashboard is authenticated), but the perceived performance is worse than SSR or streaming. Acceptable trade-off given the localStorage-based auth architecture.

### React Re-renders
- `traineeColumns` is correctly defined at module scope, avoiding recreation on render.
- `QueryProvider` correctly uses `useState` for `QueryClient`.
- `DashboardPage` makes two independent queries; when one resolves before the other, there are intermediate re-renders showing partial data. Low severity.

---

## Quality Score: 6/10

### Positives
- Clean, well-organized architecture following React/Next.js best practices
- Feature-first component structure with good separation of concerns
- Proper use of React Query for server state management
- Comprehensive loading, empty, and error states throughout
- TypeScript strict mode enabled
- Good use of shadcn/ui component library
- Proper JWT refresh mutex for concurrent requests
- Responsive design with mobile sidebar
- Dark mode support
- Accessible screen reader text on notification bell

### Issues Driving Score Down
- 3 critical API contract mismatches (C1, C2, C3) that mean notifications display wrong icons and invitation expiry is ignored -- the dashboard will not function correctly against the real backend
- Docker deployment completely broken (C6) -- browser cannot reach backend API
- Non-trainer login produces a blank page with no feedback (C5)
- JWT decoder has a latent base64url bug (C4)
- No pagination on notifications or invitations pages (M6, M7)
- N+1 queries in the backend serializer (M11)
- Multiple auth flow edge cases (M2, M5, M10)

## Recommendation: REQUEST CHANGES

The 6 critical issues must be resolved before merge. The most impactful are:

1. **C1 + C2 (Notification contract):** Every notification will display the wrong icon and the frontend will silently discard backend data fields. This makes the notification feature appear broken.

2. **C3 (Invitation field names):** The invitation expiry field is silently ignored. Trainers who set custom expiry periods will not get what they expect.

3. **C5 (Non-trainer login):** Any non-trainer who attempts to log in sees a blank white page with no error feedback. This will be the first thing reported as a bug.

4. **C6 (Docker URL):** The Docker-based deployment is completely non-functional. No API call will succeed.

5. **C4 (JWT decoder):** A latent bug that may or may not manifest depending on token content, but is trivial to fix.

Among the major issues, M4 (NaN trainee ID), M5 (blank page on auth failure), M6/M7 (no pagination), and M11 (N+1 queries) should be addressed for a production-quality dashboard.
