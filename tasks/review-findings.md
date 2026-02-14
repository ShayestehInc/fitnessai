# Code Review: White-Label Branding Infrastructure

## Review Date
2026-02-14

## Files Reviewed
### Backend
- `backend/trainer/models.py` (TrainerBranding model, _validate_hex_color, HEX_COLOR_REGEX)
- `backend/trainer/serializers.py` (TrainerBrandingSerializer)
- `backend/trainer/views.py` (TrainerBrandingView, TrainerBrandingLogoView)
- `backend/users/views.py` (MyBrandingView)
- `backend/trainer/urls.py` (branding routes)
- `backend/users/urls.py` (my-branding route)
- `backend/trainer/migrations/0004_add_trainer_branding.py`
- `backend/core/permissions.py` (IsTrainee, IsTrainer)

### Mobile
- `mobile/lib/features/settings/data/models/branding_model.dart`
- `mobile/lib/features/settings/data/repositories/branding_repository.dart`
- `mobile/lib/features/settings/presentation/screens/branding_screen.dart`
- `mobile/lib/core/theme/theme_provider.dart` (TrainerBrandingTheme, ThemeNotifier, AppThemeBuilder)
- `mobile/lib/core/constants/api_constants.dart`
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart`
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart`
- `mobile/lib/core/router/app_router.dart`
- `mobile/lib/features/auth/presentation/screens/login_screen.dart` (verified branding fetch gap)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `mobile/lib/features/auth/presentation/screens/login_screen.dart:112-113` | **Branding never fetched on fresh login.** When a trainee logs in, the login screen navigates directly to `/home`, bypassing the splash screen entirely. The branding fetch only happens in `splash_screen.dart._fetchTraineeBranding()`. On a fresh login (not a cold app restart), the trainee will NEVER see their trainer's branding until they kill and restart the app. This violates AC-8: "On trainee login, app fetches branding." | After successful login, before navigating to `/home`, fetch branding for trainee users. Either: (a) call `_fetchTraineeBranding()` logic after login in login_screen.dart, (b) navigate to `/splash` instead of `/home` after login, or (c) add branding fetch to the auth state notifier's login flow. Option (c) is cleanest -- add branding fetch to `auth_repository.dart` or `auth_provider.dart` post-login callback. |
| C2 | `mobile/lib/features/settings/data/models/branding_model.dart:82-96` | **copyWith cannot clear logoUrl to null.** The `copyWith` method uses `logoUrl: logoUrl ?? this.logoUrl`, so passing `null` for logoUrl keeps the old value. After a trainer removes their logo via the DELETE endpoint, any caller doing `model.copyWith(logoUrl: null)` will silently retain the old URL instead of clearing it. The current save flow works around this because `_removeLogo()` updates `_branding` from the full API response, but the model's copyWith is fundamentally broken for nullable fields. | Add a `bool clearLogoUrl = false` parameter to `copyWith` and use: `logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl)`. This mirrors the `clearBranding` pattern already used in `AppThemeState.copyWith`. |
| C3 | `backend/trainer/views.py:1246` | **Silent exception swallowing in logo upload.** `except Exception:` catches ALL exceptions during Pillow image validation, including unexpected errors like memory exhaustion, corrupted files causing segfaults in Pillow, import errors, etc. This silences real errors. Per project rules: "All functions should raise errors if there is an error, NO exception silencing!" | Catch only specific Pillow exceptions: `except (PIL.UnidentifiedImageError, PIL.DecompressionBombError, OSError, ValueError) as e:` and include the error type in the response or log. At minimum, log the exception before returning the 400 response. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `mobile/lib/features/settings/data/repositories/branding_repository.dart` (all methods) | **Repository returns `Map<String, dynamic>` instead of typed result.** Project rules state: "for services and utils, return dataclass or pydantic models, never ever return dict." Every method returns `Map<String, dynamic>` with stringly-typed keys `'success'`, `'error'`, `'branding'`. This is error-prone -- a typo in a key name causes silent failures. | Create a typed result class: `class BrandingResult { final bool success; final BrandingModel? branding; final String? error; const BrandingResult({required this.success, this.branding, this.error}); }` and return that from all repository methods. |
| M2 | `backend/trainer/views.py:1214-1215` | **content_type validation is client-controlled and insufficient for security.** `image.content_type` comes from the HTTP request header, which can be forged. A malicious user could upload a non-image file with a spoofed `image/jpeg` content-type. The Pillow validation at line 1232 partially mitigates this by actually parsing the file, but the content-type alone should not be trusted. | After `PILImage.open(image)` succeeds, validate `pil_image.format` is in `('JPEG', 'PNG', 'WEBP')` to verify actual file content matches claimed type. This is defense-in-depth. |
| M3 | `mobile/lib/features/splash/presentation/screens/splash_screen.dart:192` | **Silent exception swallowing.** `catch (_) { // Silent failure }` violates the project rule "NO exception silencing." Even if branding is non-critical, swallowing ALL exceptions (including programming errors like null reference, type errors, etc.) makes debugging impossible. | Catch specific expected exceptions (e.g., `on DioException` or `on FormatException`) and let unexpected exceptions propagate. If all must be caught for UX reasons, at least log them. |
| M4 | `backend/trainer/views.py:1265` and `1284` | **`branding.save()` without `update_fields` on logo upload/delete.** After setting `branding.logo = image`, `branding.save()` writes ALL fields to the database. If a concurrent request is updating `primary_color` or `app_name`, this full save could overwrite those changes with stale values (race condition). Same issue at line 1284 after logo delete. | Use `branding.save(update_fields=['logo', 'updated_at'])` for both the upload and delete paths. |
| M5 | `mobile/lib/features/settings/presentation/screens/branding_screen.dart` | **Screen is 692 lines -- far exceeds the 150-line convention.** Project convention says "Max 150 lines per widget file -- extract sub-widgets into separate files." This file contains the full screen logic, preview card, app name field, logo section, color picker dialog, color rows, save button, and error state. | Extract into separate files: `branding_preview_card.dart`, `branding_logo_section.dart`, `branding_color_pickers.dart`. Keep `branding_screen.dart` as the orchestrator with state management and the main build method. |
| M6 | `mobile/lib/core/theme/theme_provider.dart:219-226` vs `mobile/lib/features/settings/data/models/branding_model.dart:64-70` | **Two competing branding cache formats.** `TrainerBrandingTheme.toJson()` stores colors as raw ints (`color.value`), while `BrandingModel.toCacheJson()` stores colors as hex strings (`#6366F1`). Both are cached in SharedPreferences under different keys. If the two caching mechanisms ever interact or someone reads one expecting the other's format, colors will be corrupted. | Standardize on one format. Recommend hex strings throughout (consistent with the API). Update `TrainerBrandingTheme.toJson/fromJson` to serialize colors as hex strings and parse them back. |
| M7 | `backend/trainer/views.py:1177-1184` and `1252-1258` | **Duplicate `get_or_create` with hardcoded defaults.** The auto-creation logic with default colors is duplicated in `TrainerBrandingView.get_object()` and `TrainerBrandingLogoView.post()`. If defaults change, both must be updated, and they could diverge. | Extract to a shared method: `TrainerBranding.get_or_create_for_trainer(trainer)` as a classmethod on the model, or a utility function. Both views should call this single method. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `backend/trainer/models.py:307` | **Validator function `_validate_hex_color` uses private naming but is public API via migrations.** The migration at `0004_add_trainer_branding.py:32-33` references `trainer.models._validate_hex_color`. Private-convention functions in migrations are fragile -- renaming or moving them breaks migrations. | Rename to `validate_hex_color` (no underscore prefix). Update model field reference and migration. |
| m2 | `backend/trainer/serializers.py:299-302` | **Redundant `validate_app_name` method.** Checks `len(value) > 50`, but the model's `CharField(max_length=50)` and the `ModelSerializer` already auto-generate a max_length validator from the model field definition. | Remove `validate_app_name` -- the inherited validation from the model field is sufficient. |
| m3 | `backend/trainer/models.py:360-362` | **Redundant index on OneToOneField.** `models.Index(fields=['trainer'])` in Meta.indexes is redundant because Django's OneToOneField automatically creates a unique index on the column. The explicit index adds a second, non-unique index. | Remove the explicit `models.Index(fields=['trainer'])` from the Meta class. The OneToOneField's unique constraint already provides an efficient index. |
| m4 | `mobile/lib/features/settings/presentation/screens/branding_screen.dart:29-30` | **Hardcoded default colors duplicate constants.** `_primaryColor = const Color(0xFF6366F1)` and `_secondaryColor = const Color(0xFF818CF8)` duplicate the same values defined in `BrandingModel.defaultBranding`. | Use `BrandingModel.defaultBranding.primaryColorValue` and `BrandingModel.defaultBranding.secondaryColorValue` instead. |
| m5 | `mobile/lib/core/theme/theme_provider.dart:327` and `339` | **Two instances of silently catching JSON decode errors.** `catch (_) { // Invalid JSON, use default }` and `catch (_) { // Invalid JSON, ignore }` -- per project rules, errors should not be silenced even when falling back to defaults. | Add error logging: `catch (e) { debugPrint('Failed to decode theme preference: $e'); }`. Note: project also says no debug prints. Use a proper logging utility if available, or at minimum convert to `catch (e, st)` so stack traces are available during debugging. |
| m6 | `backend/users/views.py:404-405` | **try/except for single-object lookup could use filter().first() instead.** `TrainerBranding.objects.get(trainer=trainer)` wrapped in try/except DoesNotExist is fine but verbose. | Consider `branding = TrainerBranding.objects.filter(trainer=trainer).first()` with `if branding is None:` check for slightly cleaner code. |
| m7 | `mobile/lib/features/settings/presentation/screens/branding_screen.dart:239` | **`color.withValues(alpha: 0.5)` used throughout.** Verify this is a valid method. Standard Flutter `Color` does not have `withValues()` -- the standard methods are `withOpacity()` or `withAlpha()`. If this is a custom extension, ensure it's well-tested. | Verify `withValues` exists in the codebase as an extension method. If it's the new Flutter 3.27+ API, confirm the project's minimum Flutter version supports it. |

