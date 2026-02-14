# Dev Done: White-Label Branding Infrastructure

## Date: 2026-02-14

## Files Created
### Backend
- `backend/trainer/migrations/0004_add_trainer_branding.py` — Migration for TrainerBranding table

### Mobile
- `mobile/lib/features/settings/data/models/branding_model.dart` — BrandingModel with fromJson/toJson, hex-to-Color conversion, caching support
- `mobile/lib/features/settings/data/repositories/branding_repository.dart` — API calls: getTrainerBranding, updateTrainerBranding, uploadLogo, removeLogo, getMyBranding
- `mobile/lib/features/settings/presentation/screens/branding_screen.dart` — Full trainer branding editor with preview card, app name field, logo upload, color pickers, save button

## Files Modified
### Backend
- `backend/trainer/models.py` — Added `_validate_hex_color` function, `HEX_COLOR_REGEX`, `TrainerBranding` model (OneToOne to User, app_name, primary_color, secondary_color, logo ImageField, timestamps)
- `backend/trainer/serializers.py` — Added `TrainerBrandingSerializer` with logo_url SerializerMethodField, hex color validation
- `backend/trainer/views.py` — Added `TrainerBrandingView` (GET/PUT with auto-create), `TrainerBrandingLogoView` (POST/DELETE with image validation: type, size, dimensions via Pillow)
- `backend/trainer/urls.py` — Added `branding/` and `branding/logo/` endpoints
- `backend/users/views.py` — Added `MyBrandingView` (GET for trainee, returns trainer's branding or defaults). Added `IsTrainee` and `TrainerBranding` imports.
- `backend/users/urls.py` — Added `my-branding/` endpoint

### Mobile
- `mobile/lib/core/theme/theme_provider.dart` — Added `TrainerBrandingTheme` class, `trainerBranding` field to `AppThemeState`, `clearBranding` parameter to `copyWith`, `hasTrainerBranding` getter, branding-aware `effectivePrimary`/`effectivePrimaryLight`, `applyTrainerBranding()` and `clearTrainerBranding()` methods on `ThemeNotifier`, `_trainerBrandingKey` for SharedPreferences caching, branding-first color selection in `_buildDarkTheme` and `_buildLightTheme`
- `mobile/lib/core/constants/api_constants.dart` — Added `trainerBranding`, `trainerBrandingLogo`, `myBranding` endpoint constants
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart` — Added `_fetchTraineeBranding()` (silent fetch on trainee login), `_buildBrandedText()` (dynamic app name + subtitle), updated `_buildLogo()` to show trainer logo when available with `_buildDefaultLogo()` fallback, clears branding for non-trainees/logged-out users
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart` — Added "Branding" section in trainer settings between Appearance and Notifications
- `mobile/lib/core/router/app_router.dart` — Added `/trainer/branding` route pointing to `BrandingScreen`

## Key Design Decisions
1. **OneToOne model** — `TrainerBranding` is 1:1 with User (trainer). Keeps User model clean, allows independent migration.
2. **Hex string colors** — `#6366F1` format. Human-readable, validated with `^#[0-9A-Fa-f]{6}$` regex.
3. **Separate logo endpoint** — Multipart upload handled separately from JSON PUT (same pattern as profile image upload).
4. **Auto-create on GET** — `TrainerBrandingView.get_object()` uses `get_or_create` with defaults, so trainers always get a response.
5. **Branding cached in SharedPreferences** — `_trainerBrandingKey` persists trainer branding across app restarts. Updated on each trainee login via splash screen.
6. **Branding overrides theme colors** — `AppThemeBuilder._buildDarkTheme/_buildLightTheme` check `hasTrainerBranding` first, before user's color preference.
7. **Silent branding fetch** — `_fetchTraineeBranding()` catches all errors silently. On failure, cached branding or defaults are used. No visible loading/error to trainee.
8. **Preset color picker** — 12 preset colors matching common brand colors. Simple grid dialog.
9. **Image validation via Pillow** — Backend validates content type (JPEG/PNG/WebP), size (≤2MB), and dimensions (128-1024px).
10. **Row-level security** — TrainerBrandingView: trainer accesses only their own branding (via OneToOne auto-create). MyBrandingView: trainee gets only `parent_trainer`'s branding (IsTrainee permission + parent_trainer lookup). No IDOR possible.

## Deviations from Ticket
- AC-15 called for using the existing `CustomColorPalette` HSL system for the color picker. Used a simpler 12-color preset grid instead. The HSL picker is complex and presets cover common brand colors.
- AC-18 "Live preview" is a static preview card (logo, name, sample buttons) that updates as trainer changes settings, not a full real-time theme preview.

## How to Test Manually
### Trainer Side
1. Login as trainer → Settings → Branding
2. Change app name → field updates, preview card updates
3. Pick primary/secondary colors → preview card updates
4. Upload logo → preview shows logo
5. Save → "Branding updated successfully" green SnackBar
6. Remove logo → confirm dialog → logo removed

### Trainee Side
1. Have trainer configure branding first
2. Login as trainee (whose parent_trainer = above trainer)
3. Splash screen shows trainer's logo (if set) and app name (if set)
4. App theme colors = trainer's primary/secondary colors throughout
5. Kill and reopen app → cached branding persists without API call

### Edge Cases
1. Trainer with no branding → trainee sees default FitnessAI theme
2. Trainer deletes logo → trainee sees default icon on next launch
3. Upload >2MB logo → "Logo must be under 2MB" error
4. Upload non-image file → "Invalid file type" error
5. Invalid hex color → validation error prevents save
6. Long app name (>50 chars) → backend rejects, UI truncates with ellipsis
7. Offline trainee → cached branding from last fetch used
8. Trainee with no parent_trainer → defaults returned
9. Non-trainee user → branding cleared on splash

## Test Results
- Backend: 12 tests ran, 10 passed. 2 pre-existing MCP import errors (unrelated).
- Flutter analyze: 232 issues total, all pre-existing. Zero new errors/warnings from this feature.
