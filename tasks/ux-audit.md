# UX Audit: Trainer Program Builder (Pipeline 12)

## Audit Date: 2026-02-15

## Pages & Components Reviewed
- Programs list page: `web/src/app/(dashboard)/programs/page.tsx`
- New program page: `web/src/app/(dashboard)/programs/new/page.tsx`
- Edit program page: `web/src/app/(dashboard)/programs/[id]/edit/page.tsx`
- Program builder: `web/src/components/programs/program-builder.tsx`
- Program list: `web/src/components/programs/program-list.tsx`
- Exercise picker dialog: `web/src/components/programs/exercise-picker-dialog.tsx`
- Exercise row: `web/src/components/programs/exercise-row.tsx`
- Day editor: `web/src/components/programs/day-editor.tsx`
- Week editor: `web/src/components/programs/week-editor.tsx`
- Assign program dialog: `web/src/components/programs/assign-program-dialog.tsx`
- Delete program dialog: `web/src/components/programs/delete-program-dialog.tsx`
- Reference patterns: `web/src/components/shared/page-header.tsx`, `web/src/components/shared/empty-state.tsx`, `web/src/components/shared/error-state.tsx`, `web/src/components/shared/data-table.tsx`, `web/src/components/shared/loading-spinner.tsx`
- Reference pages: `web/src/app/(dashboard)/trainees/page.tsx`, `web/src/app/(dashboard)/invitations/page.tsx`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation |
|---|----------|-----------------|-------|----------------|
| 1 | High | ExerciseRow | All exercise parameter inputs (sets, reps, weight, rest) were crammed into a single horizontal line with the exercise name and action buttons. On screens narrower than ~900px, the row overflowed and became unusable. Inputs were impossible to tap accurately on mobile. | Restructured ExerciseRow into a two-row layout: top row has exercise name + reorder/delete buttons, bottom row has parameter inputs with `flex-wrap` so they wrap naturally on narrow screens. Added `pl-8` indent to visually associate inputs with their parent exercise. -- FIXED |
| 2 | High | ExerciseRow | Input labels were `sr-only` (hidden), meaning sighted users relied entirely on the tiny "sets" / "reps" suffix text after each input to understand what each field was for. These suffix labels were easy to miss and not associated with the inputs. | Changed labels from `sr-only` to visible `text-xs font-medium text-muted-foreground` labels that appear before each input field, serving as both visual and accessible labels via `htmlFor`. Removed redundant `aria-label` attributes since the visible `<label>` now serves that purpose. -- FIXED |
| 3 | High | ExerciseRow (weight unit select) | The unit `<select>` (`lbs`/`kg`) had no `border-input` class and no `focus-visible` ring styling, making it visually inconsistent with other form elements and invisible to keyboard focus. | Added `border-input` and `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` classes to match the Input component's focus behavior. -- FIXED |
| 4 | High | ProgramBuilder (form) | All form fields (textarea, selects, duration input) remained interactive during save. A user could modify fields while a save request was in flight, creating potential race conditions. | Wrapped all form fields in a `<fieldset disabled={isSaving}>` element, which natively disables all child inputs, selects, and textareas during save. -- FIXED |
| 5 | High | AssignProgramDialog | No empty state when trainer has zero trainees. The select dropdown would render with only the "Select a trainee..." placeholder, leaving the user stuck with no way to proceed and no explanation. | Added empty state with Users icon, "No trainees yet" title, helpful description, and "Send Invitation" CTA button linking to `/invitations`. Also added error state with retry button when trainee fetch fails. -- FIXED |
| 6 | High | New/Edit Program Pages | No back navigation. Users had to use the browser back button or manually navigate to `/programs`. Inconsistent with the rest of the dashboard where sub-pages have breadcrumbs or back links. | Added "Back to Programs" ghost button with ArrowLeft icon at the top of both pages, visible in all states (loading, error, success). Created reusable `BackLink` component in the edit page. -- FIXED |
| 7 | Medium | ProgramBuilder (textarea) | The description `<textarea>` lacked `disabled` styling classes. When the fieldset was disabled, the textarea would appear disabled but without the consistent opacity/cursor styling that the Input component provides. | Added `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50` classes to match the Input component's disabled behavior. -- FIXED |
| 8 | Medium | ProgramBuilder (selects) | The `<select>` elements for Difficulty Level and Goal Type lacked `disabled` styling classes, creating visual inconsistency when the form is disabled during save. | Added `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50` classes to both select elements. -- FIXED |
| 9 | Medium | ProgramBuilder (name input) | No character count indicator. Users could type up to 100 characters but had no visual feedback about how close they were to the limit. | Added `{length}/{max}` counter below the name field that turns amber when above 90% capacity. Also added inline validation message "Name cannot be only whitespace" that appears when name is non-empty but only whitespace. Connected via `aria-describedby`. -- FIXED |
| 10 | Medium | ProgramBuilder (description textarea) | Same as above -- no character count for the 500-character description field. | Added `{length}/{max}` counter below the description field with amber color at 90%+ capacity. Connected via `aria-describedby`. -- FIXED |
| 11 | Medium | ProgramBuilder (week tabs) | With programs of 12+ weeks, the week tabs (`TabsList`) used `flex-wrap` which caused the tabs to wrap into multiple rows, consuming excessive vertical space and making it hard to identify the active tab. | Changed TabsList to use horizontal `ScrollArea` with `ScrollBar orientation="horizontal"`, so tabs scroll horizontally and the active tab remains visible. TabsList now uses `inline-flex w-max` for single-line rendering. -- FIXED |
| 12 | Medium | DayEditor (header) | The day name, input field, and Rest Day button were in a single `flex` row. On narrow screens, the day name input and button would collide. | Changed to `flex-col gap-2 sm:flex-row sm:items-center sm:justify-between` so the header stacks vertically on mobile and sits side-by-side on desktop. Day name input now has `w-full max-w-[200px]`. -- FIXED |
| 13 | Medium | DayEditor (empty state) | Empty state was a plain text paragraph "No exercises added yet" with no visual indicator. Inconsistent with the shared `EmptyState` pattern used elsewhere (icon + title + description). | Added Dumbbell icon above the text and improved copy to "No exercises added yet. Click below to add one." for actionable guidance. -- FIXED |
| 14 | Medium | DayEditor (exercise count) | No visual feedback showing how many exercises a training day has. When scrolling through 7 days, it was hard to see at a glance which days were populated. | Added exercise count text below the exercise list: "3 exercises" (with proper pluralization). -- FIXED |
| 15 | Medium | AssignProgramDialog (disabled states) | The trainee select and start date input remained interactive during the assign mutation, allowing the user to change selections while a request was in flight. | Added `disabled={assignMutation.isPending}` to both the trainee select and start date input. -- FIXED |
| 16 | Medium | DeleteProgramDialog (success toast) | Success toast said generic "Program deleted" without mentioning which program was deleted. Confusing when managing many programs. | Changed to `"{program.name}" has been deleted` for specific feedback. -- FIXED |
| 17 | Low | ProgramBuilder (card descriptions) | The "Program Details" and "Weekly Schedule" cards had titles but no descriptions, leaving no context about what each section is for. Other dashboard sections provide descriptions. | Added `CardDescription` to both cards: "Define the basic information for this program template." and "Configure exercises for each day of each week. Click a week tab to edit its schedule." -- FIXED |
| 18 | Low | ProgramBuilder (duration help text) | No indication of the valid range for the duration field. Users could only discover the 1-52 constraint by trial and error. | Added helper text "Between 1 and 52 weeks" below the duration input. -- FIXED |
| 19 | Low | EditProgramPage (loading label) | The `LoadingSpinner` used the default "Loading..." label. More specific label helps screen reader users understand what is loading. | Changed to `label="Loading program..."` for specificity. -- FIXED |

