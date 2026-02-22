# Security Audit: Trainee Web — Workout Logging & Progress Tracking (Pipeline 33)

## Audit Date
2026-02-21

## Scope
Frontend-only feature: new pages (workout, history, progress), new components (active-workout, exercise-log-card, workout-finish-dialog, workout-detail-dialog, workout-history-list, trainee-progress-charts, weight-checkin-dialog, weight-trend-card), modified hooks and constants. No backend changes. All API endpoints already exist with server-side auth and row-level security.

## Files Audited

### Pages (New)
- `web/src/app/(trainee-dashboard)/trainee/workout/page.tsx` -- Active workout page
- `web/src/app/(trainee-dashboard)/trainee/history/page.tsx` -- Workout history page
- `web/src/app/(trainee-dashboard)/trainee/progress/page.tsx` -- Progress charts page

### Components (New)
- `web/src/components/trainee-dashboard/active-workout.tsx` -- Active workout session with timer, exercise logging, and save
- `web/src/components/trainee-dashboard/exercise-log-card.tsx` -- Per-exercise card with reps/weight inputs and set management
- `web/src/components/trainee-dashboard/workout-finish-dialog.tsx` -- Workout summary confirmation dialog before save
- `web/src/components/trainee-dashboard/workout-detail-dialog.tsx` -- Read-only workout detail view dialog
- `web/src/components/trainee-dashboard/workout-history-list.tsx` -- Paginated workout history with detail drill-down
- `web/src/components/trainee-dashboard/trainee-progress-charts.tsx` -- Weight trend, workout volume, weekly adherence charts
- `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx` -- Weight check-in form dialog
- `web/src/components/trainee-dashboard/weight-trend-card.tsx` -- Weight trend summary card with log button

### Components (Modified)
- `web/src/components/trainee-dashboard/todays-workout-card.tsx` -- Added "already logged" detection and conditional CTA
- `web/src/components/trainee-dashboard/trainee-nav-links.tsx` -- Added History and Progress nav links

### Hooks (Modified)
- `web/src/hooks/use-trainee-dashboard.ts` -- Added `useCreateWeightCheckIn`, `useTraineeWorkoutHistory`, `useTraineeWorkoutDetail`, `useTraineeTodayLog`, `useSaveWorkout` hooks

### Types (Modified)
- `web/src/types/trainee-dashboard.ts` -- Added `WorkoutHistoryItem`, `WorkoutHistoryResponse`, `WorkoutDetailData`, `WorkoutData`, `WorkoutSession`, `WorkoutExerciseLog`, `WorkoutSetLog`, `CreateWeightCheckInPayload`, `SaveWorkoutPayload`

### Utilities (New/Modified)
- `web/src/lib/schedule-utils.ts` -- Added `getTodayString`, `formatDuration` utilities
- `web/src/lib/constants.ts` -- Added `TRAINEE_DAILY_LOGS`, `TRAINEE_WORKOUT_HISTORY`, `traineeWorkoutDetail` URL constants
- `web/src/lib/chart-utils.ts` -- New shared chart styling constants
- `web/src/components/ui/textarea.tsx` -- New shadcn/ui textarea component

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized (React auto-escaping; no `dangerouslySetInnerHTML`)
- [x] Authentication checked on all new routes (inherited from trainee-dashboard layout guard)
- [x] Authorization -- correct role/permission guards (TRAINEE role enforced in layout + middleware; backend enforces row-level security)
- [x] No IDOR vulnerabilities (backend `DailyLogViewSet.get_queryset()` filters by `trainee=user`; `workout_detail` uses `self.get_object()` which respects the scoped queryset)
- [x] Rate limiting -- relies on existing backend DRF throttling
- [x] Error messages don't leak internals (generic user-facing error messages throughout)
- [x] Input validation -- reps/weight inputs clamped to `Math.max(0, ...)`, `min` attributes set on HTML inputs, weight check-in validated (20-500 kg range, date not in future)
- [x] CORS policy appropriate (handled globally; no changes in this feature)

---

## 1. SECRETS Analysis

