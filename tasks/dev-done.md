# Dev Done: Full Audit UI + Exports — v6.5 Step 16

## Files Created

- `backend/trainer/services/audit_service.py` — Audit trail summary + timeline (decision counts, grouping, human-readable descriptions)
- `backend/trainer/services/audit_export_service.py` — CSV exports: decision logs, trainee workout history, nutrition history, progress (weight + e1RM)
- `backend/trainer/audit_views.py` — 6 API views: AuditSummaryView, AuditTimelineView, DecisionLogExportView, TraineeWorkoutExportView, TraineeNutritionExportView, TraineeProgressExportView
- `backend/trainer/tests/test_audit_exports.py` — 24 tests (service + API)

## Files Modified

- `backend/trainer/urls.py` — Added 6 routes for audit + export endpoints

## Endpoints

- GET /api/trainer/audit/summary/ — Decision counts by type/actor, recent 7d count, reverted count
- GET /api/trainer/audit/timeline/ — Paginated timeline with human-readable descriptions
- GET /api/trainer/export/decision-logs/ — CSV export of decision log entries
- GET /api/trainer/export/trainee/{id}/workout-history/ — CSV of LiftSetLog entries (sets, reps, weight, RPE)
- GET /api/trainer/export/trainee/{id}/nutrition-history/ — CSV of TraineeActivitySummary (calories, macros, adherence)
- GET /api/trainer/export/trainee/{id}/progress/ — CSV of weight check-ins + e1RM history

## Key Decisions

- Reuses CsvExportResult dataclass and CSV sanitization from existing export_service.py
- Row-level security: all endpoints scoped to trainer + their trainees
- Human-readable timeline descriptions generated from decision context
- All exports have CSV injection protection via \_sanitize_csv_value
- Pagination for timeline via limit/offset params (clamped to 1-100)
