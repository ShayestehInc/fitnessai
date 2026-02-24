# Architecture Review: Trainee Web Nutrition Page

## Review Date
2026-02-24

## Files Reviewed
- `web/src/hooks/use-trainee-nutrition.ts`
- `web/src/hooks/use-trainee-dashboard.ts`
- `web/src/components/trainee-dashboard/nutrition-page.tsx`
- `web/src/components/trainee-dashboard/meal-log-input.tsx`
- `web/src/components/trainee-dashboard/meal-history.tsx`
- `web/src/components/trainee-dashboard/macro-preset-chips.tsx`
- `web/src/components/shared/macro-bar.tsx`
- `web/src/types/trainee-dashboard.ts`
- `web/src/types/trainee-view.ts`
- `web/src/lib/constants.ts`
- `web/src/lib/schedule-utils.ts`
- `web/src/lib/api-client.ts`
- `web/src/components/ui/progress.tsx`
- `web/src/components/trainee-dashboard/nutrition-summary-card.tsx`
- `backend/workouts/serializers.py`
- `backend/workouts/views.py`

---

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (components are purely rendering; mutations and queries in hook layer)
- [x] Consistent with existing patterns

### Layering Assessment

**Hook Layer (`use-trainee-nutrition.ts`)**

Follows the exact same conventions as `use-trainee-dashboard.ts`:
- React Query `useMutation`/`useQuery` wrappers returning typed results
- API URLs from the centralized `constants.ts` object
- Proper cache invalidation on mutation success targeting `["trainee-dashboard", "nutrition-summary", date]` and `["trainee-dashboard", "today-log", date]`
- Input validation (`assertValidDate`) in the hook layer, guarding against developer misuse
- `STALE_TIME` constant consistent with the dashboard hook (5 minutes)

**Component Layer**

Clear separation of concerns:
- `NutritionPage` -- orchestrator: date state management, data fetching, conditional rendering
- `MealLogInput` -- encapsulates the parse-then-confirm two-step mutation lifecycle
- `MealHistory` -- handles meal display and deletion with a confirmation dialog
- `MacroPresetChips` -- read-only display of trainer-created presets with active detection
- `MacroBar` -- pure presentational component (correctly omits `"use client"`)

**Type Layer**

Types are intentionally split:
- `trainee-dashboard.ts` -- dashboard-specific types (workout history, weight, AI parsing, macro presets)
- `trainee-view.ts` -- types shared with the impersonation view (NutritionSummary, MacroValues, NutritionMeal)

This split is correct. `NutritionSummary` and `NutritionMeal` are referenced by both the summary card on the trainee dashboard home and the full nutrition page.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes -- purely frontend |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | No new backend queries |
| No N+1 query patterns | PASS | Single query per data need (nutrition summary, macro presets, today log) |

### Frontend-to-Backend Type Alignment

| Frontend Type | Backend Serializer | Match |
|---------------|-------------------|-------|
| `MacroPreset` (`trainee-dashboard.ts`) | `MacroPresetSerializer` | PASS -- All 13 fields match exactly |
| `ParseNaturalLanguageResponse` | `NaturalLanguageLogResponseSerializer` | PASS -- Fields match: `nutrition`, `workout`, `confidence`, `needs_clarification`, `clarification_question` |
| `ConfirmAndSavePayload` | `ConfirmLogSaveSerializer` | PASS -- `parsed_data`, `date`, `confirm` |
| `NutritionSummary` (`trainee-view.ts`) | `nutrition_summary` action response | PASS -- `date`, `goals`, `consumed`, `remaining`, `meals`, `per_meal_targets` |
| `NutritionMeal` (`trainee-view.ts`) | Meal entries in `nutrition_data.meals` JSON | PASS -- `name`, `protein`, `carbs`, `fat`, `calories`, `timestamp` |

**Minor note**: The inline type for meals in `ParseNaturalLanguageResponse.nutrition.meals` omits `timestamp` compared to `NutritionMeal`. This is correct because timestamps are not available at parse time -- they are added when the meal is saved. Using a separate inline type (rather than `Omit<NutritionMeal, 'timestamp'>`) avoids coupling.

---

## Scalability Concerns

| # | Area | Issue | Recommendation | Severity |
|---|------|-------|----------------|----------|
| 1 | MealHistory extra query | `MealHistory` calls `useTraineeTodayLog(date)` to resolve `dailyLogId` for the delete endpoint. This adds a second network request. | Consider adding `daily_log_id` to the `nutrition-summary` backend response. The frontend could then pass it down as a prop, eliminating this query entirely. Low urgency: the query is cached (5-min stale) and the response is small. | Minor |
| 2 | `useCallback` with unstable dependency (FIXED) | `handleDelete` had `deleteMutation` in its dependency array. The mutation object reference changes every render, making the memoization ineffective. | Fixed: removed `deleteMutation` from deps. `mutate` is referentially stable in React Query v5. | Minor (fixed) |
| 3 | Date utilities duplicated (FIXED) | `formatDisplayDate` and `addDays` were defined locally in `nutrition-page.tsx`, duplicating logic that belongs in the shared `schedule-utils.ts`. | Fixed: extracted both functions to `schedule-utils.ts` and updated the import. | Minor (fixed) |
| 4 | Delete dialog stale-index risk (FIXED by linter) | The original `deleteIndex` state stored only the array index. If the meals array reordered between opening the dialog and confirming, the wrong meal could be deleted. | The linter refactored to `deleteTarget: { index, name }`, capturing the meal name at dialog-open time. The name is used in the confirmation text, providing a visual safeguard. The index is still used for the API call, which is correct given React Query invalidation refreshes the list. | Minor (fixed) |

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| -- | None introduced. | -- | -- |

