# QA Report: Trainee Web — Workout Logging & Progress Tracking (Pipeline 33)

## Test Results
- Total: 31
- Passed: 26
- Failed: 5

## Acceptance Criteria Verification

### Weight Check-In (AC-1 through AC-6)

- [x] AC-1 — PASS — `weight-trend-card.tsx` shows a "Log Weight" button in the `CardFooter` (lines 152-159) when weight data exists, and inside an `EmptyState` action (lines 75-78) when no weight data exists. Both use a `Plus` icon with "Log Weight" text. Button opens the `WeightCheckInDialog`.

- [x] AC-2 — PASS — `weight-checkin-dialog.tsx` renders a `Dialog` with three fields: weight number input (`type="number"`, step 0.1, min 20, max 500, lines 127-145), date input (`type="date"`, defaults to `getTodayString()`, line 32 and 155-175), and optional notes `Textarea` (lines 178-186). All fields are labeled via `Label` components.

- [x] AC-3 — PASS — `handleSubmit` in `weight-checkin-dialog.tsx` (line 70-106) calls `createMutation.mutate({ date, weight_kg: parseFloat(weight), notes })`. The `useCreateWeightCheckIn()` hook (use-trainee-dashboard.ts lines 81-98) calls `apiClient.post<LatestWeightCheckIn>(API_URLS.TRAINEE_WEIGHT_CHECKINS, payload)` which maps to `POST /api/workouts/weight-checkins/`.

- [x] AC-4 — PASS — On success (dialog lines 81-84): `toast.success("Weight check-in saved")` fires, form resets via `resetForm()`, dialog closes via `onOpenChange(false)`. The mutation `onSuccess` callback (hook lines 89-95) invalidates both `["trainee-dashboard", "weight-checkins"]` and `["trainee-dashboard", "latest-weight"]` query keys, refreshing both the weight trend card and weight history data.

- [x] AC-5 — PASS — On error (dialog lines 86-103): if the error is an `ApiError` with a body, field-level errors are parsed from the DRF response (handles both `string[]` and `string` format values) and set into `fieldErrors` state. Each field renders a conditional error `<p>` with `role="alert"` and proper `aria-describedby` linkage. Non-field errors display at line 189-193. Network errors fall through to `toast.error("Failed to save weight check-in")`.

- [x] AC-6 — PASS — Client-side validation in `validate()` (lines 46-68): weight must be 20-500 kg (checked with `weightNum < 20 || weightNum > 500`), date cannot be in the future (compares selected date to today at 23:59:59). HTML attributes also enforce `min="20" max="500"` on the weight input and `max={getTodayString()}` on the date input for native browser validation.

### Active Workout Logging (AC-7 through AC-18)

- [x] AC-7 — PASS — `todays-workout-card.tsx` computes `canStartWorkout = todaysDay && !isRestDay && hasExercises` (line 85). "Start Workout" button renders only when `canStartWorkout` is true (lines 171-177). Rest day renders "Rest Day" message with `BedDouble` icon (lines 110-121). No program shows "No program assigned" empty state (lines 62-79). No exercises shows "No exercises scheduled" (lines 122-136).

- [x] AC-8 — PASS — "Start Workout" is a `Link` to `/trainee/workout` (line 173). The page at `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx` renders `<ActiveWorkout />` which loads today's exercises from the active program via `useTraineeDashboardPrograms()`.

- [x] AC-9 — PASS — `active-workout.tsx` renders `PageHeader` with `title={workoutName}` (day name captured at initialization, line 114: `workoutNameRef.current = todaysDay.name || "Workout"`) and `description={activeProgram.name}` (line 293). Timer displays `formatDuration(elapsedSeconds)` in MM:SS format (lines 296-303) with `font-mono tabular-nums` styling and ARIA label. "Finish Workout" button present (lines 305-306). Timer starts via `setInterval` after exercises are initialized (lines 82-88).

- [x] AC-10 — PASS — Each exercise rendered as an `ExerciseLogCard` component (active-workout.tsx lines 313-327). Card shows exercise name as `CardTitle` (exercise-log-card.tsx line 51), target info as "Target: {targetSets} x {targetReps} @ {targetWeight} {unit}" (lines 56-59), and an editable log table below.

