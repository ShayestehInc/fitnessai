# Architecture Review: Trainee Web -- Trainer Branding Application (Pipeline 34)

## Review Date
2026-02-23

## Files Reviewed

**New/Modified Components (Pipeline 34 scope):**
- `web/src/components/trainee-dashboard/trainee-sidebar.tsx` -- desktop sidebar with branding
- `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` -- mobile sidebar with branding
- `web/src/components/trainee-dashboard/brand-logo.tsx` -- **extracted** shared BrandLogo component

**New/Modified Hooks:**
- `web/src/hooks/use-trainee-branding.ts` -- React Query hook for trainee-facing branding data

**New/Modified Types:**
- `web/src/types/branding.ts` -- `TraineeBranding` interface moved here (alongside existing `TrainerBranding`)

**Comparison Files Reviewed (existing patterns):**
- `web/src/hooks/use-branding.ts` -- trainer-side branding hook (for pattern comparison)
- `web/src/types/branding.ts` -- existing `TrainerBranding` type
- `web/src/lib/constants.ts` -- `API_URLS.TRAINEE_BRANDING` endpoint
- `web/src/lib/api-client.ts` -- API client pattern
- `web/src/components/layout/sidebar.tsx` -- trainer desktop sidebar (structural reference)
- `web/src/components/layout/sidebar-mobile.tsx` -- trainer mobile sidebar (structural reference)
- `web/src/components/layout/admin-sidebar.tsx` -- admin desktop sidebar (structural reference)
- `web/src/components/layout/admin-sidebar-mobile.tsx` -- admin mobile sidebar (structural reference)
- `web/src/components/layout/ambassador-sidebar.tsx` -- ambassador desktop sidebar (structural reference)
- `web/src/components/layout/ambassador-sidebar-mobile.tsx` -- ambassador mobile sidebar (structural reference)
- `backend/users/views.py` -- `MyBrandingView` endpoint (API contract verification)
- `backend/trainer/serializers.py` -- `TrainerBrandingSerializer` (response shape verification)

---

## Architectural Alignment

- [x] Follows existing layered architecture (hook for data fetching, component for UI, types in `types/`)
- [x] Models/schemas in correct locations (after fix: `TraineeBranding` moved to `types/branding.ts`)
- [x] No business logic in components (display name derivation and color comparison are pure utility functions in the hook module)
- [x] Consistent with existing patterns (mirrors `use-branding.ts` / `TrainerBranding` patterns)

---

## 1. LAYERING -- Business Logic in Right Layer?

**Score: 10/10**

The layering is textbook:

| Layer | File | Responsibility |
|-------|------|---------------|
| Types | `types/branding.ts` | `TraineeBranding` interface |
| Data | `hooks/use-trainee-branding.ts` | React Query fetch + defaults + utility functions |
| UI | `trainee-sidebar.tsx`, `trainee-sidebar-mobile.tsx` | Consume hook, render branding |
| Shared UI | `brand-logo.tsx` | Reusable logo rendering with error fallback |

The hook cleanly separates three concerns:
1. **Data fetching** (`useTraineeBranding`) -- query, staleTime, retry, default fallback
2. **Display logic** (`getBrandingDisplayName`) -- pure function, no side effects
3. **Color detection** (`hasCustomPrimaryColor`) -- pure comparison function

Components consume these without any data-fetching logic of their own. The sidebar components only deal with presentation: skeleton states, layout, active-link highlighting with branded colors.

---

## 2. DATA MODEL -- Types Match Backend? Well-Defined?

**Score: 9/10**

**API contract verification:**

The backend `MyBrandingView` returns:
```python
{'app_name': str, 'primary_color': str, 'secondary_color': str, 'logo_url': str | None}
```

The frontend `TraineeBranding` interface matches exactly:
```typescript
{ app_name: string; primary_color: string; secondary_color: string; logo_url: string | null; }
```

**Field naming discrepancy (documented, correct):**
- `TrainerBranding.logo` (relative path, used for CRUD in trainer branding settings)
- `TraineeBranding.logo_url` (absolute URL from `SerializerMethodField`, read-only for trainees)

This is not a bug -- it correctly reflects two different API contracts. The `TrainerBrandingSerializer` exposes `logo_url` as a `SerializerMethodField` that calls `request.build_absolute_uri()`, while the trainer-facing CRUD uses the raw `logo` field. I added a JSDoc comment to `types/branding.ts` documenting this intentional difference.

**Default branding values:**
```typescript
const DEFAULT_BRANDING: TraineeBranding = {
  app_name: "",
  primary_color: "#6366F1",
  secondary_color: "#818CF8",
  logo_url: null,
};
```

