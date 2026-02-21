# Feature: Macro Preset Management for Web Trainer Dashboard

## Priority
High

## User Story
As a **trainer**, I want to **create, edit, delete, and copy macro presets for my trainees on the web dashboard** so that I can **efficiently manage nutrition templates (Training Day, Rest Day, etc.) without having to set individual macros from scratch for every trainee**.

## Background
The MacroPreset backend is fully built: model, ViewSet with full CRUD, copy-to-trainee, and all-presets endpoints. The mobile app has a complete UI where trainees can see and apply their presets. However, the web trainer dashboard has zero macro preset UI — trainers can only edit raw nutrition goals (calories, protein, carbs, fat) per trainee via a simple dialog. There is no way to create named presets, set defaults, or copy presets between trainees from the web.

## Backend API (Already Built — No Changes Needed)

### Endpoints
- `GET /api/workouts/macro-presets/?trainee_id={id}` — List presets for a trainee
- `POST /api/workouts/macro-presets/` — Create preset (body: `trainee_id`, `name`, `calories`, `protein`, `carbs`, `fat`, `frequency_per_week?`, `is_default?`, `sort_order?`)
- `GET /api/workouts/macro-presets/{id}/` — Get single preset
- `PUT /api/workouts/macro-presets/{id}/` — Update preset
- `DELETE /api/workouts/macro-presets/{id}/` — Delete preset
- `GET /api/workouts/macro-presets/all_presets/` — All presets grouped by trainee
- `POST /api/workouts/macro-presets/{id}/copy_to/` — Copy preset to another trainee (body: `trainee_id`)

### Response Shape (MacroPreset)
```json
{
  "id": 1,
  "trainee": 5,
  "trainee_email": "jane@example.com",
  "name": "Training Day",
  "calories": 2500,
  "protein": 180,
  "carbs": 280,
  "fat": 75,
  "frequency_per_week": 4,
  "is_default": true,
  "sort_order": 0,
  "created_by": 2,
  "created_by_email": "trainer@example.com",
  "created_at": "2026-02-21T10:00:00Z",
  "updated_at": "2026-02-21T10:00:00Z"
}
```

### Validation Rules (enforced by backend)
- `calories`: 500–10,000
- `protein`: 0–500g
- `carbs`: 0–1,000g
- `fat`: 0–500g
- `frequency_per_week`: 1–7 (optional, nullable)
- `name`: max 100 chars, required
- Only one `is_default=true` per trainee (model enforces uniqueness)

## Acceptance Criteria

### Frontend — Types
- [ ] AC-1: New `MacroPreset` TypeScript interface in `web/src/types/trainer.ts` matching the API response shape
- [ ] AC-2: Interface includes all fields: `id`, `trainee`, `trainee_email`, `name`, `calories`, `protein`, `carbs`, `fat`, `frequency_per_week`, `is_default`, `sort_order`, `created_by`, `created_by_email`, `created_at`, `updated_at`

### Frontend — Constants
- [ ] AC-3: URL constants added to `constants.ts`: `MACRO_PRESETS` (base), `macroPresetDetail(id)`, `macroPresetCopyTo(id)`, `MACRO_PRESETS_ALL`
- [ ] AC-4: URLs match backend: `/api/workouts/macro-presets/`, `/api/workouts/macro-presets/{id}/`, `/api/workouts/macro-presets/{id}/copy_to/`, `/api/workouts/macro-presets/all_presets/`

### Frontend — Hooks (`web/src/hooks/use-macro-presets.ts`)
- [ ] AC-5: `useMacroPresets(traineeId)` query hook — fetches `GET /api/workouts/macro-presets/?trainee_id={traineeId}`, returns `MacroPreset[]`, enabled when `traineeId > 0`
- [ ] AC-6: `useCreateMacroPreset()` mutation hook — posts to macro presets endpoint, invalidates `["macroPresets", traineeId]` on success
- [ ] AC-7: `useUpdateMacroPreset()` mutation hook — puts to preset detail endpoint, invalidates preset query on success
- [ ] AC-8: `useDeleteMacroPreset()` mutation hook — deletes preset, invalidates preset query on success
- [ ] AC-9: `useCopyMacroPreset()` mutation hook — posts to copy_to endpoint, invalidates target trainee's preset query on success

