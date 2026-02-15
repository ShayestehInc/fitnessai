# Security Audit: Web Dashboard Phase 2 (Pipeline 10)

**Date:** 2026-02-15
**Auditor:** Security Engineer (Senior Application Security)
**Pipeline:** 10
**Scope:** Settings Page, Progress Charts, Notification Click-Through, Invitation Row Actions

**New Files Audited:**
- `web/src/hooks/use-settings.ts` -- Mutation hooks for profile update, image upload, password change
- `web/src/hooks/use-progress.ts` -- Query hook for trainee progress data
- `web/src/types/progress.ts` -- TypeScript types for progress API response
- `web/src/components/settings/profile-section.tsx` -- Profile form with image upload
- `web/src/components/settings/appearance-section.tsx` -- Theme toggle
- `web/src/components/settings/security-section.tsx` -- Password change form
- `web/src/components/trainees/progress-charts.tsx` -- Chart components (Weight, Volume, Adherence)
- `web/src/components/invitations/invitation-actions.tsx` -- Dropdown menu with Copy/Resend/Cancel

**Modified Files Audited:**
- `web/src/providers/auth-provider.tsx` -- Added `refreshUser` to context value
- `web/src/lib/api-client.ts` -- Added `postFormData()` method, FormData Content-Type fix
- `web/src/lib/constants.ts` -- New API endpoint URLs
- `web/src/hooks/use-invitations.ts` -- Added `useResendInvitation()` and `useCancelInvitation()`
- `web/src/components/notifications/notification-item.tsx` -- Added `getNotificationTraineeId()` helper, ChevronRight indicator
- `web/src/components/notifications/notification-popover.tsx` -- Click-through navigation with `onClose` prop
- `web/src/components/notifications/notification-bell.tsx` -- Controlled Popover state
- `web/src/app/(dashboard)/notifications/page.tsx` -- Click-through navigation via `useRouter`
- `web/src/app/(dashboard)/settings/page.tsx` -- Replaced placeholder with settings sections
- `web/src/components/trainees/trainee-progress-tab.tsx` -- Replaced placeholder with chart components
- `web/src/app/(dashboard)/trainees/[id]/page.tsx` -- Passes `trainee.id` to progress tab
- `web/src/components/invitations/invitation-columns.tsx` -- Added actions column

---

## Executive Summary

This audit covers the Phase 2 features added to the web trainer dashboard: Settings page (profile edit, image upload, password change), trainee progress charts, notification click-through navigation, and invitation row actions. All changes are frontend-only (Next.js/React).

The implementation follows strong security practices: all API calls use JWT Bearer authentication, user input is validated client-side, no XSS vectors introduced, file upload validates type and size, password fields use proper `type="password"` and `autoComplete` attributes, and navigation paths are constructed from validated integer IDs only.

**No Critical or High issues were found. No fixes required.**

**Issues Found:**
- 0 Critical
- 0 High
- 0 Medium
- 4 Low / Informational

---

## Security Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (`.env.local` is in `.gitignore`, verified not tracked)
- [x] All user input sanitized (file type/size validation, password length validation, React auto-escaping)
- [x] Authentication checked on all new API calls (all use `apiClient` which injects Bearer token)
- [x] Authorization -- correct role/permission guards (existing three-layer TRAINER gating applies to all new pages)
- [x] No IDOR vulnerabilities (backend row-level security enforced; frontend passes typed numeric IDs)
- [x] File uploads validated (5MB size limit, MIME type whitelist: JPEG, PNG, GIF, WebP)
- [x] Rate limiting on sensitive endpoints (backend DRF throttling: 5/hr password change via registration throttle)
- [x] Error messages don't leak internals (generic toasts like "Failed to update profile")
- [x] CORS policy appropriate (unchanged from Pipeline 9 -- production restricts origins)

---

## Secrets Scan

### Scan Methodology

Grepped all new and modified files for:
- API keys, secret keys, passwords, tokens: `(api[_-]?key|secret[_-]?key|password|token|credential)\s*[=:]\s*['"][A-Za-z0-9]`
- Provider-specific patterns: `(sk-|pk_|rk_|AIza|ghp_|gho_|AKIA|aws_)`
- Hardcoded URLs with embedded credentials

### Results: PASS

No secrets, API keys, passwords, or tokens found in any new or modified files. The only matches for "password" are UI label strings and validation error messages (e.g., `"Password must be at least 8 characters"`), which is expected and safe.

