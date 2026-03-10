# Code Review: Workload Engine — Aggregation, Trends, and Facts (Pipeline 61)

## Review Date
2026-03-09

## Files Reviewed
- `backend/workouts/services/workload_service.py` (full, 721 lines)
- `backend/workouts/models.py` (WorkloadFactTemplate, lines 2144-2200)
- `backend/workouts/serializers.py` (WorkloadFactTemplateSerializer, lines 1301-1317)
- `backend/workouts/views.py` (WorkloadFactTemplateViewSet + WorkloadViewSet, lines 3635-3891)
- `backend/workouts/urls.py` (full, 59 lines)
- `tasks/next-ticket.md`

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `workload_service.py:631-634` | **WorkloadFactService ignores trainer scoping.** `select_and_render()` queries ALL active templates regardless of who created them. A trainer's custom fact templates leak to every trainee on the platform. This violates row-level security and tenant isolation. | Pass `trainee_id` or `trainer_id` into `select_and_render()`. Filter templates to `Q(created_by__isnull=True) | Q(created_by=trainee.parent_trainer)` — matching the ViewSet's queryset logic. Update all call sites (lines 161, 308) to pass the trainer context. |
| C2 | `workload_service.py:694-713` | **Template injection via `str.format_map()`.** Trainer-authored `template_text` is rendered with `str.format_map()`. While `SafeFormatDict` handles missing keys, `format_map` can access object attributes via format spec (e.g., `{exercise_name.__class__.__init__.__globals__}`). Since trainers control `template_text`, this is a real injection vector that could leak internal Python object info. | Replace `str.format_map()` with `string.Template.safe_substitute()` which only supports `$variable` substitution and has no attribute access. Alternatively, use a regex-based replacer: `re.sub(r'\{(\w+)\}', lambda m: safe.get(m.group(1), ''), template_text)`. |
| C3 | `workload_service.py:636` | **Unbounded queryset iteration for fact selection.** `for template in templates:` loads ALL matching templates into memory with no limit. If a trainer creates hundreds of templates (or an attacker floods via API), this is an unbounded loop consuming memory and CPU. | Add a reasonable limit: `.order_by('priority')[:50]` or use `.iterator()` with a hard cap. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `workload_service.py:150-152, 252, 362-363` | **Mixed unit edge case not handled (ticket edge case #3).** The implementation takes `unit` from the first set and applies it to the entire aggregate. If a trainee has sets in both `lb_reps` and `kg_reps` in the same session, the total workload is a meaningless sum of incompatible units. The ticket explicitly requires: "aggregate separately by unit, flag mixed." | Either: (a) group aggregation by `set_workload_unit` and return per-unit totals, or (b) convert to canonical unit before summing, or (c) at minimum add a `mixed_units: bool` flag to the response. The ticket requires (a) or at least a flag. |
| M2 | `workload_service.py:420, 456` | **Double full-queryset iteration in `compute_weekly_workload`.** `_compute_muscle_distribution` and `_compute_pattern_distribution` each execute the full queryset via `sets.iterator(chunk_size=500)`. Combined with aggregation queries above, `compute_weekly_workload` issues ~6 DB round-trips. | Prefetch sets into a list once and pass the list to both methods. Or combine both distributions into a single iteration pass. |
| M3 | `views.py:3668-3677` | **`perform_update` calls `self.get_object()` redundantly.** DRF already calls `get_object()` before `perform_update`. Calling it again is a redundant DB query and introduces a TOCTOU race — the object fetched inside `perform_update` could differ from what DRF is saving. | Use `serializer.instance` instead of `self.get_object()`. |
| M4 | `views.py:3657-3659` | **Trainee with no `parent_trainer` sees unexpected results.** If `user.parent_trainer` is `None`, the filter `Q(created_by=user.parent_trainer)` becomes `Q(created_by=None)`, matching ALL system defaults (already matched by the first Q) plus any template where `created_by` is null. Not a security hole but produces confusing duplicate results. | Guard: if `user.parent_trainer is None`, only return `Q(created_by__isnull=True)`. |
| M5 | `views.py:3761-3772, 3804-3817, 3845-3856, 3881-3891` | **Manual dict serialization violates project conventions.** All four `WorkloadViewSet` actions manually construct Response dicts from dataclass fields. This violates `.claude/rules/datatypes.md` which requires `rest_framework_dataclasses` for API responses. It also means no schema validation on responses, inconsistent serialization, and duplicated code. | Create proper serializers: `ExerciseWorkloadSerializer`, `SessionWorkloadSerializer`, `WeeklyWorkloadSerializer`, `WorkloadTrendSerializer` using `rest_framework_dataclasses`. |
| M6 | `views.py:3872` | **`weeks_back` allows 0 and negative values.** `min(int(weeks_str), 52)` caps at 52 but doesn't prevent `weeks_back=0` (useless, returns one entry) or negative values (computes future dates in `_get_weekly_deltas`). | Use `max(1, min(int(weeks_str), 52))` to enforce a valid range. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `workload_service.py:14` | `from typing import Any` used in 6 places. Project rules require strict typing; `dict[str, Any]` should be narrowed. | Use `dict[str, str \| Decimal \| None]` for context, or a typed `FactContext` dataclass. |
| m2 | `workload_service.py:48` | `top_exercises: list[dict[str, Any]]` in `SessionWorkload` dataclass. Raw dicts violate "never return dict" rule. | Create a `TopExercise` dataclass: `exercise_name: str, workload: Decimal, unit: str`. |
| m3 | `workload_service.py:374` | `daily_breakdown` values are `str(d['workload'])` — Decimal-to-string conversion happens in the service layer. | Keep as `Decimal` in the dataclass; serialize at the view/serializer layer. |
| m4 | `views.py:3663-3664, 3671-3672, 3681-3682` | `from rest_framework.exceptions import PermissionDenied` imported inline in 3 methods. | Move to module-level imports. |
| m5 | `serializers.py:1306-1317` | `condition_rules` JSONField has no validation. A trainer could submit arbitrary JSON with unsupported keys that silently do nothing. | Add `validate_condition_rules()` method that whitelists allowed keys: `min_workload`, `max_workload`, `has_comparison`, `delta_positive`, `min_sets`, `always`. |
| m6 | `workload_service.py:584` | `_get_weekly_deltas` makes N+1 DB queries — one `_rolling_workload` call per week. For `weeks_back=52`, that's 53 queries. | Consider a single grouped query and compute deltas in Python. |
| m7 | `workload_service.py:81` | `weekly_deltas: list[dict[str, Any]]` in `WorkloadTrend` dataclass. Same dict-not-dataclass violation. | Create a `WeeklyDelta` dataclass. |

## Security Concerns

1. **Template injection (C2):** `str.format_map()` with trainer-controlled template text allows Python attribute access via format specs. Severity: Medium-High.
2. **Fact template scoping (C1):** Cross-trainer data leakage through unscoped fact templates. Templates are "just text" but still violate tenant isolation.
3. **Row-level security in `_resolve_trainee()` is correctly implemented** — trainees see own data, trainers only their trainees, admins see all. No IDOR here.
4. **No rate limiting** on compute-heavy endpoints (trends with `weeks_back=52` triggers 53 DB queries). Not critical for now but worth noting.

## Performance Concerns

1. **Trend endpoint:** `weeks_back=52` triggers 53 individual DB queries via `_rolling_workload`. Each is simple but the volume adds up.
2. **Muscle/pattern distribution:** Full Python-side iteration of all sets. For high-volume trainees (thousands of sets/week), this will be slow. Could use conditional aggregation at the DB level.
3. **No caching:** All computations are on-read. Ticket says "optimize later" which is acceptable for now, but should be tracked.

## Quality Score: 5/10

**Rationale:** The architecture is fundamentally sound — clean service layer separation, proper dataclasses for return types, good use of Django ORM aggregation, well-designed fact selection algorithm, and correct row-level security in the ViewSet. However:
- The template injection vulnerability (C2) is a real security risk
- The fact template scoping leak (C1) breaks tenant isolation
- The completely unhandled mixed-units edge case (M1) contradicts an explicit ticket requirement
- Manual dict serialization in views (M5) violates a mandatory project convention
- The unbounded template iteration (C3) is a denial-of-service vector

The happy path works well, but the implementation doesn't meet its own ticket's edge case requirements or the project's mandatory coding conventions.

## Recommendation: REQUEST CHANGES

**Blocking items that must be fixed:**
1. C1 — Scope fact template queries by trainer (security)
2. C2 — Replace `str.format_map()` with safe template rendering (security)
3. C3 — Cap template iteration (reliability)
4. M1 — Handle mixed units per ticket requirement (correctness)
5. M5 — Use `rest_framework_dataclasses` serializers per project rules (convention)