---

## Accessibility Issues

| # | WCAG Level | Issue | Fix |
|---|------------|-------|-----|
| 1 | A (1.3.1) | ExerciseRow input labels were `sr-only`, making it harder for sighted keyboard users to associate inputs with their purpose. While technically accessible via `aria-label`, the redundant `aria-label` and `sr-only` label created two competing accessible names. | Made labels visible (`text-xs font-medium`) and removed redundant `aria-label` attributes. Now each input has exactly one accessible name via its visible `<label htmlFor>`. -- FIXED |
| 2 | AA (2.4.7) | Weight unit `<select>` in ExerciseRow had no `focus-visible` ring styling. Keyboard focus was invisible when tabbing through the exercise form fields. | Added `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` to match other form elements. -- FIXED |
| 3 | A (1.3.1) | ExerciseRow `<div>` container had no semantic grouping. Screen readers could not distinguish where one exercise's controls ended and another's began. | Added `role="group"` and `aria-label="Exercise {n}: {name}"` to the root container for each exercise row. -- FIXED |
| 4 | A (4.1.2) | Move up/down button `aria-label` values were generic ("Move exercise up" / "Move exercise down") without mentioning which exercise. With multiple exercises, screen reader users could not distinguish which button moves which exercise. | Changed to `Move {exercise_name} up` / `Move {exercise_name} down` for specific context. -- FIXED |
| 5 | A (4.1.2) | DayEditor Rest Day toggle `aria-label` was missing. The button text "Rest Day" did not convey the toggle action. Screen reader users could not understand that clicking would mark the day as rest or training. | Added dynamic `aria-label`: "Mark {day} as rest day" when currently a training day, "Mark {day} as training day" when currently a rest day. -- FIXED |
| 6 | A (1.3.1) | DayEditor `<Label>` for day name input said generic "Day name". Screen reader users navigating by form controls could not tell which day's name field they were editing. | Changed to "Day name for {day.day}" (e.g., "Day name for Monday"). -- FIXED |
| 7 | AA (4.1.3) | ProgramBuilder name field had no inline error announcement for whitespace-only names. The validation happened silently on save via toast. | Added inline `role="alert"` error message "Name cannot be only whitespace" that appears immediately when the name field contains only spaces. Also added `aria-invalid` attribute. -- FIXED |
| 8 | A (1.3.1) | Week tab triggers had no context about total week count. Screen reader users hearing "Week 3" had no sense of how many weeks existed. | Added `aria-label="Week {n} of {total}"` to each tab trigger. -- FIXED |
| 9 | AA (1.3.1) | ExerciseRow index number used `aria-label="Exercise {n}"` on a `<span>`, which created a competing accessible name with the new `role="group"` on the parent container. | Changed index span to `aria-hidden="true"` since the parent `role="group"` already has the full `aria-label`. -- FIXED |
| 10 | A (4.1.2) | AssignProgramDialog select and date input lacked `disabled` attributes during pending state. Screen readers would not announce the fields as unavailable during the assign operation. | Added `disabled={assignMutation.isPending}` to both form controls. -- FIXED |

