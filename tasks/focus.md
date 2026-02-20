# Pipeline 26 Focus: Advanced Trainer Analytics — Calorie Goal + Adherence Trends

## Priority
Expand the trainer analytics page with calorie goal tracking and daily adherence trend charts. This directly addresses the "Advanced analytics and reporting" Phase 11 item.

## Why This Feature
1. **Explicitly listed in Phase 11** — "Advanced analytics and reporting" is one of only 6 remaining Phase 11 items.
2. **Data already exists but is unused** — `TraineeActivitySummary` tracks `hit_calorie_goal` daily but the analytics page ignores it entirely. Free data is being wasted.
3. **Trainers can't see trends** — The current analytics page shows only a single aggregate percentage per metric. A trainer can't tell if adherence is improving, declining, or volatile over time.
4. **Low risk, high impact** — Uses existing model, existing Recharts infrastructure, existing period selector pattern. No new models or migrations needed.
5. **Actionable for trainers** — Seeing a downward trend lets a trainer intervene early; seeing a weekend dip lets them adjust programming.

## Scope
- Backend: Add `calorie_goal_rate` to `AdherenceAnalyticsView` response
- Backend: New `AdherenceTrendView` endpoint returning daily adherence rates for the selected period
- Web: 4th stat card for Calorie Goal Hit %
- Web: New `AdherenceTrendChart` line/area chart showing daily food/workout/protein/calorie rates over the period
- Web: Wire trend chart into analytics page between stat cards and per-trainee bar chart

## What NOT to build
- Per-trainee drill-down analytics (defer)
- Nutrition macro trends (calories/protein/carbs over time per trainee — defer)
- Export/CSV/PDF for analytics (defer)
- Custom date range picker beyond 7/14/30d (defer)
- Streak tracking / leaderboard (defer)
