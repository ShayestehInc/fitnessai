# Code Review: Web Dashboard Phase 3 — Trainer Analytics Page

## Review Date: 2026-02-15

## Files Reviewed
- `web/src/types/analytics.ts` (new — 29 lines)
- `web/src/hooks/use-analytics.ts` (new — 26 lines)
- `web/src/components/analytics/period-selector.tsx` (new — 34 lines)
- `web/src/components/analytics/adherence-chart.tsx` (new — 95 lines)
- `web/src/components/analytics/adherence-section.tsx` (new — 133 lines)
- `web/src/components/analytics/progress-section.tsx` (new — 160 lines)
- `web/src/app/(dashboard)/analytics/page.tsx` (new — 18 lines)
- `web/src/components/layout/nav-links.tsx` (modified)
- `web/src/lib/constants.ts` (modified)

Comparison patterns reviewed:
- `web/src/hooks/use-dashboard.ts`
- `web/src/components/dashboard/stat-card.tsx`
- `web/src/components/shared/data-table.tsx`
- `web/src/components/shared/error-state.tsx`
- `web/src/components/shared/empty-state.tsx`
- `web/src/lib/api-client.ts`
- `web/src/components/shared/page-header.tsx`
- `backend/trainer/views.py` (AdherenceAnalyticsView, ProgressAnalyticsView)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `adherence-chart.tsx:17` | **Amber color is wrong — uses green instead of amber.** `hsl(142 71% 45%)` is a green hue (142 = green on the HSL wheel). The comment says "amber/yellow-green" but the actual color is visually green, making it indistinguishable from the >=80% green bar (`hsl(var(--chart-2))`). Users will see two shades of green and one red, defeating the purpose of the tri-color coding. The ticket explicitly says "amber 50-79%". | Change to a proper amber/orange hue: `"hsl(38 92% 50%)"` or use the theme's `--chart-3` or `--chart-4` which typically map to amber/orange in shadcn themes. Alternatively, match the `adherence-section.tsx` approach that uses `text-amber-600` for this tier — use the equivalent HSL for amber-600 which is approximately `hsl(32 95% 44%)`. |
| C2 | `adherence-section.tsx:82-97` | **No loading feedback when switching period.** When `days` changes, React Query's `isLoading` is only true on the *first* fetch. Subsequent period changes use `isFetching` internally. So after the first successful load, changing from 30d to 7d will show stale 30d data (because `data` is still populated and `isLoading` is false) until the new fetch completes. There is no visual feedback that new data is loading. This makes the period selector feel broken — user clicks 7d but still sees 30d data for 1-2 seconds with no indicator. | Destructure `isFetching` from the hook in addition to `isLoading`. Show a subtle loading indicator (e.g., spinner overlay or reduced opacity on the content area) when `isFetching && !isLoading` to indicate a background refetch is in progress. Alternatively, use `placeholderData: keepPreviousData` in the query config with an `isPlaceholderData` check to visually dim the stale content. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `adherence-chart.tsx:76-81` | **Recharts `onClick` handler cast is fragile for recharts 3.x.** The `entry` parameter in the `Bar` `onClick` callback is a recharts internal event object, not the raw data entry. Casting `entry as unknown as TraineeAdherence` works because recharts spreads data properties onto the event object, but this is an implementation detail, not a contract. The project uses `recharts: ^3.7.0` — in recharts 3.x the event shape may differ across minor versions, and this cast bypasses all type safety. | Use the second argument (index): `onClick={(_entry, index) => { const trainee = sorted[index]; if (trainee) { router.push(\`/trainees/${trainee.trainee_id}\`); } }}`. This is type-safe and relies on stable array indexing rather than internal recharts object shapes. |
| M2 | `adherence-chart.tsx:59-61` | **Y-axis trainee name truncation has no tooltip for the full name.** When a trainee name exceeds 15 characters, it's silently truncated to `name.slice(0, 15)...`. Ticket edge case #9 says "Truncated with title tooltip on hover." SVG `<text>` elements rendered by recharts don't natively support browser `title` tooltips. The user has no way to see the full name from the Y-axis label. | Use a custom `tick` component for the Y-axis that renders an SVG `<title>` element inside each `<text>` element: `tick={(props) => <text x={props.x} y={props.y} textAnchor="end" fill="..." fontSize={12}><title>{props.payload.value}</title>{truncated}</text>}`. Alternatively, the Tooltip shows the full name on bar hover, which partially mitigates this, but it only appears on bar hover — not when hovering the Y-axis label itself. |
| M3 | `adherence-section.tsx:82-97` and `progress-section.tsx:126-157` | **Conditional rendering allows impossible dual states.** The four branches (`isLoading`, `isError`, `data && length === 0`, `data && length > 0`) are not mutually exclusive. React Query preserves last-known `data` when an error occurs on refetch. So when `isError` is true after a previously successful fetch, `data` is still populated — both the error state AND the data content will render simultaneously, one on top of the other. | Convert to a deterministic priority chain: render only the highest-priority branch. For example: `{isLoading ? <Skeleton/> : isError ? <ErrorState/> : !data || data.trainee_adherence.length === 0 ? <EmptyState/> : <DataContent/>}`. This ensures exactly one state renders. Apply the same pattern to both `adherence-section.tsx` and `progress-section.tsx`. |
| M4 | `adherence-section.tsx:91-97` | **Empty state message may be misleading.** When `data.trainee_adherence.length === 0`, the UI shows "No active trainees." However, the backend only returns trainees that have `TraineeActivitySummary` records for the selected date range (it uses `.values('trainee__id', ...)` on the filtered summaries queryset). A trainer with 10 active trainees who have no tracking data for the selected period will see "No active trainees" — which is factually wrong and could be alarming. | Change empty state text to "No adherence data for this period" with description "No trainees have logged activity in the last {days} days. They'll appear here once they start tracking." This accurately reflects the data semantics. |
| M5 | `period-selector.tsx:22-28` | **Missing keyboard navigation for radio group.** The component correctly uses `role="radiogroup"` and `role="radio"` semantically, but arrow key navigation is not implemented. Per the WAI-ARIA Radio Group pattern, Left/Up arrow should move to the previous radio, Right/Down should move to the next. Currently all three buttons have implicit `tabIndex={0}`, so Tab stops on every button — this violates the roving tabindex pattern for radio groups. Notably, the previous pipeline's UX audit (tasks/ux-audit.md, item #1) specifically fixed this exact same issue in `appearance-section.tsx`. | Implement roving tabindex: only the selected button gets `tabIndex={0}`, others get `tabIndex={-1}`. Add `onKeyDown` handler on the group container for ArrowLeft/ArrowRight/ArrowUp/ArrowDown that cycles through options, calls `onChange`, and moves focus. Reference `appearance-section.tsx` for the exact pattern already established in this codebase. |
| M6 | `use-analytics.ts:13` | **`days` parameter has no type narrowing.** The `days` parameter is typed as `number` but the valid values are only `{7, 14, 30}`. Passing `NaN`, `0`, `-1`, `Infinity`, or `3.14` would produce malformed URLs like `?days=NaN` or `?days=Infinity`. The backend silently defaults invalid values to 30, but the queryKey would contain garbage values causing cache misses on equivalent requests. | Type the parameter as `days: 7 | 14 | 30` for compile-time safety. This also requires updating `PeriodSelectorProps.onChange` and `PeriodSelectorProps.value` to `7 | 14 | 30` and the `PERIODS` array elements to propagate the literal types, which prevents any caller from passing invalid values. |
| M7 | `progress-section.tsx:65-96` | **Column `key` values don't match TypeScript property names.** `key: "name"` doesn't match any property on `TraineeProgressEntry` (the actual property is `trainee_name`). Similarly, `key: "current_weight"` and `key: "weight_change"` are fine, but `key: "name"` is misleading. While `DataTable` only uses `key` as a React key (not as a data accessor), this creates a maintenance trap: if anyone adds sort-by-column functionality using column keys to access object properties, it will silently fail for the "name" column. | Use `key: "trainee_name"` to match the actual property name. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `adherence-section.tsx:25-38` | **StatDisplay duplicates the existing StatCard component.** `components/dashboard/stat-card.tsx` is nearly identical (Card + icon + value). StatDisplay adds color-coded text, but this could be achieved by extending StatCard with an optional `valueClassName` prop. | Extend `StatCard` with a `valueClassName?: string` prop and use it instead of creating a parallel component. |
| m2 | `adherence-chart.tsx:15-19` vs `adherence-section.tsx:13-17` | **Color representations differ between chart and stat cards for the same data tiers.** The chart uses `hsl(var(--chart-2))` and `hsl(var(--destructive))` while stat cards use Tailwind classes `text-green-600`, `text-amber-600`, `text-red-600`. These may not visually match, creating an inconsistent palette. | Extract a shared constant or utility for the three adherence tier colors so chart bars and stat card text use the same visual palette. |
| m3 | `adherence-chart.tsx:69` | **`labelFormatter` is a no-op.** `labelFormatter={(label: React.ReactNode) => label}` returns the label unchanged. Recharts uses the label as-is when no `labelFormatter` is provided. | Remove `labelFormatter` prop entirely. |
| m4 | `progress-section.tsx:70` | **Name column has `title={row.trainee_name}` but no truncation CSS.** The `title` tooltip only helps when text overflows, but there's no `truncate` or `max-w-*` class, so the name always displays in full and the title tooltip is useless. | Add `className="font-medium truncate max-w-[200px]"` to enable truncation for very long names, making the `title` attribute meaningful. Or remove `title` if truncation is not desired. |
| m5 | `analytics/page.tsx` | **No Next.js metadata export.** App Router pages should export a `metadata` object for SEO and browser tab title. | Add `export const metadata: Metadata = { title: "Analytics" }` with `import type { Metadata } from "next"`. |
| m6 | `adherence-chart.tsx:22-27` | **`tooltipContentStyle` is declared at module level but the same pattern exists in `progress-charts.tsx`.** If the shared tooltip style diverges between files, dark mode or theme changes will look inconsistent across pages. | Extract to a shared constant in `lib/chart-utils.ts` or similar. |
| m7 | `adherence-chart.tsx:36` | **Client-side sort is redundant.** The backend's `AdherenceAnalyticsView` already returns `trainee_adherence` sorted by `-adherence_rate` (line 888 of `views.py`). The `[...data].sort(...)` on every render is wasted CPU. | Remove the client-side sort since the backend guarantees the order. Or, if defensive coding is preferred, memoize with `useMemo`. |
| m8 | `adherence-section.tsx:45` and `progress-section.tsx:107` | **`Array.from({ length: N }).map((_, i) => ...)` with index key.** While functionally correct for static skeletons, this pattern is verbose. | Use a simple array literal: `{[0, 1, 2].map((i) => ...)}`. |
| m9 | `adherence-chart.tsx:65` | **Tooltip `formatter` type is loose.** The recharts `Formatter` type is `(value: ValueType, name: NameType, props: Props) => ReactNode`. Typing `value` as `number | undefined` may conflict with stricter recharts type definitions in future minor versions. | Use `formatter={(value: number) => [\`${value.toFixed(1)}%\`, "Adherence"]}` since `adherence_rate` is always a number. |

