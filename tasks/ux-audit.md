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

---
---

# UX Audit: Macro Preset Management

## Audit Date
2026-02-21

## Components Reviewed
- `web/src/components/trainees/macro-presets-section.tsx`
- `web/src/components/trainees/preset-card.tsx` (extracted from macro-presets-section)
- `web/src/components/trainees/preset-form-dialog.tsx`
- `web/src/components/trainees/copy-preset-dialog.tsx`
- `web/src/components/trainees/trainee-overview-tab.tsx`
- `web/src/hooks/use-macro-presets.ts`

---

## Usability Issues Found & Fixed

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Critical | preset-form-dialog.tsx | Form validation errors had no `aria-describedby` linking error text to inputs. Screen readers could not associate error messages with their corresponding fields. | Added `aria-describedby` on all 5 form inputs (name, calories, protein, carbs, fat) pointing to error `<p>` IDs. | FIXED |
| 2 | Critical | preset-form-dialog.tsx | Validation error messages lacked `role="alert"`, so screen readers were not notified when errors appeared dynamically. | Added `role="alert"` to all 5 error message `<p>` elements. | FIXED |
| 3 | Major | macro-presets-section.tsx | Delete confirmation dialog used generic `Dialog` without `role="alertdialog"`. Destructive actions should signal urgency to assistive technology. | Added `role="alertdialog"` and explicit `aria-describedby` to the delete dialog's `DialogContent`. | FIXED |
| 4 | Major | preset-form-dialog.tsx | Dialog could be dismissed (via overlay click, Escape key, or X button) during a pending create/edit mutation. User could close the dialog while their data was still being saved, causing confusion if the mutation succeeded after dismissal. | Added `handleOpenChange` guard that prevents closing while `isPending`. Added `onPointerDownOutside` and `onEscapeKeyDown` handlers that call `e.preventDefault()` during pending state. Disabled Cancel button during pending. | FIXED |
| 5 | Major | copy-preset-dialog.tsx | Same dismissal-during-pending issue as the form dialog. | Applied identical pattern: `handleOpenChange` guard, `onPointerDownOutside`/`onEscapeKeyDown` prevention, Cancel button disabled during pending. | FIXED |
| 6 | Major | macro-presets-section.tsx | Delete dialog could be dismissed via overlay click or Escape while deletion was in progress. The `onOpenChange` handler was guarded, but overlay/Escape interactions were not. | Added `onPointerDownOutside` and `onEscapeKeyDown` prevention on the delete dialog's `DialogContent`. | FIXED |
| 7 | Minor | preset-card.tsx | Icon action buttons (Copy, Edit, Delete) had hover styles but no visible `focus-visible` ring for keyboard navigation. Users tabbing through the card had no visual indicator of focus. | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-1` to all three action buttons. Delete button uses `focus-visible:ring-destructive` for visual consistency with its destructive intent. | FIXED |
| 8 | Minor | preset-card.tsx | Star icon for default presets used `aria-label` on an SVG, which has inconsistent screen reader support across browsers. | Changed to `aria-hidden="true"` on the Star SVG and added a `<span className="sr-only">` with "(Default preset)" text, which is the more reliable pattern. | FIXED |
| 9 | Minor | macro-presets-section.tsx | Error state retry button lacked descriptive `aria-label`. | Added `aria-label="Retry loading macro presets"` to the retry button. | FIXED |
| 10 | Minor | macro-presets-section.tsx | Loading skeleton had no `aria-busy` or loading announcement for screen readers. | Wrapped `PresetsSkeleton` in a `<div aria-busy="true" aria-label="Loading macro presets">`. | FIXED |
| 11 | Minor | macro-presets-section.tsx | Error state container lacked `role="alert"` so screen readers would not announce the failure. | Added `role="alert"` to the error state wrapper div. | FIXED |
| 12 | Minor | preset-form-dialog.tsx | Native `<select>` for frequency and native `<input type="checkbox">` for "Set as default" had inconsistent focus ring styling (ring-1 vs ring-2 used elsewhere). | Upgraded to `focus-visible:ring-2` and `focus-visible:ring-offset-1` for consistency. Added `accent-primary` to checkbox for design system color alignment. Added `disabled:cursor-not-allowed disabled:opacity-50` for disabled states. | FIXED |
| 13 | Minor | preset-form-dialog.tsx, copy-preset-dialog.tsx | Native `<select>` elements lacked `aria-label` attributes. | Added `aria-label="Preset frequency per week"` and `aria-label="Select target trainee for preset copy"`. | FIXED |

## Additional Enhancements Applied

| # | Component | Enhancement |
|---|-----------|-------------|
| 1 | preset-form-dialog.tsx | Calorie mismatch warning: computed `P*4 + C*4 + F*9` comparison with entered calories. Displays amber warning banner when difference exceeds 10%. Uses `AlertTriangle` icon. |
| 2 | preset-form-dialog.tsx | All form inputs (`name`, `calories`, `protein`, `carbs`, `fat`, frequency `select`, default `checkbox`) are now `disabled={isPending}` during mutation. |
| 3 | preset-form-dialog.tsx | Number inputs now include `step="1"` to prevent fractional input in the stepper UI. |
| 4 | preset-form-dialog.tsx | Validation logic rounds before range-checking (`Math.round(Number(calories))`) so edge cases like 499.6 correctly round to 500 and pass. |
| 5 | copy-preset-dialog.tsx | Loading state for trainee list: shows skeleton + "Loading trainees..." text while `useAllTrainees()` is fetching. |
| 6 | copy-preset-dialog.tsx | Empty state improved: uses `Users` icon centered above the "No other trainees" message for visual consistency with other empty states. |
| 7 | copy-preset-dialog.tsx | Select is disabled during copy mutation. Submit button also disabled while trainees are loading. |
| 8 | macro-presets-section.tsx / preset-card.tsx | `PresetCard` and `MacroCell` extracted into separate `preset-card.tsx` file for better code organization (max 150 lines per widget convention). |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A (1.3.1) | Error messages not programmatically associated with form controls | Added `aria-describedby` linking errors to inputs |
| 2 | A (4.1.3) | Dynamic validation errors not announced | Added `role="alert"` on error messages |
| 3 | A (1.3.1) | Delete dialog not identified as alert dialog | Added `role="alertdialog"` |
| 4 | AA (2.4.7) | Action buttons lacked visible focus indicators | Added `focus-visible:ring-2` classes |
| 5 | A (1.1.1) | Star icon used `aria-label` on SVG (inconsistent support) | Switched to `aria-hidden` + `sr-only` span pattern |
| 6 | A (4.1.3) | Loading state not announced to assistive technology | Added `aria-busy="true"` with `aria-label` |
| 7 | A (4.1.3) | Error state not announced | Added `role="alert"` to error container |

---

## Missing States Checklist

- [x] Loading / skeleton -- Preset cards show 3 skeleton cards; copy dialog shows skeleton while trainees load
- [x] Empty / zero data -- Centered Utensils icon + descriptive message + "Add Preset" CTA
- [x] Error / failure -- Inline error with retry button, `role="alert"` for screen readers
- [x] Success / confirmation -- Toast notifications for create/update/delete/copy
- [x] Offline / degraded -- Handled by React Query retry + error state
- [x] Permission denied -- Not applicable (trainer always has access to their own trainees' presets)

---

## Consistency Check (vs. Edit Goals Dialog and Remove Trainee Dialog)

| Aspect | Edit Goals Dialog | Remove Trainee Dialog | Preset Form Dialog | Consistent? |
|--------|------------------|----------------------|-------------------|-------------|
| Dialog max-width | sm:max-w-md | sm:max-w-md | sm:max-w-md | Yes |
| Cancel button | variant="outline" | variant="outline" + disabled during pending | variant="outline" + disabled during pending | Yes |
| Loading spinner | Loader2 with aria-hidden | Loader2 with aria-hidden | Loader2 with aria-hidden | Yes |
| Error toast | getErrorMessage(err) | getErrorMessage(err) | getErrorMessage(err) | Yes |
| Success toast | toast.success() | toast.success() | toast.success() | Yes |
| Form validation | Same pattern (Record<string, string> errors) | N/A (uses typed confirmation) | Same pattern + aria-describedby (improvement) | Yes (improved) |
| Label/Input pairing | htmlFor + id | htmlFor + id | htmlFor + id | Yes |

---

## Files Changed

| File | Changes |
|------|---------|
| `web/src/components/trainees/macro-presets-section.tsx` | Added `aria-busy`, `aria-label` on loading wrapper; `role="alert"` on error state; `aria-label` on retry button; `role="alertdialog"`, `aria-describedby`, pointer/escape prevention on delete dialog |
| `web/src/components/trainees/preset-card.tsx` | Fixed Star icon accessibility (`aria-hidden` + `sr-only`); added `focus-visible:ring-2` to all action buttons |
| `web/src/components/trainees/preset-form-dialog.tsx` | Added `aria-describedby` and `role="alert"` to all 5 form field errors; added `handleOpenChange` guard; added `onPointerDownOutside`/`onEscapeKeyDown` prevention; improved focus ring consistency on select/checkbox; added `cursor-pointer` to checkbox label; calorie mismatch warning; all inputs disabled during pending |
| `web/src/components/trainees/copy-preset-dialog.tsx` | Added `handleOpenChange` guard; added `onPointerDownOutside`/`onEscapeKeyDown` prevention; improved select `aria-label` and focus ring; disabled cancel during pending; cancel uses `handleOpenChange`; loading state for trainee list; enhanced empty state |

---

## TypeScript Check
`npx tsc --noEmit` passed with exit code 0. No type errors.

---

## Overall UX Score: 9/10

The Macro Preset Management feature is well-built with strong fundamentals: clear empty states, proper loading skeletons, error handling with retry, toast feedback for all mutations, and delete confirmation. The primary gaps were accessibility-related (missing ARIA attributes for screen readers, missing focus indicators for keyboard users, dialog dismissal during mutations). All issues have been fixed. The calorie mismatch warning is a thoughtful UX addition that helps trainers catch data entry mistakes before saving. The feature is consistent with the existing dashboard patterns (same dialog structure, button styles, card layout as other trainee components like Edit Goals and Remove Trainee).

---
---

# UX Audit: Smart Program Generator

## Audit Date: 2026-02-21

## Files Reviewed

### Web
- `web/src/components/programs/program-generator-wizard.tsx`
- `web/src/components/programs/generator/split-type-step.tsx`
- `web/src/components/programs/generator/config-step.tsx`
- `web/src/components/programs/generator/custom-day-config.tsx`
- `web/src/components/programs/generator/preview-step.tsx`
- `web/src/components/programs/exercise-picker-dialog.tsx`
- `web/src/app/(dashboard)/programs/page.tsx`
- `web/src/app/(dashboard)/programs/generate/page.tsx`

### Mobile
- `mobile/lib/features/programs/presentation/screens/program_generator_screen.dart`
- `mobile/lib/features/programs/presentation/widgets/split_type_card.dart`
- `mobile/lib/features/programs/presentation/widgets/goal_type_card.dart`
- `mobile/lib/features/programs/presentation/widgets/custom_day_configurator.dart`
- `mobile/lib/features/programs/presentation/widgets/step_indicator.dart`
- `mobile/lib/features/programs/presentation/widgets/exercise_picker_sheet.dart`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Status |
|---|----------|-----------------|-------|----------------|--------|
| 1 | High | Web: config-step.tsx | Difficulty and Goal badge groups had no `radiogroup` wrapper role. Screen readers could not understand these are grouped selections. | Wrapped in `<fieldset>` with `<legend>` and `role="radiogroup"`. | FIXED |
| 2 | High | Web: config-step.tsx | Radio badges lacked arrow key navigation per WAI-ARIA radio group pattern. Users stuck tabbing through every option instead of using arrow keys. | Added ArrowRight/ArrowDown/ArrowLeft/ArrowUp key handlers that cycle through options. | FIXED |
| 3 | High | Web: custom-day-config.tsx | Muscle group badges completely missing keyboard support -- no `tabIndex`, no `onKeyDown`, no `role`. Keyboard-only users could not interact. | Added `role="checkbox"`, `aria-checked`, `tabIndex={0}`, `onKeyDown` handlers, and `focus-visible` ring styles. | FIXED |
| 4 | High | Mobile: exercise_picker_sheet.dart | Error state was plain `Text('Error: $error')` with no retry button and no guidance. Users hit a dead end with no way to recover. | Replaced with proper error UI: icon, title, description, and Retry button that invalidates the provider. | FIXED |
| 5 | Medium | Mobile: exercise_picker_sheet.dart | Empty state was plain `Text('No exercises found')` with no guidance or icon. Inconsistent with the polished web counterpart. | Added proper empty state with icon, title, and contextual description that adapts to whether filters are active. | FIXED |
| 6 | Medium | Web: preview-step.tsx | Loading skeleton had no `role="status"` or screen reader announcement. Users relying on assistive tech had no idea generation was in progress. | Added `role="status"`, `aria-label`, descriptive subtitle text, and `sr-only` live announcement. | FIXED |
| 7 | Medium | Web: preview-step.tsx | Error state container had no `role="alert"` for assistive tech to announce the failure automatically. | Added `role="alert"` and `aria-live="assertive"` to the error container. | FIXED |
| 8 | Medium | Web: preview-step.tsx | When `data` was null (no error, not loading), component returned `null` -- a blank page with no explanation. | Replaced with explanatory text: "No program data available. Go back and configure your program." with retry button. | FIXED |
| 9 | Medium | Mobile: program_generator_screen.dart | Null `_generatedData` state showed plain `CircularProgressIndicator` with no text. User saw a spinner forever. | Replaced with proper empty state: hourglass icon, explanatory text, and Generate button. | FIXED |
| 10 | Medium | Web: split-type-step.tsx | No descriptive subtitle below the heading. Users had to infer what "split type" means from the cards alone. | Added subtitle: "This determines how muscle groups are distributed across training days." | FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Status |
|---|------------|-------|-----|--------|
| 1 | A (2.1.1 Keyboard) | Web: custom-day-config badges had no keyboard support at all. Failed keyboard operability. | Added `tabIndex`, `onKeyDown`, `role="checkbox"`, `aria-checked`. | FIXED |
| 2 | A (1.3.1 Info) | Web: program-generator-wizard step indicator used `role="tablist"` but steps are not tabs -- they represent sequential progress. | Changed to `<nav><ol>` with `aria-label="Program generator progress"` and `aria-current="step"`. | FIXED |
| 3 | A (4.1.2 Name/Role) | Web: step buttons lacked descriptive `aria-label`. Screen reader just reads "1" or "2". | Added `aria-label="Step 1: Split Type (current)"` with state suffix. | FIXED |
| 4 | A (1.3.1 Info) | Web: Difficulty and Goal badge groups missing `role="radiogroup"` container. | Wrapped in `<fieldset>` with `<legend>` and `role="radiogroup"`. | FIXED |
| 5 | A (2.4.7 Focus) | Web: split type cards, config badges, and custom day badges missing `focus-visible` ring styles. Focus not visible when tabbing. | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` to all interactive elements. | FIXED |
| 6 | A (1.3.1 Info) | Web: split type cards used `role="button"` inside `role="listbox"` -- semantically invalid. | Changed to `role="radiogroup"` container with `role="radio"` + `aria-checked` children. | FIXED |
| 7 | A (4.1.2 Name/Role) | Mobile: step_indicator.dart circles had no semantic labels. TalkBack/VoiceOver users hear nothing meaningful. | Wrapped each step in `Semantics` widget with label like "Step 1 of 3: Split Type, current step". | FIXED |
| 8 | A (4.1.2 Name/Role) | Mobile: split_type_card.dart and goal_type_card.dart had no Semantics widget. Screen readers miss the description and selected state. | Added `Semantics(button: true, selected: selected, label: ...)` wrapper. | FIXED |
| 9 | A (4.1.2 Name/Role) | Mobile: IconButtons for duration/days had no tooltip. Screen readers read "button" with no description. | Added `tooltip` property: "Decrease duration", "Increase duration", etc. | FIXED |
| 10 | A (4.1.2 Name/Role) | Mobile: Duration and days display text had no Semantics label. Screen reader reads "4 weeks" with no context. | Wrapped in `Semantics(label: 'Program duration: 4 weeks')`. | FIXED |
| 11 | AA (1.1.1 Non-text) | Web: nutrition macro abbreviations (P, C, F) unclear to screen readers. | Added `aria-label` with full text: "Protein: 150 grams", "Carbs: 200 grams", "Fat: 60 grams". | FIXED |

