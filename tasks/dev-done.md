# Dev Done: ExerciseCard Rich Tagging + DecisionLog + UndoSnapshot

## Date: 2026-03-09

## Files Changed

### Modified
- `backend/config/settings.py` — Added `django.contrib.postgres` to INSTALLED_APPS (required for ArrayField)
- `backend/workouts/models.py` — Added 16 new fields to Exercise model + 2 new models (DecisionLog, UndoSnapshot)
- `backend/workouts/serializers.py` — Updated ExerciseSerializer with new fields + validation; added DecisionLogSerializer and UndoSnapshotSerializer
- `backend/workouts/views.py` — Added v6.5 tag-based filters to ExerciseViewSet; added DecisionLogViewSet with undo action
- `backend/workouts/urls.py` — Registered DecisionLogViewSet at `/decision-logs/`

### Created
- `backend/workouts/services/decision_log_service.py` — Service with `log_decision()` and `undo_decision()` methods
- `backend/workouts/management/commands/backfill_exercise_tags.py` — Management command to backfill existing exercises
- `backend/workouts/migrations/0018_v65_exercise_tags_decision_log_undo_snapshot.py` — Migration

## Key Decisions
1. Added fields to existing Exercise model (not separate ExerciseCard model)
2. All new fields optional — zero impact on existing exercises
3. PostgreSQL ArrayField for tags — enables __overlap and __contains lookups
4. DecisionLog uses JSONField for flexible context storage
5. UndoSnapshot stores full state (not diffs) for reliability
6. DecisionLogService is sole entry point for creating log entries
7. Undo creates a new DecisionLog entry (the undo itself is logged)
8. Kept legacy `muscle_group` field for backwards compatibility

## New API Endpoints
- `GET /api/workouts/decision-logs/` — List (filtered by role)
- `GET /api/workouts/decision-logs/{id}/` — Detail
- `POST /api/workouts/decision-logs/{id}/undo/` — Revert a decision
- Exercise filters: `?pattern_tags=`, `?stance=`, `?plane=`, `?rom_bias=`, `?primary_muscle_group=`, `?equipment_required=`

## How to Test
1. `python manage.py migrate`
2. `GET /api/workouts/exercises/` — verify existing exercises still load
3. `POST /api/workouts/exercises/` with pattern_tags, stance, etc.
4. `GET /api/workouts/exercises/?pattern_tags=knee_dominant`
5. `python manage.py backfill_exercise_tags --dry-run`