---

## Security Concerns

1. **No XSS risk from trainee names.** Recharts renders SVG `<text>` elements (not HTML). React's DataTable renders inside JSX `<span>` elements with automatic escaping. **PASS.**

2. **API URLs use query parameter for `days`.** The value is constrained to `{7, 14, 30}` by the PeriodSelector UI. The backend also validates and clamps `days` to `[1, 365]`. No injection vector. **PASS.**

3. **No secrets or tokens in source code.** All API calls use `apiClient` which handles auth via `token-manager`. Reviewed all new files — no hardcoded credentials. **PASS.**

4. **Authentication enforced.** Both backend views use `[IsAuthenticated, IsTrainer]` permission classes. The frontend `(dashboard)` layout group enforces auth via middleware. **PASS.**

5. **No IDOR vulnerability.** Backend filters trainees by `parent_trainer=request.user`. A trainer can only see their own trainees' analytics. Navigation URLs use `trainee_id` which is also scoped by the trainer on the detail endpoint (`/api/trainer/trainees/{id}/`). **PASS.**

6. **No data exposure.** API responses contain trainee names, emails, and weight data — all appropriate for a trainer to see. No sensitive fields leaked. **PASS.**

---

## Performance Concerns

1. **No unbounded data risk for the chart.** The backend returns all active trainees in a flat list (no pagination). For 50+ trainees the chart dynamically sizes itself (`n * 36 + 40`px). For 100 trainees this creates a ~3640px SVG — expensive but not catastrophic. For 500+ trainees (unlikely for personal trainers) this could cause rendering jank. **LOW RISK** — acceptable for the use case. Consider adding a `max-h-[600px] overflow-y-auto` wrapper for future-proofing.

