# Architecture Review: Pipeline 9 -- Web Trainer Dashboard

## Review Date
2026-02-15

## Files Reviewed

### Frontend (web/)
- `web/src/types/activity.ts`, `api.ts`, `trainer.ts`, `user.ts`, `notification.ts`, `invitation.ts`
- `web/src/hooks/use-auth.ts`, `use-dashboard.ts`, `use-debounce.ts`, `use-trainees.ts`, `use-invitations.ts`, `use-notifications.ts`
- `web/src/providers/query-provider.tsx`, `theme-provider.tsx`, `auth-provider.tsx`
- `web/src/lib/constants.ts`, `utils.ts`, `token-manager.ts`, `api-client.ts`
- `web/src/app/layout.tsx`, `web/src/app/(dashboard)/layout.tsx`, `web/src/app/(auth)/layout.tsx`
- `web/src/app/(dashboard)/dashboard/page.tsx`, `trainees/page.tsx`, `trainees/[id]/page.tsx`, `invitations/page.tsx`, `notifications/page.tsx`, `settings/page.tsx`
- `web/src/app/(auth)/login/page.tsx`
- `web/src/middleware.ts`, `web/next.config.ts`
- All components in `web/src/components/` (dashboard/, layout/, trainees/, invitations/, notifications/, shared/)

### Backend (reviewed for API contract alignment)
- `backend/trainer/serializers.py` (all serializers)
- `backend/trainer/views.py` (all views)
- `backend/config/settings.py` (CORS config)

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (PASS -- pages delegate to hooks, hooks delegate to API client)
- [x] Consistent with existing patterns

### Layering Assessment

The Web Trainer Dashboard follows a clean layered architecture:

```
Pages (app/)  -->  Hooks (hooks/)  -->  API Client (lib/api-client.ts)  -->  Backend API
   |                    |                        |
   v                    v                        v
Components (components/)  Types (types/)   Constants (lib/constants.ts)
```

**Strengths:**
1. **Pages are thin orchestrators.** Each page file composes hooks + components and handles routing/state transitions. No data fetching or business logic in pages.
2. **Hooks encapsulate data concerns.** React Query configuration, cache keys, and URL construction are all in hooks. Components never call `apiClient` directly.
3. **Shared components are genuinely reusable.** `DataTable`, `EmptyState`, `ErrorState`, `PageHeader`, `LoadingSpinner` are parameterized generics used across all pages.
4. **TypeScript types mirror backend serializers.** `TraineeListItem`, `TraineeDetail`, `DashboardStats`, `Invitation`, `Notification` all match their Django serializer counterparts field-for-field.
5. **Auth is centralized.** Token management, refresh logic, and role enforcement all live in `auth-provider.tsx` + `token-manager.ts` + `middleware.ts`. No auth logic leaks into components.

### Issues Found and Fixed

**Issue 1 (FIXED): Backend `TraineeDetailView` missing `select_related`/`prefetch_related`.**

The `TraineeDetailView.get_queryset()` returned a plain `User.objects.filter(...)` without any prefetching. The `TraineeDetailSerializer` accesses `obj.profile`, `obj.nutrition_goal`, `obj.programs`, and `obj.activity_summaries` -- each triggering a separate SQL query per trainee (N+1).

**Fix applied:** Added `.select_related('profile', 'nutrition_goal').prefetch_related('programs', 'activity_summaries')` to the queryset.

**Issue 2 (FIXED): Backend `TrainerDashboardView` N+1 loop for inactive trainees.**

The view iterated over all trainees in Python, querying `trainee.activity_summaries.order_by('-date').first()` for each one. For a trainer with 50 trainees, this was 50+ SQL queries.

**Fix applied:** Replaced the Python loop with a single annotated query: `trainees.annotate(latest_activity_date=Max('activity_summaries__date')).filter(...)`. Also added `select_related('profile').prefetch_related('daily_logs', 'programs')` to the base queryset.

