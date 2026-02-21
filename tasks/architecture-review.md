# Architecture Review: Macro Preset Management (Web Dashboard)

## Review Date
2026-02-21

## Files Reviewed
- `web/src/types/trainer.ts` -- `MacroPreset` type definition
- `web/src/lib/constants.ts` -- API URL constants for macro preset endpoints
- `web/src/hooks/use-macro-presets.ts` -- React Query hooks (CRUD + copy)
- `web/src/components/trainees/macro-presets-section.tsx` -- Section-level container (state orchestration, dialogs)
- `web/src/components/trainees/preset-card.tsx` -- Individual preset card display (extracted during this review)
- `web/src/components/trainees/preset-form-dialog.tsx` -- Create/Edit form dialog
- `web/src/components/trainees/copy-preset-dialog.tsx` -- Copy-to-trainee dialog
- `web/src/components/trainees/trainee-overview-tab.tsx` -- Integration point (renders `MacroPresetsSection`)

**Reference files (pattern comparison):**
- `web/src/hooks/use-trainee-goals.ts` -- Existing mutation hook pattern
- `web/src/hooks/use-trainees.ts` -- Existing query hook pattern
- `web/src/components/trainees/edit-goals-dialog.tsx` -- Existing dialog pattern
- `web/src/lib/api-client.ts` -- HTTP client with auth refresh

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Hooks encapsulate data fetching / mutations (no API calls in components)
- [x] Components handle presentation only
- [x] Types centralized in `types/trainer.ts`
- [x] API URLs centralized in `lib/constants.ts`
- [x] Consistent with existing patterns (dialog structure, toast notifications, error handling)

**Details:**

1. **Hook layer separation**: All five operations (query, create, update, delete, copy) live in `use-macro-presets.ts`. Components import hooks and call `mutate()` with success/error callbacks. No `apiClient` calls exist in any component file. This matches the pattern in `use-trainee-goals.ts` and `use-trainees.ts` exactly.

2. **Type centralization**: `MacroPreset` interface is defined in `types/trainer.ts` alongside `NutritionGoal`, `TraineeDetail`, and other trainee-related types. Correct placement -- all trainer-dashboard types colocated.

3. **URL constants**: `MACRO_PRESETS`, `macroPresetDetail()`, `macroPresetCopyTo()`, `MACRO_PRESETS_ALL` follow the established constant patterns (static strings for list endpoints, functions for detail endpoints). Consistent with `traineeDetail()`, `traineeGoals()`, etc.

4. **Dialog pattern**: `PresetFormDialog` and `CopyPresetDialog` follow the exact same structure as `EditGoalsDialog`: controlled `open`/`onOpenChange` props, `useEffect` reset on open, `useCallback` for validation/submit, toast on success/error. Nearly identical boilerplate, which is good for maintainability.

5. **Error handling**: All mutations use `getErrorMessage()` from `lib/error-utils.ts` to parse `ApiError` bodies into user-friendly messages. No silent error swallowing.

6. **Component composition in `trainee-overview-tab.tsx`**: `MacroPresetsSection` is placed below the two-column profile/goals grid as a full-width section. It manages its own data fetching (via `useMacroPresets`), so it is self-contained. The parent only passes `traineeId` and `traineeName`. Clean composition boundary.

## Data Flow Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| React Query cache keys consistent | PASS (after fix) | Changed `"macroPresets"` to `"macro-presets"` to match codebase kebab-case convention |
| Mutations invalidate correct queries | PASS | Create/update/delete invalidate `["macro-presets", traineeId]`. Copy invalidates both source and target trainee caches |
| `enabled` guard on query | PASS | `enabled: traineeId > 0` prevents firing with invalid IDs |
| `staleTime` set | PASS (after fix) | Added `staleTime: 5 * 60 * 1000` to match all other hooks in the codebase |
| No stale closure bugs | PASS | `useCallback` dependency arrays are complete. `useEffect` resets form state when dialog opens |

## Issues Found and Fixed

### Issue 1: Query key naming convention (Minor -- Fixed)
**Problem:** The hook used `"macroPresets"` (camelCase) as the query key prefix. Every other hook in the codebase uses kebab-case: `"feature-requests"`, `"admin-ambassador"`, `"stripe-connect-status"`, `"trainee-view"`, `"leaderboard-settings"`, etc. Inconsistency makes cache invalidation patterns harder to reason about.

**Fix:** Changed all occurrences in `use-macro-presets.ts` from `"macroPresets"` to `"macro-presets"`.

**Files changed:** `web/src/hooks/use-macro-presets.ts` (6 occurrences)

### Issue 2: Missing staleTime (Minor -- Fixed)
**Problem:** The `useMacroPresets` query had no `staleTime` configured. The codebase convention is `staleTime: 5 * 60 * 1000` (5 minutes) on all data-fetching queries (`use-trainees.ts`, `use-analytics.ts`, `use-admin-dashboard.ts`, `use-exercises.ts`, `use-progress.ts`, etc.). Without it, presets refetch on every component mount/focus, causing unnecessary network requests.

**Fix:** Added `staleTime: 5 * 60 * 1000` to the `useMacroPresets` query options.

**Files changed:** `web/src/hooks/use-macro-presets.ts`

