# Feature: White-Label Branding Infrastructure

## Priority
High — #1 priority per CLAUDE.md. Core value proposition for trainer acquisition.

## User Story
As a **trainer**, I want to customize the app's colors, logo, and name so that my trainees see my brand instead of "FitnessAI."

As a **trainee**, I want to see my trainer's branding throughout the app so it feels like my trainer's personal platform.

## Acceptance Criteria

### Backend
- [ ] AC-1: `TrainerBranding` model with fields: `trainer` (OneToOne → User), `app_name` (CharField, max 50), `primary_color` (CharField, hex format like `#6366F1`), `secondary_color` (CharField, hex), `logo` (ImageField, upload_to='branding/'), `created_at`, `updated_at`
- [ ] AC-2: `GET /api/trainer/branding/` — trainer fetches their own branding config. Auto-creates with defaults if none exists.
- [ ] AC-3: `PUT /api/trainer/branding/` — trainer updates branding fields (app_name, primary_color, secondary_color). Requires IsTrainer permission.
- [ ] AC-4: `POST /api/trainer/branding/logo/` — trainer uploads logo image (JPEG/PNG/WebP, max 2MB, min 128x128, max 1024x1024). Requires IsTrainer.
- [ ] AC-5: `DELETE /api/trainer/branding/logo/` — trainer removes logo. Requires IsTrainer.
- [ ] AC-6: `GET /api/users/my-branding/` — trainee fetches their parent trainer's branding. Returns defaults if no branding configured. Requires IsTrainee.
- [ ] AC-7: Row-level security: trainers can only manage their own branding. Trainees can only see their own trainer's branding.

### Mobile — Trainee Experience
- [ ] AC-8: On trainee login, app fetches branding from `GET /api/users/my-branding/` and applies trainer's colors to the theme.
- [ ] AC-9: Splash screen shows trainer's logo (if set) and app_name (if set) instead of hardcoded "FitnessAI" branding.
- [ ] AC-10: Trainer's primary/secondary colors override the default theme colors throughout the app (buttons, headers, accent colors).
- [ ] AC-11: Branding is cached locally (SharedPreferences) so it persists across app restarts without re-fetching.
- [ ] AC-12: If trainer has no branding configured, trainee sees the default "FitnessAI" theme (graceful fallback).

### Mobile — Trainer Experience
- [ ] AC-13: New "Branding" section in trainer Settings (between Appearance and Notifications).
- [ ] AC-14: Branding screen shows: app name text field, primary color picker, secondary color picker, logo upload/preview.
- [ ] AC-15: Color pickers use the existing `CustomColorPalette` HSL system from `theme_provider.dart`.
- [ ] AC-16: Logo upload uses existing image picker flow (ImagePicker, max 512x512, quality 85).
- [ ] AC-17: Save button calls PUT for colors/name + POST for logo. Success/error SnackBars.
- [ ] AC-18: Live preview: trainer sees their branding changes applied to a mini preview card before saving.

## Edge Cases
1. **Trainer has no branding** → trainee sees default FitnessAI theme (primary: Indigo #6366F1)
2. **Trainer sets branding, then trainee opens app offline** → cached branding from last fetch is used
3. **Trainer changes branding while trainee is using app** → branding updates on next app launch (not mid-session)
4. **Trainer uploads oversized logo** → backend rejects with 400 + clear error message
5. **Trainer uploads non-image file** → backend validates content type, rejects with 400
6. **Invalid hex color format** → backend validates regex `^#[0-9A-Fa-f]{6}$`, rejects with 400
7. **Trainee's trainer is removed** → branding fetch returns defaults (no crash)
8. **Admin impersonating trainer** → sees trainer's branding in branding screen
9. **Very long app_name** → truncated in UI with ellipsis, max 50 chars enforced by backend
10. **Trainer deletes logo then saves** → logo field cleared, trainee sees default icon

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Branding API fails on trainee login | Default theme, no error shown | Falls back to cached branding or defaults |
| Logo upload fails (network) | "Failed to upload logo" SnackBar | Keeps existing logo, no state change |
| Invalid color hex entered | Inline validation "Invalid color" | Prevents save until corrected |
| Logo too large (>2MB) | "Logo must be under 2MB" SnackBar | Backend returns 400, mobile shows error |
| Branding save fails | "Failed to save branding" SnackBar | Reverts to previous state |

## UX Requirements
- **Loading state:** Spinner while fetching branding in trainer screen. Trainee-side: silent fetch, no visible loading.
- **Empty state:** No branding configured → default colors shown with "Customize your brand" CTA.
- **Error state:** Red SnackBar with descriptive message + retry where applicable.
- **Success feedback:** Green SnackBar "Branding updated successfully" on save.
- **Preview:** Mini card showing how the app will look with chosen colors/logo.

## Technical Approach

### Backend (files to create/modify)
- **Create:** `backend/trainer/models.py` — Add `TrainerBranding` model (OneToOne to User)
- **Create:** `backend/trainer/serializers.py` — Add `TrainerBrandingSerializer`
- **Create:** `backend/trainer/views.py` — Add `TrainerBrandingView` (GET/PUT), `TrainerBrandingLogoView` (POST/DELETE)
- **Modify:** `backend/trainer/urls.py` — Add branding endpoints
- **Create:** `backend/users/views.py` — Add `MyBrandingView` (GET for trainee)
- **Modify:** `backend/users/urls.py` — Add my-branding endpoint
- **Create:** `backend/trainer/migrations/0004_add_trainer_branding.py`

### Mobile (files to create/modify)
- **Create:** `mobile/lib/features/settings/data/models/branding_model.dart` — BrandingModel with fromJson/toJson
- **Create:** `mobile/lib/features/settings/data/repositories/branding_repository.dart` — API calls for branding
- **Create:** `mobile/lib/features/settings/presentation/screens/branding_screen.dart` — Trainer branding editor
- **Modify:** `mobile/lib/core/theme/theme_provider.dart` — Add `applyTrainerBranding()` method to ThemeNotifier
- **Modify:** `mobile/lib/core/constants/api_constants.dart` — Add branding endpoint constants
- **Modify:** `mobile/lib/features/splash/presentation/screens/splash_screen.dart` — Dynamic logo/app_name
- **Modify:** `mobile/lib/features/settings/presentation/screens/settings_screen.dart` — Add "Branding" section for trainers
- **Modify:** `mobile/lib/features/auth/data/repositories/auth_repository.dart` — Fetch branding after login

### Key Design Decisions
1. **OneToOne model (not fields on User)** — Keeps User model clean, allows independent migration
2. **Hex string colors (not integer)** — Human-readable, easy to validate, standard web format
3. **Separate logo endpoint** — Multipart upload handled separately from JSON fields
4. **Cached on device** — SharedPreferences for branding, loaded before theme is applied
5. **Trainee fetches from /api/users/my-branding/** — Consistent with existing "my-" pattern (my-layout, my-subscription)
6. **ThemeNotifier.applyTrainerBranding()** — Leverages existing CustomColorPalette HSL math to generate full palette from primary color

## Out of Scope
- Per-page branding (same branding everywhere)
- Custom fonts (only colors and logo)
- Custom app icon (requires native rebuild)
- Tier-gating for branding features (future: only PRO/ENTERPRISE)
- Email template branding
- Push notification branding