## Technical Debt Reduced

| # | Description |
|---|-------------|
| 1 | `addDays()` and `formatDisplayDate()` extracted to `schedule-utils.ts` -- centralizes date utilities for reuse across any future date-navigation UI |
| 2 | `useCallback` dependency correctness in `MealHistory` -- eliminates a subtle anti-pattern where memoization was ineffective |
| 3 | Linter improved `deleteTarget` to capture meal name at dialog open time, improving correctness |
| 4 | Linter added `aria-busy` and `aria-label` to skeleton loading states, `aria-live="polite"` to the date display, and `aria-label` to individual macro values in the meal list |

---

## Positive Architectural Observations

1. **Query invalidation chain is correct and complete**: When a meal is confirmed/saved or deleted, both `nutrition-summary` and `today-log` queries are invalidated. This ensures macro bars, meal history, and preset active states all stay in sync.

2. **`"use client"` boundaries are correct**: Hook files use it (consistent with all other hooks in the project). `MacroBar` correctly omits it since it's a pure function component with no hooks or event handlers.

3. **Accessibility is production-quality**: All interactive elements have `aria-label`s. Date navigation uses `<nav>` with `aria-label`. Meal list uses `role="list"` / `role="listitem"`. Progress bars have descriptive `aria-label` text. Error states use `role="alert"`. Skeletons now have `aria-busy`.

4. **Error handling is thorough**: Every mutation has `onError` callbacks with user-facing toasts. The nutrition query has loading/error/empty states. The parse mutation differentiates API errors from general failures.

5. **All UX states are handled**: Loading (skeleton), Error (retry-able), Empty/no goals, Empty/no meals, Success (macro bars + meal list), Clarification needed, Over input limit.

6. **Component sizes are within guidelines**: NutritionPage ~255 lines (orchestrator, justified), MealLogInput ~241 lines, MealHistory ~180 lines, MacroPresetChips ~67 lines, MacroBar ~33 lines.

---

## Changes Made During This Review

| # | File | What Changed | Why |
|---|------|-------------|-----|
| 1 | `web/src/lib/schedule-utils.ts` | Added `addDays()` and `formatDisplayDate()` utility functions | Extracted from nutrition-page.tsx to centralize date utilities for reuse |
| 2 | `web/src/components/trainee-dashboard/nutrition-page.tsx` | Replaced local `addDays` and `formatDisplayDate` with imports from `schedule-utils.ts` | DRY: utilities belong in the shared lib, not in a component file |
| 3 | `web/src/components/trainee-dashboard/meal-history.tsx` | Removed `deleteMutation` from `useCallback` dependency array | `mutate` is referentially stable in React Query v5; including the full mutation object defeated memoization |

---

## Detailed Scoring Matrix

| Area | Score | Notes |
|------|-------|-------|
| Layering | 10/10 | Hook fetches data, components render, types in dedicated files |
| Data model / types | 10/10 | All frontend types match backend serializer contracts exactly |
| API design / query keys | 10/10 | Proper staleTime, retry, invalidation chains, centralized URLs |
| Component decomposition | 9/10 | Clean separation; minor: MealHistory's extra query for dailyLogId could be eliminated with a backend change |
| Scalability | 9/10 | No re-render issues; one optimizable extra network request |
| Technical debt | 9/10 | Net reduction -- extracted utilities, fixed useCallback anti-pattern |

---

## Architecture Score: 9/10

The trainee web nutrition page implementation is architecturally sound. It follows every established pattern in the codebase:

- **Hook structure**: mirrors `use-trainee-dashboard.ts` exactly (React Query, typed responses, centralized URLs, consistent stale time)
- **Query key naming**: all under `["trainee-dashboard", ...]` namespace with date parameterization
- **Type organization**: types split correctly between `trainee-dashboard.ts` (dashboard-specific) and `trainee-view.ts` (shared with impersonation)
- **Component layering**: orchestrator pattern in NutritionPage, self-contained mutation lifecycles in MealLogInput and MealHistory
- **API URL centralization**: all endpoints registered in `constants.ts` following the `TRAINEE_*` naming convention

Three improvements were made during this review:
1. Extracted `addDays` and `formatDisplayDate` to `schedule-utils.ts` for reuse
2. Fixed `useCallback` dependency anti-pattern in MealHistory
3. Linter additionally improved accessibility attributes and delete-dialog safety

The one remaining suggestion (backend returning `daily_log_id` in nutrition summary to eliminate MealHistory's secondary query) is an optimization opportunity for a future iteration.

## Recommendation: APPROVE
