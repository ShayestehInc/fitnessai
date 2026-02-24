# Feature: Trainee Web Portal — Trainer Branding Application

## Priority
High — This is the last incomplete item in the white-label infrastructure (Priority #1 in CLAUDE.md). The backend API has existed since Pipeline 14, the trainer can configure branding, but trainees on the web portal still see hardcoded "FitnessAI" defaults. Mobile already applies branding. Web is the gap.

## User Story
As a **trainee using the web portal**, I want to see my trainer's custom branding (name, logo, colors) instead of the generic "FitnessAI" defaults, so that the platform feels like my trainer's own product.

## Acceptance Criteria
- [ ] AC-1: Trainee web portal fetches branding from `GET /api/users/my-branding/` on layout mount
- [ ] AC-2: Sidebar header shows trainer's `app_name` instead of hardcoded "FitnessAI" (falls back to "FitnessAI" when `app_name` is empty string)
- [ ] AC-3: Mobile sidebar (Sheet drawer) shows trainer's `app_name` instead of hardcoded "FitnessAI"
- [ ] AC-4: When trainer has uploaded a logo, it displays in the sidebar header replacing the Dumbbell icon
- [ ] AC-5: When trainer has uploaded a logo, mobile sidebar also shows the logo
- [ ] AC-6: Trainer's `primary_color` is applied as the sidebar accent/active color (sidebar-primary, sidebar-accent)
- [ ] AC-7: Trainer's `secondary_color` is applied as a secondary accent where applicable
- [ ] AC-8: Branding data is cached via React Query (5-min staleTime) — not re-fetched on every page navigation
- [ ] AC-9: Loading state: sidebar shows skeleton placeholder for logo/name while branding loads
- [ ] AC-10: Error state: falls back to default "FitnessAI" branding silently (no error toast — trainee shouldn't know about branding failures)
- [ ] AC-11: Default branding: when trainer has no custom branding, everything looks exactly like it does now (FitnessAI + Dumbbell icon + default colors)
- [ ] AC-12: Branding colors respect dark mode (colors should work in both light and dark themes)
- [ ] AC-13: Logo renders at correct size (24x24 in sidebar header, matching the Dumbbell icon dimensions) with proper aspect ratio handling
- [ ] AC-14: `npx tsc --noEmit` passes with zero errors
- [ ] AC-15: Trainer/Admin/Ambassador dashboards are completely unaffected by this change

## Edge Cases
1. **Trainer has no branding configured** — API returns `{ app_name: "", primary_color: "#6366F1", secondary_color: "#818CF8", logo_url: null }`. Portal should look identical to current state.
2. **Trainer's `app_name` is empty string** — Display "FitnessAI" as fallback, not an empty sidebar header.
3. **Logo URL returns 404** — The `<img>` tag should have an `onError` fallback to the Dumbbell icon. Don't show a broken image.
4. **Trainee has no `parent_trainer`** — API returns default branding. Portal works normally.
5. **Very long `app_name` (50 chars)** — Must truncate with ellipsis in sidebar header. Tooltip on hover showing full name.
6. **Hex colors with different casing** — API guarantees `#RRGGBB` format. Frontend should handle case-insensitively.
7. **API request fails (network error, 500)** — Silently fall back to defaults. No error UI.
8. **User switches between light and dark mode** — Branding colors must remain visible/readable in both modes. If primary_color is very light (#FFFFFF-like), it shouldn't become invisible on white background.
9. **Sidebar is collapsed** — Logo should still display correctly in collapsed mode (centered, no text).
10. **Branding loads after sidebar is already rendered** — Transition should be smooth, not jarring (avoid flash of default → custom).

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| API returns default branding (no trainer config) | Normal FitnessAI default appearance | Uses hardcoded defaults |
| API returns custom branding | Trainer's brand name + logo + colors | Applies branding to sidebar + theme |
| API call fails (network/500) | Normal FitnessAI default | Silently uses defaults, logs error to console |
| Logo URL broken (404) | Dumbbell icon (default) | `onError` handler swaps to Dumbbell icon |
| Very long app name | Truncated with "..." | CSS `truncate` class with title tooltip |

## UX Requirements
- **Loading state:** Sidebar header shows a skeleton rectangle (w-24 h-5) where the name goes, and a skeleton circle (w-6 h-6) where the icon goes. Appears only on initial load — subsequent navigations use cached data.
- **Empty state:** N/A — there's always either custom branding or defaults.
- **Error state:** Invisible — silent fallback to defaults. No toast, no error banner.
- **Success feedback:** None needed — branding just appears.
- **Mobile behavior:** Same branding applied to the mobile Sheet drawer sidebar.
- **Color application:** Apply `primary_color` as an inline CSS variable override on the trainee layout wrapper. This way, sidebar accent colors pick it up. If that's too complex, apply the color directly to specific elements (active nav link background).

## Technical Approach

### New file: `web/src/hooks/use-trainee-branding.ts`
- `useTraineeBranding()` hook using React Query
- Calls `apiClient.get<TrainerBranding>(API_URLS.TRAINEE_BRANDING)`
- `staleTime: 5 * 60 * 1000` (5 minutes)
- Returns `{ data, isLoading, isError }` — consumers check `isLoading` for skeleton, use `data` or defaults
- Type: reuse existing `TrainerBranding` interface from `types/branding.ts`

### Modify: `web/src/components/trainee-dashboard/trainee-sidebar.tsx`
- Import `useTraineeBranding()` hook
- Replace hardcoded "FitnessAI" with `branding?.app_name || "FitnessAI"`
- Replace Dumbbell icon with conditional: if `branding?.logo_url`, show `<img>` with `onError` fallback to Dumbbell
- Apply `primary_color` to sidebar active link styling via inline style or CSS variable

### Modify: `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx`
- Same branding changes as desktop sidebar

### Modify: `web/src/app/(trainee-dashboard)/layout.tsx`
- Apply branding color as CSS custom property on the layout wrapper div
- This allows sidebar components to use the variable

### Files NOT modified:
- No backend changes
- No trainer/admin/ambassador dashboard changes
- No mobile (Flutter) changes

## Out of Scope
- Applying branding to the trainee login page (separate flow)
- Applying branding to email templates
- Custom fonts per trainer
- Custom favicon per trainer
- Full theme override (only sidebar accent + app name + logo)
