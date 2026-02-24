# Architecture Review: Web App Mobile Responsiveness — Trainee Dashboard

## Review Date
2026-02-24

## Files Reviewed
- `web/src/app/globals.css`
- `web/src/app/layout.tsx`
- `web/src/app/(dashboard)/layout.tsx`
- `web/src/app/(trainee-dashboard)/layout.tsx`
- `web/src/app/(trainee-dashboard)/trainee/messages/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/announcements/page.tsx`
- `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx`
- `web/src/components/shared/page-header.tsx`
- `web/src/components/trainee-dashboard/exercise-log-card.tsx`
- `web/src/components/trainee-dashboard/active-workout.tsx`
- `web/src/components/trainee-dashboard/workout-detail-dialog.tsx`
- `web/src/components/trainee-dashboard/workout-finish-dialog.tsx`
- `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx`
- `web/src/components/trainee-dashboard/trainee-progress-charts.tsx`
- `web/src/components/trainee-dashboard/program-viewer.tsx`
- `web/src/components/trainee-dashboard/meal-history.tsx`
- `web/src/components/trainee-dashboard/nutrition-page.tsx`

---

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations (no data model changes)
- [x] No business logic in routers/views (changes are purely presentational)
- [x] Consistent with existing patterns (mostly -- see findings below)

### Overall Assessment

The changes are entirely presentational/CSS-level and do not alter any data models, API contracts, state management, or business logic. This is architecturally clean. The responsive adjustments use Tailwind's mobile-first breakpoint system (`sm:`, `lg:`) which is the established convention in the codebase. Good decisions were made around CSS-only solutions where possible (Tailwind responsive classes) versus JS-based solutions (`useIsMobile` hook) only where the third-party library (Recharts) requires imperative configuration that cannot be controlled via CSS.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | No new queries |
| No N+1 query patterns | N/A | No query changes |

---

## Detailed Findings

### 1. `useIsMobile` Hook Placement (Minor Concern)

**File:** `web/src/components/trainee-dashboard/trainee-progress-charts.tsx:44-54`

The `useIsMobile` hook is defined inline in the charts component file rather than extracted to `src/hooks/`. Currently it is only used by `WeightTrendChart` and `WorkoutVolumeChart` in that same file, so co-location is defensible. However:

- The hook is a general-purpose utility (parameterized breakpoint, standard `matchMedia` pattern).
- The `src/hooks/` directory already has 40+ hooks, establishing a clear convention for extracting reusable hooks.
- If any other component (e.g., trainer-facing charts, admin charts) needs responsive behavior for Recharts, this hook will be duplicated.
- shadcn/ui projects conventionally ship a `use-mobile.ts` hook in the hooks directory.

**Recommendation:** Extract to `src/hooks/use-mobile.ts` for consistency. This is minor and does not block shipping, but should be done to prevent duplication as the codebase grows.

### 2. Inconsistent `h-dvh` vs `h-screen` Across Layouts (Minor Concern)

**Files:** Layout files across route groups.

The developer correctly migrated `(dashboard)/layout.tsx` and `(trainee-dashboard)/layout.tsx` from `h-screen` to `h-dvh` to fix mobile Safari's dynamic viewport issue. However, two other layouts still use `h-screen`:

- `(admin-dashboard)/layout.tsx` line 54: `h-screen`
- `(ambassador-dashboard)/layout.tsx` line 80: `h-screen`

While the ticket scope was explicitly "trainee dashboard only," this creates an inconsistency. When admin/ambassador users access their dashboards on mobile Safari, they will hit the same 100vh bug. This is tech debt that should be tracked.

**Recommendation:** Either update all four layouts now (trivial two-line change), or create a follow-up ticket. The inconsistency is minor since admin/ambassador dashboards are not primarily used on mobile today, but it is a latent bug.

### 3. Dialog Pattern Consistency (Good, with one minor inconsistency)

All trainee dashboard dialogs now consistently use:
```
max-h-[90dvh] overflow-y-auto sm:max-w-[Npx]
```

