# UX Audit: Trainer Revenue & Subscription Analytics

## Audit Date
2026-02-20

## Files Reviewed
- `web/src/components/analytics/revenue-section.tsx`
- `web/src/components/analytics/revenue-chart.tsx`
- `web/src/app/(dashboard)/analytics/page.tsx`
- `web/src/components/shared/data-table.tsx`
- `web/src/components/shared/error-state.tsx`
- `web/src/components/shared/empty-state.tsx`
- `web/src/components/dashboard/stat-card.tsx`
- `web/src/components/analytics/adherence-section.tsx` (pattern comparison)
- `web/src/components/analytics/progress-section.tsx` (pattern comparison)
- `web/src/components/analytics/period-selector.tsx` (pattern comparison)
- `web/src/components/analytics/adherence-chart.tsx` (pattern comparison)
- `web/src/components/analytics/adherence-trend-chart.tsx` (pattern comparison)
- `web/src/types/analytics.ts`
- `web/src/hooks/use-analytics.ts`
- `web/src/lib/chart-utils.ts`

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | Minor | revenue-section.tsx | Skeleton loading state only showed 1 table skeleton but the populated state has 2 tables (subscribers + payments). This makes the skeleton-to-content transition feel jumpy as the second table pops in. | Added second table skeleton to `RevenueSkeleton` to match the actual content structure. **FIXED.** |
| 2 | Minor | revenue-section.tsx | Payment table header said "Trainee" while subscriber table and all other analytics tables say "Name". Inconsistent column labeling across the page. | Changed payment table header from "Trainee" to "Name" for consistency with subscriber table, progress section, and adherence section. **FIXED.** |
| 3 | Minor | revenue-chart.tsx | Month labels on X-axis showed only abbreviated month names (e.g., "Jan"). For 1-year period views, when data spans a year boundary, two "Jan" labels could appear without year context, confusing users. | Added year suffix to January labels (e.g., "Jan '26") so year boundaries are clear. **FIXED.** |
| 4 | Low | revenue-section.tsx | Renewal column shows abbreviated "14d" without full context. Sighted users can infer "14 days" from context, but the abbreviation is still slightly cryptic. | Added `aria-label` with full text ("14 days until renewal") for screen readers. Visual abbreviation is acceptable given the column header "Renewal". **FIXED.** |
| 5 | Low | revenue-section.tsx | Currency formatting is hardcoded to USD. The `RevenueSubscriber` and `RevenuePayment` types include a `currency` field that is not used. | Acceptable for now since the platform is US-only and Stripe Connect is configured for USD. When multi-currency support is added, `formatCurrency` should accept a currency parameter. Not fixed -- noted for future. |

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | AA (2.4.7 Focus Visible) | Period selector buttons in both revenue-section.tsx and period-selector.tsx used `ring-offset-2` without `ring-offset-background`, causing the focus ring offset to render against a transparent background in dark mode. | Added `focus-visible:ring-offset-background` to both period selectors. **FIXED.** |
| 2 | AA (4.1.2 Name, Role, Value) | Clickable table rows in DataTable had `role="button"` but no `aria-label`, meaning screen readers would announce the row content without context about what clicking does. | Added `rowAriaLabel` prop to DataTable. Applied "View [name]'s profile" labels to revenue subscriber table and progress section table. **FIXED.** |
| 3 | AA (2.4.7 Focus Visible) | DataTable clickable rows used `ring-offset-2` focus style which could clip outside the table border. | Changed to `focus-visible:ring-inset` so the focus ring stays within the row boundaries and doesn't overlap adjacent rows. **FIXED.** |
| 4 | AA (1.4.1 Use of Color) | Payment status badges use color to distinguish statuses (green/amber/red/blue). However, the status text label IS visible alongside the color (e.g., "Succeeded", "Pending"), so color is not the sole differentiator. | No fix needed -- text label is present. Compliant. |
| 5 | A (1.3.1 Info and Relationships) | Chart data conveyed only via visual bar chart. | Already handled with sr-only `<ul>` list providing screen-reader accessible data. Compliant. |
| 6 | AA (2.1.1 Keyboard) | Period selector and table rows already support full keyboard navigation (arrow keys for radiogroup, Enter/Space for row clicks). | Compliant -- no fix needed. |

## Missing States

- [x] Loading / skeleton -- Comprehensive skeleton with 4 stat cards, chart, and 2 table skeletons. `role="status"` and sr-only loading text present.
- [x] Empty / zero data -- EmptyState component with DollarSign icon, clear description, and "Manage Pricing" CTA. RevenueChart also has its own internal empty state for when subscribers exist but no revenue data.
- [x] Error / failure -- ErrorState with retry button, `role="alert"` and `aria-live="assertive"`. Section-level error isolation (other analytics sections remain functional).
- [x] Success / confirmation -- Data renders with well-formatted stat cards, chart, and tables. Currency formatting, date formatting, and status badges all polished.
- [x] Refreshing / transition -- Opacity 50% transition with `aria-busy` and sr-only `aria-live="polite"` announcement. React Query `isFetching` state properly detected.

