# Dev Done: Smart Program Generator

## Date
2026-02-21

## Files Changed

### Backend — New Files
- `backend/workouts/migrations/0008_add_exercise_difficulty_and_category.py` — Migration adding `difficulty_level` and `category` to Exercise
- `backend/workouts/management/commands/classify_exercises.py` — AI + heuristic exercise classification command
- `backend/workouts/management/commands/seed_kilo_exercises.py` — KILO exercise library seeder
- `backend/workouts/fixtures/kilo_exercises.json` — 1,067 exercise fixture data
- `backend/workouts/services/program_generator.py` — Core program generation service with dataclasses, split configs, exercise selection, sets/reps schemes, progressive overload, nutrition templates

### Backend — Modified Files
- `backend/workouts/models.py` — Added `DifficultyLevel` choices, `difficulty_level` and `category` fields to Exercise, composite index
- `backend/workouts/serializers.py` — Added new fields to ExerciseSerializer
- `backend/workouts/views.py` — Added `difficulty_level` query param filter to ExerciseViewSet
- `backend/workouts/ai_prompts.py` — Added `get_exercise_classification_prompt()`
- `backend/trainer/serializers.py` — Added `CustomDayConfigSerializer`, `GenerateProgramRequestSerializer`
- `backend/trainer/views.py` — Added `GenerateProgramView` (POST endpoint)
- `backend/trainer/urls.py` — Added URL route for generate endpoint

### Web — New Files
- `web/src/app/(dashboard)/programs/generate/page.tsx` — Route page
- `web/src/components/programs/program-generator-wizard.tsx` — Main 3-step wizard
- `web/src/components/programs/generator/split-type-step.tsx` — Split type selector
- `web/src/components/programs/generator/config-step.tsx` — Configuration step
- `web/src/components/programs/generator/custom-day-config.tsx` — Custom split day configurator
- `web/src/components/programs/generator/preview-step.tsx` — Preview/results step

### Web — Modified Files
- `web/src/types/program.ts` — Added SplitType, GenerateProgramPayload, GeneratedProgramResponse types; `difficulty_level`/`category` on Exercise
- `web/src/hooks/use-programs.ts` — Added `useGenerateProgram()` mutation
- `web/src/hooks/use-exercises.ts` — Added `difficultyLevel` param
- `web/src/lib/constants.ts` — Added `GENERATE_PROGRAM` URL constant
- `web/src/app/(dashboard)/programs/page.tsx` — Added "Generate with AI" button
- `web/src/components/programs/program-builder.tsx` — Loads generated data from sessionStorage
- `web/src/components/programs/exercise-picker-dialog.tsx` — Added difficulty filter

### Mobile — New Files
- `mobile/lib/features/programs/presentation/screens/program_generator_screen.dart` — 3-step generator wizard
- `mobile/lib/features/programs/presentation/widgets/split_type_card.dart` — Split type selection card
- `mobile/lib/features/programs/presentation/widgets/goal_type_card.dart` — Goal type selection card
- `mobile/lib/features/programs/presentation/widgets/custom_day_configurator.dart` — Custom day muscle group configurator

### Mobile — Modified Files
- `mobile/lib/core/constants/api_constants.dart` — Added `generateProgram` endpoint
- `mobile/lib/features/programs/data/repositories/program_repository.dart` — Added `generateProgram()` method
- `mobile/lib/features/exercises/data/repositories/exercise_repository.dart` — Added `difficultyLevel` param
- `mobile/lib/features/exercises/presentation/providers/exercise_provider.dart` — Added `difficultyLevel` to ExerciseFilter
- `mobile/lib/features/programs/presentation/screens/programs_screen.dart` — Added "Generate with AI" option
- `mobile/lib/features/programs/presentation/screens/week_editor_screen.dart` — Added difficulty filter to exercise picker

## Key Decisions
1. Program generation is deterministic (no AI API call) — uses algorithm with exercise DB queries, making it fast and predictable
2. Generated programs are NOT saved automatically — they load into the existing program builder for trainer customization
3. Exercise classification command supports both OpenAI GPT-4o and a heuristic fallback mode
4. Progressive overload is built into multi-week programs (+1 set every 3 weeks, +1 rep every 2 weeks, deload every 4th week)
5. Nutrition templates are goal-based defaults with training day/rest day variations

## How to Test
1. Run migration: `python manage.py migrate`
2. Seed exercises: `python manage.py seed_kilo_exercises`
3. Classify exercises: `python manage.py classify_exercises --heuristic` (or with `OPENAI_API_KEY` for AI classification)
4. API test: `POST /api/trainer/program-templates/generate/` with body `{"split_type": "ppl", "difficulty": "intermediate", "goal": "build_muscle", "duration_weeks": 4, "training_days_per_week": 5}`
5. Web: Navigate to `/programs` → click "Generate with AI" → complete wizard → verify builder loads
6. Mobile: Open Programs → tap "+" → "Generate with AI" → complete wizard → verify builder loads

## Review Fixes Applied (Round 1)

### Critical Fixes
- **C1 (IDOR):** Fixed `_get_exercises_for_muscle_group` and `_prefetch_exercise_pool` — when `trainer_id=None`, only `is_public=True` exercises are returned. Previously `Q()` (empty) was OR'd, which matched all rows.
- **C2 (N+1 queries):** Added `_prefetch_exercise_pool()` that fetches ALL exercises needed for the split's muscle groups in 1-2 queries (with fallback). `_pick_exercises_from_pool()` now operates on in-memory lists instead of per-day DB queries.
- **C3 (Unbounded progressive overload):** Capped `extra_sets` at 3, `extra_reps` at 5. Overload counters reset every 4-week block (deload resets the effective week counter).

### Major Fixes
- **M1:** Moved `used_exercise_ids` outside the week loop so exercises don't repeat across weeks.
- **M3:** Added exercise IDs to AI classification prompt and lookup dict. `classify_exercises` now keys results by ID (string) first, falls back to name.
- **M4:** Added try/except around `int()` conversions in `_apply_progressive_overload` for malformed reps formats.
- **M5:** Added `GeneratedProgramResponseSerializer` to `trainer/serializers.py` and wired it in `GenerateProgramView`.
- **M6:** Added `trainer_id` parameter to `to_dataclass()` on `GenerateProgramRequestSerializer`, eliminating the manual dataclass reconstruction in the view.

### Minor Fixes
- **m1:** Changed bare `dict` type hints to `dict[str, Any]` in `GeneratedProgram` dataclass and JSON helper functions.
- **m2:** Moved `valid_groups` computation outside the loop in `seed_kilo_exercises.py`.
- **m4:** Added `total_failed` (fallback-to-heuristic count) to `classify_exercises` summary output.
- **m5:** Added validation of `difficulty_level` query param in `ExerciseViewSet.get_queryset()` — returns empty queryset for invalid values.
