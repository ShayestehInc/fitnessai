# Focus: Trainer Packet v6.5 — Step 1: Foundation Layer

## Priority
Build the foundation schema that ALL other trainer packet v6.5 features depend on.

## What to Build (this pipeline)
Following the trainer packet v6.5 recommended build order (Section 20), implement Step 1:

### 1. ExerciseCard Enrichment (Rich Tagging on existing Exercise model)
Add the following fields to the existing `Exercise` model in `backend/workouts/models.py`:
- `pattern_tags` — ArrayField of pattern tag choices (Knee dominant, Hip dominant, etc.)
- `athletic_skill_tags` — ArrayField of athletic skill tag choices
- `athletic_attribute_tags` — ArrayField of athletic attribute tags
- `muscle_contribution_map` — JSONField: {muscle_group: weight} where weights sum to 1.0
- `stance` — CharField with choices (bilateral, single-leg, split stance, etc.)
- `plane` — CharField with choices (sagittal, frontal, transverse, mixed)
- `rom_bias` — CharField with choices (lengthened, mid-range, shortened, mixed)
- `standardization_block` — JSONField: {what_counts[], feel_checks[], fail_flags[], default_dials[], assess_hooks[]}
- `swap_seed_ids` — JSONField: {recommended_same_muscle_ids[], recommended_same_pattern_ids[]}
- `equipment_required` — ArrayField
- `equipment_optional` — ArrayField
- `athletic_constraints` — JSONField: {impact_level, ground_contacts_level, space_required, surface_required, skill_demand}

### 2. DecisionLog Model
New model in `backend/workouts/models.py`:
- `decision_id` (UUID primary key)
- `timestamp` (DateTimeField auto)
- `actor_type` (CharField: system/trainer/user)
- `actor_id` (ForeignKey to User, nullable)
- `context` (JSONField: plan/week/session/slot OR nutrition-day)
- `decision_type` (CharField)
- `inputs_snapshot` (JSONField)
- `constraints_applied` (JSONField)
- `options_considered` (JSONField: top N + score breakdown)
- `final_choice` (JSONField)
- `reason_codes` (ArrayField)
- `override_info` (JSONField, nullable)
- `undo_pointer` (OneToOneField to UndoSnapshot, nullable)

### 3. UndoSnapshot Model
New model in `backend/workouts/models.py`:
- `snapshot_id` (UUID primary key)
- `scope` (CharField: slot/session/week)
- `before_state` (JSONField)
- `after_state` (JSONField)
- `decision` (ForeignKey to DecisionLog)
- `created_at` (DateTimeField auto)

### 4. Backend API Endpoints
- CRUD for DecisionLog (read-only for trainees, full for trainers)
- Undo endpoint: POST `/api/workouts/decisions/{id}/undo/`
- ExerciseCard filtering by new tag fields
- Serializers using rest_framework_dataclasses per project rules

### 5. Migration + Seed Data
- Django migration for all new fields/models
- Management command to backfill existing exercises with basic tags (at minimum pattern_tags and primary_muscle_group mapped to contribution map)

## What NOT to Build (save for later pipelines)
- LiftSetLog/LiftMax (Step 3)
- Session/Slot models (Step 5 — Plan hierarchy)
- Workload engine (Step 4)
- Pain triage (Step 8-9)
- Session runner, swap system, auto-tagging, import pipeline

## Source Document
Trainer Packet v6.5: `/Users/rezashayesteh/Downloads/ai_app_unified_master_packet_v6_5_session_feedback_user-1.pdf`
