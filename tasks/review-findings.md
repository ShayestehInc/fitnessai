# Code Review: Trainer Revenue & Subscription Analytics

## Review Date
2026-02-20

## Files Reviewed
- backend/trainer/services/revenue_analytics_service.py (new)
- backend/trainer/views.py (modified)
- backend/trainer/urls.py (modified)
- web/src/types/analytics.ts (modified)
- web/src/hooks/use-analytics.ts (modified)
- web/src/lib/constants.ts (modified)
- web/src/components/analytics/revenue-section.tsx (new)
- web/src/components/analytics/revenue-chart.tsx (new)
- web/src/app/(dashboard)/analytics/page.tsx (modified)

## Critical Issues (must fix before merge)
None.

## Major Issues (should fix)
| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 1 | revenue-section.tsx:13 | Unused import `CreditCard` | Remove import | **FIXED** |
| 2 | revenue_analytics_service.py:87-89 | Extra DB query — `aggregate()` then `count()` are 2 separate queries | Combine into single `aggregate(total=Sum('amount'), count=Count('id'))` | **FIXED** |

## Minor Issues (nice to fix)
None remaining.

## Security Concerns
- Row-level security: `trainer=trainer` filter on all querysets — verified correct.
- Permission classes: `[IsAuthenticated, IsTrainer]` — matches existing analytics views.
- No user input injection vectors (days param is clamped by `_parse_days_param`).

## Performance Concerns
- 5 DB queries total: 1 aggregate (MRR + count), 1 aggregate (period revenue), 1 monthly breakdown, 1 subscriber list + iteration, 1 recent payments. Acceptable for analytics.
- `select_related('trainee')` on subscriber and payment queries prevents N+1.
- Monthly breakdown uses `TruncMonth` aggregation — efficient single query.

## Quality Score: 9/10
## Recommendation: APPROVE