---

## Injection Vulnerabilities

### XSS: PASS

| Vector | Status | Evidence |
|--------|--------|----------|
| `dangerouslySetInnerHTML` | Not used | `grep` returned zero matches across entire `web/src/` |
| `innerHTML` / `outerHTML` / `__html` | Not used | `grep` returned zero matches |
| `eval()` / `new Function()` | Not used | `grep` returned zero matches |
| React JSX interpolation | Safe | All dynamic content rendered via `{variable}` in JSX (React auto-escapes) |
| `invitation.email` in Dialog | Safe | Rendered inside `<strong>{invitation.email}</strong>` -- React text node, auto-escaped |
| `notification.title` / `.message` | Safe | Rendered via JSX text nodes with `title` attribute for truncation tooltips |
| `user.profile_image` in `<img src>` | Safe | Server-controlled URL, rendered via React `<AvatarImage src={...}>` (no script execution) |

**Analysis:** No new XSS vectors introduced. All user-controlled data (notification titles, invitation emails, user names, profile image URLs) is rendered through React's default text-node escaping. No unsafe DOM APIs used.

### Open Redirect: PASS

Two new `router.push()` calls added for notification click-through:

```typescript
// notification-popover.tsx:32
router.push(`/trainees/${traineeId}`);

// notifications/page.tsx:50
router.push(`/trainees/${traineeId}`);
```

The `traineeId` is strictly validated by `getNotificationTraineeId()`:
1. If `typeof raw === "number"` and `raw > 0` -- returns the number
2. If `typeof raw === "string"` -- `parseInt(raw, 10)`, must not be `NaN` and must be `> 0`
3. Otherwise returns `null` (no navigation occurs)

This means only positive integers can be inserted into the path template. Inputs like `"../admin"`, `"javascript:alert(1)"`, or `"//evil.com"` all fail `parseInt()` (return `NaN`) and are rejected. No open redirect or path traversal is possible.

### Path Traversal: PASS

All new API URL builder functions use typed `number` parameters:
```typescript
traineeProgress: (id: number) => `${API_BASE}/api/trainer/trainees/${id}/progress/`,
invitationDetail: (id: number) => `${API_BASE}/api/trainer/invitations/${id}/`,
invitationResend: (id: number) => `${API_BASE}/api/trainer/invitations/${id}/resend/`,
```

TypeScript enforces the `number` type at compile time. Runtime callers pass `invitation.id` and `traineeId` (validated positive integers).

---

## Auth & Authz Issues

### Authentication on New Endpoints: PASS

All new API calls go through `apiClient` methods, which inject the Bearer token via `getAuthHeaders()`:

| Hook | Method | Endpoint | Auth |
|------|--------|----------|------|
| `useUpdateProfile` | `apiClient.patch` | `PATCH /api/users/me/` | Bearer |
| `useUploadProfileImage` | `apiClient.postFormData` | `POST /api/users/profile-image/` | Bearer |
| `useDeleteProfileImage` | `apiClient.delete` | `DELETE /api/users/profile-image/` | Bearer |
| `useChangePassword` | `apiClient.post` | `POST /api/auth/users/set_password/` | Bearer |
| `useTraineeProgress` | `apiClient.get` | `GET /api/trainer/trainees/<id>/progress/` | Bearer |
| `useResendInvitation` | `apiClient.post` | `POST /api/trainer/invitations/<id>/resend/` | Bearer |
| `useCancelInvitation` | `apiClient.delete` | `DELETE /api/trainer/invitations/<id>/` | Bearer |

No unauthenticated API calls were introduced. The `postFormData()` method correctly goes through the same `request()` function with `getAuthHeaders()`.

### Authorization: PASS

The new settings page is under the `(dashboard)` route group, which is protected by:
1. Middleware cookie check
2. Dashboard layout `isAuthenticated` guard
3. Auth provider TRAINER role validation

