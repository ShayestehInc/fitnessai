# Architecture Review: Pipeline 10 -- Web Dashboard Phase 2 (Settings, Progress Charts, Notifications, Invitations)

## Review Date
2026-02-15

## Files Reviewed

### New Files
- `web/src/types/progress.ts`
- `web/src/hooks/use-progress.ts`
- `web/src/hooks/use-settings.ts`
- `web/src/components/settings/profile-section.tsx`
- `web/src/components/settings/appearance-section.tsx`
- `web/src/components/settings/security-section.tsx`
- `web/src/components/trainees/progress-charts.tsx`
- `web/src/components/invitations/invitation-actions.tsx`

### Modified Files
- `web/src/lib/constants.ts`
- `web/src/lib/api-client.ts`
- `web/src/hooks/use-invitations.ts`
- `web/src/providers/auth-provider.tsx`
- `web/src/app/(dashboard)/settings/page.tsx`
- `web/src/app/(dashboard)/trainees/[id]/page.tsx`
- `web/src/app/(dashboard)/notifications/page.tsx`
- `web/src/components/trainees/trainee-progress-tab.tsx`
- `web/src/components/notifications/notification-item.tsx`
- `web/src/components/notifications/notification-popover.tsx`
- `web/src/components/notifications/notification-bell.tsx`
- `web/src/components/invitations/invitation-columns.tsx`
- `web/src/components/layout/user-nav.tsx`

---

## Architectural Alignment

- [x] Follows existing layered architecture (Pages > Hooks > API Client > Backend)
- [x] Models/schemas in correct locations (`types/progress.ts` alongside existing types)
- [x] No business logic in pages (pages delegate to hooks and components)
- [x] Consistent with existing patterns (hooks, components, providers)

### Layering Assessment

All four features follow the established architecture cleanly:

```
Settings Page:
  SettingsPage (page) -> ProfileSection/AppearanceSection/SecuritySection (components)
    -> useUpdateProfile/useUploadProfileImage/useDeleteProfileImage/useChangePassword (hooks)
      -> apiClient.patch/postFormData/delete/post (api-client)

Progress Charts:
  TraineeDetailPage (page) -> TraineeProgressTab (component) -> progress-charts (components)
    -> useTraineeProgress (hook) -> apiClient.get (api-client)

Notifications:
  NotificationBell -> NotificationPopover -> NotificationItem (all components)
    -> useNotifications/useMarkAsRead (existing hooks) + getNotificationTraineeId (helper)

Invitations:
  InvitationColumns -> InvitationActions (component)
    -> useResendInvitation/useCancelInvitation (hooks) -> apiClient.post/delete (api-client)
```

**No layering violations detected.** Every data access goes through hooks. No component calls `apiClient` directly. Navigation logic (notification click-through) lives in page/popover containers, not in the `NotificationItem` presentation component.

---

## State Management Assessment

### Auth Context vs React Query -- Boundary Analysis

The codebase uses two state management approaches with a clear boundary:

| Concern | Mechanism | Why |
|---------|-----------|-----|
| Current user identity | AuthContext (`useState`) | Needed before React Query is initialized; gates route access |
| Server data (trainees, notifications, invitations) | React Query | Caching, background refetch, optimistic updates |
| Profile mutations | React Query mutations + `refreshUser()` | Mutation via React Query; user state sync via AuthContext |
| Theme preference | `next-themes` (localStorage) | Client-only, no server state |
| Form state (settings) | `useState` | Ephemeral, component-local |

**Assessment:** The boundary is clear and correct. The settings hooks (`use-settings.ts`) call `refreshUser()` (from AuthContext) on mutation success rather than invalidating a React Query cache key for the current user. This is the right call because the `user` object lives in AuthContext state, not in a React Query cache. If the user data were migrated to React Query in the future, the mutations would need to invalidate `["current-user"]` instead, but for now the imperative `refreshUser` approach is simpler and correct.

**One nuance:** After `refreshUser()` updates the `user` reference in AuthContext, `ProfileSection`'s `useState`-based form does NOT automatically re-sync (by design -- `useState` only captures the initial value). This means after save + refreshUser, the form retains the user's local values. Since the save just sent those exact values to the server, they are consistent. The `isDirty` flag uses trimmed comparisons against the server-returned user to correctly disable the Save button after a successful save. This is the right behavior.