---

## Security Concerns

1. **Content-type spoofing (M2):** The logo upload validates `image.content_type` which is client-controlled. Pillow's `Image.open()` provides real file parsing, but an explicit format check on the parsed image (`pil_image.format in ('JPEG', 'PNG', 'WEBP')`) would be stronger defense-in-depth.

2. **No rate limiting on logo upload:** `TrainerBrandingLogoView.post()` has no throttle. A malicious trainer could repeatedly upload 2MB images to exhaust disk storage. Consider adding Django REST Framework's `UserRateThrottle`.

3. **File deletion before save (race condition):** In `TrainerBrandingLogoView.post()` line 1261-1262, `branding.logo.delete(save=False)` deletes the old logo file before the new `branding.save()` succeeds. If the save fails (DB error), the old file is gone but the DB still references it, leaving a dangling reference. Consider deleting the old file AFTER the save succeeds.

4. **No IDOR vulnerability detected.** TrainerBrandingView uses `get_or_create(trainer=request.user)` -- trainer can only access own branding. MyBrandingView uses `user.parent_trainer` -- trainee sees only their own trainer's branding. Both confirmed secure.

5. **No secrets or credentials in committed code.** Reviewed all new files -- no API keys, tokens, or passwords.

6. **Branding default response leaks no sensitive data.** MyBrandingView returns only color strings and an optional URL.

