# Dev Done: Web Trainer Program Builder

## Summary
Implemented a complete program builder feature for the web trainer dashboard, allowing trainers to create, edit, delete, and assign workout program templates from the web interface.

## Files Created (14)

### Types & Hooks
1. `web/src/types/program.ts` — TypeScript types for ProgramTemplate, Exercise, Schedule JSON, all enums (DifficultyLevel, GoalType, MuscleGroup) with label maps
2. `web/src/hooks/use-programs.ts` — 6 React Query hooks: usePrograms (paginated + search), useProgram, useCreateProgram, useUpdateProgram, useDeleteProgram, useAssignProgram
3. `web/src/hooks/use-exercises.ts` — useExercises hook with search + muscle group filter, 5-min staleTime

### Pages
4. `web/src/app/(dashboard)/programs/page.tsx` — Programs list page with search, empty state, pagination
5. `web/src/app/(dashboard)/programs/new/page.tsx` — Create program page hosting ProgramBuilder
6. `web/src/app/(dashboard)/programs/[id]/edit/page.tsx` — Edit program page with data loading

### Components
7. `web/src/components/programs/program-list.tsx` — DataTable with 7 columns (name, difficulty badge, goal, duration, times used, created date, actions dropdown)
8. `web/src/components/programs/program-builder.tsx` — Main builder: metadata form (name, description, duration, difficulty, goal) + schedule editor with week tabs
9. `web/src/components/programs/week-editor.tsx` — Renders 7 DayEditor cards per week
10. `web/src/components/programs/day-editor.tsx` — Day card with name field, rest day toggle, exercise list, add exercise button
11. `web/src/components/programs/exercise-row.tsx` — Exercise entry with sets/reps/weight/unit/rest inputs, move up/down, delete
12. `web/src/components/programs/exercise-picker-dialog.tsx` — Dialog with search + muscle group filter, exercise list with badges
13. `web/src/components/programs/assign-program-dialog.tsx` — Trainee dropdown + start date picker for program assignment
14. `web/src/components/programs/delete-program-dialog.tsx` — Confirmation dialog with times_used warning

## Files Modified (2)
1. `web/src/lib/constants.ts` — Added PROGRAM_TEMPLATES, programTemplateDetail, programTemplateAssign, EXERCISES URLs
2. `web/src/components/layout/nav-links.tsx` — Added Programs nav link with Dumbbell icon

## Key Decisions
- **Schedule state:** useState with nested JSON structure, structuredClone avoided in favor of spread operators for simple mutations
- **Week/duration sync:** Changing duration_weeks automatically adds/removes week tabs, preserving existing weeks
- **Exercise picker:** useDeferredValue for search debouncing, 100 page_size for single-page exercise list
- **Dirty state tracking:** useRef for isDirtyRef + beforeunload event for unsaved changes warning
- **Error handling:** ApiError body parsing shows field-specific validation errors from DRF
- **Dark mode:** All components use theme tokens (no hardcoded colors)

## How to Test
1. Navigate to `/programs` — should show empty state with CTA
2. Click "Create Program" — opens builder with metadata + 4-week schedule
3. Fill in name, toggle rest days off, add exercises via picker
4. Save — creates template, redirects to list
5. Click three-dot menu on a program → Edit, Assign, Delete
6. Search programs by name in the list
7. Assign a template to a trainee with start date