**Issue 3 (FIXED): Backend `TrainerStatsView` N+1 loop for pending onboarding count.**

The view iterated over trainees with `for trainee in trainees: trainee.profile.onboarding_completed`, triggering a query per trainee.

**Fix applied:** Replaced with `trainees.filter(Q(profile__isnull=True) | Q(profile__onboarding_completed=False)).count()`.

**Issue 4 (FIXED): Backend `AdherenceAnalyticsView` N+1 loop for per-trainee adherence.**

The view iterated over trainees, running `summaries.filter(trainee=trainee).count()` and a second filtered count per trainee.

**Fix applied:** Replaced with a single annotated `.values().annotate()` query using `Case`/`When` to compute adherence in one SQL pass.

**Issue 5 (FIXED): Backend `ProgressAnalyticsView` N+1 queries and bare `except:`.**

The view iterated per-trainee calling `trainee.weight_checkins.order_by('date')` without prefetch, and used bare `except:` for profile access.

**Fix applied:** Added `.select_related('profile').prefetch_related('weight_checkins')`. Changed bare `except:` to specific `User.profile.RelatedObjectDoesNotExist`.

**Issue 6 (FIXED): Backend serializers used bare `except:` clauses (4 instances).**

`TraineeListSerializer.get_profile_complete`, `TraineeDetailSerializer.get_profile`, `TraineeDetailSerializer.get_nutrition_goal`, and `ProgressAnalyticsView.get` all had bare `except:` that would silently swallow any error. Per project rules: "NO exception silencing."

**Fix applied:** Changed all 4 instances to catch the specific `RelatedObjectDoesNotExist` exception.

**Issue 7 (FIXED): `TraineeListSerializer.get_last_activity` bypassed prefetch cache.**

The method called `obj.daily_logs.order_by('-date').first()` which issues a new SQL query even when `daily_logs` is prefetched (because `.order_by().first()` creates a new queryset).

**Fix applied:** Changed to iterate prefetched data in Python: `list(obj.daily_logs.all())` then `max(log.date for log in logs)`.

**Issue 8 (FIXED): `TraineeListSerializer.get_current_program` bypassed prefetch cache.**

Same pattern -- `obj.programs.filter(is_active=True).first()` creates a new queryset, defeating prefetch.

**Fix applied:** Changed to `next((p for p in obj.programs.all() if p.is_active), None)`.

**Issue 9 (FIXED): Frontend `DashboardOverview` type missing `today` field.**

The backend `TrainerDashboardView` returns `{'recent_trainees': ..., 'inactive_trainees': ..., 'today': str(today)}` but the TypeScript `DashboardOverview` interface only had `recent_trainees` and `inactive_trainees`.

**Fix applied:** Added `today: string` to the `DashboardOverview` interface.

**Issue 10 (FIXED): Backend `TraineeActivityView` and `AdherenceAnalyticsView` accepted unbounded `days` parameter.**

The `days` query parameter was parsed as `int(request.query_params.get('days', 30))` without bounds checking. A malicious request with `?days=999999999` would generate an expensive query.

**Fix applied:** Added `min(max(int(...), 1), 365)` clamping with try/except fallback to 30.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | N/A | No schema changes -- web dashboard consumes existing API |
| Migrations needed | N/A | No new models or fields |
| Indexes for new queries | PASS | All queries use existing indexed fields (`parent_trainer`, `date`, `trainee`) |
| No N+1 query patterns | FIXED | 6 N+1 patterns fixed (see Issues 1-5, 7-8 above) |

### TypeScript / Django Serializer Contract Alignment

