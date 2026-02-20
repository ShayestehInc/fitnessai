# Pipeline 25 Focus: Ambassador Dashboard Enhancement

## Priority
Complete the ambassador web dashboard by adding the monthly earnings chart and server-side pagination on the referral list. These are two explicitly listed Phase 11 items that together polish the ambassador experience.

## Why This Feature
1. **Explicitly listed in Phase 11** — "Ambassador monthly earnings chart (web dashboard)" and "Server-side pagination on ambassador list (web dashboard)" are both outstanding items.
2. **Data already exists** — The backend `AmbassadorDashboardView` already returns `monthly_earnings` as an array of `{month, earnings}` objects. The `AmbassadorReferralsView` already supports pagination. Just need the frontend components.
3. **Low risk, high polish** — Recharts is already installed and used by the adherence chart. Chart utilities and patterns are established.
4. **Completes the ambassador experience** — The dashboard currently shows only stat cards and a text list. Adding the chart makes the earnings data visual and actionable.

## Scope
- Web: New `EarningsChart` component using Recharts BarChart showing monthly earnings over the last 6 months
- Web: Add the chart to the ambassador dashboard page between stat cards and referral code card
- Web: Server-side pagination on the referral list page with page controls, status filter tabs, and proper loading states
- Web: Referral status breakdown (donut/ring chart or status breakdown bar) showing active/pending/churned distribution
- Backend: Extend monthly earnings to return last 12 months (not just 6) for a better chart view
- Backend: Ensure referral list pagination returns proper count/has_next/has_previous

## What NOT to build
- Admin-side ambassador analytics (defer)
- Ambassador earnings export/CSV (defer)
- Push notifications for commission events (defer)
- Commission history page redesign (defer)
