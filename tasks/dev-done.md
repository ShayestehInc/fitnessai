# Dev Done: Trainer Revenue & Subscription Analytics (Web Dashboard)

## Date
2026-02-20

## Files Created
- `backend/trainer/services/revenue_analytics_service.py` — Service with frozen dataclasses (`RevenueAnalyticsResult`, `RevenueSubscriberItem`, `RevenuePaymentItem`, `MonthlyRevenuePoint`) and `get_revenue_analytics()` function
- `web/src/components/analytics/revenue-section.tsx` — Main RevenueSection component with stat cards, period selector, subscriber table, payment table
- `web/src/components/analytics/revenue-chart.tsx` — Recharts BarChart for monthly revenue (matches ambassador EarningsChart pattern)

## Files Modified
- `backend/trainer/views.py` — Added `RevenueAnalyticsView` (APIView, GET, IsAuthenticated+IsTrainer)
- `backend/trainer/urls.py` — Added `path('analytics/revenue/', ...)` and import
- `web/src/types/analytics.ts` — Added `RevenuePeriod`, `RevenueAnalytics`, `RevenueSubscriber`, `RevenuePayment`, `MonthlyRevenuePoint` types
- `web/src/hooks/use-analytics.ts` — Added `useRevenueAnalytics(days)` hook with 5-min staleTime
- `web/src/lib/constants.ts` — Added `ANALYTICS_REVENUE` URL constant
- `web/src/app/(dashboard)/analytics/page.tsx` — Added `<RevenueSection />` below ProgressSection, updated description

## Key Decisions
1. **Service layer with dataclasses** — Following project convention: business logic in services, views handle request/response only. All return types are frozen dataclasses.
2. **MRR computed from active subs** — MRR is the sum of all active TraineeSubscription amounts (not period-filtered). Total revenue IS period-filtered to succeeded payments.
3. **Monthly revenue uses paid_at** — TruncMonth aggregates on `paid_at` (not `created_at`) for accurate month attribution.
4. **12-month zero-filled chart** — Same pattern as ambassador dashboard: generates all months in range and fills gaps with "0.00".
5. **RevenuePeriodSelector** — Custom period selector (30d/90d/1y) instead of reusing AdherencePeriod (7/14/30) since revenue needs longer periods.
6. **Inline import** — Service uses `from subscriptions.models import ...` inside the function to avoid circular imports between trainer and subscriptions apps.
7. **Status badge colors** — Matches standard patterns: green=succeeded, amber=pending, red=failed, blue=refunded.
8. **Renewal color coding** — Green >14d, amber 7-14d, red <7d.

## Deviations from Ticket
- None. All acceptance criteria addressed.

## How to Manually Test
1. Login as a trainer on the web dashboard
2. Navigate to Analytics page
3. Scroll to the bottom to see the new "Revenue" section
4. Period selector switches between 30d/90d/1y
5. With no payment data: shows empty state with "Manage Pricing" CTA
6. With payment data: shows 4 stat cards, monthly bar chart, subscribers table, payments table
7. Subscriber rows are clickable (navigate to trainee detail)
8. Payment status badges are color-coded

## Test Results
- Backend: 164 trainer tests pass (0 failures)
- Frontend: TypeScript check clean (0 errors)
