# Code Review: Ambassador Dashboard Enhancement (Pipeline 25)

## Review Date
2026-02-20

## Files Reviewed
- `backend/ambassador/views.py`
- `web/src/components/ambassador/earnings-chart.tsx`
- `web/src/components/ambassador/referral-list.tsx`
- `web/src/components/ambassador/referral-status-breakdown.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx`
- `web/src/hooks/use-ambassador.ts`

## Critical Issues (must fix before merge)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| — | — | No critical issues found | — |

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | referral-list.tsx:86-87 | `hasNext`/`hasPrevious` evaluate to `true` when `data` is `undefined` — `undefined !== null` is `true`. This enables pagination buttons before data loads. | Use `data?.next != null` (coerces undefined and null both to false) or `Boolean(data?.next)` |
| M2 | referral-list.tsx:165 | `isFetching && !isLoading` shows skeleton, completely replacing content. This defeats `keepPreviousData` which provides stale data during refetch. | Show previous data with a subtle opacity fade or loading spinner overlay instead of replacing with skeleton. |
| M3 | views.py:180-183 | `AmbassadorReferralsView` queryset has no explicit `order_by`. Paginated results may be non-deterministic across pages. | Add `.order_by('-referred_at')` to the queryset. |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | earnings-chart.tsx:37-38 | Redundant condition: `value >= 10_000` branch is dead code since `value >= 1_000` on line 38 covers it identically. | Remove the first condition. |
| m2 | referral-list.tsx:60 | StatusBadge displays raw lowercase status ("active") — should capitalize for display. | Capitalize first letter. |
| m3 | dashboard/page.tsx:56 | When ReferralStatusBreakdown returns null (zero referrals), ReferralCodeCard sits alone in a 2-col grid, looking off-center. | Conditionally skip the grid wrapper if all counts are zero. |

## Security Concerns
- None. All endpoints require auth + ambassador role. No data leakage across users.

## Performance Concerns
- Monthly earnings uses single GROUP BY with TruncMonth — efficient.
- `keepPreviousData` for pagination — good pattern (but M2 defeats it).

## Quality Score: 7/10
## Recommendation: REQUEST CHANGES
