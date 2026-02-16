# Feature: Web Trainer Program Builder

## Priority
High

## User Story
As a trainer, I want to create, edit, and manage workout program templates from the web dashboard so that I can build programs efficiently on a large screen and assign them to my trainees without needing the mobile app.

## Acceptance Criteria

### Navigation & Page Structure
- [ ] AC-1: "Programs" nav link with Dumbbell icon appears in sidebar between "Trainees" and "Invitations"
- [ ] AC-2: `/programs` page shows list of trainer's program templates with name, difficulty, goal, duration, times used, and created date
- [ ] AC-3: Programs list supports search by name with 300ms debounce (matching existing trainee search pattern)

### Program Template CRUD
- [ ] AC-4: "Create Program" button opens program builder page at `/programs/new`
- [ ] AC-5: Program builder has metadata section: name (required), description, difficulty level (Beginner/Intermediate/Advanced), goal type (6 options), duration weeks (1-52)
- [ ] AC-6: Program builder has week/day/exercise editor: visual week tabs, day cards within each week, exercise list within each day
- [ ] AC-7: Each day has a name field (e.g., "Push Day"), rest day toggle, and exercise list
- [ ] AC-8: Exercises can be added via exercise picker dialog that shows exercise bank with muscle group filter and search
- [ ] AC-9: Each exercise entry has: exercise name (auto-filled from picker), sets, reps, weight, unit (lbs/kg), rest seconds fields
- [ ] AC-10: Exercises can be reordered within a day via up/down buttons
- [ ] AC-11: Exercises can be removed from a day with a delete button
- [ ] AC-12: Days default to 7 per week (Monday-Sunday) with all marked as rest days initially
- [ ] AC-13: "Save Template" button creates template via POST `/api/trainer/program-templates/`
- [ ] AC-14: Existing templates can be edited via `/programs/[id]/edit` using PATCH
- [ ] AC-15: Templates can be deleted with confirmation dialog

### Program Assignment
- [ ] AC-16: "Assign to Trainee" button on template detail/list opens assignment dialog
- [ ] AC-17: Assignment dialog shows trainee dropdown (fetched from API) and start date picker
- [ ] AC-18: Assignment calls POST `/api/trainer/program-templates/{id}/assign/` and shows success toast

### UX States
- [ ] AC-19: Loading state: skeleton on programs list, spinner on builder save
- [ ] AC-20: Empty state: "No program templates yet" with "Create your first program" CTA on programs list
- [ ] AC-21: Error state: error alert with retry on programs list, toast on save/delete/assign failures
- [ ] AC-22: Success feedback: toast on create, update, delete, and assign operations
- [ ] AC-23: Unsaved changes: browser beforeunload warning when navigating away from dirty builder form

### Exercise Picker
- [ ] AC-24: Exercise picker dialog shows exercises in a searchable, filterable list
- [ ] AC-25: Exercise picker supports filtering by muscle group (10 groups from backend)
- [ ] AC-26: Exercise picker shows exercise name and muscle group badge
- [ ] AC-27: Clicking an exercise in picker adds it to the current day and closes the dialog

## Edge Cases
1. Empty schedule — saving a template with zero exercises in any day should work (rest days are valid)
2. Long program name — name field has maxLength of 100, truncated in list with title tooltip
3. Large number of exercises — a day with 20+ exercises should scroll without layout issues
4. Concurrent edit — if template is deleted while editing, save should show clear error toast
5. Duplicate exercise — same exercise can appear multiple times in a day (different set schemes)
6. Week navigation — switching between weeks preserves unsaved changes in other weeks
7. Zero weeks — duration_weeks minimum is 1, max is 52, enforced in UI
8. Missing fields — save button disabled until name is provided; other fields are optional
9. Template with many uses — deleting a template that has been assigned should warn "This template has been used X times"
10. Exercise bank empty — if no exercises exist, exercise picker shows empty state with message

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Programs API fails | Error alert with retry button | Show ErrorState component |
| Save template fails (400) | Toast with validation error | Parse DRF error response |
| Save template fails (500) | Toast "Failed to save program" | Log error |
| Delete template fails | Toast "Failed to delete program" | Keep template in list |
| Assign template fails (400) | Toast with error (e.g., "Trainee not found") | Parse DRF error |
| Exercise fetch fails | Error state in picker dialog | Show retry button |
| Network timeout | Toast "Network error" | ApiError handler |

