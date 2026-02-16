# Architecture Review: Web Dashboard Phase 3 -- Trainer Analytics Page

## Review Date: 2026-02-15

## Files Reviewed

### New Files
- `web/src/types/analytics.ts` -- TypeScript types for API responses
- `web/src/hooks/use-analytics.ts` -- React Query hooks for adherence and progress
- `web/src/components/analytics/period-selector.tsx` -- Period radio group (7/14/30 days)
- `web/src/components/analytics/adherence-chart.tsx` -- Horizontal bar chart for trainee adherence
- `web/src/components/analytics/adherence-section.tsx` -- Adherence stat cards + chart section
- `web/src/components/analytics/progress-section.tsx` -- Progress data table section
- `web/src/app/(dashboard)/analytics/page.tsx` -- Page composition
- `web/src/lib/chart-utils.ts` -- Shared chart styling constants (created during this review)

### Modified Files
- `web/src/components/layout/nav-links.tsx` -- Added Analytics nav item
- `web/src/lib/constants.ts` -- Added analytics API URL constants
- `web/src/components/dashboard/stat-card.tsx` -- Extended with `valueClassName` prop (during this review)
- `web/src/components/trainees/progress-charts.tsx` -- Refactored to use shared chart-utils (during this review)

### Comparison Files (existing patterns)
- `web/src/hooks/use-dashboard.ts`
- `web/src/components/dashboard/stat-card.tsx`
- `web/src/components/shared/data-table.tsx`
- `web/src/components/trainees/progress-charts.tsx`
- `web/src/lib/api-client.ts`
- `backend/trainer/views.py` (lines 825-938)

---

## Architectural Alignment

- [x] Follows existing layered architecture (Page -> Section -> Component, Hook -> ApiClient)
- [x] Types in correct location (`types/analytics.ts`)
- [x] No business logic in page component -- logic delegated to hooks and child components
- [x] Consistent with existing patterns (matches `use-dashboard.ts`, `stat-card.tsx`, `data-table.tsx`)
- [x] Feature directory structure follows convention (`components/analytics/`)
- [x] API constants centralized in `lib/constants.ts`

### Layering Assessment

The implementation follows the established architecture precisely:

```
AnalyticsPage (page)
  -> AdherenceSection (section component)
      -> PeriodSelector (presentation component)
      -> StatCard (shared component, reused from dashboard)
      -> AdherenceBarChart (chart component)
      -> useAdherenceAnalytics (hook) -> apiClient.get (api-client)
  -> ProgressSection (section component)
      -> DataTable (shared component)
      -> useProgressAnalytics (hook) -> apiClient.get (api-client)
```

The page is a thin composition layer. Hooks encapsulate data fetching. Sections handle their own loading/error/empty states. Presentation components are purely visual. This is exactly the same pattern used by the dashboard, trainees, and notifications features.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| TypeScript types match backend API response | PASS | Verified against `AdherenceAnalyticsView` (views.py:825) and `ProgressAnalyticsView` (views.py:892). All field names, types, and nullability match exactly. |
| Nullable fields handled correctly | PASS | `current_weight: number | null`, `weight_change: number | null`, `goal: string | null` match backend where `checkins[-1].weight_kg` or `profile.goal` can be `None`. |
| Period parameter correctly typed | PASS | `AdherencePeriod = 7 | 14 | 30` is a union literal type, not just `number`. Backend clamps to `min(max(int(...), 1), 365)` so these values are safe. |
| No schema changes needed | PASS | Analytics endpoints consume existing models (`TraineeActivitySummary`, `WeightCheckIn`, `UserProfile`). No migrations required. |
| Response shape is stable | PASS | Both APIs return flat JSON with no nested pagination or cursors. Types accurately model this. |

---

## API Design Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Hook signature matches codebase conventions | PASS | `useAdherenceAnalytics(days)` and `useProgressAnalytics()` follow the same pattern as `useDashboardStats()` and `useDashboardOverview()`. |
| Query keys are properly namespaced | PASS | `["analytics", "adherence", days]` and `["analytics", "progress"]`. The `days` parameter in the key ensures React Query refetches when the period changes. |
| staleTime configured | PASS | Both hooks use `staleTime: 5 * 60 * 1000` (5 min) since analytics data changes infrequently. Dashboard hooks use the default (0), so the analytics hooks are more cache-efficient -- appropriate for aggregate data. |
| Authenticated requests | PASS | Uses `apiClient.get<T>()` which adds JWT auth headers and handles 401 refresh automatically. |
| Error handling | PASS | React Query surfaces errors via `isError`; each section has its own `ErrorState` with retry via `refetch()`. |