### Frontend — Macro Presets Section (`web/src/components/trainees/macro-presets-section.tsx`)
- [ ] AC-10: New component renders in trainee detail Overview tab, below the existing Nutrition Goals card
- [ ] AC-11: Section header: "Macro Presets" with an "Add Preset" button (Plus icon, `variant="outline"`, `size="sm"`)
- [ ] AC-12: When presets exist: renders a responsive grid of preset cards (1 col mobile, 2 cols sm, 3 cols lg)
- [ ] AC-13: Each preset card shows: name (bold), calories/protein/carbs/fat in a 2×2 grid, frequency badge (if set), "Default" badge (if is_default), edit and delete action icons
- [ ] AC-14: When no presets exist: shows an empty state with Utensils icon, "No macro presets" title, "Create presets like Training Day, Rest Day to quickly manage nutrition for this trainee." description, and "Add Preset" CTA button
- [ ] AC-15: Each card has a "Copy to..." action (Copy icon) that opens the copy dialog
- [ ] AC-16: Loading state: 3 skeleton cards matching the preset card layout
- [ ] AC-17: Error state: inline error with retry button

### Frontend — Create/Edit Preset Dialog (`web/src/components/trainees/preset-form-dialog.tsx`)
- [ ] AC-18: Single reusable dialog for both CREATE and EDIT modes (determined by `preset` prop being null or defined)
- [ ] AC-19: Title: "Create Macro Preset" or "Edit Macro Preset" based on mode
- [ ] AC-20: Form fields: Name (text input, max 100, required), Calories (number, 500–10000), Protein (number, 0–500, suffix "g"), Carbs (number, 0–1000, suffix "g"), Fat (number, 0–500, suffix "g"), Frequency (optional select: None, 1x/week through 7x/week or Daily), Is Default (checkbox)
- [ ] AC-21: Client-side validation matching backend rules. Inline error messages below each field.
- [ ] AC-22: In edit mode, form populates with existing preset values when dialog opens
- [ ] AC-23: Submit button shows loading spinner during mutation, disabled while pending
- [ ] AC-24: On success: toast "Preset created" / "Preset updated", dialog closes
- [ ] AC-25: On error: toast with error message from API

### Frontend — Delete Preset Confirmation
- [ ] AC-26: Delete uses an AlertDialog with preset name in the description: "Are you sure you want to delete the preset "{name}"? This cannot be undone."
- [ ] AC-27: Delete button shows loading spinner during deletion
- [ ] AC-28: On success: toast "Preset deleted", dialog closes
- [ ] AC-29: On error: toast with error message

### Frontend — Copy Preset Dialog (`web/src/components/trainees/copy-preset-dialog.tsx`)
- [ ] AC-30: Dialog shows: preset name being copied, trainee selector dropdown
- [ ] AC-31: Trainee selector uses `useAllTrainees()` hook, excludes the current trainee (the one who already has this preset)
- [ ] AC-32: Submit copies preset to selected trainee
- [ ] AC-33: On success: toast "Preset copied to {trainee name}", dialog closes
- [ ] AC-34: On error: toast with error message
- [ ] AC-35: Submit button disabled when no trainee selected, shows spinner during mutation

### Frontend — Integration
- [ ] AC-36: Macro presets section appears in trainee detail Overview tab between the Nutrition Goals card and the Programs card
- [ ] AC-37: Section only appears for trainee detail pages (not in list view)
- [ ] AC-38: Creating/editing/deleting a preset refetches the presets list automatically

