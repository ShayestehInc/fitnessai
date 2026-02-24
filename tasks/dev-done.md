# Dev Done: Trainee Web — Trainer Branding Application

## Date: 2026-02-23

## Summary
Applied trainer white-label branding (app name, logo, primary color) to the trainee web portal. The backend API (`GET /api/users/my-branding/`) already existed. This is purely frontend work — fetching branding data and applying it to sidebar components.

## Files Created (1)
1. `web/src/hooks/use-trainee-branding.ts` — `useTraineeBranding()` hook with React Query (5-min staleTime), `getBrandingDisplayName()` helper. Returns typed `TraineeBranding` with defaults.

## Files Modified (2)
1. `web/src/components/trainee-dashboard/trainee-sidebar.tsx` — Integrated branding: logo with `<Image>` + `onError` fallback to Dumbbell, app name with truncation + title tooltip, primary color applied to active nav links (background + icon color), skeleton loading state for header.
2. `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` — Same branding integration: logo, app name, primary color on active links, skeleton loading.

## Key Decisions
1. Created a separate `TraineeBranding` interface in the hook file (with `logo_url` matching the actual API field name) rather than reusing the trainer-side `TrainerBranding` type which uses `logo`.
2. Used `next/image` with `unoptimized` for logo (external URL from backend, can't be optimized by Next.js).
3. Applied branding primary color via inline `style` on active nav links rather than CSS variables — simpler, more targeted, no global CSS changes needed.
4. Color application uses `${color}20` (hex with alpha) for background tint, raw color for icon — works in both light and dark modes.
5. Default branding check uses `!== "#6366F1"` to avoid applying inline styles when using default colors (prevents style override of the CSS theme).
6. Skeleton loading for header area only — nav links render immediately since they don't depend on branding.

## Deviations from Ticket
- AC-7 (secondary_color application): Not explicitly applied to distinct elements since the sidebar only has one accent color. The secondary color is available in the branding data for future use.
- Did not add CSS variable override in layout.tsx — inline styles on individual elements were simpler and more contained.

## How to Test
1. Log in as TRAINEE user whose trainer has custom branding configured
2. Sidebar should show trainer's app_name (or "FitnessAI" if empty), trainer's logo (or Dumbbell if none), and active nav link with trainer's primary color tint
3. Toggle sidebar collapse — logo should display correctly in both states
4. Open mobile drawer — same branding appears
5. Log in as TRAINEE whose trainer has NO branding — everything looks identical to before (FitnessAI + Dumbbell + default indigo)
6. Refresh page — branding loads from cache (no flash), re-fetches in background after 5 min
7. `npx tsc --noEmit` passes