---

## Frontend Pattern Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Component reuse | PASS (after fix) | `StatCard` from `dashboard/stat-card.tsx` is now reused instead of duplicated. Extended with `valueClassName` prop for color indicators. |
| Shared chart styling | PASS (after fix) | `tooltipContentStyle` and `CHART_COLORS` extracted to `lib/chart-utils.ts`, imported by both `progress-charts.tsx` and `adherence-chart.tsx`. |
| `DataTable` reuse | PASS | Progress section correctly reuses the shared `DataTable` component with typed `Column<TraineeProgressEntry>[]`. |
| Shared empty/error states | PASS | Uses `EmptyState` and `ErrorState` from `components/shared/`. |
| Independent section loading | PASS | Both sections fetch independently and manage their own loading/error/empty states, consistent with AC-19. |
| Icon type consistency | PASS (after fix) | Analytics section now uses `LucideIcon` through `StatCard` rather than `React.ElementType`. |
| `"use client"` directives | PASS | Applied correctly to all components that use React hooks or browser APIs. Omitted from the types file and chart-utils (pure declarations). |

---

## Scalability Concerns

| # | Area | Issue | Severity | Recommendation |
|---|------|-------|----------|----------------|
| 1 | Client-side sort | `AdherenceBarChart` re-sorts data on every render. Backend already returns data sorted by `adherence_rate` descending (views.py:888). | Low | The defensive sort is harmless for <100 items and guards against backend changes. Could add `useMemo` for large lists, but not necessary at current scale. No action needed. |
| 2 | Unbounded trainee list | Neither API paginates. For trainers with 50+ trainees, the chart renders 50+ bars and the table renders 50+ rows. | Low | At current scale (trainers typically have 5-30 trainees), this is fine. The adherence chart container handles overflow. If trainer scale grows to 100+, server-side pagination or virtual scrolling would be needed. Monitor, no action now. |
| 3 | Progress endpoint performance | `ProgressAnalyticsView` iterates over all trainees and sorts their weight check-ins in Python (views.py:913). With `prefetch_related` this avoids N+1 queries, but sorting is per-trainee in memory. | Low | Acceptable. `prefetch_related('weight_checkins')` prevents N+1. The in-memory sort is on small lists (a trainee typically has <100 check-ins). No action needed. |
| 4 | Adherence endpoint | Uses a single annotated query with `Count` + `Case/When` (views.py:858-868). | N/A | Excellent -- single query, no N+1. No concern. |

---

## Technical Debt Assessment

| # | Description | Severity | Status |
|---|-------------|----------|--------|
| 1 | **RESOLVED:** `tooltipContentStyle` was duplicated in `progress-charts.tsx` and `adherence-chart.tsx`. | Medium | Fixed -- extracted to `web/src/lib/chart-utils.ts`. Both files now import from the shared module. |
| 2 | **RESOLVED:** `StatDisplay` in `adherence-section.tsx` duplicated the `StatCard` component from `dashboard/stat-card.tsx`. | Medium | Fixed -- `StatCard` extended with `valueClassName` prop. `StatDisplay` removed entirely. Analytics section now imports and reuses `StatCard`. |
| 3 | **RESOLVED:** `CHART_COLORS` constant was defined only in `progress-charts.tsx`. | Low | Fixed -- moved to `web/src/lib/chart-utils.ts` for cross-feature reuse. |
| 4 | `getIndicatorColor()` in `adherence-section.tsx` uses Tailwind classes while `getAdherenceColor()` in `adherence-chart.tsx` uses HSL CSS vars. | None | These serve different purposes: Tailwind classes for text elements in the DOM, HSL strings for SVG `fill` attributes in recharts. Different tools for different contexts. Not debt. |
| 5 | `GOAL_LABELS` in `progress-section.tsx` is a local constant. | None | Only used in one component. If goal labels are needed elsewhere, extract to a shared location. No action now. |

**Net technical debt: Reduced.** Three instances of duplication were eliminated. One new shared utility file was created that benefits the entire chart ecosystem.

---

## Architectural Decisions Evaluated

### 1. Two Independent Hooks (Good)
Adherence and progress sections load independently, each with their own loading/error/empty state. This is the correct pattern -- one section failing does not block the other. Matches how the dashboard page works with `useDashboardStats()` and `useDashboardOverview()`.

