# Hacker Report: Trainee Web Portal -- Trainer Branding Application (Pipeline 34)

## Date: 2026-02-23

## Files Audited
- `web/src/hooks/use-trainee-branding.ts`
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx`
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`
- `web/src/components/trainee-dashboard/brand-logo.tsx`
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx`
- `web/src/components/trainee-dashboard/trainee-header.tsx`
- `web/src/app/(trainee-dashboard)/layout.tsx`
- `web/src/types/branding.ts`

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| -- | -- | -- | -- | -- | No dead buttons or non-functional UI elements found in the branding feature. All sidebar toggle buttons, nav links, and collapse/expand controls are properly wired. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Medium | trainee-sidebar-mobile.tsx | Nav link labels missing `truncate` class. Desktop sidebar uses `<span className="flex-1 truncate">` for labels, but mobile sidebar had `<span className="flex-1">` without `truncate`. The trainer sidebar mobile (`sidebar-mobile.tsx`) also uses `truncate`. Inconsistency could cause text overflow if nav labels are long or translated into a verbose locale. | **Fixed** -- Added `truncate` class to `<span className="flex-1 truncate">{link.label}</span>` in mobile sidebar nav links. |
| 2 | Low | trainee-sidebar-mobile.tsx | Nav link icons missing `shrink-0` class. Desktop sidebar wraps icons in `<span className="relative shrink-0">`, and the trainer mobile sidebar uses `className="h-4 w-4 shrink-0"` on icons. The trainee mobile sidebar had `className="h-4 w-4"` without `shrink-0`. In an edge case with very long labels and tight layout, the icon could shrink. | **Fixed** -- Added `shrink-0` to icon className: `className="h-4 w-4 shrink-0"`. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 3 | Medium | Malformed hex color from API | 1. Trainer saves branding via API. 2. Due to a bug or direct DB edit, `primary_color` becomes an invalid value like `red` or `#GGG`. 3. Trainee opens portal. | Sidebar should fall back to default colors. | **Before fix:** `hasCustomPrimaryColor` would return `true` (it only checks inequality with default), and the invalid value would be injected into inline `style={{ color: "red" }}` or `style={{ backgroundColor: "#GGG20" }}`. CSS would ignore the invalid value, leading to no color at all on the active link icon, or falling through to the className-based colors. Not catastrophic, but unpredictable. **Fixed** -- Added `sanitizeBranding()` function in `use-trainee-branding.ts` that validates `primary_color` and `secondary_color` against `/^#[0-9a-fA-F]{6}$/` regex. Invalid colors fall back to defaults before reaching any component. |
| 4 | Low | Accessibility: missing SheetDescription | 1. Open trainee mobile sidebar. 2. Check browser console. 3. Radix Dialog (which Sheet is built on) may log a console warning about missing Description. | No accessibility warnings in console. | **Before fix:** The `Sheet` component wraps Radix `Dialog.Root`. Radix Dialog expects both `Title` and `Description` children. The mobile sidebar had `SheetTitle` but no `SheetDescription`. While not visually broken, screen readers get less context and Radix logs a warning. **Fixed** -- Added `<SheetDescription className="sr-only">Navigation menu</SheetDescription>` after `SheetHeader`, providing screen reader context without visual impact. |

