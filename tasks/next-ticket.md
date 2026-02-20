# Feature: Trainer Revenue & Subscription Analytics (Web Dashboard)

## Priority
High

## User Story
As a **trainer**, I want to **see my revenue metrics, subscriber status, and payment history on the web dashboard** so that I can **track my business health, identify trends, and make informed decisions about pricing and retention**.

## Acceptance Criteria

### Backend — Revenue Analytics Endpoint
- [ ] AC-1: New `GET /api/trainer/analytics/revenue/` endpoint with `[IsAuthenticated, IsTrainer]` permissions
- [ ] AC-2: Accepts `?days=30` query param (30, 90, 365; default 30; clamped 1-365) for time filtering
- [ ] AC-3: Returns aggregated stats: `mrr` (sum of active subscription amounts), `total_revenue` (sum of succeeded payments in period), `active_subscribers` (count of active TraineeSubscriptions), `avg_revenue_per_subscriber` (mrr / active_subscribers or 0)
- [ ] AC-4: Returns `monthly_revenue` — array of `{ month: "YYYY-MM", amount: "decimal_string" }` for last 12 months, zero-filled for gaps (same pattern as ambassador dashboard)
- [ ] AC-5: Returns `subscribers` — array of active subscribers: `{ trainee_id, trainee_email, trainee_name, amount, currency, current_period_end, days_until_renewal, subscribed_since }`
- [ ] AC-6: Returns `recent_payments` — last 10 payments: `{ id, trainee_email, trainee_name, payment_type, status, amount, currency, description, paid_at, created_at }`
- [ ] AC-7: Row-level security: only returns data for the authenticated trainer's payments and subscriptions
- [ ] AC-8: Uses `select_related('trainee')` on all querysets to avoid N+1
- [ ] AC-9: Revenue analytics service in a service function (not inline in view), returning dataclasses

### Frontend — Types & Hooks
- [ ] AC-10: New `RevenueAnalytics` type in `types/analytics.ts` matching the API response shape
- [ ] AC-11: New `useRevenueAnalytics(days)` hook in `hooks/use-analytics.ts` with 5-minute staleTime
- [ ] AC-12: New API URL constant `ANALYTICS_REVENUE` in `lib/constants.ts`

### Frontend — Revenue Section
- [ ] AC-13: New `RevenueSection` component added to the analytics page below the existing Progress section
- [ ] AC-14: Period selector with 30d / 90d / 1y options (reuse `PeriodSelector` pattern or build inline tabs)
- [ ] AC-15: Four stat cards in a responsive grid: **MRR** (DollarSign icon), **Period Revenue** (TrendingUp icon), **Active Subscribers** (Users icon), **Avg/Subscriber** (UserCheck icon)
- [ ] AC-16: MRR stat card shows the `mrr` value formatted as currency ($X,XXX.XX)
- [ ] AC-17: Period Revenue stat card shows `total_revenue` for the selected period
- [ ] AC-18: Active Subscribers stat card shows count
- [ ] AC-19: Avg/Subscriber stat card shows `avg_revenue_per_subscriber` formatted as currency

### Frontend — Monthly Revenue Chart
- [ ] AC-20: Recharts `BarChart` showing monthly revenue for last 12 months (same pattern as ambassador `EarningsChart`)
- [ ] AC-21: Current month bar highlighted with `chart-1` color, other months with `chart-2`
- [ ] AC-22: Y-axis formatted as currency ($1K, $5K, etc.)
- [ ] AC-23: Tooltip shows full month name and exact dollar amount
- [ ] AC-24: Screen-reader accessible data list (sr-only `<ul>`)

### Frontend — Subscribers Table
- [ ] AC-25: DataTable showing active subscribers with columns: Name, Amount, Renewal, Subscribed Since
- [ ] AC-26: Amount column formatted as monthly currency ($XX.XX/mo)
- [ ] AC-27: Renewal column shows days until renewal with color coding (green >14d, amber 7-14d, red <7d)
- [ ] AC-28: Clickable rows navigate to trainee detail page (`/trainees/{id}`)

### Frontend — Recent Payments Table
- [ ] AC-29: DataTable showing recent 10 payments with columns: Trainee, Type, Amount, Status, Date
- [ ] AC-30: Status column with color-coded badges: succeeded (green), pending (amber), failed (red), refunded (blue)
- [ ] AC-31: Type column shows "Subscription" or "One-time"

