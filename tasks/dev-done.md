# Dev Done: Ambassador Dashboard Enhancement (Pipeline 25)

## Date
2026-02-20

## Files Changed

### Backend (Modified)
- `backend/ambassador/views.py` — Updated `AmbassadorDashboardView.get()` to return 12 months of earnings data (was 6), zero-fill months with no earnings, use `amount` key (aligned with frontend type)

### Web (New)
- `web/src/components/ambassador/earnings-chart.tsx` — Recharts BarChart component showing monthly earnings with tooltips, current month highlighting, empty state, dark mode support, screen reader data list
- `web/src/components/ambassador/referral-status-breakdown.tsx` — Stacked progress bar showing active/pending/churned distribution with color-coded legend

### Web (Modified)
- `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx` — Wired EarningsChart and ReferralStatusBreakdown into the dashboard layout (chart between stats and referral code card, status breakdown beside referral code card)
- `web/src/components/ambassador/referral-list.tsx` — Complete rewrite: added server-side pagination with Previous/Next controls, status filter tabs (All/Active/Pending/Churned), loading skeletons during page transitions, proper empty states for each scenario
- `web/src/hooks/use-ambassador.ts` — Added `keepPreviousData` to `useAmbassadorReferrals` for smooth pagination transitions

## Key Decisions
1. Used Recharts `BarChart` with `ResponsiveContainer` matching existing `AdherenceBarChart` pattern
2. Current month bar uses `--chart-1` color, other months use `--chart-2` — same CSS variable pattern
3. Referral status breakdown uses a stacked horizontal bar (not a donut chart) — simpler, more accessible, no extra dependency
4. Pagination uses `keepPreviousData` (React Query v5) to prevent flash of empty state during page transitions
5. Status filter tabs reset page to 1 and clear search when changed
6. Client-side search preserved within current page results (AC-19)
7. Used `<Button>` components for filter tabs rather than custom Tab component for consistency

## Deviations from Ticket
- None — all acceptance criteria addressed.

## Acceptance Criteria Status
- AC-1: 12 months of data ✅
- AC-2: Zero-fill gaps ✅
- AC-3: Uses `amount` key ✅
- AC-4-12: EarningsChart component ✅
- AC-13-16: ReferralStatusBreakdown ✅
- AC-17-23: Referral list pagination + filters ✅

## How to Test
1. Login as ambassador
2. Navigate to /ambassador/dashboard — see stat cards, earnings chart, status breakdown bar, referral code card, recent referrals
3. Chart shows 12 months; current month highlighted in distinct color
4. Navigate to /ambassador/referrals — see filter tabs and paginated list
5. Click filter tabs to filter by status; page resets to 1
6. Use Previous/Next buttons for pagination
7. Search filters within current page
8. Test empty states: new ambassador with no referrals