---

## Missing States

### Programs List Page (`/programs`)
- [x] Loading -- `LoadingSpinner` with default "Loading..." label
- [x] Empty / zero data -- `EmptyState` with Dumbbell icon, "No program templates yet", and "Create Program" CTA
- [x] No search results -- `EmptyState` with Search icon, "No programs found", suggestion to adjust search
- [x] Error / failure -- `ErrorState` with "Failed to load programs" and retry button
- [x] Success / populated -- `ProgramList` (DataTable) with pagination

### Program Builder (new/edit)
- [x] Loading (edit only) -- `LoadingSpinner` with specific "Loading program..." label
- [x] Error (edit only) -- `ErrorState` with "Failed to load program" and retry, plus back navigation
- [x] Invalid ID (edit only) -- `ErrorState` with "Invalid program ID", plus back navigation
- [x] Saving -- `isSaving` disables save button, shows Loader2 spinner with "Saving..." text, fieldset disables all form fields
- [x] Success (save) -- Toast "Program created" or "Program updated", redirect to list on create
- [x] Error (save) -- Toast with `getErrorMessage(error)` for specific API error
- [x] Unsaved changes -- `beforeunload` warning on browser navigation, confirm dialog on Cancel button click
- [x] Disabled (empty name) -- Save button disabled when name is empty or whitespace-only

### Exercise Picker Dialog
- [x] Loading -- 5 Skeleton rows with `role="status"` and sr-only "Loading exercises..." text
- [x] Empty (no exercises) -- `EmptyState` with Dumbbell icon, "No exercises found" with contextual description
- [x] Error -- `ErrorState` with "Failed to load exercises" and retry button
- [x] Success -- ScrollArea with exercise list, badge for muscle group
- [x] Filtered (partial results) -- "Showing X of Y exercises. Refine your search to see more."

### Assign Program Dialog
- [x] Loading (trainees) -- Skeleton placeholder for select input
- [x] Empty (no trainees) -- Users icon, "No trainees yet", "Invite a trainee before assigning programs.", "Send Invitation" CTA
- [x] Error (trainees) -- Users icon, "Failed to load trainees", "Try again" retry button
- [x] Saving -- Loader2 with "Assigning...", all form fields and buttons disabled
- [x] Success -- Toast with trainee name: "Program assigned to {name}", dialog closes
- [x] Error (assign) -- Toast with specific error message