### 2. Period in Query Key (Good)
`queryKey: ["analytics", "adherence", days]` -- when the user switches from 30d to 7d, React Query treats it as a new query. The old data remains cached, so switching back to 30d is instant. This is the idiomatic React Query approach.

### 3. `staleTime: 5 * 60 * 1000` (Good)
Analytics data is computed from daily summaries. Caching for 5 minutes prevents unnecessary refetches when navigating away and back. The dashboard hooks use no staleTime (0), which means they refetch on every mount -- the analytics hooks are more efficient for their use case.

### 4. Extending StatCard vs. Creating a New Component (Good)
Rather than creating `AnalyticsStatCard`, the existing `StatCard` was extended with an optional `valueClassName` prop. This is backward-compatible -- existing consumers are unaffected. The `cn()` utility merges the base classes with the optional ones safely.

### 5. Shared Chart Utils (Good)
The `chart-utils.ts` module is placed in `lib/` alongside `utils.ts`, `constants.ts`, and `api-client.ts`. This follows the convention of putting shared, non-component utilities in `lib/`. The module exports only pure constants (no side effects), making it safe to import from any component.

---

## Changes Made by Architect

### 1. Created `web/src/lib/chart-utils.ts`
Extracted `tooltipContentStyle` (shared Recharts tooltip styling) and `CHART_COLORS` (theme-aware chart color constants) into a shared utility module. Previously `tooltipContentStyle` was duplicated across `progress-charts.tsx` and `adherence-chart.tsx`, and `CHART_COLORS` was only available in `progress-charts.tsx`.

### 2. Extended `web/src/components/dashboard/stat-card.tsx`
Added optional `valueClassName` prop to `StatCard`, allowing consumers to apply custom styling (e.g., color indicators) to the value text. Uses `cn()` from `lib/utils` for safe class merging. Backward-compatible -- existing consumers are unaffected. Also added `cn` import.

### 3. Refactored `web/src/components/analytics/adherence-section.tsx`
Replaced the duplicated `StatDisplay` component with the shared `StatCard` from `dashboard/stat-card.tsx`. The `getIndicatorColor()` function is passed via the new `valueClassName` prop, and `getIndicatorDescription()` is passed via the existing `description` prop. Removed dead `StatDisplayProps` interface and `StatDisplay` function.

### 4. Refactored `web/src/components/analytics/adherence-chart.tsx`
Replaced local `tooltipContentStyle` constant with import from `@/lib/chart-utils`.

### 5. Refactored `web/src/components/trainees/progress-charts.tsx`
Replaced local `tooltipContentStyle` and `CHART_COLORS` constants with imports from `@/lib/chart-utils`. Removed 12 lines of duplicated constant definitions.

---

## Architecture Score: 9/10

### Breakdown:
- **Layering:** 10/10 -- Clean separation: page -> section -> component, hooks encapsulate data fetching, no business logic in views
- **Data Model:** 10/10 -- Types exactly match backend API responses, nullable fields handled correctly
- **API Design:** 9/10 -- Consistent with existing hooks, good cache strategy, independent error handling
- **Frontend Patterns:** 9/10 -- After fixes, all shared components are properly reused. Chart styles consolidated.
- **Scalability:** 8/10 -- Adequate for current scale (5-30 trainees). Would need pagination at 100+ trainees.
- **Technical Debt:** 9/10 -- Net reduction in debt. Three instances of duplication eliminated.

### Strengths:
- Perfect alignment with existing architecture and patterns
- Backend APIs are well-designed (no N+1, single annotated query for adherence)
- TypeScript types accurately model the API contract
- Independent section loading for resilience
- Defensive coding (null checks, sorted data guard, empty state handling)

### Minor Observations (Not Blocking):
- The client-side sort in `AdherenceBarChart` is redundant since the backend already sorts, but serves as a defensive guard
- The unbounded trainee list is acceptable at current scale but should be monitored as trainer adoption grows

## Recommendation: APPROVE

The implementation follows the established architecture consistently. All three instances of code duplication identified during this review have been fixed. The new shared `chart-utils.ts` module reduces future technical debt for any chart components added to the application. The data model accurately reflects the backend API. No architectural concerns blocking ship.

---

**Review completed by:** Architect Agent
**Date:** 2026-02-15
**Build status:** Compiled successfully, 0 TypeScript errors
**Lint status:** 0 errors, 0 warnings
