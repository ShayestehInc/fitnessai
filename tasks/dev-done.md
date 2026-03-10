# Dev Done: Analytics + Correlations — v6.5 Step 15

## Files Created

- `backend/trainer/services/correlation_analytics_service.py` — Correlation engine: Pearson r, cross-metric correlations, pattern detection, cohort analysis, exercise progressions
- `backend/trainer/correlation_views.py` — 3 API views: CorrelationOverviewView, TraineePatternsView, CohortAnalysisView
- `backend/trainer/tests/test_correlation_analytics.py` — 22 tests (unit + service + API)

## Files Modified

- `backend/trainer/urls.py` — Added 3 routes for correlation analytics endpoints

## Endpoints

- GET /api/trainer/analytics/correlations/ — Cross-metric correlations across all trainees (Pearson r for protein↔volume, calorie↔workout, sleep↔next-day-volume, food↔workout logging)
- GET /api/trainer/analytics/trainee/{id}/patterns/ — Per-trainee insights + exercise progressions + adherence stats
- GET /api/trainer/analytics/cohort/ — High vs low adherence cohort comparison (configurable threshold)

## Key Decisions

- Compute on demand (no batch jobs) per focus.md spec
- Returns frozen dataclasses from service, serialized via `dataclasses.asdict()` in views
- Pearson r requires minimum 3 data points (5 for sleep correlation)
- Days parameter clamped to 7-365 range
- Row-level security: trainee patterns endpoint validates trainee belongs to requesting trainer
- Fixed field name mismatch: model uses `calories_consumed` not `calories`