### Issue 3: Oversized component file (Minor -- Fixed)
**Problem:** `macro-presets-section.tsx` was 343 lines (369 after UX audit additions). It contained `MacroPresetsSection`, `PresetCard`, `MacroCell`, and `PresetsSkeleton` -- four distinct visual concerns in one file. While the 150-line rule is a mobile convention, the web codebase also benefits from component isolation for reusability and readability. `PresetCard` is a self-contained presentational component with its own subcomponent (`MacroCell`) and could be reused in other contexts (e.g., a preset search/browser view).

**Fix:** Extracted `PresetCard` and `MacroCell` into `web/src/components/trainees/preset-card.tsx` (118 lines). Updated `macro-presets-section.tsx` to import `PresetCard` from the new file. Removed unused icon imports (`Pencil`, `Trash2`, `Copy`, `Star`) and `Badge` import from the section file.

**Result:** `macro-presets-section.tsx` dropped to 253 lines. The section file now focuses on orchestration (state management, data fetching, dialog coordination) while `preset-card.tsx` handles individual preset display.

**Files changed:** `web/src/components/trainees/macro-presets-section.tsx`, new file `web/src/components/trainees/preset-card.tsx`

## Scalability Concerns
| # | Area | Severity | Assessment |
|---|------|----------|------------|
| 1 | Preset list not paginated | Low | The API returns all presets for a trainee as a flat array. For typical use (3-7 presets per trainee like "Training Day", "Rest Day", "High Carb Day"), this is fine. If the domain were to support hundreds of presets, pagination would be needed. However, that is not a realistic use case for macro presets. |
| 2 | `useAllTrainees` in copy dialog | Low | `CopyPresetDialog` calls `useAllTrainees()` which fetches up to 200 trainees. This is cached with a 5-minute staleTime so it does not re-fetch on every dialog open. For trainers with very large rosters, a search/autocomplete would be better, but the current tier limits cap at 50 trainees (Pro tier). Acceptable for now. |
| 3 | No optimistic updates on mutations | Low | Create/update/delete mutations wait for server confirmation then invalidate the cache. This causes a brief delay before the UI updates. Optimistic updates would improve perceived performance but add complexity. Given the infrequent nature of preset CRUD (trainers set these up once), the current approach is pragmatic. |

## API Design Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| URL structure consistent | PASS | `/api/workouts/macro-presets/` with `{id}/` detail and `{id}/copy_to/` action follow Django REST Framework conventions |
| Query param for filtering | PASS | `?trainee_id=X` on the list endpoint -- standard DRF filter pattern |
| HTTP methods correct | PASS | GET (list), POST (create), PUT (update), DELETE (delete), POST for copy action |
| Frontend constants registered | PASS | All 4 URL patterns registered in `constants.ts` |

## Component Design Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Prop interfaces defined | PASS | `MacroPresetsSectionProps`, `PresetCardProps`, `PresetFormDialogProps`, `CopyPresetDialogProps` all have explicit interfaces |
| Controlled dialog pattern | PASS | All three dialogs use `open`/`onOpenChange` controlled pattern matching Radix/shadcn conventions |
| Form validation | PASS | Client-side validation in `PresetFormDialog` matches backend constraints (name required, calories 500-10000, protein 0-500, etc.) |
| Skeleton matches content layout | PASS | `PresetsSkeleton` mirrors the exact grid/card structure of the populated state |
| Error boundary needed? | N/A | React Query handles error states at the data level; the section component renders an error state with retry button |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Native `<select>` elements in `PresetFormDialog` and `CopyPresetDialog` | Low | The rest of the codebase may eventually adopt a shadcn Select component for visual consistency. Using native `<select>` is functionally correct and accessible, but looks different from shadcn form controls. When a Select component is adopted codebase-wide, these should be updated. Not urgent. |
| 2 | Duplicate macro validation logic between `PresetFormDialog` and `EditGoalsDialog` | Low | Both dialogs validate calories (500-10000), protein (0-500), carbs (0-1000), fat (0-500) with identical logic. A shared `validateMacros()` utility could DRY this up. However, the validation ranges may diverge over time (presets vs goals may have different valid ranges), so keeping them separate is defensible. |

## Technical Debt Reduced
- The extraction of `PresetCard` into its own file prevents the section file from growing unbounded as features are added (e.g., drag-to-reorder, preset comparison view).
- Query key naming alignment reduces future confusion when debugging cache invalidation issues.
- Adding `staleTime` prevents unnecessary API calls and aligns with the codebase's performance conventions.

## Summary

The Macro Preset Management feature is architecturally sound. It follows the established patterns of the web dashboard exactly: hooks for data access, components for presentation, types centralized, URLs centralized, dialog pattern matching existing implementations. Three minor issues were found and fixed:

1. Query key naming changed from camelCase to kebab-case to match codebase convention.
2. Added missing `staleTime` to prevent unnecessary refetches.
3. Extracted `PresetCard` into its own file to improve component separation (253 + 118 lines vs. 369 lines in one file).

All fixes pass TypeScript compilation with zero errors (`npx tsc --noEmit`). No architectural concerns that would block shipping. The data flow is correct, cache invalidation is thorough (including cross-trainee invalidation on copy), and the component boundaries are clean.

## Architecture Score: 9/10
## Recommendation: APPROVE
