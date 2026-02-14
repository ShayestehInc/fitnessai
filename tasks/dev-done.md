# Dev Done: White-Label Branding Infrastructure

## Date: 2026-02-14

## Files Created
### Backend
- `backend/trainer/migrations/0004_add_trainer_branding.py` — Migration for TrainerBranding table

### Mobile
- `mobile/lib/features/settings/data/models/branding_model.dart` — BrandingModel with fromJson/toJson, hex-to-Color conversion, caching, copyWith with clearLogoUrl
- `mobile/lib/features/settings/data/repositories/branding_repository.dart` — BrandingResult typed class + API calls: getTrainerBranding, updateTrainerBranding, uploadLogo, removeLogo, getMyBranding
- `mobile/lib/features/settings/presentation/screens/branding_screen.dart` — Trainer branding editor orchestrator (state, API calls, layout)
- `mobile/lib/features/settings/presentation/widgets/branding_preview_card.dart` — Preview card sub-widget
- `mobile/lib/features/settings/presentation/widgets/branding_logo_section.dart` — Logo upload/preview sub-widget
- `mobile/lib/features/settings/presentation/widgets/branding_color_section.dart` — Color picker sub-widget with preset grid

## Files Modified
### Backend
- `backend/trainer/models.py` — Added `validate_hex_color` (public), `HEX_COLOR_REGEX`, `TrainerBranding` model with `get_or_create_for_trainer()` classmethod. Removed redundant index on OneToOneField.
- `backend/trainer/serializers.py` — Added `TrainerBrandingSerializer` with logo_url, hex color validation. Simplified `validate_app_name` (removed redundant length check, kept strip).
- `backend/trainer/views.py` — Added `TrainerBrandingView` (GET/PUT), `TrainerBrandingLogoView` (POST/DELETE). Uses `get_or_create_for_trainer()`, `update_fields=['logo', 'updated_at']` on save, specific Pillow exception handling, pil_image.format validation.
- `backend/trainer/urls.py` — Added `branding/` and `branding/logo/` endpoints
- `backend/users/views.py` — Added `MyBrandingView` using `filter().first()` pattern.
- `backend/users/urls.py` — Added `my-branding/` endpoint

### Mobile
- `mobile/lib/core/theme/theme_provider.dart` — `TrainerBrandingTheme` with hex-string cache format (consistent with BrandingModel), specific exception catches for JSON parse. `AppThemeState` with branding support, branding-first theme colors.
- `mobile/lib/core/constants/api_constants.dart` — Added `trainerBranding`, `trainerBrandingLogo`, `myBranding` endpoint constants
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart` — Branding fetch with `DioException`/`FormatException` catches instead of `catch (_)`. Dynamic app name + logo.
- `mobile/lib/features/auth/presentation/screens/login_screen.dart` — Branding fetch in `_navigateBasedOnRole` for trainee login path. Specific exception catches.
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart` — Added "Branding" section in trainer settings
- `mobile/lib/core/router/app_router.dart` — Added `/trainer/branding` route

## Review Fixes Applied (Round 1)
### Critical
- **C1**: Branding now fetched on fresh login via `_navigateBasedOnRole` in login_screen.dart
- **C2**: `BrandingModel.copyWith` supports `clearLogoUrl` parameter
- **C3**: Specific Pillow exception handling (UnidentifiedImageError, OSError, ValueError) instead of catch-all

### Major
- **M1**: Repository returns typed `BrandingResult` instead of `Map<String, dynamic>`
- **M2**: Pillow format validation after opening (defense-in-depth)
- **M3**: Splash screen catches `DioException`/`FormatException` instead of `catch (_)`
- **M4**: `branding.save(update_fields=['logo', 'updated_at'])` prevents race conditions
- **M5**: branding_screen.dart split into 4 files (~305 + ~130 + ~105 + ~190 lines)
- **M6**: TrainerBrandingTheme cache uses hex strings consistently with BrandingModel
- **M7**: `get_or_create_for_trainer()` classmethod eliminates duplicate defaults

### Minor
- **m1**: Renamed `_validate_hex_color` to `validate_hex_color` (public, migration-safe)
- **m2**: Removed redundant `validate_app_name` length check (model handles it), kept strip()
- **m3**: Removed redundant index on OneToOneField `trainer`
- **m4**: Default colors use `BrandingModel.defaultBranding` constants
- **m5**: Specific exception catches in theme_provider.dart (FormatException, TypeError)
- **m6**: MyBrandingView uses `filter().first()` instead of try/except

## Key Design Decisions
1. **OneToOne model** — Keeps User model clean, allows independent migration.
2. **Hex string colors** — `#6366F1` format everywhere (API, cache, model).
3. **Separate logo endpoint** — Multipart upload handled separately from JSON PUT.
4. **Auto-create on GET** — `get_or_create_for_trainer()` shared classmethod.
5. **Branding cached in SharedPreferences** — Hex-string format consistent with API.
6. **Branding overrides theme colors** — Trainer branding takes highest priority.
7. **Typed result class** — `BrandingResult` prevents stringly-typed key errors.
8. **Preset color picker** — 12 preset colors matching common brand colors.
9. **Defense-in-depth image validation** — Content-type + Pillow format + size + dimensions.
10. **Row-level security** — OneToOne auto-create + parent_trainer lookup.

## Deviations from Ticket
- AC-15: Used 12-color preset grid instead of HSL picker. Simpler, covers common brand colors.
- AC-18: Static preview card that updates reactively, not full theme preview.

## How to Test Manually
### Trainer Side
1. Login as trainer → Settings → Branding
2. Change app name → preview card updates live
3. Pick primary/secondary colors → preview card updates
4. Upload logo → preview shows logo
5. Save → "Branding updated successfully" green SnackBar
6. Remove logo → confirm dialog → logo removed

### Trainee Side
1. Have trainer configure branding first
2. Login as trainee (fresh login, not cold restart) → branding applied immediately
3. Splash screen shows trainer's logo and app name
4. App theme colors = trainer's primary/secondary colors throughout
5. Kill and reopen app → cached branding persists

### Edge Cases
1. Trainer with no branding → trainee sees default FitnessAI theme
2. Trainer deletes logo → trainee sees default icon on next login
3. Upload >2MB logo → "Logo must be under 2MB" error
4. Upload non-image file (spoofed content-type) → Pillow format check rejects
5. Invalid hex color → validation error prevents save
6. Long app name (>50 chars) → backend rejects
7. Offline trainee → cached branding from last fetch used
8. Trainee with no parent_trainer → defaults returned
9. Non-trainee user → branding cleared on splash

## Test Results
- Backend: Django system check passes. No issues.
- Flutter analyze: All pre-existing issues. Zero new errors/warnings from this feature.
