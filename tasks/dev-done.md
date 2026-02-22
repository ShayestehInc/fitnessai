# Dev Done: Trainee Web — Workout Logging & Progress Tracking

## Date: 2026-02-21

## Summary
Added interactive workout logging, weight check-in, workout history, and progress charts to the trainee web portal. The portal was previously read-only (Pipeline 32); this pipeline makes it fully interactive for workout tracking.

## Files Created (11)

### Components
1. `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` — Weight check-in form dialog with kg input, date picker, notes, client-side validation (20-500 kg, no future dates), backend error display
2. `web/src/components/trainee-dashboard/active-workout.tsx` — Full active workout component with timer, exercise state management, beforeunload guard, save mutation
3. `web/src/components/trainee-dashboard/exercise-log-card.tsx` — Individual exercise logging card with set table (reps, weight, completed checkbox), add/remove sets, target display
4. `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` — Workout completion confirmation dialog showing summary (exercises, sets, volume, duration)
5. `web/src/components/trainee-dashboard/workout-history-list.tsx` — Paginated workout history list with detail dialog integration
6. `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` — Workout detail view dialog showing all exercises with logged sets
7. `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` — Three progress components: WeightTrendChart (line), WorkoutVolumeChart (bar), WeeklyAdherenceCard (progress bar)
8. `web/src/components/ui/textarea.tsx` — Standard shadcn/ui textarea component

### Pages
9. `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx` — Active workout page
10. `web/src/app/(trainee-dashboard)/trainee/history/page.tsx` — Workout history page
11. `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx` — Progress charts page

## Files Modified (6)
1. `web/src/types/trainee-dashboard.ts` — Added 9 new types: WorkoutHistoryItem, WorkoutHistoryResponse, WorkoutDetailData, WorkoutData, WorkoutSession, WorkoutExerciseLog, WorkoutSetLog, CreateWeightCheckInPayload, SaveWorkoutPayload
2. `web/src/lib/constants.ts` — Added 3 API URL constants: TRAINEE_DAILY_LOGS, TRAINEE_WORKOUT_HISTORY, traineeWorkoutDetail(id)
3. `web/src/hooks/use-trainee-dashboard.ts` — Added 4 hooks: useCreateWeightCheckIn (mutation), useTraineeWorkoutHistory (query), useTraineeWorkoutDetail (query), useSaveWorkout (mutation)
4. `web/src/components/trainee-dashboard/trainee-nav-links.tsx` — Added History and Progress nav links (8 total, was 6)
5. `web/src/components/trainee-dashboard/weight-trend-card.tsx` — Added "Log Weight" button and WeightCheckInDialog integration
6. `web/src/components/trainee-dashboard/todays-workout-card.tsx` — Added "Start Workout" button linking to /trainee/workout

## Key Decisions
1. Used native HTML button with role="checkbox" instead of Radix Checkbox to avoid adding new dependency
2. Timer is client-side only (useState + setInterval), not persisted to backend
3. Workout data format matches existing backend `workout_data` JSONField schema
4. No readiness/post-workout surveys — deferred to keep scope manageable (mobile-only for now)
5. Progress charts reuse the same recharts + chart-utils patterns as the trainer analytics page
6. Weight chart reverses API data (newest-first) to display chronologically (left=old, right=new)

## How to Test
1. Log in as TRAINEE user
2. Dashboard: Weight card shows "Log Weight" button -> opens dialog -> submit -> toast + card refresh
3. Dashboard: Today's Workout card shows "Start Workout" button -> navigates to /trainee/workout
4. /trainee/workout: Timer runs, edit reps/weight, toggle completed checkboxes, add/remove sets, "Finish Workout" -> summary dialog -> save -> redirect to dashboard
5. /trainee/history: Shows paginated workout history, click "Details" -> full workout view in dialog
6. /trainee/progress: Weight trend line chart, workout volume bar chart, weekly adherence with color-coded progress bar
7. All pages have loading, empty, and error states
8. beforeunload fires if navigating away during active workout
