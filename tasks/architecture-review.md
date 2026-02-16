# Architecture Review: Trainer Program Builder (Pipeline 12)

## Review Date: 2026-02-15

## Files Reviewed

### New Types
- `web/src/types/program.ts` -- TypeScript types for programs, exercises, schedule JSON, enums, payloads

### New Hooks
- `web/src/hooks/use-programs.ts` -- React Query hooks for program CRUD and assignment
- `web/src/hooks/use-exercises.ts` -- React Query hook for exercise listing with search/filter

### New Components (8 files)
- `web/src/components/programs/program-builder.tsx` -- Main form component (create/edit)
- `web/src/components/programs/program-list.tsx` -- DataTable wrapper with columns
- `web/src/components/programs/week-editor.tsx` -- Week-level schedule editor
- `web/src/components/programs/day-editor.tsx` -- Day-level schedule editor
- `web/src/components/programs/exercise-row.tsx` -- Inline exercise parameter editor
- `web/src/components/programs/exercise-picker-dialog.tsx` -- Exercise search/filter dialog
- `web/src/components/programs/assign-program-dialog.tsx` -- Assign to trainee dialog
- `web/src/components/programs/delete-program-dialog.tsx` -- Delete confirmation dialog

### New Pages (3 files)
- `web/src/app/(dashboard)/programs/page.tsx` -- Programs list page
- `web/src/app/(dashboard)/programs/new/page.tsx` -- Create program page
- `web/src/app/(dashboard)/programs/[id]/edit/page.tsx` -- Edit program page

### Modified Files
- `web/src/lib/constants.ts` -- Added API_URLS entries for programs and exercises
- `web/src/lib/error-utils.ts` -- New shared error message extractor
- `web/src/components/layout/nav-links.tsx` -- Programs nav link added

### Comparison Files (existing patterns)
- `web/src/types/trainer.ts`, `web/src/types/api.ts`
- `web/src/hooks/use-trainees.ts`, `web/src/hooks/use-invitations.ts`, `web/src/hooks/use-analytics.ts`
- `web/src/app/(dashboard)/trainees/page.tsx`, `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/components/shared/data-table.tsx`, `web/src/components/shared/empty-state.tsx`, `web/src/components/shared/error-state.tsx`, `web/src/components/shared/page-header.tsx`, `web/src/components/shared/loading-spinner.tsx`
- `web/src/components/trainees/trainee-table.tsx`, `web/src/components/invitations/create-invitation-dialog.tsx`
- `web/src/lib/api-client.ts`
- Backend: `backend/workouts/models.py`, `backend/trainer/serializers.py`, `backend/trainer/views.py`, `backend/trainer/urls.py`

---

## Architectural Alignment

- [x] Follows existing layered architecture (Types -> Hooks -> Components -> Pages)
- [x] Models/schemas in correct locations (`types/program.ts` for all program-related types)
- [x] No business logic in pages (pages are thin, delegate to hooks and components)
- [x] Consistent with existing patterns (matches trainees, invitations, analytics architecture)
- [x] API constants centralized in `lib/constants.ts` (not scattered)
- [x] Shared components properly reused (`DataTable`, `EmptyState`, `ErrorState`, `PageHeader`, `LoadingSpinner`)

### Layering Assessment: STRONG

The feature follows the exact same layer hierarchy established by trainees, invitations, and analytics:

```
Types (program.ts)
  -> Hooks (use-programs.ts, use-exercises.ts)
    -> Components (programs/*.tsx)
      -> Pages (programs/**/page.tsx)
```

Pages are thin -- `new/page.tsx` is 16 lines, `page.tsx` is 99 lines, and the edit page is 60 lines. All substantial logic lives in the `ProgramBuilder` component and hook layer. This is correct.