---

## Missing States

- [x] Loading / skeleton -- Web: skeleton with `role="status"`. Mobile: CircularProgressIndicator with text.
- [x] Empty / zero data -- Web: fallback message when data is null. Mobile: proper empty state with icon.
- [x] Error / failure -- Web: destructive border + message + retry. Mobile: error icon + message + back + retry.
- [x] Success / confirmation -- Web: toast on "Open in Builder". Mobile: navigates to builder.
- [x] Disabled -- Both web and mobile disable Next button when selections incomplete.
- [ ] Offline / degraded -- Neither platform handles offline state specifically (not in scope for this feature).
- [x] Permission denied -- Handled at the API level, not directly relevant to this wizard.

---

## Consistency Assessment

| Area | Web | Mobile | Consistent? |
|------|-----|--------|-------------|
| Step indicator | Nav with `aria-current` | Custom circles with Semantics | Yes (platform-appropriate) |
| Split type selection | Card grid with focus rings | Card list with AnimatedContainer | Yes |
| Difficulty selection | Badge radio group | ChoiceChip row | Yes (platform-idiomatic) |
| Goal selection | Badge radio group | Card list | Yes |
| Duration input | Number input with helper text | Slider + stepper buttons | Yes (platform-appropriate) |
| Custom day config | Badge checkboxes with keyboard | FilterChip with labels | Yes |
| Error state | Destructive border + retry | Error icon + back + retry | Yes |
| Loading state | Skeleton shimmer | Centered spinner + text | Yes (platform-idiomatic) |
| Empty state | Message + retry button | Icon + message + action | Yes |

