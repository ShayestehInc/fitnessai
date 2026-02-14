# Focus: Fix All 5 Trainee-Side Bugs

Priority #1 from CLAUDE.md. All trainee workout functionality is broken.

## Bugs to Fix (ordered by severity)
1. **BUG-1 [CRITICAL]**: Workout data never saves to database — 100% data loss
2. **BUG-2 [HIGH]**: Trainer never gets notified — wrong attribute used
3. **BUG-3 [HIGH]**: Fake sample data shows instead of real programs
4. **BUG-4 [MEDIUM]**: Debug print statements in production code
5. **BUG-5 [MEDIUM]**: Program switcher not implemented

## Success Criteria
- Completing a workout persists all exercise data to DailyLog.workout_data
- Trainer receives notification when trainee starts or finishes a workout
- Trainee sees their real assigned program, not sample data
- No print() debug statements in workout_repository.dart
- Trainee can switch between assigned programs via bottom sheet
