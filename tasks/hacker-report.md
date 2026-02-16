# Hacker Report: Trainer Program Builder (Pipeline 12)

## Date: 2026-02-15

## Focus Areas
Trainer Program Builder: program list page, create/edit program builder, exercise picker dialog, day/week editor, exercise row configuration, assign/delete dialogs, supporting hooks, types, and error utilities.

---

## Dead Buttons & Non-Functional UI

| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | High | ExercisePickerDialog | Exercise selection | User can add multiple exercises in one session | Dialog closed after each selection, requiring reopen for every exercise -- **FIXED**: dialog now stays open with checkmarks on added items and a "Done (N added)" footer button |
| 2 | Medium | ProgramBuilder (Cancel) | Cancel button | Warns about unsaved changes before navigating away | Silently discarded `isDirtyRef` and navigated without confirmation -- **FIXED**: now shows "You have unsaved changes. Discard and go back?" confirmation dialog |

---

## Visual Misalignments & Layout Bugs

| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | ProgramList (name column) | Name column max-width locked at 200px, truncating even on wide screens. Not clickable -- users must find the "..." menu to edit | **FIXED**: widened to 300px. Made name a clickable link to edit page for owners (hover underline). Non-owners see plain text. |
| 2 | Medium | DeleteProgramDialog | Long program names (100 chars) could overflow the dialog description without wrapping, pushing content off-screen | **FIXED**: wrapped program name in `break-all font-medium` span inside `DialogDescription` for proper line breaking. Added "This action cannot be undone." copy for clarity. |
| 3 | Low | ProgramBuilder (description) | No character counter -- user had no idea they were approaching the 500 char limit until browser-level maxLength silently stopped input | **FIXED**: added character counter (e.g., "247/500") that turns amber when >90% full |
| 4 | Low | ProgramBuilder (name) | No character counter for the 100 char max name field | **FIXED**: added character counter with amber color warning at >90% |
| 5 | Low | ProgramBuilder (description textarea) | Textarea had no disabled styling -- while other inputs disable during save via `<fieldset disabled>`, the textarea looked the same when disabled | **FIXED**: added `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50` classes |

---

## Broken Flows & Logic Bugs

| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Program Builder duration | 1. Create 8-week program 2. Add exercises to weeks 5-8 3. Change duration to 4 weeks | Confirmation dialog warning about data loss | Weeks 5-8 silently destroyed with all exercise data. No warning. No undo. -- **FIXED**: now shows confirmation "Reducing to 4 weeks will remove 4 weeks that contain exercise data. This cannot be undone. Continue?" Only triggers when removed weeks actually contain data. |
| 2 | High | Day Editor rest toggle | 1. Add 5 exercises to Monday 2. Click "Rest Day" toggle | Confirmation warning that exercises will be removed | All 5 exercises silently deleted with no warning -- **FIXED**: now shows "Setting Monday as a rest day will remove 5 exercises. Continue?" Only triggers when exercises exist. |
| 3 | High | Exercise Row weight | 1. Click weight input 2. Type 999999 | Value clamped to reasonable max | Value accepted as-is. Only HTML `min=0` was set, no max. Could submit 999999 lbs to backend -- **FIXED**: added `max=9999` with `Math.min(9999, ...)` clamping |
| 4 | High | Exercise Row reps (text mode) | 1. Type "10-12" in reps (range notation) 2. Clear and type arbitrary long string | Input sanitized or length-limited | Any arbitrary string accepted. While XSS is mitigated by React's escaping, unconstrained input could produce bad data -- **FIXED**: string values now sliced to 10 chars max with `.slice(0, 10)` |
| 5 | High | Exercise Row reps (number mode) | 1. Type 999 in reps field | Value clamped to max 100 | Value accepted. HTML `max=100` is advisory only -- **FIXED**: added `Math.min(100, ...)` clamping |
| 6 | Medium | ProgramBuilder Ctrl+S | 1. Change description 2. Press Ctrl+S | Save triggered with latest state | Keyboard shortcut useEffect captured stale closure -- deps were `[isSaving, name]` but handleSave depends on description, schedule, etc. -- **FIXED**: refactored to use `handleSaveRef` pattern that always calls the latest `handleSave` |
| 7 | Medium | Day Editor exercise limit | 1. Add 100+ exercises to a single day | Some reasonable limit or warning | No limit at all. User could add unlimited exercises, creating an unusable UI and potentially crashing the browser -- **FIXED**: added MAX_EXERCISES_PER_DAY = 50 cap with toast error and hidden "Add Exercise" button at limit |
| 8 | Medium | DeleteProgramDialog | 1. Click Delete 2. While deleting, click outside dialog or press Escape | Dialog should stay open during deletion | Dialog could be closed while API call in progress, leaving UI in inconsistent state -- **FIXED**: `handleOpenChange` prevents closing while `deleteMutation.isPending` |
| 9 | Low | Error utils | 1. Throw a native `Error` (not `ApiError`) | Error message displayed | Returns generic "An unexpected error occurred" even when `Error.message` has useful info -- **FIXED**: added `error instanceof Error` check that returns `error.message` |
| 10 | Low | Error utils | DRF returns `{"detail": "Not found."}` | User sees "Not found." | User sees "detail: Not found." -- the field key prefix is confusing for `detail` and `non_field_errors` keys -- **FIXED**: added sensitive key stripping so these common DRF keys display cleanly without the prefix |

---

## Product Improvement Suggestions

| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Program Builder | "Copy Week to All" button | Building a 12-week program where most weeks are identical requires manually configuring 12 x 7 = 84 days. A single "Copy Week 1 to All" button reduces this to 7 days of work. -- **IMPLEMENTED** |
| 2 | High | Program Builder | Cmd+S / Ctrl+S keyboard shortcut | Power users expect Cmd+S to save. Without it, they must scroll down to find the save button every time. The shortcut hint is shown next to the Save button. -- **IMPLEMENTED** |
| 3 | Medium | Program List | Clickable program name to edit | Users had to find the tiny "..." menu button, then click Edit. Most data tables (Linear, Notion) let you click the row name to open it. -- **IMPLEMENTED** |
| 4 | Medium | Program Builder | Whitespace-only name validation | User could type "   " (spaces only) and the save button appeared enabled, but save would fail or create a program with a blank display name. Now shows inline "Name cannot be only whitespace" error with `aria-invalid`. -- **IMPLEMENTED** |
| 5 | Medium | Program Builder | Form disabled during save | While saving, all form inputs should be disabled to prevent editing during the API call. Now wrapped in `<fieldset disabled={isSaving}>`. -- **IMPLEMENTED** |
| 6 | Low | Exercise Picker | "Added" checkmark feedback | After selecting an exercise, there was zero visual feedback that it was added (since the dialog previously just closed). Now shows a green checkmark next to already-added exercises, and the footer shows "Done (3 added)". -- **IMPLEMENTED** |
| 7 | Low | Error Utils | Clean DRF field error display | DRF returns `{"detail": "Not found."}` and `{"non_field_errors": [...]}` -- showing "detail: Not found." to users looks like developer output. Now strips these known keys for cleaner messages. -- **IMPLEMENTED** |
| 8 | Medium | Program Builder | Duplicate exercise warning | User can add the same exercise to a day multiple times with no warning. While valid (e.g., different set/rep schemes), accidental duplicates are common. | **NOT FIXED** -- requires design decision on whether duplicates are intentional |
| 9 | Medium | Program Builder | Undo/redo for schedule changes | Accidentally deleting exercises or toggling rest day is destructive. An undo stack would let users recover. | **NOT FIXED** -- significant refactor needed, would require a state history manager |
| 10 | Low | Program List | Bulk delete/assign | If trainer has 20 programs and wants to clean up old ones, they must delete them one by one. Bulk selection would be faster. | **NOT FIXED** -- requires DataTable selection enhancement |
| 11 | Low | Assign Dialog | Searchable trainee combobox | `useAllTrainees` fetches up to 200 trainees. With many trainees, scrolling through an unsorted `<select>` dropdown is painful. A searchable combobox would be better. | **NOT FIXED** -- requires combobox component |

---

## Cannot Fix (Need Design/Backend Changes)

| # | Area | Issue | Suggested Approach |
|---|------|-------|-------------------|
| 1 | Exercise Picker | Pagination only fetches first 100 exercises | Backend returns paginated results with `page_size=100`. If the trainer or system has 200+ exercises, only the first page shows. Should add infinite scroll or increase page size, but this requires backend coordination. |
| 2 | Assign Dialog | Trainee limit of 200 | `useAllTrainees` hardcodes `page_size=200`. Trainers with 201+ trainees silently lose trainees from the dropdown. Should either paginate or use a searchable async combobox. |
| 3 | Program Builder | No autosave / draft recovery | If the browser crashes or the user accidentally navigates away (bypassing beforeunload), all work is lost. An autosave-to-localStorage mechanism would prevent data loss. Requires design decision on draft storage format. |
| 4 | Day Editor | No drag-and-drop reorder | Exercise reorder is button-only (up/down arrows). Drag-and-drop would be much faster. Requires a DnD library (dnd-kit) integration. |

---

## Summary

- Dead UI elements found: 2
- Visual bugs found: 5
- Logic bugs found: 10
- Improvements suggested: 11
- Items fixed by hacker: 16
- Cannot-fix items documented: 4

## Chaos Score: 7/10

### Rationale
The Program Builder is functional for the happy path but had several significant data-loss risks (silent week deletion, silent rest day toggle clearing exercises, no exercise count limits) that would frustrate real users. The exercise picker's one-at-a-time selection pattern was a major UX friction point for anyone building a real program. Input validation relied entirely on advisory HTML attributes without JavaScript clamping, meaning keyboard users could easily enter absurd values (999999 lbs, 999 reps). The Cancel button offered no unsaved changes protection despite having a `beforeunload` handler for browser-level navigation. The Ctrl+S keyboard shortcut had a stale closure bug that would save outdated state.

**Good:**
- Clean architecture: types, hooks, and components are well-separated
- Consistent state handling: loading, error, and empty states on list page
- `beforeunload` handler prevents browser-level navigation data loss
- `reconcileSchedule` properly handles schedule/duration mismatches on edit
- `useDeferredValue` on search inputs prevents excessive API calls
- Week tabs with `ScrollArea` handle high week counts gracefully
- Row-level ownership checks (isOwner) on edit/delete actions
- All form inputs have proper ARIA labels and IDs

**After Fixes:**
- All destructive actions require explicit confirmation
- All numeric inputs have both HTML and JavaScript validation
- Exercise picker supports multi-add workflow with visual feedback
- Copy Week to All eliminates repetitive configuration for uniform programs
- Keyboard shortcut (Cmd/Ctrl+S) enables fast save without scrolling
- Character counters provide proactive feedback on field limits
- Error messages are cleaner for common DRF response patterns
- Delete dialog prevents accidental close during API operation