2. **Client-side sort is redundant** (see m7). Backend pre-sorts. **NEGLIGIBLE IMPACT.**

3. **Both queries use `staleTime: 5 * 60 * 1000`.** Reduces unnecessary refetches for analytics data that changes infrequently. **GOOD.**

4. **No N+1 queries.** Backend uses annotated querysets for adherence and `select_related`/`prefetch_related` for progress. **PASS.**

5. **No unnecessary re-renders.** `PeriodSelector` receives stable `setDays` from `useState`. `AdherenceBarChart` only re-renders when `data` changes. `sorted` array is recomputed on each render — could be memoized with `useMemo` for larger datasets but impact is negligible for typical trainee counts (<100). **PASS.**

---

## Acceptance Criteria Verification

### Navigation & Layout (AC-1 through AC-3)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-1 | "Analytics" nav item with `BarChart3` icon between Invitations and Notifications | **PASS** | `nav-links.tsx:21` — positioned at index 3 between Invitations (index 2) and Notifications (index 4) |
| AC-2 | Analytics page at `/analytics` within dashboard layout | **PASS** | `app/(dashboard)/analytics/page.tsx` exists in the `(dashboard)` route group |
| AC-3 | PageHeader with title "Analytics" and description | **PASS** | `page.tsx:10-13` |