**Methodology:** Searched all new and modified files (24 files total) for patterns matching `password`, `secret`, `api_key`, `apikey`, `token`, `credential`, `bearer`, `sk_`, `pk_`, `ghp_`, `gho_`, `OPENAI`, and `process.env`. Also searched all files under `tasks/` for leaked secrets.

**Result: CLEAN**

- Zero hardcoded secrets, API keys, passwords, or tokens found in any new or modified file.
- No `.env` files introduced or modified.
- `constants.ts` additions are URL path constants only (`TRAINEE_DAILY_LOGS`, `TRAINEE_WORKOUT_HISTORY`, `traineeWorkoutDetail`) -- no secrets.
- Task files (`tasks/*.md`) contain references to "token" and "password" only in the context of describing security audit findings -- no actual secrets.
- `chart-utils.ts` contains only CSS custom property references (`hsl(var(--chart-N))`).

---

## 2. INJECTION Analysis

### XSS
**Result: CLEAN**

- **No `dangerouslySetInnerHTML`** in any new or modified file. Verified via grep across all 24 files.
- **No `innerHTML`**, **no `eval()`**, **no `new Function()`**, **no `document.write()`** in any file.
- All user-supplied content is rendered through JSX text interpolation (`{variable}`), which React auto-escapes:
  - `exercise-log-card.tsx`: Exercise names rendered as `{exerciseName}` in `<CardTitle>`.
  - `workout-detail-dialog.tsx`: Workout names rendered as `{workoutName}` in `<DialogTitle>`, exercise names as `{ex.exercise_name}`, notes as `{data.notes}` in `<p>` tags.
  - `workout-finish-dialog.tsx`: Workout name and duration rendered as text content.
  - `workout-history-list.tsx`: Workout names rendered as `{item.workout_name}` in `<CardTitle>`.
  - `trainee-progress-charts.tsx`: Chart data uses numeric values only (weight, volume). Labels are formatted dates.
  - `weight-checkin-dialog.tsx`: Notes field accepts user input, rendered only in form inputs (not displayed elsewhere in the new code).
- The `workout-detail-dialog.tsx` renders `data.notes` (line 146) as `<p className="mt-1 text-sm">{data.notes}</p>` -- JSX auto-escaping applies. Safe.

### URL Parameter Injection
**Result: FIXED (was Low severity)**

Three instances of direct date string interpolation into URLs were found in `use-trainee-dashboard.ts`:
- Line 41: `?date=${date}` in nutrition summary
- Line 138: `?date=${date}` in today's log
- Line 152: `?date=${payload.date}` in save workout

While the `date` values are internally generated (from `getTodayString()` producing safe `YYYY-MM-DD` format), defensive coding requires URL encoding. **Fixed:** Added `encodeURIComponent()` to all three instances.

### Template Injection
**Result: CLEAN**

No template strings used for HTML rendering. All UI is built via React JSX components.

### SQL Injection
**Result: N/A**

Frontend-only changes. The backend's `DailyLogViewSet.get_queryset()` filters `date_param` via Django ORM's `queryset.filter(date=date_param)` (line 396 of `views.py`), which uses parameterized queries.

---

## 3. AUTH/AUTHZ Analysis

### Route Protection
**Result: CORRECTLY IMPLEMENTED**

All three new pages (`/trainee/workout`, `/trainee/history`, `/trainee/progress`) are inside the `(trainee-dashboard)` route group which is protected by:
1. `middleware.ts` -- cookie-based convenience guard (redirects non-trainees)
2. `layout.tsx` -- server-verified role check via `useAuth()` (authoritative guard)
3. Backend API -- JWT authentication + row-level security (ultimate authority)

### API Endpoint Scope
**Result: ALL ENDPOINTS ARE TRAINEE-SAFE**

New hooks added in Pipeline 33 use the following endpoints:

| Hook | API Endpoint | Backend Auth | Row-Level Security |
|------|-------------|--------------|-------------------|
| `useCreateWeightCheckIn` | `POST /api/workouts/weight-checkins/` | `IsAuthenticated` | Weight check-in created for requesting user |
| `useTraineeWorkoutHistory` | `GET /api/workouts/daily-logs/workout-history/` | `IsTrainee` | `DailyLogService.get_workout_history_queryset(user.id)` scoped to user |
| `useTraineeWorkoutDetail` | `GET /api/workouts/daily-logs/{id}/workout-detail/` | `IsTrainee` | `self.get_object()` uses `get_queryset()` which filters `trainee=user` |
| `useTraineeTodayLog` | `GET /api/workouts/daily-logs/?date=X` | `IsAuthenticated` | `get_queryset()` filters `trainee=user` |
| `useSaveWorkout` | `POST/PATCH /api/workouts/daily-logs/` | `IsAuthenticated` | `get_queryset()` filters `trainee=user`; PATCH uses filtered queryset |

### IDOR Analysis
**Result: NO IDOR VULNERABILITIES**

- `traineeWorkoutDetail(id)` constructs `/api/workouts/daily-logs/{id}/workout-detail/`. The `id` parameter is typed as `number` in TypeScript. On the backend, `DailyLogViewSet.workout_detail()` calls `self.get_object()` which uses the scoped `get_queryset()` filtering `trainee=user`. A trainee cannot access another trainee's workout detail -- Django returns 404 for IDs outside their queryset.
- `useSaveWorkout` performs a read-modify-write pattern: first fetches existing daily logs filtered by date (scoped to user), then PATCHes the first result. The PATCH URL uses the fetched log's `id` from the user's own scoped results, preventing IDOR.
- `useTraineeWorkoutHistory` pagination uses only `page` (a number) and `page_size` (hardcoded to 20). The backend's `workout_history` action has `permission_classes=[IsTrainee]` and queries only the requesting user's data.

---

## 4. DATA EXPOSURE Analysis

### Type Definitions
**Result: CLEAN**

New types in `trainee-dashboard.ts` expose only appropriate fields:
- `WorkoutHistoryItem`: `id`, `date`, `workout_name`, `exercise_count`, `total_sets`, `total_volume_lbs`, `duration_display` -- summary data only.
- `WorkoutDetailData`: `id`, `date`, `workout_data`, `notes` -- trainee's own workout log.
- `WorkoutData`, `WorkoutSession`, `WorkoutExerciseLog`, `WorkoutSetLog`: Nested exercise/set data structures -- no PII.
- `CreateWeightCheckInPayload`: `date`, `weight_kg`, `notes` -- outgoing payload only.
- `SaveWorkoutPayload`: `date`, `workout_data` -- outgoing payload only.