The component decomposition is well-structured:
- `ProgramBuilder` -> `WeekEditor` -> `DayEditor` -> `ExerciseRow` (hierarchical schedule editor)
- `ExercisePickerDialog`, `AssignProgramDialog`, `DeleteProgramDialog` (flat dialog components)
- `ProgramList` (table wrapper, consistent with `TraineeTable`)

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| TypeScript types match backend serializer | PASS | `ProgramTemplate` fields align with `ProgramTemplateSerializer.Meta.fields`. All 14 serializer fields have corresponding TS properties. |
| Schedule JSON structure sound | PASS | `Schedule > ScheduleWeek[] > ScheduleDay[] > ScheduleExercise[]` is a clean nested structure that matches the backend `schedule_template` JSONField. |
| Enum values match backend choices | PASS | `DifficultyLevel` enum values (`beginner`, `intermediate`, `advanced`) exactly match `ProgramTemplate.DifficultyLevel.choices`. Same for `GoalType` (6 values) and `MuscleGroup` (10 values). |
| Payload types match API expectations | PASS | `CreateProgramPayload` and `UpdateProgramPayload` send only writable fields. Read-only fields (`created_by`, `times_used`, timestamps) are excluded. |
| `AssignProgramPayload` matches `AssignProgramSerializer` | PASS | Frontend sends `trainee_id` (int) and `start_date` (string). Backend serializer expects same. `customize_schedule` and `customize_nutrition` optional fields not yet exposed on frontend (acceptable -- they have `default=dict`). |
| Nullable fields handled correctly | NOTE | Backend `difficulty_level` and `goal_type` have defaults (`INTERMEDIATE`, `BUILD_MUSCLE`) and no `null=True`/`blank=True`, so they will never be null from the API. Frontend types them as `DifficultyLevel | null` and `GoalType | null`. This is defensively safe (more permissive than the contract) but could mislead future developers into thinking null is an expected value. Not a breaking issue. |
| Exercise type completeness | FIXED | Frontend `Exercise` type was missing `created_by_email` which the backend `ExerciseSerializer` returns. Added the field. |
| No N+1 query patterns in frontend | PASS | All data fetching is done at the hook level with single API calls. No component-level data fetching that could cause waterfalls. |
| Index coverage | PASS | Backend model has indexes on `created_by`, `is_public`, `goal_type`, `difficulty_level` -- covers the query patterns in `ProgramTemplateListCreateView.get_queryset()`. |
| Migrations | N/A | No schema changes in this feature. All frontend-only changes consuming existing backend API. |

---

## API Design Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| URL structure RESTful | PASS | `program-templates/`, `program-templates/<id>/`, `program-templates/<id>/assign/` follows REST conventions. Uses `api/trainer/` prefix consistent with all trainer endpoints. |
| Consistent with existing patterns | PASS | URL patterns in `constants.ts` follow the exact same structure as trainees, invitations, notifications: static base constant + dynamic detail function. |
| Error handling consistent | PASS | All mutations use `getErrorMessage()` from `error-utils.ts` which extracts DRF structured error responses. Consistent with `ApiError` pattern in `api-client.ts`. |
| Pagination support | PASS | Programs list hook passes `page` and `search` params. Backend view uses `SearchFilter` with `search_fields = ['name', 'description']`. Frontend uses `PaginatedResponse<T>` type. |
| HTTP methods correct | PASS | Create uses POST, update uses PATCH (partial update), delete uses DELETE, list/detail use GET. Matches DRF generics. |

---

