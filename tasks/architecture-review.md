# Architecture Review: Trainer Revenue & Subscription Analytics

## Review Date: 2026-02-20

## Files Reviewed
- `backend/trainer/services/revenue_analytics_service.py` (new)
- `backend/trainer/views.py` (RevenueAnalyticsView, lines 1025-1077)
- `backend/trainer/urls.py` (route at `analytics/revenue/`)
- `backend/subscriptions/models.py` (TraineePayment, TraineeSubscription)
- `web/src/types/analytics.ts` (revenue type definitions)
- `web/src/hooks/use-analytics.ts` (useRevenueAnalytics hook)
- `web/src/components/analytics/revenue-section.tsx` (main revenue UI)
- `web/src/components/analytics/revenue-chart.tsx` (bar chart component)
- `web/src/app/(dashboard)/analytics/page.tsx` (analytics page)
- Comparison: `adherence-section.tsx`, `AdherenceAnalyticsView`, `branding_service.py`

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in views
- [x] Consistent with existing patterns

**Details:**

1. **Service layer separation**: The revenue feature correctly places all business logic in `revenue_analytics_service.py`, following the project convention that views handle request/response only. This is actually *better* than the existing `AdherenceAnalyticsView` and `AdherenceTrendView`, which have their business logic inline in the view. The revenue feature sets a good precedent.

2. **Dataclass return types**: The service returns frozen dataclasses (`RevenueAnalyticsResult`, `RevenueSubscriberItem`, etc.), which aligns with the project rule: "for services and utils, return dataclass or pydantic models, never ever return dict." This is correctly implemented.

3. **View is thin**: `RevenueAnalyticsView` (lines 1025-1077) does exactly three things: authenticate, parse query params, and serialize the response. The manual dict-building in the view for response serialization is consistent with how other views in this file work (e.g., `AdherenceAnalyticsView`, `TrainerDashboardView`). While the project rules suggest `rest_framework_dataclasses` for API responses, this library is not used anywhere in the codebase, so the current approach is consistent with the actual codebase pattern.

4. **URL pattern**: `analytics/revenue/` sits alongside `analytics/adherence/` and `analytics/progress/` -- consistent naming and grouping.

5. **Permission classes**: Uses `[IsAuthenticated, IsTrainer]`, identical to all other trainer analytics endpoints.

6. **Row-level security**: All queries filter by `trainer=trainer`, ensuring trainers only see their own data. No cross-trainer data leakage.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | No schema changes to existing tables; only new indexes added |
| Migrations reversible | PASS | AddIndex operations are reversible |
| Indexes added for new queries | FIXED | Added `paid_at` index and composite `(trainer, status, paid_at)` index -- see Fixes Applied |
| No N+1 query patterns | PASS | `select_related('trainee')` used on both subscription and payment querysets |
| Correct ORM usage | PASS | Uses `aggregate`, `annotate`, `TruncMonth` -- no raw SQL |
| Queryset evaluation | PASS | Aggregations use `.aggregate()` (single query), lists use sliced querysets |

**Query analysis (5 queries total):**
1. `active_subs.aggregate(...)` -- MRR + count in one query, uses `(trainer, status)` index
2. `period_payments.aggregate(...)` -- total revenue, now uses `(trainer, status, paid_at)` composite index
3. Monthly breakdown with `TruncMonth` -- uses same composite index
4. `active_subs.order_by(...)[:100]` -- subscriber list, uses `(trainer, status)` index + `select_related`
5. `TraineePayment.objects.filter(trainer=...)[:10]` -- recent payments, uses `trainer` index + `select_related`

