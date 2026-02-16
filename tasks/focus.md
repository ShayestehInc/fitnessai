# Pipeline 16 Focus: Health Data Sync + Performance Audit (Phase 6 Completion)

## Priority
Complete remaining Phase 6 items: HealthKit/Health Connect integration, app performance audit, and deferred offline UI polish.

## Phase 6 Remaining Items
1. Background health data sync (HealthKit on iOS / Health Connect on Android)
2. App performance audit (60fps target, RepaintBoundary audit)
3. Deferred offline ACs: merge local pending data into list views (AC-12, AC-16, AC-18), sync badges on cards (AC-36/37/38)

## Context
- Mobile app uses Flutter 3.0+ with Riverpod state management
- Drift (SQLite) local database already exists from Pipeline 15 (offline-first)
- `mobile/lib/core/services/health_service.dart` already exists (placeholder or partial)
- Weight check-ins model exists: `WeightCheckIn` with `weight_kg`, `date`, `notes`
- DailyLog has `workout_data` and `nutrition_data` JSON fields
- The app already tracks workouts, nutrition, and weight manually
- HealthKit/Health Connect can provide: steps, heart rate, active calories, sleep, weight

## What to build
1. **Health data integration**: Read steps, active calories, heart rate, and weight from HealthKit (iOS) / Health Connect (Android). Display on trainee home screen. Auto-import weight to weight check-ins (with dedup).
2. **Performance audit**: Profile the app for jank. Add RepaintBoundary where needed. Audit const constructors. Check for unnecessary rebuilds. Target 60fps on common flows (scrolling lists, workout logging, navigation transitions).
3. **Offline UI polish**: Wire SyncStatusBadge onto workout/nutrition/weight cards. Merge local pending data into home screen recent workouts and nutrition macro totals.

## What NOT to build
- Don't add background sync when app is fully closed (requires platform-specific BGTaskScheduler/WorkManager — too complex for this pipeline)
- Don't write health data back (read-only integration)
- Don't build a full health dashboard — just surface key metrics on the home screen