## Frontend Patterns Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Hook patterns match existing | PASS | `usePrograms`, `useProgram`, `useCreateProgram`, `useUpdateProgram`, `useDeleteProgram` follow the exact same patterns as `useTrainees`/`useTrainee` and `useCreateInvitation`/`useCancelInvitation`. |
| Query key structure consistent | PASS | Uses `["programs", page, search]` for list, `["program", id]` for detail. Matches `["trainees", page, search]` / `["trainee", id]` pattern. |
| Query invalidation correct | PASS | Create/delete invalidate `["programs"]` (list). Update invalidates both `["programs"]` and `["program", id]` (list + detail). Assign invalidates `["programs"]` and `["trainees"]` (cross-feature). All correct. |
| Caching strategy appropriate | PASS | Exercises use `staleTime: 5 * 60 * 1000` (5 min) since the exercise library changes rarely. Programs use default staleTime (0) since they change frequently. Matches analytics hook pattern. |
| State management consistent | PASS | `ProgramBuilder` uses `useState` for form fields and `useCallback` + `useRef` for performance-sensitive operations. Dialog components use `useState` for open/close. No `useReducer` needed -- form state is straightforward. |
| Shared components reused | PASS | `DataTable`, `EmptyState`, `ErrorState`, `PageHeader`, `LoadingSpinner`, `Skeleton`, `ScrollArea` all reused from shared library. No duplicate implementations. |
| Search debouncing | NOTE | Programs page uses `useDeferredValue` while Trainees page uses custom `useDebounce`. Both work correctly. `useDeferredValue` is the more modern React 18+ pattern (no fixed delay, lets React prioritize). This is an acceptable evolution, not a bug. |
| Dialog pattern consistent | PASS | `AssignProgramDialog` and `DeleteProgramDialog` follow the same controlled `Dialog` pattern with `open`/`onOpenChange` as `CreateInvitationDialog`. Trigger passed as prop for use inside `DropdownMenu`. |
| Edit page params handling | PASS | Uses `use(params)` for async params (Next.js 15 pattern), same as `trainees/[id]/page.tsx`. Validates ID with `parseInt` + `isNaN` guard. |

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | `useAllTrainees` | Fetches with `page_size=200` hardcoded ceiling. For trainers with 200+ trainees, the assign dialog dropdown would show an incomplete list without warning. | **Medium risk.** For now, 200 trainees covers the vast majority of trainers (business tier caps are well below 200). Long-term, consider: (a) a dedicated unpaginated endpoint for select dropdowns, or (b) a searchable combobox in the assign dialog that searches on keystroke (matching the exercise picker pattern). No immediate fix needed. |
| 2 | Exercise picker `page_size=100` | Fetches 100 exercises at a time. With large custom exercise libraries, some exercises may be hidden. | **Low risk.** The picker includes search and muscle group filter, so users can find specific exercises even with truncation. The "Showing X of Y" message properly informs users when results are truncated. |
| 3 | Schedule structure for 52-week programs | A 52-week program with 7 days per week and 10+ exercises per day would create a large JSON payload (52 x 7 x 10 = 3640 exercise entries). | **Low risk.** JSON compression is efficient, and the backend `JSONField` handles large objects. The frontend uses `Tabs` to render only one week at a time, avoiding DOM bloat. `reconcileSchedule` efficiently handles week count changes without recreating existing data. |
| 4 | Column memoization | `makeColumns` was called on every render without memoization, recreating column definitions (including closures) needlessly. | **Fixed.** Added `useMemo` wrapping the `makeColumns` call with `currentUserId` dependency. |

---

## Technical Debt Assessment

| # | Description | Severity | Status |
|---|-------------|----------|--------|
| 1 | `useAllTrainees` was placed in `use-programs.ts` -- a trainee data hook inside a programs hook file breaks feature-scoped hook layering. Other features needing an "all trainees" list would not know to look in `use-programs.ts`. | Medium | **FIXED** -- Moved to `use-trainees.ts`. Updated import in `assign-program-dialog.tsx`. |
| 2 | `Exercise` type was missing `created_by_email` field that the backend `ExerciseSerializer` returns. Incomplete type contracts can cause confusion when developers reference the type. | Low | **FIXED** -- Added `created_by_email: string | null` to `Exercise` interface. |
| 3 | Column definitions in `ProgramList` recreated on every render without memoization. | Low | **FIXED** -- Added `useMemo` around `makeColumns` call. |
| 4 | Raw `<textarea>` and `<select>` elements use inline className strings duplicating input styling instead of using shadcn/ui `Textarea` and `Select` components. Creates maintenance burden if design system input styles change. | Low | Not fixed. The inline styles match the current design system and work correctly. Migrating to shadcn `Select` and `Textarea` components is a future cleanup task that does not affect functionality or architecture. |
| 5 | `ProgramBuilder` at 365 lines is the largest component. The metadata form (name, description, duration, difficulty, goal) could be extracted into a `ProgramMetadataForm` sub-component. | Low | Not fixed. All state is tightly coupled (duration changes affect schedule), making extraction non-trivial without lifting state into a parent or using a form context. Current size is manageable. |

**Net technical debt: Neutral.** Three items of minor debt were introduced (items 4-5) but three were also fixed during this review (items 1-3). The `error-utils.ts` shared module is a net positive -- it can be reused by all future features.

---

## Positive Architecture Decisions

### 1. `reconcileSchedule` function
Elegantly handles the relationship between `durationWeeks` and the schedule state. Adding weeks preserves existing data, removing weeks truncates from the end. This prevents data loss when trainers adjust program length.