## UX Requirements
- **Loading state:** Skeleton cards on programs list (3 skeleton rows). Loader2 spinner on save/delete buttons.
- **Empty state:** Dumbbell icon, "No program templates yet", "Create your first program to get started", CTA button.
- **Error state:** ErrorState component with retry on list. Toast notifications on mutations.
- **Success feedback:** Toast "Program created" / "Program updated" / "Program deleted" / "Program assigned to [name]".
- **Responsive:** Programs list is table on desktop, stacked cards on mobile. Builder form is full-width with comfortable spacing.
- **Dark mode:** All components use theme tokens via shadcn/ui. No hardcoded colors.

## Technical Approach

### Files to create:
1. `web/src/types/program.ts` — TypeScript types for ProgramTemplate, Exercise, schedule JSON, assignment payload
2. `web/src/hooks/use-programs.ts` — React Query hooks: usePrograms, useProgram, useCreateProgram, useUpdateProgram, useDeleteProgram, useAssignProgram
3. `web/src/hooks/use-exercises.ts` — React Query hook: useExercises (with search + muscle group filter)
4. `web/src/app/(dashboard)/programs/page.tsx` — Programs list page
5. `web/src/app/(dashboard)/programs/new/page.tsx` — Create program page (hosts ProgramBuilder)
6. `web/src/app/(dashboard)/programs/[id]/edit/page.tsx` — Edit program page (hosts ProgramBuilder with existing data)
7. `web/src/components/programs/program-list.tsx` — Program templates table/list component
8. `web/src/components/programs/program-builder.tsx` — Main builder form with metadata + schedule editor
9. `web/src/components/programs/week-editor.tsx` — Week tab panel with day cards
10. `web/src/components/programs/day-editor.tsx` — Day card with exercise list
11. `web/src/components/programs/exercise-row.tsx` — Single exercise entry with sets/reps/weight fields
12. `web/src/components/programs/exercise-picker-dialog.tsx` — Dialog for browsing and selecting exercises
13. `web/src/components/programs/assign-program-dialog.tsx` — Dialog for assigning template to trainee
14. `web/src/components/programs/delete-program-dialog.tsx` — Confirmation dialog for delete

### Files to modify:
1. `web/src/lib/constants.ts` — Add PROGRAMS, EXERCISES, programDetail, programAssign, exerciseDetail API URLs
2. `web/src/components/layout/nav-links.tsx` — Add Programs nav link with Dumbbell icon

### Key design decisions:
- **Schedule state management:** Use React useState with the nested weeks→days→exercises JSON structure. Mutations operate on copies via structuredClone to avoid reference issues.
- **Week tabs:** shadcn Tabs component for week navigation. Each tab renders a WeekEditor.
- **Exercise picker:** Dialog with input search + muscle group Select filter. Fetches exercises with query params.
- **Form validation:** Zod schema for template metadata. Schedule validation done at save time (name required, duration_weeks 1-52).
- **Trainee list for assignment:** Reuse existing trainees API endpoint with simple Select dropdown.

### Dependencies:
- All shadcn/ui components already installed (Dialog, Tabs, Select, Input, Button, Card, Badge, Toast)
- React Query already configured
- apiClient already supports GET/POST/PATCH/DELETE

## Out of Scope
- Program image upload (backend supports it but not essential for MVP)
- Superset grouping UI (complex drag-and-drop, can be Phase 2)
- Progressive overload automation (auto-increment reps/weight)
- ProgramWeek model integration (intensity/volume modifiers, deload weeks)
- Copy week to all weeks functionality
- Drag-and-drop exercise reordering (up/down buttons instead)
- Exercise CRUD from web (trainers create custom exercises on mobile for now)