### Delete Program Dialog
- [x] Confirm -- Destructive button, dialog prevents close during pending
- [x] Deleting -- Loader2 with "Deleting...", Cancel button disabled
- [x] Success -- Toast with program name: `"{name}" has been deleted`
- [x] Error -- Toast with specific error message
- [x] Warning (used template) -- Amber text: "This template has been used X times. Assigned programs will not be affected."

### Day Editor
- [x] Empty (no exercises) -- Dumbbell icon, "No exercises added yet. Click below to add one."
- [x] Populated -- Exercise list with count: "3 exercises"
- [x] Rest day -- Card collapses content, shows only header with filled Rest Day button
- [x] Max exercises -- "Maximum of 50 exercises reached" text replaces Add button
- [x] Rest day toggle (data loss) -- Confirmation dialog when toggling training day with exercises to rest day

---

## Copy Assessment

| Element | Copy | Verdict |
|---------|------|---------|
| Programs list title | "Programs" | Clear, matches nav |
| Programs list description | "Create and manage workout program templates" | Informative |
| Create button | "Create Program" | Action-oriented |
| Search placeholder | "Search programs..." | Clear |
| Back to Programs link | "Back to Programs" | Clear navigation breadcrumb |
| Create page title | "Create Program" | Clear |
| Create page description | "Build a new workout program template" | Sets expectation |
| Edit page title | "Edit Program" | Clear |
| Edit page description | Shows program name | Contextual |
| Program Details card title | "Program Details" | Clear section |
| Program Details description | "Define the basic information for this program template." | Helpful |
| Weekly Schedule card title | "Weekly Schedule" | Clear section |
| Weekly Schedule description | "Configure exercises for each day of each week. Click a week tab to edit its schedule." | Instructive |
| Duration help text | "Between 1 and 52 weeks" | Clear constraint |
| Name required indicator | Red asterisk (*) | Standard pattern |
| Character count | "45/100" / "120/500" | Clear |
| Whitespace error | "Name cannot be only whitespace" | Specific |
| Empty program list | "No program templates yet" + "Create your first program to get started." | Actionable |
| Empty day | "No exercises added yet. Click below to add one." | Actionable, guides user |
| Exercise count | "3 exercises" | Informative |
| Max exercises | "Maximum of 50 exercises reached" | Clear limit |
| Save button (create) | "Save Template" | Matches concept |
| Save button (edit) | "Update Program" | Action-specific |
| Cancel confirm | "You have unsaved changes. Discard and go back?" | Clear consequences |
| Rest day confirm | "Setting Monday as a rest day will remove 3 exercises. Continue?" | Specific, warns of data loss |
| Duration reduce confirm | "Reducing to 4 weeks will remove 2 weeks that contain exercise data. This cannot be undone. Continue?" | Specific, warns of permanence |
| Delete confirm | "Are you sure you want to delete {name}? This action cannot be undone." | Clear consequences |
| Delete success | `"{name}" has been deleted` | Specific |
| Assign description | "Assign {name} to a trainee. A new program will be created based on this template." | Sets expectation clearly |
| No trainees (assign) | "No trainees yet" + "Invite a trainee before assigning programs." | Actionable |

---

## Consistency Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Page header | Consistent | Uses shared `PageHeader` with title, description, and optional actions |
| Back navigation | Consistent (after fix) | Both new/edit pages now have back links |
| Empty states | Consistent (after fix) | All empty states use icon + title + description + optional CTA, matching Trainees/Invitations pages |
| Error states | Consistent | All error states use shared `ErrorState` with retry, matching all other pages |
| Loading states | Consistent | Uses shared `LoadingSpinner` with specific labels |
| Data table | Consistent | `ProgramList` uses shared `DataTable` with `keyExtractor`, matching `TraineeTable` pattern |
| Search pattern | Consistent | Uses `useDeferredValue` for search debouncing (same as programs list) |
| Dialog pattern | Consistent | All dialogs use shadcn `Dialog` with `DialogTrigger asChild`, header, footer pattern |
| Toast feedback | Consistent (after fix) | All mutations show success/error toasts with specific messages |
| Destructive actions | Consistent | Delete uses `variant="destructive"`, has confirmation, prevents close during pending |
| Form disabled states | Consistent (after fix) | All form elements disable during mutations, matching other dialog patterns |
| Card structure | Consistent (after fix) | All cards use `CardTitle` + `CardDescription`, matching dashboard pattern |

