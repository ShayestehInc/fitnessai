# UX Audit: Web Dashboard Phase 3 -- Trainer Analytics Page

## Audit Date: 2026-02-15

## Pages & Components Reviewed
- Analytics page: `web/src/app/(dashboard)/analytics/page.tsx`
- Adherence section: `web/src/components/analytics/adherence-section.tsx`
- Period selector: `web/src/components/analytics/period-selector.tsx`
- Adherence chart: `web/src/components/analytics/adherence-chart.tsx`
- Progress section: `web/src/components/analytics/progress-section.tsx`
- Supporting: `web/src/hooks/use-analytics.ts`, `web/src/types/analytics.ts`, `web/src/lib/chart-utils.ts`
- Reference patterns: `web/src/components/shared/empty-state.tsx`, `web/src/components/shared/error-state.tsx`, `web/src/components/shared/data-table.tsx`, `web/src/components/dashboard/stat-card.tsx`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | High | AdherenceSection (empty state) | Empty state said "No adherence data for this period" with no CTA -- inconsistent with Trainees page which has "Send Invitation" button. Ticket specifies "No active trainees" + "Invite trainees to see analytics". | Changed to "No active trainees" with "Invite Trainee" CTA button linking to `/invitations` -- FIXED |
| 2 | High | ProgressSection (empty state) | Empty state had no CTA action button and used `TrendingUp` icon which doesn't clearly represent progress/weight data. Inconsistent with other pages that include actionable buttons. | Changed icon to `Scale`, added "Invite Trainee" CTA button, improved description to mention weight tracking -- FIXED |
| 3 | High | StatDisplay (adherence cards) | Custom `StatDisplay` component duplicated the `StatCard` pattern from `dashboard/stat-card.tsx` rather than reusing the shared component. Created inconsistency risk if `StatCard` is updated. | Replaced custom `StatDisplay` with shared `StatCard` component using `valueClassName` for colored indicators -- FIXED |
| 4 | Medium | StatCard (adherence) | Colored percentage values (green/amber/red) conveyed quality level through color alone. Users with color vision deficiency or screen reader users would miss the meaning entirely. | Added `description` prop with text labels: "Above target" (>=80%), "Below target" (50-79%), "Needs attention" (<50%) -- FIXED |
| 5 | Medium | PeriodSelector | No visible focus indicator on radio buttons. When tabbing through the page, focus was invisible on the period selector, failing WCAG 2.4.7 Focus Visible. | Added `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` styles -- FIXED |
| 6 | Medium | PeriodSelector | No disabled state support. When adherence data was loading, the period selector remained interactive, potentially triggering multiple concurrent requests. | Added `disabled` prop with `disabled:pointer-events-none disabled:opacity-50` styling; parent passes `disabled={isLoading}` -- FIXED |
| 7 | Medium | PeriodSelector | Inactive buttons used `hover:bg-muted/80` which is nearly indistinguishable from `bg-muted`, providing no meaningful hover feedback. No `active` state for mobile touch feedback. | Changed hover to `hover:bg-accent hover:text-accent-foreground` for better contrast. Added `active:bg-primary/90` (active) and `active:bg-accent/80` (inactive) for touch feedback -- FIXED |
| 8 | Medium | AdherenceSection (header) | Period selector and heading were in `flex items-center justify-between` which could cause the heading and selector to collide on narrow viewports, especially on mobile. | Changed to `flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between` so they stack on mobile -- FIXED |
| 9 | Medium | AdherenceBarChart | Amber color was hardcoded as `hsl(32 95% 44%)` instead of using a CSS custom property, which would break in dark mode or custom themes. | Changed to `hsl(var(--chart-4))` for theme-aware amber color -- FIXED |
| 10 | Medium | AdherenceBarChart | Tooltip content style was defined locally instead of using the shared `tooltipContentStyle` from `chart-utils.ts`, creating a maintenance risk. | Refactored to import from `@/lib/chart-utils` -- FIXED |
| 11 | Low | AdherenceSection (fetching state) | When switching periods, the section faded to 50% opacity but had no `duration` on the transition, making the fade abrupt rather than smooth. | Added `duration-200` to the opacity transition class -- FIXED |
| 12 | Low | AdherenceChart (card title) | Chart card title said "Trainee Adherence (30-day)" but gave no indication of how many trainees were being shown. | Added trainee count: "Trainee Adherence (30-day) 5 trainees" -- FIXED |
| 13 | Low | ProgressSection (card title) | Same as above -- no trainee count indicator. | Added trainee count span to "Trainee Progress" card title -- FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | AA (2.4.7) | PeriodSelector radio buttons had no visible focus indicator -- Tab key focus was invisible. | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` -- FIXED |
| 2 | A (1.1.1) | PeriodSelector buttons displayed only "7d", "14d", "30d" with no expanded aria-label. Screen readers would announce cryptic shortened text. | Added `aria-label` with full text: "7 days", "14 days", "30 days" via `PERIOD_LABELS` map -- FIXED |
| 3 | A (1.3.1) | AdherenceSkeleton had no `role="status"` or screen reader announcement. Screen readers could not inform users that data was loading. | Added `role="status"` and `aria-label="Loading adherence data"` plus `sr-only` span -- FIXED |
| 4 | A (1.3.1) | ProgressSkeleton had no `role="status"` or screen reader announcement. | Added `role="status"` and `aria-label="Loading progress data"` plus `sr-only` span -- FIXED |
| 5 | AA (4.1.3) | When switching periods, the data area faded to 50% opacity (`isFetching`) but screen readers received no notification that a refresh was occurring. | Added `sr-only` div with `role="status"` and `aria-live="polite"` announcing "Refreshing adherence data..." when `isFetching` is true -- FIXED |
| 6 | AA (4.1.3) | Same issue on ProgressSection during background refetch. | Added matching `sr-only` refresh announcement for progress section -- FIXED |
| 7 | A (1.1.1) | AdherenceBarChart SVG had no accessible name or alternative content for screen readers. The chart was completely opaque to assistive technology. | Added `role="img"` with descriptive `aria-label` on the chart container. Added `sr-only` unordered list with all trainee names and adherence percentages as alternative content -- FIXED |
| 8 | A (1.1.1) | Null weight values in ProgressSection table showed an em-dash character with no `aria-label`, which screen readers might announce as "dash" or skip entirely. | Added `aria-label="No data"` to all em-dash `<span>` elements in both `current_weight` and `weight_change` columns -- FIXED |
| 9 | AA (1.4.1) | Colored stat card values (green/amber/red) relied solely on color to convey status. Color alone fails WCAG 1.4.1 Use of Color. | Added text descriptions ("Above target", "Below target", "Needs attention") below the value via `StatCard` description prop -- FIXED |

---

## Missing States

### Adherence Section
- [x] Loading / skeleton -- `AdherenceSkeleton` renders 3 stat card placeholders + chart placeholder, with `role="status"` and `sr-only` text
- [x] Empty / zero data -- `EmptyState` with `BarChart3` icon, "No active trainees" title, and "Invite Trainee" CTA
- [x] Error / failure -- `ErrorState` with "Failed to load adherence data" and retry button
- [x] Success / populated -- Stat cards with colored values + descriptions + adherence bar chart
- [x] Refreshing / background fetch -- `opacity-50` transition with `aria-busy` and `sr-only` "Refreshing adherence data..." announcement
- [x] Disabled -- Period selector disabled during initial load

### Progress Section
- [x] Loading / skeleton -- `ProgressSkeleton` renders table header + 4 row placeholders, with `role="status"` and `sr-only` text
- [x] Empty / zero data -- `EmptyState` with `Scale` icon, "No progress data" title, and "Invite Trainee" CTA
- [x] Error / failure -- `ErrorState` with "Failed to load progress data" and retry button
- [x] Success / populated -- DataTable with clickable rows, name truncation with title tooltip
- [x] Refreshing / background fetch -- `opacity-50` transition with `aria-busy` and `sr-only` refresh announcement

### Period Selector
- [x] Default -- 30-day selected with primary styling
- [x] Active -- `bg-primary text-primary-foreground` with `active:bg-primary/90`
- [x] Hover -- `hover:bg-accent hover:text-accent-foreground` on inactive buttons
- [x] Focus -- `focus-visible:ring-2 focus-visible:ring-ring` ring indicator
- [x] Disabled -- `disabled:pointer-events-none disabled:opacity-50` during loading

---

## Copy Assessment

| Element | Copy | Verdict |
|---------|------|---------|
| Page title | "Analytics" | Clear, matches nav link |
| Page description | "Track trainee performance and adherence" | Informative, tells trainer what the page does |
| Adherence heading | "Adherence" | Clear section label |
| Progress heading | "Progress" | Clear section label |
| Period button labels | "7d" / "14d" / "30d" | Concise; expanded aria-labels provide "7 days" etc. for screen readers |
| Stat card titles | "Food Logged" / "Workouts Logged" / "Protein Goal Hit" | Clear, action-oriented |
| Stat card descriptions | "Above target" / "Below target" / "Needs attention" | Meaningful quality labels that complement the colored values |
| Chart title | "Trainee Adherence (30-day) 5 trainees" | Clear, includes count for context |
| Progress table title | "Trainee Progress 5 trainees" | Matches chart pattern |
| Adherence empty title | "No active trainees" | Direct |
| Adherence empty description | "Invite trainees to see their adherence analytics here." | Actionable, explains next step |
| Progress empty title | "No progress data" | Direct |
| Progress empty description | "Trainees will appear here once they start tracking their weight." | Sets expectation |
| Adherence error | "Failed to load adherence data" | Clear, not technical |
| Progress error | "Failed to load progress data" | Clear, matches pattern |
| Null weight value | em-dash with aria-label "No data" | Visual dash + accessible label |
| Goal "Not set" | "Not set" | Clear for null goal |

---

## Consistency Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Stat cards | Consistent (after fix) | Now uses shared `StatCard` from `dashboard/stat-card.tsx` instead of custom `StatDisplay` |
| Empty states | Consistent (after fix) | Both sections use shared `EmptyState` with CTA buttons, matching Trainees page pattern |
| Error states | Consistent | Both sections use shared `ErrorState` with retry, matching all other pages |
| Skeleton loading | Consistent | Both sections have purpose-built skeletons with `role="status"` and `sr-only` text |
| Section headings | Consistent | Both sections use `<section aria-labelledby>` with `<h2>` headings |
| Chart tooltip | Consistent (after fix) | Uses shared `tooltipContentStyle` from `chart-utils.ts` |
| Chart colors | Consistent (after fix) | All colors use CSS custom properties (`--chart-2`, `--chart-4`, `--destructive`) |
| Table row click | Consistent | Uses `DataTable` with `onRowClick` which provides `cursor-pointer`, `tabIndex`, keyboard support, and focus ring |
| Navigation pattern | Consistent | Both chart bars and table rows navigate to `/trainees/{id}`, matching trainee list behavior |

---

## Responsiveness Assessment

| Aspect | Status |
|--------|--------|
| Stat cards grid | `sm:grid-cols-3` on desktop, stacks to single column on mobile |
| Section header layout | `flex-col gap-3 sm:flex-row sm:items-center sm:justify-between` -- stacks on mobile, side-by-side on desktop |
| Adherence chart | `ResponsiveContainer` handles resize; Y-axis width is fixed at 120px |
| Progress table | Wrapped in `overflow-x-auto` via DataTable for horizontal scroll on mobile |
| Period selector | Compact `px-3 py-1.5` touch-friendly button sizing |
| Page overall | `space-y-8` vertical stacking adapts naturally to all viewport sizes |

---

## Fixes Implemented

### 1. `web/src/components/analytics/adherence-section.tsx`
- Replaced custom `StatDisplay` with shared `StatCard` component for consistency
- Added `getIndicatorDescription()` function providing text labels ("Above target", "Below target", "Needs attention") for each stat card, addressing color-only information conveyance (WCAG 1.4.1)
- Added `role="status"`, `aria-label`, and `sr-only` text to `AdherenceSkeleton` for screen reader loading announcements
- Added `sr-only` live region (`aria-live="polite"`) announcing "Refreshing adherence data..." during background refetch
- Changed empty state to "No active trainees" with "Invite Trainee" CTA button
- Made section header responsive: `flex-col gap-3 sm:flex-row` for mobile stacking
- Added `disabled={isLoading}` to PeriodSelector during initial data load
- Added `duration-200` to opacity transition for smoother period-switch fade
- Added trainee count to chart card title

### 2. `web/src/components/analytics/period-selector.tsx`
- Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` for visible keyboard focus
- Added `disabled` prop with `disabled:pointer-events-none disabled:opacity-50` styling
- Added `PERIOD_LABELS` map and `aria-label` for expanded screen reader text ("7 days", "14 days", "30 days")
- Improved hover to `hover:bg-accent hover:text-accent-foreground` for better contrast
- Added `active:bg-primary/90` and `active:bg-accent/80` for mobile touch feedback
- Added `disabled` guard to keyboard handler

