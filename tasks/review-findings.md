# Code Review: Full Trainer→Trainee Impersonation Token Swap (Pipeline 27)

## Review Date
2026-02-20

## Files Reviewed
- `web/src/components/trainees/impersonate-trainee-button.tsx`
- `web/src/components/layout/trainer-impersonation-banner.tsx`
- `web/src/app/(trainee-view)/layout.tsx`
- `web/src/app/(trainee-view)/trainee-view/page.tsx`
- `web/src/components/trainee-view/profile-card.tsx`
- `web/src/components/trainee-view/program-card.tsx`
- `web/src/components/trainee-view/nutrition-card.tsx`
- `web/src/components/trainee-view/weight-card.tsx`
- `web/src/hooks/use-trainee-view.ts`
- `web/src/types/trainee-view.ts`
- `web/src/lib/constants.ts`
- `web/src/middleware.ts`
- `web/src/providers/auth-provider.tsx`
- `web/src/app/(dashboard)/layout.tsx`

## Critical Issues (must fix before merge)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| — | — | None found | — |

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix | Status |
|---|-----------|-------|---------------|--------|
| 1 | constants.ts | **Dead code**: `TRAINEE_USER_PROFILE` constant added but `useTraineeProfile` uses `CURRENT_USER` instead | Remove unused constant | FIXED |
| 2 | weight-card.tsx:76 | **Sorting assumption**: assumes API returns weight check-ins sorted by date descending, but API may return ascending | Add explicit client-side sort before slicing | FIXED |
| 3 | (dashboard)/layout.tsx:29-33 | **Missing TRAINEE redirect**: Dashboard layout redirects ADMIN and AMBASSADOR but not TRAINEE. Defense-in-depth gap | Add TRAINEE → /trainee-view redirect | FIXED |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix | Status |
|---|-----------|-------|---------------|--------|
| 1 | trainee-view/page.tsx:45 | **Redundant CSS**: `sm:grid-cols-1` is the same as default grid behavior | Simplify to `grid gap-6 lg:grid-cols-2` | FIXED |
| 2 | program-card.tsx:31 | **Misleading comment**: "Check first week (current week)" but it always uses weeks[0] regardless of program duration | Clarify comment about representative schedule | FIXED |

## Security Concerns
- Trainer tokens stored in sessionStorage (per-tab, cleared on tab close) — same pattern as admin impersonation
- Token swap uses existing API endpoints with proper `IsTrainer` permission checks
- No secrets or credentials in committed code
- Role cookie is client-writable (noted in middleware) — server-side API enforces true authorization
- Auth-provider impersonation bypass is gated on sessionStorage state + TRAINEE role — cannot be exploited without valid trainee JWT

## Performance Concerns
- 4 independent React Query calls on the trainee view page — all parallel with 5-min staleTime
- Hard navigation (window.location.href) clears all cached data — intentional to prevent stale data between trainee/trainer views
- No N+1 patterns — each hook makes a single API call
- Weight check-in sorting is O(n log n) on client but n is small (total check-ins per trainee)

## Quality Score: 9/10
## Recommendation: APPROVE
