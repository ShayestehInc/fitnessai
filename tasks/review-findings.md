# Code Review: Web Trainer Program Builder

## Review Date: 2026-02-15

## Files Reviewed
1. `web/src/types/program.ts`
2. `web/src/hooks/use-programs.ts`
3. `web/src/hooks/use-exercises.ts`
4. `web/src/lib/constants.ts`
5. `web/src/components/layout/nav-links.tsx`
6. `web/src/app/(dashboard)/programs/page.tsx`
7. `web/src/app/(dashboard)/programs/new/page.tsx`
8. `web/src/app/(dashboard)/programs/[id]/edit/page.tsx`
9. `web/src/components/programs/program-list.tsx`
10. `web/src/components/programs/program-builder.tsx`
11. `web/src/components/programs/week-editor.tsx`
12. `web/src/components/programs/day-editor.tsx`
13. `web/src/components/programs/exercise-row.tsx`
14. `web/src/components/programs/exercise-picker-dialog.tsx`
15. `web/src/components/programs/assign-program-dialog.tsx`
16. `web/src/components/programs/delete-program-dialog.tsx`

Also reviewed for cross-reference:
- `backend/workouts/models.py` (ProgramTemplate model, Exercise model)
- `backend/trainer/views.py` (ProgramTemplate views, AssignProgramTemplateView)
- `backend/trainer/serializers.py` (ProgramTemplateSerializer, AssignProgramSerializer)
- `backend/trainer/urls.py` (URL patterns)
- `web/src/lib/api-client.ts` (ApiError, request handling)
- `web/src/types/api.ts` (PaginatedResponse)
- `web/src/hooks/use-trainees.ts` (for assign dialog comparison)
- `web/src/components/shared/data-table.tsx` (DataTable)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `web/src/types/program.ts:1-34` | **Enum value case mismatch -- ALL CRUD operations will break.** The frontend defines `DifficultyLevel` as `"BEGINNER"`, `"INTERMEDIATE"`, `"ADVANCED"` and `GoalType` as `"BUILD_MUSCLE"`, `"FAT_LOSS"`, etc. (UPPERCASE). The backend Django model uses `TextChoices` with **lowercase** DB values: `'beginner'`, `'intermediate'`, `'advanced'`, `'build_muscle'`, `'fat_loss'`, etc. (see `backend/workouts/models.py:429-440`). When the frontend sends `"BEGINNER"` via POST/PATCH, DRF serializer validation rejects it with a 400 because `"BEGINNER"` is not a valid choice. When the backend returns `"beginner"` in GET responses, `DIFFICULTY_LABELS["beginner"]` is `undefined` because the Record only has uppercase keys. The entire programs list renders broken badges, and no create/update operation succeeds. | Change all `DifficultyLevel` values to lowercase: `BEGINNER: "beginner"`, `INTERMEDIATE: "intermediate"`, `ADVANCED: "advanced"`. Change all `GoalType` values to lowercase: `BUILD_MUSCLE: "build_muscle"`, `FAT_LOSS: "fat_loss"`, etc. Update the `DIFFICULTY_LABELS` and `GOAL_LABELS` Records to use lowercase keys. |
| C2 | `web/src/types/program.ts:36-62` | **MuscleGroup enum value case mismatch -- exercise picker filter is non-functional.** The frontend defines `MuscleGroup` as `"CHEST"`, `"BACK"`, `"SHOULDERS"`, etc. (UPPERCASE). The backend Exercise model uses lowercase: `'chest'`, `'back'`, `'shoulders'`, etc. (see `backend/workouts/models.py:17-27`). When the exercise picker sends `?muscle_group=CHEST`, the backend query `queryset.filter(muscle_group=muscle_group)` matches zero rows because all stored values are lowercase. Every muscle group filter button in the exercise picker returns empty results. Additionally, `MUSCLE_GROUP_LABELS[exercise.muscle_group]` in the picker will be `undefined` for exercises returned from the API because the API returns lowercase values. | Change all `MuscleGroup` values to lowercase: `CHEST: "chest"`, `BACK: "back"`, etc. Update the `MUSCLE_GROUP_LABELS` Record keys to match. |
| C3 | `web/src/app/(dashboard)/programs/[id]/edit/page.tsx:16` | **NaN programId causes eternal loading state.** `parseInt("abc", 10)` returns `NaN`. The `useProgram` hook has `enabled: id > 0`, and `NaN > 0` evaluates to `false`, so the query never fires. `isLoading` remains truthy (query is idle/disabled, which TanStack Query may report as loading depending on version). The user sees an infinite loading spinner with no explanation. There is no validation that the URL parameter is a valid numeric ID. | Add a guard after `parseInt`: `if (isNaN(programId) || programId <= 0) { return <div className="space-y-6"><PageHeader title="Edit Program" /><ErrorState message="Invalid program ID" /></div>; }` |
| C4 | `web/src/hooks/use-exercises.ts:16` | **Hardcoded `page_size=100` with no pagination silently truncates results.** If a trainer has more than 100 exercises (public + custom), only the first 100 are shown. The remaining exercises are invisible with no indication to the user that results are truncated. There is no "Load more" button, no scroll-based pagination, and no count display. Established trainers with large custom exercise libraries will be unable to find their exercises. | Implement either: (a) infinite scroll pagination in the exercise picker using `useInfiniteQuery`, or (b) at minimum, display `Showing {results.length} of {count}` when `data.count > data.results.length` and increase `page_size` to a more generous value. |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `web/src/app/(dashboard)/programs/page.tsx:17-22` | **Search is completely non-functional.** The frontend sends `?search=` to `ProgramTemplateListCreateView`, but the backend view has NO `filter_backends` or `search_fields` configured (unlike `TraineeListView` which has `filter_backends = [SearchFilter]` and `search_fields`). DRF silently ignores the unknown query parameter. The trainer types a search query, the API returns unfiltered results, and the trainer sees no change. This creates a confusing, broken UX. | Either: (a) add `filter_backends = [SearchFilter]` and `search_fields = ['name', 'description']` to `ProgramTemplateListCreateView` in the backend, or (b) remove the search UI from the frontend until backend support exists. Option (a) is strongly preferred since the ticket explicitly requires search (AC-3). |
| M2 | `web/src/components/programs/program-list.tsx:121-170` | **Edit/Delete actions shown for templates the trainer does not own.** The backend list endpoint returns `Q(created_by=user) | Q(is_public=True)` -- public templates from other trainers appear in the list. The frontend renders Edit/Delete/Assign actions for ALL templates without checking ownership. When the trainer clicks Edit or Delete on another trainer's public template, the backend returns 404 (because `ProgramTemplateDetailView` scopes to `created_by=user` only). The error toast says "Failed to load program" or "Failed to delete program" with no explanation of why. | Compare `program.created_by` with the current user's ID (available from auth context). For templates the trainer doesn't own, hide Edit/Delete and show only "Assign" and optionally "Clone". Alternatively, add an `is_owner` boolean computed field to the serializer. |
| M3 | `web/src/components/programs/program-builder.tsx:96-98` | **Dirty state flag fires on initial mount, causing false unsaved changes warning.** The `useEffect` at line 96 sets `isDirtyRef.current = true` whenever any dependency changes. Since `name`, `description`, `durationWeeks`, etc. are initialized from props/defaults during mount, the effect fires immediately on the first render. If the trainer navigates to `/programs/new` and then tries to leave without making any changes, the browser shows "Changes you made may not be saved" even though nothing was changed. | Use a mount guard: add `const hasMountedRef = useRef(false)` and in the effect body, check `if (!hasMountedRef.current) { hasMountedRef.current = true; return; }` before setting `isDirtyRef.current = true`. |
| M4 | `web/src/components/programs/program-builder.tsx:151-179` | **Double-click race condition can create duplicate programs.** Between the user clicking Save and React re-rendering with `isPending=true` (which disables the button), there is a synchronous gap where `handleSave` can be invoked twice. Both calls reach `createMutation.mutateAsync()` before the first one sets `isPending`, resulting in two identical programs created on the backend. | Add a ref-based guard: `const savingRef = useRef(false)` at the top of the component. At the start of `handleSave`: `if (savingRef.current) return; savingRef.current = true;`. In the `finally` block: `savingRef.current = false;`. |
| M5 | `web/src/components/programs/assign-program-dialog.tsx:40` | **Trainee dropdown limited to first page (20 trainees).** `useTrainees(1, "")` fetches only page 1 with the default page size of 20. Trainers with more than 20 trainees cannot assign programs to trainees beyond the first page. The dropdown gives no indication that more trainees exist. | Either: (a) pass `page_size=200` to fetch all trainees in one request (acceptable for dropdowns), or (b) implement a searchable combobox that filters trainees on the server as the trainer types. Option (b) is the better UX. |
| M6 | `web/src/components/programs/program-builder.tsx:157-168` | **Unsafe `as` type casts on payload.** The payload is typed as `CreateProgramPayload | UpdateProgramPayload`, then cast with `as CreateProgramPayload` and `as UpdateProgramPayload` at the call sites. These casts bypass TypeScript's type checking. If the payload structure is wrong (e.g., missing `schedule_template` for create), the error surfaces at runtime, not compile time. | Build separate payload objects: `if (isEditing) { const payload: UpdateProgramPayload = { ... }; await updateMutation.mutateAsync(payload); } else { const payload: CreateProgramPayload = { ... }; await createMutation.mutateAsync(payload); }`. |
| M7 | `web/src/types/program.ts:117-131` | **`ProgramTemplate` type missing `nutrition_template` and `created_by_email` fields returned by the backend serializer.** The backend `ProgramTemplateSerializer` returns `nutrition_template` and `created_by_email` in every response, but these fields are absent from the frontend type. `created_by_email` is useful for displaying ownership in the list (needed for M2 fix). `nutrition_template` should be typed even if unused, to maintain type accuracy. | Add to the `ProgramTemplate` interface: `nutrition_template: Record<string, unknown> | null;` and `created_by_email: string;`. |
| M8 | `web/src/components/programs/exercise-row.tsx:85` | **String reps values silently converted to 0.** `ScheduleExercise.reps` is typed as `number | string` (to support ranges like `"8-12"`). The input renders `value={typeof exercise.reps === "number" ? exercise.reps : 0}`. When the backend returns `reps: "8-12"`, the input displays `0`. If the trainer then changes any other field on that row (e.g., weight), `onUpdate` fires with `reps: 0`, permanently destroying the original range value. | Either: (a) change the reps field to a text input when the value is a string, preserving the range, or (b) restrict `reps` to `number` only and document that the web builder does not support range notation. Option (a) is more robust. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `web/src/components/programs/program-builder.tsx:207-215` | `<textarea>` uses inline className replicating shadcn Input styles instead of using the shadcn `Textarea` component. If Input styles are updated, the textarea will become inconsistent. | Use the shadcn `Textarea` component. |
| m2 | `web/src/components/programs/program-builder.tsx:235-249` | Two `<select>` elements use long inline className strings instead of a shadcn `Select` component. Inconsistent with the rest of the UI. | Use the shadcn `Select` component for difficulty and goal dropdowns. |
| m3 | `web/src/components/programs/program-builder.tsx:239` | `e.target.value as DifficultyLevel | ""` is an unsafe cast. If a browser extension injects an unexpected option, the cast is incorrect. Low risk. | Validate against the enum before setting state. |
| m4 | `web/src/components/programs/program-list.tsx:81` | `row.goal_type as GoalType` cast without validation. If the backend adds a new GoalType value, `GOAL_LABELS[row.goal_type as GoalType]` returns `undefined` and renders nothing. | Use fallback: `GOAL_LABELS[row.goal_type as GoalType] ?? row.goal_type`. |
| m5 | `web/src/hooks/use-programs.ts:1`, `use-exercises.ts:1` | `"use client"` directive is unnecessary in hook files. Hooks are not components. The calling component determines the render mode. Harmless but noisy. | Remove `"use client"` from hook files. |
| m6 | `web/src/components/programs/week-editor.tsx:12` | `updateDay` function is recreated on every render, causing all 7 `DayEditor` children to re-render even when only one day changes. | Wrap `updateDay` in `useCallback`. |
| m7 | `web/src/components/programs/day-editor.tsx:19-56` | All handler functions (`updateName`, `toggleRestDay`, `addExercise`, `updateExercise`, `removeExercise`, `moveExercise`) are recreated on every render. With 7 days x N exercises, this creates significant re-render overhead. | Wrap handlers in `useCallback` with appropriate dependencies. |
| m8 | `web/src/components/programs/exercise-picker-dialog.tsx:59-61` | Search and filter state not reset when dialog opens. If the user opens the dialog, types a search, closes without selecting, and reopens, the stale search is still shown. `handleSelect` resets state, but closing without selecting does not. | Reset `search` and `selectedGroup` in `onOpenChange` when the dialog opens. |
| m9 | `web/src/components/programs/assign-program-dialog.tsx:35-38` | `startDate` default uses UTC via `toISOString()`. For a trainer in UTC-8 at 11pm, `new Date().toISOString().split("T")[0]` returns tomorrow's date. | Use `new Date().toLocaleDateString('en-CA')` which returns `YYYY-MM-DD` in the local timezone. |
| m10 | `web/src/components/programs/assign-program-dialog.tsx:62` | `selectedTraineeId` is not reset when dialog closes via Cancel or outside click. If the trainer selects a trainee, cancels, and reopens, the previous selection persists. | Reset `selectedTraineeId` and `startDate` in `onOpenChange` when `open` becomes `false`. |
| m11 | `web/src/components/programs/program-builder.tsx:87` | If `existingProgram.schedule_template` is not null but has fewer weeks than `duration_weeks`, the schedule and week tabs will be out of sync. | After initializing schedule from existing data, reconcile: pad with empty weeks if `schedule.weeks.length < duration_weeks`, trim if greater. |
| m12 | `web/src/components/programs/delete-program-dialog.tsx:36-38` | Catch block discards the error: `catch { toast.error("Failed to delete program") }`. If deletion fails with a specific server message (e.g., "Cannot delete template with active assignments"), the user never sees it. | Catch as `catch (error)` and use the `getErrorMessage` helper from `program-builder.tsx` (extract to a shared utility). |
| m13 | `web/src/components/programs/program-builder.tsx:92` | `useUpdateProgram(existingProgram?.id ?? 0)` initializes a mutation hook with id=0 for new programs. While the mutation is never called in create mode, it creates unnecessary TanStack Query internals. | Not easily fixable without violating hooks rules. Low priority. Document with a comment. |