### Adherence Section (AC-4 through AC-11)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-4 | Period selector 7/14/30, default 30, refetches on change | **PASS** | `adherence-section.tsx:70` — `useState(30)`, queryKey includes `days` |
| AC-5 | Three stat cards: Food Logged, Workouts Logged, Protein Goal Hit | **PASS** | `adherence-section.tsx:101-116` |
| AC-6 | Values with 1 decimal place, color indicator: green >= 80%, amber 50-79%, red < 50% | **PARTIAL** | Stat card colors are correct (`getIndicatorColor` at line 13-17). Chart bar colors are wrong — amber tier renders green (C1). |
| AC-7 | Horizontal bar chart, trainee names on Y-axis, percentage on X-axis, sorted highest to lowest | **PASS** | `adherence-chart.tsx:43-91` |
| AC-8 | Clicking a bar navigates to `/trainees/{id}` | **PASS** | `adherence-chart.tsx:76-81` — works but has fragile typing (M1) |
| AC-9 | Loading skeleton while data fetches | **PASS** | `AdherenceSkeleton` at `adherence-section.tsx:41-67` |
| AC-10 | Error state with retry button | **PASS** | `adherence-section.tsx:84-88` |
| AC-11 | Empty state when no active trainees | **PASS** | `adherence-section.tsx:91-97` — message accuracy concern (M4) but functionally meets AC |

### Progress Section (AC-12 through AC-18)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-12 | Table with Name, Current Weight (kg), Weight Change (+/- indicator and color), Goal | **PASS** | `progress-section.tsx:65-96` — all four columns present |
| AC-13 | Weight change green for loss when weight_loss, green for gain when muscle_gain, neutral otherwise | **PASS** | `getWeightChangeColor` at lines 25-41 — logic verified correct |
| AC-14 | Null weight shows "—" | **PASS** | `WeightChangeCell` returns `<span>—</span>` for null; current weight column also shows "—" for null |
| AC-15 | Row click navigates to `/trainees/{id}` | **PASS** | `progress-section.tsx:153` — `onRowClick` handler |
| AC-16 | Loading skeleton | **PASS** | `ProgressSkeleton` at lines 98-114 |
| AC-17 | Error state with retry | **PASS** | `progress-section.tsx:128-132` |
| AC-18 | Empty state when no trainees | **PASS** | `progress-section.tsx:135-141` |