---

## API Client Assessment

### FormData Addition

The `postFormData<T>()` method was added cleanly to `api-client.ts`:

```typescript
postFormData<T>(url: string, formData: FormData): Promise<T> {
  return request<T>(url, { method: "POST", body: formData });
}
```

The `buildHeaders()` function correctly skips `Content-Type: application/json` when `body instanceof FormData`, letting the browser set the correct `multipart/form-data` boundary:

```typescript
...(options.body && !(options.body instanceof FormData)
  ? { "Content-Type": "application/json" }
  : {}),
```

**Assessment:** Clean. The FormData detection is in `buildHeaders` (shared by both initial request and retry), so the 401-retry path also handles FormData correctly. No issues.

### Constants Organization

New endpoints follow the established pattern:

```typescript
// Static endpoints: SCREAMING_SNAKE_CASE
UPDATE_PROFILE: `${API_BASE}/api/users/me/`,
PROFILE_IMAGE: `${API_BASE}/api/users/profile-image/`,
CHANGE_PASSWORD: `${API_BASE}/api/auth/users/set_password/`,

// Dynamic endpoints: camelCase functions
traineeProgress: (id: number) => `${API_BASE}/api/trainer/trainees/${id}/progress/`,
invitationDetail: (id: number) => `${API_BASE}/api/trainer/invitations/${id}/`,
invitationResend: (id: number) => `${API_BASE}/api/trainer/invitations/${id}/resend/`,
```

**Note:** `UPDATE_PROFILE` (`/api/users/me/`) and `CURRENT_USER` (`/api/auth/users/me/`) are different endpoints. The naming makes this clear, but a comment explaining the distinction would be helpful for future developers. Not blocking.

---

## Component Patterns Assessment

### Settings Components

The three settings sections (Profile, Appearance, Security) follow the established component conventions:

1. **ProfileSection** (223 lines): Slightly over the 150-line guideline, but the file is a single cohesive form with image upload. Splitting the image upload into a separate component would be reasonable but not urgent.

2. **AppearanceSection** (104 lines): Well under limit. Uses `useSyncExternalStore` for hydration-safe mount detection -- this is the correct React 19 approach (avoids the `useEffect(() => setMounted(true), [])` anti-pattern). Keyboard navigation with arrow keys and roving tabindex follows WAI-ARIA radiogroup pattern.

3. **SecuritySection** (173 lines): Slightly over limit. Error handling for Djoser's password validation responses is thorough -- parses `current_password`, `new_password`, and `non_field_errors` from the response body. The form uses `<form onSubmit>` (correct -- enables Enter-to-submit).

### Progress Charts

**progress-charts.tsx** (276 lines): Contains three chart components (`WeightChart`, `VolumeChart`, `AdherenceChart`) and two shared utilities. This exceeds the 150-line guideline, but splitting three tightly related chart components into three separate files would create import churn without meaningful benefit. The file is organized with clear interfaces between each section. Acceptable pragmatic decision.

**Architectural fixes applied:**
1. **Extracted `tooltipContentStyle`** -- The identical tooltip CSS object was duplicated across all three charts. Extracted to a single shared `const tooltipContentStyle: React.CSSProperties` at the top of the file. Reduces duplication and ensures tooltip styling stays consistent.

2. **Replaced hardcoded HSL colors with theme chart variables** -- The `AdherenceChart` used `hsl(142, 76%, 36%)`, `hsl(221, 83%, 53%)`, `hsl(47, 96%, 53%)` for the stacked bars. These bypassed the design system and would not adapt to dark mode. Replaced with `hsl(var(--chart-2))`, `hsl(var(--chart-1))`, `hsl(var(--chart-4))` which reference the CSS custom properties defined in `globals.css` for both light and dark themes. This is architecturally important for the white-label infrastructure priority -- when per-trainer branding is added, chart colors will automatically follow the theme.

3. **Fixed recharts v3 formatter type** -- The `VolumeChart` tooltip formatter had `(value: number)` but recharts v3's `Formatter` type expects `(value: number | undefined)`. Fixed to handle `undefined` gracefully.

### Notification Click-Through

