# Code Review: v6.5 ExerciseCard + DecisionLog + UndoSnapshot

## Review Date
2026-03-09

## Files Reviewed
- `backend/workouts/models.py` (Exercise v6.5 fields, DecisionLog, UndoSnapshot)
- `backend/workouts/serializers.py` (ExerciseSerializer, DecisionLogSerializer, UndoSnapshotSerializer)
- `backend/workouts/views.py` (ExerciseViewSet filters, DecisionLogViewSet)
- `backend/workouts/urls.py`
- `backend/workouts/services/decision_log_service.py`
- `backend/workouts/management/commands/backfill_exercise_tags.py`
- `backend/config/settings.py` (django.contrib.postgres confirmed in INSTALLED_APPS, line 34)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `views.py:3279` | **IDOR / over-broad scoping for trainers in DecisionLogViewSet.** The trainer query includes `Q(actor__isnull=True, actor_type=DecisionLog.ActorType.SYSTEM)` which leaks ALL system-level decisions to every trainer, including decisions about other trainers' trainees. A system decision for Trainer-B's trainee would appear in Trainer-A's list. | Add `context__plan_id__in=<trainer's plan ids>` or link DecisionLog to a trainee FK and filter by `parent_trainer`. At minimum, remove the blanket system-decision clause or scope it via context data. |
| C2 | `views.py:3281-3286` | **IDOR for trainees in DecisionLogViewSet.** Same problem but worse: trainees also see ALL system decisions (`actor__isnull=True, actor_type=SYSTEM`) regardless of whether those decisions are about them. A trainee can enumerate system decisions about other trainees. | Trainees should only see decisions where `actor=user` OR decisions linked to their own resources (via context). The system-decision fallback must be scoped. |
| C3 | `services/decision_log_service.py:119-169` | **undo_decision does not actually restore state.** It marks the snapshot as reverted and logs an undo entry, but it never applies `before_state` back to the actual domain objects (Program schedule, Exercise, etc.). The undo endpoint is effectively a no-op that claims success. This is a data integrity issue -- trainers will believe the undo worked. | Either: (a) implement actual state restoration dispatched by `scope`, or (b) rename this to `mark_decision_reverted` and clearly document that callers must apply the state change themselves, returning `before_state` in the response so the caller can act on it. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `models.py:1835-1836` | **`options_considered` field uses `default=dict` but docstring says it should be a list** (`[{option, score, reasons}, ...]`). The service also defaults to `{}` (line 105). This type mismatch will cause runtime errors or confusing data when consumers expect a list. | Change to `default=list` and update the service fallback from `options_considered or {}` to `options_considered or []`. |
| M2 | `views.py:117-207` | **ExerciseViewSet.get_queryset() missing `select_related('created_by')`.** The serializer has `created_by_email = CharField(source='created_by.email')` which triggers an N+1 query for every exercise in a list response. With hundreds of exercises, this is a significant performance hit. | Add `.select_related('created_by')` to all queryset branches. |
| M3 | `views.py:209-215` | **Trainees and admins can create exercises via ExerciseViewSet.** `perform_create` only checks `is_trainer()` -- if the user is a trainee, it falls through to `save(is_public=True)`, allowing any trainee to create public system exercises. This is a privilege escalation. | Add explicit role checks. Only trainers (custom) and admins (public) should create exercises. Return 403 for trainees. |
| M4 | `views.py:3266-3307` | **DecisionLogViewSet has no default ordering.** The model has `ordering = ['-timestamp']` but the queryset applies no explicit ordering and adds filters. Depending on the database optimizer, results could be inconsistent. Also, the `PageNumberPagination` class has no `page_size` set, which means it falls back to the global default. If no global default is set, pagination won't work. | Add `.order_by('-timestamp')` to the queryset. Set `page_size` on the pagination class or verify the global `PAGE_SIZE` is configured. |
| M5 | `management/commands/backfill_exercise_tags.py:122-167` | **Backfill command loads all exercises into memory at once** (`Exercise.objects.all()`) and saves them one-by-one in a loop. For large exercise libraries this is both memory-intensive and creates N individual database writes. | Use `.iterator()` for the read, batch with `bulk_update()`, and wrap in a transaction. Also, the `.count()` call on line 166 fires a second full-table query. |
| M6 | `management/commands/backfill_exercise_tags.py:157-162` | **Backfill always writes `primary_muscle_group` and `muscle_contribution_map` in update_fields even when only `pattern_tags` changed.** If `primary_muscle_group` wasn't changed by this iteration, the existing (possibly manually set) value is fine, but the intent is unclear. Also `updated_at` is `auto_now=True` which means it auto-updates on `.save()` regardless -- including it in `update_fields` is fine but redundant. | Track which fields actually changed per exercise and only include those in `update_fields`. |
| M7 | `views.py:3299-3305` | **Date filters `date_from` and `date_to` are not validated.** If a user passes `date_from=not-a-date`, Django will raise an unhandled `ValidationError` which surfaces as a 500 error rather than a clean 400. | Parse and validate date strings, returning 400 on invalid input. |
| M8 | `views.py:3293` | **`decision_type` filter has no validation.** Any arbitrary string is passed directly to the ORM filter. While not SQL injection (ORM is safe), it means no feedback for typos. Similarly `actor_type` is unvalidated. | Validate against `DecisionLog.ActorType.choices` for `actor_type`. For `decision_type`, either document valid values or validate against a known set. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `serializers.py:40` | `created_by_email` will raise `AttributeError` when `created_by` is null (system exercises). DRF won't catch this for `CharField` with a `source` -- it needs a `default=None` or should be `SerializerMethodField`. | Add `default=None` to the `created_by_email` field, or use `SerializerMethodField` with a null check. |
| m2 | `models.py:1800` | `actor_type` max_length=10 but the longest ActorType value is `'trainer'` (7 chars). Fine, but if you add e.g. `'auto_system'` in the future it will fail. Consider max_length=20 for headroom. | Increase to `max_length=20`. |
| m3 | `serializers.py:128` | `read_only_fields = fields` -- this is a common DRF pattern but `fields` is evaluated at class creation time, which can be fragile if inherited. Works fine here but worth noting. | No action needed; just a note. |
| m4 | `views.py:3310` | `pk: str = None` should be `pk: str | None = None` per project typing conventions. | Update the type hint. |
| m5 | `views.py:3273-3274` | `list(User.objects.filter(parent_trainer=user).values_list('id', flat=True))` materializes all trainee IDs into a Python list. For trainers with thousands of trainees, use a subquery instead. | Use `Subquery` or pass the queryset directly to the `__in` filter (Django evaluates it as a subquery). |
| m6 | `models.py:292-296` | `swap_seed_ids` uses `default=dict` but the help text describes it as having list values (`recommended_same_muscle_ids[]`). The field name suggests IDs, but the type is a generic JSONField dict. This is fine but inconsistent naming -- `swap_seeds` would be clearer. | Minor naming concern. No action needed. |
| m7 | `services/decision_log_service.py:53` | `actor_type: str` -- should be typed as `DecisionLog.ActorType` (or a Literal) rather than bare `str` for type safety. Same for `undo_scope: str | None`. | Use the enum type from the model. |
| m8 | `views.py:165-168` | `pattern_tags` filter uses `__overlap` (ANY match) rather than `__contains` (ALL match). The choice is valid but not documented. A trainer filtering by `['horizontal_push', 'knee_dominant']` might expect exercises matching BOTH tags, not either. | Document the behavior or add a `pattern_tags_match` param (e.g., `any` vs `all`). |
| m9 | `models.py:320-328` | Indexes for Exercise are good but missing a GIN index on `pattern_tags` ArrayField. The `__overlap` filter in the view (line 168) will do a sequential scan without a GIN index. | Add `GinIndex(fields=['pattern_tags'])` to the Meta indexes. Requires `django.contrib.postgres` (already installed). |

---

## Security Concerns

1. **C1/C2 above are IDOR vulnerabilities** -- trainers and trainees can see decision logs they shouldn't have access to via the system-decision leak.
2. **M3: Trainee privilege escalation** -- trainees can create public exercises that all users see.
3. The undo endpoint (line 3309) correctly restricts to trainers/admins. Good.
4. ExerciseSerializer exposes `created_by` (integer FK) which reveals user IDs. Low risk but could use `write_only=True` on the `created_by` field and rely on `created_by_email` for reads.
5. No rate limiting on the undo endpoint -- a malicious user could spam undo requests. Low severity.

## Performance Concerns

1. **M2: N+1 on ExerciseViewSet** -- missing `select_related('created_by')`.
2. **m5: Trainee ID materialization** in DecisionLogViewSet.
3. **m9: Missing GIN index** on `pattern_tags` for `__overlap` queries.
4. **M5: Backfill command** loads everything into memory and does single-row saves.
5. DecisionLogViewSet correctly uses `select_related('actor', 'undo_snapshot')` on line 3288. Good.

---

## Quality Score: 5/10

The feature is architecturally sound -- models are well-designed, the service layer correctly separates business logic, the serializer validation on tag fields is thorough, and the DecisionLog/UndoSnapshot pattern is extensible. However, there are two IDOR/scoping vulnerabilities (C1, C2), a fundamentally broken undo that doesn't actually restore state (C3), and a privilege escalation allowing trainees to create public exercises (M3). These are production-safety issues that must be fixed.

## Recommendation: BLOCK

Blocking on:
- **C1 + C2:** DecisionLog IDOR -- trainers and trainees see other users' system decisions
- **C3:** undo_decision is a no-op that claims success without restoring actual state
- **M3:** Trainees can create public exercises (privilege escalation)

After these are fixed, the remaining Major issues (M1, M2, M4-M8) should be addressed to bring the score to 7+/10 for an APPROVE.
