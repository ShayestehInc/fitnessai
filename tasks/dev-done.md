# Dev Done: Fix All 5 Trainee-Side Workout Bugs

## Date: 2026-02-13

## Files Changed

### Backend
1. **`backend/workouts/survey_views.py`**
   - BUG-1: Added `_save_workout_to_daily_log()` method to `PostWorkoutSurveyView`
     - Uses `DailyLog.objects.get_or_create(trainee=user, date=today)`
     - Merges exercises if multiple workouts in one day (appends to existing list)
     - Saves via `save(update_fields=['workout_data'])` to avoid overwriting nutrition_data
     - Error is caught and logged but does not block survey submission
   - BUG-2: Replaced `getattr(user, 'trainer', None)` with `user.parent_trainer` in both views
     - `ReadinessSurveyView.post()` line ~56
     - `PostWorkoutSurveyView.post()` line ~205
   - Replaced silent `except (ImportError, Exception): pass` with proper `logger.error()` calls
   - Added `import logging` and `from workouts.models import DailyLog`

### Mobile
2. **`mobile/lib/features/workout_log/presentation/providers/workout_provider.dart`**
   - BUG-3: `_parseProgramWeeks()` now returns `[]` instead of `_generateSampleWeeks()` when schedule is null/empty
   - Removed `_generateSampleWeeks()` method entirely (130+ lines of dead sample data)
   - Removed `_getSampleExercises()` method entirely
   - Added `switchProgram(ProgramModel program)` method for BUG-5

3. **`mobile/lib/features/workout_log/data/repositories/workout_repository.dart`**
   - BUG-4: Removed all 15+ `print('[WorkoutRepository]...')` debug statements

4. **`mobile/lib/features/workout_log/presentation/screens/workout_log_screen.dart`**
   - BUG-5: Replaced `// TODO: Show program switcher` with `_showProgramSwitcher()` call
   - Added `_showProgramSwitcher()` method: bottom sheet listing all programs with active indicator
   - Updated `_buildEmptyState()` to differentiate between:
     - No programs assigned: "Your trainer will assign you a program soon"
     - Empty schedule: "Your trainer hasn't built your schedule yet"
     - No workouts this week: "Check other weeks or contact your trainer"

## Key Decisions
- Workout save errors do NOT block the survey response (non-blocking, returns warning field)
- Exercise data is merged (appended) for multiple workouts per day, not overwritten
- Sample data methods deleted entirely rather than kept around
- Program switcher shows snackbar confirmation + handles edge cases (0 programs, 1 program)

## How to Manually Test
1. **BUG-1**: Complete a workout → check DailyLog in admin for today's date → workout_data should be populated
2. **BUG-2**: Complete a readiness survey → check TrainerNotification in admin → notification should exist for parent_trainer
3. **BUG-3**: Assign a real program to a trainee → open workout log → should show real exercises, not "Push Day/Pull Day/Legs"
4. **BUG-4**: Open workout log → check Flutter console → no `[WorkoutRepository]` prints
5. **BUG-5**: Tap "..." menu → "Switch Program" → bottom sheet shows all programs → tap to switch
