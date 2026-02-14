# Security Audit: White-Label Branding Infrastructure

## Audit Date: 2026-02-14

## Scope
All files created or modified as part of the White-Label Branding feature:
- `backend/trainer/models.py` (TrainerBranding model, `_branding_logo_upload_path`, `validate_hex_color`)
- `backend/trainer/views.py` (TrainerBrandingView, TrainerBrandingLogoView)
- `backend/trainer/serializers.py` (TrainerBrandingSerializer)
- `backend/trainer/urls.py` (branding/ and branding/logo/ routes)
- `backend/users/views.py` (MyBrandingView)
- `backend/users/urls.py` (my-branding/ route)
- `mobile/lib/features/settings/data/models/branding_model.dart`
- `mobile/lib/features/settings/data/repositories/branding_repository.dart`
- `mobile/lib/features/settings/presentation/screens/branding_screen.dart`
- `mobile/lib/features/settings/presentation/widgets/branding_preview_card.dart`
- `mobile/lib/features/settings/presentation/widgets/branding_logo_section.dart`
- `mobile/lib/features/settings/presentation/widgets/branding_color_section.dart`
- `mobile/lib/core/theme/theme_provider.dart`
- `mobile/lib/core/constants/api_constants.dart`
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart`
- `mobile/lib/features/auth/presentation/screens/login_screen.dart`

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] No secrets in git history (grep'd all new/changed files)
- [x] All user input sanitized (hex color regex + app_name HTML stripping)
- [x] Authentication checked on all new endpoints
- [x] Authorization -- correct role/permission guards
- [x] No IDOR vulnerabilities
- [x] File uploads validated (type, size, dimensions, format, filename)
- [ ] Rate limiting on sensitive endpoints (not implemented -- see Medium issues)
- [x] Error messages don't leak internals (FIXED)
- [x] CORS policy appropriate (pre-existing config, not changed by this feature)

---

## 1. SECRETS

**Result: PASS**

Grepped all new and modified files for API keys, passwords, tokens, secrets, and credentials. No secrets found in:
- Backend Python files (models, views, serializers, urls)
- Mobile Dart files (models, repositories, screens, widgets)
- `tasks/dev-done.md`

All sensitive configuration (OPENAI_API_KEY, STRIPE_SECRET_KEY, etc.) remains properly environment-variable based in `settings.py`.

---

## 2. INJECTION

**Result: PASS (after fixes)**

| # | Type | File:Line | Issue | Status |
|---|------|-----------|-------|--------|
| 1 | SQL Injection | N/A | All queries use Django ORM (`.objects.get()`, `.objects.filter()`, `get_or_create()`). No raw SQL. | PASS |
| 2 | Stored XSS | `backend/trainer/serializers.py:299` | `app_name` field accepted arbitrary text including HTML/script tags. While DRF JSON responses are safe, this value could be rendered in a future web dashboard. | FIXED -- added HTML tag stripping in `validate_app_name()` |
| 3 | Command Injection | N/A | No shell commands or `os.system()` calls. PIL/Pillow used for image processing only. | PASS |
| 4 | Path Traversal | `backend/trainer/models.py:365` | Logo upload used `upload_to='branding/'` which preserves the client-supplied filename. A crafted filename like `../../etc/passwd.png` could theoretically write outside the branding directory. | FIXED -- replaced with `_branding_logo_upload_path()` callable that generates UUID-based filenames |

---

## 3. AUTH & AUTHZ

**Result: PASS**

| # | Endpoint | Method | Auth | Permission | Row-Level Security | Status |
|---|----------|--------|------|------------|-------------------|--------|
| 1 | `/api/trainer/branding/` | GET/PUT/PATCH | IsAuthenticated | IsTrainer | `get_object()` uses `request.user` directly -- trainer can only access their own branding | PASS |
| 2 | `/api/trainer/branding/logo/` | POST/DELETE | IsAuthenticated | IsTrainer | Uses `cast(User, request.user)` -- trainer can only manage their own logo | PASS |
| 3 | `/api/users/my-branding/` | GET | IsAuthenticated | IsTrainee | Uses `user.parent_trainer` FK -- trainee can only see their own trainer's branding | PASS |

**IDOR Analysis:**
- `TrainerBrandingView.get_object()` calls `TrainerBranding.get_or_create_for_trainer(trainer)` where `trainer = cast(User, self.request.user)`. No user-supplied ID -- impossible to access another trainer's branding.
- `TrainerBrandingLogoView` uses `request.user` directly. No user-supplied trainer ID.
- `MyBrandingView` uses `user.parent_trainer` FK. Trainee cannot specify a different trainer ID.
- OneToOneField on `trainer` ensures each trainer has exactly one branding row.

**No IDOR vulnerabilities found.**

---

## 4. DATA EXPOSURE

**Result: PASS**

The `TrainerBrandingSerializer` exposes only:
- `app_name` (non-sensitive)
- `primary_color` (non-sensitive)
- `secondary_color` (non-sensitive)
- `logo_url` (public URL to uploaded image)
- `created_at`, `updated_at` (timestamps, read-only)

Fields NOT exposed:
- `id` (model PK)
- `trainer` (FK, no user ID leak)

The `MyBrandingView` for trainees returns the same fields via the same serializer. Default fallback returns only color constants and null logo_url.

**Error messages reviewed:**
- All error messages are generic and do not leak internal state, file paths, or stack traces.
- FIXED: `OSError`/`ValueError` handler previously echoed exception message (`f'Image processing error: {e}'`) which could reveal internal file system details. Now returns generic message.
- FIXED: `pil_image.format` value was echoed back in error message. Now returns generic message.

---

## 5. FILE UPLOADS

**Result: PASS (after fixes)**

### Validation Chain (Defense in Depth):
1. **Content-Type check**: `image.content_type` must be in `['image/jpeg', 'image/png', 'image/webp']`
2. **File size check**: Max 2MB. FIXED: Previously skipped when `image.size is None` (changed from `is not None and > max_size` to `is None or > max_size`)
3. **PIL format verification**: `pil_image.format` must be in `('JPEG', 'PNG', 'WEBP')` -- prevents spoofed content-type attacks
4. **Dimension validation**: Min 128x128, max 1024x1024
5. **Filename sanitization**: FIXED: Added `_branding_logo_upload_path()` that generates UUID-based filenames, ignoring client-supplied names entirely
6. **Extension whitelist**: Only `.jpg`, `.jpeg`, `.png`, `.webp` extensions allowed in the upload path generator

### Issues Found and Fixed:

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| S5-1 | HIGH | File size bypass: `image.size is not None and image.size > max_size` allowed files with `size=None` to bypass the 2MB limit | Changed to `image.size is None or image.size > max_size` -- unknown-size files are now rejected |
| S5-2 | HIGH | Path traversal via filename: `upload_to='branding/'` preserved client filename. Crafted filenames could write outside intended directory | Added `_branding_logo_upload_path()` callable generating UUID-based names |
| S5-3 | MEDIUM | Error message leaked internal details: `f'Image processing error: {e}'` could reveal filesystem paths from OSError | Changed to generic message |
| S5-4 | LOW | PIL format name leaked: `f'Invalid image format: {pil_image.format}'` echoed back Pillow's format string | Changed to generic message |

### Old logo cleanup:
- Verified: `branding.logo.delete(save=False)` is called before saving new logo -- old files are cleaned up.
- DELETE endpoint also properly removes the file from storage.

---

## 6. CORS/CSRF

**Result: ACCEPTABLE (pre-existing configuration, not changed by this feature)**

- `CORS_ALLOW_ALL_ORIGINS = True` is set in settings. This is acceptable for a mobile-first API during development but should be restricted in production.
- JWT authentication (via `JWTAuthentication`) is stateless and not vulnerable to CSRF attacks.
- All new endpoints use `IsAuthenticated` which requires Bearer token, providing CSRF protection implicitly.

---

## 7. RATE LIMITING

**Result: NOT IMPLEMENTED (Medium priority)**

| # | Severity | Endpoint | Risk | Recommendation |
|---|----------|----------|------|----------------|
| R7-1 | MEDIUM | `POST /api/trainer/branding/logo/` | File upload without rate limiting could be used for storage exhaustion attacks. Each upload triggers PIL processing (CPU-intensive). | Add throttle class: `'upload': '10/hour'` |
| R7-2 | LOW | `PUT /api/trainer/branding/` | Branding update without rate limiting. Low risk since it only writes a few varchar fields. | Consider `'branding': '30/hour'` |

The `REST_FRAMEWORK` config in settings.py has no `DEFAULT_THROTTLE_CLASSES` or `DEFAULT_THROTTLE_RATES`. This is a pre-existing gap not specific to this feature, but the logo upload endpoint is particularly sensitive due to file I/O and image processing costs.

---

## Critical Issues Fixed (by this audit)

| # | Severity | File | Issue | Fix Applied |
|---|----------|------|-------|-------------|
| C1 | HIGH | `backend/trainer/views.py:1217` | File size bypass when `image.size is None` | Changed `is not None and` to `is None or` |
| C2 | HIGH | `backend/trainer/models.py:365` | Path traversal via client-supplied filename in `upload_to` | Added `_branding_logo_upload_path()` with UUID filenames |
| C3 | MEDIUM | `backend/trainer/views.py:1253` | OSError/ValueError exception details leaked to client | Replaced with generic error message |
| C4 | MEDIUM | `backend/trainer/views.py:1230` | PIL format name leaked to client in error | Replaced with generic error message |
| C5 | MEDIUM | `backend/trainer/serializers.py:299` | `app_name` accepted HTML/script tags (stored XSS risk) | Added HTML tag stripping in `validate_app_name()` |

## Minor Observations (No fix needed)

| # | Observation | Notes |
|---|------------|-------|
| O1 | `BrandingModel._hexToColor` in Dart silently falls back to default indigo on invalid hex | Acceptable -- defensive parsing, no security impact |
| O2 | SharedPreferences cache not encrypted | Standard for non-sensitive theme data (colors, app name). Logo URL is public. No PII. |
| O3 | `Image.network()` in Flutter loads logo from absolute URL | URL is server-provided via `request.build_absolute_uri()`. No user-controlled URL injection possible. |
| O4 | No `Content-Security-Policy` headers | Not applicable -- mobile API, not web-served content |

---

## Security Score: 9/10

**Deductions:**
- -0.5: Missing rate limiting on file upload endpoint (pre-existing gap, not specific to this feature)
- -0.5: `CORS_ALLOW_ALL_ORIGINS = True` in production settings (pre-existing, not this feature)

## Recommendation: PASS

All Critical and High issues have been fixed. The branding feature has strong defense-in-depth for file uploads (5-layer validation), proper auth/authz on all endpoints, no IDOR, no data leaks, and no injection vulnerabilities. The remaining Medium items (rate limiting) are pre-existing gaps that should be addressed in a separate infrastructure ticket.