### 3. `web/src/components/analytics/progress-section.tsx`
- Changed empty state icon from `TrendingUp` to `Scale` (more relevant to weight progress)
- Added "Invite Trainee" CTA button to empty state
- Improved empty state description: "Trainees will appear here once they start tracking their weight."
- Added `aria-label="No data"` to all em-dash spans for null weight values
- Added `role="status"`, `aria-label`, and `sr-only` text to `ProgressSkeleton`
- Added `isFetching` opacity transition with `sr-only` refresh announcement
- Added trainee count to card title

### 4. `web/src/components/analytics/adherence-chart.tsx`
- Changed amber color from hardcoded `hsl(32 95% 44%)` to theme-aware `hsl(var(--chart-4))`
- Added `role="img"` and descriptive `aria-label` to chart container
- Added `sr-only` unordered list with all trainee adherence data as screen reader alternative
- Refactored tooltip to use shared `tooltipContentStyle` from `chart-utils.ts`
- Extracted `navigateToTrainee` function for cleaner click handler

---

## Items Not Fixed (Require Design Decisions or Out of Scope)

1. **Bar chart keyboard navigation** -- Recharts does not natively support keyboard interaction on individual bars. Adding keyboard navigation would require a custom implementation wrapping each bar in a focusable element, which conflicts with how SVG-based recharts renders. The `sr-only` list provides an accessible alternative, and the DataTable in the progress section provides keyboard-navigable trainee access. Future enhancement: consider replacing recharts with a library that supports ARIA-compliant chart interactions.

