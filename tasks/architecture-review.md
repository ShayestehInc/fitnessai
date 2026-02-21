# Architecture Review: CSV Data Export

## Review Date
2026-02-21

## Files Reviewed
- `backend/trainer/services/export_service.py` -- Export business logic (CSV generation)
- `backend/trainer/export_views.py` -- HTTP request/response layer
- `backend/trainer/utils.py` -- Shared `parse_days_param` utility
- `backend/trainer/urls.py` -- URL wiring (`export/payments/`, `export/subscribers/`, `export/trainees/`)
- `web/src/components/shared/export-button.tsx` -- Frontend download component
- `web/src/lib/constants.ts` -- URL constants (`EXPORT_PAYMENTS`, `EXPORT_SUBSCRIBERS`, `EXPORT_TRAINEES`)
- `backend/trainer/services/revenue_analytics_service.py` -- Existing service (pattern reference)
- `backend/subscriptions/models.py` -- Underlying data models and indexes (`TraineePayment`, `TraineeSubscription`)
- `backend/trainer/views.py` -- Existing views (pattern reference, import conventions)

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Service handles business logic
- [x] Views handle request/response only
- [x] Consistent with existing patterns
- [x] Models/schemas in correct locations
- [x] No business logic in views
- [x] Return types use dataclass (not dict)
- [x] Type hints on all functions

**Details:**

1. **Service layer separation**: All CSV generation logic (queries, formatting, buffer writing) lives in `export_service.py`. The views in `export_views.py` are 3-4 lines each: cast user, parse params, call service, return `HttpResponse`. This mirrors the `RevenueAnalyticsView` + `revenue_analytics_service.py` pattern exactly.

2. **Dataclass return type**: `CsvExportResult` is a `frozen=True` dataclass with `content`, `filename`, and `row_count` fields. This follows the project rule: "for services and utils, return dataclass or pydantic models, never ever return dict." Immutability prevents accidental mutation between service and view layers.

3. **Dedicated views file**: Export views are in `export_views.py`, keeping `views.py` from growing further. This is a good organizational decision -- `views.py` already has 1000+ lines.

4. **Shared utility reuse**: `parse_days_param` in `utils.py` is shared between `export_views.py` and `views.py` (used by `RevenueAnalyticsView`). Good DRY practice.

5. **Permission classes**: All three views use `[IsAuthenticated, IsTrainer]` from `core.permissions`, identical to all other trainer endpoints.

6. **Row-level security**: All queries filter by `trainer=trainer` (the authenticated user). No IDOR possible -- a trainer cannot export another trainer's data.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| No schema changes needed | PASS | Reads existing models only; no migrations required |
| `select_related` used correctly | PASS | `export_payments_csv` and `export_subscribers_csv` both use `.select_related("trainee")` to avoid N+1 |
| `prefetch_related` used correctly | PASS | `export_trainees_csv` uses `Prefetch` with `queryset` filter and `to_attr` for active programs |
| Annotation for aggregates | PASS | `export_trainees_csv` uses `annotate(last_log_date=Max("daily_logs__date"))` instead of prefetching all daily logs -- avoids unbounded memory |
| Existing indexes cover queries | PASS | `TraineePayment` has index on `trainer`; `TraineeSubscription` has index on `trainer`; `User.parent_trainer` FK has implicit index |
| No N+1 query patterns | PASS | All related data loaded via `select_related`/`prefetch_related`/`annotate` |

**Query analysis per export function:**

1. **`export_payments_csv`**: 1 query -- `TraineePayment.filter(trainer=, created_at__gte=).select_related("trainee")`. Uses `trainer` index. Filters by `created_at__gte` with `days` param (max 365), bounding the result set.

2. **`export_subscribers_csv`**: 1 query -- `TraineeSubscription.filter(trainer=).select_related("trainee")`. Uses `trainer` index. Returns all statuses for complete bookkeeping.

3. **`export_trainees_csv`**: 1 query -- `User.filter(parent_trainer=, role=TRAINEE).select_related("profile").prefetch_related(Prefetch("programs", ...)).annotate(...)`. The `Prefetch` adds a second query for active programs. Total: 2 queries. Efficient.

