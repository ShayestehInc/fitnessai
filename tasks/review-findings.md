# Code Review: Trainee Web — Workout Logging & Progress Tracking (Pipeline 33)

## Review Date: 2026-02-21

## Files Reviewed
- `web/src/types/trainee-dashboard.ts` (9 new interfaces)
- `web/src/lib/constants.ts` (3 new URL constants)
- `web/src/hooks/use-trainee-dashboard.ts` (4 new hooks)
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx` (2 new nav links)
- `web/src/components/trainee-dashboard/weight-trend-card.tsx` (Log Weight integration)
- `web/src/components/trainee-dashboard/todays-workout-card.tsx` (Start Workout button)
- `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` (new)
- `web/src/components/trainee-dashboard/exercise-log-card.tsx` (new)
- `web/src/components/trainee-dashboard/active-workout.tsx` (new)
- `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` (new)
- `web/src/components/trainee-dashboard/workout-history-list.tsx` (new)
- `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` (new)
- `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` (new)
- `web/src/components/ui/textarea.tsx` (new)
- `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx` (new)
- `web/src/app/(trainee-dashboard)/trainee/history/page.tsx` (new)
- `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx` (new)

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 1 | `active-workout.tsx:226` | `handleFinish` captures stale `todaysDay` and `elapsedSeconds` via closure because they're in the useCallback dependency array but `todaysDay` is derived from `programs` data which is an object reference. If the user finishes the workout while the query refetches in the background, the closure might reference the old program data. More critically, `saveMutation` itself is a new reference each render — including it in deps means `handleFinish` is recreated every render, defeating `useCallback`. | Remove `saveMutation` from deps and use `saveMutation.mutate` directly (it's stable). Alternatively, use `useRef` for mutation or accept the re-renders since they're harmless. |
| 2 | `active-workout.tsx:334` | Assumes `todaysDay.exercises[i]` always aligns with `exerciseStates[i]`. If the program data re-fetches and exercises change order or count mid-workout, the `targetExercise` lookup becomes misaligned, showing wrong targets. | The exercise data is snapshotted at initialization (good), but `todaysDay` comes from a live query. Store target exercise data alongside `ExerciseState` at initialization time to decouple from live query data. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 3 | `workout-detail-dialog.tsx:24-38` | `getExercises` and `getWorkoutName` cast `workout_data` to `Record<string, unknown>` but the type `WorkoutDetailData` already defines `workout_data: WorkoutData`. The casting is inconsistent with the type system and bypasses TypeScript safety. | Use the typed `WorkoutData` interface directly instead of casting to `Record<string, unknown>`. Access `data.workout_data.exercises` and `data.workout_data.workout_name` directly. |
| 4 | `active-workout.tsx:24-52` | `getTodaysDayNumber()`, `DAY_NAMES`, and `findTodaysWorkout()` are duplicated from `todays-workout-card.tsx` (identical code). This violates DRY and creates a maintenance risk. | Extract these helpers to a shared utility file (e.g., `web/src/lib/schedule-utils.ts`) and import in both components. |
| 5 | `weight-checkin-dialog.tsx:26-32` and `active-workout.tsx:60-63` | `getTodayString()` is duplicated in two files with identical implementations. | Extract to a shared utility. |
| 6 | `trainee-progress-charts.tsx:108` | Weight chart data is produced by `[...checkIns].reverse()` which creates a reversed copy. If the API returns many entries (e.g., 365 days), all of them are rendered in the chart. No pagination or limit on chart data points, which could slow rendering. | Slice to the last N entries (e.g., 30 or 90) before charting: `checkIns.slice(0, 30).reverse()`. |
| 7 | `trainee-progress-charts.tsx:203` | Workout volume chart fetches `useTraineeWorkoutHistory(1)` which returns page 1 (20 items). This means the chart always shows the 20 most recent workouts reversed. If the user wants to see longer trends, there's no option. Also, using page 1 data may include very old data if user hasn't worked out recently. | Fine for v1, but add a TODO or ticket to support date-range filtering in future. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 8 | `exercise-log-card.tsx:85` | `value={set.reps \|\| ""}` — when reps is 0, this shows empty string instead of 0. This is intentional UX for empty inputs but means user can't distinguish "0 reps" from "not entered." | Consider using `value={set.reps === 0 ? "" : set.reps}` pattern consistently or allow 0 to display as 0. Currently acceptable UX. |
| 9 | `exercise-log-card.tsx:102` | Same pattern for weight: `value={set.weight \|\| ""}`. Weight of 0 shows empty. Bodyweight exercises would show empty. | Display "0" or "BW" for bodyweight exercises explicitly. |
| 10 | `workout-finish-dialog.tsx:47-48` | Volume calculation `s.weight * s.reps` doesn't account for sets where weight is 0 (bodyweight). These are excluded from volume, which is correct, but the total might be confusing if most exercises are bodyweight. | Consider adding a note "(excludes bodyweight exercises)" or show bodyweight set count separately. |
| 11 | `active-workout.tsx:97-109` | Timer starts immediately on component mount, even before program data loads. The timer runs during the loading skeleton state. | Start the timer only after exercise states are initialized (when `initialized` is true). |
| 12 | `workout-history-list.tsx:93-98` | `new Date(item.date)` parsing of "YYYY-MM-DD" string can produce off-by-one day errors due to timezone. `new Date("2026-02-21")` is interpreted as UTC midnight, which in negative UTC offsets becomes the previous day. | Use `parseISO` from date-fns (already imported in progress-charts) for consistent local date parsing. |

## Security Concerns
- Weight check-in validates client-side but also relies on backend validation — good.
- No XSS vectors found — all user input goes through React's JSX escaping.
- No raw HTML insertion.
- API calls go through `apiClient` with JWT auth.

## Performance Concerns
- Active workout uses multiple `useCallback` with `[]` deps — efficient.
- `setExerciseStates` uses `map` which creates new arrays each time — fine for typical exercise counts (< 20).
- No memo on `ExerciseLogCard` — could cause unnecessary re-renders when any exercise changes since the parent re-renders all cards. Consider `React.memo`.
- Chart components each make independent API calls which is correct (isolated error boundaries).

## Quality Score: 7/10
## Recommendation: REQUEST CHANGES

The implementation is solid overall — all acceptance criteria are met, UX states are thorough, and the component architecture is clean. However, the critical issues around stale closures and target exercise alignment in the active workout need to be fixed before shipping. The code duplication (DRY violations) is a maintenance risk that should also be addressed.