---

## Security Concerns

1. **No XSS risk.** React JSX auto-escapes string output. No `dangerouslySetInnerHTML` usage. Program names and descriptions are rendered as text content. -- PASS
2. **No CSRF concerns.** API uses JWT Bearer token auth, not session cookies. -- PASS
3. **No IDOR on detail/update/delete.** Backend `ProgramTemplateDetailView.get_queryset()` correctly scopes to `created_by=user`. Trainers cannot edit/delete other trainers' private templates. -- PASS (but frontend shows misleading UI for public templates; see M2)
4. **Assignment validates trainee ownership.** Backend `AssignProgramSerializer.validate_trainee_id()` checks `parent_trainer=trainer`. Trainers cannot assign programs to other trainers' trainees. -- PASS
5. **No secrets exposed.** `NEXT_PUBLIC_API_URL` is designed to be public. No private keys, tokens, or credentials in reviewed code. -- PASS
6. **Client-side input limits supplemented by backend validation.** `maxLength` on name (100), description (500), duration (1-52), sets (1-20), etc. are client-side only. Backend enforces `max_length=255` for name and `MinValueValidator(1)/MaxValueValidator(52)` for duration_weeks. -- PASS

---

## Performance Concerns

1. **C4 -- Unbounded exercise fetch.** `page_size=100` with no pagination. Large exercise banks will have truncated results.
2. **M5 -- Truncated trainee list.** Assignment dialog fetches only 20 trainees, missing trainers with large client bases.
3. **m6/m7 -- Excessive re-renders.** `WeekEditor` and `DayEditor` recreate all handler functions on every render. With 7 days x 10 exercises = 70 `ExerciseRow` components, a single keystroke in one input causes all 70 rows to re-render because every handler identity changes. Should use `useCallback` and consider `React.memo` on `ExerciseRow`.
4. **All week tab panels mounted simultaneously.** Shadcn/Radix `TabsContent` renders all panels and hides inactive ones with CSS. For a 52-week program, 52 `WeekEditor` components are mounted (52 x 7 = 364 `DayEditor` instances). This could cause slow initial renders and high memory usage. Consider lazy-rendering only the active week using `forceMount={false}` or conditional rendering.
5. **No debounce on exercise picker search API calls.** `useDeferredValue` defers rendering but does not prevent API calls. Every keystroke triggers a new `useExercises` query (deferred but still fired). A proper debounce (300ms) would reduce unnecessary network requests.