## Scalability Concerns
| # | Area | Severity | Assessment |
|---|------|----------|------------|
| 1 | Payment export date filter | Low | Filters `created_at__gte` but the compound index is `(trainer, status, paid_at)`. The single-column `trainer` index still covers the filter adequately. For typical trainer volumes (tens to hundreds of payments per year), this is not a bottleneck. A compound `(trainer, created_at)` index would help at very high volume but is premature optimization. |
| 2 | Subscriber/trainee exports have no LIMIT | Low | Intentional -- exports should include all data for bookkeeping. Bounded in practice by tier trainee limits (3 for Free, 10 for Starter, 50 for Pro). Enterprise trainers with thousands of trainees could produce large CSVs, but CSV is lightweight and this is an infrequent user-initiated action. Acceptable. |
| 3 | In-memory CSV buffer | Low | Uses `io.StringIO` to build CSV before returning. For expected volumes (hundreds to low-thousands of rows), memory usage is trivial. If exports grew to millions of rows, `StreamingHttpResponse` would be needed, but that is premature optimization. |

## API Design Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| RESTful URL structure | PASS | `GET /api/trainer/export/payments/`, `/subscribers/`, `/trainees/` -- clean noun-based paths under `export/` namespace |
| Consistent with existing endpoints | PASS | Same `GET` + query param pattern as `RevenueAnalyticsView` |
| Query params validated | PASS | `parse_days_param` clamps to 1-365, defaults to 30, handles `ValueError`/`TypeError` |
| Auth + permissions | PASS | `[IsAuthenticated, IsTrainer]` on all views |
| Response format | PASS | `HttpResponse` with `text/csv` content type and `Content-Disposition: attachment` header |
| Frontend URL constants | PASS | `EXPORT_PAYMENTS`, `EXPORT_SUBSCRIBERS`, `EXPORT_TRAINEES` registered in `constants.ts` |

## Frontend Component Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Auth token handling | PASS | Refreshes expired token before request; retries once on 401 race condition |
| Error states | PASS | Distinct messages for 403 (permission denied) vs generic failure vs network error |
| Loading state | PASS | `isDownloading` boolean with `Loader2` spinner, button disabled during download |
| Download mechanism | PASS | `URL.createObjectURL` + programmatic `<a>` click + delayed `revokeObjectURL` for Safari |
| Accessibility | PASS | `aria-label` prop support, button disabled during download |
| Reusability | PASS | Generic props (`url`, `filename`, `label`) -- works for any CSV export endpoint |
| Component size | PASS | 124 lines including the `triggerDownload` helper -- well within 150-line convention |

## Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| -- | -- | No critical or major issues found | -- |

## Minor Observations (not requiring changes)

1. **Payment date filter is correct for its use case**: `export_payments_csv` filters on `created_at__gte` while the revenue analytics service filters on `paid_at__gte` for succeeded payments. The export is correct -- it includes all payment statuses (pending, failed, etc.) which may not have `paid_at` set, so `created_at` is the right filter field.

2. **No cap on export rows vs. analytics cap**: The revenue analytics service caps subscribers at 100 (`[:100]`), but export functions return all rows. This is the correct design decision -- analytics shows a summary while exports provide complete data.

3. **Helper functions are module-private**: `_format_date`, `_format_date_only`, `_safe_str`, `_format_amount` are prefixed with underscore, signaling they are internal to the service module. Clean encapsulation.

4. **Frozen dataclass immutability**: `CsvExportResult(frozen=True)` matches the pattern in `revenue_analytics_service.py` (`RevenueAnalyticsResult(frozen=True)`). Consistent and prevents accidental mutation.

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| -- | None introduced | -- | The implementation follows established patterns exactly and does not introduce new patterns or deviations |

## Technical Debt Reduced
- Export views are in a dedicated file (`export_views.py`), preventing further growth of the 1000+ line `views.py`.
- `parse_days_param` extraction into `utils.py` is reused across multiple view files, reducing duplication.

## Summary

The CSV Data Export feature is architecturally clean. It follows the established service-layer pattern precisely: thin views in a dedicated file, all business logic in a service, shared utilities extracted, frozen dataclass return types, proper query optimization with `select_related`/`prefetch_related`/`annotate`, and correct auth/row-level security enforcement. The frontend component is reusable, accessible, handles all error states, and stays well within file size conventions. No new models, migrations, or schema changes are needed. No architectural issues found.

## Architecture Score: 9/10
## Recommendation: APPROVE
