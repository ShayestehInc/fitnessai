# Dev Done: Macro Preset Management for Web Trainer Dashboard

## Date
2026-02-21

## Summary
Added macro preset management UI to the trainer web dashboard. Trainers can now create, edit, delete, and copy nutrition presets (e.g. Training Day, Rest Day) for their trainees directly from the trainee detail page. This is a frontend-only feature — all backend APIs already existed.

## Files Created
- `web/src/hooks/use-macro-presets.ts` — 5 hooks: `useMacroPresets` (query), `useCreateMacroPreset`, `useUpdateMacroPreset`, `useDeleteMacroPreset`, `useCopyMacroPreset` (mutations). All use React Query with proper query invalidation.
- `web/src/components/trainees/macro-presets-section.tsx` — Main section component with preset cards grid, empty state, loading skeleton, error state with retry, and delete confirmation dialog. Sub-components: `PresetCard`, `MacroCell`, `PresetsSkeleton`.
- `web/src/components/trainees/preset-form-dialog.tsx` — Reusable create/edit dialog with name, calories, protein, carbs, fat fields, frequency selector, and is-default checkbox. Client-side validation matching backend rules.
- `web/src/components/trainees/copy-preset-dialog.tsx` — Copy-to-trainee dialog with trainee selector dropdown (excludes current trainee). Uses `useAllTrainees()` hook.

## Files Modified
- `web/src/types/trainer.ts` — Added `MacroPreset` interface with all 14 fields matching the API response.
- `web/src/lib/constants.ts` — Added 4 URL constants: `MACRO_PRESETS`, `macroPresetDetail(id)`, `macroPresetCopyTo(id)`, `MACRO_PRESETS_ALL`.
- `web/src/components/trainees/trainee-overview-tab.tsx` — Imported and rendered `MacroPresetsSection` below the 2-column grid (Profile + Nutrition/Programs). Added outer `space-y-6` wrapper to accommodate full-width section.

## Key Decisions
1. **Section in Overview tab, full-width below grid** — Macro presets need a 3-column card grid which wouldn't fit in the existing 2-column layout. Placed as a full-width section below Profile and Nutrition Goals.
2. **Reusable PresetFormDialog** — Same dialog for create and edit, determined by `preset` prop being null or defined. Follows existing EditGoalsDialog pattern.
3. **Native HTML select for frequency** — No shadcn Select component in the project. Used a styled native `<select>` matching the project's input styling.
4. **No optimistic updates** — Operations are fast enough; server confirmation preferred for simplicity.
5. **Card layout instead of table** — Trainers typically have 2-4 presets per trainee. Cards show macro values at a glance better than table rows.
6. **Delete via Dialog, not AlertDialog** — AlertDialog component doesn't exist in the project. Used regular Dialog with destructive button styling.

## Deviations from Ticket
None.

## Test Results
- Backend: 553 tests ran, 2 pre-existing mcp_server errors (unrelated). No backend changes made.
- TypeScript `tsc --noEmit`: 0 errors.

## How to Manually Test
1. Log in as a trainer on the web dashboard
2. Navigate to any trainee's detail page → Overview tab
3. Scroll down to see the "Macro Presets" section below Profile and Nutrition Goals
4. Verify empty state shows with "Add Preset" CTA when no presets exist
5. Click "Add Preset" → fill in form → verify preset appears in card grid
6. Click edit icon on a preset → modify values → verify card updates
7. Click delete icon → confirm → verify preset removed
8. Click copy icon → select another trainee → verify toast confirmation
9. Navigate to the target trainee's page → verify copied preset appears
10. Test "Set as default" checkbox → verify star icon and Default badge
