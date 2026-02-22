# Security Audit: Trainee Web Portal (Pipeline 32)

## Audit Date
2026-02-21

## Scope
Frontend-only feature: new Next.js route group `(trainee-dashboard)` with pages, components, hooks, and types. No backend changes. All API endpoints already exist with server-side auth.

## Files Audited

### Pages (New)
- `web/src/app/(trainee-dashboard)/layout.tsx` -- Layout with auth guard + role redirect
- `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx` -- Dashboard home
- `web/src/app/(trainee-dashboard)/trainee/program/page.tsx` -- Program viewer
- `web/src/app/(trainee-dashboard)/trainee/achievements/page.tsx` -- Achievements grid
- `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx` -- Announcements list
- `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx` -- Messaging page (reuses shared messaging components)
- `web/src/app/(trainee-dashboard)/trainee/settings/page.tsx` -- Settings (reuses shared profile/security/appearance components)

### Components (New)
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` -- Desktop sidebar navigation
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` -- Mobile sidebar (Sheet)
- `web/src/components/trainee-dashboard/trainee-header.tsx` -- Header with user nav
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx` -- Navigation link definitions
- `web/src/components/trainee-dashboard/todays-workout-card.tsx` -- Today's workout card
- `web/src/components/trainee-dashboard/nutrition-summary-card.tsx` -- Nutrition macro bars
- `web/src/components/trainee-dashboard/weight-trend-card.tsx` -- Weight trend card
- `web/src/components/trainee-dashboard/weekly-progress-card.tsx` -- Weekly progress card
- `web/src/components/trainee-dashboard/program-viewer.tsx` -- Full program viewer with week tabs
- `web/src/components/trainee-dashboard/achievements-grid.tsx` -- Achievement card grid
- `web/src/components/trainee-dashboard/announcements-list.tsx` -- Expandable announcement cards

### Hooks (New)
- `web/src/hooks/use-trainee-dashboard.ts` -- Dashboard data fetching hooks
- `web/src/hooks/use-trainee-achievements.ts` -- Achievements fetching hook
- `web/src/hooks/use-trainee-announcements.ts` -- Announcements + mark-read mutations
- `web/src/hooks/use-trainee-badge-counts.ts` -- Unread badge count aggregation

### Types (New)
- `web/src/types/trainee-dashboard.ts` -- WeeklyProgress, LatestWeightCheckIn, Announcement, Achievement

### Modified (Existing)
- `web/src/middleware.ts` -- Added trainee dashboard route guards
- `web/src/lib/constants.ts` -- Added trainee-facing API URL constants
- `web/src/providers/auth-provider.tsx` -- Added TRAINEE to allowed roles

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized (React auto-escaping; no `dangerouslySetInnerHTML`)
- [x] Authentication checked on all new routes (layout-level auth guard + middleware cookie guard)
- [x] Authorization -- correct role/permission guards (TRAINEE role enforced in layout + middleware; non-TRAINEE users redirected)
- [x] No IDOR vulnerabilities (all API endpoints are trainee-scoped server-side; no trainee ID in URLs)
- [x] No file uploads in new components (settings page reuses existing profile-section with proper file type/size validation)
- [x] Rate limiting -- relies on existing backend DRF throttling
- [x] Error messages don't leak internals (generic user-facing error messages throughout)
- [x] CORS policy appropriate (handled globally; no changes in this feature)

## 1. SECRETS Analysis

**Methodology:** Searched all new and modified files for patterns matching `password`, `secret`, `api_key`, `apikey`, `token`, `credential`, `hardcoded`, `.env`, and `process.env`.

**Result: CLEAN**

- Zero hardcoded secrets, API keys, passwords, or tokens found in any new file.
- No `.env` files introduced. Existing `.env.local` is properly gitignored via `.env*.local` pattern.
- `NEXT_PUBLIC_API_URL` is the only environment variable indirectly used (via `web/src/lib/constants.ts`), and it contains only a URL, not a secret.
- JWT tokens are stored in `localStorage` (existing pattern, not introduced by this feature). The `SESSION_COOKIE` and `ROLE_COOKIE` contain only `"1"` and the role string respectively -- no tokens in cookies.

## 2. INJECTION Analysis

### XSS
**Result: CLEAN**

- **No `dangerouslySetInnerHTML`** in any new file. Verified via grep across all 18 new files.
- All user-supplied content (announcement titles/content, exercise names, program names/descriptions, user names, weight values) is rendered through JSX text interpolation (`{variable}`), which React auto-escapes.
- The `announcements-list.tsx` component renders `announcement.content` inside a `<p>` tag with `whitespace-pre-wrap` -- this preserves whitespace formatting without interpreting HTML. Safe.
- The `program-viewer.tsx` renders `selectedProgram.description` and `selectedProgram.goal_type.replace(/_/g, " ")` -- string replacement with a literal pattern, then rendered as JSX text. Safe.

### URL Injection / Open Redirect
**Result: CLEAN**

- `messages/page.tsx` line 48: `parseInt(conversationIdParam, 10)` safely converts the `?conversation=` search parameter to a number. The result is used only to `.find()` against a locally-fetched array. `NaN` will simply not match any conversation. No URL injection vector.
- All `router.replace()` calls use hardcoded internal paths (`/login`, `/admin/dashboard`, `/ambassador/dashboard`, `/dashboard`, `/trainee/messages?conversation=${numericId}`). No user-controlled redirect targets.
- All sidebar links are hardcoded in `trainee-nav-links.tsx` with fixed `/trainee/*` paths. No dynamic href construction from user input.

### Template Injection
**Result: CLEAN**

- No template strings used for HTML rendering. All UI is built via React JSX components.

### SQL Injection
**Result: N/A**

- This is a frontend-only feature. No database queries. All data access goes through existing server-side API endpoints that use Django ORM.

## 3. AUTH/AUTHZ Analysis

### Middleware Guard (`web/src/middleware.ts`)
**Result: CORRECTLY IMPLEMENTED**

The middleware implements a three-layer defense:

1. **Unauthenticated redirect** (line 54): Users without `has_session` cookie are redirected to `/login`. This prevents unauthenticated access to trainee routes.

2. **Non-trainee redirect** (lines 76-80): Users with `has_session` cookie but `user_role !== "TRAINEE"` are redirected away from `/trainee/*` paths. This prevents trainers/admins/ambassadors from accidentally accessing trainee routes.

3. **Trainee containment** (lines 83-89): Users with `user_role === "TRAINEE"` trying to access trainer/admin/ambassador paths are redirected to `/trainee/dashboard`. This prevents trainees from reaching privileged routes.

**Important (correctly documented):** Line 59 contains the comment: `"NOTE: The role cookie is client-writable, so this is a convenience guard only."` This is accurate. The middleware cookie-based guard is a UX convenience, NOT a security boundary. True authorization is enforced by:
- The layout component (server-verified user object)
- The backend API (HTTP 403 on unauthorized requests)

### Layout Guard (`web/src/app/(trainee-dashboard)/layout.tsx`)
**Result: CORRECTLY IMPLEMENTED**

1. **Authentication check** (lines 21-25): Redirects to `/login` when not authenticated.
2. **Role verification** (lines 29-37): Redirects ADMIN, AMBASSADOR, and TRAINER users to their respective dashboards.
3. **Guard render** (line 40): Shows a loading spinner when `isLoading`, not authenticated, or user role is not TRAINEE. This prevents any flash of trainee content for non-trainee users.
4. The `user` object comes from `useAuth()` which fetches from the server (`/api/auth/users/me/`), so the role check is based on server-verified data, not the client-writable cookie.

### Auth Provider (`web/src/providers/auth-provider.tsx`)
**Result: CORRECTLY IMPLEMENTED**

- Line 48: `userData.role === UserRole.TRAINEE` is in the `isAllowedRole` check, allowing trainees to use the web dashboard.
- Line 51: Users with unsupported roles have their tokens cleared and are rejected.
- The role verification uses server-returned data from the JWT-authenticated `/api/auth/users/me/` endpoint.

### API Endpoint Scope
**Result: ALL ENDPOINTS ARE TRAINEE-SAFE**

Every API URL used by the trainee dashboard hooks hits trainee-accessible endpoints:

| Hook | API Endpoint | Backend Auth |
|------|-------------|--------------|
| `useTraineeDashboardPrograms` | `/api/workouts/programs/` | `IsAuthenticated`, queryset filtered by `trainee=user` |
| `useTraineeDashboardNutrition` | `/api/workouts/daily-logs/nutrition-summary/` | `IsAuthenticated`, scoped to requesting user |
| `useTraineeWeeklyProgress` | `/api/workouts/daily-logs/weekly-progress/` | `IsAuthenticated`, scoped to requesting user |
| `useTraineeLatestWeight` | `/api/workouts/weight-checkins/latest/` | `IsAuthenticated`, scoped to requesting user |
| `useTraineeWeightHistory` | `/api/workouts/weight-checkins/` | `IsAuthenticated`, scoped to requesting user |
| `useAnnouncements` | `/api/community/announcements/` | `IsAuthenticated`, scoped to trainee's trainer |
| `useAnnouncementUnreadCount` | `/api/community/announcements/unread-count/` | `IsAuthenticated`, scoped |
| `useMarkAnnouncementsRead` | `/api/community/announcements/mark-read/` | `IsAuthenticated`, scoped |
| `useMarkAnnouncementRead` | `/api/community/announcements/{id}/mark-read/` | `IsAuthenticated`, scoped |
| `useAchievements` | `/api/community/achievements/` | `IsAuthenticated`, scoped |
| `useConversations` | `/api/messaging/conversations/` | `IsAuthenticated`, participant-scoped |
| `useMessagingUnreadCount` | `/api/messaging/unread-count/` | `IsAuthenticated`, scoped |

No trainee dashboard hook calls trainer-only (`/api/trainer/`) or admin-only (`/api/admin/`) endpoints. The `use-trainee-goals.ts` hook does call `/api/trainer/trainees/{id}/goals/`, but this hook is NOT imported or used anywhere in the trainee dashboard -- it's a pre-existing hook used only in the trainer's trainee-detail view.

## 4. DATA EXPOSURE Analysis

### Type Definitions
**Result: CLEAN**

The `trainee-dashboard.ts` types expose only appropriate fields:
- `WeeklyProgress`: `total_days`, `completed_days`, `percentage` -- numeric stats only.
- `LatestWeightCheckIn`: `id`, `trainee` (own ID), `date`, `weight_kg`, `notes`, `created_at` -- trainee's own data.
- `Announcement`: `id`, `trainer` (trainer ID), `title`, `content`, `is_pinned`, `is_read`, timestamps -- announcement content only.
- `Achievement`: `id`, `name`, `description`, `icon`, `criteria_type`, `criteria_value`, `earned`, `earned_at`, `progress` -- achievement metadata only.

No sensitive fields (passwords, payment info, emails of other users, internal IDs of unrelated resources) are present.

### Shared Types
The `TraineeViewProgram` type (from `trainee-view.ts`, pre-existing) includes:
- `trainee_email`: The trainee's own email (from their own program).
- `created_by_email`: The trainer's email (the trainee already knows their trainer).
- `created_by`: Trainer's user ID.

These are acceptable: the trainee has a direct relationship with their trainer, so this is not cross-user data leakage.

### Error Messages
**Result: CLEAN**

All error messages shown to users are generic:
- "Failed to load workout" / "Failed to load nutrition" / "Failed to load weight data" / "Failed to load progress"
- "Failed to load your program. Please try again."
- "Failed to load achievements. Please try again."
- "Failed to load announcements. Please try again."
- "Failed to load conversations. Please try again."
- "Failed to load settings"

No API error details, stack traces, or internal structure information is exposed to the user.

### API Error Handling
The `ApiError` class (in `api-client.ts`, pre-existing) stores `status`, `statusText`, and `body`. The error body from DRF may contain field-level validation errors. In the trainee dashboard, API errors are caught by React Query's `isError` state and displayed with generic messages. The `SecuritySection` (shared, pre-existing) does display server-side validation messages for password changes, but these are standard DRF field validation messages (e.g., "This password is too common") -- not internal system details.

## 5. CORS/CSRF Analysis

**Result: NO ISSUES**

- **CORS**: Handled globally in Django's `settings.py` via `django-cors-headers`. No CORS changes in this feature.
- **CSRF**: Not applicable -- the web frontend uses JWT Bearer token authentication via `Authorization` header, not session cookies. DRF's `SessionAuthentication` is not in `DEFAULT_AUTHENTICATION_CLASSES`, so CSRF middleware is not engaged for API requests.
- **Next.js security headers** (in `next.config.ts`, pre-existing): X-Frame-Options: DENY, X-Content-Type-Options: nosniff, Referrer-Policy: strict-origin-when-cross-origin, Permissions-Policy restricts camera/microphone/geolocation, poweredByHeader: false. All correctly configured.

## 6. CLIENT-SIDE SECURITY Analysis

### Cookie-Based Middleware Guard
**Result: CORRECTLY DOCUMENTED**

- The middleware guard at line 59 of `middleware.ts` explicitly documents: `"NOTE: The role cookie is client-writable, so this is a convenience guard only. True authorization is enforced server-side by the API (HTTP 403) and by the layout component which verifies the role from the authenticated user object."`
- This is the correct approach for Next.js middleware. Cookie manipulation cannot bypass actual authorization because:
  1. API calls require a valid JWT token (not the cookie).
  2. The layout component verifies the role from the server-authenticated user object (fetched via JWT).
  3. Backend endpoints enforce their own auth/authz regardless of frontend routing.

### Cookie Manipulation Scenarios
**Scenario 1: Non-trainee sets `user_role=TRAINEE` cookie:**
- Middleware allows access to `/trainee/*` routes.
- Layout fetches user from API using JWT, gets actual role (e.g., TRAINER).
- Layout redirects to `/dashboard` (line 35). No trainee content rendered.

**Scenario 2: Trainee sets `user_role=ADMIN` cookie:**
- Middleware allows access to `/admin/*` routes.
- Admin layout (not part of this feature) fetches user from API, gets TRAINEE role.
- Admin layout redirects to trainee dashboard. No admin content rendered.

**Scenario 3: Unauthenticated user sets `has_session=1` cookie:**
- Middleware allows access to protected routes.
- Layout calls `useAuth()`, which calls API with no valid JWT token.
- API returns 401. Auth provider clears tokens, sets `user=null`.
- Layout redirects to `/login`. No protected content rendered.

All cookie manipulation scenarios are safely handled.

### Token Storage
JWT tokens are stored in `localStorage` (pre-existing pattern). While `localStorage` is vulnerable to XSS attacks (if XSS were present), this feature introduces no XSS vectors (see Section 2). Moving to `httpOnly` cookies would be a stronger pattern, but this is a pre-existing architectural decision outside the scope of this feature.

## Injection Vulnerabilities

| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

## Auth & Authz Issues

| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

## Security Issues Found

### Critical Issues
None.

### High Issues
None.

### Medium Issues
None.

### Low Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 1 | **Low** | URL parameter encoding | `web/src/hooks/use-trainee-dashboard.ts:37` | The `date` parameter is interpolated directly into the URL without `encodeURIComponent()`: `` `${API_URLS.TRAINEE_NUTRITION_SUMMARY}?date=${date}` ``. While the `date` value is generated internally from `new Date()` (not user input) and always produces a safe `YYYY-MM-DD` string, using `encodeURIComponent()` or `URLSearchParams` would be a defensive coding practice. | Consider using `new URLSearchParams({ date }).toString()` for consistency with other hooks (e.g., `use-messaging.ts` uses `URLSearchParams`). No security impact in current code. |
| 2 | **Low** | Pre-existing debug endpoint | `backend/workouts/views.py:329-357` | The `ProgramViewSet.debug` action at `/api/workouts/programs/debug/` is accessible to any authenticated user and exposes user details (email, role, parent_trainer_email). Not introduced by this feature, but the trainee dashboard user could hit this endpoint. | Remove the `debug` action or restrict it to admin-only. (Carried over from prior audit.) |

### Info Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 3 | **Info** | localStorage for JWTs | `web/src/lib/token-manager.ts:44` | JWT tokens stored in `localStorage` are accessible to any JavaScript running on the same origin. If an XSS vulnerability were introduced in the future, tokens could be exfiltrated. This is a pre-existing architectural pattern, not introduced by this feature. | Consider migrating to `httpOnly` cookies for token storage in a future security hardening pass. |
| 4 | **Info** | Profile image upload reuse | `web/src/components/settings/profile-section.tsx:60-88` | The trainee settings page reuses the shared `ProfileSection` component which includes profile image upload. File type validation (JPEG/PNG/GIF/WebP) and size validation (5MB max) are implemented client-side. Server-side validation is also present in the existing backend endpoint. The `business_name` field is correctly hidden for TRAINEE role users (line 187). | No action needed -- properly implemented. |

## Summary

The Trainee Web Portal (Pipeline 32) has an **excellent security posture**:

1. **No secrets leaked** -- zero hardcoded credentials, API keys, or tokens in any new file.

2. **No injection vectors** -- no `dangerouslySetInnerHTML`, no raw HTML rendering, no template injection. All user content is rendered through React's auto-escaping JSX. URL parameters are either hardcoded or safely parsed.

3. **Strong auth/authz** -- three-layer defense: (1) middleware cookie guard (convenience), (2) layout-level server-verified role check (security), (3) backend API auth enforcement (authoritative). The cookie guard is correctly documented as convenience-only. Cookie manipulation cannot bypass authorization.

4. **No data exposure** -- type definitions contain only trainee-appropriate fields. Error messages are generic. No internal system details leaked.

5. **Correct API scoping** -- all hooks call trainee-accessible endpoints (`/api/workouts/`, `/api/community/`, `/api/messaging/`). No hooks call trainer-only or admin-only endpoints. Backend queryset filtering ensures trainees see only their own data.

6. **Good security headers** -- X-Frame-Options: DENY, X-Content-Type-Options: nosniff, Referrer-Policy, Permissions-Policy all correctly configured via Next.js config.

7. **No CORS/CSRF concerns** -- JWT Bearer auth is used (not session cookies). CORS handled globally.

## Security Score: 9/10

The 1-point deduction is for the pre-existing `ProgramViewSet.debug` endpoint (Low severity, not introduced by this feature) and the pre-existing `localStorage` JWT storage pattern. Neither was introduced by Pipeline 32.

## Recommendation: PASS
