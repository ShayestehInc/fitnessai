# Hacker Report: Macro Preset Management

## Date: 2026-02-21

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| -- | -- | -- | -- | -- | -- |

No dead buttons found. All buttons (Add Preset, Edit, Delete, Copy, Cancel, Submit) in the Macro Presets section are correctly wired to their handlers. The empty-state "Add Preset" button correctly opens the create dialog. All three action icons on PresetCard (Copy, Edit, Delete) invoke the correct parent callbacks.

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | preset-form-dialog.tsx | Native `<select>` element for Frequency looks inconsistent with shadcn/ui `<Input>` components. Browser-default styling, poor dark mode support on some browsers. | **Cannot fix now** -- project has no `@/components/ui/select` component installed. Would require adding shadcn Select. Noted for future. |
| 2 | Low | preset-form-dialog.tsx | Native `<input type="checkbox">` for "Set as default" looks inconsistent with design system. | **Cannot fix now** -- project has no `@/components/ui/checkbox` or `@/components/ui/switch` component installed. Prior audit pass added `accent-primary` and `cursor-pointer` on label to improve appearance. |
| 3 | Low | preset-form-dialog.tsx | Number inputs accepted decimal values (e.g., 150.5) via typing, creating confusion since the payload rounds to integers. | **Fixed** -- Added `step="1"` to all four number inputs (calories, protein, carbs, fat) to hint integer input and enable proper step behavior in browser spinners. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 4 | Medium | Form dialog closes during pending mutation | 1. Open Create Preset dialog. 2. Fill in valid data. 3. Click "Create Preset". 4. While spinner is showing (pending), click Cancel. | Dialog should stay open until mutation completes. | **Fixed** -- Cancel button now calls `handleOpenChange(false)` (which guards against closing during pending) instead of directly calling `onOpenChange(false)`. All form inputs are disabled during pending. Cancel button is disabled during pending. |
| 5 | Medium | Calorie-macro mismatch goes unnoticed | 1. Open Create Preset. 2. Enter protein=200, carbs=200, fat=200 (= 3400 kcal from macros). 3. Enter calories=500. 4. Submit succeeds silently. | User should be warned that calories don't match macros. | **Fixed** -- Added calorie sanity check warning that appears when entered calories differ from macro-computed calories (P*4 + C*4 + F*9) by more than 10%. Shows a non-blocking amber warning banner below the macro inputs. |
| 6 | Low | Decimal edge case in validation | 1. Open Create Preset. 2. Enter calories=499.6. 3. Submit. | Should pass validation since Math.round(499.6) = 500, which is within range [500, 10000]. | Previously failed because validation checked `cal < 500` on the raw 499.6 value, but submit handler would round to 500. **Fixed** -- Validation now rounds before checking bounds, matching the submit handler behavior. |
| 7 | Medium | Misleading empty state in copy dialog | 1. Click Copy on a preset. 2. Dialog opens while `useAllTrainees` is still fetching. 3. User sees "No other trainees to copy to." | Should show loading indicator while trainees load. | **Fixed** -- Added loading state with Skeleton placeholder and "Loading trainees..." text. Added Users icon for the genuine empty state. Previously showed misleading "No other trainees to copy to" while data was still loading. |
| 8 | Low | Copy dialog select editable during mutation | 1. Open Copy dialog. 2. Select a trainee. 3. Click Copy Preset. 4. While pending, the trainee select dropdown remained editable. | Dropdown should be disabled during pending mutation. | **Fixed** -- Added `disabled={copyMutation.isPending}` to the select element with appropriate `disabled:` CSS classes. |
| 9 | Low | Form inputs remain editable during mutation | 1. Open Create/Edit Preset dialog. 2. Fill data and submit. 3. While pending, all inputs remain editable. | Form inputs should be locked during save. | **Fixed** -- Added `disabled={isPending}` to all form inputs: name, calories, protein, carbs, fat, frequency select, and is_default checkbox. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 10 | Medium | preset-form-dialog.tsx | Add calorie sanity check warning when macros don't match entered calories. | **Implemented** -- Trainers often miscalculate. The amber warning (non-blocking) surfaces the discrepancy immediately without preventing submission. Shows when the difference exceeds 10%. |
| 11 | Medium | copy-preset-dialog.tsx | For trainers with 200+ trainees, the dropdown won't show all trainees (hard `page_size=200` limit in `useAllTrainees`). Should use a searchable combobox with server-side filtering. | **Cannot fix now** -- Requires adding a combobox/command component and potentially backend search support. The current approach works for the vast majority of trainers. |
| 12 | Low | macro-presets-section.tsx | The `sort_order` field exists on the `MacroPreset` type but there's no drag-to-reorder UI. Presets display in whatever order the API returns. | **Cannot fix now** -- Requires a drag-and-drop library (e.g., dnd-kit) and a backend endpoint to update sort order. Future enhancement. |
| 13 | Low | preset-form-dialog.tsx | No keyboard shortcut to quickly create a preset (e.g., Cmd+N when the presets section is focused). | **Won't fix** -- Low priority. The "Add Preset" button is easily accessible. |
| 14 | Low | copy-preset-dialog.tsx | Copy dialog should show a summary of the preset being copied (macros, calories) as a visual confirmation before the user selects a target. | **Won't fix now** -- Nice to have but not critical. The dialog header already shows the preset name. |
| 15 | Low | macro-presets-section.tsx | Consider adding a "Duplicate" action to quickly clone a preset for the same trainee (e.g., duplicate Training Day as "Training Day (High Carb)" and edit). Currently the only clone action is copy-to-another-trainee. | **Won't fix now** -- Would need a new backend endpoint or client-side pre-fill of the create form with existing preset data. |