| TS Type | Django Serializer | Match? | Notes |
|---------|-------------------|--------|-------|
| `DashboardStats` | `TrainerDashboardStatsSerializer` | PASS | All 8 fields match |
| `DashboardOverview` | `TrainerDashboardView.get()` response | FIXED | Added missing `today` field |
| `TraineeListItem` | `TraineeListSerializer` | PASS | All 9 fields match |
| `TraineeDetail` | `TraineeDetailSerializer` | PASS | All 12 fields match |
| `TraineeProgram` | Inline dict in serializer | PASS | `is_active` is optional in TS (only returned in detail view) |
| `TraineeProfile` | Inline dict in serializer | PASS | All 9 fields match |
| `NutritionGoal` | Inline dict in serializer | PASS | All 5 fields match |
| `RecentActivity` | Inline dict in serializer | PASS | All 6 fields match |
| `ActivitySummary` | `TraineeActivitySerializer` | PASS | All 16 fields match |
| `Invitation` | `TraineeInvitationSerializer` | PASS | All 12 fields match |
| `CreateInvitationPayload` | `CreateInvitationSerializer` | PASS | All 4 fields match |
| `Notification` | Implied from backend | PASS | Standard notification fields |
| `User` | `users/me/` response | PASS | Matches Djoser user serializer |
| `PaginatedResponse<T>` | DRF standard pagination | PASS | `{count, next, previous, results}` |

---

## API Design

| Area | Pattern | Status | Notes |
|------|---------|--------|-------|
| RESTful URLs | `/api/trainer/trainees/`, `/api/trainer/dashboard/` | PASS | Consistent noun-based paths |
| Error handling | `ApiError` class with status/body | PASS | Structured error propagation |
| Pagination | DRF `PageNumberPagination` | PASS | Standard `?page=N` with `count`/`next`/`previous` |
| Auth | JWT with auto-refresh | PASS | 401 triggers refresh + retry pattern |
| CORS | Development: allow all; Production: env-configured whitelist | PASS | `CORS_ALLOW_CREDENTIALS = True` |

**API Client Design (Frontend):**

The `apiClient` object in `web/src/lib/api-client.ts` is well-designed:
- Generic `request<T>()` with typed responses
- Automatic 401 handling with token refresh and retry (single retry only -- prevents infinite loops)
- Session expiry redirects to `/login`
- `ApiError` class preserves status code and response body for structured error display
- Content-Type header only added when body is present (correct for GET/DELETE)

---

## Frontend Patterns

### Component Hierarchy

```
RootLayout (providers: Theme > Query > Auth > Tooltip)
  ├── AuthLayout (centered card)
  │   └── LoginPage
  └── DashboardLayout (sidebar + header + main)
      ├── DashboardPage (StatsCards, RecentTrainees, InactiveTrainees)
      ├── TraineesPage (TraineeSearch, TraineeTable w/ DataTable)
      ├── TraineeDetailPage (Overview/Activity/Progress tabs)
      ├── InvitationsPage (InvitationTable, CreateInvitationDialog)
      ├── NotificationsPage (NotificationItem list)
      └── SettingsPage (placeholder)
```

**Assessment:** Clean hierarchy. No deeply nested prop drilling -- hooks provide data at the point of use. Layout concerns (sidebar, header) are separated from page content. The `(dashboard)` and `(auth)` route groups correctly split authenticated and public layouts.

### React Query Configuration

| Setting | Value | Assessment |
|---------|-------|------------|
| `staleTime` | 30s | GOOD -- dashboard data is reasonably fresh without over-fetching |
| `retry` | 1 | GOOD -- prevents hammering a failing API |
| `refetchOnWindowFocus` | false | GOOD for dashboard (avoids jarring refetches when tabbing back) |
| Notification polling | 30s (`refetchInterval`) | GOOD -- not in background (`refetchIntervalInBackground: false`) |

**Cache Key Strategy:**
- `["dashboard", "stats"]` / `["dashboard", "overview"]` -- correctly separated
- `["trainees", page, search]` -- includes all query parameters as cache key dimensions
- `["trainee", id]` -- per-trainee cache
- `["trainee", id, "activity", days]` -- correctly parameterized by days
- `["invitations", page]` -- paginated
- `["notifications", page, filter]` -- paginated + filtered
- `["notifications", "unread-count"]` -- polled independently

