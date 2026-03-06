# Code Review: Achievement Toast on New Badge

## Review Date: 2026-03-05

## Files Reviewed
- backend/workouts/views.py
- mobile/lib/shared/widgets/achievement_celebration_overlay.dart
- mobile/lib/core/services/achievement_toast_service.dart
- mobile/lib/core/router/app_router.dart
- mobile/lib/core/database/offline_save_result.dart
- mobile/lib/core/database/offline_nutrition_repository.dart
- mobile/lib/features/workout_log/data/repositories/workout_repository.dart
- mobile/lib/features/nutrition/data/repositories/nutrition_repository.dart
- mobile/lib/features/logging/presentation/providers/logging_provider.dart
- mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart
- mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart
- mobile/lib/features/logging/presentation/screens/ai_command_center_screen.dart
- mobile/lib/features/nutrition/presentation/screens/add_food_screen.dart
- mobile/lib/features/barcode_scanner/presentation/screens/food_result_screen.dart

## Critical Issues (must fix before merge)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 1 | achievement_celebration_overlay.dart:153-161 | **Completer never completes if widget disposed during reverse animation.** If the user navigates away while a toast is showing, `mounted` becomes false after `_entranceController.reverse()`, so `onDismissed` is never called. The Completer never completes, and `_processQueue` in the toast service hangs forever. `_isShowing` stays `true`, blocking all future toasts for the rest of the app session. | In `dispose()`, call `onDismissed()` if not already dismissed. Also ensure OverlayEntry is safely removed. |

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 2 | views.py:1509 | `response_data = serializer.data` — not wrapped in `dict()`. While DRF's ReturnDict is mutable, the nutrition endpoint (line 798) correctly wraps with `dict()`. Inconsistent and fragile. | Change to `response_data = dict(serializer.data)` for consistency. |
| 3 | Multiple files | `catch (_)` blocks silently swallow exceptions in `_showAchievementToasts` helpers. Violates project error-handling rule: "NO exception silencing". | Replace `catch (_)` with `catch (e)` and use `debugPrint` or a logging framework. |
| 4 | Duplicated _showAchievementToasts helper | The same 10-line helper method is copy-pasted in 4+ screen files. Should be extracted to a shared utility. | Extract to a top-level function in achievement_toast_service.dart. |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 5 | achievement_toast_service.dart | No mechanism to cancel queued toasts if app navigates to a completely different section. | Add a `cancelAll()` method for future use. |

## Security Concerns
None.

## Performance Concerns
- Backdrop blur is expensive on low-end devices. Acceptable for a brief overlay.

## Quality Score: 7/10
## Recommendation: REQUEST CHANGES