This is a good, uniform pattern within the trainee scope. The one minor inconsistency is `workout-detail-dialog.tsx` which adds `sm:max-h-[80vh]`:
```
max-h-[90dvh] overflow-y-auto sm:max-h-[80vh] sm:max-w-[600px]
```

This means on desktop it reverts to `vh` units rather than `dvh`. While `dvh` vs `vh` matters less on desktop (no dynamic address bars), mixing units within the same component is slightly inconsistent. The admin dialogs (`subscription-detail-dialog.tsx`, `coupon-detail-dialog.tsx`) still use `max-h-[80vh]` / `max-h-[85vh]` without `dvh`. This means the project now has three different max-height patterns for dialogs:

1. `max-h-[90dvh]` (trainee dialogs, mobile)
2. `max-h-[80vh]` / `max-h-[85vh]` (admin dialogs)
3. No max-height at all (some trainer dialogs like `sm:max-w-md`)

**Recommendation:** This is acceptable for now given the scoped ticket. Consider establishing a shared dialog size constant or utility class (e.g., `.dialog-mobile-safe`) if more dialogs are added. The current approach works correctly.

### 4. Responsive Grid in exercise-log-card.tsx (Good)

**File:** `web/src/components/trainee-dashboard/exercise-log-card.tsx:64,78`

The grid pattern `grid-cols-[1.75rem_1fr_1fr_2rem_2rem] sm:grid-cols-[2.5rem_1fr_1fr_2.5rem_2.5rem]` is specific and well-considered. The use of `rem` for fixed columns and `1fr` for fluid columns is the correct approach for this type of data-entry grid. The values are defined inline (not via CSS variables or utilities) which is the standard Tailwind approach.

The grid template is duplicated between the header row (line 64) and the data rows (line 78). If the column widths need to change, two lines must be updated in sync. This is a pre-existing pattern (not introduced by this change), so it is not new tech debt. If a third occurrence were added, extracting to a variable would be warranted.

**Status:** Approved. The approach is maintainable and follows Tailwind conventions.

### 5. Global CSS Additions (Good)

**File:** `web/src/app/globals.css`

Four CSS blocks were added:
1. `.scrollbar-thin` -- Utility for horizontal scroll containers (used by program-viewer week tabs)
2. iOS text-size-adjust prevention (`-webkit-text-size-adjust: 100%`)
3. iOS auto-zoom prevention (16px minimum input font-size below 639px)
4. Number input spinner removal

All four are well-organized, properly commented, and placed in logical order. The iOS-specific fixes use appropriate media queries and vendor prefixes. The number input spinner removal is global, which is a deliberate decision documented in `dev-done.md` (saves horizontal space, and the exercise log uses its own controls).

**Note on scope:** The 16px minimum font-size for inputs below 639px and the spinner removal are applied globally, not just to trainee dashboard. This is actually correct behavior (prevents iOS zoom on all inputs, and spinners are generally unwanted in this app) and is not a problem, but it is a broader change than the ticket scope implies. The developer made the right call applying these globally.

The `.scrollbar-thin` class is a custom utility. An alternative would be to use a Tailwind plugin like `tailwind-scrollbar`, but a 12-line CSS class is simpler and avoids a dependency. Good pragmatic choice.

### 6. Viewport Meta Export (Good)

**File:** `web/src/app/layout.tsx`

Adding `export const viewport: Viewport` follows the Next.js 14+ convention for viewport configuration. This correctly separates viewport metadata from the `metadata` export (which is the Next.js recommended approach since v14).

### 7. CSS-First vs JS-First Responsive Approach (Good Architecture Decision)

The implementation correctly uses CSS-first responsive patterns (Tailwind breakpoints, `hidden sm:inline`, responsive grid classes) for layout changes, and only resorts to the JS-based `useIsMobile` hook for Recharts configuration which cannot be controlled via CSS. This separation is architecturally sound:

- **CSS:** layout, visibility, spacing, sizing, typography
- **JS:** library-specific imperative config (Recharts XAxis angle, tick size, margin)

