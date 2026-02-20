# Code Review: Advanced Trainer Analytics — Calorie Goal + Adherence Trends (Pipeline 26)

## Review Date
2026-02-20

## Files Reviewed
- `backend/trainer/views.py` (AdherenceAnalyticsView changes + new AdherenceTrendView)
- `backend/trainer/urls.py`
- `web/src/types/analytics.ts`
- `web/src/hooks/use-analytics.ts`
- `web/src/lib/constants.ts`
- `web/src/lib/chart-utils.ts`
- `web/src/components/analytics/adherence-trend-chart.tsx`
- `web/src/components/analytics/adherence-section.tsx`

## Critical Issues (must fix before merge)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| — | — | None found | — |

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix | Status |
|---|-----------|-------|---------------|--------|
| 1 | adherence-trend-chart.tsx:162-167 | **Compounding opacity**: AdherenceSection wraps everything in `opacity-50` when `isFetching`, and the trend chart applies its own `opacity-50` — resulting in 0.25 opacity for the trend chart while other elements are at 0.5 | Remove the trend chart's own opacity wrapper since it's rendered inside the section's opacity container | FIXED |

## Minor Issues (nice to fix)
| # | File:Line | Issue | Suggested Fix | Status |
|---|-----------|-------|---------------|--------|
| 1 | adherence-trend-chart.tsx:146 | Unused `label` field — `chartData` maps over trends adding a `label` property that's never used by the chart (XAxis uses `tickFormatter`) | Remove the map, pass `trends` directly | FIXED |
| 2 | views.py:848-851 + 918-921 | Duplicated days parsing logic in two views — identical `try/except` blocks | Extract to `_parse_days_param()` helper | FIXED |

## Security Concerns
- Both views properly use `IsAuthenticated, IsTrainer` permissions
- Trainee data is scoped to `parent_trainer=user` — no IDOR risk
- No secrets or sensitive data in responses

## Performance Concerns
- AdherenceTrendView uses a single annotated query (`.values('date').annotate(...)`) — no N+1
- Response size is O(days), not O(trainees × days) — efficient
- Two parallel React Query requests fire on the analytics page (adherence stats + trends) — both cached with 5-min staleTime

## Quality Score: 9/10
## Recommendation: APPROVE
