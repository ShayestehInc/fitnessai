# Architecture Review: Web Dashboard Full Parity + UI/UX Polish + E2E Tests (Pipeline 19)

## Review Date: 2026-02-19

## Architectural Alignment
- [x] Follows existing layered architecture (Page -> Hook -> apiClient -> API)
- [x] Types in `/types/`, hooks in `/hooks/`, components in `/components/`, pages in `/app/`
- [x] No business logic in page components (pages delegate to hooks and components)
- [x] Consistent with existing patterns (TanStack React Query, shadcn/ui, Tailwind CSS)

## Layering Assessment
| Layer | Pattern | Status |
|-------|---------|--------|
| Pages (app/) | Minimal wrapper: fetch data via hooks, render components | GOOD -- all pages follow this |
| Hooks (hooks/) | useQuery/useMutation wrappers with query invalidation | GOOD -- consistent pattern |
| Components (components/) | Stateful UI with local useState + hook-provided data | GOOD -- proper separation |
| API Client (lib/api-client) | Centralized fetch with JWT auth, refresh, error types | GOOD -- single responsibility |
| Types (types/) | Interface definitions matching API contract | GOOD -- properly typed |
| Constants (lib/constants) | Centralized API URLs, token keys, cookie names | GOOD -- no magic strings |

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Types match API contract | FIXED | StripeConnectSetup was casting `is_connected` but API returns `has_account` |
| Consistent naming conventions | PASS | snake_case for API fields (matching Django), camelCase for local variables |
| PaginatedResponse used correctly | PASS | After R1 fix, all paginated hooks unwrap `.results` |
| Type reuse vs duplication | PASS | Shared types in `/types/ambassador.ts`, separate admin vs self-service types |

## API URL Organization
| Area | Count | Pattern |
|------|-------|---------|
| Auth | 3 | Constants |
| Trainer | 18 | Constants + functions for ID params |
| Admin | 24 | Constants + functions for ID params |
| Ambassador | 7 | Constants |
| Feature/Calendar | 8 | Constants + functions |
| **Total** | **60** | Consistent pattern |

All API URLs centralized in `lib/constants.ts`. No hardcoded URLs in components or hooks. Function-based URL builders for parameterized endpoints.

## Query Key Strategy
| Hook Group | Key Pattern | Invalidation Strategy |
|------------|------------|----------------------|
| Ambassador list | ["admin-ambassadors", page, search, status] | Broad invalidation on mutations |
| Ambassador detail | ["admin-ambassador", id] | Targeted invalidation |
| Self-service dashboard | ["ambassador-dashboard"] | Targeted invalidation |
| Referral code | ["ambassador-referral-code"] | Targeted + dashboard cascade |
| Leaderboard settings | ["leaderboard-settings"] | Global invalidation |

Keys are descriptive and hierarchical. Mutations invalidate the right queries. No stale data issues identified.

## Component Architecture
| Pattern | Implementation | Assessment |
|---------|---------------|------------|
| Route groups | (dashboard), (admin-dashboard), (ambassador-dashboard), (auth) | GOOD -- clean separation |
| Shared components | EmptyState, ErrorState, PageHeader, PageTransition, StatCard | GOOD -- DRY |
| Dialog extraction | Form dialogs as separate components | GOOD -- testable, reusable |
| Skeleton components | Per-feature content-shaped skeletons | GOOD -- not generic spinners |
| Nav links | Separate files per role (nav-links.ts, admin-nav-links.ts, ambassador-nav-links.ts) | GOOD -- clean split |

## Scalability Concerns
| # | Area | Issue | Severity | Recommendation |
|---|------|-------|----------|----------------|
| 1 | Ambassador list | Only fetches page 1, no pagination UI | Low | Add pagination component when list grows |
| 2 | Feature requests | Client-side status filtering of full list | Low | Acceptable for V1, add server-side filtering when volume grows |
| 3 | Exercise bank | Client-side search with debounce | Low | Currently fine, server-side search available if needed |

## Technical Debt Assessment
| # | Description | Severity | Impact |
|---|-------------|----------|--------|
| 1 | StripeConnectSetup had incorrect type cast (now fixed) | Fixed | Was using `is_connected` instead of `has_account` |
| 2 | Impersonation flow incomplete (no token swap) | Documented | Deferred to backend integration |
| 3 | Ambassador list "filtered" variable redundant | Cosmetic | No functional impact |
| 4 | Some hooks lack error boundaries at the page level | Low | ErrorState covers most cases |

## Fixes Applied
1. **StripeConnectSetup type alignment** -- Removed unsafe cast, now uses `data?.has_account` and `data?.payouts_enabled` directly from the typed hook return value

## Architecture Score: 8/10
## Recommendation: APPROVE

The architecture is clean and consistent. The layered pattern (Page -> Hook -> apiClient -> API) is followed throughout all 124 files. Types are well-organized and shared appropriately. The PaginatedResponse pattern is used correctly after R1 fixes. Query keys are descriptive and invalidation is targeted. The one type mismatch in StripeConnectSetup has been fixed. The codebase will scale well for the next set of features.
