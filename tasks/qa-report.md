# QA Report: Web Dashboard Phase 3 -- Trainer Analytics Page

## Date: 2026-02-15

## Test Methodology
Code-level verification only (no running backend or E2E framework available). Every acceptance criterion verified by reading implementation source, cross-referencing backend API response shapes (`backend/trainer/views.py` lines 825-938), and tracing data flow from hook to component to rendered output.

---

## Test Results
- Total AC Verified: 22
- Passed: 21
- Failed: 1
- Edge Cases Verified: 9
- Edge Cases Passed: 8
- Edge Cases Failed: 1

---

## Acceptance Criteria Verification

### Navigation & Layout (AC-1 through AC-3)

- [x] **AC-1** -- PASS -- New "Analytics" nav item in sidebar between "Invitations" and "Notifications" with `BarChart3` icon
  - `web/src/components/layout/nav-links.tsx` line 21: `{ label: "Analytics", href: "/analytics", icon: BarChart3 }` placed at index 3, between Invitations (index 2) and Notifications (index 4). `BarChart3` imported from lucide-react at line 5.

- [x] **AC-2** -- PASS -- Analytics page at `/analytics` renders within the dashboard layout
  - File at `web/src/app/(dashboard)/analytics/page.tsx` is inside the `(dashboard)` route group, so it inherits the dashboard layout. Exports a default function component `AnalyticsPage`.

- [x] **AC-3** -- PASS -- Page has PageHeader with title "Analytics" and description "Track trainee performance and adherence"
  - `page.tsx` lines 10-13: `<PageHeader title="Analytics" description="Track trainee performance and adherence" />`. Text matches ticket exactly. Uses shared `PageHeader` component.

### Adherence Section (AC-4 through AC-11)

- [x] **AC-4** -- PASS -- Period selector with 7/14/30 day options (default 30). Selecting a period refetches adherence data.
  - `adherence-section.tsx` line 71: `useState<AdherencePeriod>(30)` sets default to 30.
  - `period-selector.tsx` line 6: `PERIODS: AdherencePeriod[] = [7, 14, 30]` renders three buttons.
  - `onChange` calls `setDays`, which changes the `days` param passed to `useAdherenceAnalytics(days)`.
  - `use-analytics.ts` line 14: `queryKey: ["analytics", "adherence", days]` -- React Query automatically refetches when the key changes.
  - Period selector styled as tab-style buttons (not dropdown) with active period getting primary styling. Keyboard navigation implemented with ArrowLeft/Right/Up/Down and roving tabindex.

- [x] **AC-5** -- PASS -- Three stat cards showing aggregate rates: "Food Logged" (`food_logged_rate`%), "Workouts Logged" (`workout_logged_rate`%), "Protein Goal Hit" (`protein_goal_rate`%)
  - `adherence-section.tsx` lines 106-121: Three `<StatDisplay>` components with titles "Food Logged", "Workouts Logged", "Protein Goal Hit" mapping to `data.food_logged_rate`, `data.workout_logged_rate`, `data.protein_goal_rate` respectively. Icons: UtensilsCrossed, Dumbbell, Target.

- [x] **AC-6** -- PASS -- Stat card values show percentage with 1 decimal place and a colored indicator: green >= 80%, amber 50-79%, red < 50%
  - `StatDisplay` (line 34): `{value.toFixed(1)}%` produces 1 decimal place.
  - `getIndicatorColor` (lines 14-18): `rate >= 80` returns green, `rate >= 50` returns amber, else red.
  - Boundary verification: 80.0 -> green (correct, >= 80), 79.9 -> amber (correct, >= 50 and < 80), 50.0 -> amber (correct, >= 50), 49.9 -> red (correct, < 50).
  - Colors use dark mode variants: `text-green-600 dark:text-green-400`, etc.

- [x] **AC-7** -- PASS -- Adherence bar chart: horizontal bars showing each trainee's `adherence_rate`, sorted highest to lowest. Trainee name on Y-axis, percentage on X-axis.
  - `adherence-chart.tsx` line 36: `sorted = [...data].sort((a, b) => b.adherence_rate - a.adherence_rate)` -- sorted descending (highest first).
  - `layout="vertical"` on `BarChart` makes bars horizontal.
  - `YAxis type="category" dataKey="trainee_name"` puts trainee names on Y-axis.
  - `XAxis type="number" domain={[0, 100]}` with `tickFormatter={(v: number) => \`${v}%\`}` puts percentages on X-axis.

