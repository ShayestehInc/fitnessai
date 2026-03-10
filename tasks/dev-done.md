# Dev Done: Modality Library with Counting Rules and Guardrails

## Date: 2026-03-09

## Files Changed

### Modified

- `backend/workouts/models.py` — Added SetStructureModality, ModalityGuardrail models; added modality fields to PlanSlot
- `backend/workouts/serializers.py` — Added modality serializers; updated PlanSlotSerializer with modality fields
- `backend/workouts/views.py` — Added SetStructureModalityViewSet, PlanSessionViewSet; added modality-recommendations and set-modality actions to PlanSlotViewSet
- `backend/workouts/urls.py` — Registered modalities, plan-sessions routes
- `backend/workouts/services/training_generator_service.py` — Enhanced A5 step with modality assignment; added modality fields to SlotSpec

### Created

- `backend/workouts/services/modality_service.py` — Full modality service: guardrail validation, recommendations, volume computation, apply/assign logic
- `backend/workouts/management/commands/seed_modalities.py` — Seeds 8 system modalities + 5 guardrails
- `backend/workouts/migrations/0024_modality_library.py` — Migration

## Key Decisions

1. SetStructureModality is a standalone model (not TextChoices) — supports trainer-created custom modalities
2. ModalityGuardrail uses condition_field/operator/value pattern — extensible without code changes
3. Volume multiplier from packet: 1.0x (straight/down/eccentrics), 0.67x (giant/myo/drop/occlusion), 2.0x (supersets)
4. PlanSlot gets nullable FK to SetStructureModality — backward compatible with existing plans
5. A5 enhanced to assign default modality during pipeline — uses prefetched modality map
6. SlotSpec extended with modality fields — passed through to PlanSlot during bulk_create
7. Guardrail evaluation resolves field values from exercise tags and slot properties
8. Deload weeks always get Straight Sets regardless of goal
9. Trainer override creates DecisionLog with guardrail_override reason code
10. Volume summary service aggregates per-muscle with modality multipliers

## New API Endpoints

- `GET/POST /api/workouts/modalities/` — list/create modalities
- `GET/PUT/DELETE /api/workouts/modalities/{id}/` — CRUD modality
- `GET /api/workouts/plan-slots/{id}/modality-recommendations/` — ranked valid modalities
- `POST /api/workouts/plan-slots/{id}/set-modality/` — apply modality with guardrail check
- `GET /api/workouts/plan-sessions/{id}/` — retrieve session
- `GET /api/workouts/plan-sessions/{id}/volume-summary/` — per-muscle volume summary

## How to Test

1. `python manage.py migrate`
2. `python manage.py seed_modalities` — seeds 8 system modalities + guardrails
3. `GET /api/workouts/modalities/` — verify 8 system modalities listed
4. Generate a plan: existing flow now assigns modalities in A5
5. `GET /api/workouts/training-plans/{id}/` — verify slots have modality data
6. `GET /api/workouts/plan-slots/{id}/modality-recommendations/` — verify ranked list
7. `POST /api/workouts/plan-slots/{id}/set-modality/` — apply modality, verify guardrails
8. `GET /api/workouts/plan-sessions/{id}/volume-summary/` — verify per-muscle volume