The `getNotificationTraineeId()` helper in `notification-item.tsx` is an exported pure function that:
- Handles both `number` and `string` types from the API's `data` JSONField
- Returns `number | null` (not `number | undefined`) -- clear null-means-absent semantics
- Validates `> 0` to prevent ID 0 edge cases

This helper is shared between `notification-item.tsx` (visual indicator), `notification-popover.tsx` (navigation), and `notifications/page.tsx` (navigation). Extracting it as a named export rather than duplicating the logic is correct.

**Controlled Popover pattern:** `NotificationBell` uses `useState(false)` for controlled open/close, passing `onClose` to `NotificationPopover`. This is necessary because programmatic close (after navigation) is not possible with uncontrolled Radix Popovers. Correct approach.

### Invitation Actions

`InvitationActions` handles the PENDING/EXPIRED/ACCEPTED/CANCELLED status matrix correctly:
- Status-dependent action visibility (`canResend`, `canCancel`)
- `is_expired` flag override (backend keeps `status=PENDING` even after expiration)
- Controlled dropdown state to prevent UI conflicts between dropdown and dialog
- Confirmation dialog for destructive cancel action

The mutations use `queryClient.invalidateQueries({ queryKey: ["invitations"] })` which correctly invalidates all paginated invitation queries. No stale data after resend/cancel.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No backend changes -- all APIs already existed |
| Migrations needed | N/A | No new models or fields |
| Indexes for new queries | PASS | Progress endpoint uses existing indexed fields |
| No N+1 query patterns | PASS | All new frontend queries are single-endpoint fetches |

### TypeScript Type Alignment

| TS Type | Backend Source | Status | Notes |
|---------|---------------|--------|-------|
| `TraineeProgress` | `GET /api/trainer/trainees/<id>/progress/` | PASS | `weight_progress`, `volume_progress`, `adherence_progress` arrays |
| `WeightEntry` | Inline in progress response | PASS | `date: string`, `weight_kg: number` |
| `VolumeEntry` | Inline in progress response | PASS | `date: string`, `volume: number` |
| `AdherenceEntry` | Inline in progress response | PASS | `date: string`, `logged_food/workout: boolean`, `hit_protein: boolean` |
| `UpdateProfilePayload` | `PATCH /api/users/me/` | PASS | `first_name`, `last_name`, `business_name` |
| `ChangePasswordPayload` | `POST /api/auth/users/set_password/` | PASS | Djoser `current_password`, `new_password` |
| `ProfileImageResponse` | `POST /api/users/profile-image/` | PASS | `success`, `profile_image`, `user` |

---

## Scalability Concerns

| # | Area | Status | Notes |
|---|------|--------|-------|
| 1 | Progress charts with large datasets | MINOR | recharts renders all data points. For trainees with 365+ weight check-ins, the weight chart would render 365 SVG elements. Currently acceptable (backend returns last N check-ins). If the API ever returns unbounded data, add client-side data downsampling or time-range filtering. |
| 2 | recharts bundle size | PASS | recharts v3 is tree-shakeable. Only `LineChart`, `BarChart`, and their sub-components are imported. Bundle impact is ~45-60KB gzipped. The `TraineeProgressTab` is only rendered when the user navigates to a specific trainee's Progress tab, so this does not affect initial load. |
| 3 | Profile image upload size | PASS | Client-side validation at 5MB prevents oversized uploads. Backend likely has its own limit. |
| 4 | Notification popover slice | MINOR | `data?.results?.slice(0, 5)` fetches a full page (~20 items) and discards 15. A `?page_size=5` parameter would be more efficient. Carried forward from Pipeline 9 debt. |
| 5 | Settings form re-renders | PASS | `useCallback` on handlers prevents unnecessary child re-renders. `isDirty` is computed inline (not in state) -- correct, avoids stale comparisons. |

---

## Technical Debt

### Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `progress-charts.tsx` is 276 lines (vs 150-line guideline) | LOW | Three chart components + shared utilities in one file. Pragmatic for now; split when a 4th chart is added. |
| 2 | `ProfileSection` at 223 lines | LOW | Image upload section could be extracted to `ProfileImageUpload` component. Not urgent. |
| 3 | Dev-done.md lists recharts as `^2.15.3` but package.json has `^3.7.0` | LOW | Documentation inconsistency. The actual dependency is correct at v3. |
| 4 | `SettingsPage.refreshUser` in error retry uses `window.location.reload()` | LOW | Could use `refreshUser()` directly instead of a full page reload. Minor -- the error state is rare. |