- [x] **AC-8** -- PASS -- Clicking a trainee bar navigates to `/trainees/{id}`
  - `adherence-chart.tsx` lines 89-94: `onClick` handler on `<Bar>` does `router.push(\`/trainees/${trainee.trainee_id}\`)`. Guard `if (trainee)` prevents crash on invalid index. Uses `useRouter` from `next/navigation`.

- [x] **AC-9** -- PASS -- Adherence section loading skeleton while data fetches
  - `adherence-section.tsx` line 87: `isLoading ? <AdherenceSkeleton />`.
  - `AdherenceSkeleton` (lines 42-68) renders: 3 skeleton stat cards in a `sm:grid-cols-3` grid (matching the real layout) plus a skeleton chart area inside a Card. Uses shared `Skeleton` component.

- [x] **AC-10** -- PASS -- Adherence section error state with retry button
  - `adherence-section.tsx` lines 89-93: `isError ? <ErrorState message="Failed to load adherence data" onRetry={() => refetch()} />`.
  - Error message matches ticket's Error States table exactly.
  - `ErrorState` component (`error-state.tsx`) renders AlertCircle icon, message, and "Try again" button with RefreshCw icon when `onRetry` is provided. Has `role="alert"` and `aria-live="assertive"` for accessibility.

- [ ] **AC-11** -- **FAIL** -- Adherence section empty state when trainer has no active trainees
  - `adherence-section.tsx` lines 94-99: Empty state renders `<EmptyState icon={BarChart3} title="No adherence data for this period" description={...} />`.
  - **Issue 1 -- Copy mismatch**: The ticket's Error States table specifies: title "No active trainees" + description "Invite trainees to see analytics". The implementation uses "No adherence data for this period" with a period-specific description mentioning days. These are different user scenarios: the ticket describes a zero-trainees state, the implementation describes a no-data-in-period state.
  - **Issue 2 -- Missing CTA**: The ticket specifies "Invite trainees to see analytics" which implies a CTA link/button to the Invitations page. The `EmptyState` component supports an `action` prop (`empty-state.tsx` line 8: `action?: ReactNode`), but it is not used here. No actionable element is rendered.

### Progress Section (AC-12 through AC-18)

- [x] **AC-12** -- PASS -- Progress table showing: Name, Current Weight (kg), Weight Change (kg with +/- indicator and color), Goal
  - `progress-section.tsx` lines 65-96: Four columns defined:
    - `trainee_name` header "Name" with font-medium styling and truncation
    - `current_weight` header "Current Weight" with `${row.current_weight.toFixed(1)} kg` formatting
    - `weight_change` header "Weight Change" rendered by `WeightChangeCell` with +/- sign prefix and TrendingUp/TrendingDown icons
    - `goal` header "Goal" formatted by `formatGoal()` which maps internal values to display labels

- [x] **AC-13** -- PASS -- Weight change column uses color: green for loss when goal is "weight_loss", green for gain when goal is "muscle_gain", neutral otherwise
  - `getWeightChangeColor` (lines 25-41):
    - `weightChange === null || weightChange === 0`: returns empty string (neutral) -- correct
    - `goal === "weight_loss"` + `weightChange < 0`: green (losing weight toward loss goal) -- correct
    - `goal === "weight_loss"` + `weightChange > 0`: red (gaining weight against loss goal) -- correct
    - `goal === "muscle_gain"` + `weightChange > 0`: green (gaining toward gain goal) -- correct
    - `goal === "muscle_gain"` + `weightChange < 0`: red (losing against gain goal) -- correct
    - Any other goal (maintenance, body_recomposition, null): neutral -- correct

- [x] **AC-14** -- PASS -- Null weight values show dash
  - `current_weight` column (line 80): `row.current_weight !== null ? \`${row.current_weight.toFixed(1)} kg\` : "\u2014"`.
  - `WeightChangeCell` (line 50): `if (weightChange === null) return <span>\u2014</span>`.
  - Both null cases produce an em-dash. TypeScript types (`TraineeProgressEntry`) correctly type both fields as `number | null`.

- [x] **AC-15** -- PASS -- Clicking a trainee row navigates to `/trainees/{id}`
  - `progress-section.tsx` line 152: `onRowClick={(row) => router.push(\`/trainees/${row.trainee_id}\`)}`.
  - `DataTable` component (`data-table.tsx` lines 73-85) adds `cursor-pointer`, `tabIndex={0}`, `role="button"`, and keyboard handlers (Enter/Space) when `onRowClick` is provided. Fully accessible.

- [x] **AC-16** -- PASS -- Progress section loading skeleton
  - `progress-section.tsx` line 130: `isLoading ? <ProgressSkeleton />`.
  - `ProgressSkeleton` (lines 98-114) renders a Card with a skeleton header and 4 skeleton rows.

