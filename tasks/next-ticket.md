# Feature: Advanced Trainer Analytics — Calorie Goal Tracking + Adherence Trends

## Priority
High

## User Story
As a **trainer**, I want to **see my roster's calorie goal hit rate and daily adherence trends over time** so that I can **identify declining engagement early and adjust my coaching strategy before trainees fall off**.

## Acceptance Criteria

### Backend — Calorie Goal Rate
- [ ] AC-1: `GET /api/trainer/analytics/adherence/?days=N` response now includes `calorie_goal_rate` (float, 0-100) alongside the existing `food_logged_rate`, `workout_logged_rate`, `protein_goal_rate`
- [ ] AC-2: `calorie_goal_rate` is calculated as `(days with hit_calorie_goal=True / total_tracking_days) * 100`, same formula as `protein_goal_rate`
- [ ] AC-3: When `total_tracking_days` is 0, `calorie_goal_rate` returns 0 (not NaN/null)

### Backend — Adherence Trend Endpoint
- [ ] AC-4: New endpoint `GET /api/trainer/analytics/adherence/trends/?days=N` returns daily adherence rates for the selected period
- [ ] AC-5: Response shape: `{ period_days: number, trends: Array<{ date: "YYYY-MM-DD", food_logged_rate: float, workout_logged_rate: float, protein_goal_rate: float, calorie_goal_rate: float, trainee_count: int }> }`
- [ ] AC-6: Each day's rates are calculated as `(trainees who hit metric / total active trainees with a summary that day) * 100`
- [ ] AC-7: Days with 0 trainees tracked return all rates as 0 with `trainee_count: 0`
- [ ] AC-8: Days are sorted ascending by date
- [ ] AC-9: The `days` param is clamped to 1-365, defaults to 30 (same validation as existing adherence endpoint)
- [ ] AC-10: Endpoint requires `IsAuthenticated` + `IsTrainer` permissions
- [ ] AC-11: Only includes trainees belonging to the requesting trainer (row-level security)

### Web — 4th Stat Card
- [ ] AC-12: Adherence section shows 4 stat cards in a 2x2 grid on mobile, 4-column on desktop: Food Logged, Workouts Logged, Protein Goal Hit, **Calorie Goal Hit**
- [ ] AC-13: Calorie Goal Hit card uses the `Flame` icon from lucide-react
- [ ] AC-14: Same color-coded indicator logic (green ≥80%, amber 50-79%, red <50%)
- [ ] AC-15: Skeleton state shows 4 cards instead of 3

### Web — Adherence Trend Chart
- [ ] AC-16: New `AdherenceTrendChart` component rendering a Recharts `AreaChart` with 4 trend lines (food, workout, protein, calorie)
- [ ] AC-17: X-axis shows dates (formatted as "Mon DD" or "DD" depending on period length)
- [ ] AC-18: Y-axis shows percentage 0-100%
- [ ] AC-19: Each metric is a distinct color matching the stat card icon colors (or chart CSS variables)
- [ ] AC-20: Tooltips on hover show exact date and all 4 rates + trainee count for that day
- [ ] AC-21: Chart is placed between the stat cards and the per-trainee bar chart
- [ ] AC-22: Loading state: skeleton rectangle placeholder matching chart height
- [ ] AC-23: Empty state: "No trend data yet" with muted description when no data points exist
- [ ] AC-24: Chart has `role="img"` and `aria-label` for screen readers
- [ ] AC-25: A legend below the chart shows each metric's color and name, matching Recharts `<Legend>` or a custom legend
- [ ] AC-26: The chart respects the period selector (7d/14d/30d) already on the page — shares the same `days` state
- [ ] AC-27: Dark mode support via CSS variables (no hardcoded colors)

### Web — Hook & Types
- [ ] AC-28: New `useAdherenceTrends(days)` hook in `use-analytics.ts` calling the trend endpoint
- [ ] AC-29: New TypeScript types `AdherenceTrendPoint` and `AdherenceTrends` in `analytics.ts`
- [ ] AC-30: Hook uses 5-minute `staleTime` consistent with existing analytics hooks

## Edge Cases
1. **Zero trainees** — Trainer has no active trainees. Trend chart shows empty state, stat cards show 0.0% with red indicator.
2. **One day of data** — Only today has summary records. Chart renders a single point (area chart degrades gracefully to a dot).
3. **Partial days** — Some days have summaries for only some trainees (e.g., new trainee joined mid-period). Rates are calculated per-day based on trainees who have records that day.
4. **100% adherence** — All metrics at 100%. Y-axis should auto-scale to show 100% at top.
5. **Rapid period switching** — Switching 7d→30d→14d quickly. React Query cache handles this; stale data should not flash due to `staleTime`.
6. **Very large roster** — 50+ trainees. The trend endpoint aggregates per-day, so response size is O(days) not O(trainees*days).
7. **Weekend dips** — Adherence naturally drops on weekends. Chart should clearly show day-level granularity to reveal patterns.
8. **No calorie goals set** — If no trainees have calorie goals, `hit_calorie_goal` is always False. Calorie goal rate will be 0% — this is correct and expected, not an error.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Adherence API fails | ErrorState with retry button | `refetch()` on retry click |
| Trend API fails | Trend chart area shows error inline | Separate `useAdherenceTrends` error handling |
| No trainees | EmptyState with "Invite Trainee" CTA | Existing empty state behavior |
| No data for period | Chart empty state "No trend data yet" | Trend array is empty |

## UX Requirements
- **Loading state:** 4 skeleton stat cards + skeleton chart area + skeleton per-trainee bar chart
- **Empty state:** Trend chart shows "No trend data yet" centered in card area
- **Error state:** ErrorState component with retry, scoped to the failing section
- **Period selector:** Shared between stat cards, trend chart, and per-trainee chart (single `days` state)
- **Mobile behavior:** Stat cards in 2x2 grid; chart uses `ResponsiveContainer` for fluid width; min-height 200px
- **Dark mode:** All components use CSS variables from theme
- **Transition:** `opacity-50` during refetch (existing pattern), no skeleton replacement

## Technical Approach

### Backend
- **Modify:** `backend/trainer/views.py` — `AdherenceAnalyticsView.get()` — add `calorie_goal_rate` to response (1 new count query + 1 line in response dict)
- **New:** `backend/trainer/views.py` — `AdherenceTrendView` class (APIView) — aggregates `TraineeActivitySummary` per day using `.values('date').annotate(...)` with `Count` + `Case/When` for each metric
- **Modify:** `backend/trainer/urls.py` — register `analytics/adherence/trends/` path

### Web
- **New file:** `web/src/components/analytics/adherence-trend-chart.tsx` — Recharts AreaChart component
- **Modify:** `web/src/components/analytics/adherence-section.tsx` — add 4th stat card, embed trend chart, adjust grid from `sm:grid-cols-3` to `sm:grid-cols-2 lg:grid-cols-4`
- **Modify:** `web/src/hooks/use-analytics.ts` — add `useAdherenceTrends(days)` hook
- **Modify:** `web/src/types/analytics.ts` — add `AdherenceTrendPoint` and `AdherenceTrends` types
- **Modify:** `web/src/lib/constants.ts` — add `ANALYTICS_ADHERENCE_TRENDS` URL constant

## Out of Scope
- Per-trainee time-series drill-down
- Nutrition macro breakdown charts (calories/protein/carbs per trainee)
- CSV/PDF export of analytics data
- Custom date range picker (beyond 7/14/30d)
- Streak tracking or leaderboard
- Comparison between time periods (e.g., this week vs last week)
