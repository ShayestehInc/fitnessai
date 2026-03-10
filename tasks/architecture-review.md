# Architecture Review: v6.5 ExerciseCard + DecisionLog + UndoSnapshot

## Review Date: 2026-03-09

## Files Reviewed
- `backend/workouts/models.py` — Exercise v6.5 fields, DecisionLog, UndoSnapshot models
- `backend/workouts/serializers.py` — ExerciseSerializer, DecisionLogSerializer, UndoSnapshotSerializer
- `backend/workouts/views.py` — ExerciseViewSet filter updates, DecisionLogViewSet
- `backend/workouts/urls.py` — Router registration
- `backend/workouts/services/decision_log_service.py` — DecisionLogService
- `backend/workouts/management/commands/backfill_exercise_tags.py` — Tag backfill command

## Architectural Alignment
- [x] Follows existing layered architecture (views handle request/response, service handles business logic)
- [x] Models in correct locations (DecisionLog and UndoSnapshot in workouts/models.py)
- [x] No business logic in views (undo logic delegated to DecisionLogService)
- [x] Consistent with existing patterns (ModelViewSet, ReadOnlyModelViewSet, serializer validation, service layer)

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | All new Exercise fields have `default=list/dict, blank=True`. Legacy `muscle_group` field preserved. No existing columns removed or renamed. |
| Migrations reversible | PASS | New fields are nullable/have defaults; dropping them would not lose existing data. New tables (DecisionLog, UndoSnapshot) can be dropped independently. |
| Indexes added for new queries | PASS | GinIndex on `pattern_tags` for overlap queries. B-tree indexes on `stance`, `plane`, `primary_muscle_group` for equality filters. DecisionLog indexed on `decision_type`, `actor_type`, `timestamp`, `actor`. |
| No N+1 query patterns | PASS | `ExerciseViewSet.get_queryset()` uses `select_related('created_by')`. `DecisionLogViewSet.get_queryset()` uses `select_related('actor', 'undo_snapshot')`. |

## Positive Architecture Decisions

1. **DecisionLog as a service, not a mixin.** `DecisionLogService` is a standalone static service with `@transaction.atomic`. Any part of the codebase can log decisions without inheriting from a base class. Clean separation.

2. **UndoSnapshot stores full state, not diffs.** Full before/after snapshots are simpler to reason about and safer to apply. The tradeoff is storage, but decision logs are low-volume.

3. **Undo does not auto-restore domain objects.** The service returns `before_state` but leaves actual restoration to the caller. This is the right design -- different decision types (exercise swap, progression, deload) require different restoration logic. Forcing a generic restore would be fragile.

4. **DecisionResult dataclass return type.** Follows the project rule of never returning raw dicts from services.

5. **Backfill command with `--dry-run`.** Uses `iterator(chunk_size=500)` for memory efficiency and `bulk_update(batch_size=200)` for DB efficiency. Idempotent (skips exercises that already have tags).

6. **ReadOnlyModelViewSet for DecisionLog.** Audit logs should never be edited/deleted through the API. The `undo` action creates a NEW log entry rather than modifying the original.

7. **Trainer queryset uses subquery.** `DecisionLogViewSet.get_queryset()` uses `User.objects.filter(parent_trainer=user).values('id')` as a subquery rather than materializing trainee IDs into a Python list. Scales well with large trainee counts.

## Minor Observations (Not Issues)

| # | Area | Observation | Recommendation |
|---|------|-------------|----------------|
| 1 | ExerciseViewSet filters | Filter logic is ~60 lines of repetitive query param validation in `get_queryset()`. | Consider extracting to a `django-filter` FilterSet in the future to reduce boilerplate. Not urgent -- current approach is explicit and correct. |
| 2 | DecisionLog.decision_type | Free-text CharField, not a TextChoices enum. | Intentional -- decision types will grow as features are added (exercise_swap, progression, deload_rewrite, load_prescription, etc.). An enum would require a migration for each new type. Free text with `reason_codes` ArrayField provides flexibility. Current approach is fine. |
| 3 | UndoSnapshot.before_state/after_state | JSONField with no schema validation. | Acceptable for an audit/undo system where the shape varies by decision type. Schema validation would require a polymorphic approach that adds complexity without proportional benefit. |

## Scalability Concerns

| # | Area | Status | Notes |
|---|------|--------|-------|
| 1 | DecisionLog growth | OK | Paginated (50/page, max 200). Indexed on timestamp for range queries. UUID primary keys avoid sequential ID enumeration. |
| 2 | Backfill command | OK | Uses `iterator()` to avoid loading all exercises into memory. `bulk_update` with batch_size. |
| 3 | Exercise filter queries | OK | GinIndex on `pattern_tags` supports `__overlap` efficiently. B-tree indexes on `stance`, `plane`, `primary_muscle_group`. |

## Technical Debt Introduced

| # | Description | Severity | Notes |
|---|-------------|----------|-------|
| None | No new technical debt introduced. | N/A | The implementation follows existing patterns cleanly. Legacy `muscle_group` field is preserved for backward compatibility with a clear migration path via the backfill command. |

## Architecture Score: 9/10
## Recommendation: APPROVE

The implementation is well-structured, follows the project's layered architecture, and makes sound design decisions (full-state snapshots, service-layer delegation, read-only ViewSet for audit logs). Data model changes are fully backward-compatible. No architectural concerns.
