# Ship Decision: ExerciseCard Rich Tagging + DecisionLog + UndoSnapshot Foundation (v6.5)

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 8/10

## Summary
The v6.5 foundation layer is production-ready. All ExerciseCard tag fields, DecisionLog, and UndoSnapshot models are properly defined with correct choices, defaults, indexes, and row-level security. The DecisionLogService uses dataclass returns and atomic transactions, the backfill command uses bulk_update with iterator, and the undo endpoint has proper scope checks preventing IDOR.

---

## Acceptance Criteria Verification

### ExerciseCard Enrichment: ALL PASS
- [x] `pattern_tags` ArrayField with PatternTag choices (16 movement patterns) — models.py:197
- [x] `athletic_skill_tags` ArrayField with AthleticSkillTag choices (19 skills) — models.py:204
- [x] `athletic_attribute_tags` ArrayField with AthleticAttributeTag choices (10 attributes) — models.py:211
- [x] `muscle_contribution_map` JSONField — models.py:233
- [x] `stance` CharField with 13 Stance choices — models.py:240
- [x] `plane` CharField with 4 Plane choices — models.py:248
- [x] `rom_bias` CharField with 4 RomBias choices — models.py:256
- [x] `equipment_required` ArrayField — models.py:264
- [x] `equipment_optional` ArrayField — models.py:271
- [x] `athletic_constraints` JSONField — models.py:278
- [x] `standardization_block` JSONField — models.py:286
- [x] `swap_seed_ids` JSONField — models.py:293
- [x] All new fields nullable/have defaults (blank=True, default=list/dict) — no existing exercises broken
- [x] ExerciseSerializer includes all v6.5 fields — serializers.py:44-55
- [x] ExerciseViewSet supports filtering by pattern_tags (overlap), stance, plane, rom_bias, primary_muscle_group, equipment_required — views.py:166-208
- [x] Validation: muscle_contribution_map weights sum to 1.0 (tolerance 0.01) — serializers.py:59-78
- [x] Validation: pattern_tags, athletic_skill_tags, athletic_attribute_tags validated against allowed choices — serializers.py:80-114
- [x] DB indexes: GinIndex on pattern_tags, Index on stance, plane, primary_muscle_group — models.py:321-330
- [x] `version` field for versioning — models.py:301

### DecisionLog Model: ALL PASS
- [x] UUID primary key — models.py:1798
- [x] timestamp (auto_now_add) — models.py:1799
- [x] actor_type (system/trainer/user) with TextChoices — models.py:1793-1796, 1802
- [x] actor FK to User, nullable, SET_NULL — models.py:1807-1814
- [x] decision_type CharField — models.py:1817
- [x] context JSONField — models.py:1822
- [x] inputs_snapshot JSONField — models.py:1829
- [x] constraints_applied JSONField — models.py:1833
- [x] options_considered JSONField — models.py:1837
- [x] final_choice JSONField — models.py:1841
- [x] reason_codes ArrayField — models.py:1845
- [x] override_info JSONField nullable — models.py:1853
- [x] undo_snapshot OneToOneField to UndoSnapshot, nullable — models.py:1860
- [x] DecisionLogSerializer is fully read-only (read_only_fields = fields) — serializers.py:147
- [x] DecisionLogViewSet is ReadOnlyModelViewSet — views.py:3263
- [x] Filtering by decision_type, actor_type, date_from, date_to — views.py:3299-3325
- [x] Row-level security: admins see all, trainers see own + trainee decisions, trainees see only own — views.py:3280-3294
- [x] NO blanket system decision access for non-admins — VERIFIED (system decisions where actor=None only visible to admins)
- [x] Proper indexes on decision_type, actor_type, timestamp, actor — models.py:1872-1876

### UndoSnapshot Model: ALL PASS
- [x] UUID primary key — models.py:1753
- [x] scope choices (slot/session/week/exercise/nutrition_day) — models.py:1746-1751
- [x] before_state JSONField — models.py:1759
- [x] after_state JSONField — models.py:1762
- [x] created_at DateTimeField — models.py:1765
- [x] reverted_at nullable — models.py:1766
- [x] is_reverted property — models.py:1780-1782
- [x] Undo endpoint: POST /api/workouts/decision-logs/{id}/undo/ — views.py:3329
- [x] Undo creates new DecisionLog recording the undo action — decision_log_service.py:160-170
- [x] Already-reverted returns 409 Conflict — views.py:3375-3379
- [x] Non-undoable returns 400 — decision_log_service.py:143

### DecisionLogService: ALL PASS
- [x] Returns `DecisionResult` frozen dataclass (not dict) — decision_log_service.py:20-25
- [x] `undo_decision` returns `before_state` in result — decision_log_service.py:172-176
- [x] Uses `@transaction.atomic` on both methods — decision_log_service.py:53, 119
- [x] Partial undo fields raises ValueError — decision_log_service.py:82-85
- [x] select_related('undo_snapshot') on undo lookup — decision_log_service.py:138