2. **Chart-within-card scroll for 50+ trainees** -- The chart dynamically grows based on trainee count (36px per bar). For very large trainee counts (50+), the chart card becomes tall. The page scrolls naturally, keeping the chart content accessible. A `max-h` with internal scroll was considered but creates a scroll-within-scroll pattern that is worse UX on mobile. Acceptable trade-off.

---

## Overall UX Score: 9/10

### Breakdown:
- **State Handling:** 10/10 -- Every component handles all relevant states: loading (with skeleton and sr-only text), empty (with icon, description, and CTA), error (with message and retry), populated (with full data), and refreshing (with opacity fade and sr-only announcement)
- **Accessibility:** 9/10 -- Proper ARIA roles on skeletons and chart, roving tabindex on period selector, focus-visible rings, aria-labels on truncated content and null values, sr-only chart data list, live region for background refetch. Bar chart lacks keyboard navigation (recharts limitation).
- **Visual Consistency:** 9/10 -- Uses shared StatCard, EmptyState, ErrorState, DataTable components. Chart colors use CSS custom properties. Tooltip styling shared via chart-utils.
- **Copy Clarity:** 10/10 -- All copy is clear, actionable, and non-technical. Empty states explain next steps. Stat descriptions complement color indicators.
- **Responsiveness:** 9/10 -- Stat cards stack on mobile, section headers stack on mobile, table scrolls horizontally, chart uses ResponsiveContainer. Period selector has touch-friendly active states.
- **Feedback & Interaction:** 9/10 -- Period switch triggers immediate visual feedback (opacity fade), loading shows skeleton, errors show retry, chart bars have cursor:pointer, table rows have hover highlight and focus ring.

### Strengths:
- Independent loading/error/empty states for each section (adherence and progress) so one can succeed while the other fails
- Proper use of shared components (StatCard, EmptyState, ErrorState, DataTable) maintaining consistency across the dashboard
- Theme-aware chart colors using CSS custom properties for correct dark mode behavior
- Comprehensive screen reader support including chart data alternative text, loading announcements, and refresh notifications
- Period selector follows the WAI-ARIA radiogroup pattern with roving tabindex and arrow key navigation

### Areas for Future Improvement:
- Add keyboard navigation for individual chart bars (requires recharts alternative or custom overlay)
- Consider adding chart data export (CSV) for accessibility compliance beyond WCAG (useful for trainers who want to share reports)
- Add animated skeleton shimmer for loading states (currently using static pulse animation)
- Consider adding a "no change" label for zero weight change instead of showing "+0.0 kg"

---

**Audit completed by:** UX Auditor Agent
**Date:** 2026-02-15
**Pipeline:** 9 -- Web Dashboard Phase 3 (Trainer Analytics)
**Verdict:** PASS -- All critical and major UX and accessibility issues fixed. 4 component files modified with 13 usability fixes and 9 accessibility fixes. Build and lint pass cleanly.