---

## Product Improvements (Not Implemented -- Require Design Decisions)

| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | Medium | Web: preview-step | Add exercise expansion -- clicking a day could show the full exercise list with sets/reps/rest | Currently only shows first 3 exercise names. User might want to see the full workout before opening in builder. |
| 2 | Medium | Mobile: preview step | Show nutrition template in mobile preview (present in web but missing in mobile) | Web shows training day / rest day macros but mobile only shows the weekly schedule. Parity gap. |
| 3 | Low | Both platforms | Add estimated workout duration per day in the preview | Trainers commonly need to know session length before assigning to clients. |
| 4 | Low | Web: exercise-picker-dialog | Add pagination for exercise results beyond page 1 | Currently only shows "Showing X of Y exercises. Refine your search to see more." No way to load more. |

---

## Changes Made in This Audit

### Web Files Modified
1. **`program-generator-wizard.tsx`** -- Replaced `role="tablist"` step indicator with semantic `<nav><ol>` pattern; added `aria-current`, `aria-label`, and `focus-visible` styles to step buttons. Cleaned up generation state reset on back navigation.
2. **`split-type-step.tsx`** -- Added descriptive subtitle; changed to `role="radiogroup"` with `role="radio"` + `aria-checked` children; added `focus-visible` ring styles.
3. **`config-step.tsx`** -- Wrapped Difficulty and Goal in `<fieldset>` with `<legend>` and `role="radiogroup"`; added arrow key navigation between radio options; added `focus-visible` ring; added `step={1}` and helper text to number inputs.
4. **`custom-day-config.tsx`** -- Added `role="group"`, `role="checkbox"`, `aria-checked`, `aria-label`, `tabIndex`, `onKeyDown`, and `focus-visible` styles to muscle group badges.
5. **`preview-step.tsx`** -- Added `role="status"` and `aria-label` to skeleton; added subtitle and `sr-only` announcement to loading state; added `role="alert"` and `aria-live="assertive"` to error state; added `aria-label` to nutrition cards and macro abbreviations; improved null data fallback with explanatory text and retry button.

