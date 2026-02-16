# Dev Done: Web Dashboard Phase 3 — Trainer Analytics Page

## Date: 2026-02-15

## Files Created
| File | Purpose |
|------|---------|
| `web/src/types/analytics.ts` | TypeScript types for AdherenceAnalytics and ProgressAnalytics API responses |
| `web/src/hooks/use-analytics.ts` | Two React Query hooks: `useAdherenceAnalytics(days)` with days param in queryKey, `useProgressAnalytics()` — both with 5-min staleTime |
| `web/src/components/analytics/period-selector.tsx` | Tab-style radio group for 7/14/30 day selection |
| `web/src/components/analytics/adherence-chart.tsx` | Horizontal bar chart using recharts, color-coded by adherence level, clickable bars navigate to trainee detail |
| `web/src/components/analytics/adherence-section.tsx` | Three stat cards + adherence chart + period selector with independent loading/error/empty states |
| `web/src/components/analytics/progress-section.tsx` | Progress table using DataTable with weight change colors and row click navigation |
| `web/src/app/(dashboard)/analytics/page.tsx` | Analytics page composing both sections with PageHeader |

## Files Modified
| File | Changes |
|------|---------|
| `web/src/components/layout/nav-links.tsx` | Added Analytics nav item with BarChart3 icon between Invitations and Notifications |
| `web/src/lib/constants.ts` | Added ANALYTICS_ADHERENCE and ANALYTICS_PROGRESS API URL constants |

## Key Decisions
1. **Two independent React Query hooks** — Adherence and progress sections load independently (AC-19). Each has its own loading/error/empty state.
2. **Period selector as radio group** — Uses `role="radiogroup"` and `role="radio"` with `aria-checked` for proper accessibility.
3. **Horizontal BarChart** — Vertical layout with trainee names on Y-axis for better readability with many trainees.
4. **Color-coded adherence** — Green (≥80%), amber (50-79%), red (<50%) using CSS custom properties for theme awareness.
5. **Weight change color logic** — Green for progress toward goal (loss if weight_loss, gain if muscle_gain), red for regression, neutral otherwise.
6. **Null handling** — Null weight shows "—", null goal shows "Not set".
7. **Recharts Bar onClick typing** — Used `as unknown as TraineeAdherence` cast because recharts doesn't carry data type generics into click handler.
8. **5-minute staleTime** — Both queries use `staleTime: 5 * 60 * 1000` since analytics data changes infrequently (AC-22).

## Deviations from Ticket
- None. All 22 acceptance criteria addressed.

## How to Manually Test
1. Navigate to `/analytics` in the sidebar
2. Verify three stat cards appear with percentage values and colored indicators
3. Change period selector (7d/14d/30d) — verify data refreshes
4. Verify horizontal bar chart shows trainees sorted by adherence, color-coded
5. Click a trainee bar — should navigate to `/trainees/{id}`
6. Verify progress table shows name, weight, weight change (with arrows), goal
7. Click a progress table row — should navigate to `/trainees/{id}`
8. Test empty state by having a trainer with no trainees
9. Test error state by disconnecting network
10. Verify responsive layout: stat cards stack on mobile, table scrolls horizontally

## Build & Lint Status
- `npm run build` — Compiled successfully, 0 errors
- `npm run lint` — 0 errors, 0 warnings
- Backend tests — Not runnable (no venv available, no backend changes made)
