# Changelog

All notable changes to the FitnessAI platform are documented in this file.

---

## [2026-02-14] — Trainer-Selectable Workout Layouts

### Added
- **WorkoutLayoutConfig model** — OneToOne per trainee with layout_type (classic/card/minimal), config_options JSONField, and configured_by FK for audit trail.
- **Trainer API endpoints** — `GET/PUT /api/trainer/trainees/<id>/layout-config/` with auto-create default and row-level security (parent_trainer check).
- **Trainee API endpoint** — `GET /api/workouts/my-layout/` with IsTrainee permission and graceful fallback to 'classic' when no config exists.
- **ClassicWorkoutLayout widget** — All exercises in scrollable ListView with full sets tables, previous weight/reps, add set, and complete buttons.
- **MinimalWorkoutLayout widget** — Compact collapsible tiles with circular progress indicators, expand/collapse, and quick-complete.
- **Workout Display section** in trainer's trainee detail Overview tab — segmented control with Classic/Card/Minimal options, optimistic update with rollback on failure.
- Error state with retry button on layout picker when API fetch fails.
- `validate_config_options()` on serializer — rejects non-dict and oversized (>2048 char) payloads.
- Database migration: `trainer/migrations/0003_add_workout_layout_config.py`.

### Changed
- `active_workout_screen.dart` — Added `_layoutType` state variable and `_buildExerciseContent` switch statement to render Classic/Card/Minimal based on API config.
- Card layout uses existing `_ExerciseCard` PageView (no new widget needed).

### Quality
- Code review: 9/10 backend, 8.5/10 mobile — APPROVE (Round 2)
- QA: 13/13 acceptance criteria PASS, Confidence HIGH
- Security audit: 9/10 — PASS
- Architecture review: 8.6/10 — APPROVE
- UX audit: 7.5/10 — Fixes applied
- Hacker report: 7.5/10 — 4 issues fixed
- Overall quality: 8.5/10 — SHIP

---

## [2026-02-13] — Fix All 5 Trainee-Side Workout Bugs

### Fixed
- **CRITICAL — Workout data now persists to database.** `PostWorkoutSurveyView` writes to `DailyLog.workout_data` via `_save_workout_to_daily_log()` with `transaction.atomic()` and `get_or_create`. Multiple workouts per day merge into a `sessions` list while preserving a flat `exercises` list for backward compatibility.
- **HIGH — Trainer notifications now fire correctly.** Changed `getattr(user, 'trainer', None)` to `user.parent_trainer` in both `ReadinessSurveyView` and `PostWorkoutSurveyView`. Created missing `TrainerNotification` database migration.
- **HIGH — Real program schedules shown instead of sample data.** Removed `_generateSampleWeeks()` and `_getSampleExercises()` fallbacks from workout provider. Proper empty states for: no programs assigned, empty schedule, no workouts this week.
- **MEDIUM — Debug print statements removed.** All 15+ `print('[WorkoutRepository]...')` statements removed from `workout_repository.dart`.
- **MEDIUM — Program switcher implemented.** Bottom sheet with full program list, active program indicator, snackbar confirmation, and `WorkoutNotifier.switchProgram()` for state update.

### Added
- Comprehensive Django test suite: 10 tests covering workout persistence, merge logic, trainer notifications, edge cases, and auth.
- Error state UI with retry button on workout log screen.
- Accessibility tooltips on icon buttons in workout log header.
- `TrainerNotification` database migration (`trainer/migrations/0002_add_trainer_notification.py`).

### Removed
- ~130 lines of hardcoded sample workout data (`_generateSampleWeeks`, `_getSampleExercises`).
- 2 stale TODO comments in `active_workout_screen.dart` that falsely suggested code was unimplemented.

### Changed
- `DailyLog.workout_data` JSON schema extended with `sessions` array to support multiple workouts per day (backward compatible).

### Quality
- Security audit: 9/10 — PASS
- Architecture review: 8/10 — APPROVE
- UX audit: 7/10 — Acceptable
- Overall quality: 8/10 — SHIP