## Accessibility Fixes Applied (by this audit + prior audit pass)
- All form error messages have `id` attributes and are linked to their inputs via `aria-describedby`.
- Error messages use `role="alert"` for screen reader announcement.
- Select element has `aria-label="Preset frequency per week"`.
- Copy dialog select has `aria-label="Select target trainee for preset copy"`.
- Delete dialog uses `role="alertdialog"` with `aria-describedby`.
- Checkbox label has `cursor-pointer` for visual affordance.

## Summary
- Dead UI elements found: 0
- Visual bugs found: 3 (1 fixed, 2 require missing UI components)
- Logic bugs found: 6 (all 6 fixed)
- Improvements suggested: 6 (1 implemented, 5 deferred)
- Items fixed by hacker: 7

### Files Changed
1. **`web/src/components/trainees/preset-form-dialog.tsx`**
   - Added `useMemo` import and `AlertTriangle` icon import
   - Added `computedCalories()` helper function for macro-to-calorie calculation
   - Added `calorieMismatchWarning` memo for calorie sanity check (>10% difference triggers amber warning)
   - Fixed validation to round before checking bounds (decimal edge case: 499.6 rounds to 500)
   - Added `step="1"` to all four number inputs (calories, protein, carbs, fat)
   - Added `disabled={isPending}` to all form inputs (name, calories, protein, carbs, fat, frequency select, is_default checkbox)
   - Added `disabled:cursor-not-allowed disabled:opacity-50` classes to select and checkbox
   - Changed Cancel button to use `handleOpenChange(false)` instead of direct `onOpenChange(false)`
   - Added `disabled={isPending}` to Cancel button
   - Added calorie mismatch warning banner (amber, non-blocking, dark-mode aware)

2. **`web/src/components/trainees/copy-preset-dialog.tsx`**
   - Added `Users` icon and `Skeleton` component imports
   - Extracted `isLoading: isLoadingTrainees` from `useAllTrainees()`
   - Added loading state (Skeleton + "Loading trainees..." text) shown while trainees are fetching
   - Improved empty state with `Users` icon and centered layout
   - Added `disabled={copyMutation.isPending}` to trainee select dropdown
   - Added `disabled:cursor-not-allowed disabled:opacity-50` classes to select
   - Added `isLoadingTrainees` to submit button disabled condition

## Chaos Score: 8/10

The Macro Preset Management feature is well-built overall. The main issues were around mutation lifecycle handling (dialog closing during pending, form input mutability during saves) and a missing loading state in the copy dialog that caused a misleading empty state. The calorie sanity check is a significant product improvement that will save trainers from common data entry mistakes. The remaining issues (native select/checkbox styling, drag-to-reorder, 200-trainee pagination limit) are real but low-severity and require infrastructure changes (installing new UI components or libraries) to fix properly.
