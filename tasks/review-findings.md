# Code Review: Web Dashboard Full Parity + UI/UX Polish + E2E Tests

## Review Date: 2026-02-19
## Round: 1

## Files Reviewed
All 124 files from the raw implementation commit (f53b9aa).

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `web/src/components/admin/ambassador-list.tsx:29` | Accesses `ambassador.user_email` but `Ambassador` type has `user.email` (nested object). Also accesses `ambassador.created_at` which is not on the type. Will cause runtime errors. | Change to `ambassador.user.email`, `ambassador.user.first_name`, etc. Remove or guard `created_at`. |
| C2 | `web/src/components/ambassador/dashboard-earnings-card.tsx:14-25` | Calls `.toFixed(2)` on `data.total_earnings` (a `string`) and `data.monthly_earnings` (an array). `.toFixed()` is Number method. Runtime crash. | Use `parseFloat(data.total_earnings).toFixed(2)`. Fix monthly_earnings to compute sum from array. |
| C3 | `web/src/components/ambassador/referral-code-card.tsx:37` | `useUpdateReferralCode` mutationFn takes `string`, but call passes `{ referral_code: sanitized }` (object). Type mismatch. | Change to `updateMutation.mutate(sanitized, {...})` |
| C4 | `web/src/components/admin/create-ambassador-dialog.tsx:55-59` | `CreateAmbassadorPayload` requires `first_name`, `last_name`, `password` but form only has email, commission_rate, referral_code. API will 400. | Add missing form fields or update type/payload. |
| C5 | `web/src/components/admin/ambassador-list.tsx:25` | Casts paginated response `data` as `Ambassador[]` losing pagination wrapper. `data` is `PaginatedResponse<Ambassador>` with `results` property. | Use `data?.results ?? []` instead of `(data ?? []) as Ambassador[]`. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `web/src/components/announcements/announcement-list.tsx:163-209` | Two `AnnouncementFormDialog` instances render simultaneously during edit (main + EditAnnouncementWrapper). | Only render one dialog: use EditAnnouncementWrapper for edits, main for creates. |
| M2 | `web/src/components/trainees/impersonate-trainee-button.tsx:33-43` | Impersonation incomplete: no token swap, no sessionStorage backup, no banner. | Implement full token swap flow. |
| M3 | `web/src/app/(ambassador-dashboard)/layout.tsx:46-58` | Bare `Loader2` spinner for loading. AC-31 says no bare spinners. | Use content-shaped skeleton. |
| M4 | `web/src/components/admin/ambassador-list.tsx:25-32` | Client-side filtering on paginated data only filters current page. | Use server-side search via hook params. |
| M5 | `web/src/app/(dashboard)/announcements/page.tsx` and `feature-requests/page.tsx` | Pagination state `page` never updated. Only page 1 shown. | Add pagination controls. |
| M6 | `web/src/components/settings/branding-section.tsx` | Missing `beforeunload` handler for unsaved changes (AC-3 edge case 4). | Add beforeunload event listener. |
| M7 | `web/src/components/trainees/mark-missed-day-dialog.tsx` | Missing skip/push radio group per AC-12. Only has date + reason. | Add action type selection. |
| M8 | `web/src/components/layout/ambassador-nav-links.ts` | Redefines `NavLink` interface instead of importing from `nav-links.tsx`. | Import from `./nav-links`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `nav-links.tsx` | Duplicate `Dumbbell` icon for Programs and Exercises. | Use different icon for one. |
| m2 | `chat-container.tsx:57-63` | AI providers loading uses bare Loader2. | Use ChatSkeleton. |
| m3 | `use-trainee-goals.ts:20` | Uses PATCH but ticket says PUT. | Minor REST semantics. |
| m4 | Dashboard onboarding checklist (AC-33.4) not implemented. | Deferred per dev-done.md. |
| m5 | Monthly earnings chart (AC-22) not implemented. | Deferred per dev-done.md. |
| m6 | Community tab on trainee detail (AC-27) not implemented. | Deferred per dev-done.md. |

## Security Concerns
- Impersonation tokens not properly handled (M2)
- No CSRF protection on form submissions (mitigated by JWT)
- Referral code sanitization good (alphanumeric only)

## Performance Concerns
- Client-side filtering in ambassador-list instead of server-side (M4)
- Exercise list fetches page_size=100
- No error boundaries

## Quality Score: 5/10
## Recommendation: REQUEST CHANGES