The key strategy is correct -- invalidation after mutations uses `queryKey` prefix matching (`{ queryKey: ["invitations"] }` invalidates all invitation pages).

### Hook Pattern

All hooks follow a consistent pattern:
```typescript
export function useXxx(params) {
  return useQuery<TypedResponse>({
    queryKey: ["key", ...params],
    queryFn: () => apiClient.get<TypedResponse>(url),
  });
}
```

Mutations follow:
```typescript
export function useCreateXxx() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data) => apiClient.post<T>(url, data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: [...] }),
  });
}
```

This is textbook React Query usage. No issues.

### Provider Nesting

```
ThemeProvider > QueryProvider > AuthProvider > TooltipProvider
```

This is correct:
- `ThemeProvider` is outermost (no dependencies)
- `QueryProvider` wraps `AuthProvider` (auth could use queries in future)
- `AuthProvider` provides user context to all dashboard components
- `TooltipProvider` is innermost (UI only)

The `Toaster` sits outside all providers (correct -- it uses its own portal).

### Auth Flow

```
Middleware (server-side):
  cookie "has_session" → redirect to /dashboard or /login

AuthProvider (client-side):
  1. Check localStorage for tokens
  2. If access token expired, try refresh
  3. Fetch /users/me/ to validate
  4. If role !== TRAINER, clear tokens + error
  5. 10-second timeout guard against hanging auth
```

The dual-layer auth (server middleware + client provider) is the correct Next.js pattern. The middleware handles the initial redirect (before JS loads), and the AuthProvider handles the detailed validation (after hydration).

**Security note:** The `has_session` cookie is not an auth token -- it's a boolean hint. The actual auth happens via the JWT tokens in localStorage. This is acceptable because the cookie only controls redirect behavior, not data access.

---

## Scalability Concerns

| # | Area | Status | Notes |
|---|------|--------|-------|
| 1 | N+1 queries (backend) | FIXED | 6 N+1 patterns resolved (see Issues above) |
| 2 | Unbounded query params | FIXED | `days` parameter clamped to 1-365 |
| 3 | React Query caching | PASS | 30s stale time, polling only for notification count |
| 4 | Bundle size | MINOR | Only shadcn/ui + lucide-react + date-fns + React Query. No chart library yet. When progress charts are added, use dynamic imports. |
| 5 | DataTable re-renders | PASS | `keyExtractor` prevents unnecessary row remounts |
| 6 | Notification polling | PASS | 30s interval, disabled in background tab |
| 7 | Dashboard concurrent queries | PASS | `useDashboardStats()` and `useDashboardOverview()` fire in parallel (separate hooks, not sequential) |
| 8 | Image optimization | PASS | Next.js `remotePatterns` configured for backend image hosts |
| 9 | Standalone output | PASS | `output: "standalone"` in next.config for Docker deployment |

**Concern #4 detail:** The current bundle is lean. When the `TraineeProgressTab` is implemented with charts (currently a placeholder), the charting library should be loaded via `next/dynamic` with `ssr: false` to keep the initial bundle small.

---

## Technical Debt

### Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `TraineeProgressTab` is a placeholder | LOW | Documented as "Coming soon." Backend `TraineeProgressView` already exists. Frontend integration is the remaining work. |
| 2 | `SettingsPage` is a placeholder | LOW | Documented as "Coming soon." Expected to be implemented in a future pipeline. |
| 3 | Pagination UI duplicated across pages | LOW | `InvitationsPage` and `NotificationsPage` have inline prev/next buttons. `TraineesPage` uses `DataTable`'s built-in pagination. A shared `Pagination` component would unify these. The shadcn `Pagination` component exists but is not used. |
| 4 | `NotificationPopover` fetches page 1 and slices to 5 | LOW | This works but fetches up to 20 items (default page size) and discards 15. A dedicated endpoint or `?page_size=5` query param would be more efficient. |
| 5 | Token storage in `localStorage` | MEDIUM | Industry practice is shifting toward `httpOnly` cookies for JWT storage to prevent XSS token theft. The current approach is common and acceptable for a trainer dashboard (not a banking app), but should be revisited if the dashboard handles sensitive financial data (Stripe). |

