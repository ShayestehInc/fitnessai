# Pipeline 28 Focus: Trainer Revenue & Subscription Analytics (Web Dashboard)

## Priority
Add a Revenue section to the trainer analytics page so trainers can track their income, active subscribers, and payment history. The backend already stores all payment data (TraineePayment, TraineeSubscription), but there is zero trainer-facing UI for it on the web dashboard.

## Why This Feature
1. **Trainers are the paying customers** — They need to understand their business metrics (MRR, subscriber count, revenue trends).
2. **Data exists but is invisible** — `TraineePayment` and `TraineeSubscription` models are populated by Stripe webhooks, and endpoints `/api/payments/trainer/payments/` and `/api/payments/trainer/subscribers/` exist, but NO web UI consumes them.
3. **Pattern is established** — The analytics page already has Adherence + Progress sections with StatCards, recharts, DataTable, and period selectors. Revenue is a natural third section.
4. **Extends Phase 11** — "Advanced analytics and reporting" is listed as partially completed.
5. **Moderate complexity** — New backend analytics endpoint + 3-4 frontend components following proven patterns.

## Scope
- Backend: New `GET /api/trainer/analytics/revenue/` endpoint with aggregated revenue data (MRR, total revenue, monthly breakdown, subscriber stats)
- Web: New `RevenueSection` component on the analytics page
- Web: Revenue stat cards (MRR, Total Revenue, Active Subscribers, Avg Revenue/Subscriber)
- Web: Monthly revenue bar chart (recharts)
- Web: Active subscribers table and recent payments table
- Web: Period selector for revenue trends (7/14/30/90 days)

## What NOT to build
- Admin-level platform revenue analytics (already exists on admin dashboard)
- Payment processing changes or new checkout flows
- Mobile revenue dashboard (mobile is trainer-facing, not a priority here)
- Payout/withdrawal features