These match the backend's `_DEFAULT_BRANDING_RESPONSE` exactly (`TrainerBranding.DEFAULT_PRIMARY_COLOR` = `#6366F1`, `DEFAULT_SECONDARY_COLOR` = `#818CF8`). Backward-compatible -- trainees with no trainer or no branding configured will see the FitnessAI defaults.

---

## 3. API DESIGN -- React Query Setup Correct? Cache Strategy Appropriate?

**Score: 10/10**

```typescript
useQuery<TraineeBranding>({
  queryKey: ["trainee-branding"],
  queryFn: () => apiClient.get<TraineeBranding>(API_URLS.TRAINEE_BRANDING),
  staleTime: 5 * 60 * 1000,
  retry: 1,
});
```

**Cache strategy analysis:**

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| `staleTime: 5min` | Correct | Branding changes infrequently (trainer updates once, maybe never again). 5 minutes prevents unnecessary refetches while still picking up changes within a session. |
| `retry: 1` | Correct | Branding is non-critical UI enhancement. One retry is sufficient; failing silently to defaults is the right behavior. |
| Query key `["trainee-branding"]` | Correct | Simple, stable key. No parameterization needed (one branding per trainee session). No collision with trainer-side `["branding"]` key used in `use-branding.ts`. |
| Default fallback `data ?? DEFAULT_BRANDING` | Correct | Graceful degradation -- the sidebar renders with FitnessAI defaults during loading or on error. |

**API URL centralized:**
```typescript
TRAINEE_BRANDING: `${API_BASE}/api/users/my-branding/`,
```

Follows the existing `TRAINEE_*` naming pattern used for `TRAINEE_PROGRAMS`, `TRAINEE_NUTRITION_SUMMARY`, etc.

---

## 4. FRONTEND PATTERNS -- Components Follow Conventions? DRY?

**Score: 9/10 (after fixes)**

### Issues Found and Fixed

**Issue 1 (Major -- fixed): DRY violation in BrandLogo**

Both `trainee-sidebar.tsx` and `trainee-sidebar-mobile.tsx` contained independent implementations of a `BrandLogo` component with the same logic: accept a `logoUrl`, manage `imgError` state, fall back to `<Dumbbell>` on error. The implementations were nearly identical but subtly different (desktop version accepted a `size` prop, mobile version was hardcoded to `h-6 w-6`).

**Fix:** Extracted `BrandLogo` to `/web/src/components/trainee-dashboard/brand-logo.tsx` as a shared component with `logoUrl`, `altText`, and `size` props. Both sidebars now import from the shared file. Removed ~25 lines of duplicated code per sidebar.

**Issue 2 (Minor -- fixed): Type defined in wrong layer**

The `TraineeBranding` interface was defined inline in `hooks/use-trainee-branding.ts`. The codebase convention is types in `types/` directory -- `TrainerBranding` is in `types/branding.ts`, `WorkoutHistoryItem` is in `types/trainee-dashboard.ts`, etc.

**Fix:** Moved `TraineeBranding` to `types/branding.ts` (collocated with the related `TrainerBranding` type). The hook file now imports from `@/types/branding` and re-exports the type for convenience.

### Patterns That Align Well

- Both sidebars follow the exact structural pattern of the trainer/admin/ambassador sidebars: same class names, same collapse behavior, same tooltip pattern
- Loading states use `<Skeleton>` consistently with other sidebars
- Badge rendering follows the same pattern as the trainer sidebar's unread count badges
- Custom color application (`style={{ backgroundColor: ... }}`) is a safe progressive enhancement -- falls back to theme colors when `isCustomColor` is false
- The `${branding.primary_color}20` pattern (appending hex alpha) is a clean approach for creating a tinted background without needing CSS variable injection

---

## 5. SCALABILITY -- Re-renders, Performance

**Score: 10/10**

**No unnecessary re-renders:**
- `useTraineeBranding()` is called once per sidebar component. Since both desktop and mobile sidebars are never mounted simultaneously (desktop is `hidden lg:block`, mobile is a Sheet), the React Query cache serves both efficiently with zero duplicate network requests.
- `getBrandingDisplayName` and `hasCustomPrimaryColor` are pure functions called during render -- no memo needed since their inputs (`branding` object) only change when the query refetches.
- `BrandLogo` uses local `useState` for `imgError` -- this is the correct pattern. The error state is per-mount, so if the image 404s, only the mounted instance re-renders.

**No N+1 patterns:**
- One API call fetches all branding data. No per-field fetching, no waterfall.

**Image optimization:**
- `unoptimized` prop on `next/image` is correct for user-uploaded logos from the backend (external URLs that Next.js image optimizer may not be configured for).