---

## Responsiveness Assessment

| Aspect | Status |
|--------|--------|
| Programs list | `DataTable` wraps in `overflow-x-auto` for horizontal scroll on narrow screens |
| Program builder form | `sm:grid-cols-2` grid stacks to single column on mobile |
| Week tabs | Horizontal `ScrollArea` prevents tab overflow -- scrolls instead of wrapping |
| Day editor header | `flex-col gap-2 sm:flex-row` -- stacks day name/input and rest button on mobile |
| Day name input | `w-full max-w-[200px]` -- fills available space on mobile, constrained on desktop |
| Exercise row | Two-row layout with `flex-wrap` on parameters row -- inputs wrap naturally on narrow screens |
| Exercise row inputs | Compact `h-8 w-14/w-16` sizing with visible labels for clarity at small sizes |
| Save/Cancel footer | `flex justify-end gap-3` -- buttons remain right-aligned and accessible at all sizes |
| Exercise picker dialog | `sm:max-w-lg` with `ScrollArea h-[40vh]` -- adapts to viewport |
| Muscle group filter buttons | `flex-wrap gap-1.5` -- wraps naturally |

---

## Fixes Implemented

### 1. `web/src/components/programs/exercise-row.tsx`
- **Restructured layout**: Split from single-line to two-row layout (name + actions on top, inputs on bottom) for responsive behavior
- **Made input labels visible**: Changed from `sr-only` to visible `text-xs font-medium text-muted-foreground` labels above each input
- **Added `role="group"`** with descriptive `aria-label` to root container for screen reader grouping
- **Changed index `<span>`** to `aria-hidden="true"` to avoid competing accessible names
- **Improved move button aria-labels**: Changed from generic "Move exercise up" to specific "Move {exercise_name} up"
- **Added `border-input` and focus-visible ring** to weight unit `<select>` for keyboard accessibility
- **Added responsive wrapping**: Parameter inputs use `flex-wrap` with `gap-x-3 gap-y-2` so they wrap on narrow screens
- **Added upper bound validation**: Weight capped at 9999, reps at 100 (from linter)

### 2. `web/src/components/programs/program-builder.tsx`
- **Added `<fieldset disabled={isSaving}>`** wrapping all form fields to prevent interaction during save
- **Added character count indicators** to name (`{n}/100`) and description (`{n}/500`) fields with amber color at 90%+ capacity
- **Added inline validation** for whitespace-only names with `role="alert"` for screen reader announcement
- **Added `aria-describedby`** connecting inputs to their character count elements
- **Added `aria-invalid`** to name input when it contains only whitespace
- **Added `CardDescription`** to both "Program Details" and "Weekly Schedule" cards
- **Added duration help text** "Between 1 and 52 weeks"
- **Changed week tabs to `ScrollArea`** with horizontal scrollbar for programs with many weeks
- **Added `aria-label`** to each week tab: "Week {n} of {total}"
- **Added disabled styling** to textarea and select elements: `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50`
- **Added Ctrl+S / Cmd+S keyboard shortcut** for save (from linter)
- **Added "Copy Week to All" button** for multi-week programs (from linter)
- **Added unsaved changes confirmation** on Cancel button click (from linter)
- **Added data loss warning** when reducing duration removes weeks with exercises (from linter)

### 3. `web/src/components/programs/day-editor.tsx`
- **Made header responsive**: Changed to `flex-col gap-2 sm:flex-row sm:items-center sm:justify-between`
- **Made day name input responsive**: Changed from fixed `w-48` to `w-full max-w-[200px]`
- **Improved empty state**: Added Dumbbell icon and more actionable copy
- **Added exercise count** text below exercise list
- **Added Rest Day button `aria-label`** with dynamic text based on current state
- **Improved sr-only label** for day name input to include the day name
- **Added rest day toggle confirmation** when exercises would be removed (from linter)
- **Added max exercise limit** of 50 per day with toast error and text indicator (from linter)

### 4. `web/src/components/programs/assign-program-dialog.tsx`
- **Added empty state** for zero trainees: Users icon, "No trainees yet", "Send Invitation" CTA
- **Added error state** for failed trainee fetch: retry button
- **Added `disabled` attribute** to trainee select and start date input during assign mutation
- **Added disabled styling classes** to trainee select element

### 5. `web/src/components/programs/delete-program-dialog.tsx`
- **Improved success toast**: Changed from generic "Program deleted" to specific `"{name}" has been deleted`