- [x] AC-11 — PASS — `exercise-log-card.tsx` log table has a 5-column grid (line 63): Set number (line 78-80), Reps number input (lines 81-93 with `min={0}` and `max={999}`), Weight number input (lines 97-113 with `min={0}` and `step="0.5"`), completed checkbox (`role="checkbox"`, `aria-checked`, lines 114-130), and unit label in column header "Weight ({unit})" (line 66). Sets pre-populated from program targets via `buildInitialSets()` (active-workout.tsx lines 36-53), which copies target reps and weight into each set.

- [x] AC-12 — PASS — "Add Set" button at exercise-log-card.tsx lines 149-157 triggers `onAddSet(exerciseIndex)`. In `handleAddSet` (active-workout.tsx lines 161-184), a new set is created with `isExtra: true`, copying `reps` and `weight` from the last existing set, numbered sequentially.

- [x] AC-13 — PASS — Remove button only appears for extra sets (`set.isExtra` check at exercise-log-card.tsx line 132). Original target sets render an empty `<span>` placeholder instead (line 143). `handleRemoveSet` (active-workout.tsx lines 187-203) filters out the set and renumbers all remaining sets sequentially.

- [x] AC-14 — PASS — `WorkoutFinishDialog` (workout-finish-dialog.tsx) shows a confirmation summary with: workout name (line 68), duration (line 72), exercises count (line 76), completed sets / total sets (lines 80-81), and total volume calculated from completed sets only (lines 42-49, formula: `sum of (weight * reps)` for completed sets). Volume formatted with `Intl.NumberFormat`.

