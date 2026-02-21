# Security Audit: Macro Preset Management for Web Trainer Dashboard

## Audit Date
2026-02-21

## Files Audited

### Frontend (new files -- primary audit scope)
- `web/src/types/trainer.ts` -- MacroPreset interface (lines 81-97)
- `web/src/lib/constants.ts` -- URL constants (lines 241-247)
- `web/src/hooks/use-macro-presets.ts` -- Query + mutation hooks
- `web/src/components/trainees/macro-presets-section.tsx` -- Section UI with cards, empty/loading/error states
- `web/src/components/trainees/preset-form-dialog.tsx` -- Create/edit form dialog
- `web/src/components/trainees/copy-preset-dialog.tsx` -- Copy-to-trainee dialog
- `web/src/components/trainees/trainee-overview-tab.tsx` -- Integration point

### Backend (reviewed for IDOR/auth completeness -- no changes in this feature)
- `backend/workouts/views.py` -- MacroPresetViewSet (lines 1173-1416)
- `backend/workouts/serializers.py` -- MacroPresetSerializer, MacroPresetCreateSerializer (lines 207-235)
- `backend/workouts/models.py` -- MacroPreset model (lines 323-371)

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (no new secrets introduced)
- [x] All user input sanitized (React's default escaping, no dangerouslySetInnerHTML)
- [x] Authentication checked on all new endpoints (all API calls via `apiClient` which injects JWT Bearer token)
- [x] Authorization -- correct role/permission guards (backend ViewSet checks `is_trainer()` + `parent_trainer` ownership)
- [x] No IDOR vulnerabilities (backend `get_queryset()` filters by role; explicit ownership checks in update/destroy/copy_to)
- [x] No file uploads in this feature
- [x] Rate limiting -- relies on global DRF throttling (acceptable for authenticated trainer-only endpoints)
- [x] Error messages don't leak internals (frontend uses `getErrorMessage()` which formats DRF field errors; no stack traces exposed)
- [x] CORS policy appropriate (handled globally by Django corsheaders middleware)

## Injection Vulnerabilities

| # | Type | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|
| -- | -- | -- | None found | -- |

**XSS Analysis:**
- No `dangerouslySetInnerHTML` anywhere in the new code.
- All user-supplied strings (`preset.name`, `traineeName`, error messages) are rendered via JSX text interpolation (`{preset.name}`), which React auto-escapes.
- The `title` attributes on elements (e.g., line 235 in `macro-presets-section.tsx`: `title={preset.name}`) are safe from XSS -- HTML attribute values in JSX are escaped by React.
- The dialog description uses `&ldquo;{deleteTarget?.name}&rdquo;` and `&ldquo;{preset.name}&rdquo;` -- properly escaped by React.
- In `preset-form-dialog.tsx` line 187: `` `Update "${preset.name}" for ${traineeName}` `` -- this is rendered inside a `<DialogDescription>` React component, so React's auto-escaping applies.

**SQL Injection:** Not applicable to frontend. Backend uses Django ORM exclusively.

**URL Injection:** URL construction uses typed `number` parameters (`macroPresetDetail(id: number)`, `macroPresetCopyTo(id: number)`). TypeScript enforces the parameter type, preventing URL special character injection. Query parameter `trainee_id=${traineeId}` is also a `number` type.

## Auth & Authz Issues

| # | Severity | Endpoint | Issue | Fix |
|---|----------|----------|-------|-----|
| -- | -- | -- | None found | -- |

**Detailed Auth Analysis:**

1. **All API calls go through `apiClient`** -- Verified by grep. No direct `fetch()` calls in any of the new files. The `apiClient` (in `web/src/lib/api-client.ts`) automatically:
   - Injects `Authorization: Bearer <token>` header on every request
   - Handles 401 with automatic token refresh
   - Redirects to `/login` on auth failure

2. **Backend permission enforcement** -- Every ViewSet method checks:
   - `IsAuthenticated` permission class (line 1180)
   - Explicit `user.is_trainer()` role check in create/update/destroy/copy_to/all_presets
   - `trainee.parent_trainer == user` ownership verification in create/update/destroy/copy_to
   - `get_queryset()` filters by role (trainee sees own, trainer sees own trainees', admin sees all)

3. **No auth bypass vectors** -- The frontend hooks are only used within authenticated trainer dashboard pages (behind route guards). Even if rendered outside an auth context, `apiClient` would throw `ApiError(401)` since `getAccessToken()` would fail.

## IDOR Analysis

**Could a malicious trainer access another trainer's presets?**

No. Defense-in-depth protections at multiple layers:

1. **`get_queryset()` (line 1182-1196):** Trainer role returns `MacroPreset.objects.filter(trainee__parent_trainer=user)`. This means `get_object()` calls in update/destroy/copy_to will 404 for presets belonging to other trainers' trainees.

2. **`list()` (line 1198-1222):** When `trainee_id` is provided, the backend explicitly verifies `User.objects.get(id=trainee_id, role=TRAINEE, parent_trainer=user)`. Another trainer's trainee ID returns 404.

3. **`create()` (line 1224-1269):** Verifies `parent_trainer=user` before creating.

4. **`update()` (line 1271-1296):** Checks `preset.trainee.parent_trainer != user` after `get_object()`.

5. **`destroy()` (line 1298-1317):** Same ownership check.

6. **`copy_to()` (line 1355-1416):** Checks ownership on both source preset AND target trainee.

7. **Frontend isolation:** The `useMacroPresets(traineeId)` hook passes `traineeId` from the trainee detail page, which is already fetched through trainer-scoped endpoints. A trainer can only navigate to their own trainees' detail pages.

## Input Validation Analysis

**Frontend validation (`preset-form-dialog.tsx` lines 92-123):**
- `name`: Required, trimmed, max 100 characters
- `calories`: Required, numeric, range 500-10,000
- `protein`: Required, numeric, range 0-500
- `carbs`: Required, numeric, range 0-1,000
- `fat`: Required, numeric, range 0-500
- `frequency`: Optional select with fixed options (1-7 or empty)
- `is_default`: Boolean checkbox

Values are sanitized before submission (line 131-137): `name.trim()`, `Math.round(Number(...))` for all numeric fields.

**Backend validation:**
- `MacroPresetCreateSerializer` enforces the same ranges on create (lines 227-235)
- Note: The `update()` method (line 1289-1293) uses `setattr` directly from `request.data` without running through the serializer. See Backend Note below.

## Data Exposure Analysis

**API response shape (MacroPresetSerializer):**
The `MacroPreset` response includes `trainee` (ID), `trainee_email`, `created_by` (ID), `created_by_email`. These fields expose:
- Trainee email: Already visible to the trainer in the dashboard
- Created_by email: This is the trainer's own email (or null)
- Integer IDs: These are auto-increment PKs, not a security concern for this use case (trainer already knows their trainee IDs)

No sensitive data is exposed beyond what the trainer already has access to.

**Error message safety:**
The `getErrorMessage()` utility (in `error-utils.ts`) formats DRF field-level errors (e.g., `"calories: Ensure this value is greater than or equal to 500"`) into user-facing messages. It does not expose stack traces, internal paths, or database details. The `SENSITIVE_KEYS` set prevents displaying `detail` or `non_field_errors` keys as labels. This is appropriate.

## Security Issues Found

| # | Severity | Type | File:Line | Issue | Fix |
|---|----------|------|-----------|-------|-----|
| 1 | **Medium** | Missing server-side validation on update | `backend/workouts/views.py:1289-1293` | The `update()` method uses `setattr(preset, field, request.data[field])` for whitelisted fields without serializer validation. While the field whitelist prevents mass-assignment of arbitrary attributes, the **values** are not validated against the same rules as create (500-10000 for calories, etc.). A malicious request could send `{"calories": 50}` or `{"calories": 99999}`. Django's `PositiveIntegerField` prevents negatives, but there's no upper bound enforcement at the model level. The `CharField(max_length=100)` on `name` enforces at DB level but would raise a raw `DataError` instead of a clean validation response. | **Not fixed** (backend change, out of scope for this frontend feature). Recommend using `MacroPresetSerializer` or a dedicated update serializer with validation in the `update()` method. Frontend validation mitigates this for legitimate users. |
| 2 | **Low** | Potential integer overflow via devtools | `web/src/components/trainees/preset-form-dialog.tsx:131-135` | `Math.round(Number(calories))` converts string to number. If a user manipulates the DOM to bypass the `type="number"` and `max` attributes, they could submit a value like `Number("99999999999999999")` which rounds to a large integer. However, the frontend `validate()` function (line 101-103) catches this before submission (`cal > 10000`), and the backend `PositiveIntegerField` has a DB-level constraint. Risk is minimal. | No fix needed -- defense-in-depth already handles this. |
| 3 | **Info** | No CSRF token in API calls | `web/src/lib/api-client.ts` | API calls use JWT Bearer tokens, not session cookies, so CSRF is not applicable. This is correct and safe. | No action needed. |

## Backend Note (Outside Scope)

The `update()` method in `MacroPresetViewSet` (line 1289-1293) should be refactored to use serializer validation, similar to how `create()` uses `MacroPresetCreateSerializer`. This is a pre-existing backend pattern issue, not introduced by this feature. The frontend's client-side validation covers all the same ranges, so legitimate users are protected. The risk is a trainer deliberately crafting API requests to bypass the web UI -- possible but low-impact since they can only modify their own trainees' presets.

## Security Score: 9/10

The implementation is clean and secure. All API calls go through the authenticated `apiClient`. No XSS vectors exist (React auto-escaping, no `dangerouslySetInnerHTML`). IDOR is thoroughly prevented at both frontend routing and backend queryset levels. Input validation on the frontend mirrors backend rules. No secrets are present in any changed files.

The 1-point deduction is for the backend `update()` method's lack of serializer validation -- a pre-existing issue surfaced by this audit, not introduced by this feature, and mitigated by frontend validation.

## Recommendation: PASS