This is efficient. No N+1 patterns. All related objects loaded via `select_related`.

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Missing `paid_at` index | The service filters `TraineePayment` by `paid_at__gte` on lines 98 and 109. With no index on `paid_at`, these become full table scans as payment volume grows. | **FIXED**: Added `paid_at` single-column index and `(trainer, status, paid_at)` composite index. |
| 2 | Unbounded subscribers list | The original code iterated all active subscribers without any limit. A trainer with 1000+ subscribers would produce a very large API response. | **FIXED**: Capped subscriber list at 100 entries. For trainers exceeding this, a dedicated paginated endpoint should be built in the future. |
| 3 | Monthly zero-fill loop | The 12-month zero-fill loop (lines 121-132) iterates at most 13 times. This is bounded and trivial -- not a concern. | No action needed. |
| 4 | Hardcoded recent payments limit | Recent payments is capped at 10 (line 158). This is reasonable for a dashboard widget but may need pagination if users expect to browse payment history. | Acceptable for current scope. Consider a paginated `/payments/` endpoint in the future. |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Manual dict serialization in view | Low | The view manually converts dataclasses to dicts (lines 1039-1077). This is a pre-existing pattern across all analytics views. Adopting `rest_framework_dataclasses` or a `DataclassSerializer` would reduce boilerplate, but that is a codebase-wide refactor, not specific to this feature. |
| 2 | Adherence views lack service layer | Low (pre-existing) | `AdherenceAnalyticsView` and `AdherenceTrendView` have business logic inline. The revenue feature's service-layer approach is the better pattern. Eventually, adherence should be refactored to match. This is pre-existing debt that revenue did NOT introduce. |
| 3 | Currency hardcoded to USD formatter on frontend | Low | `revenue-section.tsx` uses a USD-hardcoded `Intl.NumberFormat`. The API returns `currency` per subscriber/payment. If multi-currency support is needed, the formatter should be dynamic. Acceptable for now since all pricing is USD. |

## Technical Debt Reduced
- Revenue analytics now follows the service-layer pattern, setting a better precedent than the inline analytics views.
- Proper frozen dataclasses ensure immutability of service results.
- Added database indexes that benefit all payment-related queries, not just this feature.

## Frontend Architecture Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Component structure matches adherence pattern | PASS | `RevenueSection` mirrors `AdherenceSection` exactly: period selector, stat cards, chart, tables |
| Shared components reused | PASS | Uses `StatCard`, `DataTable`, `ErrorState`, `EmptyState`, `PageHeader` |
| Chart follows conventions | PASS | Uses `recharts`, `tooltipContentStyle` from shared `chart-utils`, theme-aware colors |
| State management via React Query | PASS | `useRevenueAnalytics` hook with `staleTime: 5min`, consistent with other hooks |
| Type safety | PASS | All types defined in `analytics.ts`, exact 1:1 mapping with API response |
| Accessibility | PASS | ARIA labels, `role="radiogroup"` on period selector, `sr-only` data table for chart, keyboard navigation |
| Loading/empty/error states | PASS | All three handled with skeleton, `EmptyState`, and `ErrorState` |
| Fetching indicator | PASS | `opacity-50` + `aria-busy` during refetch, with `sr-only` live region |
| File size | PASS | `revenue-section.tsx` is ~452 lines which is on the higher side but contains period selector, skeleton, column definitions, and main component. Each is clearly delineated. The chart is properly extracted into `revenue-chart.tsx`. |

## Fixes Applied
1. **Added `paid_at` index to `TraineePayment`** (`backend/subscriptions/models.py` line 561): Single-column index on `paid_at` to support date-range filtering.
2. **Added composite index `(trainer, status, paid_at)`** (`backend/subscriptions/models.py` line 562): Covers the most common query pattern -- "succeeded payments for this trainer in a date range." This is the optimal index for the revenue service's two main payment queries.
3. **Generated migration** `0005_add_paid_at_indexes_to_trainee_payment.py`: Clean, reversible migration adding both indexes.
4. **Capped subscriber list at 100** (`backend/trainer/services/revenue_analytics_service.py` line 136): Prevents unbounded response payload for trainers with many subscribers.

## Architecture Score: 9/10
## Recommendation: APPROVE

**Summary:** The Trainer Revenue & Subscription Analytics feature is architecturally sound. It correctly follows the service-layer pattern (better than existing analytics views), uses frozen dataclasses for service returns, has proper N+1 prevention with `select_related`, maintains row-level security, and the frontend follows established component patterns with full accessibility support. The two issues found (missing `paid_at` index and unbounded subscribers list) have been fixed. The only minor concerns are pre-existing patterns (manual dict serialization, USD-hardcoded formatting) that are codebase-wide and not introduced by this feature.
