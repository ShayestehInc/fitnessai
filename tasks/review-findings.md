# Code Review: Smart Program Generator

## Review Date: 2026-02-21

## Files Reviewed: 35 files across backend, web, mobile

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `program_generator.py:311-313` | `Q()` when `trainer_id=None` exposes all trainers' private exercises (IDOR) | Use `privacy_q = Q(is_public=True); if trainer_id: privacy_q |= Q(created_by_id=trainer_id)` |
| C2 | `program_generator.py:316-334` | N+1 queries — up to 200+ DB queries per generation call | Prefetch all exercises once, keyed by (muscle_group, difficulty), pass dict into builder |
| C3 | `program_generator.py:414-438` | Progressive overload unbounded — 52-week program gets 20 sets, 37 reps per exercise | Cap extra_sets at 3, extra_reps at 5; reset after deload |
| C4 | `custom_day_configurator.dart:147` | TextEditingController created inside StatelessWidget build() — memory leak + cursor reset on rebuild | Convert to StatefulWidget with proper init/dispose lifecycle |
| C5 | `program-builder.tsx:84-95` | Side effect in useMemo (sessionStorage.removeItem) with suppressed lint | Move to useEffect or useRef-initialized value |
| C6 | `program-generator-wizard.tsx:56-91` | Race condition — Generate button can fire duplicate concurrent mutations | Add isPending guard to disabled prop; reset mutation on back navigation |
| C7 | `program_generator_screen.dart:1-831` | 831 lines — violates 150-line max per CLAUDE.md | Extract step widgets and StepIndicator to separate files |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `program_generator.py:492` | `used_exercise_ids` resets per-week — same exercises repeat identically every week | Persist set across weeks or rotate per-day-slot |
| M2 | `program_generator.py:349` | Full queryset materialized into Python list — memory risk | Apply `[:needed_count]` or ORDER_BY ? LIMIT at DB level |
| M3 | `classify_exercises.py:307-312` | Name-based lookup for classification — duplicates cause wrong classification | Use exercise IDs instead of names |
| M4 | `program_generator.py:431-437` | No validation of base_reps format before int() — crashes on non-numeric | Add try/except or validate at ExerciseScheme construction |
| M5 | `trainer/views.py:672-680` | No output serializer for generated program response | Add GeneratedProgramResponseSerializer |
| M6 | `trainer/serializers.py:423-443` | to_dataclass() doesn't accept trainer_id; view creates object twice | Add trainer_id parameter to to_dataclass() |
| M7 | `exercise_provider.dart:20-23` | API errors silently return empty list instead of throwing | Throw exception so .when(error:) fires |
| M8 | `program_repository.dart:126` | Unsafe `as Map<String, dynamic>` cast — crashes on unexpected response | Add type check before cast |
| M9 | `program_generator_screen.dart:74-81` | Concurrent generate race — no guard against double-tap | Add `if (_isGenerating) return;` guard |
| M10 | `program_generator_screen.dart:151` | pushReplacement loses back stack — user can't return to generator | Use Navigator.push instead |
| M11 | `split_type_card.dart:67` / `goal_type_card.dart:73` | GestureDetector — no ripple feedback, no accessibility semantics | Replace with InkWell, add Semantics |
| M12 | `program-builder.tsx:84-95` | Unvalidated JSON.parse from sessionStorage — no runtime validation | Add key validation before cast |
| M13 | `exercise-picker-dialog.tsx:139-151` | Difficulty filter badges not keyboard accessible (no tabIndex/role) | Use Button instead of Badge for interactivity |
| M14 | `exercise-picker-dialog.tsx:174` | Empty state doesn't account for difficulty filter in condition | Add selectedDifficulty to the check |
| M15 | `custom-day-config.tsx:36-50` | Stale closure in useEffect with suppressed eslint deps | Add onChange to deps, use functional update |

## Minor Issues (nice to fix)

| # | File:Line | Issue |
|---|-----------|-------|
| m1 | `program_generator.py:625,661` | `dict` type hint should be `dict[str, Any]` |
| m2 | `seed_kilo_exercises.py:68` | `valid_groups` set rebuilt every iteration |
| m3 | `seed_kilo_exercises.py:113` | `.save()` without `update_fields` |
| m4 | `classify_exercises.py:256` | `total_failed` never incremented |
| m5 | `views.py:85-87` | `difficulty_level` query param not validated against choices |
| m6 | `config-step.tsx:111-133` | Raw `<input>` instead of design system `<Input>` |
| m7 | `preview-step.tsx:81` | Array index used as React key |
| m8 | `preview-step.tsx:17-31` | No retry button in error state |
| m9 | `program-generator-wizard.tsx:101-106` | sessionStorage.setItem not wrapped in try/catch |
| m10 | `program_generator_screen.dart:583` | capitalize() crashes on empty string |
| m11 | `programs_screen.dart:979` | debugPrint left in code |

## Quality Score: 5/10

## Recommendation: BLOCK

Three security/correctness criticals (C1-C3) and a memory leak critical (C4) must be resolved. Multiple major issues affect UX and reliability.