### Frontend — States
- [ ] AC-32: Loading state with skeleton cards + skeleton chart + skeleton tables
- [ ] AC-33: Empty state when trainer has no payment data ("No revenue data yet. Set up pricing to start accepting payments.")
- [ ] AC-34: Error state with retry button
- [ ] AC-35: Refreshing state with opacity transition and sr-only aria-live message

## Edge Cases
1. **Trainer has no Stripe account connected** — Revenue section shows empty state with "Set up Stripe" CTA linking to subscription management page
2. **Trainer has subscribers but zero payments in selected period** — Stat cards show $0.00 for period revenue, MRR still calculated from active subs, charts show empty bars
3. **Trainer has one subscriber** — Avg/Subscriber equals MRR, tables show single row
4. **Subscriber with null period_end** — Renewal column shows "—" instead of days
5. **Payment with null paid_at** — Date column falls back to `created_at`
6. **All payments are failed/refunded** — Total revenue is $0.00 (only counts succeeded)
7. **Rapid period switching** — React Query caches each period independently; `isFetching` opacity handles transition
8. **Very large payment amounts** — Currency formatting handles $100,000+ with proper comma separation

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| API request fails | ErrorState with retry inside Revenue section | Section-level error, other analytics sections unaffected |
| No payment data | EmptyState with "Set up pricing" CTA | Check `total_revenue === 0 && active_subscribers === 0` |
| Network timeout | ErrorState with retry | React Query default error handling |

## UX Requirements
- **Loading state:** 4 skeleton cards + skeleton chart + 2 skeleton tables (matching adherence section pattern)
- **Empty state:** DollarSign icon, "No revenue data yet", "Set up pricing to start accepting payments" description, "Manage Pricing" button
- **Error state:** ErrorState with `onRetry` per section
- **Period transition:** `isFetching` opacity 50% + sr-only "Refreshing revenue data..." live region
- **Mobile behavior:** Stat cards 2-column on mobile (sm:grid-cols-2), tables horizontal-scroll on narrow screens
- **Chart height:** 240px (matching adherence trend chart)
- **Currency formatting:** Use `Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })`
- **Section heading:** "Revenue" with DollarSign icon, below Progress section

## Technical Approach

### Backend
- **New file:** `backend/trainer/services/revenue_analytics_service.py` — Service function `get_revenue_analytics(trainer: User, days: int)` returning a frozen dataclass `RevenueAnalyticsResult`
- **Modify:** `backend/trainer/views.py` — Add `RevenueAnalyticsView` (APIView, GET)
- **Modify:** `backend/trainer/urls.py` — Add `path('analytics/revenue/', RevenueAnalyticsView.as_view())`
- **Pattern:** Follow `AdherenceAnalyticsView` — same permission_classes, same `_parse_days_param()` helper, `select_related('trainee')` on queries
- **Monthly aggregation:** Use `TruncMonth` + `Sum` on `TraineePayment.objects.filter(trainer=user, status='succeeded', paid_at__gte=start)` with zero-fill for gaps (same pattern as ambassador dashboard)
- **MRR calculation:** `TraineeSubscription.objects.filter(trainer=user, status='active').aggregate(Sum('amount'))`

### Frontend
- **Modify:** `web/src/types/analytics.ts` — Add `RevenueAnalytics`, `RevenueSubscriber`, `RevenuePayment`, `RevenuePeriod` types
- **Modify:** `web/src/hooks/use-analytics.ts` — Add `useRevenueAnalytics(days: RevenuePeriod)` hook
- **Modify:** `web/src/lib/constants.ts` — Add `ANALYTICS_REVENUE` URL
- **New file:** `web/src/components/analytics/revenue-section.tsx` — Main section with stat cards, chart, tables
- **New file:** `web/src/components/analytics/revenue-chart.tsx` — Recharts BarChart (monthly revenue)
- **Modify:** `web/src/app/(dashboard)/analytics/page.tsx` — Add `<RevenueSection />` below `<ProgressSection />`

## Out of Scope
- Admin platform revenue analytics (already on admin dashboard)
- Stripe payout tracking or balance display
- Revenue forecasting or predictions
- CSV/PDF export of revenue data
- Mobile revenue dashboard
- Revenue notifications or alerts