---

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | Programs nav link with Dumbbell icon positioned between Trainees and Invitations in `nav-links.tsx` |
| AC-2 | FAIL | List renders columns correctly in code, but difficulty badges and goal labels will show `undefined` due to enum case mismatch (C1) |
| AC-3 | FAIL | Search UI exists but backend `ProgramTemplateListCreateView` has no `search_fields` -- parameter is silently ignored (M1) |
| AC-4 | PASS | "Create Program" button links to `/programs/new` |
| AC-5 | FAIL | Metadata section is structurally complete, but difficulty/goal values sent as UPPERCASE will be rejected by backend with 400 (C1) |
| AC-6 | PASS | Week tabs, day cards, exercise lists implemented |
| AC-7 | PASS | Day name field, rest day toggle, exercise list all functional |
| AC-8 | FAIL | Exercise picker dialog exists with search and muscle group filter, but filter sends UPPERCASE values that match nothing (C2) |
| AC-9 | PASS | Sets, reps, weight, unit, rest_seconds fields all present and editable |
| AC-10 | PASS | Up/down buttons with proper disable at first/last position |
| AC-11 | PASS | Delete button removes exercise from day |
| AC-12 | PASS | 7 days per week (Monday-Sunday), all rest days by default |
| AC-13 | FAIL | Save triggers POST but will receive 400 due to enum mismatch (C1) |
| AC-14 | FAIL | Same issue as AC-13 for PATCH |
| AC-15 | PASS | Delete confirmation dialog with times_used warning |
| AC-16 | PASS | "Assign to Trainee" in dropdown menu |
| AC-17 | PARTIAL | Trainee dropdown exists but shows only first 20 trainees (M5) |
| AC-18 | PASS | Assignment calls correct endpoint, shows success toast with trainee name |
| AC-19 | PASS | LoadingSpinner on list, Loader2 spinner on save button |
| AC-20 | PASS | Empty state with Dumbbell icon and "Create your first program" CTA |
| AC-21 | PASS | ErrorState with retry on list, toast on mutation failures |
| AC-22 | PASS | Toast messages for create/update/delete/assign |
| AC-23 | PARTIAL | beforeunload fires but also triggers on pristine forms (M3) |
| AC-24 | PASS | Searchable exercise list in dialog |
| AC-25 | FAIL | Muscle group filter sends wrong case values, returns empty results (C2) |
| AC-26 | PARTIAL | Exercise name shown, but muscle group badge renders `undefined` for API values (C2) |
| AC-27 | PASS | Clicking exercise adds to day and closes dialog |