### Undo Endpoint Security: ALL PASS
- [x] Only trainers and admins can undo (403 for trainees) — views.py:3346-3350
- [x] IDOR protection: verifies decision is within user's queryset scope — views.py:3362
- [x] UUID format validation — views.py:3353-3359

### Migration & Seed Data: ALL PASS
- [x] backfill_exercise_tags uses `bulk_update` with batch_size=200 — backfill_exercise_tags.py:159
- [x] Uses `iterator(chunk_size=500)` for memory efficiency — backfill_exercise_tags.py:126
- [x] Supports --dry-run flag — backfill_exercise_tags.py:114-118
- [x] Maps legacy muscle_group to primary_muscle_group + contribution map — backfill_exercise_tags.py:23-56
- [x] Name-based heuristics for pattern_tags — backfill_exercise_tags.py:59-107

### URL Registration: PASS
- [x] decision-logs registered in router — urls.py:43

---

## Security Verification
- No secrets, API keys, or tokens in any reviewed files
- Row-level security enforced in DecisionLogViewSet.get_queryset() — trainers scoped to own + trainees
- IDOR protection on undo endpoint via queryset scope check
- DecisionLog is read-only (ReadOnlyModelViewSet + read_only_fields on serializer)
- Input validation on all tag fields, muscle_contribution_map, and filter parameters
- Invalid filter values return empty querysets (not unfiltered data)

## Architecture Verification
- Business logic in services (DecisionLogService), not views — correct layering
- Dataclass returns per project rules (no raw dicts from services)
- select_related('created_by') on ExerciseViewSet, select_related('actor', 'undo_snapshot') on DecisionLogViewSet
- All new fields backward-compatible (defaults/nullable)
- GinIndex for ArrayField queries, standard indexes for CharFields
- Pagination on DecisionLogViewSet

---

## Remaining Concerns (non-blocking)

1. **System decision visibility gap:** System decisions (actor=None) about a trainee's plan are only visible to admins, not to the trainee's trainer. The trainer query filters by actor identity, not by context (e.g., plan_id belonging to their trainee). This is acceptable for the foundation layer since no system decisions are being created yet — when the swap/progression engines are built (Steps 3-5), the DecisionLogViewSet scoping should be extended to also check context fields.

2. **Trainee DecisionLog access is actor-only:** Trainees can only see decisions where they are the actor. System-generated decisions about their program (actor=None) are invisible to them. This matches the ticket specification but may need revisiting when the decision engine is active.

3. **No pagination on backfill command's bulk_update:** The `to_update` list accumulates all exercises in memory before calling `bulk_update`. For very large exercise libraries (10k+), this could use significant memory. The `batch_size=200` on bulk_update mitigates the DB side, but the Python list still holds all objects. Low risk for current data volumes.

---

## What Was Built

**ExerciseCard Rich Tagging + DecisionLog + UndoSnapshot Foundation (v6.5 Step 1)**

### Exercise Model Enrichment
- 16 movement pattern tags (knee_dominant through carries)
- 19 athletic skill tags (jumps, sprints, throws, Olympic derivatives)
- 10 athletic attribute tags (power, elasticity, speed, agility, etc.)
- 21 detailed muscle groups replacing the legacy 10-group taxonomy
- Muscle contribution map with sum-to-1.0 validation
- Stance (13 positions), Plane (4), ROM Bias (4) classifications
- Equipment required/optional arrays
- Athletic constraints JSON (impact, ground contacts, space, surface, skill demand)
- Standardization block JSON (what_counts, feel_checks, fail_flags, default_dials, assess_hooks)
- Swap seed IDs for pre-computed swap candidates
- Version field for edit tracking
- GinIndex on pattern_tags, indexes on stance/plane/primary_muscle_group

### DecisionLog + UndoSnapshot Models
- Full audit trail for every automated decision: inputs, constraints, options considered, final choice, reason codes
- UndoSnapshot with before/after state, scope (slot/session/week/exercise/nutrition_day), revert tracking
- Read-only API with filtering by decision_type, actor_type, date range
- Undo endpoint with IDOR protection, double-undo prevention (409), proper actor logging

### DecisionLogService
- Atomic log_decision and undo_decision methods
- Frozen dataclass return type (DecisionResult)
- Partial undo field validation

### ExerciseViewSet Enhancements
- Tag-based filtering: pattern_tags (overlap), stance, plane, rom_bias, primary_muscle_group, equipment_required
- Input validation on all filter parameters (invalid values return empty queryset)

### Backfill Management Command
- Maps legacy muscle_group to detailed taxonomy
- Name-based heuristic pattern tag assignment
- Memory-efficient: iterator(chunk_size=500) + bulk_update(batch_size=200)
- Dry-run support
