# Feature: Web Dashboard Phase 3 — Trainer Analytics Page

## Priority
High — Trainers currently have no aggregate view of trainee performance. Backend APIs exist but have zero frontend consumers.

## User Story
As a **trainer**, I want to see aggregate adherence and progress analytics across all my trainees so that I can identify who needs extra attention, measure program effectiveness, and track coaching outcomes.

## Acceptance Criteria

### Navigation & Layout (AC-1 through AC-3)
- [ ] **AC-1**: New "Analytics" nav item in sidebar between "Invitations" and "Notifications" with `BarChart3` icon from lucide-react
- [ ] **AC-2**: Analytics page at `/analytics` renders within the dashboard layout
- [ ] **AC-3**: Page has PageHeader with title "Analytics" and description "Track trainee performance and adherence"

### Adherence Section (AC-4 through AC-11)
- [ ] **AC-4**: Period selector with 7 / 14 / 30 day options (default 30). Selecting a period refetches adherence data.
- [ ] **AC-5**: Three stat cards showing aggregate rates from adherence API: "Food Logged" (`food_logged_rate`%), "Workouts Logged" (`workout_logged_rate`%), "Protein Goal Hit" (`protein_goal_rate`%)
- [ ] **AC-6**: Stat card values show percentage with 1 decimal place and a colored indicator: green >= 80%, amber 50-79%, red < 50%
- [ ] **AC-7**: Adherence bar chart visualization: horizontal bars showing each trainee's overall `adherence_rate`, sorted highest to lowest. Trainee name on Y-axis, percentage on X-axis.
- [ ] **AC-8**: Clicking a trainee bar navigates to `/trainees/{id}`
- [ ] **AC-9**: Adherence section loading skeleton while data fetches
- [ ] **AC-10**: Adherence section error state with retry button
- [ ] **AC-11**: Adherence section empty state when trainer has no active trainees

### Progress Section (AC-12 through AC-18)
- [ ] **AC-12**: Progress table showing all trainees: Name, Current Weight (kg), Weight Change (kg with +/- indicator and color), Goal
- [ ] **AC-13**: Weight change column uses color: green for loss when goal is "weight_loss", green for gain when goal is "muscle_gain", neutral otherwise
- [ ] **AC-14**: Null weight values show "—" dash
- [ ] **AC-15**: Clicking a trainee row navigates to `/trainees/{id}`
- [ ] **AC-16**: Progress section loading skeleton
- [ ] **AC-17**: Progress section error state with retry button
- [ ] **AC-18**: Progress section empty state when trainer has no active trainees

### General (AC-19 through AC-22)
- [ ] **AC-19**: Page handles both sections loading independently (each has its own loading/error/empty state)
- [ ] **AC-20**: All API calls use authenticated `apiClient.get()` with proper types
- [ ] **AC-21**: New TypeScript types for both API responses
- [ ] **AC-22**: Adherence data uses `staleTime: 5 * 60 * 1000` (5 min) since it changes infrequently

## Edge Cases
1. **Zero trainees** — Both sections show empty states with different messages
2. **Trainee with no weight data** — `current_weight` and `weight_change` are null → show "—"
3. **Trainee with no profile** — `goal` is null → show "Not set"
4. **All trainees at 0% adherence** — Chart renders with zero-width bars, still shows names
5. **Single trainee** — Chart and table work correctly with 1 row
6. **Large number of trainees (50+)** — Chart scrolls vertically, table works via standard layout
7. **Period selector rapid switching** — React Query handles via queryKey change (old request cancelled)
8. **Network failure mid-page** — One section can error while other succeeds
9. **Very long trainee names** — Truncated with title tooltip on hover

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Adherence API 500 | Error card with "Failed to load adherence data" + retry button | React Query error state |
| Progress API 500 | Error card with "Failed to load progress data" + retry button | React Query error state |
| No active trainees (adherence) | EmptyState: "No active trainees" + "Invite trainees to see analytics" | API returns empty `trainee_adherence` array |
| No active trainees (progress) | EmptyState: "No progress data" + "Trainees will appear here once they start tracking" | API returns empty `trainee_progress` array |
| Auth token expired | Redirect to login (existing auth middleware) | 401 → refresh → retry |

## UX Requirements
- **Loading state**: Skeleton placeholders for stat cards (3 cards) and chart/table area
- **Empty state**: Per-section empty states with relevant icons and CTAs
- **Error state**: Per-section error alerts with retry buttons
- **Success feedback**: No toast needed (read-only analytics page)
- **Period selector**: Tab-style buttons (not dropdown) for quick switching. Active period has primary styling.
- **Chart**: Horizontal bar chart. Bars colored by adherence level (green/amber/red). Trainee names as Y-axis labels.
- **Table**: Standard DataTable component with row click navigation. Sortable by weight change column.
- **Responsive**: Stat cards in 3-column grid on desktop, stack on mobile. Chart full width. Table scrollable on mobile.

## Technical Approach

### Files to Create
- `web/src/app/(dashboard)/analytics/page.tsx` — Analytics page
- `web/src/types/analytics.ts` — TypeScript types for API responses
- `web/src/hooks/use-analytics.ts` — React Query hooks for both endpoints
- `web/src/components/analytics/adherence-section.tsx` — Adherence stat cards + chart
- `web/src/components/analytics/progress-section.tsx` — Progress table
- `web/src/components/analytics/adherence-chart.tsx` — Horizontal bar chart component
- `web/src/components/analytics/period-selector.tsx` — 7/14/30 day tab selector

### Files to Modify
- `web/src/components/layout/nav-links.tsx` — Add Analytics nav item
- `web/src/lib/constants.ts` — Add analytics API URLs

### Backend APIs (already exist, no changes needed)
- `GET /api/trainer/analytics/adherence/?days=30` → `AdherenceAnalyticsView`
- `GET /api/trainer/analytics/progress/` → `ProgressAnalyticsView`

### Key Design Decisions
- Two independent React Query hooks (adherence + progress) so sections load independently
- Period selector changes queryKey `["analytics", "adherence", days]` → automatic refetch
- Horizontal bar chart (not vertical) for adherence — better readability with trainee names
- Reuse existing `DataTable` component for progress table
- Reuse existing shared components (`PageHeader`, `EmptyState`, `ErrorState`, `LoadingSpinner`, `Skeleton`)

## Out of Scope
- Historical trend charts (adherence over time) — future enhancement
- Export to CSV/PDF
- Custom date range picker
- Notification triggers based on analytics thresholds
- Program effectiveness metrics
