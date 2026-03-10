# Dev Done: Training Generator Pipeline + Swap System

## Date: 2026-03-09

## Files Changed

### Modified
- `backend/workouts/models.py` — Added SplitTemplate, TrainingPlan, PlanWeek, PlanSession, PlanSlot models
- `backend/workouts/serializers.py` — Added serializers for all new models + generate/swap inputs
- `backend/workouts/views.py` — Added TrainingPlanViewSet, PlanSlotViewSet, SplitTemplateViewSet
- `backend/workouts/urls.py` — Registered training-plans, plan-slots, split-templates routes

### Created
- `backend/workouts/services/training_generator_service.py` — 7-step deterministic pipeline (A1-A7)
- `backend/workouts/services/swap_service.py` — 3-tab swap options + swap execution with undo
- `backend/workouts/migrations/0023_training_plan_split_template.py` — Migration

## Key Decisions
1. Plan hierarchy: TrainingPlan → PlanWeek → PlanSession → PlanSlot (relational, not JSON)
2. SplitTemplate stores session_definitions as JSON list of {label, muscle_groups, pattern_focus}
3. PlanSlot.exercise uses PROTECT on delete — exercises can't be removed while in active plans
4. Slot roles assigned by position: slots 1-2 = compounds, 3-4 = accessories, 5+ = isolation
5. Scheme table keyed by (goal, slot_role) — 24 combinations covering all goals × roles
6. Exercise selection uses primary_muscle_group (v6.5 field), falls back to legacy muscle_group
7. Swap options: pre-computed via swap_seed_ids on Exercise, dynamic query as fallback
8. Swap execution creates DecisionLog + UndoSnapshot for full audit trail
9. Swap preserves prescription (sets/reps/rest carry over to new exercise)
10. Pipeline is fully transactional — failure at any step rolls back everything
11. DecisionLog created at every pipeline step for complete auditability
12. Deload weeks: every 4th week when program is 4+ weeks (60% intensity/volume)

## New API Endpoints
- `GET/POST /api/workouts/training-plans/` — list/create plans
- `GET/PUT/DELETE /api/workouts/training-plans/{id}/` — retrieve/update/delete plan
- `POST /api/workouts/training-plans/generate/` — run 7-step pipeline
- `POST /api/workouts/training-plans/{id}/activate/` — activate plan (deactivate others)
- `POST /api/workouts/training-plans/{id}/archive/` — archive plan
- `GET/PUT /api/workouts/plan-slots/{id}/` — retrieve/update slot
- `GET /api/workouts/plan-slots/{id}/swap-options/` — 3-tab swap candidates
- `POST /api/workouts/plan-slots/{id}/swap/` — execute swap
- `GET/POST /api/workouts/split-templates/` — list/create split templates
- `GET/PUT/DELETE /api/workouts/split-templates/{id}/` — CRUD split template

## How to Test
1. `python manage.py migrate`
2. Create a SplitTemplate: `POST /api/workouts/split-templates/` with session_definitions
3. `POST /api/workouts/training-plans/generate/` with trainee_id, goal, difficulty, days_per_week
4. `GET /api/workouts/training-plans/{id}/` — verify nested week/session/slot structure
5. `GET /api/workouts/plan-slots/{id}/swap-options/` — verify 3-tab options
6. `POST /api/workouts/plan-slots/{id}/swap/` with new_exercise_id — verify swap + decision log
7. `GET /api/workouts/decision-logs/?decision_type=plan_generation_a6_exercise_selection` — verify audit trail
