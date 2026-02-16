# Security Audit: Web Dashboard Phase 3 -- Trainer Analytics Page

**Date:** 2026-02-15
**Auditor:** Security Engineer (Senior Application Security)
**Scope:** Trainer Analytics page -- adherence stats, adherence bar chart, progress table, period selector

**New Files Audited:**
- `web/src/types/analytics.ts` -- TypeScript types for API responses
- `web/src/hooks/use-analytics.ts` -- React Query hooks for adherence and progress endpoints
- `web/src/components/analytics/period-selector.tsx` -- Tab-style period radio group
- `web/src/components/analytics/adherence-chart.tsx` -- Horizontal bar chart with clickable bars
- `web/src/components/analytics/adherence-section.tsx` -- Stat cards + chart with loading/error/empty states
- `web/src/components/analytics/progress-section.tsx` -- Progress table with weight change colors
- `web/src/app/(dashboard)/analytics/page.tsx` -- Analytics page composing both sections

**Modified Files Audited:**
- `web/src/components/layout/nav-links.tsx` -- Added Analytics nav item
- `web/src/lib/constants.ts` -- Added `ANALYTICS_ADHERENCE` and `ANALYTICS_PROGRESS` API URL constants

**Backend Endpoints Reviewed (for auth/authz only):**
- `backend/trainer/views.py` -- `AdherenceAnalyticsView`, `ProgressAnalyticsView`
- `backend/trainer/urls.py` -- URL routing for analytics endpoints
- `backend/core/permissions.py` -- `IsTrainer` permission class

---

## Executive Summary

This audit covers the Phase 3 Trainer Analytics page: adherence statistics (three stat cards), a per-trainee adherence bar chart, and a progress table showing weight changes. All changes are frontend-only (Next.js/React), consuming two existing backend API endpoints.

The implementation follows strong security practices: all API calls use JWT Bearer authentication via the centralized `apiClient`, no XSS vectors introduced, trainee IDs used in navigation are server-provided integers, the `days` query parameter is constrained to a TypeScript union type (`7 | 14 | 30`) on the frontend and clamped to `[1, 365]` on the backend, and both backend views enforce `[IsAuthenticated, IsTrainer]` with row-level filtering by `parent_trainer=user`.

**No Critical or High issues were found. No fixes required.**

**Issues Found:**
- 0 Critical
- 0 High
- 0 Medium
- 3 Low / Informational

---

## Security Checklist

- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (`.env.local` is in `.gitignore`, verified not tracked)
- [x] All user input sanitized (period selector constrained to `7 | 14 | 30`, React auto-escaping for names)
- [x] Authentication checked on all new API calls (both hooks use `apiClient.get()` which injects Bearer token)
- [x] Authorization -- correct role/permission guards (backend: `[IsAuthenticated, IsTrainer]` on both endpoints)
- [x] No IDOR vulnerabilities (backend filters by `parent_trainer=user`; trainee IDs come from server-provided data)
- [x] File uploads validated (N/A -- no file uploads in this feature)
- [x] Rate limiting on sensitive endpoints (N/A -- read-only analytics, no sensitive mutations)
- [x] Error messages don't leak internals (generic messages: "Failed to load adherence data", "Failed to load progress data")
- [x] CORS policy appropriate (unchanged from prior audit -- production restricts origins)

---

## Secrets Scan

### Scan Methodology

Grepped all 7 new files and 2 modified files for:
- API keys, secret keys, passwords, tokens: `(api[_-]?key|secret[_-]?key|password|token|credential)\s*[=:]\s*['"][A-Za-z0-9]`
- Provider-specific patterns: `(sk-|pk_|rk_|AIza|ghp_|gho_|AKIA|aws_)`
- Hardcoded URLs with embedded credentials

### Results: PASS

No secrets, API keys, passwords, or tokens found in any new or modified files. The only token-related code is the pre-existing `apiClient` and `token-manager` (unchanged).

---

## Injection Vulnerabilities

### XSS: PASS