### Mobile Files Modified
1. **`step_indicator.dart`** -- Wrapped each step in `Semantics` widget with descriptive labels including step number, name, and status.
2. **`split_type_card.dart`** -- Added `Semantics` wrapper with `button: true`, `selected`, and combined label.
3. **`goal_type_card.dart`** -- Added `Semantics` wrapper with `button: true`, `selected`, and combined label.
4. **`exercise_picker_sheet.dart`** -- Replaced plain text error state with rich error UI (icon + title + description + retry button); replaced plain text empty state with rich empty UI (icon + contextual guidance).
5. **`program_generator_screen.dart`** -- Added `tooltip` to all stepper IconButtons; wrapped duration and days display in `Semantics` with descriptive labels; improved null data state with icon, text, and Generate button.

---

## Overall UX Score: 8/10

### Strengths
- Wizard flow is clear and linear with proper back/forward navigation
- Both platforms handle loading, error, and success states
- Copy is jargon-free and actionable
- Visual design is consistent with the design system
- Smooth transitions on mobile (PageView animation)
- Exercise picker dialog is well-designed with search, filters, and multi-select

### Areas Improved
- Keyboard accessibility now fully functional across all interactive elements
- Screen reader support dramatically improved with proper ARIA roles and Semantics
- Error and empty states on mobile exercise picker match the polish level of the web
- Step indicators are now semantically correct on both platforms

### Remaining Concerns
- Mobile preview step does not show nutrition template (parity gap with web)
- No offline handling on either platform
- Exercise picker lacks pagination beyond page 1 on web