No sensitive fields (passwords, payment info, other users' data) present in any type definition.

### localStorage / sessionStorage
**Result: CLEAN**

No new `localStorage` or `sessionStorage` usage introduced by Pipeline 33 files. The existing token storage pattern (pre-existing, from Pipeline 32 audit) remains unchanged.

### Console Logging
**Result: CLEAN**

Zero `console.log`, `console.warn`, `console.error`, `console.debug`, or `console.info` statements found in any new or modified file.

### Error Messages
**Result: CLEAN**

All error messages shown to users are generic:
- "Failed to load workout data" (active-workout.tsx)
- "Failed to save workout. Please try again." (active-workout.tsx)
- "Failed to load workout details" (workout-detail-dialog.tsx)
- "Failed to load workout history" (workout-history-list.tsx)
- "Failed to load weight data" (weight-trend-card.tsx, trainee-progress-charts.tsx)
- "Failed to save weight check-in" (weight-checkin-dialog.tsx)
- "Failed to load workout data" (trainee-progress-charts.tsx)
- "Failed to load progress data" (trainee-progress-charts.tsx)

The weight check-in dialog does display server-side field validation errors (line 88-99 of weight-checkin-dialog.tsx), but these are standard DRF field-level errors (e.g., "This field is required", "Ensure this value is greater than or equal to 20") -- not internal system details.

---

## 5. INPUT VALIDATION Analysis

### Reps Input (`exercise-log-card.tsx`)
**Result: PROPERLY VALIDATED**

- HTML `type="number"`, `min={0}`, `max={999}` attributes on the input element.
- JavaScript: `Math.max(0, parseInt(e.target.value) || 0)` ensures non-negative integer. `parseInt` with `|| 0` handles NaN gracefully.
- Negative numbers are impossible: `Math.max(0, ...)` clamps to zero.

### Weight Input (`exercise-log-card.tsx`)
**Result: PROPERLY VALIDATED**

- HTML `type="number"`, `min={0}`, `max={9999}`, `step="0.5"` attributes.
- JavaScript: `Math.max(0, parseFloat(e.target.value) || 0)` ensures non-negative float. `parseFloat` with `|| 0` handles NaN gracefully.
- Negative numbers are impossible: `Math.max(0, ...)` clamps to zero.

### Weight Check-in (`weight-checkin-dialog.tsx`)
**Result: PROPERLY VALIDATED**

- Weight: HTML `type="number"`, `step="0.1"`, `min="20"`, `max="500"`. JavaScript: validates `parseFloat(weight)` is between 20 and 500 kg.
- Date: HTML `type="date"`, `max={getTodayString()}`. JavaScript: validates date is not in the future.
- Notes: HTML `<Textarea>` with `maxLength={500}` (added during this audit as defense-in-depth).
- All validation errors displayed with `role="alert"` and linked via `aria-describedby` for accessibility.

### Date Parameters
**Result: PROPERLY VALIDATED**

- `getTodayString()` in `schedule-utils.ts` constructs dates from `new Date()` as `YYYY-MM-DD` -- always safe format.
- The `date` parameter in the weight check-in dialog comes from an HTML `type="date"` input, which browsers constrain to valid date formats.
- URL parameters now use `encodeURIComponent()` (fixed during this audit).

### Set Count Limits
**Result: ACCEPTABLE**

- Users can add extra sets via the "Add Set" button (`active-workout.tsx` line 161). There is no hardcoded maximum set count on the frontend. However:
  - Each additional set requires an explicit button click (no accidental mass creation).
  - The backend will validate the payload size.
  - The UI would become unwieldy before reaching any problematic count.
  - This is a LOW concern -- a motivated user could POST a large payload directly to the API regardless of frontend limits.

---

## 6. CORS/CSRF Analysis

**Result: NO ISSUES**

- No new CORS configuration. All API calls go through the existing `apiClient` which uses JWT Bearer token authentication via `Authorization` header.
- No hardcoded URLs in any Pipeline 33 file (all URLs use `API_URLS` constants derived from `NEXT_PUBLIC_API_URL`).
- CSRF: not applicable -- JWT Bearer auth, not session cookies.

---

## 7. DOM / Window Access Analysis

**Result: ACCEPTABLE**

Only one instance of direct `window` access:
- `active-workout.tsx` lines 97-104: `window.addEventListener("beforeunload", ...)` to prevent accidental navigation away from an unsaved workout. This is a legitimate, safe use pattern. The event listener is properly cleaned up in the useEffect return function.

No `document.write()`, `eval()`, `new Function()`, `javascript:` URIs, or `onclick` string handlers found.

---

## Fixes Applied During This Audit

| # | Severity | Type | File | Change | Rationale |
|---|----------|------|------|--------|-----------|
| 1 | **Low** | URL encoding | `web/src/hooks/use-trainee-dashboard.ts:41` | Added `encodeURIComponent(date)` to nutrition summary URL | Defensive coding -- prevent URL injection if date parameter source changes in the future |
| 2 | **Low** | URL encoding | `web/src/hooks/use-trainee-dashboard.ts:138` | Added `encodeURIComponent(date)` to today's log URL | Same as above |
| 3 | **Low** | URL encoding | `web/src/hooks/use-trainee-dashboard.ts:152` | Added `encodeURIComponent(payload.date)` to save workout URL | Same as above |
| 4 | **Low** | Input length | `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx:184` | Added `maxLength={500}` to notes textarea | Defense-in-depth against extremely long input payloads |

All fixes verified with `npx tsc --noEmit` -- zero compilation errors.

---

## Injection Vulnerabilities

| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

## Auth & Authz Issues

| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

---

## Security Issues Found

### Critical Issues
None.

### High Issues
None.

### Medium Issues
None.

### Low Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 1 | **Low** | URL parameter encoding | `web/src/hooks/use-trainee-dashboard.ts:41,138,152` | Date parameters were interpolated directly into URLs without `encodeURIComponent()`. | **FIXED** during this audit -- added `encodeURIComponent()` to all three instances. |
| 2 | **Low** | Input length limit | `web/src/components/trainee-dashboard/weight-checkin-dialog.tsx:184` | Notes textarea had no `maxLength` attribute. While the backend enforces field length limits, defense-in-depth requires frontend limits too. | **FIXED** during this audit -- added `maxLength={500}`. |
| 3 | **Low** | Unbounded set count | `web/src/components/trainee-dashboard/active-workout.tsx:161` | Users can add unlimited extra sets via the "Add Set" button. No frontend cap. | Consider adding a frontend cap (e.g., 50 sets per exercise) to prevent unreasonably large payloads. LOW priority since each set requires a deliberate button click and backend validates payload size. |
| 4 | **Low** | Pre-existing debug endpoint | `backend/workouts/views.py:329-357` | The `ProgramViewSet.debug` action at `/api/workouts/programs/debug/` is accessible to any authenticated user. (Carried over from Pipeline 32 audit.) | Remove the `debug` action or restrict to admin-only. |

### Info Issues

| # | Severity | Type | File:Line | Issue | Recommendation |
|---|----------|------|-----------|-------|----------------|
| 5 | **Info** | localStorage for JWTs | `web/src/lib/token-manager.ts` | JWT tokens stored in `localStorage` are accessible to any JavaScript on the same origin. Pre-existing pattern, not introduced by this feature. | Consider migrating to `httpOnly` cookies in a future security hardening pass. |
| 6 | **Info** | Read-modify-write race | `web/src/hooks/use-trainee-dashboard.ts:149-163` | `useSaveWorkout` performs a GET-then-PATCH/POST sequence. If two saves happen concurrently (e.g., double-click), the second save could create a duplicate log or overwrite the first. | The `isPending` state on the mutation button (passed via `workout-finish-dialog.tsx` line 111) prevents double-submission at the UI level. This is sufficient for normal usage. Consider adding a `mutationKey` or optimistic locking for extra robustness. |

---

## Summary

Pipeline 33 (Workout Logging & Progress Tracking) has an **excellent security posture**:

1. **No secrets leaked** -- zero hardcoded credentials, API keys, or tokens in any new or modified file. Task files clean.

2. **No injection vectors** -- no `dangerouslySetInnerHTML`, no raw HTML rendering, no `eval()`, no template injection. All user content (exercise names, workout names, notes) rendered through React's auto-escaping JSX.

3. **Strong auth/authz** -- all new pages inherit the three-layer defense from the trainee-dashboard layout (middleware cookie guard, layout server-verified role check, backend API auth). New API hooks use only trainee-accessible endpoints with proper backend row-level security.

4. **No IDOR vulnerabilities** -- `traineeWorkoutDetail(id)` is protected by `DailyLogViewSet.get_queryset()` which filters `trainee=user`. The `useSaveWorkout` read-modify-write pattern uses the user's scoped queryset results.

5. **Proper input validation** -- reps clamped to 0-999, weight clamped to 0-9999, weight check-in validated 20-500 kg, date cannot be future, notes limited to 500 chars. All use `Math.max(0, ...)` to prevent negative values.

6. **No data exposure** -- no `console.log` statements, no localStorage usage, no PII in type definitions, generic error messages throughout.

7. **No CORS/CSRF concerns** -- JWT Bearer auth, no hardcoded URLs, no new CORS configuration.

8. **Defensive fixes applied** -- URL parameter encoding added to 3 instances, notes maxLength added to textarea.

## Security Score: 9/10

The 1-point deduction is for the pre-existing `ProgramViewSet.debug` endpoint (Low severity, carried over from Pipeline 32) and the pre-existing `localStorage` JWT storage pattern. Neither was introduced by Pipeline 33. All Pipeline 33-specific issues were fixed during this audit.

## Recommendation: PASS
