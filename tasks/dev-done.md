# Dev Done: Trainer-Selectable Workout Layouts

## Date: 2026-02-14

## Files Changed

### Backend (new)
- `backend/trainer/models.py` — Added `WorkoutLayoutConfig` model (OneToOne to User, layout_type choices, config_options JSONField, configured_by FK)
- `backend/trainer/serializers.py` — Added `WorkoutLayoutConfigSerializer` with layout_type validation
- `backend/trainer/views.py` — Added `TraineeLayoutConfigView` (GET/PUT) with get_or_create, row-level security
- `backend/trainer/urls.py` — Added `trainees/<int:trainee_id>/layout-config/` endpoint
- `backend/trainer/migrations/0003_add_workout_layout_config.py` — CreateModel migration
- `backend/workouts/survey_views.py` — Added `MyLayoutConfigView` (GET for trainee)
- `backend/workouts/urls.py` — Added `my-layout/` endpoint

### Mobile (new)
- `mobile/lib/features/workout_log/data/models/layout_config_model.dart` — Simple model with layoutType, configOptions, defaultConfig
- `mobile/lib/features/workout_log/presentation/widgets/classic_workout_layout.dart` — All-exercises scrollable list with full sets tables
- `mobile/lib/features/workout_log/presentation/widgets/minimal_workout_layout.dart` — Collapsible compact list with circular progress

### Mobile (modified)
- `mobile/lib/core/constants/api_constants.dart` — Added `myWorkoutLayout` and `traineeLayoutConfig(id)` endpoints
- `mobile/lib/features/workout_log/data/repositories/workout_repository.dart` — Added `getMyLayout()` method
- `mobile/lib/features/workout_log/presentation/screens/active_workout_screen.dart` — Added `_layoutType` state, `_fetchLayoutConfig()` in initState, switch statement in `_buildExerciseContent`
- `mobile/lib/features/trainer/data/repositories/trainer_repository.dart` — Added `getTraineeLayoutConfig()` and `updateTraineeLayoutConfig()` methods
- `mobile/lib/features/trainer/presentation/screens/trainee_detail_screen.dart` — Added `_WorkoutLayoutPicker` and `_LayoutOption` widgets in Overview tab

## Key Decisions
1. **Layout is per-trainee (OneToOne), not per-program** — a trainee has one layout regardless of which program they're on
2. **Default is 'classic'** — when no config row exists, API returns 'classic' without creating a row (lazy creation on trainer GET)
3. **Layout fetched at workout start** — `_fetchLayoutConfig()` in initState, cached in `_layoutType`. Mid-workout changes by trainer take effect on next workout.
4. **Card layout = existing behavior** — no new widget needed for Card, the existing `_ExerciseCard` PageView remains inline
5. **All three layouts share same data model** — `ExerciseLogState` / `SetLogState` / callbacks are identical

## How to Manually Test
1. **Backend**: `cd backend && ./venv/bin/python manage.py test` (existing tests pass)
2. **Trainer side**: Open trainee detail → Overview tab → "Workout Display" section → tap Classic/Card/Minimal
3. **Trainee side**: Start a workout → observe the layout matches what trainer set
4. **Default**: New trainee with no config → sees Classic layout
5. **API**: `GET /api/workouts/my-layout/` returns `{"layout_type": "classic", "config_options": {}}`

## Review Fixes (Round 1)

### Backend fixes
- **CRITICAL**: Added `IsTrainee` permission to `MyLayoutConfigView` — trainee endpoint now requires trainee role, not just authentication
- **MAJOR**: Added `select_related('configured_by')` to `get_or_create` in `TraineeLayoutConfigView` — prevents N+1 query for serializer's `configured_by_email`
- **MAJOR**: Removed redundant `validate_layout_type` from `WorkoutLayoutConfigSerializer` — Django's `choices` already validates
- **MINOR**: Moved `Http404` import from inline to top-level in `trainer/views.py`

### Mobile fixes
- **MAJOR**: Fixed race condition in `_updateLayout` — now saves `previousLayout` before optimistic update and reverts to it on failure (instead of re-fetching from server)
- **MAJOR**: Added bounds checking in `ClassicWorkoutLayout.didUpdateWidget` — handles case where exercise list grows (adds empty controller lists)
- **MAJOR**: Added same bounds checking in `MinimalWorkoutLayout.didUpdateWidget`
- **MINOR**: Removed unused import `api_client.dart` from `trainee_detail_screen.dart`

## Audit Fixes

### Backend fixes
- **SECURITY**: Added `validate_config_options()` to `WorkoutLayoutConfigSerializer` — validates config_options is a dict and rejects payloads > 2048 chars (prevents DoS via oversized JSON)

### Mobile fixes
- **UX/HACKER**: Added error state with retry button to `_WorkoutLayoutPicker._fetchCurrentLayout()` — was silently falling back to 'classic' on API failure, now shows error icon + "Retry" button
- **UX/HACKER**: Added `is Map<String, dynamic>` type guard on `result['data']` cast in `_fetchCurrentLayout()` — prevents type cast errors on unexpected API response
- **VISUAL**: Fixed border flicker in `_LayoutOption` — compensated padding (12→11, 8→7) when border width increases from 1→2px on selection
- **VISUAL**: Standardized badge sizing in `MinimalWorkoutLayout` from 24x24 to 28x28 to match `ClassicWorkoutLayout`