### 2. Tabs for week navigation
Only renders the active week's DOM, preventing performance issues with long programs. This is the right trade-off for a form that could have 52 weeks x 7 days x N exercises.

### 3. `isDirtyRef` + `beforeunload` pattern
Protects trainers from losing unsaved work. Using a ref (not state) avoids unnecessary re-renders while still being accessible in the event handler closure.

### 4. `savingRef` guard
Prevents double-submission of the save action, which is especially important for large schedule payloads that take time to transmit.

### 5. Exercise picker with `useDeferredValue`
Provides responsive search without debounce delay, using React 18 concurrent features. The search input stays responsive while the API call and results rendering are deferred.

### 6. Cross-feature query invalidation
`useAssignProgram` invalidates both `["programs"]` and `["trainees"]` query keys, ensuring that if a trainer assigns a program and navigates to the trainees list, the trainee's `current_program` data is fresh.

### 7. `error-utils.ts` shared module
Extracts DRF-style error responses into human-readable messages. Reusable across all features. Properly handles both structured error objects and plain status text.

### 8. Component decomposition hierarchy
`ProgramBuilder -> WeekEditor -> DayEditor -> ExerciseRow` mirrors the data model hierarchy (`Schedule -> ScheduleWeek -> ScheduleDay -> ScheduleExercise`). Each component is responsible for exactly one level of the tree. Updates flow up via `onUpdate` callbacks, down via props. Clean unidirectional data flow.

---

## Architecture Score: 9/10

### Breakdown:
- **Layering:** 9/10 -- Clean types -> hooks -> components -> pages hierarchy. One misplaced hook (now fixed).
- **Data Model:** 9/10 -- TypeScript types faithfully mirror backend serializers. Schedule JSON structure is sound. One missing field (now fixed).
- **API Design:** 10/10 -- Consistent URL patterns, proper pagination, correct REST verbs, centralized constants.
- **Frontend Patterns:** 9/10 -- Follows all established conventions. Proper React Query usage with correct cache invalidation. Minor inconsistency in search debouncing approach (acceptable evolution).
- **Scalability:** 9/10 -- Appropriate for current scale. `page_size=200` ceiling is the main limitation, acceptable given business constraints.
- **Technical Debt:** 9/10 -- Very little debt introduced. Three minor items fixed during review. Two remaining are cosmetic.

### Why not 10/10:
- The `page_size=200` hardcoded ceiling in `useAllTrainees` is a latent scalability concern that will need addressing when the platform grows.
- Raw HTML `<select>` and `<textarea>` instead of shadcn components creates minor style maintenance risk.
- `ProgramBuilder` at 365 lines could benefit from sub-component extraction, though the tight state coupling makes this non-trivial.

## Recommendation: APPROVE

The Trainer Program Builder is architecturally sound. It follows every established pattern in the codebase, introduces no significant technical debt, and makes smart decisions about component decomposition, state management, and cache invalidation. The three issues found during review have been fixed. The remaining items are cosmetic and can be addressed in future cleanup passes.

---

## Fixes Applied During Review

### 1. Moved `useAllTrainees` from `use-programs.ts` to `use-trainees.ts`
Restores feature-scoped hook layering. The trainee data hook now lives alongside `useTrainees`, `useTrainee`, and `useTraineeActivity` where developers would expect to find it.
- Modified: `web/src/hooks/use-programs.ts` (removed function and `TraineeListItem` import)
- Modified: `web/src/hooks/use-trainees.ts` (added function)
- Modified: `web/src/components/programs/assign-program-dialog.tsx` (updated import path from `use-programs` to `use-trainees`)

### 2. Added `created_by_email` to `Exercise` type
Completes the API contract to match `ExerciseSerializer` output fields.
- Modified: `web/src/types/program.ts` (added `created_by_email: string | null`)

### 3. Added `useMemo` for column definitions in `ProgramList`
Prevents unnecessary object recreation on every render cycle.
- Modified: `web/src/components/programs/program-list.tsx` (added `useMemo` import and wrapped `makeColumns` call with `currentUserId` dependency)

---

**Review completed by:** Architect Agent
**Date:** 2026-02-15
**Pipeline:** 12 -- Trainer Program Builder
