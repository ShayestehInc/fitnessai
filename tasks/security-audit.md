# Security Audit: Trainer Revenue & Subscription Analytics (Pipeline 28)

## Audit Date: 2026-02-20

## Files Reviewed
- `backend/trainer/services/revenue_analytics_service.py`
- `backend/trainer/views.py` (RevenueAnalyticsView + `_parse_days_param` helper)
- `backend/trainer/urls.py`
- `backend/trainer/tests/test_revenue_analytics.py`
- `backend/core/permissions.py` (IsTrainer permission class)
- `backend/config/settings.py` (throttling, auth defaults)
- `web/src/hooks/use-analytics.ts`
- `web/src/lib/constants.ts` (API_URLS)
- `web/src/lib/api-client.ts` (auth header injection)
- `web/src/components/analytics/revenue-section.tsx`
- `web/src/components/analytics/revenue-chart.tsx`
- `web/src/types/analytics.ts`

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] All user input sanitized
- [x] Authentication checked on all new endpoints
- [x] Authorization -- correct role/permission guards
- [x] No IDOR vulnerabilities
- [x] File uploads validated (N/A -- no file uploads in this feature)
- [x] Rate limiting on sensitive endpoints (global throttle: 120/min for authenticated users)
- [x] Error messages don't leak internals
- [x] CORS policy appropriate (global config, not modified by this feature)

## Secrets Scan
**Result: CLEAN**

Grepped all new/changed files for API keys, passwords, tokens, Stripe keys (`sk_`, `pk_`), AWS keys (`AKIA`), Google API keys (`AIza`), and GitHub tokens (`ghp_`, `glpat_`). No secrets found.

The `password='testpass123'` in `test_revenue_analytics.py` is a test-only fixture used with `create_user` in Django's test framework -- standard practice, not a leaked credential.

## Injection Vulnerabilities
**None found.**

| Check | Status | Notes |
|-------|--------|-------|
| SQL Injection | PASS | All queries use Django ORM exclusively (`filter()`, `aggregate()`, `annotate()`, `values()`). No raw SQL, `cursor.execute()`, `.extra()`, or string formatting in queries. |
| XSS | PASS | Backend returns JSON data only (no HTML rendering). Frontend uses React (JSX auto-escapes by default). No `dangerouslySetInnerHTML` or `innerHTML` usage. The `revenue-chart.tsx` renders via Recharts (SVG-based), not raw HTML. |
| Command Injection | PASS | No subprocess calls, `os.system()`, or shell commands. |
| Path Traversal | PASS | No file operations in the revenue analytics feature. |

## Auth & Authz Issues
**None found.**

| Check | Status | Details |
|-------|--------|---------|
| Authentication required | PASS | `RevenueAnalyticsView` has `permission_classes = [IsAuthenticated, IsTrainer]`. Global DRF default also requires `IsAuthenticated`. |
| Trainer-only access | PASS | `IsTrainer` permission (in `core/permissions.py`) checks `request.user.is_trainer()` -- validates the user role before allowing access. |
| Row-level security (subscriptions) | PASS | Service queries `TraineeSubscription.objects.filter(trainer=trainer, ...)` -- filters by the authenticated trainer. A trainer cannot see another trainer's subscriptions. |
| Row-level security (payments) | PASS | Service queries `TraineePayment.objects.filter(trainer=trainer, ...)` -- filters by the authenticated trainer. |
| IDOR on subscriber data | PASS | Subscriber list is derived from `active_subs` which is already scoped to `trainer=trainer`. No user-supplied ID is used to fetch subscriber details. |
| IDOR on payment data | PASS | Recent payments list is derived from `TraineePayment.objects.filter(trainer=trainer)`. No user-supplied ID is used. |
| Test coverage for auth | PASS | Tests cover unauthenticated (401), non-trainer role (403), and trainer isolation (trainer A cannot see trainer B's data). |

## Data Exposure Assessment

| Field | Risk | Assessment |
|-------|------|------------|
| `trainee_email` | Low | Trainers legitimately need to see their trainees' emails. This is the same data available in the trainee list. Scoped to trainer's own trainees only. |
| `trainee_id` | Low | Internal IDs are sequential integers. Acceptable because the endpoint is already scoped to the trainer's own data. No risk of enumeration since the ID alone cannot be used to fetch cross-trainer data. |
| Payment `id` | Low | Sequential payment IDs. No endpoint accepts a payment ID to fetch details, so no IDOR risk. |
| `amount` / `mrr` | None | Financial data the trainer needs to see. Properly scoped. |
| Error messages | PASS | View returns generic error messages. DRF handles validation errors without leaking stack traces. No `DEBUG`-dependent error output. |

## Input Validation

| Input | Validation | Assessment |
|-------|-----------|------------|
| `days` query param | `_parse_days_param()` clamps to 1-365, handles `ValueError`/`TypeError` with fallback to default 30 | PASS -- properly bounded, no integer overflow risk |
| Frontend `RevenuePeriod` | TypeScript union type `30 \| 90 \| 365` constrains client-side values | PASS -- defense in depth with backend validation |

## Performance & Availability Concerns

| # | Severity | Issue | Assessment |
|---|----------|-------|------------|
| 1 | Low | Subscriber list is unbounded (no pagination) | For a trainer platform, subscriber counts are typically < 100. If a trainer had 10,000+ subscribers, this could be slow. Current design is acceptable for the product's scale. |
| 2 | Low | Recent payments capped at 10 via `[:10]` | PASS -- properly bounded. |
| 3 | Low | Monthly revenue uses `TruncMonth` aggregate over 12 months | PASS -- bounded time range, efficient DB aggregation. |

## Rate Limiting

Global DRF throttle applies: 120 requests/minute for authenticated users. This is sufficient for an analytics dashboard endpoint that is read-only and uses React Query's `staleTime: 5 * 60 * 1000` (5-minute caching) to prevent excessive requests.

## CSRF

The endpoint uses JWT authentication (via `Authorization: Bearer` header), not session/cookie auth. CSRF protection is not needed for token-based auth because the browser cannot automatically attach the token to cross-origin requests.

## Fixes Applied
None required. No Critical or High security issues were identified.

## Security Score: 9/10

**-1 point:** The subscriber list lacks pagination, which at extreme scale could be used for a minor denial-of-service by a legitimate authenticated trainer. This is a very low risk given the product context (personal trainers with typically < 100 clients) and is not a security vulnerability per se, but a minor hardening opportunity.

## Recommendation: PASS

The Trainer Revenue & Subscription Analytics feature has a clean security posture:

1. **Authentication & authorization are enforced** at both the view layer (`IsAuthenticated + IsTrainer`) and the data layer (all queries filter by `trainer=trainer`).
2. **Row-level security is correct** -- test coverage explicitly validates trainer isolation (trainer A cannot see trainer B's subscriptions or payments).
3. **No injection vectors** -- all queries use Django ORM, no raw SQL. Frontend uses React's automatic XSS protection.
4. **No secrets leaked** -- no hardcoded credentials, API keys, or tokens in any file.
5. **Input validation is solid** -- the `days` parameter is properly clamped and has fallback handling for invalid input.
6. **Error messages are safe** -- no internal details exposed in error responses.
