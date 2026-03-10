# Feature: Training Generator Pipeline + Swap System

## Priority
Critical — Step 5 of v6.5 build order. Foundation for session runner, progression engine, and trainer copilot.

## User Story
As a **trainer**, I want to generate structured training plans for my trainees using a deterministic pipeline so I can quickly create periodized programs with full auditability.

As a **trainee**, I want to swap exercises in my plan with intelligent alternatives so I can adapt my training without losing programming intent.

## Acceptance Criteria

### Models
- [ ] TrainingPlan model with trainee FK, name, goal, status (draft/active/completed/archived), created_by
- [ ] PlanWeek model with plan FK, week_number, is_deload, intensity_modifier, volume_modifier
- [ ] PlanSession model with week FK, day_of_week, label, order
- [ ] PlanSlot model with session FK, exercise FK, order, slot_role, sets, reps_min, reps_max, rest_seconds, load_prescription_pct, notes, swap_options_cache
- [ ] SplitTemplate model with name, days_per_week, session_definitions JSON, goal_type, is_system, created_by
- [ ] All models use UUID primary keys
- [ ] Proper unique constraints and indexes

### Generator Pipeline
- [ ] A1: SELECT_PROGRAM_LENGTH — returns weeks count based on goal/experience
- [ ] A2: SELECT_SPLIT_TEMPLATE — picks split based on frequency/goal
- [ ] A3: BUILD_WEEKLY_SLOT_SKELETON — creates PlanWeek/PlanSession/PlanSlot records
- [ ] A4: ASSIGN_SLOT_ROLE — tags each slot (primary_compound, secondary_compound, accessory, isolation)
- [ ] A5: SET_SET_STRUCTURE — assigns sets/reps/rest per role and goal
- [ ] A6: SELECT_EXERCISE — fills slots from exercise pool (respecting muscle, pattern, equipment, variety)
- [ ] A7: BUILD_SWAP_RECOMMENDATIONS — pre-computes swap candidates per slot
- [ ] Each step creates a DecisionLog entry
- [ ] Pipeline is transactional — failure at any step rolls back
- [ ] Pipeline returns the complete TrainingPlan with nested structure

### Swap System
- [ ] Same Muscle tab: exercises sharing primary_muscle_group
- [ ] Same Pattern tab: exercises sharing pattern_tags
- [ ] Explore All tab: all exercises matching equipment constraints
- [ ] Swap execution: updates PlanSlot.exercise, creates DecisionLog + UndoSnapshot
- [ ] Swap preserves set/rep prescription (transfers to new exercise)
- [ ] Pre-computed swap_seed_ids used when available, dynamic query as fallback

### API Endpoints
- [ ] CRUD for TrainingPlan with nested reads
- [ ] POST /api/workouts/training-plans/generate/ — run full pipeline
- [ ] GET /api/workouts/plan-slots/{id}/swap-options/ — 3-tab swap candidates
- [ ] POST /api/workouts/plan-slots/{id}/swap/ — execute swap
- [ ] CRUD for SplitTemplate
- [ ] Row-level security on all endpoints

### Conventions
- [ ] All service methods return dataclasses, not dicts
- [ ] Business logic in services/, not views
- [ ] Type hints on all functions
- [ ] No raw queries — Django ORM only
- [ ] Proper prefetching on all querysets

## Edge Cases
1. No exercises match slot criteria (muscle group + equipment) — widen search progressively: drop equipment, drop difficulty, use any exercise with matching primary_muscle_group
2. Trainee has no exercise history — generate without variety constraints
3. Split template requires 6 days but only 3 available — select template matching available days
4. Swap to same exercise already in session — prevent duplicate in same session
5. All swap candidates exhausted — show empty tab with explanation
6. Deload week — reduce volume/intensity modifiers, skip heavy compounds
7. Exercise has no pattern_tags — skip pattern-based swap tab, don't error
8. Exercise has no swap_seed_ids — fall back to dynamic query
9. Plan generation with zero exercises in database — return error before creating any records
10. Concurrent swap on same slot — last write wins (no optimistic locking needed for v1)

## Technical Approach
- Create models in `backend/workouts/models.py`
- Create `backend/workouts/services/training_generator_service.py` — 7-step pipeline
- Create `backend/workouts/services/swap_service.py` — swap computation + execution
- Add serializers to `backend/workouts/serializers.py`
- Add views to `backend/workouts/views.py`
- Register routes in `backend/workouts/urls.py`
- Generate migration

## Out of Scope
- Set structure modalities (Step 6)
- Progression engine integration (Step 7)
- Session runner UI (Step 8)
- AI-powered generation alternative
- Workout schedule calendar sync
