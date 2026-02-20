# UX Audit: Ambassador Dashboard Enhancement (Pipeline 25)

## Audit Date
2026-02-20

## Files Audited
- `web/src/components/ambassador/earnings-chart.tsx`
- `web/src/components/ambassador/referral-list.tsx`
- `web/src/components/ambassador/referral-status-breakdown.tsx`
- `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx`

## Usability Issues
| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Major | ReferralList/StatusBadge | Badge variant always "outline" because case-sensitive comparison — API returns "ACTIVE" but code checked "active" | Normalize to lowercase before comparing | FIXED |
| 2 | Minor | ReferralList search input | Missing explicit aria-label | Added aria-label for screen readers | FIXED |

## Accessibility Issues
| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| — | — | All new components already have proper ARIA attributes | No additional fixes needed |

Items verified as good:
- EarningsChart: `role="img"`, `aria-label`, `sr-only` data list
- ReferralStatusBreakdown: descriptive `aria-label` on stacked bar
- ReferralList filter tabs: `role="tablist"`, `role="tab"`, `aria-selected`
- Pagination: `<nav>` with `aria-label`, buttons with `aria-label`
- Search input: `aria-label` (added)

## Missing States
- [x] Loading / skeleton — Chart uses dashboard skeleton; ReferralList has skeleton for tabs + search + cards
- [x] Empty / zero data — Chart: "No earnings data yet"; List: 3 contextual variants
- [x] Error / failure — Dashboard: ErrorState with retry; List: error EmptyState
- [x] Success / confirmation — N/A (read-only views)
- [x] Offline / degraded — React Query retry + keepPreviousData for stale data
- [x] Permission denied — 403 handled by existing auth redirect

## Overall UX Score: 9/10
