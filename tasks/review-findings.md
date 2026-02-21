# Code Review: Macro Preset Management for Web Trainer Dashboard

## Review Date
2026-02-21

## Files Reviewed
1. `web/src/types/trainer.ts` (lines 81-97 -- `MacroPreset` interface)
2. `web/src/lib/constants.ts` (lines 241-247 -- macro preset URL constants)
3. `web/src/hooks/use-macro-presets.ts` (all 103 lines -- 5 hooks)
4. `web/src/components/trainees/macro-presets-section.tsx` (all 339 lines -- section + cards + skeleton)
5. `web/src/components/trainees/preset-form-dialog.tsx` (all 346 lines -- create/edit dialog)
6. `web/src/components/trainees/copy-preset-dialog.tsx` (all 140 lines -- copy dialog)
7. `web/src/components/trainees/trainee-overview-tab.tsx` (all 199 lines -- integration point)

Also reviewed for pattern comparison:
- `web/src/hooks/use-trainee-goals.ts`
- `web/src/hooks/use-trainees.ts`
- `web/src/hooks/use-announcements.ts`
- `web/src/components/trainees/edit-goals-dialog.tsx`
- `web/src/components/trainees/remove-trainee-dialog.tsx`
- `web/src/lib/api-client.ts`
- `web/src/lib/error-utils.ts`
- `backend/workouts/views.py` (MacroPresetViewSet, lines 1173-1417)
- `backend/workouts/serializers.py` (MacroPresetSerializer + MacroPresetCreateSerializer)
- `backend/workouts/models.py` (MacroPreset model, lines 323+)

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| -- | -- | No critical issues found. | -- |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `macro-presets-section.tsx:184` | **Cancel button in delete dialog is not disabled while deletion is pending.** The Delete button at line 187-199 correctly has `disabled={deleteMutation.isPending}`, but the Cancel button at line 184 has no `disabled` prop. If the user clicks Cancel while the DELETE request is in-flight, `setDeleteTarget(null)` fires, the dialog unmounts, and the user gets no toast feedback (onSuccess/onError callbacks still fire but the dialog is gone so the UX is jarring). The existing `remove-trainee-dialog.tsx` at line 96 correctly disables its Cancel button during pending state. This is inconsistent. | Add `disabled={deleteMutation.isPending}` to the Cancel button on line 184, matching the pattern in `remove-trainee-dialog.tsx`. |
| M2 | `macro-presets-section.tsx:171-173` | **Delete Dialog `onOpenChange` does not prevent close during pending mutation.** The Dialog's `onOpenChange` handler unconditionally sets `deleteTarget` to null when `!open`. This means the user can also dismiss the dialog by clicking the overlay or pressing Escape while the delete is in-flight. The dialog should prevent dismissal while the mutation is pending. | Change the handler to: `onOpenChange={(open) => { if (!open && !deleteMutation.isPending) setDeleteTarget(null); }}`. This prevents dismissal via overlay click or Escape while the request is in-flight. |
| M3 | `copy-preset-dialog.tsx:38` | **`otherTrainees` is recomputed on every render without memoization.** The filter `(allTrainees ?? []).filter((t) => t.id !== traineeId)` runs on every render. With `useAllTrainees()` fetching up to 200 trainees (page_size=200 at use-trainees.ts:29), this is a 200-iteration filter on every render. Since neither `allTrainees` nor `traineeId` changes during typical dialog interaction, this should be memoized. | Wrap in `useMemo`: `const otherTrainees = useMemo(() => (allTrainees ?? []).filter((t) => t.id !== traineeId), [allTrainees, traineeId]);` and add the `useMemo` import. |
| M4 | `preset-form-dialog.tsx:130-137` | **Numeric payload values are not rounded to integers.** If the user types "2000.5" into the calories field, `Number("2000.5")` sends `2000.5` to the backend. The backend model uses `PositiveIntegerField` and the serializer uses `IntegerField`, so Django will reject `2000.5` with a validation error. The frontend validation at lines 101-103 checks min/max range but does not check for integer values. The existing `edit-goals-dialog.tsx` does not have this issue because its inputs are only used for `Number()` conversion and the backend for goals accepts floats. But here, the backend strictly requires integers. | Add `Math.round()` to the payload: `calories: Math.round(Number(calories))`, `protein: Math.round(Number(protein))`, `carbs: Math.round(Number(carbs))`, `fat: Math.round(Number(fat))`. Alternatively, add integer validation: `if (!Number.isInteger(cal)) { newErrors.calories = "Must be a whole number"; }`. |
| M5 | `preset-form-dialog.tsx:311-316` | **Raw HTML checkbox has no focus-visible styling and relies on browser defaults.** The `<input type="checkbox">` at line 311-316 uses `className="h-4 w-4 rounded border-input"` but has no `focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring` classes matching the pattern used on the `<select>` element at line 300. In Firefox, the default checkbox styling looks noticeably different from Chrome/Safari. The project's other form elements (all `<Input>` components from shadcn) have consistent focus ring styling. This checkbox stands out as inconsistent. | Add focus-visible ring classes to the checkbox: `className="h-4 w-4 rounded border-input focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"`. This matches the project's focus styling pattern for other form inputs. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `macro-presets-section.tsx:303-308` | **Font sizes `text-[10px]` are below WCAG accessibility thresholds.** Both the MacroCell label (line 303: `text-[10px]`) and the unit suffix (line 306: `text-[10px]`) use 10px text. WCAG does not set a hard minimum, but 10px is widely considered too small for readability, especially for nutritional data that users need to read quickly. The existing `MacroCard` component in `trainee-overview-tab.tsx` (line 183) uses `text-xs` (12px) for its labels. The preset cards should be consistent with that. | Change both `text-[10px]` occurrences to `text-xs` (12px) for consistency with `MacroCard` in `trainee-overview-tab.tsx` and better readability. |
| m2 | `macro-presets-section.tsx:114` | **`presets` can be `undefined` in a brief window, causing empty card content.** When `traineeId > 0`, the query is enabled, but before it resolves, `presets` is `undefined`. The condition chain `!isLoading && !isError && presets && presets.length === 0` and `!isLoading && !isError && presets && presets.length > 0` both skip the `undefined` case. In practice, React Query sets `isLoading=true` during the initial fetch, so `undefined` and `isLoading=false` simultaneously should not occur on a valid query. However, if `traineeId` is passed as 0, the query is disabled, `isLoading` is `false`, `isError` is `false`, and `presets` is `undefined`, resulting in an empty card body. | Either ensure `traineeId` is always > 0 at the call site (it currently uses `trainee.id` which should always be positive from the backend), or add a guard: `if (traineeId <= 0) return null;` at the start of the component. |
| m3 | `copy-preset-dialog.tsx:72` | **Early return `if (!preset) return null` prevents Dialog close animation.** When the parent sets `copyTarget` to null (on close), the early return at line 72 causes the entire Dialog to unmount immediately rather than allowing the Dialog component's built-in close animation to play. | Accept current behavior (close animation is typically 150-200ms and the visual difference is negligible), or move the null check inside the DialogContent so the Dialog wrapper can still animate. |
| m4 | `use-macro-presets.ts:13` | **Query string built via template literal instead of `URLSearchParams`.** The existing `use-trainees.ts` (lines 13-14) uses `URLSearchParams` for query construction. This file uses direct template interpolation. While safe for a single numeric param, it is inconsistent with established patterns. | For consistency with `use-trainees.ts`, use `URLSearchParams`: `const params = new URLSearchParams(); params.set("trainee_id", String(traineeId)); return apiClient.get<MacroPreset[]>(\`${API_URLS.MACRO_PRESETS}?\${params.toString()}\`);`. Not required since the current approach works correctly. |
| m5 | `preset-form-dialog.tsx:92,125` | **`useCallback` on `validate` and `handleSubmit` provides zero memoization benefit.** The `validate` callback has 5 dependencies (`name, calories, protein, carbs, fat`) and `handleSubmit` has 14 dependencies. Both are recreated on every keystroke, making `useCallback` pure overhead. However, the existing `edit-goals-dialog.tsx` follows the exact same pattern, so this is consistent with the codebase. | No change required for consistency. Consider removing `useCallback` from both functions in a future codebase-wide cleanup. |
| m6 | `preset-form-dialog.tsx:187` | **Property access on `preset` without optional chaining in template string.** When `isEdit` is true, the description renders `preset.name`. Since `isEdit` is `preset !== null` (line 50), this is safe within a single render. However, using `preset?.name ?? ""` would be more defensive against future refactors. | Use optional chaining: `\`Update "${preset?.name}" for ${traineeName}\``. |
| m7 | `trainee-overview-tab.tsx:157-158` | **MacroPresetsSection placement deviates from AC-36 literal text.** AC-36 says "between the Nutrition Goals card and the Programs card", but the section is placed full-width below the entire 2-column grid. The dev-done.md correctly documents this as a deliberate decision because the 3-column card grid would not fit inside the existing 2-column layout. | No fix needed. This is a justified deviation. The current placement is better for the 3-column card layout. |
| m8 | `use-macro-presets.ts:1` | **`"use client"` directive on a hooks-only file.** This is technically unnecessary since hooks files are only imported by client components and inherit the client context. However, every other hook file in the project (`use-trainees.ts`, `use-trainee-goals.ts`, `use-announcements.ts`, etc.) also has this directive. | No change needed. Consistent with codebase convention. |