The progress endpoint (`/api/trainer/trainees/<id>/progress/`) is scoped under the trainer namespace, which the backend filters by `request.user` (trainers can only see their own trainees' progress).

### IDOR: PASS (Frontend)

- **Profile update/image/password:** Operates on `me/` endpoints -- the backend identifies the user from the JWT, not a URL parameter. No IDOR possible.
- **Trainee progress:** Uses `trainee.id` from the already-fetched trainee object. Backend enforces row-level security.
- **Invitation actions:** Uses `invitation.id` from the table data. Backend verifies the invitation belongs to the authenticated trainer.

---

## File Upload Security

### Profile Image Upload: PASS

**Client-side validation** in `profile-section.tsx:52-69`:

| Check | Implementation | Status |
|-------|---------------|--------|
| File size | `file.size > 5 * 1024 * 1024` rejects files over 5MB | PASS |
| MIME type | Whitelist: `image/jpeg`, `image/png`, `image/gif`, `image/webp` | PASS |
| HTML `accept` attribute | `accept="image/jpeg,image/png,image/gif,image/webp"` on file input | PASS |
| FormData transmission | Uses `apiClient.postFormData()` which sets `multipart/form-data` boundary automatically | PASS |
| Content-Type header | `buildHeaders()` skips `Content-Type: application/json` when body is `FormData` (lets browser set boundary) | PASS |

**Analysis:** Client-side validation is defense-in-depth. The backend must also validate file type/size (which it does via Django's file upload validators). The frontend prevents obviously invalid uploads from reaching the server, improving UX and reducing unnecessary bandwidth.

**Note:** The client-side MIME type check relies on `file.type`, which is set by the browser based on the file extension. A sophisticated attacker could bypass this by renaming a file. However, this is only a client-side convenience check -- the backend performs its own validation and is the authoritative security boundary.

---

## Password Change Security

### Security Section: PASS

| Check | Implementation | Status |
|-------|---------------|--------|
| `type="password"` | All three password fields use `type="password"` | PASS |
| `autoComplete` attributes | `current-password` and `new-password` -- correct per HTML spec | PASS |
| Minimum length | Client-side: 8 characters (matches Django default) | PASS |
| Confirm match | `newPassword !== confirmPassword` check | PASS |
| `maxLength` | 128 characters on all fields (prevents DoS via bcrypt/argon2 with huge inputs) | PASS |
| Error handling | Djoser field errors parsed and shown inline; generic toast for unknown errors | PASS |
| Form clear on success | All fields cleared on successful password change | PASS |
| No password logging | No `console.log` in settings hooks or components | PASS |
| Rate limiting | Backend Djoser endpoint has DRF throttling | PASS |

**Analysis:** The password change form follows security best practices. Sensitive field values are cleared from state on success. Error messages from Djoser are parsed for field-specific errors (e.g., "wrong current password") but no password values are leaked in error messages.

---

## Data Exposure

### API Response Fields: PASS

New response types introduced:
- `UpdateProfileResponse`: `{ success: boolean, user: User }` -- same User type as before, no new sensitive fields
- `ProfileImageResponse`: `{ success: boolean, profile_image: string | null, user: User }` -- only URL, not file contents
- `TraineeProgress`: `{ weight_progress, volume_progress, adherence_progress }` -- fitness data, no PII

### Error Messages: PASS

All new error messages are generic:
- `"Failed to update profile"` / `"Profile updated"`
- `"Failed to upload image"` / `"Image must be under 5MB"` / `"Only JPEG, PNG, GIF, and WebP are allowed"`
- `"Failed to change password"` / `"Password changed successfully"`
- `"Failed to load progress data"`
- `"Failed to resend invitation"` / `"Failed to cancel invitation"`

The Djoser password error handling deserializes `error.body` into field-specific messages, but these come from Django's password validators (e.g., "This password is too common", "Incorrect password") and do not leak server internals.

---

## Dependencies

### New Dependency: recharts ^3.7.0

| Check | Status |
|-------|--------|
| Known CVEs | No known CVEs for recharts (checked Snyk, NVD) |
| Maintenance | Actively maintained, 6M+ weekly downloads |
| Attack surface | Client-side charting only, no network requests, no DOM manipulation outside React |

### Existing Dependencies: PASS

| Package | Version | Status |
|---------|---------|--------|
| next | 16.1.6 | Patched for CVE-2025-66478 (fix was in 16.0.7) |
| react / react-dom | 19.2.3 | Patched for CVE-2025-55182 (fix was in 19.2.1) |
| All others | Unchanged | No new CVEs since Pipeline 9 audit |

---

## Low / Informational Items

### 1. Client-Side File Type Validation Is Bypassable (Low)

**File:** `web/src/components/settings/profile-section.tsx:61-68`
**Status:** ACCEPTABLE -- defense in depth

The MIME type check uses `file.type`, which is browser-derived from the file extension. An attacker could rename a malicious file to `.jpg`. However, the backend performs its own validation (file content sniffing, extension check, size limit), so this is purely a UX convenience on the frontend.

### 2. Clipboard API Requires HTTPS in Some Browsers (Low)

**File:** `web/src/components/invitations/invitation-actions.tsx:44-52`
**Status:** ACCEPTABLE

`navigator.clipboard.writeText()` requires a secure context (HTTPS) in some browsers. The code has a proper `.then(success, failure)` pattern and a try/catch fallback, so failures are handled gracefully with an error toast.

### 3. Notification `data` Field Typing Is Loose (Informational)

**File:** `web/src/types/notification.ts:19`
**Status:** ACCEPTABLE

The `data` field is typed as `Record<string, unknown>`, which is appropriate since the backend sends varying JSON payloads. The `getNotificationTraineeId()` helper properly validates the `trainee_id` field at runtime before using it, handling both `number` and `string` types defensively.

### 4. JWT in localStorage (Pre-Existing, Informational)

**Status:** UNCHANGED from Pipeline 9

JWT tokens continue to be stored in `localStorage`. This is an accepted tradeoff for SPA architecture. No new XSS vectors were introduced that could enable token theft. The `refreshUser()` function added to the auth context does not expose tokens -- it re-fetches the user profile via the authenticated API client.

---

## Security Strengths of This Implementation

1. **No new XSS vectors** -- Zero usage of `dangerouslySetInnerHTML`, `eval`, `innerHTML`, or any unsafe DOM API in any new or modified file.

2. **Authenticated API client for all calls** -- The `postFormData()` method correctly reuses the same `request()` flow with Bearer token injection, maintaining consistent auth.

3. **FormData Content-Type handling** -- Correctly avoids setting `Content-Type: application/json` for FormData requests, letting the browser set the proper `multipart/form-data` with boundary. This prevents request corruption and potential security issues from mismatched content types.

4. **Password field hygiene** -- Proper `type="password"`, correct `autoComplete` values, `maxLength` cap, and form state clearing on success.

5. **Validated navigation targets** -- `getNotificationTraineeId()` strictly validates `trainee_id` as a positive integer before constructing any navigation path, preventing open redirect and path traversal.

6. **Defensive error handling** -- All mutations use `onError` callbacks with generic user-facing messages. The Djoser password error parsing extracts field-specific validation messages without leaking server internals.

7. **File upload defense in depth** -- Client-side size and type validation reduces attack surface, while the backend remains the authoritative validation boundary.

8. **No console.log or debug output** -- No sensitive data logged to browser console.

9. **Typed API URL construction** -- All new endpoint functions use `number` parameters, preventing injection in URL paths.

10. **Cache invalidation via refreshUser()** -- Profile and image updates trigger `refreshUser()` which re-fetches the current user via the authenticated API, ensuring the UI reflects the latest server state without storing stale data.

---

## Security Score: 9/10

**Breakdown:**
- **Authentication:** 10/10 (all new endpoints use Bearer auth, FormData path included)
- **Authorization:** 10/10 (settings on `me/` endpoints, progress/invitations behind trainer namespace)
- **Input Validation:** 9/10 (file upload validation, password validation, typed IDs, navigation target validation)
- **Output Encoding:** 10/10 (React auto-escaping, no unsafe HTML rendering)
- **Secrets Management:** 10/10 (no secrets in code, passwords not logged, form state cleared)
- **File Upload:** 9/10 (client-side validation is bypassable but backend validates; good defense-in-depth)
- **Dependencies:** 10/10 (recharts has no known CVEs, React/Next.js patched for recent CVEs)
- **Data Exposure:** 10/10 (generic error messages, no PII in progress data, password fields masked)

**Deductions:**
- -0.5: Client-side MIME type validation relies on browser-set `file.type` (bypassable, but backend validates)
- -0.5: Pre-existing JWT in localStorage concern (unchanged, accepted tradeoff)

---

## Recommendation: PASS

**Verdict:** The Phase 2 web dashboard features are **secure for production**. No Critical, High, or Medium issues were found. The implementation demonstrates strong security practices across authentication, file upload validation, password handling, navigation safety, and data exposure controls.

**Ship Blockers:** None.

**Fixes Applied:** None required -- no issues of sufficient severity to warrant code changes.

---

**Audit Completed:** 2026-02-15
**Next Review:** Standard review cycle