## Edge Cases
1. **No presets** — Shows empty state with CTA button. Not an error.
2. **Setting new default** — When a preset is marked as default, the backend automatically unmarks any previous default. UI should refetch and reflect the change.
3. **Deleting the default preset** — Backend allows this. After deletion, no preset is default. UI should handle gracefully.
4. **Copy to trainee with existing presets** — Backend creates a new preset (copy doesn't override). Copy sets `is_default=false` on the new preset.
5. **Copy to trainee who is the same trainee** — Frontend excludes current trainee from the selector dropdown. Backend would also reject this.
6. **Trainer with no other trainees** — Copy dialog shows empty trainee dropdown with message "No other trainees to copy to."
7. **Very long preset name** — Truncated in card display with ellipsis. Full name visible in edit dialog.
8. **Backend validation error** — e.g., calories=50 (below 500 minimum). Frontend validates first, but if backend rejects, show error toast.
9. **Rapid create/delete** — React Query invalidation handles stale data. Optimistic updates not needed (simple enough).
10. **Frequency null** — No frequency badge shown on the card. Frequency select shows "None" option.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Failed to load presets | Inline error with "Retry" button | Query retries, shows error after 3 fails |
| Create/edit fails (validation) | Error toast with message | Mutation onError, dialog stays open |
| Delete fails | Error toast with message | Mutation onError, confirm dialog closes |
| Copy fails | Error toast with message | Mutation onError, dialog stays open |
| No trainee selected in copy | Submit button disabled | Prevents empty POST |
| Network error | Error toast: "Something went wrong" | Standard apiClient error handling |

## UX Requirements
- **Loading state**: 3 skeleton cards in grid layout while presets load
- **Empty state**: Centered Utensils icon + message + "Add Preset" CTA
- **Populated state**: Responsive card grid with all actions accessible
- **Error state**: Inline error with retry
- **Success feedback**: Toast for create/edit/delete/copy operations
- **Delete confirmation**: AlertDialog, not instant delete
- **Accessibility**: aria-labels on all action buttons ("Edit Training Day preset", "Delete Training Day preset", "Copy Training Day preset to another trainee")

## Technical Approach

### Files to Create
- `web/src/hooks/use-macro-presets.ts` — Query + 4 mutation hooks
- `web/src/components/trainees/macro-presets-section.tsx` — Section component with preset cards, empty state, loading state
- `web/src/components/trainees/preset-form-dialog.tsx` — Create/edit dialog (reusable)
- `web/src/components/trainees/copy-preset-dialog.tsx` — Copy-to-trainee dialog

### Files to Modify
- `web/src/types/trainer.ts` — Add `MacroPreset` interface
- `web/src/lib/constants.ts` — Add 4 macro preset URL constants
- `web/src/components/trainees/trainee-overview-tab.tsx` — Import and render `MacroPresetsSection` between Nutrition Goals and Programs

### Key Design Decisions
1. **Section in Overview tab, not separate tab** — Macro presets are closely related to nutrition goals. Keeping them together in Overview reduces navigation friction.
2. **Reusable PresetFormDialog** — Same dialog for create and edit avoids duplication. Mode determined by `preset` prop.
3. **No optimistic updates** — CRUD operations are fast enough that waiting for server confirmation is fine. Simplifies implementation.
4. **Card layout not table** — Presets are few per trainee (typically 2–4). Cards show macro values at a glance better than a table row.
5. **Copy dialog with trainee selector** — Uses existing `useAllTrainees()` hook. Filters out current trainee client-side.
6. **Frontend validation mirrors backend** — Same min/max ranges. Backend is the authority, but frontend catches errors early.

## Out of Scope
- Dedicated /macro-presets/ page for bulk management across all trainees
- Drag-and-drop reordering (sort_order can be set but no UI for reordering)
- Preset templates library (global/shared presets)
- "Apply preset" button (that's trainee-facing, on mobile)
- Backend changes (API is complete)
- Mobile changes
