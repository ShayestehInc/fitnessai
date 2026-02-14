# Feature: Fix All 5 Trainee-Side Workout Bugs

## Priority
Critical

## User Story
As a trainee, I want my workout data to be saved, my real program to be displayed, and my trainer to be notified when I work out, so that my training is tracked and my trainer can monitor my progress.

As a trainer, I want to receive notifications when my trainees start and complete workouts, so that I can monitor their adherence and provide timely feedback.

## Acceptance Criteria
- [x] AC-1: Completing a workout via PostWorkoutSurveyView persists all exercise data to `DailyLog.workout_data` using `get_or_create` for today's date
- [x] AC-2: If a trainee completes multiple workouts in one day, exercise data is merged (appended) into the existing DailyLog
- [x] AC-3: Trainer receives an in-app notification (TrainerNotification) when a trainee submits a readiness survey
- [x] AC-4: Trainer receives an in-app notification when a trainee completes a post-workout survey
- [x] AC-5: Trainee with a real assigned program sees their actual program schedule, not hardcoded sample data
- [x] AC-6: Trainee with zero programs sees an informative empty state ("Your trainer hasn't assigned a program yet")
- [x] AC-7: Trainee with a program that has an empty/null schedule sees "Your trainer hasn't built your schedule yet"
- [x] AC-8: All `print()` debug statements are removed from `workout_repository.dart`
- [x] AC-9: "Switch Program" menu item opens a bottom sheet listing all assigned programs
- [x] AC-10: Tapping a program in the switcher updates the active program in provider state and reloads the schedule

## Edge Cases
1. **No DailyLog exists for today**: `get_or_create` creates a new one with the workout data
2. **DailyLog already has workout_data**: New exercises are appended to the existing exercises list (merge, don't overwrite)
3. **DailyLog already has nutrition_data**: Workout save must NOT overwrite existing nutrition_data
4. **Trainee has no parent_trainer**: Notification code must handle `parent_trainer is None` gracefully (no crash)
5. **Trainee has exactly one program**: Program switcher shows the single program as active (no switch needed but UI is consistent)
6. **Trainee has multiple programs, none marked active**: First program is used as default
7. **Program schedule is null**: Show "schedule not built yet" empty state, NOT sample data
8. **Program schedule is empty list/map**: Show "schedule not built yet" empty state, NOT sample data
9. **Program schedule parsing fails (bad JSON structure)**: Show error state, NOT sample data
10. **Survey submission with empty exercises list**: Save an empty workout (valid — user may have skipped exercises)

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Workout save fails (DB error) | Survey still succeeds (non-blocking) | Logs error, returns success for survey but includes warning |
| Trainer notification fails | Nothing (transparent to trainee) | Catches exception, continues without crashing |
| Program API returns error | Error message with retry button | Shows cached data if available, error state if not |
| Program schedule parse fails | "Schedule not available" empty state | Falls through to empty state, does NOT generate sample data |
| Program switch fails | Error snackbar | Reverts to previous active program |

## UX Requirements
- **Loading state:** CircularProgressIndicator centered (already exists)
- **Empty state (no programs):** Icon + "No programs assigned" + "Your trainer will assign you a program soon"
- **Empty state (empty schedule):** Icon + "Schedule not built yet" + "Your trainer hasn't built your schedule yet"
- **Error state:** Error message with retry button (already exists)
- **Success feedback:** Program switch shows brief snackbar confirmation
- **Program switcher:** Bottom sheet with program list, active program has checkmark, tap to switch

## Technical Approach

### BUG-1 Fix: Save workout data to DailyLog
- **File:** `backend/workouts/survey_views.py`
- **Change:** Add `_save_workout_to_daily_log()` method to `PostWorkoutSurveyView`
- **Logic:** `DailyLog.objects.get_or_create(trainee=user, date=today)`, then merge workout_data
- **Import:** `DailyLog` from `workouts.models`

### BUG-2 Fix: Correct trainer attribute
- **File:** `backend/workouts/survey_views.py`
- **Change:** Replace `getattr(user, 'trainer', None)` with `user.parent_trainer` on lines ~56 and ~205
- **Both:** ReadinessSurveyView.post() and PostWorkoutSurveyView.post()

### BUG-3 Fix: Stop falling back to sample data
- **File:** `mobile/lib/features/workout_log/presentation/providers/workout_provider.dart`
- **Change:** `_parseProgramWeeks()` returns empty list instead of `_generateSampleWeeks()` when schedule is null/empty
- **Only use sample data:** When `programs` list is empty (trainee has zero programs)
- **Remove:** `_generateSampleWeeks()` and `_getSampleExercises()` methods entirely

### BUG-4 Fix: Remove debug prints
- **File:** `mobile/lib/features/workout_log/data/repositories/workout_repository.dart`
- **Change:** Delete all `print('[WorkoutRepository]...')` statements

### BUG-5 Fix: Implement program switcher
- **File:** `mobile/lib/features/workout_log/presentation/screens/workout_log_screen.dart`
- **Change:** Replace `// TODO: Show program switcher` with call to `_showProgramSwitcher()`
- **New method:** `_showProgramSwitcher()` — bottom sheet listing all programs, tap to switch
- **Provider change:** Add `switchProgram(ProgramModel program)` method to `WorkoutNotifier`

## Out of Scope
- Workout layout variants (Classic/Card/Minimal) — separate ticket
- Offline caching of program data
- Push notifications to trainer device
- Readiness survey persistence to DailyLog (only workout data for now)
- Weight/nutrition data changes
