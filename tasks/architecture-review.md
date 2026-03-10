# Architecture Review: Pipeline 60 — Max/Load Engine (LiftSetLog + LiftMax)

## Review Date
2026-03-09

## Files Reviewed
- `backend/workouts/services/max_load_service.py`
- `backend/workouts/views.py` (LiftSetLogViewSet, LiftMaxViewSet)
- `backend/workouts/serializers.py` (LiftSetLogSerializer, LiftMaxSerializer, LiftMaxPrescribeSerializer)
- `backend/workouts/models.py` (LiftSetLog, LiftMax)
- `backend/workouts/urls.py`
- `backend/workouts/migrations/0020_liftmax_liftsetlog.py`

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (FIXED — see below)
- [x] Consistent with existing patterns (ViewSet + Service + Model)

### What's Good
1. **Service layer is well-structured.** `MaxLoadService` is a pure computation class with clear dataclass returns (`E1RMEstimate`, `LoadPrescription`). No Django ORM leakage in the math methods. The `update_max_from_set` correctly uses `@transaction.atomic` and `select_for_update()` for race-condition safety.
2. **Models are clean.** `LiftSetLog.save()` auto-computes canonical load and workload — keeps derived data consistent without relying on the caller. The `Meta` classes have proper indexes and unique constraints.
3. **Row-level security is correct.** Both ViewSets filter by role (admin/trainer/trainee) in `get_queryset()` with subqueries for trainer access. The prescribe endpoint explicitly checks `parent_trainer_id` before allowing cross-trainee access.
4. **Pagination is bounded.** Both ViewSets use `PageNumberPagination` with `max_page_size=200`.
5. **Immutable set logs.** `LiftSetLogViewSet` deliberately omits Update/Delete mixins to preserve audit integrity — correct architectural decision.
6. **History trimming.** `MAX_HISTORY_ENTRIES=200` prevents unbounded JSONField growth.

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | New tables, no existing schema modifications |
| Migrations reversible | PASS | CreateModel is auto-reversible |
| Indexes added for new queries | PASS | 4 indexes on LiftSetLog covering all query patterns; 2 on LiftMax plus implicit unique constraint index |
| No N+1 query patterns | PASS | Both ViewSets use `select_related('exercise', 'trainee')` |
| UUID primary keys | PASS | Consistent with other models (ProgressPhoto, etc.) |
| JSONField for history | PASS | Appropriate — append-only arrays with bounded size |

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | LiftSetLog unit query in prescribe | The unit-resolution query (`order_by('-created_at').values_list(...)`) has an index on `(trainee, exercise)` but not `(trainee, exercise, created_at)`. For trainees with thousands of sets per exercise, this could be slow. | MINOR — acceptable for now. If this becomes a bottleneck, add a composite index or cache the preferred unit on LiftMax. |
| 2 | Trainer subquery pattern | `User.objects.filter(parent_trainer=user).values('id')` is used as a subquery, which is efficient — PostgreSQL evaluates as `IN (SELECT ...)`. No N+1 risk. | No action needed. |

## Issues Found and Fixed

### 1. Business logic in prescribe view (FIXED)
**Severity:** Major (layering violation)
**Before:** The `prescribe` action in `LiftMaxViewSet` contained business logic — unit resolution from `LiftSetLog`, TM validation, and prescription assembly — directly in the view.
**After:** Extracted `prescribe_for_trainee()` classmethod on `MaxLoadService` that handles the full prescription flow. The view now delegates to the service and only handles HTTP request/response. Extended `LoadPrescription` dataclass with optional `exercise_id` and `exercise_name` fields so the service can return all data the view needs without extra queries.

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `LiftMaxPrescribeSerializer` inherits from `serializers.Serializer[None]` — the `[None]` type parameter is unusual and may confuse tooling. | Low | Consider using `serializers.Serializer` without type parameter, or use a proper input type. |
| 2 | `prescribed_load` returned as string in API response (not native number). | Low | Consistent with how other Decimal fields are serialized in this codebase, but could use a response serializer for type safety. |

## Technical Debt Reduced
- Prescribe endpoint now follows the same service-layer pattern as `update_max_from_set`, making the codebase more consistent.

## Architecture Score: 9/10

Strong implementation. Clean layering with the service refactor applied, proper data model design with indexes and constraints, bounded queries, race-condition handling via `select_for_update`, and immutable audit records. The only deductions are for the minor layering fix that was needed and the low-severity debt items noted above.

## Recommendation: APPROVE
