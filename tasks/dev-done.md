# Dev Done: Import Pipeline (Draft/Confirm) — v6.5 Step 12

## Files Created

- `backend/workouts/services/program_import_service.py` — Full import service: parse CSV, validate, create draft, confirm (atomic plan creation), reject, get, list
- `backend/workouts/import_views.py` — 4 API views: upload, list, detail (GET+DELETE), confirm
- `backend/workouts/migrations/0029_program_import_draft.py` — Migration for ProgramImportDraft
- `backend/workouts/tests/test_program_import.py` — 24 tests (10 parse, 4 confirm, 5 draft mgmt, 9 API)

## Files Modified

- `backend/workouts/models.py` — Added `ProgramImportDraft` model (UUID PK, status lifecycle, raw_csv, parsed_data, validation fields, training_plan FK)
- `backend/workouts/urls.py` — Added 4 routes under /program-imports/

## Key Decisions

- Used path-based views (not ViewSet) since the import workflow is action-oriented, not CRUD
- Inline serializers in views file — small, tightly coupled to these specific views
- Draft always created even with errors (allows trainer to see what went wrong)
- CSV exercises matched case-insensitively
- Confirm atomically creates TrainingPlan + PlanWeeks + PlanSessions + PlanSlots + DecisionLog + UndoSnapshot

## Endpoints

- POST /api/workouts/program-imports/upload/ — Upload CSV, create draft
- GET /api/workouts/program-imports/ — List recent drafts
- GET /api/workouts/program-imports/{draft_id}/ — Get draft details
- POST /api/workouts/program-imports/{draft_id}/confirm/ — Execute import
- DELETE /api/workouts/program-imports/{draft_id}/ — Reject/discard draft
