# Pipeline 15 Focus: Offline-First + Performance (Phase 6)

## Priority
Complete Phase 6 items with emphasis on offline workout logging and performance optimization.

## Phase 6 Items
1. Drift (SQLite) local database for offline workout logging
2. Sync queue for uploading logs when connection returns
3. Background health data sync (HealthKit / Health Connect)
4. App performance audit (60fps target, RepaintBoundary audit)

## Context
- Mobile app currently requires network for ALL data operations
- DailyLog.workout_data and DailyLog.nutrition_data are JSON blobs stored on the backend
- Trainee logs workouts via structured UI or AI natural language input
- Workout data persists via PostWorkoutSurveyView -> _save_workout_to_daily_log()
- Nutrition data persists via confirm-and-save endpoint
- Weight check-ins persist via WeightCheckIn model
- No local caching or offline storage exists today
- Flutter app uses Riverpod for state management
- API client is Dio-based (mobile/lib/core/api/api_client.dart)
- All API constants in mobile/lib/core/constants/api_constants.dart
- Router in mobile/lib/core/router/app_router.dart

## What to prioritize
1. **Offline workout logging** is the highest-value item — trainees at the gym often have poor connectivity
2. **Sync queue** is required for offline logging to work
3. **Performance audit** is valuable but lower priority than offline
4. **HealthKit/Health Connect** integration is a nice-to-have but complex — defer if scope is too large

## What NOT to build
- Don't add offline support for trainer/admin features (trainer dashboard, admin dashboard)
- Don't add offline support for web dashboard
- Don't add offline AI natural language parsing (requires network by nature)
- Don't build a full offline-first architecture for every feature — focus on workout and nutrition logging
