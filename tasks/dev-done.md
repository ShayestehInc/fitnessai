# Dev Done: Achievement Toast on New Badge

## Summary
Wired the existing `new_achievements` backend data through all mobile layers and built an animated celebration overlay that displays when users earn badges.

## Files Changed

### Backend
| File | Change |
|------|--------|
| `backend/workouts/views.py` | WeightCheckInViewSet.create now calls `check_and_award_achievements(user, 'weight_checkin')` and returns `new_achievements` in the 201 response. Nutrition `confirm_and_save` now calls `check_and_award_achievements(user, 'nutrition_logged')` and returns `new_achievements`. |

### Mobile — New Files
| File | Purpose |
|------|---------|
| `mobile/lib/shared/widgets/achievement_celebration_overlay.dart` | Animated overlay widget with elastic scale entrance, pulsing gold glow, backdrop blur, tap/swipe dismiss, auto-dismiss after 4s, accessibility semantics. |
| `mobile/lib/core/services/achievement_toast_service.dart` | Singleton queue manager. Uses `rootNavigatorKey` to find root Overlay. Sequential display with 500ms gap between achievements. |

### Mobile — Modified Files
| File | Change |
|------|--------|
| `mobile/lib/core/router/app_router.dart` | Made `_rootNavigatorKey` public as `rootNavigatorKey` so the toast service can access the root Overlay. |
| `mobile/lib/core/database/offline_save_result.dart` | Added `newAchievements` getter to extract `new_achievements` from the data map. |
| `mobile/lib/core/database/offline_nutrition_repository.dart` | Forwards `new_achievements` from online API response through `OfflineSaveResult.onlineSuccess(data:)`. |
| `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` | `submitPostWorkoutSurvey` now forwards `new_achievements` from API response. |
| `mobile/lib/features/nutrition/data/repositories/nutrition_repository.dart` | `createWeightCheckIn` now forwards `new_achievements` from API response. |
| `mobile/lib/features/logging/presentation/providers/logging_provider.dart` | Added `newAchievements` field to `LoggingState` and `copyWith`. Both `confirmAndSave` and `saveManualFoodEntry` populate it from offline/online results. |
| `mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart` | Calls `_showAchievementToasts` after post-workout survey submission. |
| `mobile/lib/features/nutrition/presentation/screens/weight_checkin_screen.dart` | Calls `_showAchievementToasts` after successful weight check-in save. |
| `mobile/lib/features/logging/presentation/screens/ai_command_center_screen.dart` | Calls `_showAchievementToasts` after successful AI command center save. |
| `mobile/lib/features/nutrition/presentation/screens/add_food_screen.dart` | Calls `_showAchievementToastsFromLogging` after manual save, AI confirm, and search food add. |
| `mobile/lib/features/barcode_scanner/presentation/screens/food_result_screen.dart` | Inline achievement toast logic after successful barcode food save. |

## Key Decisions
1. **Singleton toast service** — uses root navigator key from go_router to access the topmost Overlay, making it work from any screen without requiring BuildContext.
2. **Queue-based sequential display** — multiple achievements show one after another with 500ms gap, not stacked simultaneously.
3. **Data forwarding pattern** — `new_achievements` flows: API response -> repository -> OfflineSaveResult/Map -> provider state -> UI helper method -> AchievementToastService.
4. **Gold accent (#FFD700)** with dark background overlay and backdrop blur for premium celebration feel.
5. **4-second auto-dismiss** with tap-to-dismiss and swipe-up-to-dismiss as alternatives.

## Deviations from Ticket
- None. All acceptance criteria addressed.

## How to Manually Test
1. **Workout flow**: Complete a workout and submit the post-workout survey. If an achievement is earned (e.g., first workout), the overlay should appear.
2. **Weight check-in**: Log a weight check-in. If a weight streak achievement triggers, the overlay appears.
3. **Nutrition — AI Command Center**: Use natural language to log food. Achievement overlay appears if earned.
4. **Nutrition — Manual Entry**: Add food manually from the Add Food screen. Achievement overlay appears if earned.
5. **Nutrition — Barcode**: Scan a barcode and add the food. Achievement overlay appears if earned.
6. **Multiple achievements**: If multiple achievements are earned at once, they should display sequentially with a brief gap.
7. **Dismiss**: Tap or swipe up on the overlay to dismiss early.
8. **Offline**: Save nutrition while offline — achievements should NOT show (they only come from online responses).
