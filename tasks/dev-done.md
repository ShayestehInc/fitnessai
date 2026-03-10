# Dev Done: Auto-tagging Pipeline — v6.5 Step 13

## Files Created

- `backend/workouts/services/auto_tagging_service.py` — Full auto-tagging service: request, retry, apply, reject, edit, history
- `backend/workouts/auto_tag_views.py` — 7 API views for auto-tag workflow
- `backend/workouts/migrations/0030_exercise_tag_draft.py` — ExerciseTagDraft model
- `backend/workouts/migrations/0031_alter_undosnapshot_scope.py` — Added 'plan' scope
- `backend/workouts/tests/test_auto_tagging.py` — 22 tests (mocked AI)

## Files Modified

- `backend/workouts/models.py` — Added ExerciseTagDraft model, added PLAN scope to UndoSnapshot
- `backend/workouts/urls.py` — Added 6 routes for auto-tag endpoints
- `backend/workouts/ai_prompts.py` — Added `get_exercise_auto_tag_prompt()` with full v6.5 taxonomy
- `backend/workouts/services/program_import_service.py` — Fixed UndoSnapshot: removed invalid `decision_log` kwarg, used PLAN scope

## Key Decisions

- AI response validated against Exercise TextChoices enums — invalid values filtered, MCM normalized to sum=1.0
- Draft/edit/retry pattern: trainers can edit AI suggestions before applying
- Retry rejects old draft and creates new one with incremented retry_count
- Apply increments Exercise.version + creates DecisionLog + UndoSnapshot
- OpenAI gpt-4o with JSON response format + temperature 0.3 for determinism
- All tests mock `_call_ai_for_tags` to avoid API dependency

## Endpoints

- POST /api/workouts/exercises/{id}/auto-tag/ — Request AI tagging
- GET /api/workouts/exercises/{id}/auto-tag-draft/ — Get current draft
- PATCH /api/workouts/exercises/{id}/auto-tag-draft/ — Edit draft
- POST /api/workouts/exercises/{id}/auto-tag-draft/apply/ — Apply tags to exercise
- POST /api/workouts/exercises/{id}/auto-tag-draft/reject/ — Reject draft
- POST /api/workouts/exercises/{id}/auto-tag-draft/retry/ — Retry AI
- GET /api/workouts/exercises/{id}/tag-history/ — Version history