This avoids unnecessary hydration mismatches and flash-of-wrong-layout issues.

### 8. `PageHeader` Change Scope (Intentional)

**File:** `web/src/components/shared/page-header.tsx`

The `PageHeader` component is in the `shared/` directory, meaning it is used across all dashboards (trainer, admin, trainee, ambassador). The change from `text-2xl` to `text-xl sm:text-2xl` affects ALL pages that use this component, not just trainee pages. This is a broader change than the ticket scope.

However, the change is an improvement for all mobile users, so it is a net positive. It is architecturally appropriate since it belongs in the shared component rather than being special-cased per dashboard.

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Hook duplication risk | `useIsMobile` defined inline will be duplicated if other chart components need it | Extract to `src/hooks/use-mobile.ts` |
| 2 | Dialog pattern sprawl | Three different max-height patterns across the app | Consider a shared dialog wrapper or documented convention |
| 3 | Layout inconsistency | `h-dvh` only applied to 2 of 4 dashboard layouts | Apply to admin and ambassador layouts as well |

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `useIsMobile` hook co-located instead of shared | Low | Extract to `src/hooks/use-mobile.ts` |
| 2 | Admin/ambassador layouts still use `h-screen` | Low | Change `h-screen` to `h-dvh` in `(admin-dashboard)/layout.tsx` and `(ambassador-dashboard)/layout.tsx` |
| 3 | Mixed `vh`/`dvh` units in workout-detail-dialog | Low | Use `dvh` consistently or document the reasoning |

## Technical Debt Reduced

| # | Description |
|---|-------------|
| 1 | Global CSS now prevents iOS auto-zoom on inputs (was a latent usability bug everywhere) |
| 2 | Number input spinners removed globally (were visually inconsistent on mobile) |
| 3 | Viewport meta properly exported via Next.js convention (was missing entirely) |
| 4 | `h-dvh` adoption in two layouts fixes the longstanding mobile Safari 100vh issue |
| 5 | Custom scrollbar utility for horizontal scroll containers is reusable across the app |

---

## Positive Architectural Observations

1. **No new dependencies introduced:** All responsive behavior achieved with existing Tailwind classes, built-in CSS, and one small inline hook. No new npm packages.

2. **Mobile-first breakpoint usage is correct:** The pattern is consistently base = mobile, then `sm:` / `lg:` for larger screens. This is Tailwind's intended approach.

3. **Touch target sizing is thoughtful:** Checkboxes enlarged to 24px (h-6 w-6) on mobile with extra padding, date nav buttons to 36px (h-9 w-9). These exceed the minimum 24px WCAG target but fall slightly short of Apple's 44px recommendation -- a reasonable pragmatic tradeoff given the data-dense nature of the exercise log.

4. **Text abbreviation pattern is consistent:** "Weight" becomes "Wt", "Set 1" becomes "S1", "Finish Workout" becomes "Finish", "Discard" becomes icon-only. All abbreviated versions include `aria-label` or `title` for accessibility.

5. **No structural component refactoring needed:** The responsive changes were achieved without splitting components or changing prop interfaces. This means the API surface of every component is unchanged, minimizing risk of regression.

---

## Architecture Score: 9/10

The changes are clean, focused, and architecturally appropriate. They follow existing Tailwind/Next.js patterns, make good CSS-first vs JS-based decisions, and introduce minimal tech debt. The three minor items (hook co-location, layout inconsistency, dialog pattern variance) are all low-severity and do not compromise the system's architecture. The implementation will be easy to maintain and extend.

The one point deducted is for the `useIsMobile` hook not being extracted to the shared hooks directory, which is a minor departure from the codebase's established convention of centralizing hooks. This is easily fixable and does not impact functionality.

## Recommendation: APPROVE

The architecture is sound. The responsive approach is well-layered and consistent with the project's existing conventions. The minor tech debt items (`useIsMobile` extraction, `h-dvh` consistency across layouts, dialog pattern documentation) are tracked above and should be addressed in a follow-up cleanup pass, but do not block shipping this feature.
