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

---
---

# UX Audit: CSV Data Export

## Audit Date: 2026-02-21

## Components Reviewed
- `web/src/components/shared/export-button.tsx` (reusable ExportButton)
- `web/src/components/analytics/revenue-section.tsx` (export buttons in Revenue header)
- `web/src/app/(dashboard)/trainees/page.tsx` (export button on trainees page)

---

## Issues Found & Fixed

| # | Severity | Component | Issue | Fix Applied |
|---|----------|-----------|-------|-------------|
| 1 | Major | `export-button.tsx` | **No success feedback after download.** Every other action in the codebase (invitation send, goal update, layout change, etc.) shows `toast.success()`. The export button only showed errors, leaving users uncertain whether the download worked. | Added `toast.success()` with the filename after successful download. Added a brief `CheckCircle` icon state (green, 2 seconds) so the button itself visually confirms completion. |
| 2 | Major | `export-button.tsx` | **No screen reader announcement during download.** The codebase uses `aria-live="polite"` regions in adherence-section, progress-section, revenue-section, messaging, and elsewhere -- but the export button had no live region. Screen reader users received zero feedback that a download was in progress or completed. | Added an `aria-live="polite"` region with `role="status"` that announces "Downloading CSV file..." when active and "[filename] downloaded successfully" on completion. |
| 3 | Medium | `export-button.tsx` | **Button label unchanged during download.** The icon switched to a spinner but the text still read "Export CSV" / "Export Payments". Users on slow connections might wonder if the button registered their click. Other apps (Linear, Notion) change the label to "Downloading..." during the action. | Button now shows "Downloading..." as label text while the download is in progress. |
| 4 | Medium | `export-button.tsx` | **Empty blob downloaded without warning.** If the server returned a 200 with an empty body (edge case: no records matching the filter, server-side bug), the user would download a 0-byte file and see no error. | Added `blob.size === 0` check before `triggerDownload()`. Shows `toast.error("No data available to export.")` if the response body is empty. Applied in both the normal path and the 401-retry path. |
| 5 | Medium | `export-button.tsx` | **No `disabled` prop.** Parent components had no way to disable the export button externally (e.g., during data refetch). The button component only disabled itself during its own download state. | Added optional `disabled` prop (default `false`). Button disables when `disabled \|\| isDownloading`. |
| 6 | Medium | `revenue-section.tsx` | **Export buttons clickable during data refetch.** When the user switches the revenue period (30d/90d/1y), the section enters a `isFetching` state with `opacity-50`, but the export buttons remained enabled. Clicking "Export Payments" during refetch would export data for the previous period's filter, which is confusing. | Passed `disabled={isFetching}` to both ExportButton instances so they are disabled while revenue data is refetching. |
| 7 | Medium | `trainees/page.tsx` | **Export button visibility tied to current page results instead of total count.** The condition `data.results.length > 0` hid the export button when a search filter returned 0 results on the current page, even though the trainer has trainees. The CSV export endpoint exports all trainees regardless of search/pagination. The button should be visible whenever the trainer has any trainees at all. | Changed condition from `data.results.length > 0` to `data.count > 0` so the button stays visible as long as the trainer has trainees, regardless of current search filter. |
| 8 | Minor | `export-button.tsx` | **Missing `type="button"` on the Button element.** While the Button component doesn't set a default type, best practice (and an accessibility requirement) is to always specify `type="button"` for non-submit buttons to prevent accidental form submission if the component is ever placed inside a form. | Added `type="button"` to the Button element. |

## Issues Found (not fixed)

| # | Severity | Component | Issue | Recommendation |
|---|----------|-----------|-------|----------------|
| 1 | Low | `export-button.tsx` | **No download progress indication for large files.** For very large CSV exports (thousands of trainees/payments), the spinner gives no indication of progress percentage. The `fetch` API does not natively expose download progress without using `ReadableStream`. | Consider using `response.body.getReader()` with `Content-Length` header to show a progress bar for exports exceeding ~500KB. Low priority since current datasets are unlikely to be that large. |
| 2 | Low | `revenue-section.tsx` | **Export buttons disappear entirely when no data, then appear after data loads.** This causes a layout shift in the header row. On slow connections, the header first renders without export buttons, then re-renders with them. | Consider rendering the export buttons always but in a disabled state when there is no data, to avoid layout shift. This is a minor polish item. |
| 3 | Low | `trainees/page.tsx` | **No tooltip explaining what the export includes.** Users might wonder: does it export the filtered list or all trainees? Does it include email addresses? | Consider adding a `title` attribute or a small info icon with tooltip: "Exports all trainees as a CSV file including name, email, and program details." |

---

## States Checklist

- [x] **Default / ready** -- Button shows Download icon + label text, correct outline variant, correct size. Consistent across all three usage sites.
- [x] **Loading / downloading** -- Spinner icon replaces download icon, label changes to "Downloading...", button is disabled, screen reader announces "Downloading CSV file..."
- [x] **Success** -- Green CheckCircle icon shown for 2 seconds, toast.success() with filename, screen reader announces completion, then returns to default state.
- [x] **Error / failure** -- Specific error messages for 403 ("You don't have permission"), empty blob ("No data available"), and generic errors ("Failed to download CSV. Please try again."). All use toast.error().
- [x] **Disabled** -- Parent can pass `disabled` prop. Revenue section disables during refetch. Visual: opacity-50 + pointer-events-none (from Button component's disabled styles).

---

## Accessibility Summary

| Area | Status | Notes |
|------|--------|-------|
| ARIA labels | Pass | All three usage sites provide explicit `aria-label` props (e.g., "Export trainees as CSV") |
| Keyboard navigation | Pass | Button is focusable, disabled state removes from tab order via `disabled` attribute, focus ring provided by Button component's `focus-visible:ring-[3px]` styles |
| Screen reader feedback | Pass (fixed) | Added `aria-live="polite"` region announcing download start and completion |
| Focus indicators | Pass | Inherited from Button component: `focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px]` |
| Color contrast | Pass | Outline variant uses standard theme colors. Success green (`text-green-600`) meets WCAG AA on white backgrounds |

---

## Consistency Check

| Criterion | Status | Notes |
|-----------|--------|-------|
| Follows existing Button patterns | Pass | Uses `variant="outline"` and `size="sm"` consistently |
| Toast usage matches codebase | Pass (fixed) | Now uses `toast.success()` like every other action in the app |
| ARIA patterns match codebase | Pass (fixed) | Now uses `aria-live="polite"` + `role="status"` pattern matching revenue-section, adherence-section, progress-section |
| Error message tone | Pass | Clear, actionable, no internal jargon leaked |
| Responsive behavior | Pass | Buttons are in flex containers that wrap on small screens (`flex-col` on mobile, `flex-row` on sm+ in revenue-section) |

---

## Overall UX Score: 8/10

The CSV export feature had solid bones -- correct auth handling, proper error status codes, good ARIA labels, consistent button styling. The main gaps were around user feedback (no success confirmation, no label change during download, no screen reader announcements) and a few edge cases (empty blob, export button visibility logic, stale-data export during refetch). All major and medium issues have been fixed. The remaining low-severity items are polish improvements that can be addressed in a future pass.