### Debt Reduced

| # | Description | Impact |
|---|-------------|--------|
| 1 | Settings page is no longer a placeholder | Removed "Coming soon" technical debt from Pipeline 9 |
| 2 | Progress tab is no longer a placeholder | Removed "Coming soon" technical debt from Pipeline 9 |
| 3 | Notification items are now actionable | Notifications go from read-only to click-through navigation |
| 4 | Invitation table has complete CRUD | Copy/Resend/Cancel actions replace the action-less table |

---

## Changes Made by Architect

### `web/src/components/trainees/progress-charts.tsx`
1. **Extracted shared `tooltipContentStyle` constant** -- Replaced three identical inline `contentStyle` objects with a single `const tooltipContentStyle: React.CSSProperties` at the top of the file. Eliminates triple-duplication and makes tooltip styling changes a single-point edit.

2. **Replaced hardcoded HSL colors with theme CSS custom properties** -- Added `CHART_COLORS` constant mapping `food`, `workout`, `protein` to `hsl(var(--chart-2))`, `hsl(var(--chart-1))`, `hsl(var(--chart-4))` respectively. These variables are defined in `globals.css` with both light and dark mode values. The hardcoded `hsl(142, 76%, 36%)`, `hsl(221, 83%, 53%)`, `hsl(47, 96%, 53%)` were bypassing the design system and would not adapt to dark mode or future white-label theming.

3. **Fixed recharts v3 type error** -- `VolumeChart` tooltip formatter parameter type changed from `(value: number)` to `(value: number | undefined)` to match recharts v3's `Formatter` type. Added `undefined` handling with an em-dash fallback.

### `web/src/components/settings/profile-section.tsx`
4. **Fixed `isDirty` trim consistency** -- Changed `isDirty` comparisons from `form.firstName !== (user?.first_name ?? "")` to `form.firstName.trim() !== (user?.first_name ?? "")`. The `handleSave` already sends `.trim()` values, so `isDirty` should compare trimmed values for consistency. Without this fix, typing " John " then saving would result in `isDirty` being `true` again after `refreshUser` returned "John".

5. **Removed `useEffect`-based form sync** -- The previous implementation had a `useEffect` that called `setForm(...)` whenever `user` changed. This violated React 19's `react-hooks/set-state-in-effect` lint rule and caused unnecessary cascading re-renders. Removed the effect entirely. The `useState` initializer captures the user's data at mount time, and subsequent changes after save are handled by the `isDirty` flag. The parent `SettingsPage` guards `!user` before rendering `ProfileSection`, so the initial state is always valid.

### `web/src/components/settings/appearance-section.tsx`
6. **Removed unused `ThemeValue` type** -- The type alias `type ThemeValue = (typeof themes)[number]["value"]` was defined but never referenced anywhere in the file. Removed dead code.

---

## Architecture Score: 9/10

**Strengths (what earned points):**
- All four features follow the established Page > Hook > API Client layering perfectly
- React Query mutations correctly invalidate related queries on success
- Auth boundary (Context for user identity, React Query for server data) is clear and consistent
- FormData handling in api-client is clean with correct Content-Type detection
- TypeScript types accurately mirror backend API responses
- getNotificationTraineeId helper is well-designed: handles both string and number types, validates > 0, exported for reuse
- Controlled popover and dropdown state management handles edge cases (navigation dismiss, dialog opening)
- Empty/loading/error states handled for every new surface
- Invitation status matrix correctly handles PENDING/EXPIRED/ACCEPTED/CANCELLED actions

**Deductions:**
- -0.5: Two files exceed 150-line component guideline (pragmatically acceptable but noted)
- -0.5: Minor documentation inconsistency (recharts version in dev-done.md)

## Recommendation: APPROVE

The architecture is clean and consistent. The four new features integrate seamlessly with the established patterns. The fixes applied (theme-aware chart colors, tooltip deduplication, isDirty trim consistency, lint violation resolution) improve the codebase quality. No redesign or major refactoring needed. The codebase is well-positioned for the upcoming white-label infrastructure work since chart colors now participate in the design system's theme variables.
