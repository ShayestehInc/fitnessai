# Code Review: Fix All 5 Trainee-Side Workout Bugs

## Review Date: 2026-02-13

## Files Reviewed
- `backend/workouts/survey_views.py`
- `mobile/lib/features/workout_log/presentation/providers/workout_provider.dart`
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart`
- `mobile/lib/features/workout_log/presentation/screens/workout_log_screen.dart`

## Critical Issues (must fix before merge)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 1 | survey_views.py:271-279 | Dead code: `new_workout_entry` dict is built but never used. The actual workout_data is built separately at line 287. | Remove the unused `new_workout_entry` variable or use it to construct `daily_log.workout_data` |
| 2 | survey_views.py:287-293 | Merge logic overwrites metadata: If trainee does 2 workouts in one day, `workout_name`, `duration`, `post_survey`, `completed_at` from the 2nd workout overwrite the 1st. Only exercises are merged. | Store workouts as a list of workout sessions, or at minimum preserve prior metadata |

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 3 | survey_views.py:260-297 | Race condition: Two concurrent POST requests could both `get_or_create` and then both `save`, with the second overwriting the first's merged exercises | Use `select_for_update()` on the queryset or wrap in `transaction.atomic()`. Low probability for mobile app but should be safe. |
| 4 | workout_log_screen.dart:383-385 | Context issue: `_showProgramSwitcher(context)` is called after `context.pop()` — the bottom sheet `context` from `_showProgramOptions` is popped, then `_showProgramSwitcher` tries to use the widget's own `context`, which should be fine but the new bottom sheet might show before the first one fully closes. | Use `Future.delayed` or `WidgetsBinding.addPostFrameCallback` to open switcher after options sheet closes |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 5 | survey_views.py:125-126, 354-355 | Lazy import of `TrainerNotification` inside try blocks | Move to top-level import — no circular dependency risk here |
| 6 | workout_log_screen.dart:453 | Spread operator `...programs.map()` could overflow for many programs | Use ListView.builder instead if >5 programs expected. Currently acceptable. |

## Security Concerns
- None introduced. The `_save_workout_to_daily_log` properly uses ORM (no raw queries). Auth is enforced via `IsAuthenticated` permission class.

## Performance Concerns
- `get_or_create` + `save` is two DB operations but acceptable for this use case.
- `select_related('parent_trainer')` is not used on the user queryset — accessing `user.parent_trainer` will trigger a lazy query. However, this is a single additional query per request, acceptable for a survey submission endpoint.

## Quality Score: 7/10
## Recommendation: REQUEST CHANGES

The dead code (Critical #1) and the merge logic overwriting metadata (Critical #2) must be fixed. The race condition (Major #3) should also be addressed.
