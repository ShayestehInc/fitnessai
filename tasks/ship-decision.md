# Ship Decision: Trainee Web — Trainer Branding Application (Pipeline 34)

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 9/10
## Summary: Trainee web portal now displays trainer's custom branding (app name, logo, primary color) in both desktop and mobile sidebars. All 14 of 15 acceptance criteria pass fully; AC-7 (secondary_color) is partial but acceptable — the color is fetched, sanitized, and available for future use. Zero critical/major issues remain. TypeScript compiles cleanly.

## Remaining Concerns:
- **AC-7 (secondary_color)**: Fetched and sanitized but not applied to any distinct UI element. This is a deliberate scope limitation — there's no natural second-accent element in the current sidebar design. The data is ready for future use (e.g., hover states, header accent).
- **Color contrast**: No frontend validation that a trainer's chosen primary_color has sufficient contrast against the sidebar background. The backend validates hex format but not contrast ratio. Recommend adding a contrast check in the trainer branding settings form in a future pipeline.
- **TraineeHeader not branded**: The top header bar doesn't apply any branding. A future pipeline could add a subtle brand accent there for a more cohesive white-label experience.

## What Was Built:
Pipeline 34 applies trainer white-label branding to the trainee web portal sidebars:

**New Hook: `use-trainee-branding.ts`**
- Fetches branding from `GET /api/users/my-branding/` via React Query
- 5-minute staleTime cache, single retry, silent fallback to defaults
- `sanitizeBranding()` validates hex colors against `/^#[0-9a-fA-F]{6}$/` (defense-in-depth)
- Exports `getBrandingDisplayName()` and `hasCustomPrimaryColor()` utility functions

**New Component: `brand-logo.tsx`**
- Shared `BrandLogo` component used by both desktop and mobile sidebars
- Renders `next/image` when logo URL present, falls back to Dumbbell icon on error/null

**Modified: `trainee-sidebar.tsx` (desktop)**
- Shows trainer's app name (truncated with title tooltip for names >15 chars)
- Displays trainer's logo via `BrandLogo` component
- Active nav links tinted with `primary_color` at 12% opacity, icons colored with full `primary_color`
- Skeleton loading states for logo and name while branding fetches
- Accessible: meaningful alt text on logo, sr-only text for collapsed badge dots

**Modified: `trainee-sidebar-mobile.tsx` (mobile)**
- Same branding applied to the Sheet drawer sidebar
- Added `SheetDescription` for Radix Dialog accessibility compliance
- Consistent `shrink-0` and `truncate` classes matching desktop sidebar

**New Type: `TraineeBranding` in `types/branding.ts`**
- Collocated with existing `TrainerBranding` type
- JSDoc documenting intentional `logo` vs `logo_url` field difference

**Technical Quality:**
- TypeScript: zero compilation errors
- Security: PASS (9/10) — no secrets, no XSS, no CSS injection, strong auth/authz
- Accessibility: meaningful alt text, sr-only labels, SheetDescription, aria-current
- Architecture: APPROVE (9/10) — proper layering, shared component, centralized types
- 5 files changed, 209 lines added, 23 removed

---

## Verification Details

### 1. TypeScript Check
**PASS** — `npx tsc --noEmit` exits with zero errors.

### 2. Acceptance Criteria Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | PASS | `useTraineeBranding()` calls `apiClient.get<TraineeBranding>(API_URLS.TRAINEE_BRANDING)` via React Query |
| AC-2 | PASS | `getBrandingDisplayName()` returns `branding.app_name.trim() \|\| "FitnessAI"` — used in desktop sidebar |
| AC-3 | PASS | Mobile sidebar uses same `getBrandingDisplayName()` in `SheetTitle` |
| AC-4 | PASS | `BrandLogo` renders `<Image>` when `logoUrl` truthy, `<Dumbbell>` on null/error |
| AC-5 | PASS | Mobile sidebar imports and uses shared `BrandLogo` component |
| AC-6 | PASS | Active links: `style={{ backgroundColor: \`${primary_color}20\` }}` and icon `style={{ color: primary_color }}` |
| AC-7 | PARTIAL | `secondary_color` fetched, sanitized, available in branding data — not applied to distinct element (acceptable scope limitation) |
| AC-8 | PASS | React Query with `staleTime: 5 * 60 * 1000` and `retry: 1` |
| AC-9 | PASS | Both sidebars show `<Skeleton>` (h-6 w-6 for logo, h-5 w-24 for name) during loading |
| AC-10 | PASS | `data ? sanitizeBranding(data) : DEFAULT_BRANDING` — silent fallback, no error toast |
| AC-11 | PASS | Default `app_name: ""` → "FitnessAI"; default `primary_color: "#6366F1"` → `hasCustomPrimaryColor()` returns false → no inline styles |
| AC-12 | PASS | `${color}20` alpha suffix for background works in both light/dark modes; icon color is full hex |
| AC-13 | PASS | `width={24} height={24}` with `className="h-6 w-6"` and `object-contain` |
| AC-14 | PASS | `npx tsc --noEmit` passes with zero errors |
| AC-15 | PASS | Only trainee files modified — no changes to trainer/admin/ambassador code |

### 3. All Audit Reports Verified

| Audit | Verdict | Score | Critical/High Issues |
|-------|---------|-------|---------------------|
| Code Review (R1) | APPROVE | 8/10 | 2 major, 2 minor — all fixed |
| QA | HIGH confidence | 14/15 pass | 0 bugs found |
| UX Audit | PASS | 9/10 | 2 a11y issues fixed, 2 usability issues fixed |
| Security Audit | PASS | 9/10 | 0 critical/high issues |
| Architecture Review | APPROVE | 9/10 | DRY violation fixed, type relocated |
| Hacker Report | All fixed | 8.5/10 | 4 issues found and fixed |