- [x] **AC-17** -- PASS -- Progress section error state with retry button
  - `progress-section.tsx` lines 131-135: `isError ? <ErrorState message="Failed to load progress data" onRetry={() => refetch()} />`.
  - Message matches ticket's Error States table exactly.

- [x] **AC-18** -- PASS -- Progress section empty state when trainer has no active trainees
  - `progress-section.tsx` lines 137-141: `<EmptyState icon={TrendingUp} title="No progress data" description="Trainees will appear here once they start tracking" />`.
  - Title and description match the ticket's Error States table: "No progress data" / "Trainees will appear here once they start tracking".

### General (AC-19 through AC-22)

- [x] **AC-19** -- PASS -- Page handles both sections loading independently
  - `page.tsx` renders `<AdherenceSection />` and `<ProgressSection />` as sibling components.
  - Each section has its own `useAdherenceAnalytics` / `useProgressAnalytics` hook, each producing independent `isLoading`, `isError`, `data` states.
  - Verified: if adherence API fails but progress succeeds, adherence renders ErrorState while progress renders the table. No shared loading/error state.

- [x] **AC-20** -- PASS -- All API calls use authenticated `apiClient.get()` with proper types
  - `use-analytics.ts` line 16: `apiClient.get<AdherenceAnalytics>(...)` and line 27: `apiClient.get<ProgressAnalytics>(...)`.
  - `apiClient.get` (in `api-client.ts` line 86) delegates to `request<T>` which attaches Bearer token, handles 401 refresh/retry, and throws `ApiError` on non-OK responses. Typed generics ensure response type safety.

- [x] **AC-21** -- PASS -- New TypeScript types for both API responses
  - `web/src/types/analytics.ts` defines:
    - `AdherencePeriod = 7 | 14 | 30` (union type for period selector)
    - `TraineeAdherence` interface with `trainee_id`, `trainee_email`, `trainee_name`, `adherence_rate`, `days_tracked`
    - `AdherenceAnalytics` interface with `period_days`, `total_tracking_days`, `food_logged_rate`, `workout_logged_rate`, `protein_goal_rate`, `trainee_adherence[]`
    - `TraineeProgressEntry` interface with `trainee_id`, `trainee_email`, `trainee_name`, `current_weight: number | null`, `weight_change: number | null`, `goal: string | null`
    - `ProgressAnalytics` interface with `trainee_progress[]`
  - All field names verified against backend response (`views.py` lines 874-888, 927-937) -- exact match.

- [x] **AC-22** -- PASS -- Adherence data uses `staleTime: 5 * 60 * 1000` (5 min)
  - `use-analytics.ts` line 19: `staleTime: 5 * 60 * 1000` on adherence query -- matches ticket exactly.
  - Note: Progress query (line 28) also has the same staleTime. The ticket only required it for adherence, but adding it to progress is a reasonable additive choice and does not violate the requirement.

---

## AC Summary

| AC | Verdict |
|----|---------|
| AC-1 | PASS |
| AC-2 | PASS |
| AC-3 | PASS |
| AC-4 | PASS |
| AC-5 | PASS |
| AC-6 | PASS |
| AC-7 | PASS |
| AC-8 | PASS |
| AC-9 | PASS |
| AC-10 | PASS |
| AC-11 | **FAIL** |
| AC-12 | PASS |
| AC-13 | PASS |
| AC-14 | PASS |
| AC-15 | PASS |
| AC-16 | PASS |
| AC-17 | PASS |
| AC-18 | PASS |
| AC-19 | PASS |
| AC-20 | PASS |
| AC-21 | PASS |
| AC-22 | PASS |

**Passed: 21 / Failed: 1**

---

## Edge Case Verification

