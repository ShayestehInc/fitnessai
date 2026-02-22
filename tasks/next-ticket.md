# Feature: Trainee Web — Workout Logging & Progress Tracking

## Priority
High

## User Story
As a trainee using the web portal, I want to record weight check-ins, log completed workouts with sets/reps/weight, view my workout history, and see progress charts — so that I can fully manage my training from a browser without needing the mobile app.

## Background
Pipeline 32 shipped a read-only trainee web portal with 6 pages (Dashboard, Program, Messages, Announcements, Achievements, Settings). Trainees can view their assigned program and nutrition macros but cannot interact — no workout logging, no weight recording, no progress charts. All backend APIs already exist; this is purely frontend work.

## Acceptance Criteria

### Weight Check-In (AC-1 through AC-6)
- [ ] AC-1: Weight trend card on dashboard shows a "Log Weight" button
- [ ] AC-2: Clicking "Log Weight" opens a dialog with weight (number input, kg), date (date picker, defaults to today), and optional notes (textarea)
- [ ] AC-3: Submitting the form calls `POST /api/workouts/weight-checkins/` with `{date, weight_kg, notes}`
- [ ] AC-4: On success, the dialog closes, weight trend card refreshes (invalidate `trainee-dashboard/weight-checkins` and `trainee-dashboard/latest-weight` queries), and a success toast shows
- [ ] AC-5: On error, inline error message appears (field validation from backend shown per-field, network errors shown as alert)
- [ ] AC-6: Weight input validates range client-side (20-500 kg), date cannot be in the future

### Active Workout Logging (AC-7 through AC-18)
- [ ] AC-7: Today's workout card on dashboard shows a "Start Workout" button when there are exercises scheduled for today (not a rest day, not "no program")
- [ ] AC-8: Clicking "Start Workout" navigates to `/trainee/workout` page with the day's exercises pre-loaded
- [ ] AC-9: The workout page shows a header with workout name (day name from program), a running timer (MM:SS), and a "Finish Workout" button
- [ ] AC-10: Each exercise is displayed as a card with exercise name, target sets/reps/weight from program, and an editable log table
- [ ] AC-11: The log table has rows for each set (pre-populated from program target). Each row has: set number, reps input (number), weight input (number), unit label (lbs/kg from program), and a "completed" checkbox
- [ ] AC-12: User can add additional sets beyond the target with an "Add Set" button per exercise
- [ ] AC-13: User can remove added sets (but not original target sets) with a remove button
- [ ] AC-14: Clicking "Finish Workout" shows a confirmation dialog with summary (exercises completed, total sets, total volume)
- [ ] AC-15: Confirming saves the workout via `POST /api/workouts/daily-logs/` (or PUT if a log already exists for today) with `workout_data` JSON containing the exercises and sets
- [ ] AC-16: On successful save, user is redirected to dashboard with a success toast, weekly progress card refreshes
- [ ] AC-17: The workout page shows loading skeleton while fetching program data
- [ ] AC-18: If user navigates away mid-workout, a browser `beforeunload` confirmation prevents accidental data loss

### Workout History (AC-19 through AC-24)
- [ ] AC-19: New "History" nav link added to trainee sidebar (between "My Program" and "Messages"), navigating to `/trainee/history`
- [ ] AC-20: History page shows a list of completed workouts fetched from `GET /api/workouts/daily-logs/workout-history/?page=1&page_size=20`
- [ ] AC-21: Each history item shows: date, workout name, exercise count, total sets, total volume, and a "View Details" button
- [ ] AC-22: Clicking "View Details" opens a dialog/panel showing the full workout with each exercise's logged sets (reps, weight, completed status)
- [ ] AC-23: History list supports pagination (Previous/Next buttons based on API response `next`/`previous` fields)
- [ ] AC-24: Empty state shows "No workouts logged yet" with a CTA to start today's workout (links to `/trainee/workout` if a workout is scheduled)

### Progress Page (AC-25 through AC-31)
- [ ] AC-25: New "Progress" nav link added to trainee sidebar (after "History"), navigating to `/trainee/progress`
- [ ] AC-26: Progress page shows three chart sections: Weight Trend, Workout Volume, and Adherence
- [ ] AC-27: Weight Trend section shows a line chart of weight check-ins over time (reuse/adapt `WeightChart` from `progress-charts.tsx`). Data from `useTraineeWeightHistory()` hook.
- [ ] AC-28: Workout Volume section shows a bar chart of daily workout volume (total weight x reps). Data from a new `useTraineeWorkoutHistory()` hook calling `GET /api/workouts/daily-logs/workout-history/`.
- [ ] AC-29: Adherence section shows weekly completion rate over the past 4 weeks. Data from `GET /api/workouts/daily-logs/weekly-progress/` (extend or add endpoint if needed).
- [ ] AC-30: Each chart section has: skeleton loading, empty state with contextual message, error with retry button
- [ ] AC-31: Charts are responsive and theme-aware (work in both light and dark mode using existing `CHART_COLORS` and `tooltipContentStyle`)