| Vector | Status | Evidence |
|--------|--------|----------|
| `dangerouslySetInnerHTML` | Not used | `grep` returned zero matches across all analytics files |
| `innerHTML` / `outerHTML` / `__html` | Not used | `grep` returned zero matches |
| `eval()` / `new Function()` | Not used | Zero matches |
| React JSX interpolation of trainee names | Safe | `{row.trainee_name}` in JSX text nodes -- React auto-escapes |
| SVG `<text>` element in chart Y-axis | Safe | `{display}` and `<title>{name}</title>` in SVG rendered via React, auto-escaped |
| `title` attribute on truncated names | Safe | `title={row.trainee_name}` -- React escapes attribute values |
| Recharts tooltip content | Safe | `formatter` returns string values via array, rendered by recharts in React DOM nodes |

**Analysis:** All user-controlled data (trainee names, adherence rates, weight values) is rendered through React's default text-node and attribute escaping. The adherence chart renders trainee names in SVG `<text>` elements via React JSX, which auto-escapes. No unsafe DOM APIs are used anywhere.

### Open Redirect: PASS

Two navigation patterns introduced:

```typescript
// adherence-chart.tsx:92
router.push(`/trainees/${trainee.trainee_id}`);

// progress-section.tsx:152
router.push(`/trainees/${row.trainee_id}`);
```

In both cases, `trainee_id` is a `number` field from the server-provided API response (`TraineeAdherence.trainee_id` and `TraineeProgressEntry.trainee_id`). The TypeScript types enforce this as `number`. The data originates from the backend where `trainee__id` is a Django `AutoField` (integer primary key). There is no user-controllable input that reaches these navigation calls.

**Verdict:** No open redirect or path traversal possible.

### SQL Injection: PASS (N/A on Frontend)

The `days` query parameter is the only user-controlled value sent to the backend:

**Frontend constraint:** `AdherencePeriod = 7 | 14 | 30` -- TypeScript union type prevents arbitrary values at compile time. The `PeriodSelector` component only offers these three options.

**Backend defense:** `days = min(max(int(request.query_params.get('days', 30)), 1), 365)` with `try/except (ValueError, TypeError)` fallback to 30. The value is then used in a `timedelta(days=days)` computation -- never interpolated into SQL. The backend uses Django ORM exclusively (`objects.filter()`, `.annotate()`, `.values()`), not raw queries.

---

## Auth & Authz

### Authentication: PASS

Both new hooks use the centralized `apiClient.get()`:

| Hook | Endpoint | Auth |
|------|----------|------|
| `useAdherenceAnalytics(days)` | `GET /api/trainer/analytics/adherence/?days=N` | Bearer token via `apiClient` |
| `useProgressAnalytics()` | `GET /api/trainer/analytics/progress/` | Bearer token via `apiClient` |

The `apiClient.get()` calls `request()` which calls `getAuthHeaders()` which reads the JWT from localStorage. If no token exists, it throws `ApiError(401, "No access token", null)`. On 401 response, it attempts one token refresh before redirecting to `/login`.

### Authorization: PASS

**Backend enforcement:**

Both `AdherenceAnalyticsView` and `ProgressAnalyticsView` have:
```python
permission_classes = [IsAuthenticated, IsTrainer]
```

The `IsTrainer` permission class checks `request.user.is_trainer()`, ensuring only users with the TRAINER role can access these endpoints.

**Row-level security:**

- `AdherenceAnalyticsView` (line 840): `User.objects.filter(parent_trainer=user, role=User.Role.TRAINEE, is_active=True)` -- only the authenticated trainer's trainees are queried.
- `ProgressAnalyticsView` (line 900): Same filter pattern -- `parent_trainer=user, role=User.Role.TRAINEE, is_active=True`.

A trainer cannot see another trainer's trainees' analytics. There is no trainee ID parameter in the URL -- the backend scopes everything to the authenticated user.

**Frontend enforcement:**

The analytics page is under the `(dashboard)` route group, which is protected by:
1. Next.js middleware cookie check (redirects to `/login` if no session cookie)
2. Dashboard layout `isAuthenticated` guard (redirects to `/login` and shows loading spinner)
3. Auth provider validates the user session on mount

