# Architecture Review: Trainee Web -- Workout Logging & Progress Tracking (Pipeline 33)

## Review Date
2026-02-21

## Files Reviewed

**New/Modified Components (Pipeline 33 scope):**
- `web/src/components/trainee-dashboard/active-workout.tsx` -- interactive workout logging
- `web/src/components/trainee-dashboard/exercise-log-card.tsx` -- per-exercise set editor
- `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` -- workout summary and save confirmation
- `web/src/components/trainee-dashboard/workout-history-list.tsx` -- paginated history list with drill-in
- `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` -- read-only workout detail view
- `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` -- weight trend, volume, and adherence charts
- `web/src/components/trainee-dashboard/weekly-progress-card.tsx` -- weekly progress dashboard card
- `web/src/components/trainee-dashboard/weight-trend-card.tsx` -- weight dashboard card with trend
- `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` -- weight check-in form dialog
- `web/src/components/trainee-dashboard/nutrition-summary-card.tsx` -- macro tracking dashboard card
- `web/src/components/trainee-dashboard/program-viewer.tsx` -- program schedule viewer with week tabs
- `web/src/components/trainee-dashboard/todays-workout-card.tsx` -- today's workout dashboard card
- `web/src/components/trainee-dashboard/trainee-header.tsx` -- header bar
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` -- desktop sidebar
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` -- mobile sidebar
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx` -- navigation configuration
- `web/src/components/trainee-dashboard/achievements-grid.tsx` -- achievements grid
- `web/src/components/trainee-dashboard/announcements-list.tsx` -- announcements list

**New/Modified Hooks:**
- `web/src/hooks/use-trainee-dashboard.ts` -- all trainee data fetching (programs, nutrition, weight, progress, workout history, daily logs, save workout)

**New/Modified Types:**
- `web/src/types/trainee-dashboard.ts` -- WorkoutHistoryItem, WorkoutHistoryResponse, WorkoutDetailData, WorkoutData, WorkoutSession, WorkoutExerciseLog, WorkoutSetLog, SaveWorkoutPayload, CreateWeightCheckInPayload, WeeklyProgress, LatestWeightCheckIn, Announcement, Achievement

**New/Modified Utilities:**
- `web/src/lib/schedule-utils.ts` -- getTodaysDayNumber, findTodaysWorkout, getTodayString, formatDuration
- `web/src/lib/chart-utils.ts` -- tooltipContentStyle, CHART_COLORS
- `web/src/lib/constants.ts` -- TRAINEE_DAILY_LOGS, TRAINEE_WORKOUT_HISTORY, traineeWorkoutDetail API URLs

**New Pages:**
- `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/history/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/dashboard/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/program/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/achievements/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/settings/page.tsx`
- `web/src/app/(trainee-dashboard)/layout.tsx`

**Comparison Files Reviewed (existing patterns):**
- `web/src/components/trainees/progress-charts.tsx` -- trainer-side charts (for pattern comparison)
- `web/src/hooks/use-programs.ts` -- existing hook pattern
- `web/src/hooks/use-trainees.ts` -- existing hook pattern
- `web/src/hooks/use-trainee-badge-counts.ts` -- badge count composition hook
- `web/src/types/trainee-view.ts` -- existing trainee types
- `web/src/lib/api-client.ts` -- API client

---

## Architectural Alignment

- [x] Follows existing layered architecture (route group -> layout -> pages -> components -> hooks)
- [x] Types in correct locations (`types/` for types, `hooks/` for data, `components/` for UI, `app/` for pages)
- [x] No business logic in route pages -- data fetching in hooks, presentation in components
- [x] Consistent with existing patterns (query hooks, API_URLS, shared components)

---

## 1. LAYERING -- Business Logic in Right Layer? State in Right Layer?

**Score: 9/10**

**Strengths:**

Business logic is properly housed in the hooks layer. The `use-trainee-dashboard.ts` file encapsulates all API interactions:
- `useTraineeDashboardPrograms()` -- program fetching
- `useTraineeDashboardNutrition(date)` -- date-parameterized nutrition summary
- `useTraineeWeeklyProgress()` -- weekly adherence
- `useTraineeLatestWeight()` -- latest check-in with 404 retry suppression
- `useTraineeWeightHistory()` -- weight history for charts
- `useCreateWeightCheckIn()` -- mutation with cache invalidation
- `useTraineeWorkoutHistory(page)` -- paginated history
- `useTraineeWorkoutDetail(id)` -- conditional detail fetch
- `useTraineeTodayLog(date)` -- today's log check
- `useSaveWorkout()` -- check-then-create-or-patch logic for daily logs

The `useSaveWorkout` hook encapsulates the "check if daily log exists, then PATCH or POST" logic, keeping it out of the component. This is the correct layer for this decision.

Date/schedule utility functions are properly extracted to `lib/schedule-utils.ts`. Chart utilities are shared via `lib/chart-utils.ts`, consistent with the trainer-side charts that also import from the same file.

Pages are thin wrappers that compose components. For example, `trainee/workout/page.tsx` is just 12 lines wrapping `<ActiveWorkout />` in `<PageTransition>`.

**One observation:** `active-workout.tsx` at ~340 lines is the largest component. It manages timer state, exercise state, and workout serialization. This is borderline but acceptable -- the logic is cohesive (all state relates to a single active workout session), and the callbacks are properly `useCallback`-wrapped. Extracting the timer to a custom `useTimer` hook would be a marginal improvement but is not architecturally necessary.

---

## 2. DATA MODEL -- Types Match Backend? Consistent Naming?

**Score: 9/10**

**Strengths:**

- New types in `trainee-dashboard.ts` are well-structured and match expected DRF API response shapes.
- Reuses existing types from `trainee-view.ts` (`TraineeViewProgram`, `NutritionSummary`) rather than duplicating them. The trainee dashboard hooks import from both type files -- this is the correct approach.
- `WorkoutHistoryResponse` properly models DRF's paginated response format (`count`, `next`, `previous`, `results`).
- `WorkoutData` type handles both direct `exercises` and `sessions` formats (web vs. mobile), showing awareness of the backend's polymorphic data shape.
- `SetEntry` interface in `exercise-log-card.tsx` adds `isExtra: boolean` to distinguish program-target sets from user-added sets. This is a UI-only concern properly kept out of the API types.

**One minor inconsistency:** `PaginatedDailyLogs` is defined inline in the hook file rather than in a types file. The trainer-side code uses `PaginatedResponse<T>` from `types/api.ts`. However, since the daily log response items have a different shape than other paginated resources, defining it inline is pragmatically acceptable.

---

## 3. API DESIGN -- API Calls Follow Established Patterns? Query Keys Consistent?

**Score: 10/10**

All API URLs are properly centralized in `lib/constants.ts` under the `API_URLS` object. The new trainee endpoints follow the exact same conventions:

- Static URLs: `TRAINEE_DAILY_LOGS`, `TRAINEE_WORKOUT_HISTORY` (UPPER_SNAKE_CASE)
- Dynamic URLs: `traineeWorkoutDetail: (id: number) => ...` (camelCase functions)
- All use the same `API_BASE` prefix

Query keys are consistently namespaced under `["trainee-dashboard", "<resource>", ...params]`:
- This namespace is shared across `use-trainee-dashboard.ts`, `use-trainee-announcements.ts`, and `use-trainee-achievements.ts`
- Enables efficient bulk invalidation if needed (e.g., `queryClient.invalidateQueries({ queryKey: ["trainee-dashboard"] })`)
- No collisions with trainer-facing query keys (which use `["programs"]`, `["trainees"]`, etc.)

Mutation `onSuccess` callbacks correctly invalidate related queries:
- `useSaveWorkout` invalidates `weekly-progress`, `workout-history`, and `today-log`
- `useCreateWeightCheckIn` invalidates `weight-checkins` and `latest-weight`

`staleTime: 5 * 60 * 1000` is used consistently across all trainee queries, matching the `useAllTrainees` pattern.

---

## 4. FRONTEND PATTERNS -- Component Decomposition, Prop Drilling, Hook Patterns

**Score: 9/10**

**Component decomposition is excellent.** Each component has a clear, single responsibility:

| Component | Role | Data Source |
|-----------|------|-------------|
| `TodaysWorkoutCard` | Read-only dashboard card | Self-fetching (hook) |
| `ActiveWorkout` | Full interactive workout logging | Self-fetching + state |
| `ExerciseLogCard` | Per-exercise set editor | Props from parent |
| `WorkoutFinishDialog` | Confirmation with summary | Props from parent |
| `WorkoutHistoryList` | Paginated history with drill-in | Self-fetching (hook) |
| `WorkoutDetailDialog` | Read-only detail view | Self-fetching (hook) |
| `WeightTrendChart` | Weight line chart | Self-fetching (hook) |
| `WorkoutVolumeChart` | Volume bar chart | Self-fetching (hook) |
| `WeeklyAdherenceCard` | Adherence metric | Self-fetching (hook) |
| `ProgramViewer` | Program schedule viewer | Props from parent |
| `AchievementsGrid` | Achievements grid | Props from parent |
| `AnnouncementsList` | Announcements list | Props from parent |

Prop drilling is minimal and appropriate. `ExerciseLogCard` receives callbacks for set manipulation from `ActiveWorkout` -- this is the correct approach (lifting state up to the workout coordinator). No context providers needed.

The trainee nav system (`trainee-nav-links.ts` data, `trainee-sidebar.tsx` desktop, `trainee-sidebar-mobile.tsx` mobile) follows the exact same pattern as the trainer dashboard's nav system.

Shared components are properly reused: `PageHeader`, `PageTransition`, `ErrorState`, `EmptyState`, `LoadingSpinner`, `Badge` from the shared library.

---

## 5. SCALABILITY -- N+1 Queries, Unbounded Fetches, Pagination

**Score: 9/10**

**Properly bounded:**
- Workout history is paginated (page_size=20) with next/previous navigation
- Weight check-in chart limits to 30 most recent entries (`checkIns.slice(0, 30)`)
- `useTraineeTodayLog` filters by date at the API level (`?date=${date}`)
- `enabled: id > 0` on `useTraineeWorkoutDetail` prevents unnecessary fetches
- `retry` function on `useTraineeLatestWeight` skips retrying 404s

**One bounded concern:** `useTraineeWeightHistory` fetches ALL weight check-ins without pagination. The chart mitigates this by slicing to 30 entries, but the full dataset is still transferred. For a trainee with years of daily weigh-ins, this could grow to 1000+ entries. Acceptable for now since most trainees have at most a few hundred entries, but adding `?ordering=-date&page_size=100` would be a future improvement.

**One display concern:** `WorkoutVolumeChart` fetches only page 1 of workout history (20 items). This is appropriate for a "recent volume" chart but the component does not explicitly indicate the time window to the user.

---

## 6. TECHNICAL DEBT -- Introduced or Reduced?

**Score: 9/10 (net positive)**

### Debt Reduced

1. **Shared chart utilities** -- `tooltipContentStyle` and `CHART_COLORS` in `lib/chart-utils.ts` are consumed by both the new trainee charts (`trainee-progress-charts.tsx`) and the existing trainer-side charts (`trainees/progress-charts.tsx`). This reduces duplication.

2. **Centralized schedule utilities** -- `getTodaysDayNumber`, `findTodaysWorkout`, `getTodayString`, `formatDuration` are properly centralized in `lib/schedule-utils.ts`.

3. **Type reuse** -- `TraineeViewProgram` and `NutritionSummary` imported from existing `trainee-view.ts` rather than redefined.

### Fixed During This Review

| # | File | What Changed | Why |
|---|------|-------------|-----|
| 1 | `nutrition-summary-card.tsx` | Removed duplicate `getToday()` function, replaced with import of `getTodayString` from `@/lib/schedule-utils` | The component defined a local `getToday()` function that was an exact duplicate of `getTodayString()` in `schedule-utils.ts`. Single source of truth for date formatting prevents divergence. |

### Minor Debt Remaining

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `PaginatedDailyLogs` defined inline in hook file | Low | Could use `PaginatedResponse<TodayLogEntry>` from `types/api.ts` if shapes align |
| 2 | `active-workout.tsx` helper functions (`buildInitialSets`, `parseTarget`) could be extracted | Low | Move to a utility file if workout initialization logic is needed elsewhere |

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No backend schema changes -- all types consume existing API endpoints |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | Uses existing endpoints |
| No N+1 query patterns | PASS | Each component makes at most one query; no nested loops of API calls |
| Types match API contracts | PASS | `WorkoutHistoryResponse` matches DRF pagination; `WorkoutData` handles both exercise and session formats |

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Weight history | `useTraineeWeightHistory` fetches all records without pagination | Low priority -- add `?page_size=100&ordering=-date` in a future pass. Chart already limits to 30 entries for rendering. |
| 2 | Workout volume chart | Only shows page 1 (20 workouts) | Acceptable -- recent volume is the most useful data. Could add a "load more" option later. |

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `PaginatedDailyLogs` defined inline in hook file | Low | Unify with `PaginatedResponse<T>` from `types/api.ts` |

---

## Detailed Scoring Matrix

| Area | Score | Notes |
|------|-------|-------|
| Layering | 9/10 | Business logic in hooks, UI in components, pages are thin orchestrators |
| Data model / types | 9/10 | Proper reuse of existing types, new types well-structured |
| API design / query keys | 10/10 | Consistent namespacing, centralized URLs, proper invalidation |
| Component decomposition | 9/10 | Clear single-responsibility, minimal prop drilling, excellent shared reuse |
| Scalability | 9/10 | Paginated history, bounded chart data, conditional fetches |
| Technical debt | 9/10 | Net reduction via shared utilities; one inline type definition is minor |
| Accessibility | 9/10 | ARIA attributes, keyboard handlers, screen reader text throughout |

---

## Architecture Score: 9/10

The implementation demonstrates strong architectural discipline. The new workout logging, progress tracking, and history features integrate seamlessly with the established codebase patterns:

- **Proper separation of concerns**: pages compose components, components consume hooks, hooks manage API interactions
- **Consistent query key namespacing** under `["trainee-dashboard", ...]` across all trainee hooks
- **Centralized API URLs** in `lib/constants.ts` following established naming conventions
- **Type reuse** from `trainee-view.ts` rather than duplication
- **Shared chart utilities** between trainer and trainee dashboards
- **Proper pagination** on workout history
- **All five UX states** (loading, empty, error, success, special cases like rest day/no program) handled at the component level
- **One duplicate utility function fixed** during this review (getToday -> getTodayString)

The only improvements would be marginal: extracting the timer to a custom hook, adding pagination to weight history fetches, and unifying the inline paginated type. None rise to the level of architectural concern.

## Recommendation: APPROVE