## Security Concerns

1. **Authentication: PASS.** All API calls go through `apiClient` which injects JWT Bearer tokens and handles 401 refresh/retry. No direct `fetch()` calls. No auth bypass vectors.
2. **XSS: PASS.** Preset names are rendered via React JSX which auto-escapes all interpolated values. The `&ldquo;`/`&rdquo;` entities in the delete dialog are safe HTML entities. No `dangerouslySetInnerHTML` anywhere.
3. **IDOR: PASS.** The frontend sends `trainee_id` in create/copy payloads, but the backend's `MacroPresetViewSet` verifies `parent_trainer` ownership on every operation (create lines 1229-1234, update lines 1276-1282, delete lines 1310-1314, copy lines 1373-1377). Row-level security is enforced server-side.
4. **Self-copy prevention: PASS.** The copy dialog filters out the current trainee from the selector (line 38). The backend would also reject same-trainee copies.
5. **Input validation: PASS.** Frontend validates ranges (calories 500-10000, protein 0-500, carbs 0-1000, fat 0-500). Backend has matching validation in `MacroPresetCreateSerializer`. Both layers enforce constraints.
6. **No secrets: PASS.** No API keys, tokens, passwords, or credentials in any reviewed file.

**Security verdict: PASS.** No security issues found.

## Performance Concerns

