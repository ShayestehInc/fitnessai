# Dev Done: Dual-Mode Program Builder (Quick Build + Advanced Builder)

## Files Changed

### Created

- `backend/workouts/services/builder_service.py` — Core builder logic: quick_build(), builder_start(), builder_advance(), explanation generators, state management
- `backend/workouts/migrations/0035_trainingplan_builder_fields.py` — Adds build_mode + builder_state fields to TrainingPlan
- `backend/workouts/tests/test_builder_service.py` — 13 tests covering Quick Build + Advanced Builder flows
- `mobile/lib/features/training_plans/data/models/builder_models.dart` — StepExplanation, QuickBuildResult, BuilderStepResult, BuilderBrief models
- `mobile/lib/features/training_plans/presentation/screens/builder_mode_screen.dart` — Entry screen: choose Quick Build vs Advanced Builder
- `mobile/lib/features/training_plans/presentation/screens/quick_build_screen.dart` — Simple form → generate → review with step explanations
- `mobile/lib/features/training_plans/presentation/screens/advanced_builder_screen.dart` — Multi-step wizard with Why panels, alternatives, override controls
- `mobile/lib/features/training_plans/presentation/widgets/why_panel.dart` — Collapsible "Why" explanation panel + AlternativesPanel widget

### Modified

- `backend/workouts/models.py` — Added `build_mode` and `builder_state` JSONField to TrainingPlan
- `backend/workouts/serializers.py` — Added QuickBuildSerializer, BuilderStartSerializer, BuilderAdvanceSerializer; updated TrainingPlanSerializer/ListSerializer with build_mode
- `backend/workouts/views.py` — Added 4 new endpoints: quick_build, builder_start, builder_advance, builder_state
- `mobile/lib/core/constants/api_constants.dart` — Added quickBuild, builderStart, builderAdvance, builderState endpoints
- `mobile/lib/core/router/app_router.dart` — Added /build-program, /quick-build, /advanced-builder routes
- `mobile/lib/features/training_plans/data/repositories/training_plan_repository.dart` — Added quickBuild, builderStart, builderAdvance, builderGetState methods
- `mobile/lib/features/training_plans/presentation/providers/training_plan_provider.dart` — Added QuickBuildNotifier/State, AdvancedBuilderNotifier/State providers
- `mobile/lib/features/training_plans/presentation/screens/my_plans_screen.dart` — Added "Build Program" button in app bar

## Key Decisions

1. **Builder state stored in JSONField** — No new model needed. TrainingPlan.builder_state tracks step progress, brief, choices, and specs. Cleaned up on publish.
2. **Pipeline steps reused** — Both modes use the existing 7-step training_generator_service pipeline. Quick Build runs all at once; Advanced Builder steps through them one at a time.
3. **Specs serialized to state** — Between advanced builder steps, SlotSpecs are serialized to the builder_state JSONField and reconstructed when needed. PlanSlots only created at publish time.
4. **Why explanations hardcoded** — Each step has deterministic explanations based on goal/inputs. No AI call needed for "why" text.

## API Endpoints

| Endpoint                                             | Method | Description                                |
| ---------------------------------------------------- | ------ | ------------------------------------------ |
| `/api/workouts/training-plans/quick-build/`          | POST   | Quick Build — full pipeline + explanations |
| `/api/workouts/training-plans/builder/start/`        | POST   | Advanced Builder — create session          |
| `/api/workouts/training-plans/{id}/builder/advance/` | POST   | Advanced Builder — next step               |
| `/api/workouts/training-plans/{id}/builder/state/`   | GET    | Get builder session state                  |

## How to Test

1. Backend: `cd backend && python manage.py test workouts.tests.test_builder_service -v2`
2. Mobile: Navigate to My Plans → tap "+" → choose Quick Build or Advanced Builder
3. Quick Build: fill form, tap Generate, verify plan + explanations appear
4. Advanced Builder: fill brief, step through each decision, verify why/alternatives at each step
