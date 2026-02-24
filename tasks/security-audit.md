# Security Audit: Trainee Web -- Trainer Branding Application (Pipeline 34)

## Audit Date
2026-02-23

## Scope
Frontend-only feature: new hook (`use-trainee-branding.ts`), modified components (`trainee-sidebar.tsx`, `trainee-sidebar-mobile.tsx`). Applies trainer's white-label branding (app name, logo URL, primary color) to the trainee web portal sidebars. No backend changes -- the `MyBrandingView` endpoint at `GET /api/users/my-branding/` already exists with `[IsAuthenticated, IsTrainee]` permission classes.

## Files Audited

### New Files
- `web/src/hooks/use-trainee-branding.ts` -- React Query hook to fetch trainee's trainer branding

### Modified Files
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` -- Desktop sidebar with branding (logo, name, active link color)
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` -- Mobile sidebar sheet with branding

### Supporting Files Reviewed (Pre-existing, for context)
- `web/src/lib/api-client.ts` -- API client with JWT auth
- `web/src/lib/constants.ts` -- `TRAINEE_BRANDING` URL constant
- `web/src/types/branding.ts` -- `TraineeBranding` type definition
- `web/next.config.ts` -- Next.js image remote patterns and security headers
- `backend/users/views.py:379-411` -- `MyBrandingView` endpoint
- `backend/trainer/serializers.py:325-359` -- `TrainerBrandingSerializer` with validation
- `backend/trainer/models.py:330-379` -- `TrainerBranding` model with hex color validators
- `backend/core/permissions.py:19-27` -- `IsTrainee` permission class

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized (React auto-escaping; no `dangerouslySetInnerHTML`)
- [x] Authentication checked on all new endpoints (pre-existing endpoint uses `[IsAuthenticated, IsTrainee]`)
- [x] Authorization -- correct role/permission guards (TRAINEE role enforced; row-level security returns only own trainer's branding)
- [x] No IDOR vulnerabilities (endpoint derives trainer from `request.user.parent_trainer` -- no user-supplied trainer ID)
- [x] Error messages don't leak internals (API errors handled by generic `apiClient` error flow)

---

## 1. SECRETS Analysis

**Methodology:** Searched all new and modified files for patterns matching `password`, `secret`, `api_key`, `apikey`, `token`, `credential`, `bearer`, `sk_`, `pk_`, `ghp_`, `gho_`. Also searched git diff of tasks files.

**Result: CLEAN**

- Zero hardcoded secrets, API keys, passwords, or tokens found in any new or modified file.
- No `.env` files introduced or modified.
- `constants.ts` addition is a single URL path constant (`TRAINEE_BRANDING`) -- no secrets.
- Task files contain no actual secret values.

---

## 2. INJECTION Analysis

### 2.1 XSS via `app_name`

**Result: SAFE -- Defense in Depth**

The trainer-supplied `app_name` string flows through:

1. **Backend model**: `CharField(max_length=50)` -- length-limited at the database level.
2. **Backend serializer**: `validate_app_name()` strips all HTML tags via `re.sub(r'<[^>]+>', '', value)` before storage.
3. **Frontend rendering**: Displayed via JSX text interpolation `{displayName}` in:
   - `trainee-sidebar.tsx` line 89: `<span>{displayName}</span>`
   - `trainee-sidebar-mobile.tsx` line 65: `<SheetTitle>{displayName}</SheetTitle>`

   React auto-escapes all text content in JSX -- no `dangerouslySetInnerHTML` is used anywhere.

4. **Additional safeguard**: `getBrandingDisplayName()` calls `.trim()` and falls back to `"FitnessAI"` for empty strings.

Verified: `grep -rn dangerouslySetInnerHTML` across the entire trainee-dashboard directory returns zero results.

### 2.2 CSS Injection via `primary_color`

**Result: SAFE -- Backend Regex + React Style Object**

The trainer-supplied `primary_color` is used in inline styles in two patterns:

- `{ backgroundColor: \`${branding.primary_color}20\` }` (active link background with alpha)
- `{ color: branding.primary_color }` (active link icon color)

**Why this is safe:**

1. **Backend validation is strict**: `HEX_COLOR_REGEX = re.compile(r'^#[0-9A-Fa-f]{6}$')` enforces exactly a 7-character hex color (e.g. `#6366F1`). Any CSS injection payload (containing semicolons, `url()`, `expression()`, `var()`, etc.) will be rejected by both:
   - Model-level validator: `validate_hex_color()` raises `ValidationError`
   - Serializer-level validator: `validate_primary_color()` raises `ValidationError`

2. **React's style object is inherently safe**: The `style` prop uses a JavaScript object assigned to `element.style.color = value` via the DOM API, NOT raw CSS string concatenation. Even if a malicious value bypassed the backend (hypothetically), the DOM API silently ignores values containing semicolons or other injection payloads.

3. **Gated by `hasCustomPrimaryColor()`**: The inline style is only applied when `hasCustomPrimaryColor()` returns `true`, which means `primary_color` differs from the default `#6366F1`. This function also calls `.toLowerCase()` which is safe against any case-based bypass.

### 2.3 Image URL (`logo_url`) -- SSRF / Open Redirect

**Result: SAFE**

- `logo_url` is NOT a user-supplied raw URL. It is constructed by Django's `request.build_absolute_uri(obj.logo.url)` from an `ImageField` file upload. The URL points to the Django media storage backend.
- The `Image` component uses `unoptimized` which bypasses Next.js image optimization proxy -- no SSRF risk from the optimizer fetching arbitrary external URLs.
- Both sidebar components implement `onError` fallback: on image load failure, they gracefully fall back to the default `Dumbbell` icon.
- `BrandLogo` component (trainee-sidebar.tsx line 27-52) also handles `null` URL gracefully.

### 2.4 Template / Command / SQL Injection

**Result: N/A**

- No template strings used for HTML rendering. All UI is built via React JSX.
- No backend changes in this feature. No command execution. No SQL queries.

---

## 3. AUTH/AUTHZ Analysis

### Backend Endpoint
**Result: CORRECTLY IMPLEMENTED**

The `MyBrandingView` (`backend/users/views.py:379-411`) has:
- `permission_classes = [IsAuthenticated, IsTrainee]` -- only authenticated trainees can access.
- Row-level security: `user.parent_trainer` derives the trainer from the authenticated user's FK. No user-supplied trainer ID parameter.
- Returns default branding if trainee has no parent trainer or trainer has no branding configured.

### Frontend Route Protection
**Result: CORRECTLY IMPLEMENTED**

The sidebar components live inside the `(trainee-dashboard)` route group, protected by:
1. `middleware.ts` -- cookie-based convenience guard
2. `layout.tsx` -- server-verified role check
3. Backend API -- JWT authentication + row-level security

### IDOR Analysis
**Result: NO IDOR VULNERABILITIES**

- The endpoint is `GET /api/users/my-branding/` with no URL parameters. The trainer is derived from `request.user.parent_trainer`. There is no way for a trainee to specify another trainer's ID.
- The serializer exposes only: `app_name`, `primary_color`, `secondary_color`, `logo_url`, `created_at`, `updated_at`. No trainer email, ID, or other sensitive data.

---

## 4. DATA EXPOSURE Analysis

### API Response Fields
**Result: CLEAN**

The `TrainerBrandingSerializer` exposes only branding-specific fields:
- `app_name` (string, max 50 chars)
- `primary_color` (hex color string)
- `secondary_color` (hex color string)
- `logo_url` (absolute URL to uploaded image or null)
- `created_at`, `updated_at` (timestamps)

No sensitive fields (trainer email, trainer ID, financial data, other trainees' data) are exposed.

### Error Messages
**Result: CLEAN**

On API failure, the `useQuery` hook relies on the generic `apiClient` error handling which throws `ApiError` with generic messages. The sidebar components handle loading/error states by showing skeleton loaders or falling back to default branding -- no error details exposed to the user.

### Console Logging
**Result: CLEAN**

Zero `console.log`, `console.warn`, `console.error` statements in any new or modified file.

---

## 5. CORS/CSRF Analysis

**Result: NO ISSUES**

- No new CORS configuration. All API calls go through the existing `apiClient` with JWT Bearer token authentication.
- No hardcoded URLs -- uses `API_URLS.TRAINEE_BRANDING` constant.
- CSRF: not applicable -- JWT Bearer auth, not session cookies.

---

## 6. Next.js Image Configuration (Pre-existing Observation)

**Result: LOW -- PRE-EXISTING, NOT INTRODUCED BY THIS FEATURE**

`web/next.config.ts` line 42-44 has an overly permissive remote pattern:
```typescript
{
  protocol: "http",
  hostname: "**",
}
```

This allows Next.js `<Image>` to load images from any HTTP host. However:
- The `unoptimized` prop on the branding images means Next.js does NOT proxy/fetch these images server-side -- the browser loads them directly.
- The `logo_url` is always a backend-generated absolute URL pointing to the same origin (Django media files).
- This is a pre-existing configuration, not introduced by Pipeline 34.
- **Recommendation for future:** Restrict `remotePatterns` to known hosts (localhost, production backend domain).

---

## Injection Vulnerabilities

| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

## Auth & Authz Issues

| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

---

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
| 1 | **Low** | Defense-in-depth | `web/src/hooks/use-trainee-branding.ts:39-40` | `hasCustomPrimaryColor()` validates that the color differs from default, but does not validate the hex format on the frontend. If a compromised/intercepted API response returned a non-hex `primary_color`, it would be used in inline styles. | Consider adding a frontend hex regex check (e.g., `/^#[0-9A-Fa-f]{6}$/`) in `hasCustomPrimaryColor()` or a separate sanitizer. The backend's strict regex validation makes exploitation extremely unlikely. |
| 2 | **Low** | Pre-existing | `web/next.config.ts:42-44` | Overly permissive `remotePatterns` (`hostname: "**"` for HTTP) allows Next.js `<Image>` to load from any host. Not exploitable in this feature due to `unoptimized` prop and backend-controlled URLs, but weakens the overall security posture. | Restrict `remotePatterns` to known backend hostnames in a future security hardening pass. |

### Info Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 3 | **Info** | localStorage for JWTs | `web/src/lib/token-manager.ts` | JWT tokens stored in `localStorage` are accessible to any JavaScript on the same origin. Pre-existing pattern, not introduced by this feature. | Consider migrating to `httpOnly` cookies in a future security hardening pass. |

---

## Fixes Applied During This Audit

No fixes were necessary. All code in this feature is secure as implemented.

---

## Summary

Pipeline 34 (Trainee Web -- Trainer Branding Application) has an **excellent security posture**:

1. **No secrets leaked** -- zero hardcoded credentials in any new or modified file.

2. **No XSS vectors** -- `app_name` is rendered via React JSX auto-escaping (no `dangerouslySetInnerHTML`). Backend additionally strips HTML tags from `app_name` before storage.

3. **No CSS injection** -- `primary_color` is strictly validated on the backend with `^#[0-9A-Fa-f]{6}$` regex. Frontend uses React's `style` object (not string concatenation), which is inherently immune to CSS injection.

4. **No image URL exploitation** -- `logo_url` is a backend-generated absolute URL from Django's `ImageField` storage, not a user-supplied arbitrary URL. `onError` fallback handles broken images gracefully.

5. **Strong auth/authz** -- `MyBrandingView` requires `[IsAuthenticated, IsTrainee]`. Row-level security derives the trainer from `request.user.parent_trainer` with no user-supplied parameters. No IDOR possible.

6. **No data exposure** -- API response contains only branding fields (app_name, colors, logo_url, timestamps). No sensitive trainer data or other trainee data exposed.

7. **No CORS/CSRF concerns** -- JWT Bearer auth, centralized URL constants, no new CORS configuration.

## Security Score: 9/10

The 1-point deduction is for:
- Low: No frontend-side hex color validation (defense-in-depth; backend validation is strict, so real-world risk is negligible).
- Low: Pre-existing overly permissive Next.js `remotePatterns` (not introduced by this feature).
- Info: Pre-existing `localStorage` JWT storage (not introduced by this feature).

## Recommendation: PASS
