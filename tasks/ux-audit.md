# UX Audit: Trainee Web -- Trainer Branding Application (Pipeline 34)

## Audit Date
2026-02-23

## Files Audited
- `web/src/hooks/use-trainee-branding.ts`
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx`
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx`
- `web/src/components/trainee-dashboard/trainee-header.tsx`

---

## Usability Issues Found & Fixed

| # | Severity | Screen/Component | Issue | Fix Applied |
|---|----------|-----------------|-------|-------------|
| 1 | Minor | trainee-sidebar.tsx | Nav link label text lacked `truncate` class (inconsistent with trainer sidebar pattern in `sidebar.tsx` line 124) -- could cause horizontal overflow with unusually long labels | Added `truncate` class to nav label `<span>` at line 174 |
| 2 | Minor | trainee-sidebar-mobile.tsx | `SheetTitle` lacked `title` attribute for long brand names -- truncated names had no way for user to see the full text | Added `title` tooltip matching desktop sidebar pattern (shows on hover when name > 15 chars) |
| 3 | Info | trainee-sidebar-mobile.tsx | Logo rendering was inlined with its own separate `imgError` state management, duplicating logic from desktop's `BrandLogo` component. Could drift in behavior over time. | Extracted local `BrandLogo` component within mobile file with consistent rendering pattern |
| 4 | Low | Both sidebars | Custom branding colors have no contrast validation -- a trainer could pick a very light primary color (e.g., `#FFFF00`) that would be invisible against the sidebar background | NOT FIXED -- This belongs at the input layer (trainer branding settings form), not the rendering layer. The sidebars correctly render whatever color they receive. Recommend: add minimum contrast ratio check in the trainer branding settings page. |

---

## Accessibility Issues Found & Fixed

| # | WCAG Level | Component | Issue | Fix Applied |
|---|------------|-----------|-------|-------------|
| 1 | A (1.1.1) | trainee-sidebar.tsx, trainee-sidebar-mobile.tsx | Brand logo `Image` used `alt=""` with `aria-hidden="true"`, treating trainer logos as decorative. When a custom logo is present, it conveys brand identity and should have meaningful alt text. | Changed `alt` to `{displayName} logo`. Removed `aria-hidden` from Image. Fallback Dumbbell icon remains `aria-hidden="true"` since the brand name is conveyed by adjacent text. |
| 2 | A (1.3.1) | trainee-sidebar.tsx | Collapsed sidebar badge dot (red circle at line 165) was purely visual with no screen reader equivalent -- screen reader users in collapsed mode would have no idea about unread items | Added `<span className="sr-only">{badgeCount} unread</span>` inside the badge dot wrapper |

---

## Missing States Checklist

- [x] Loading / skeleton -- Both desktop and mobile show `Skeleton` placeholders while branding loads. Desktop shows skeleton for logo (h-6 w-6) and name (h-5 w-24); collapsed state correctly hides name skeleton. Mobile matches.
- [x] Empty / zero data -- `getBrandingDisplayName` falls back to "FitnessAI" when `app_name` is empty. `BrandLogo` falls back to Dumbbell icon when `logo_url` is null.
- [x] Error / failure -- `BrandLogo` handles image load errors via `onError` -> falls back to Dumbbell. `useQuery` with `retry: 1` retries once on API failure, then falls back to `DEFAULT_BRANDING`.
- [x] Success / confirmation -- N/A for read-only branding display (no user mutations).
- [x] Offline / degraded -- Hook falls back to `DEFAULT_BRANDING` (default indigo color, "FitnessAI" name, no logo) ensuring sidebar is always functional. `staleTime: 5 * 60 * 1000` provides caching.
- [x] Permission denied -- Hook uses `retry: 1`; a 401/403 will be retried once then fall back to defaults. Acceptable since branding is non-critical UI chrome.

---

## What Was Already Well-Done

1. **Loading skeletons match content dimensions** -- Skeleton sizes (h-6 w-6 for logo, h-5 w-24 for text) match actual content, preventing layout shift on load.
2. **Graceful fallbacks at every level** -- Hook defaults, display name fallback, image error fallback are all handled with no broken states.
3. **Custom color application is tasteful** -- Using 12.5% opacity (`20` hex suffix) for background tint and full color for icon creates a subtle, professional branded feel that works with most colors.
4. **Keyboard navigation intact** -- All nav links are proper `<Link>` elements with `aria-current="page"` for active state. Collapsed mode has tooltips via `TooltipProvider`. Toggle buttons have descriptive aria-labels.
5. **Smooth transition animation** -- `transition-[width] duration-200` provides polished sidebar collapse/expand.
6. **Consistent with existing patterns** -- Trainee sidebar follows the same structural conventions as the trainer/admin sidebars (same header height, collapse behavior, nav spacing, tooltip pattern).
7. **`staleTime` on branding query** -- 5-minute stale time prevents unnecessary refetches of branding data which changes very infrequently.
8. **`unoptimized` on trainer logo** -- Correctly bypasses Next.js image optimization for external/dynamic logo URLs, preventing build-time errors.

---

## Overall UX Score: 9/10

**Rationale:** The branding implementation is solid and production-ready. All critical states (loading, error, empty, populated) are handled with appropriate fallbacks. The design pattern of tinting the active nav link with the brand color at low opacity is tasteful and works well. Accessibility was good from the start (aria-labels on buttons, aria-current on links, semantic nav landmarks) and has been improved with meaningful alt text on logos and screen reader text for collapsed badge dots. The only area not addressed is contrast validation for custom brand colors, which belongs in the settings/input layer rather than the rendering layer. The gap from 9 to 10 would require: (1) adding contrast validation on the trainer settings page, and (2) potentially animating the brand color transitions when branding data loads.