## Edge Case Analysis
| # | Category | Scenario | Status |
|---|----------|----------|--------|
| 5 | Boundary | `app_name` is 50 characters (model max_length=50) | **OK** -- Both sidebars use `truncate` CSS class on the display name. Desktop sidebar adds `title` attribute for names >15 chars so full name appears on hover. Mobile sidebar also adds `title` on `SheetTitle`. |
| 6 | Boundary | `app_name` is empty string (no custom name) | **OK** -- `getBrandingDisplayName()` falls back to `"FitnessAI"` when `app_name.trim()` is empty. |
| 7 | Boundary | `logo_url` returns 404 | **OK** -- `BrandLogo` component uses `useState(false)` for `imgError`, sets it `true` on `Image.onError`, then renders fallback `Dumbbell` icon. Graceful degradation. |
| 8 | Boundary | `logo_url` is null (no logo uploaded) | **OK** -- `BrandLogo` checks `!logoUrl` first and immediately renders fallback icon. |
| 9 | Boundary | `primary_color` is invalid hex | **Fixed** -- `sanitizeBranding()` now validates and falls back to default. |
| 10 | Boundary | API is slow (5+ seconds) | **OK** -- Both sidebars show `Skeleton` placeholders for logo and name during loading. Navigation links render immediately (not dependent on branding data). |
| 11 | Boundary | API fails entirely (network error) | **OK** -- `retry: 1` retries once. On failure, `data` is `undefined`, hook returns `DEFAULT_BRANDING`. User sees "FitnessAI" with default purple colors. No error banner (appropriate for branding -- app remains fully functional). |
| 12 | Boundary | Branding changes mid-session | **Acceptable** -- `staleTime: 5 * 60 * 1000` means branding refreshes at most every 5 minutes. React Query will refetch in background when the query becomes stale and the component re-mounts. For branding (which changes rarely), this is a reasonable tradeoff. |
| 13 | Boundary | Sidebar collapsed state with custom branding | **OK** -- Collapsed sidebar shows only the `BrandLogo` icon. When expanded, shows logo + name. Toggle persists via `localStorage`. |
| 14 | Boundary | 99+ unread badges with custom color active link | **OK** -- Badge uses `variant="destructive"` (red) which is independent of branding colors. The custom color only affects the active link background (`primary_color + "20"` for 12% opacity) and icon color, which doesn't conflict with the badge. |
| 15 | Auth | Non-trainee user accessing trainee routes | **OK** -- Layout checks `user.role` and redirects ADMIN/AMBASSADOR/TRAINER to their respective dashboards. The `useTraineeBranding` hook's API endpoint (`/api/users/my-branding/`) has `IsTrainee` permission, so it would 403 for non-trainee users, but the redirect happens before any API call. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 16 | Medium | Branding | Apply `primary_color` to the sidebar header border-bottom or add a subtle brand-colored accent line | Currently the branding only affects active nav link backgrounds and icons. A colored accent on the sidebar header would make the branding feel more intentional and premium. Stripe and Linear use subtle header accents. |
| 17 | Medium | Branding | Use `secondary_color` somewhere in the UI (currently unused) | The `TraineeBranding` type includes `secondary_color` but it's never used in any component. `hasCustomPrimaryColor` checks only `primary_color`. The secondary color field is fetched and sanitized but wasted. Could be used for hover states on nav links or the collapsed sidebar indicator. |
| 18 | Low | Branding | Add a smooth CSS transition when branding loads (fade from skeleton to branded) | Currently the skeleton snaps to the branded content when loading completes. A 150ms fade-in transition would feel more polished, similar to how image lazy-loading works. |
| 19 | Low | Mobile sidebar | Add swipe-to-close gesture for the mobile sidebar | The Sheet component supports drag-to-dismiss via Radix Dialog, but only via the overlay click or X button. Many mobile-first apps (Linear, Notion) support edge-swipe gestures for sidebar dismissal. |
| 20 | Medium | Branding | Apply branding to the trainee header (top bar) in addition to sidebar | The `TraineeHeader` component currently shows no branding at all -- just a greeting and user nav. Could show the trainer's logo or a subtle brand color accent, creating a more cohesive white-labeled experience. |

## Accessibility Observations
- Desktop sidebar: `nav` has `aria-label="Main navigation"`. Good.
- Mobile sidebar: `nav` has `aria-label="Main navigation"`. Good.
- Desktop sidebar: `aria-current="page"` on active links. Good.
- Mobile sidebar: `aria-current="page"` on active links. Good.
- `BrandLogo`: fallback `Dumbbell` icon has `aria-hidden="true"` (decorative). Good.
- `BrandLogo`: `Image` tag uses `altText` prop for meaningful alt text when provided. Good.
- Desktop sidebar: collapse/expand buttons have `aria-label`. Good.
- Desktop sidebar: collapsed badge dots include `<span className="sr-only">{badgeCount} unread</span>`. Good.
- Mobile sidebar: `SheetDescription` now added for screen reader context. Fixed.
- Skip-to-content link in layout. Good.
- Loading skeletons use default `Skeleton` component (animated pulse). Acceptable, though `aria-busy="true"` on the sidebar container during loading would be ideal.

## Summary
- Dead UI elements found: 0
- Visual bugs found: 2 (both fixed: missing `truncate` on mobile nav labels, missing `shrink-0` on mobile nav icons)
- Logic bugs found: 2 (both fixed: malformed hex color not sanitized, missing `SheetDescription` accessibility warning)
- Edge cases verified: 11 (all pass)
- Improvements suggested: 5 (all deferred -- cosmetic enhancements and design decisions)
- Items fixed by hacker: 4

### Files Changed
1. **`web/src/hooks/use-trainee-branding.ts`**
   - Added `HEX_COLOR_PATTERN` regex constant for `#RRGGBB` validation.
   - Added `sanitizeBranding()` function that validates `primary_color` and `secondary_color` against the regex, falling back to defaults for invalid values.
   - Changed hook return from `data ?? DEFAULT_BRANDING` to `data ? sanitizeBranding(data) : DEFAULT_BRANDING`.

2. **`web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`**
   - Added `SheetDescription` import and usage (`<SheetDescription className="sr-only">Navigation menu</SheetDescription>`) to satisfy Radix Dialog accessibility requirements.
   - Added `shrink-0` to nav link icon className for layout consistency with desktop sidebar.
   - Added `truncate` to nav link label `<span>` for consistency with desktop sidebar and trainer sidebar mobile.

## Chaos Score: 8.5/10

The branding implementation is well-structured and handles most edge cases correctly out of the box. The `BrandLogo` component with image error fallback is a solid pattern. The skeleton loading states during branding fetch are properly implemented. The `title` attribute for long app names shows attention to detail. The main gaps were defensive: missing hex color validation (which the backend already enforces, but defense-in-depth matters), a missing `SheetDescription` that would trigger Radix console warnings, and minor CSS inconsistencies between desktop and mobile sidebar nav items. The `secondary_color` being fetched but never used is a missed opportunity that a future iteration should address. Overall, this is production-ready with the fixes applied.