---

## 6. TECHNICAL DEBT -- Introduced or Reduced?

**Score: 9/10 (net positive after fixes)**

### Debt Reduced (by this review)

| # | Change | Impact |
|---|--------|--------|
| 1 | Extracted `BrandLogo` to shared component | Eliminates ~50 lines of duplication between sidebars. Future branding-aware components can import and reuse. |
| 2 | Moved `TraineeBranding` to `types/branding.ts` | All branding types now live in one file, consistent with codebase convention. |
| 3 | Added JSDoc documenting `logo` vs `logo_url` field difference | Prevents future confusion when someone sees both types side by side. |

### Debt Remaining (pre-existing, not introduced by this pipeline)

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Trainer sidebar (`layout/sidebar.tsx`) does not use trainer branding | Low | Future pipeline: apply same branding pattern to the trainer's own sidebar when viewing their dashboard |
| 2 | No shared `ActiveLinkStyle` utility for branded active states | Low | The `style={{ backgroundColor: \`\${color}20\` }}` pattern is now repeated in both sidebars. If branding expands to more components, extract a `getBrandedActiveStyle(branding, isActive)` utility. Not needed yet. |

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No backend schema changes -- reads existing `my-branding/` endpoint |
| Migrations reversible | N/A | No migrations |
| Indexes added for new queries | N/A | Uses existing endpoint |
| No N+1 query patterns | PASS | Single API call for all branding data |
| Types match API contracts | PASS | `TraineeBranding` exactly matches `MyBrandingView` response shape (verified against backend code) |
| Default values match backend | PASS | `DEFAULT_BRANDING` matches `_DEFAULT_BRANDING_RESPONSE` in `MyBrandingView` |

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| -- | -- | No scalability concerns identified | The branding data is small, infrequently changing, and properly cached. |

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| -- | None introduced | -- | The implementation is clean and follows established patterns. |

---

## Changes Made During This Review

| # | File | What Changed | Why |
|---|------|-------------|-----|
| 1 | `web/src/components/trainee-dashboard/brand-logo.tsx` | **Created** shared `BrandLogo` component | Eliminate DRY violation between desktop and mobile sidebars |
| 2 | `web/src/components/trainee-dashboard/trainee-sidebar.tsx` | Removed inline `BrandLogo` definition, now imports from `./brand-logo` | DRY fix |
| 3 | `web/src/components/trainee-dashboard/trainee-sidebar-mobile.tsx` | Removed inline `BrandLogo` definition, now imports from `./brand-logo` | DRY fix |
| 4 | `web/src/types/branding.ts` | Added `TraineeBranding` interface with JSDoc | Types belong in `types/` directory per codebase convention |
| 5 | `web/src/hooks/use-trainee-branding.ts` | Import `TraineeBranding` from `@/types/branding` instead of defining inline; re-exports for convenience | Consistent type location |

---

## Detailed Scoring Matrix

| Area | Score | Notes |
|------|-------|-------|
| Layering | 10/10 | Hook fetches data, components render, utilities are pure functions |
| Data model / types | 9/10 | Correct API contract match; minor: `logo` vs `logo_url` naming documented |
| API design / query keys | 10/10 | Proper staleTime, retry, default fallback, centralized URL, no key collisions |
| Component decomposition | 9/10 | After extraction of shared BrandLogo, both sidebars are clean and DRY |
| Scalability | 10/10 | Single small API call, proper caching, no re-render concerns |
| Technical debt | 9/10 | Net reduction -- extracted shared component, centralized type, added documentation |

---

## Architecture Score: 9/10

The trainer branding application to the trainee web portal is architecturally sound. The implementation correctly:

- **Separates data from presentation**: `useTraineeBranding` hook handles fetching and defaults; sidebar components only handle rendering
- **Matches the backend API contract**: `TraineeBranding` interface exactly matches `MyBrandingView` response shape, including the correct `logo_url` field (vs trainer-side `logo`)
- **Uses appropriate cache strategy**: 5-minute staleTime for infrequently-changing data, single retry, graceful degradation to defaults
- **Follows existing patterns**: mirrors the trainer sidebar structure, uses centralized `API_URLS`, consistent query key naming
- **Progressive enhancement**: branded colors are applied via inline `style` props only when custom color is detected, falling back to theme defaults otherwise

Three architectural improvements were made during this review:
1. Extracted `BrandLogo` into a shared component to eliminate DRY violation
2. Moved `TraineeBranding` type to `types/branding.ts` per codebase convention
3. Added JSDoc documenting the intentional `logo` vs `logo_url` field difference

## Recommendation: APPROVE
