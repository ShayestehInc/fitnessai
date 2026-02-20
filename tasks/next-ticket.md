# Feature: Ambassador Dashboard Enhancement — Earnings Chart + Referral Pagination

## Priority
Medium

## User Story
As an **ambassador**, I want to **see my monthly earnings visualized as a chart and browse my referrals with pagination and status filters** so that I can **track my commission trends over time and efficiently manage my referral portfolio**.

## Acceptance Criteria

### Backend
- [ ] AC-1: `GET /api/ambassador/dashboard/` returns `monthly_earnings` for the last 12 months (currently 6 months) — each entry has `{month: "YYYY-MM", earnings: "123.45"}`
- [ ] AC-2: Months with zero earnings are included in the response (filled with `"0.00"`) so the chart has no gaps
- [ ] AC-3: The `monthly_earnings` response key is renamed from `earnings` to `amount` for consistency with the existing TypeScript type `{ month: string; amount: string }[]` — OR the frontend type is updated to match

### Web Dashboard — Earnings Chart
- [ ] AC-4: New `EarningsChart` component on the ambassador dashboard page showing a bar chart of monthly earnings
- [ ] AC-5: Chart uses Recharts `BarChart` with `ResponsiveContainer` (same pattern as `AdherenceBarChart`)
- [ ] AC-6: X-axis shows month labels (e.g., "Mar", "Apr", "May"), Y-axis shows dollar amounts
- [ ] AC-7: Tooltips on hover show exact amount and full month name (e.g., "March 2026: $1,250.00")
- [ ] AC-8: Chart follows existing theme (CSS variables for colors, `tooltipContentStyle` from `chart-utils.ts`)
- [ ] AC-9: Chart is placed between the stat cards and the referral code card on the dashboard
- [ ] AC-10: Empty state: if no earnings data, show a message "No earnings data yet" with a muted description
- [ ] AC-11: Chart has `role="img"` and `aria-label` for screen readers, plus an `sr-only` data list
- [ ] AC-12: Dark mode support via CSS variables (no hardcoded colors)

### Web Dashboard — Referral Status Breakdown
- [ ] AC-13: Visual breakdown of referral statuses (active/pending/churned) displayed on the dashboard
- [ ] AC-14: Uses the existing dashboard data (`active_referrals`, `pending_referrals`, `churned_referrals`) — no new API call
- [ ] AC-15: Color-coded: green for active, amber/yellow for pending, red/muted for churned
- [ ] AC-16: Accessible with `aria-label` and screen-reader-friendly text

### Web Dashboard — Referral List Pagination
- [ ] AC-17: Referral list page (`/ambassador/referrals`) uses server-side pagination with page controls (Previous/Next + page indicator)
- [ ] AC-18: Status filter tabs or select (All, Active, Pending, Churned) that filter server-side via `?status=` query param
- [ ] AC-19: Search input filters client-side within the current page results (existing behavior preserved)
- [ ] AC-20: Loading skeleton shown during page transitions
- [ ] AC-21: Empty states: "No referrals yet" (no referrals at all) vs "No referrals match this filter" (filtered but empty)
- [ ] AC-22: Page resets to 1 when status filter changes
- [ ] AC-23: `useAmbassadorReferrals(status, page)` hook already supports these params — just wire up the UI

## Edge Cases
1. **No earnings data** — Ambassador just signed up, zero commissions. Chart shows empty state, not a broken chart.
2. **Single month of data** — Chart should still render correctly with one bar.
3. **Very large earnings** — Y-axis should auto-scale and format large numbers (e.g., "$1,250", "$12.5K").
4. **Zero-earnings months** — Gaps between earning months should show $0 bars, not missing bars.
5. **No referrals at all** — Referral list shows "Share your referral code to start earning commissions."
6. **All referrals same status** — Status filter tabs should still work; other tabs show empty state.
7. **Rapid filter switching** — React Query handles this via cache key changes; stale data should not flash.
8. **Mobile responsive** — Chart should be readable on small screens (min-height, horizontal padding).

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Dashboard API fails | ErrorState with retry | Toast or inline error |
| No earnings data | "No earnings data yet" muted message | EmptyState component |
| No referrals | "No referrals yet" with share CTA | EmptyState component |
| Network error on pagination | Error state in referral list | Retry button |

## UX Requirements
- **Chart default state:** Bar chart with last 12 months, current month highlighted/distinct color
- **Chart loading state:** Skeleton rectangle placeholder (same height as chart)
- **Chart empty state:** Muted message centered in chart area
- **Referral list loading:** Skeleton rows (existing pattern)
- **Referral list empty:** EmptyState with icon and contextual message
- **Mobile behavior:** Chart uses `ResponsiveContainer` for fluid width, min-height ~200px
- **Dark mode:** All components use CSS variables, chart colors from theme

## Technical Approach

### Backend
- **Modify:** `backend/ambassador/views.py` — `AmbassadorDashboardView.get()` to return 12 months of data with zero-fill for missing months
- **Response key alignment:** Check if `monthly_earnings` uses `earnings` or `amount` key and align with frontend type

### Web
- **New file:** `web/src/components/ambassador/earnings-chart.tsx` — Recharts BarChart component
- **New file:** `web/src/components/ambassador/referral-status-breakdown.tsx` — Status visualization (bar or ring)
- **Modify:** `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx` — Add chart and status breakdown
- **Modify:** `web/src/components/ambassador/referral-list.tsx` — Add server-side pagination controls and status filter tabs
- **Modify:** `web/src/types/ambassador.ts` — Update types if needed for backend response alignment

## Out of Scope
- Admin-side ambassador analytics/charts
- Ambassador earnings CSV/PDF export
- Commission detail expansion (click to see per-referral breakdown)
- Real-time WebSocket updates for ambassador events