---

## Performance Concerns

1. **Branding fetch blocks splash screen navigation.** In `splash_screen.dart:143`, `await _fetchTraineeBranding()` blocks before the fade-out animation starts. If the API is slow (cold start, poor network), splash hangs indefinitely beyond the animation time. Add a timeout: `await _fetchTraineeBranding().timeout(const Duration(seconds: 3), onTimeout: () {})`.

2. **No Image caching for logo in Flutter.** `Image.network()` uses Flutter's built-in memory cache, but for a logo that rarely changes, using `CachedNetworkImage` (from `cached_network_image` package) would provide proper disk caching. Not a blocker.

3. **Redundant database index (m3).** The explicit index on `trainer` duplicates the OneToOneField's unique constraint index. Minor wasted storage.

4. **No N+1 queries detected.** Both views access single objects. Acceptable.

---

## Acceptance Criteria Check

| AC | Met? | Notes |
|----|------|-------|
| AC-1: TrainerBranding model | PASS | All required fields present with correct types, constraints, and validators. |
| AC-2: GET /api/trainer/branding/ auto-creates | PASS | Uses get_or_create with default colors. |
| AC-3: PUT /api/trainer/branding/ | PASS | Updates fields, IsTrainer enforced. |
| AC-4: POST /api/trainer/branding/logo/ | PASS | Validates type (JPEG/PNG/WebP), size (2MB), dimensions (128-1024). |
| AC-5: DELETE /api/trainer/branding/logo/ | PASS | Removes file and clears field. |
| AC-6: GET /api/users/my-branding/ | PASS | Returns trainer's branding or defaults. IsTrainee enforced. |
| AC-7: Row-level security | PASS | Trainer owns their branding via OneToOne. Trainee sees only parent_trainer's branding. |
| AC-8: Fetch branding on trainee login | **FAIL** | Only fetched in splash (cold restart), NOT after fresh login. See C1. |
| AC-9: Splash shows trainer logo/name | PASS | _buildLogo() and _buildBrandedText() display trainer branding. |
| AC-10: Trainer colors override theme | PASS | AppThemeBuilder checks hasTrainerBranding first in both dark and light theme builders. |
| AC-11: Branding cached locally | PASS | SharedPreferences via _trainerBrandingKey, loaded on theme init. |
| AC-12: Default fallback | PASS | isCustomized check, clearTrainerBranding(), defaultBranding constant. |
| AC-13: Branding in trainer Settings | PASS | BRANDING section added between APPEARANCE and NOTIFICATIONS. |
| AC-14: Branding screen fields | PASS | App name, color pickers, logo upload/preview all present. |
| AC-15: HSL color picker | PARTIAL | Used 12-preset grid instead of HSL. Acknowledged deviation. Acceptable. |
| AC-16: Logo upload via ImagePicker | PASS | ImagePicker with max 512x512, quality 85. |
| AC-17: Save calls PUT + POST | PASS | _saveBranding() calls PUT; _pickAndUploadLogo() calls POST separately. |
| AC-18: Live preview | PARTIAL | Static preview card that updates reactively. Not full theme preview. Acceptable deviation. |