## Consistency Check (vs. Adherence and Progress sections)

| Aspect | Adherence | Progress | Revenue | Consistent? |
|--------|-----------|----------|---------|-------------|
| Section heading pattern | h2 with aria-labelledby | h2 with aria-labelledby | h2 with aria-labelledby | Yes |
| Period selector | Shared PeriodSelector component | N/A | Inline RevenuePeriodSelector (different periods: 30/90/365) | Acceptable -- different period values require separate implementation |
| Skeleton pattern | Cards + chart + chart | Card with table | Cards + chart + 2 tables | Yes (matches content structure) |
| Empty state pattern | EmptyState + icon + CTA | EmptyState + icon + CTA | EmptyState + icon + CTA | Yes |
| Error state pattern | ErrorState + retry | ErrorState + retry | ErrorState + retry | Yes |
| Refresh transition | opacity-50 + aria-busy + sr-only | opacity-50 + aria-busy + sr-only | opacity-50 + aria-busy + sr-only | Yes |
| Table column "Name" header | "Name" (in bar chart) | "Name" | "Name" (was "Trainee", fixed) | Yes (after fix) |
| DataTable clickable rows | N/A (chart click) | onRowClick + rowAriaLabel | onRowClick + rowAriaLabel | Yes (after fix) |
| Chart accessibility | sr-only list | N/A | sr-only list + role="img" | Yes |
| Chart height | 240px | N/A | 240px | Yes |

## Responsive Layout Assessment

- Stat cards: `grid gap-4 sm:grid-cols-2 lg:grid-cols-4` -- stacks 1-col on mobile, 2-col on sm, 4-col on lg. Correct.
- Tables: `overflow-x-auto` wrapper on DataTable ensures horizontal scroll on narrow screens. Correct.
- Section heading + period selector: `flex-col gap-3 sm:flex-row sm:items-center sm:justify-between` -- stacks on mobile, inline on sm+. Correct.
- Chart: `ResponsiveContainer width="100%" height="100%"` inside fixed-height div. Correct.

## Fixes Applied

1. **revenue-section.tsx** -- Added second table skeleton to `RevenueSkeleton` to match the two-table populated state (subscribers + payments).
2. **revenue-section.tsx** -- Changed payment table column header from "Trainee" to "Name" for consistency with all other analytics tables.
3. **revenue-section.tsx** -- Added `aria-label` to renewal cell ("X days until renewal") for screen reader clarity.
4. **revenue-section.tsx** -- Added `focus-visible:ring-offset-background` to period selector buttons.
5. **revenue-section.tsx** -- Added `rowAriaLabel` prop to subscriber DataTable for screen reader navigation context.
6. **revenue-chart.tsx** -- Enhanced `formatMonthLabel` to append 2-digit year on January labels (e.g., "Jan '26") for year boundary clarity.
7. **period-selector.tsx** -- Added `focus-visible:ring-offset-background` to adherence period selector buttons (consistency fix).
8. **data-table.tsx** -- Added `rowAriaLabel` prop to DataTable interface for generating per-row aria-labels on clickable rows.
9. **data-table.tsx** -- Changed focus ring style from `ring-offset-2` to `ring-inset` on clickable rows for better containment within table borders.
10. **progress-section.tsx** -- Added `rowAriaLabel` prop to progress DataTable for screen reader navigation context.

## Items NOT Fixed (Acceptable / Future Work)

1. **Currency hardcoded to USD** -- The `formatCurrency` function and chart formatters are hardcoded to USD. The API returns a `currency` field per subscriber/payment. When multi-currency is needed, pass currency dynamically. Low priority since platform is US-only currently.
2. **RevenuePeriodSelector is inline, not extracted** -- Unlike adherence which uses a shared `PeriodSelector`, the revenue section has an inline selector due to different period values (30/90/365 vs 7/14/30). Both could be generified into a shared component accepting a generic period list. Low priority -- works correctly as-is.
3. **No keyboard-accessible chart tooltips** -- Recharts tooltips are mouse-only. The sr-only data list compensates for this. This is a known limitation of the charting library shared across all analytics sections.

## Overall UX Score: 9/10

The Revenue section is well-implemented, following established patterns from the Adherence and Progress sections with high fidelity. All five critical states (loading, empty, error, success, refreshing) are properly handled with appropriate ARIA semantics. The skeleton matches the populated content structure, period selection supports keyboard navigation via radiogroup pattern, and the chart includes screen-reader accessible data. The fixes applied were minor refinements (skeleton completeness, label consistency, focus ring correctness, screen reader labels) rather than structural issues. The implementation would pass review at a design-forward company like Stripe or Linear.