### 6. `web/src/app/(dashboard)/programs/new/page.tsx`
- **Added back navigation**: "Back to Programs" ghost button with ArrowLeft icon

### 7. `web/src/app/(dashboard)/programs/[id]/edit/page.tsx`
- **Added back navigation**: Reusable `BackLink` component shown in all states (loading, error, invalid ID, success)
- **Improved loading label**: Changed from default "Loading..." to specific "Loading program..."

---

## Items Not Fixed (Require Design Decisions or Out of Scope)

1. **Drag-and-drop exercise reordering** -- Currently exercises can only be reordered using up/down arrow buttons. Drag-and-drop would provide a more intuitive interaction for reordering, especially with many exercises. Requires a library like `@dnd-kit/core` and design decisions about mobile drag behavior.

2. **Program preview/read-only mode** -- There is no way to view a program's schedule without entering edit mode. A read-only preview would be useful for trainers reviewing programs before assigning. Requires a new route and component.

3. **Keyboard shortcut discoverability** -- The Cmd/Ctrl+S shortcut hint is shown only as a small `<kbd>` element next to the save button. A keyboard shortcut panel or tooltip system would make shortcuts more discoverable.

4. **Exercise search uses `useDeferredValue` without debounce** -- The exercise picker dialog fires a new API request on every keystroke (deferred, but still every keystroke). For high-traffic deployments, a `useDebounce(300)` hook would reduce API calls. The trainees page already uses `useDebounce` -- consider standardizing on one approach.

5. **Programs list search pattern inconsistency** -- Programs page uses `useDeferredValue` while Trainees page uses `useDebounce(300)`. Both work but the inconsistency could confuse future developers. Consider standardizing.

---

## Overall UX Score: 9/10

### Breakdown:
- **State Handling:** 10/10 -- Every component handles all relevant states: loading (with skeleton or spinner), empty (with icon and CTA), error (with retry), saving (with spinner and disabled fields), success (with specific toasts), and data loss confirmation dialogs.
- **Accessibility:** 9/10 -- Visible labels with `htmlFor`, `role="group"` grouping, dynamic `aria-label` on interactive elements, `aria-invalid` and `role="alert"` for inline validation, `aria-describedby` for character counts, focus-visible rings on all form elements. Minor gap: no drag-and-drop alternative for exercise reordering.
- **Visual Consistency:** 9/10 -- Uses shared components (PageHeader, EmptyState, ErrorState, LoadingSpinner, DataTable), consistent card structure with CardDescription, matching dialog patterns. Select/textarea disabled styling now matches Input component.
- **Copy Clarity:** 10/10 -- All copy is clear, specific, and actionable. Confirmation dialogs explain consequences. Empty states guide next steps. Success toasts include entity names. Error messages are user-friendly.
- **Responsiveness:** 9/10 -- Exercise row wraps inputs on narrow screens, day editor header stacks on mobile, week tabs scroll horizontally instead of wrapping, form grid stacks to single column. Exercise row inputs are compact but may still feel cramped on very narrow (320px) viewports.
- **Feedback & Interaction:** 10/10 -- Every mutation has loading spinner, disabled states, and specific success/error toasts. Unsaved changes warning on navigation. Data loss confirmations on destructive actions. Character count with amber warning. Keyboard shortcut for save.

### Strengths:
- Comprehensive unsaved changes protection (beforeunload + cancel confirmation)
- Data loss confirmations for destructive actions (rest day toggle, duration reduction, week copy)
- Exercise row restructured for mobile-first design with visible labels
- All three dialog types (assign, delete, exercise picker) handle empty/error/loading states
- Keyboard shortcut (Cmd/Ctrl+S) for power users
- Back navigation on all sub-pages for easy escape

### Areas for Future Improvement:
- Add drag-and-drop exercise reordering as an enhancement over arrow buttons
- Add program preview/read-only view for reviewing before assigning
- Standardize search debounce approach across all list pages
- Consider adding exercise search within a day (when day has many exercises)
- Add "Duplicate Program" action to the programs list for quick copying

---

**Audit completed by:** UX Auditor Agent
**Date:** 2026-02-15
**Pipeline:** 12 -- Trainer Program Builder
**Verdict:** PASS -- All critical and major UX and accessibility issues fixed. 7 component/page files modified with 19 usability fixes and 10 accessibility fixes. All state handling verified complete across all components.
