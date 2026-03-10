# Ship Decision: Analytics + Correlations (v6.5 Step 15)

## Verdict: SHIP

## Confidence: HIGH

## Quality Score: 8/10

## Summary

Correlation analytics engine with Pearson r computation, cross-metric correlations (protein↔strength, sleep↔volume, calorie↔workout, food↔workout logging), per-trainee pattern detection (high/low adherence, plateaus, overtraining risk, sleep decline), cohort comparison, and exercise progression tracking. 3 API endpoints with proper row-level security.

## What Was Built

- CorrelationAnalyticsService with 3 entry points (overview, trainee patterns, cohort)
- Pearson correlation computation with interpretation
- 5 insight types: high_adherence, low_protein_adherence, volume_plateau, overtraining_risk, sleep_declining
- Cohort comparison across 3 metrics: weekly volume, protein adherence, workout consistency
- Exercise progression tracking with e1RM history analysis (gaining/plateau/declining)
- 3 API endpoints: GET /analytics/correlations/, GET /analytics/trainee/{id}/patterns/, GET /analytics/cohort/
- 22 tests (unit + service + API)
- N+1 query fix: batched session counts for exercise progressions