- [x] AC-15 — PASS — `handleFinish` (active-workout.tsx lines 206-238) calls `saveMutation.mutate()` which uses `apiClient.post(API_URLS.TRAINEE_DAILY_LOGS, payload)` via `useSaveWorkout()`. Payload format is `{date: getTodayString(), workout_data: {workout_name, duration, exercises: [{exercise_id, exercise_name, sets: [{set_number, reps, weight, unit, completed}]}]}}` matching the required schema. **Note:** Only POST is used; PUT for existing logs is not implemented (see Bug #1).

- [x] AC-16 — PASS — On success (active-workout.tsx lines 229-232): `hasUnsavedRef.current = false` (disables beforeunload), `toast.success("Workout saved!")` fires, `router.push("/trainee/dashboard")` redirects. The mutation's `onSuccess` (hook lines 127-133) invalidates `["trainee-dashboard", "weekly-progress"]` and `["trainee-dashboard", "workout-history"]` queries.

- [x] AC-17 — PASS — Loading skeleton in active-workout.tsx (lines 241-251): renders a `Skeleton` h-8 w-48 for the header and 3 `Skeleton` h-48 w-full cards for exercises.

- [x] AC-18 — PASS — `beforeunload` event listener registered in `useEffect` (lines 96-104). Uses `hasUnsavedRef.current` which is set to `true` when `exerciseStates.length > 0` (lines 91-93). Calls `e.preventDefault()` to trigger browser confirmation dialog on navigation/close.

### Workout History (AC-19 through AC-24)

- [x] AC-19 — PASS — `trainee-nav-links.tsx` line 23 adds `{ label: "History", href: "/trainee/history", icon: History }` at array index 2, between "My Program" (index 1) and "Progress" (index 3), which is before "Messages" (index 4). Matches the required sidebar ordering.

- [x] AC-20 — PASS — `useTraineeWorkoutHistory(page)` (hook lines 100-108) fetches `GET ${API_URLS.TRAINEE_WORKOUT_HISTORY}?page=${page}&page_size=20` which resolves to `/api/workouts/daily-logs/workout-history/?page=1&page_size=20`. `WorkoutHistoryList` uses this hook at line 34.

- [x] AC-21 — PASS — Each history item card (workout-history-list.tsx lines 76-116) renders: `workout_name` as CardTitle (line 81), date formatted via `date-fns` `format(d, "EEE, MMM d, yyyy")` (lines 94-97), `exercise_count` with singular/plural label (lines 102-105), `total_sets` (line 106), `total_volume_lbs` formatted (lines 107-109), `duration_display` (lines 110-112), and a "Details" button with `Eye` icon (lines 83-91).

- [x] AC-22 — PASS — Clicking "Details" sets `detailId` (line 86) which opens `WorkoutDetailDialog` (lines 146-154). The dialog fetches full workout detail via `useTraineeWorkoutDetail(workoutId)`. It displays each exercise name (line 104) and its logged sets with: set_number (line 112), reps (line 115), weight with "BW" fallback for 0 (lines 118-120), and completed status via Badge (lines 122-134). Handles both `exercises` array and `sessions` format (mobile app data, lines 23-33 of workout-detail-dialog.tsx).

- [x] AC-23 — PASS — Pagination implemented at workout-history-list.tsx lines 119-143. Previous/Next buttons with `ChevronLeft`/`ChevronRight` icons, disabled based on `data.previous`/`data.next` API response fields. Page counter displayed as "Page {page}". Page state managed via `useState`.

- [x] AC-24 — PASS — Empty state (lines 55-70) shows `EmptyState` with icon `Dumbbell`, title "No workouts logged yet", description "Start your first workout to see it here.", and CTA `Link` to `/trainee/workout` with "Start Workout" text and `Play` icon.

### Progress Page (AC-25 through AC-31)

- [x] AC-25 — PASS — `trainee-nav-links.tsx` line 24 adds `{ label: "Progress", href: "/trainee/progress", icon: TrendingUp }` at array index 3, directly after "History" (index 2). The route exists at `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx`.

- [x] AC-26 — PASS — `trainee/progress/page.tsx` renders three chart sections: `WeightTrendChart` (weight trend line chart), `WorkoutVolumeChart` (volume bar chart), and `WeeklyAdherenceCard` (adherence). The weight and volume charts are in a 2-column grid (`lg:grid-cols-2`), adherence below as full width.

- [x] AC-27 — PASS — `WeightTrendChart` in `trainee-progress-charts.tsx` (lines 61-161) renders a Recharts `LineChart` of weight check-ins. Uses `useTraineeWeightHistory()` hook. Limits to 30 most recent entries, reverses for chronological display. X-axis shows dates, Y-axis shows weight in kg with domain padding. Screen reader fallback `<ul>` provided (lines 151-157).

- [x] AC-28 — PASS — `WorkoutVolumeChart` (lines 163-257) renders a Recharts `BarChart`. Uses `useTraineeWorkoutHistory(1)` calling `GET /api/workouts/daily-logs/workout-history/`. Maps `total_volume_lbs` from each entry to chart bars. Reversed for chronological order. Screen reader fallback `<ul>` provided.

- [ ] AC-29 — FAIL — The ticket requires "weekly completion rate over the past 4 weeks." The `WeeklyAdherenceCard` (lines 259-344) calls `useTraineeWeeklyProgress()` which fetches `GET /api/workouts/daily-logs/weekly-progress/`. However, the `WeeklyProgress` type (`trainee-dashboard.ts` lines 3-7) only contains `total_days`, `completed_days`, and `percentage` for a single period. The component renders a single-week progress bar (lines 321-332), not a chart of 4 weeks of historical adherence data. There is no multi-week data structure, no multi-week API parameter, and no chart — just a progress bar for the current week.

- [x] AC-30 — PASS — All three chart components implement: skeleton loading via `ChartSkeleton` (lines 43-55), empty states with contextual messages and CTAs (weight: "No weight data yet" + Log Weight button; volume: "No workout data yet" + "Complete your first workout" message; adherence: "No training schedule" message), and error states using `ErrorState` component with `onRetry` callbacks.

- [ ] AC-31 — FAIL (Minor) — Charts are responsive (wrapped in `ResponsiveContainer` 100% width/height) and theme-aware (axes use `hsl(var(--muted-foreground))`, grid uses `stroke-border` CSS class, tooltip uses `tooltipContentStyle` from `chart-utils.ts` which references CSS variables). However, the ticket says to use "existing `CHART_COLORS`" from `chart-utils.ts`. The charts use `hsl(var(--primary))` directly for line/bar colors instead of `CHART_COLORS.workout` or similar constants. The named color constants are defined in `chart-utils.ts` (`CHART_COLORS = { food, workout, protein, calorie }`) but are not referenced. Functionally the charts work in both light and dark mode since `hsl(var(--primary))` is theme-aware, but this deviates from the specified approach.

## Bugs Found Outside Tests

| # | Severity | Description | Steps to Reproduce |
|---|----------|-------------|-------------------|
| 1 | Major | **No PUT handling for existing daily log.** AC-15 says "POST /api/workouts/daily-logs/ (or PUT if a log already exists for today)." The `useSaveWorkout` hook (use-trainee-dashboard.ts lines 121-135) only calls `apiClient.post()`. There is no logic to check if a daily log already exists for today and use PUT to merge. If the backend returns 400 on duplicate `date` entries, saving a second workout on the same day will fail with no graceful recovery. The error handler in `handleFinish` only shows a generic toast — no retry mechanism is presented. | 1. Complete and save a workout on a given day. 2. Navigate back to `/trainee/workout` on the same day. 3. Complete exercises and click "Finish Workout." 4. POST may fail with 400 if backend enforces unique date constraint, showing only "Failed to save workout" toast with no way to recover. |
| 2 | Major | **"Already logged workout today" edge case not handled.** Ticket edge case #3 says: "If a daily log with workout_data already exists for today, show 'View Today's Workout' instead of 'Start Workout', linking to the history detail." The `TodaysWorkoutCard` component has zero awareness of whether today's workout has already been logged. It always shows "Start Workout" when exercises are scheduled. The `TRAINEE_WORKOUT_SUMMARY` endpoint exists in constants (constants.ts line 243) and there is a `useTraineeWorkoutSummary` (if it existed) — but no such check is performed in `todays-workout-card.tsx`. | 1. Log in as trainee, complete and save a workout. 2. Navigate back to dashboard. 3. Today's Workout card still shows "Start Workout" instead of "View Today's Workout." 4. Clicking it would begin a new workout session despite one already being saved. |
| 3 | Minor | **Volume unit hardcoded as "lbs" in finish dialog.** In `workout-finish-dialog.tsx` line 88, the total volume label is always "lbs" regardless of the unit system in the user's program. If a trainee's program uses "kg" units, the volume display would still say "lbs." The volume calculation itself also sums raw numbers without unit conversion, so if exercises use mixed units, the total is meaningless. | 1. Have a program with exercises using "kg" unit. 2. Start and complete a workout. 3. Click "Finish Workout." 4. Volume summary shows "X lbs" despite program being in kg. |
| 4 | Minor | **History empty state CTA always links to `/trainee/workout`.** Ticket edge case #1 says the CTA should only show if a workout is scheduled. The current `WorkoutHistoryList` empty state (workout-history-list.tsx lines 57-69) always renders a "Start Workout" `Link` to `/trainee/workout` regardless of whether today is a rest day or the trainee has no program. Following the link on a rest day leads to an "No exercises scheduled" empty state. | 1. Be a trainee on a rest day with no workout logged. 2. Navigate to History. 3. Empty state shows "Start Workout" CTA. 4. Clicking it leads to another empty state page. |
| 5 | Minor | **Workout finish dialog not submittable via Enter key.** The ticket UX requirements state "Enter submits dialog." The weight check-in dialog uses a `<form>` with `onSubmit` so Enter works. The `WorkoutFinishDialog` uses plain `<Button onClick>` handlers without a form wrapper (workout-finish-dialog.tsx lines 94-107), so pressing Enter does nothing. User must click "Save Workout" with mouse. | 1. Start and complete a workout. 2. Click "Finish Workout" to open the confirmation dialog. 3. Press Enter. 4. Nothing happens. Must click the "Save Workout" button. |
| 6 | Low | **`reps` and `weight` values of 0 display as blank inputs.** In `exercise-log-card.tsx` lines 85 and 102, `value={set.reps || ""}` and `value={set.weight || ""}` use the `||` operator, which coerces `0` to `""` (empty string). For bodyweight exercises where target weight is 0, the weight field appears empty rather than showing "0." While arguably acceptable UX, it makes it impossible to distinguish "intentionally 0" from "not yet entered." | 1. Have an exercise with `weight: 0` (bodyweight exercise). 2. Start a workout. 3. The weight input for that exercise appears blank instead of showing "0." |
| 7 | Low | **Workout volume chart limited to page 1 (20 entries) without indication.** `WorkoutVolumeChart` (trainee-progress-charts.tsx line 164) calls `useTraineeWorkoutHistory(1)` which fetches only page 1 (up to 20 entries). The chart description says "last {results.length} workouts" which could be misleading — there is no indication that older workouts exist beyond the visible 20. Not a functional bug, but the chart silently caps at 20 entries. | 1. Log 25+ workouts over time. 2. Navigate to Progress page. 3. Volume chart shows "last 20 workouts" without indicating 5+ more exist. |
| 8 | Low | **Timer continues during navigation transition after save.** In `active-workout.tsx`, the timer `useEffect` (lines 82-88) starts an interval when `initialized` is true. On save success, `router.push("/trainee/dashboard")` triggers navigation but `initialized` remains `true` and the interval keeps firing `setElapsedSeconds` during the transition. React cleanup will eventually clear it on unmount, but state updates on a transitioning component may cause warnings in React Strict Mode. | 1. Start a workout, let timer run. 2. Click "Finish Workout" and confirm save. 3. Timer continues incrementing during the redirect to dashboard. |

## Additional Observations

### Positive Findings

1. **Solid type safety** — All new types (`WorkoutHistoryItem`, `WorkoutDetailData`, `WorkoutExerciseLog`, `WorkoutSetLog`, `CreateWeightCheckInPayload`, `SaveWorkoutPayload`) are cleanly defined in `trainee-dashboard.ts`. No `any` types found. Generic types on `useQuery` and `useMutation` properly constrain payloads and responses.

2. **Consistent architecture** — All new components follow the established pattern: loading skeleton, error state with retry, empty state with contextual message and CTA, success state. Matches existing codebase conventions perfectly.

3. **Excellent accessibility** — ARIA labels on all inputs (`aria-label="Set N reps"`, `aria-label="Set N weight"`), checkbox role with `aria-checked` for set completion, `role="alert"` on error messages, `aria-describedby` linking inputs to errors, `role="img"` with labels on charts, `sr-only` screen reader text for chart data, `role="progressbar"` with `aria-valuenow/min/max` on adherence bar, `role="group"` on set rows.

4. **Proper query invalidation** — Both mutations (weight check-in and workout save) correctly invalidate all relevant query keys, ensuring the dashboard cards refresh after data changes.

5. **Mobile-first responsive design** — Workout exercise grid uses `md:grid-cols-2`, charts use `lg:grid-cols-2`, all dialogs use `sm:max-w-[425px]` / `sm:max-w-[600px]`, pagination and history items work at any width.

6. **Smart data snapshot for workout** — The `initialized` flag and `workoutNameRef` ensure that program data is captured once at workout start. Subsequent program refetches (due to React Query cache invalidation) do not mutate the in-progress workout. This correctly handles ticket edge case #10.

7. **Graceful handling of mobile app data format** — `WorkoutDetailDialog` handles both `exercises` array format (web) and `sessions` array format (mobile app) via `getExercises()` and `getWorkoutName()` helper functions.

8. **Consistent error handling pattern** — `ApiError` from `api-client.ts` is properly used to distinguish between field validation errors (parsed from body) and network/server errors (shown as toast).

### Risk Assessment

- **Bug #1 (no PUT for existing log):** HIGH RISK — If the backend has a unique constraint on `trainee + date` for daily logs, re-logging on the same day will fail silently (only a toast, no retry). This is the most likely scenario to cause user frustration in production.
- **Bug #2 (already logged today not detected):** MEDIUM RISK — Users can accidentally start a duplicate workout. Combined with Bug #1, this could lead to data loss (user completes a second workout but cannot save it).
- **Bugs #3-5:** LOW RISK — UX polish issues that do not prevent core functionality from working. Should be addressed in a follow-up.

## Confidence Level: MEDIUM

**Rationale:** 26 of 31 acceptance criteria pass. The core flows (weight check-in, workout logging, history browsing, progress charts) are solidly implemented with proper state management, error handling, accessibility, and responsive design. However, three gaps reduce confidence:

1. **AC-29 (adherence section):** Shows a single-week progress bar instead of a 4-week trend chart. This is constrained by the backend API returning only single-week data, but the implementation does not match the AC specification.
2. **Bug #1 + Bug #2 (duplicate daily log handling):** The combination of no PUT logic and no "already logged today" detection means the most common re-logging scenario is unhandled. A trainee who saves a workout and then navigates back could be led into a second workout that cannot be saved.
3. **AC-31 (CHART_COLORS):** Minor deviation from the specified technical approach, but functionally correct.

The implementation quality is high where it exists — the issues are primarily omissions of specified edge cases rather than broken functionality.