### Debt Reduced

| # | Description | Impact |
|---|-------------|--------|
| 1 | Backend N+1 queries eliminated | 6 N+1 patterns fixed across `TraineeDetailView`, `TrainerDashboardView`, `TrainerStatsView`, `AdherenceAnalyticsView`, `ProgressAnalyticsView`, and serializers |
| 2 | Bare `except:` clauses replaced | 4 instances replaced with specific exception catches -- improves debuggability |
| 3 | TypeScript/API contract aligned | `DashboardOverview.today` field added to match backend response |
| 4 | Query param bounds checking added | `days` parameter clamped to prevent abuse |

---

## Architecture Score: 8/10

**Strengths (what earned points):**
- Clean layered architecture: Pages > Hooks > API Client > Backend
- TypeScript types accurately mirror Django serializers
- React Query used idiomatically with proper cache keys and invalidation
- Auth flow is thorough: middleware + provider + token refresh + role enforcement
- Shared components are genuinely reusable and consistently used
- All UX states handled: loading (skeletons), empty, error (with retry), success
- Component sizes are reasonable -- no bloated files
- CORS properly configured for dev/prod split

**Deductions:**
- -1.0: Six N+1 query patterns in backend views/serializers (all fixed, but they existed pre-review)
- -0.5: Pagination UI inconsistency (DataTable vs inline buttons)
- -0.5: Two placeholder pages (Progress tab, Settings) shipped as "Coming soon"

## Recommendation: APPROVE

The architecture is solid. The frontend follows Next.js App Router conventions correctly, the hook/provider pattern is clean, and the TypeScript types are well-aligned with the backend. The N+1 query fixes applied during this review significantly improve backend performance for trainers with many trainees. No redesign or major refactoring needed.

---

## Changes Made by Architect

### Backend (`backend/trainer/views.py`)
- **`TraineeDetailView.get_queryset()`**: Added `.select_related('profile', 'nutrition_goal').prefetch_related('programs', 'activity_summaries')`
- **`TrainerDashboardView.get()`**: Added `.select_related('profile').prefetch_related('daily_logs', 'programs')` to base queryset; replaced Python loop for inactive trainees with `Max` annotation query
- **`TrainerStatsView.get()`**: Replaced Python loop for `pending_onboarding` with single `.filter().count()` query
- **`AdherenceAnalyticsView.get()`**: Replaced per-trainee N+1 loop with `.values().annotate(Case/When)` aggregation; added `days` parameter bounds checking
- **`ProgressAnalyticsView.get()`**: Added `.select_related('profile').prefetch_related('weight_checkins')`; fixed bare `except:` to specific exception
- **`TraineeActivityView.get_queryset()`**: Added `days` parameter bounds checking with clamping to 1-365
- **Imports**: Added `Case`, `IntegerField`, `Max`, `When` to top-level `django.db.models` import

### Backend (`backend/trainer/serializers.py`)
- **`TraineeListSerializer.get_profile_complete()`**: Changed bare `except:` to `except User.profile.RelatedObjectDoesNotExist`
- **`TraineeListSerializer.get_last_activity()`**: Changed from `.order_by('-date').first()` (bypasses prefetch) to Python iteration over prefetched `daily_logs`; return type annotated as `str | None`
- **`TraineeListSerializer.get_current_program()`**: Changed from `.filter(is_active=True).first()` (bypasses prefetch) to Python `next()` over prefetched `programs`
- **`TraineeDetailSerializer.get_profile()`**: Changed bare `except:` to `except User.profile.RelatedObjectDoesNotExist`
- **`TraineeDetailSerializer.get_nutrition_goal()`**: Changed bare `except:` to `except User.nutrition_goal.RelatedObjectDoesNotExist`

### Frontend (`web/src/types/trainer.ts`)
- **`DashboardOverview`**: Added `today: string` field to match backend response