**Failed: 1 (AC-8 -- branding not fetched on login)**
**Partial: 2 (AC-15, AC-18 -- documented deviations, acceptable)**

---

## Quality Score: 6/10

**Rationale:**
- (+) Solid backend: proper model design, hex validation, image dimension checks, row-level security, clean migration.
- (+) Good mobile UX: loading/error/empty states, preview card, confirmation dialogs, graceful fallbacks.
- (+) Clean architecture: separate endpoints for JSON and multipart, auto-create pattern, proper API constants.
- (-) Critical: AC-8 failure means branding never works on fresh login, only cold restarts.
- (-) Multiple instances of silent exception swallowing, violating an explicit project rule.
- (-) Repository returns untyped Maps, violating the explicit "never return dict" project rule.
- (-) branding_screen.dart is 4.5x the 150-line widget file limit.
- (-) Race condition risk in logo save without update_fields.
- (-) Two competing cache formats for branding data.

---

## Recommendation: REQUEST CHANGES

**Must fix before next review (Critical + High-priority Major):**
1. **C1:** Fetch branding after trainee login (login_screen.dart or auth flow). This is the primary AC-8 failure.
2. **C3:** Stop silently swallowing all exceptions in logo upload Pillow validation. Catch specific exceptions only.
3. **M1:** Repository must return typed results, not `Map<String, dynamic>`.
4. **M3:** Remove silent `catch (_)` in splash screen branding fetch.
5. **M4:** Use `update_fields` on branding.save() in logo upload/delete to prevent race conditions.

**Should fix:**
- C2: Fix copyWith to support clearing logoUrl to null.
- M2: Validate Pillow image format after opening (defense-in-depth).
- M5: Break branding_screen.dart into sub-widget files per the 150-line convention.
- M6: Standardize branding cache format between TrainerBrandingTheme and BrandingModel.
- M7: Extract get_or_create defaults to a single shared method.