### General (AC-19 through AC-22)

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC-19 | Both sections load independently with own loading/error/empty states | **PASS** | Separate hooks, separate state management |
| AC-20 | All API calls use authenticated `apiClient.get()` with types | **PASS** | `use-analytics.ts:12-14, 22-23` |
| AC-21 | New TypeScript types for both API responses | **PASS** | `types/analytics.ts` — 4 interfaces covering both responses |
| AC-22 | Adherence data uses `staleTime: 5 * 60 * 1000` | **PASS** | `use-analytics.ts:15` |

### Summary: 21/22 ACs PASS, 1 PARTIAL PASS (AC-6 — amber color wrong in chart bars)

---

## Edge Case Verification

| # | Edge Case | Status | Notes |
|---|-----------|--------|-------|
| 1 | Zero trainees — both sections show empty states | PASS | Different messages per section |
| 2 | Null weight data — shows "—" | PASS | Both `current_weight` and `weight_change` handled |
| 3 | Null goal / no profile — shows "Not set" | PASS | `formatGoal(null)` returns "Not set" |
| 4 | All trainees at 0% — chart still shows names | PASS | `domain={[0, 100]}` ensures Y-axis labels render with zero-width bars |
| 5 | Single trainee — chart and table work with 1 row | PASS | Chart height = `max(1*36+40, 120) = 120px` |
| 6 | 50+ trainees — chart scrolls vertically | PARTIAL | Chart dynamically grows but no scroll container — ticket says "chart scrolls vertically" implying a max-height with overflow scroll. Currently the entire page stretches. |
| 7 | Rapid period switching — old request cancelled | PARTIAL | React Query 5 does abort on queryKey change. But no visual feedback that data is refreshing (C2). |
| 8 | Network failure mid-page — one section errors while other succeeds | PASS | Independent hooks, independent error states |
| 9 | Very long trainee names — truncated with tooltip | PARTIAL | Chart truncates at 15 chars but no tooltip on SVG text (M2). Table has `title` but no truncation CSS (m4). |

---

## Quality Score: 6/10

### Breakdown:
- **Correctness: 7/10** — Functionally works for the happy path. Amber color is wrong (C1), stale data shown on period change with no indicator (C2), conditional rendering allows overlapping states (M3).
- **Type Safety: 7/10** — Good TypeScript interfaces defined. One fragile `as unknown as` cast (M1). `days` parameter untyped (M6).
- **Accessibility: 6/10** — Radio group semantics present but missing keyboard navigation (M5). This is the same issue that was specifically found and fixed in the previous pipeline for `appearance-section.tsx`.
- **Code Quality: 8/10** — Clean, well-structured, follows existing patterns. Minor duplication with StatCard (m1).
- **Edge Case Handling: 7/10** — Most cases handled. Missing scroll container for large trainer rosters. Name truncation tooltip missing in chart.
- **Pattern Consistency: 7/10** — Follows hook/component patterns well. Color system inconsistency between chart and stat cards (m2). StatDisplay duplicates StatCard (m1).

### Strengths:
- Clean separation into small, focused components (7 files, all under 160 lines)
- Independent loading/error/empty states per section (AC-19)
- Proper reuse of existing shared components (DataTable, ErrorState, EmptyState, PageHeader)
- Correct weight change color logic relative to goal
- Thorough null handling throughout
- Backend API types accurately model the actual API responses
- Good use of semantic HTML (`<section>`, `aria-labelledby`, `aria-hidden`)

### Weaknesses:
- Amber color in chart is actually green (C1) — the tri-color system is visually broken
- No loading feedback when switching periods (C2) — UI feels unresponsive
- Conditional rendering allows overlapping error + data states (M3)
- Radio group missing keyboard navigation (M5) — identical bug to what was fixed last pipeline
- Recharts onClick typing is fragile for recharts 3.x (M1)

---

## Recommendation: REQUEST CHANGES

Two critical issues (C1: wrong amber color making the tri-color system useless, C2: no refetch loading indicator making the period selector feel broken) and seven major issues need to be addressed. The feature is close — architecture, structure, and patterns are solid — but it has visual correctness and interaction reliability problems that would be immediately noticeable to users. The wrong amber color means trainers cannot distinguish "okay" (50-79%) from "great" (>=80%) adherence at a glance, which undermines the core value of the analytics page. The lack of loading feedback during period changes makes the selector feel like it's doing nothing.

Fix the 2 critical and 7 major issues, then this is ready to ship.
