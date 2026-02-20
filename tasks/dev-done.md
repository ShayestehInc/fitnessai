# Dev Done: Advanced Trainer Analytics — Calorie Goal + Adherence Trends (Pipeline 26)

## Date
2026-02-20

## Files Changed

### Backend
- `backend/trainer/views.py` — Added `calorie_goal_rate` to `AdherenceAnalyticsView` response; new `AdherenceTrendView` class for daily trend data
- `backend/trainer/urls.py` — Registered `analytics/adherence/trends/` endpoint; imported `AdherenceTrendView`

### Frontend
- `web/src/types/analytics.ts` — Added `calorie_goal_rate` to `AdherenceAnalytics`, new `AdherenceTrendPoint` and `AdherenceTrends` types
- `web/src/hooks/use-analytics.ts` — New `useAdherenceTrends(days)` hook
- `web/src/lib/constants.ts` — New `ANALYTICS_ADHERENCE_TRENDS` URL constant
- `web/src/lib/chart-utils.ts` — Added `calorie` color to `CHART_COLORS`
- `web/src/components/analytics/adherence-trend-chart.tsx` — **NEW** — Recharts AreaChart component for daily adherence trends (4 lines: food, workout, protein, calorie)
- `web/src/components/analytics/adherence-section.tsx` — Added 4th stat card (Calorie Goal Hit), embedded `AdherenceTrendChart`, updated grid from `sm:grid-cols-3` to `sm:grid-cols-2 lg:grid-cols-4`, updated skeleton to 4 cards + 2 chart skeletons

## Key Decisions
1. Used `AreaChart` (not `LineChart`) for the trend chart — filled areas provide better visual weight and make it easier to distinguish overlapping metrics
2. Chart renders one Area per metric with `fillOpacity={0.1}` — keeps the fill subtle so lines remain readable
3. `AdherenceTrendView` aggregates per-day using a single annotated query with `values('date')` — O(days) response, not O(trainees*days)
4. Both the trend chart and existing stat cards/bar chart share the same period selector state — switching periods updates all three simultaneously
5. Used `CartesianGrid` with `vertical={false}` for cleaner horizontal reference lines
6. Custom `CustomTooltip` component shows all 4 rates + trainee count for the hovered day

## Deviations from Ticket
- None. All acceptance criteria addressed.

## How to Test
1. Start backend: `docker-compose up -d` or `python manage.py runserver`
2. Log in as a trainer with active trainees who have `TraineeActivitySummary` records
3. Navigate to `/analytics`
4. Verify: 4 stat cards (Food, Workouts, Protein, Calorie) in a responsive grid
5. Verify: Area chart below stat cards showing 4 trend lines
6. Use period selector (7d/14d/30d) — all sections update together
7. Hover over chart points — tooltip shows date, all 4 rates, trainee count
8. Check empty state: log in as a trainer with no trainees → see "No active trainees" empty state
9. Check dark mode: colors should use CSS variables, no hardcoded colors
