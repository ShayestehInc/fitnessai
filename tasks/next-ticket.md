# Feature: ExerciseCard Rich Tagging + DecisionLog + UndoSnapshot Foundation

## Priority
Critical — This is Step 1 of the Trainer Packet v6.5 implementation. Every subsequent feature (swap system, decision engine, workload engine, progression profiles, session runner) depends on these foundation models.

## User Story
As a **trainer**, I want exercises to have rich, standardized tags (movement patterns, muscle contribution maps, stance, plane, ROM bias) so that the system can intelligently select, swap, and program exercises based on structured data rather than just names and basic muscle groups.

As a **trainer**, I want every automated decision the system makes to be logged with full context (inputs, options considered, final choice, reason codes) and undoable, so that I can understand why the AI made a change and revert it if needed.

## Acceptance Criteria

### ExerciseCard Enrichment
- [ ] Exercise model has `pattern_tags` ArrayField with exact choices from trainer packet taxonomy
- [ ] Exercise model has `athletic_skill_tags` ArrayField with exact choices from packet
- [ ] Exercise model has `athletic_attribute_tags` ArrayField with exact choices from packet
- [ ] Exercise model has `muscle_contribution_map` JSONField (dict of muscle_group→weight, weights sum to 1.0)
- [ ] Exercise model has `stance` CharField with choices from packet taxonomy
- [ ] Exercise model has `plane` CharField with choices from packet taxonomy
- [ ] Exercise model has `rom_bias` CharField with choices from packet taxonomy
- [ ] Exercise model has `equipment_required` ArrayField of strings
- [ ] Exercise model has `equipment_optional` ArrayField of strings
- [ ] Exercise model has `athletic_constraints` JSONField with impact_level, ground_contacts_level, space_required, surface_required, skill_demand
- [ ] Exercise model has `standardization_block` JSONField with what_counts[], feel_checks[], fail_flags[], default_dials[], assess_hooks[]
- [ ] Exercise model has `swap_seed_ids` JSONField with recommended_same_muscle_ids[], recommended_same_pattern_ids[]
- [ ] All new fields are nullable/have defaults so existing exercises don't break
- [ ] ExerciseSerializer includes all new fields
- [ ] ExerciseViewSet supports filtering by pattern_tags, muscle_group (from contribution map), stance, plane
- [ ] API endpoint for exercise search supports new tag-based filtering
- [ ] Validation: muscle_contribution_map weights must sum to 1.0 (within tolerance of 0.01)
- [ ] DB indexes on pattern_tags and stance for query performance

### DecisionLog Model
- [ ] DecisionLog model exists with UUID primary key
- [ ] Fields: timestamp, actor_type (system/trainer/user), actor_id (FK to User nullable)
- [ ] Fields: context (JSONField), decision_type (CharField), inputs_snapshot (JSONField)
- [ ] Fields: constraints_applied (JSONField), options_considered (JSONField), final_choice (JSONField)
- [ ] Fields: reason_codes (ArrayField), override_info (JSONField nullable)
- [ ] Fields: undo_pointer (OneToOneField to UndoSnapshot, nullable)
- [ ] DecisionLog is read-only for trainees, full CRUD for trainers/admins
- [ ] API: GET /api/workouts/decision-logs/ with filtering by decision_type, actor_type, date range
- [ ] API: GET /api/workouts/decision-logs/{id}/ detail view
- [ ] Row-level security: trainers only see decisions for their trainees

### UndoSnapshot Model
- [ ] UndoSnapshot model exists with UUID primary key
- [ ] Fields: scope (slot/session/week), before_state (JSONField), after_state (JSONField)
- [ ] Fields: decision (ForeignKey to DecisionLog), created_at (DateTimeField)
- [ ] API: POST /api/workouts/decision-logs/{id}/undo/ — reverts to before_state
- [ ] Undo creates a new DecisionLog entry recording the undo action itself
- [ ] Row-level security matches DecisionLog

### Migration & Seed Data
- [ ] Django migration creates all new fields and models cleanly
- [ ] Migration is reversible
- [ ] Existing exercises are not broken (all new fields have defaults or are nullable)
- [ ] Management command `backfill_exercise_tags` maps existing muscle_group to pattern_tags and muscle_contribution_map for common exercises

## Edge Cases
1. Exercise with no tags set — all tag fields are optional, exercise still works normally
2. muscle_contribution_map with weights not summing to 1.0 — serializer validation rejects with clear error
3. muscle_contribution_map with unknown muscle group key — validation against allowed muscle group list
4. DecisionLog with no UndoSnapshot — undo endpoint returns 400 "This decision cannot be undone"
5. Undo on already-undone decision — returns 400 "This decision has already been reverted"
6. Filtering exercises by multiple pattern_tags — uses overlap (__overlap) for "any of these tags"
7. Trainer trying to see another trainer's DecisionLogs — row-level security returns empty queryset
8. Empty standardization_block — allowed, just means no standardization data yet
9. Concurrent undo attempts — database-level check prevents double-undo
10. Exercise with swap_seed_ids pointing to deleted exercises — gracefully ignored

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Invalid muscle_contribution_map (sum != 1.0) | "Muscle contribution weights must sum to 1.0" | Returns 400 |
| Unknown pattern_tag value | "Invalid pattern tag: X. Valid options: ..." | Returns 400 |
| Undo on non-undoable decision | "This decision cannot be undone" | Returns 400 |
| Double undo attempt | "This decision has already been reverted" | Returns 409 |
| Unauthorized DecisionLog access | Standard 403 | Returns 403 |

## UX Requirements
- **Loading state:** N/A (backend only this pipeline)
- **Empty state:** Exercises with no tags show empty arrays/null in API responses
- **Error state:** Clear validation error messages with field-level details
- **Success feedback:** Standard 200/201 responses

## Technical Approach
- **Files to modify:**
  - `backend/workouts/models.py` — Add fields to Exercise, add DecisionLog + UndoSnapshot models
  - `backend/workouts/serializers.py` — Update ExerciseSerializer, add DecisionLog/UndoSnapshot serializers
  - `backend/workouts/views.py` — Update ExerciseViewSet filters, add DecisionLogViewSet
  - `backend/workouts/urls.py` — Register new routes
  - New migration file
- **Files to create:**
  - `backend/workouts/management/commands/backfill_exercise_tags.py` — Seed command
  - `backend/workouts/services/decision_log_service.py` — Service for creating DecisionLog + UndoSnapshot entries
- **Key design decisions:**
  - Add fields to existing Exercise model (not a separate ExerciseCard model) to avoid data migration complexity
  - Use PostgreSQL ArrayField for tags (enables __contains and __overlap lookups)
  - DecisionLog uses JSONField for flexible context storage (different decision types have different context shapes)
  - UndoSnapshot stores full before/after state as JSON (not diffs) for simplicity and reliability

## Out of Scope
- Mobile UI for tags (future pipeline)
- Auto-tagging service (Step 11 in build order)
- Exercise swap system UI (Step 5)
- LiftSetLog/LiftMax (Step 3)
- Workload engine (Step 4)
- Pain triage models (Step 8-9)
- SessionFeedback model (Step 9)