## Edge Cases
1. **No program assigned**: "Start Workout" button hidden. History empty state shows "No program assigned — ask your trainer."
2. **Rest day**: "Start Workout" button hidden. Card shows "Rest Day" badge.
3. **Already logged workout today**: If a daily log with workout_data already exists for today, show "View Today's Workout" instead of "Start Workout", linking to the history detail.
4. **Zero weight entries**: Weight trend chart shows empty state "Log your first weight check-in" with button to open dialog.
5. **Duplicate date weight check-in**: Backend returns 400 (unique constraint on trainee+date). Show "You already have a weight entry for this date" error.
6. **Network failure mid-workout**: beforeunload prevents accidental navigation. If POST fails, show error with retry button. Workout data stays in component state.
7. **Very long workout history**: Pagination handles it (20 per page).
8. **Negative or zero values**: Reps must be >= 0, weight >= 0. Client-side validation with helpful error messages.
9. **Concurrent tab editing**: Not handled (browser only has one session). Each tab loads fresh data from API.
10. **Program changes mid-workout**: Workout uses the snapshot of exercises loaded at start time. Program changes don't affect in-progress workout.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Weight POST 400 (duplicate date) | "A weight entry for this date already exists" | Show inline error, keep dialog open |
| Weight POST 400 (invalid range) | "Weight must be between 20 and 500 kg" | Show inline error |
| Workout POST fails (network) | "Failed to save workout. Please try again." | Show error alert with retry button |
| History GET fails | ErrorState with retry button | Standard error component |
| Progress chart data fails | Per-chart error state with retry | Each chart independent |
| No program for workout | "No exercises scheduled for today" | Hide "Start Workout" button |

## UX Requirements
- **Loading state**: Skeleton loaders on history list, progress charts, workout page. Spinner on dialog submit buttons.
- **Empty state**: Contextual message + CTA for each empty section (no workouts -> start workout, no weight -> log weight, no charts -> needs data)
- **Error state**: ErrorState component with retry button (existing shared component)
- **Success feedback**: Sonner toast on weight check-in save, workout completion, with descriptive message
- **Mobile behavior**: All pages responsive. Workout logging page usable on mobile web. History and progress use card layout on mobile, table on desktop.
- **Keyboard**: Weight dialog form navigable by Tab. Workout set inputs navigable by Tab. Enter submits dialog. Escape closes dialogs.
- **Accessibility**: ARIA labels on all inputs, progress bars, charts. Screen reader descriptions for chart data (sr-only lists as done in existing charts).

## Technical Approach

### Files to Create
| File | Purpose |
|------|---------|
| `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx` | Active workout logging page |
| `web/src/app/(trainee-dashboard)/trainee/history/page.tsx` | Workout history list page |
| `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx` | Progress charts page |
| `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` | Weight check-in form dialog |
| `web/src/components/trainee-dashboard/active-workout.tsx` | Active workout logging component |
| `web/src/components/trainee-dashboard/exercise-log-card.tsx` | Single exercise with set logging |
| `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` | Workout completion confirmation |
| `web/src/components/trainee-dashboard/workout-history-list.tsx` | History list with pagination |
| `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` | Workout detail view dialog |
| `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` | Progress charts adapted for trainee self-view |

### Files to Modify
| File | Change |
|------|--------|
| `web/src/lib/constants.ts` | Add `TRAINEE_DAILY_LOGS`, `TRAINEE_WORKOUT_HISTORY`, `TRAINEE_WORKOUT_DETAIL` URL constants |
| `web/src/hooks/use-trainee-dashboard.ts` | Add `useCreateWeightCheckIn()` mutation, `useTraineeWorkoutHistory()`, `useSaveDailyLog()` mutation |
| `web/src/types/trainee-dashboard.ts` | Add `WorkoutHistoryItem`, `WorkoutDetailData`, `WorkoutExerciseLog`, `WorkoutSetLog`, `CreateWeightCheckInPayload` types |
| `web/src/components/trainee-dashboard/trainee-nav-links.tsx` | Add "History" and "Progress" nav links |
| `web/src/components/trainee-dashboard/weight-trend-card.tsx` | Add "Log Weight" button that opens weight check-in dialog |
| `web/src/components/trainee-dashboard/todays-workout-card.tsx` | Add "Start Workout" button linking to `/trainee/workout` |

### API Endpoints Used (all existing)
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/workouts/weight-checkins/` | POST | Create weight check-in |
| `/api/workouts/daily-logs/` | POST/PUT | Save workout data to daily log |
| `/api/workouts/daily-logs/workout-history/` | GET | Paginated workout history |
| `/api/workouts/daily-logs/{id}/workout-detail/` | GET | Single workout detail |
| `/api/workouts/programs/` | GET | Get active program (for workout exercises) |
| `/api/workouts/weight-checkins/` | GET | Weight history for chart |
| `/api/workouts/daily-logs/weekly-progress/` | GET | Weekly adherence data |

### Key Design Decisions
1. **Workout data format**: Match the existing `workout_data` JSONField schema (`{exercises: [{exercise_id, exercise_name, sets: [{set_number, reps, weight, unit, completed}]}]}`)
2. **Daily log creation**: Use `POST /api/workouts/daily-logs/` with `{date: today, workout_data: {...}}`. If log already exists for today, merge via PUT.
3. **Timer**: Client-side timer using `useState` + `useEffect` interval. Not persisted to backend — purely UX.
4. **Chart reuse**: Adapt existing `WeightChart` from `progress-charts.tsx` for trainee self-view. Create volume chart similarly.
5. **No readiness/post-workout surveys**: Skip surveys for web v1 to keep scope manageable. Mobile remains the full experience.

## Out of Scope
- Pre-workout readiness survey (mobile only for now)
- Post-workout survey (mobile only for now)
- Rest timer between sets (mobile only for now)
- AI natural language workout parsing (future pipeline)
- Nutrition logging (future pipeline)
- Food search (future pipeline)
- Offline workout logging (mobile only)
- Exercise video/image display in workout logging