**Summary:** 7 FAIL, 3 PARTIAL, 17 PASS

---

## Quality Score: 4/10

### Breakdown:
- **Correctness: 2/10** -- The enum case mismatch (C1/C2) is a fundamental data contract violation between frontend and backend that breaks all core CRUD operations and data display. This is not an edge case -- it affects 100% of interactions.
- **Architecture: 7/10** -- Clean component hierarchy (Builder > WeekEditor > DayEditor > ExerciseRow). Proper separation of hooks, types, and components. Good use of React Query for server state.
- **Type Safety: 5/10** -- Types are defined but the `as` casts (M6, m3, m4) weaken them. The enum values don't match the actual API contract, making the types actively misleading.
- **Accessibility: 8/10** -- Good use of `aria-label`, `aria-hidden`, `aria-pressed`, `sr-only` labels, `htmlFor` associations, focus-visible styles. Above average for a typical implementation.
- **UX States: 8/10** -- Loading, empty, error, and success states are implemented for all primary flows. Minor gap with premature dirty state (M3).
- **Error Handling: 6/10** -- API errors are caught and displayed via toast. Some catch blocks discard error details (m12). Double-click race condition (M4) is unhandled.
- **Performance: 5/10** -- No memoization on frequently re-rendered components. All week panels mounted simultaneously. No debounce on exercise search.

