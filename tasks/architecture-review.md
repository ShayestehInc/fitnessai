# Architecture Review: Ambassador Dashboard Enhancement (Pipeline 25)

## Review Date
2026-02-20

## Files Reviewed
- `backend/ambassador/views.py` (modified — dashboard 12-month earnings, referrals ordering)
- `web/src/components/ambassador/earnings-chart.tsx` (new)
- `web/src/components/ambassador/referral-list.tsx` (rewritten)
- `web/src/components/ambassador/referral-status-breakdown.tsx` (new)
- `web/src/app/(ambassador-dashboard)/ambassador/dashboard/page.tsx` (modified)
- `web/src/hooks/use-ambassador.ts` (modified — keepPreviousData)
- `backend/ambassador/tests/test_dashboard_views.py` (new)

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (aggregate queries are view-appropriate for read-only dashboards)
- [x] Consistent with existing patterns

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes or migrations |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | Uses existing indexes on `referred_at`, `ambassador + status` |
| No N+1 query patterns | PASS | `select_related('trainer', 'trainer__subscription')` on referral queries; aggregate queries use single DB round-trip |

## API Design
- Dashboard endpoint returns 12 months with zero-fill, using `amount` key — consistent with frontend type
- Referrals endpoint uses DRF `PageNumberPagination` format (`count`, `next`, `previous`, `results`) — standard
- Status filter via `?status=` query param with server-side uppercasing — defensive

## Frontend Patterns
- EarningsChart follows AdherenceBarChart pattern (Recharts + ResponsiveContainer)
- ReferralList uses React Query with `keepPreviousData` — correct v5 pattern
- Components are well-decomposed: ReferralCard, StatusBadge, ReferralListSkeleton extracted
- State management: `useState` for filter/page/search — correct for ephemeral UI state

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| — | — | No new scalability concerns | All queries are bounded and indexed |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| — | None introduced | — | — |

## Architecture Score: 9/10
## Recommendation: APPROVE