1. **`useAllTrainees()` fetches up to 200 trainees** (page_size=200). Called by `CopyPresetDialog` every time it mounts. The hook has `staleTime: 5 * 60 * 1000` (5 min cache), so repeated opens use cached data. Acceptable.
2. **No unbounded lists.** Macro presets per trainee are typically 2-4. Even with aggressive creation, unlikely to exceed 20. No pagination needed.
3. **No N+1 queries.** This is frontend-only; the backend handles query optimization with `select_related('trainee', 'created_by')` in `get_queryset()`.
4. **`otherTrainees` filter (M3).** 200-item array filter on every render. Should be memoized but not a performance blocker.
5. **PresetCard not memoized.** With 2-4 cards, `React.memo` would add overhead without benefit. Acceptable.
6. **React Query invalidation.** All mutations properly invalidate `["macroPresets", traineeId]`. Copy mutation also invalidates the target trainee's presets. No stale data issues.

## Acceptance Criteria Verification

| AC | Status | Notes |
|----|--------|-------|
| AC-1 | PASS | `MacroPreset` interface in `trainer.ts` lines 81-97 |
| AC-2 | PASS | All 14 fields present with correct types matching API response |
| AC-3 | PASS | 4 URL constants: `MACRO_PRESETS`, `macroPresetDetail`, `macroPresetCopyTo`, `MACRO_PRESETS_ALL` |
| AC-4 | PASS | URLs match backend routes exactly |
| AC-5 | PASS | `useMacroPresets(traineeId)` with `?trainee_id=`, enabled when > 0 |
| AC-6 | PASS | `useCreateMacroPreset` posts and invalidates `["macroPresets", traineeId]` |
| AC-7 | PASS | `useUpdateMacroPreset` puts and invalidates |
| AC-8 | PASS | `useDeleteMacroPreset` deletes and invalidates |
| AC-9 | PASS | `useCopyMacroPreset` posts to copy_to, invalidates both source and target |
| AC-10 | PASS | Section renders in trainee detail Overview tab |
| AC-11 | PASS | "Macro Presets" header with "Add Preset" button (Plus icon, outline, sm) |
| AC-12 | PASS | Responsive grid: `sm:grid-cols-2 lg:grid-cols-3` |
| AC-13 | PASS | Cards show name, 2x2 macro grid, frequency badge, default badge, edit/delete icons |
| AC-14 | PASS | Empty state with Utensils icon, correct copy, Add Preset CTA |
| AC-15 | PASS | Copy icon on each card opens copy dialog |
| AC-16 | PASS | 3 skeleton cards matching layout |
| AC-17 | PASS | Error state with RefreshCw icon and retry button |
| AC-18 | PASS | Single `PresetFormDialog` for create and edit |
| AC-19 | PASS | Title changes: "Create Macro Preset" / "Edit Macro Preset" |
| AC-20 | PASS | All fields: Name, Calories, Protein, Carbs, Fat, Frequency select, Is Default checkbox |
| AC-21 | PASS | Client-side validation matching backend ranges |
| AC-22 | PASS | Edit mode populates from existing preset via useEffect |
| AC-23 | PASS | Submit button shows Loader2 and is disabled while pending |
| AC-24 | PASS | Toast "Preset created" / "Preset updated", dialog closes on success |
| AC-25 | PASS | Error toast with `getErrorMessage(err)` |
| AC-26 | PASS | Delete uses Dialog with preset name and "cannot be undone" text |
| AC-27 | PASS | Delete button shows Loader2 during deletion |
| AC-28 | PASS | Toast "Preset deleted" |
| AC-29 | PASS | Error toast on delete failure |
| AC-30 | PASS | Copy dialog shows preset name and trainee selector |
| AC-31 | PASS | Uses `useAllTrainees()`, excludes current trainee |
| AC-32 | PASS | Submits copy to selected trainee |
| AC-33 | PASS | Toast "Preset copied to {name}" |
| AC-34 | PASS | Error toast on copy failure |
| AC-35 | PASS | Submit disabled when no trainee selected, spinner during mutation |
| AC-36 | PASS* | Section in Overview tab. *Placed below grid instead of between Nutrition Goals and Programs. Justified deviation -- see m7. |
| AC-37 | PASS | Component only exists in trainee detail context |
| AC-38 | PASS | All CRUD operations invalidate React Query cache |

