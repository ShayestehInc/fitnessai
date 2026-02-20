# Hacker Report: Trainer Revenue & Subscription Analytics

## Date: 2026-02-20

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| -- | -- | -- | -- | -- | -- |

No dead buttons or non-functional UI elements found. All buttons (period selector, retry, "Manage Pricing" CTA) are wired up correctly. Subscriber table rows navigate to trainee profiles via `router.push`. Empty, loading, and error states all render correctly.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Minor | revenue-chart.tsx | Y-axis `formatDollarAxis` doesn't handle values >= $1M -- would render `$1000.0K` instead of `$1.0M`. A high-revenue trainer with $1M+ monthly could see garbled axis labels. | **FIXED**: Added `$1M` tier to formatter and widened Y-axis width from 60 to 65px to accommodate the wider label. |
| 2 | Minor | revenue-section.tsx | Currency is hardcoded to USD via `Intl.NumberFormat("en-US", { currency: "USD" })` even though `RevenueSubscriber` and `RevenuePayment` types include a `currency` field that could be a non-USD value. A trainer in GBP would see all amounts prefixed with `$`. | **Not fixed** -- requires a design decision about whether to support multi-currency display. The backend `TraineeSubscription.currency` defaults to `'usd'` so the risk is low today, but this should be addressed before international expansion. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Major | Period switching flash | Switch revenue period from 30d to 90d while data is loaded. | Previous data stays visible (dimmed at 50% opacity via `isFetching` check already in place) while new data loads. Smooth transition. | `isLoading` goes `true`, entire section flashes to skeleton loader, then back to data. The opacity dimming code (`isFetching ? "opacity-50"`) never triggers because `useQuery` without `placeholderData` sets `isLoading=true` (not `isFetching=true`) when the query key changes. **FIXED**: Added `placeholderData: keepPreviousData` to `useRevenueAnalytics` hook (and also to `useAdherenceAnalytics`/`useAdherenceTrends` which had the same issue). |
| 2 | Minor | NaN currency display | If the API returns an empty string or non-numeric value for `mrr`, `total_revenue`, or `avg_revenue_per_subscriber`, `formatCurrency` calls `parseFloat("")` which returns `NaN`, and `Intl.NumberFormat.format(NaN)` renders "NaN" on screen. | Should display `$0.00` as a safe fallback. | Displays literal text "NaN". **FIXED**: Added `Number.isNaN` guard to `formatCurrency` in revenue-section.tsx. |
| 3 | Minor | NaN chart data | If a `MonthlyRevenuePoint.amount` is an empty string, `parseFloat("")` returns `NaN`, which would cause the bar chart to render incorrectly or crash. | Bars should render as zero-height. | Potential rendering error or invisible bars. **FIXED**: Added `Number.isNaN` guard to chart data mapping and `hasAnyRevenue` check in revenue-chart.tsx. |
| 4 | Minor | isEmpty NaN edge case | If `data.total_revenue` is a non-numeric string, `parseFloat(data.total_revenue) === 0` is `false` (because `NaN !== 0`), so the isEmpty check would fail and the component would attempt to render data with broken values. | Should treat NaN total_revenue as empty/zero. | Would attempt to render broken data cards. **FIXED**: Added NaN guard to the `isEmpty` check in revenue-section.tsx. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Stat cards | Add trend indicators to MRR and Revenue stat cards using the existing `trend` and `trendLabel` props on `StatCard`. For example: "MRR: $500/mo (+12% vs last month)". The component already supports this via `trend` and `trendLabel` props but they are never passed. | Trainers want to know if their business is growing. A number without context is less useful than a number with a trend arrow. Would require a small backend change to compute period-over-period delta. |
| 2 | Medium | Payments table | Show the `description` field from `RevenuePayment` in the payments table. The data is already returned by the API but not displayed. Could be a tooltip on hover or a dedicated column. | Trainers would benefit from seeing what each payment was for (e.g., "Monthly coaching subscription", "One-time program purchase"). |
| 3 | Medium | Revenue chart | Monthly revenue chart always shows exactly 12 months regardless of the period selector value (30d / 90d / 1y). The stat cards correctly reflect the selected period, but the chart ignores it. This creates a visual mismatch: the "Revenue (30d)" card shows $X but the chart shows 12 months of data. | Consider showing fewer months for shorter periods (e.g., 3 months for 30d, 6 months for 90d, 12 for 1y) or adding a label clarifying the chart always shows 12 months. |
| 4 | Low | Payments table | Add CSV export capability for payment data. Trainers who do their own bookkeeping or taxes need to export this data. | This is a common need for any financial data display. A simple "Download CSV" button on the payments table header would suffice. |
| 5 | Low | Multi-currency | Respect the `currency` field from the API response instead of hardcoding USD formatting. Each subscriber and payment already returns a `currency` field. | Future-proofs the UI for international trainers. Low priority since all current data uses USD. |
| 6 | Low | Subscriber table | The subscriber table has no sort capability. Trainers with 20+ subscribers may want to sort by amount (highest-paying first) or by days until renewal (about to churn). | Would require either client-side sorting (feasible since subscriber list is typically small) or server-side sort params. |

## Summary
- Dead UI elements found: 0
- Visual bugs found: 2 (1 fixed, 1 requires design decision)
- Logic bugs found: 4 (all 4 fixed)
- Improvements suggested: 6
- Items fixed by hacker: 5 (across 3 files)

### Files Changed
- `web/src/components/analytics/revenue-section.tsx` -- NaN guards in `formatCurrency` and `isEmpty` check
- `web/src/components/analytics/revenue-chart.tsx` -- `$1M` tier in `formatDollarAxis`, NaN guards in chart data parsing, wider Y-axis
- `web/src/hooks/use-analytics.ts` -- Added `keepPreviousData` to all period-parameterized hooks (`useRevenueAnalytics`, `useAdherenceAnalytics`, `useAdherenceTrends`) to prevent flash-to-skeleton on period switch

## Chaos Score: 7/10