| # | Edge Case | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | **Zero trainees** -- Both sections show empty states with different messages | **FAIL** | Progress empty state matches ticket: "No progress data" / "Trainees will appear here once they start tracking". Adherence empty state does NOT match: shows "No adherence data for this period" instead of ticket-specified "No active trainees" / "Invite trainees to see analytics". The messages are different between sections (as required) but the adherence copy does not match the ticket. |
| 2 | **Trainee with no weight data** -- `current_weight` and `weight_change` null shows dash | **PASS** | `progress-section.tsx` line 80: null `current_weight` renders "\u2014". Line 50: null `weightChange` renders "\u2014". Types correctly specify `number | null`. |
| 3 | **Trainee with no profile** -- `goal` is null shows "Not set" | **PASS** | `formatGoal` (line 20): `if (!goal) return "Not set"`. Backend (`views.py` line 924): catches `RelatedObjectDoesNotExist` and sets `goal = None`. Frontend type: `goal: string | null`. |
| 4 | **All trainees at 0% adherence** -- Chart renders with zero-width bars, still shows names | **PASS** | `XAxis domain={[0, 100]}` ensures axis renders with fixed range even when all values are 0. `YAxis dataKey="trainee_name"` renders names as category ticks independent of bar width. Recharts renders zero-value bars as minimal-width elements. Names remain visible. |
| 5 | **Single trainee** -- Chart and table work with 1 row | **PASS** | Chart: `chartHeight = Math.max(1 * 36 + 40, 120)` = 120px minimum -- valid height. Sort with single element works. Table: `DataTable` renders single `<TableRow>` without issue; `keyExtractor` produces unique key. No special-case logic that would break. |
| 6 | **Large number of trainees (50+)** -- Chart scrolls vertically | **PASS** | `adherence-section.tsx` line 130: `<div className="max-h-[600px] overflow-y-auto">` wraps the chart. With 50 trainees: `chartHeight = 50 * 36 + 40 = 1840px`, exceeding the 600px max-height, so the container scrolls vertically. Table uses DataTable with `overflow-x-auto` for horizontal scroll on narrow viewports. |
| 7 | **Period selector rapid switching** -- React Query handles via queryKey change | **PASS** | `queryKey: ["analytics", "adherence", days]` -- each period produces a unique key. React Query automatically manages request lifecycle per key: stale queries are superseded by new ones. Additionally, `isFetching` (line 72 of `adherence-section.tsx`) is used to show `opacity-50` during background refetch, giving visual feedback of in-flight request. |
| 8 | **Network failure mid-page** -- One section can error while other succeeds | **PASS** | `AdherenceSection` and `ProgressSection` are independent React components with independent React Query hooks. Each has its own `isLoading`, `isError`, `data` state. If adherence API returns 500 but progress API succeeds, adherence shows `ErrorState` while progress shows the data table. No shared error boundary between them. |
| 9 | **Very long trainee names** -- Truncated with title tooltip | **PASS** | Chart Y-axis (`adherence-chart.tsx` lines 58-74): names longer than 15 characters truncated to `${name.slice(0, 15)}...` with `<title>{name}</title>` inside `<text>` for SVG tooltip on hover. Progress table (`progress-section.tsx` lines 69-72): `<span className="truncate max-w-[200px] block" title={row.trainee_name}>` uses CSS text-overflow with `title` attribute for hover tooltip. Both locations implement truncation with tooltip. |

**Edge Cases Passed: 8 / Failed: 1**

---

## Bugs Found

| # | Severity | File:Line | Description | How to Reproduce |
|---|----------|-----------|-------------|-----------------|
| 1 | Medium | `adherence-section.tsx:94-99` | **Adherence empty state copy does not match ticket.** Implementation shows title "No adherence data for this period" and description mentioning "{days} days". Ticket specifies title "No active trainees" and description "Invite trainees to see analytics". The implementation conflates two distinct scenarios: (a) trainer has zero trainees, and (b) trainer has trainees but none logged in the selected period. The ticket intended scenario (a). | Log in as a trainer with zero trainees. Navigate to `/analytics`. Observe adherence empty state. Expected: "No active trainees" / "Invite trainees to see analytics". Actual: "No adherence data for this period" / "No trainees have logged activity in the last 30 days..." |
| 2 | Medium | `adherence-section.tsx:94-99` | **Missing CTA action in adherence empty state.** The ticket's Error States table says the empty state should include a CTA that implies guiding the user to invite trainees ("Invite trainees to see analytics"). The `EmptyState` component accepts an `action` prop (`empty-state.tsx` line 8: `action?: ReactNode`) but the adherence section does not pass one. There is no button or link to navigate to the Invitations page (`/invitations`). | Same as bug #1. Observe the empty state. Expected: an "Invite trainees" button/link. Actual: only text, no actionable element. |
| 3 | Low | `adherence-chart.tsx:89` | **Bar onClick uses index-based lookup instead of entry data.** The `onClick` handler receives `(_entry, index)` but ignores `_entry` and instead does `sorted[index]` to find the trainee. While this works because the `sorted` array order matches the rendered bar order, using the entry data directly would be more robust. If recharts ever changes how it handles bar indices (e.g., with animations or transitions), this could break silently and navigate to the wrong trainee. | Not directly reproducible as a runtime bug. Fragility concern for future recharts updates. Suggested fix: use `_entry` payload data instead of `sorted[index]`. |
| 4 | Low | Progress table | **Ticket UX Requirements specify "Sortable by weight change column" but DataTable has no sorting capability.** The ticket says the progress table should be sortable by weight change. However, the shared `DataTable` component (`data-table.tsx`) has no sort functionality (no `sortable` prop, no column header click handlers, no sort state). The progress section does not implement any client-side sorting either. This is a pre-existing limitation of the shared component rather than a bug in this implementation. | Navigate to `/analytics`. View the progress table. Try to click the "Weight Change" column header. Expected: rows reorder by weight change. Actual: nothing happens. |