**All 38 acceptance criteria: PASS** (1 with documented, justified deviation).

## Edge Cases Verification

1. **No presets** -- Empty state renders correctly with CTA. PASS.
2. **Setting new default** -- Backend enforces uniqueness. Frontend refetches after update. PASS.
3. **Deleting default preset** -- Frontend makes no assumptions about default state. PASS.
4. **Copy to trainee with existing presets** -- Backend creates new record. PASS.
5. **Same-trainee copy** -- Excluded from dropdown. PASS.
6. **No other trainees** -- Empty message shown, submit disabled. PASS.
7. **Long preset name** -- `truncate` class + `title` attribute. PASS.
8. **Backend validation error** -- Frontend validates first; backend errors shown via toast. PASS.
9. **Rapid create/delete** -- React Query invalidation handles stale data. PASS.
10. **Frequency null** -- No badge shown; select shows "None". PASS.

## Summary

This is a well-structured, production-quality implementation that closely follows existing codebase patterns. The developer studied `edit-goals-dialog.tsx`, `use-trainee-goals.ts`, and other existing hooks/components before building, and the consistency shows. All 38 acceptance criteria are met. All 10 edge cases are handled. Security is clean. Performance is adequate.

The main areas for improvement:
1. **Delete dialog should prevent dismissal during pending mutation** (M1, M2) -- a UX issue that could leave users confused about whether a delete succeeded.
2. **Integer rounding for macro values** (M4) -- will cause backend validation errors if users enter decimal values.
3. **Missing `useMemo` on `otherTrainees`** (M3) -- minor performance improvement.
4. **Checkbox focus styling** (M5) -- cross-browser consistency.
5. **Tiny font sizes** (m1) -- accessibility concern.

None of these are data-integrity or security issues. The implementation is solid.

## Quality Score: 8/10

**Rationale**: Clean code, correct architecture, full feature coverage, proper state management, good error handling, consistent with codebase patterns. Deductions:
- -0.5 for delete dialog dismissal during pending state (M1/M2)
- -0.5 for missing integer validation/rounding on macro inputs (M4)
- -0.5 for font size accessibility concern (m1)
- -0.5 for raw checkbox without focus styling (M5)

## Recommendation: APPROVE

The code is production-ready. The 5 major issues identified are UX polish items that do not affect functionality, security, or data integrity. M4 (integer rounding) is the most likely to cause a user-visible issue if someone enters a decimal, but the backend will reject it with a clear validation error -- the user experience is slightly degraded, not broken. All issues are safe to address as a quick follow-up. No blockers found.