### IDOR Analysis: PASS

The analytics endpoints are aggregate views -- they return data for ALL of the trainer's trainees, not a specific trainee. There is no trainee ID in the request URL or query parameters.

The `trainee_id` values in the response are used only for client-side navigation (`/trainees/{id}`). When the user navigates to a specific trainee, the `TraineeDetailView` backend endpoint enforces `parent_trainer=user` filtering, so even a tampered ID in the URL would return 404.

---

## Data Exposure

### API Response Fields: ACCEPTABLE (with note)

**Adherence API response includes:**
- `trainee_id` (integer) -- needed for navigation
- `trainee_email` (string) -- **not displayed in UI**
- `trainee_name` (string) -- displayed in chart and tooltip
- `adherence_rate` (number) -- displayed in chart
- `days_tracked` (number) -- not displayed but benign

**Progress API response includes:**
- `trainee_id` (integer) -- needed for navigation
- `trainee_email` (string) -- **not displayed in UI**
- `trainee_name` (string) -- displayed in table
- `current_weight`, `weight_change`, `goal` -- displayed in table

The `trainee_email` field is present in both TypeScript types but never rendered in any component. While trainers legitimately have access to their trainees' emails (they invited them), this is unnecessary data over the wire for an analytics page. See Low/Informational items below.

### Error Messages: PASS

All error states use generic messages:
- `"Failed to load adherence data"` (adherence section)
- `"Failed to load progress data"` (progress section)

No server error details, stack traces, or internal identifiers are exposed.

---

## CORS / CSRF

### CORS: PASS (Unchanged)

Backend CORS configuration remains:
- `DEBUG=True`: `CORS_ALLOW_ALL_ORIGINS = True` (development only)
- `DEBUG=False`: `CORS_ALLOW_ALL_ORIGINS = False`, origins restricted to `CORS_ALLOWED_ORIGINS` env var
- `CORS_ALLOW_CREDENTIALS = True` -- needed for cookie-based session indicator

### CSRF: PASS (N/A)

The analytics endpoints use JWT Bearer token authentication, not session cookies. CSRF is not a concern because the browser does not automatically attach Bearer tokens to cross-origin requests. The Django CSRF middleware is active but DRF's JWT authentication exempts API views from CSRF checks (standard DRF behavior for token-based auth).

---

## Trainee ID in URL -- Validation / Scoping

### Frontend Bar Chart Click:
```typescript
// adherence-chart.tsx:89-93
onClick={(_entry, index) => {
  const trainee = sorted[index];
  if (trainee) {
    router.push(`/trainees/${trainee.trainee_id}`);
  }
}}
```

- `sorted[index]` accesses the pre-sorted array by numeric index from the chart library
- `trainee.trainee_id` is a `number` from the server response
- The `if (trainee)` guard prevents navigation if the index is somehow out of bounds
- **No user-controlled input reaches the URL**

### Frontend Table Row Click:
```typescript
// progress-section.tsx:152
onRowClick={(row) => router.push(`/trainees/${row.trainee_id}`)}
```

- `row.trainee_id` is typed as `number` from `TraineeProgressEntry`
- Data comes from the authenticated API response
- **No user-controlled input reaches the URL**

### Backend Destination:
```python
# TraineeDetailView.get_queryset()
User.objects.filter(parent_trainer=user, role=User.Role.TRAINEE)
```

Even if a malicious user manually edits the URL to `/trainees/999`, the backend will return 404 if trainee 999 does not belong to that trainer. IDOR is not possible.

**Verdict: PASS** -- Trainee IDs are server-provided, typed as integers, and the destination endpoint enforces row-level security.

---

## Low / Informational Items

### 1. Unused `trainee_email` in API Response Types (Low)

**Files:** `web/src/types/analytics.ts:5`, `web/src/types/analytics.ts:22`
**Status:** ACCEPTABLE -- no security impact, minor data minimization concern