### Strengths:
- Well-organized component structure following feature-first architecture
- Comprehensive UX states (loading, empty, error, success) across all views
- Strong accessibility with ARIA attributes, keyboard navigation, and screen reader support
- Clean React Query integration with proper cache invalidation
- Good error message parsing from DRF responses via `getErrorMessage`

### Critical Weakness:
The enum case mismatch is a single-point-of-failure that makes the entire feature non-functional against the real backend. Every program create, program edit, exercise filter, difficulty badge, and goal label is broken.

---

## Recommendation: BLOCK

**Rationale:** The enum case mismatch (C1/C2) between the frontend TypeScript types and the backend Django TextChoices is a showstopper. With this bug present:
- No program can be created (400 validation error from DRF)
- No program can be updated (400 validation error)
- Program list displays `undefined` for difficulty and goal badges
- Exercise picker muscle group filter returns empty results
- Exercise picker muscle group badges display `undefined`

These are not edge cases or degraded experiences -- they are complete functional failures on every user interaction. Combined with non-functional search (M1), misleading ownership UI (M2), false dirty state warnings (M3), and the double-click race condition (M4), the feature cannot ship.

**Must fix before re-review:**
1. **C1** -- Fix DifficultyLevel and GoalType enum values to lowercase
2. **C2** -- Fix MuscleGroup enum values to lowercase
3. **C3** -- Handle NaN/invalid program ID on edit page
4. **C4** -- Address unbounded exercise fetch (at minimum, truncation warning)
5. **M1** -- Add backend search support or remove search UI
6. **M2** -- Hide Edit/Delete for templates trainer doesn't own
7. **M3** -- Fix false dirty state on initial render
8. **M4** -- Guard against double-click duplicate creation
9. **M5** -- Trainee dropdown must show all trainees
