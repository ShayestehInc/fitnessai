# Architecture Review: Full Trainer→Trainee Impersonation Token Swap (Pipeline 27)

## Review Date
2026-02-20

## Architectural Alignment
- [x] Follows existing layered architecture (components → hooks → apiClient → backend)
- [x] Models/schemas in correct locations (types in types/, hooks in hooks/, components in components/)
- [x] No business logic in views/routers — all frontend
- [x] Consistent with existing patterns (mirrors admin impersonation pattern exactly)

## Pattern Consistency
| Pattern | Admin Impersonation | Trainer Impersonation | Consistent? |
|---------|--------------------|-----------------------|-------------|
| SessionStorage key | `fitnessai_impersonation` | `fitnessai_trainer_impersonation` | Yes (unique keys) |
| State shape | `{adminAccessToken, adminRefreshToken, trainerEmail}` | `{trainerAccessToken, trainerRefreshToken, traineeId, traineeName}` | Yes (parallel structure) |
| Token swap flow | Save → Set → Cookie → Navigate | Save → Set → Cookie → Navigate | Yes (identical flow) |
| End impersonation | API call → Restore → Clear → Navigate | API call → Restore → Clear → Navigate | Yes (identical flow) |
| Error handling | Try/catch, still restore on failure | Try/catch, still restore on failure | Yes |
| Banner style | Amber, AlertTriangle, End button | Amber, AlertTriangle, End button | Yes |
| Navigation | Hard navigate (window.location.href) | Hard navigate (window.location.href) | Yes |

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No backend changes |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | Uses existing endpoints |
| No N+1 query patterns | OK | 4 independent queries, no nesting |

## Frontend Architecture
- New `(trainee-view)` route group follows Next.js convention for route grouping
- Types in `trainee-view.ts` — isolated from trainer types, avoids polluting existing type files
- Hooks in `use-trainee-view.ts` — separate from trainer hooks, clear purpose
- Components in `components/trainee-view/` — scoped directory, matches feature
- Auth-provider modification is minimal — single boolean check, doesn't change existing behavior

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| — | — | No concerns. 4 independent API calls, standard React Query caching. | — |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| — | None. The implementation reduces debt by replacing the no-op impersonation handler with a working one. | — | — |

## Architecture Score: 9/10
## Recommendation: APPROVE