Both `TraineeAdherence` and `TraineeProgressEntry` include a `trainee_email: string` field that is never rendered in any component. While trainers have legitimate access to their trainees' emails, sending unnecessary PII over the network increases the data exposure surface. If the API response were ever inadvertently cached by a CDN or browser cache, emails would be included.

**Recommendation:** Consider removing `trainee_email` from the backend serializer responses for these two analytics endpoints, or omitting the field from the TypeScript types if it serves no frontend purpose. This is a defense-in-depth improvement, not a vulnerability.

### 2. JWT in localStorage (Pre-Existing, Informational)

**Status:** UNCHANGED from prior audit

JWT tokens continue to be stored in `localStorage`. This is an accepted tradeoff for SPA architecture. No new XSS vectors were introduced that could enable token theft. The analytics page is read-only and introduces no mutation endpoints.

### 3. Recharts `as unknown as` Type Cast (Informational)

**File:** `tasks/dev-done.md` mentions this; actual code uses `sorted[index]` pattern instead
**Status:** ACCEPTABLE

The dev-done notes mention a `as unknown as TraineeAdherence` cast was considered for the recharts onClick handler, but the final implementation uses `sorted[index]` which is type-safe. No security impact.

---

## Security Strengths of This Implementation

1. **No new XSS vectors** -- All trainee names and numeric values rendered through React's auto-escaping. No `dangerouslySetInnerHTML`, `eval`, or unsafe DOM APIs.

2. **Constrained query parameter** -- The `days` parameter is limited to `7 | 14 | 30` by the TypeScript union type on the frontend, and clamped to `[1, 365]` with type-safe parsing on the backend.

3. **Strong backend auth/authz** -- Both endpoints enforce `[IsAuthenticated, IsTrainer]` and filter by `parent_trainer=user`. No IDOR is possible.

4. **Server-provided trainee IDs** -- Navigation targets use `trainee_id` values from authenticated API responses, not user input. Destination endpoints also enforce row-level security.

5. **Independent section error handling** -- Each section (adherence, progress) has its own loading/error/empty state, so a failure in one does not expose data from the other or create confusing UI states.

6. **No mutations** -- The entire analytics page is read-only. No POST/PATCH/DELETE requests, no form submissions, no file uploads. This dramatically reduces the attack surface.

7. **React Query cache isolation** -- Adherence data is keyed by `["analytics", "adherence", days]`, so switching periods does not leak data across different time windows.

8. **No console.log or debug output** -- No sensitive data logged to browser console.

9. **Typed API URL construction** -- `ANALYTICS_ADHERENCE` and `ANALYTICS_PROGRESS` are compile-time constants, not dynamically constructed URLs.

---

## Security Score: 9/10

**Breakdown:**
- **Authentication:** 10/10 (all endpoints use Bearer auth via centralized apiClient)
- **Authorization:** 10/10 (backend enforces IsTrainer + parent_trainer filtering)
- **Input Validation:** 10/10 (days parameter constrained on both frontend and backend)
- **Output Encoding:** 10/10 (React auto-escaping, no unsafe HTML rendering)
- **Secrets Management:** 10/10 (no secrets in code)
- **IDOR Protection:** 10/10 (aggregate endpoints with no user-supplied trainee ID)
- **Data Exposure:** 9/10 (unused `trainee_email` in response is minor over-fetch)
- **Dependencies:** 10/10 (no new dependencies, recharts previously audited)

**Deductions:**
- -0.5: Unused `trainee_email` field in API responses (minor data minimization concern)
- -0.5: Pre-existing JWT in localStorage concern (unchanged, accepted tradeoff)

---

## Recommendation: PASS

**Verdict:** The Phase 3 Trainer Analytics page is **secure for production**. No Critical, High, or Medium issues were found. The implementation demonstrates strong security practices across authentication, authorization, input validation, output encoding, and IDOR protection. The read-only nature of this feature significantly limits the attack surface.

**Ship Blockers:** None.

**Fixes Applied:** None required -- no issues of sufficient severity to warrant code changes.

---

**Audit Completed:** 2026-02-15
**Next Review:** Standard review cycle