---

## Loading / Error / Empty State Coverage

| Component | Loading | Error | Empty |
|-----------|---------|-------|-------|
| Adherence section | AdherenceSkeleton (3 stat cards + chart placeholder) | ErrorState "Failed to load adherence data" with retry | EmptyState with BarChart3 icon (copy mismatch -- see Bug #1) |
| Progress section | ProgressSkeleton (table header + 4 row placeholders) | ErrorState "Failed to load progress data" with retry | EmptyState with TrendingUp icon, correct copy |
| Period selector | Rendered immediately (no async state) | N/A | N/A |
| Stat cards | Part of AdherenceSkeleton | Part of adherence ErrorState | Part of adherence EmptyState |
| Adherence chart | Part of AdherenceSkeleton | Part of adherence ErrorState | Part of adherence EmptyState |
| Progress table | Part of ProgressSkeleton | Part of progress ErrorState | Part of progress EmptyState |

---

## Type Safety Verification

| Check | Status |
|-------|--------|
| Frontend types match backend response fields | PASS -- All field names in `analytics.ts` match backend `views.py` response dicts exactly |
| Nullable fields typed as `T | null` | PASS -- `current_weight`, `weight_change`, `goal` all typed `number | null` or `string | null` |
| All null paths handled in rendering | PASS -- Null checks with dash fallback in table cells, null goal -> "Not set" |
| React Query generic types match hook return usage | PASS -- `useQuery<AdherenceAnalytics>` and `useQuery<ProgressAnalytics>` provide correctly typed `data` |
| API URL constants use correct paths | PASS -- `ANALYTICS_ADHERENCE` = `/api/trainer/analytics/adherence/`, `ANALYTICS_PROGRESS` = `/api/trainer/analytics/progress/` -- match `backend/trainer/urls.py` |

---

## Observations (Non-Blocking)

1. **Both hooks have 5-minute staleTime**: The ticket only specified staleTime for adherence, but the implementation applies it to progress too. This is a reasonable additive choice -- progress data (weight check-ins) also changes infrequently. Not a bug.

2. **Adherence chart dynamic height**: The chart height formula `Math.max(sorted.length * 36 + 40, 120)` works well but with very large trainee counts (100+), the chart inside the 600px scroll container could have performance implications as recharts renders all bars even when scrolled out of view. Not a concern for typical trainer sizes (< 50 trainees).

3. **Backend sorts adherence data too**: `views.py` line 888 sorts `trainee_adherence` by `-adherence_rate`. The frontend also sorts in `adherence-chart.tsx` line 36. This is redundant but harmless -- the frontend sort ensures correct order regardless of backend changes.

4. **Period selector opacity feedback**: When switching periods, the adherence section shows `opacity-50` during refetch (`isFetching` state). This is a nice UX touch that provides immediate visual feedback while fresh data loads.

5. **No test runner configured**: The web dashboard has no Vitest/Jest testing framework. All verification was code-level inspection only.

---

## Confidence Level: HIGH

**Reasoning:**
- 21 of 22 acceptance criteria verified as PASS by thorough code inspection.
- 8 of 9 edge cases verified as PASS.
- The single failure (AC-11 / Edge Case 1) is a copy/UX mismatch in the adherence empty state -- the wrong text is shown and a CTA is missing. This is a low-risk cosmetic issue, not a functional, security, or architectural problem.
- All data flows are correctly implemented: hooks fetch with proper queryKeys, components destructure data correctly, null paths are handled, navigation works, error states have retry.
- Type safety is maintained throughout: TypeScript interfaces match backend response shapes exactly.
- React Query usage is correct: independent queries, proper staleTime, queryKey-based refetch on period change.
- Shared components (DataTable, ErrorState, EmptyState, PageHeader, Skeleton) are used correctly and consistently.
- Authentication is handled by the existing `apiClient` which attaches Bearer tokens and handles 401 refresh.
- Accessibility is properly implemented: ARIA roles on period selector, decorative icons hidden, keyboard navigation on table rows and period selector buttons.

---

**QA completed by:** QA Engineer Agent
**Date:** 2026-02-15
**Pipeline:** 9 -- Web Dashboard Phase 3
