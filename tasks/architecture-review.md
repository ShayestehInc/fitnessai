# Architecture Review: White-Label Branding Infrastructure

## Review Date: 2026-02-14

## Architectural Alignment
- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations (`trainer/models.py`)
- [x] No business logic in routers/views -- **FIXED: extracted image validation to `trainer/services/branding_service.py`**
- [x] Consistent with existing patterns (OneToOne model, serializer-based API responses)

## Data Model Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | New `TrainerBranding` table, no existing table modifications |
| Migrations reversible | PASS | Single `CreateModel` migration, can be reversed cleanly |
| Indexes added for new queries | PASS | OneToOneField on `trainer` is auto-indexed by Django. `parent_trainer` FK already indexed for trainee lookups |
| No N+1 query patterns | PASS | `MyBrandingView` does `filter().first()` -- single query. `get_or_create_for_trainer` is single query |

## API Design Assessment
| Concern | Status | Notes |
|---------|--------|-------|
| RESTful endpoint design | PASS | `GET/PUT trainer/branding/` for config, `POST/DELETE trainer/branding/logo/` for file ops |
| Consistent error format | PASS | All errors return `{'error': '...'}` with appropriate HTTP status codes |
| Pagination needed | N/A | Singleton resource, no list endpoints |
| Auth/permission guards | PASS | `IsTrainer` on trainer endpoints, `IsTrainee` on trainee endpoint |
| Row-level security | PASS | Trainer sees own branding via OneToOne. Trainee sees parent_trainer's branding via FK |

## Layering Assessment

### Before Fix
The `TrainerBrandingLogoView.post()` method contained ~50 lines of image validation business logic directly in the view: content-type checking, file size limits, Pillow format verification, dimension bounds checking, and file pointer management. This violated the project convention: **"Business logic in services/ -- Views handle request/response only."**

This was consistent with an existing anti-pattern in `ProgramTemplateUploadImageView` and `UploadProfileImageView`, which also have inline image validation. However, the branding logo validation was the most complex (5 validation steps including Pillow format verification), making it the highest-priority candidate for extraction.

### After Fix
Created `backend/trainer/services/branding_service.py` with:
- `validate_logo_image(image) -> LogoValidationResult` -- pure validation, returns dataclass
- `upload_trainer_logo(trainer, image) -> TrainerBranding` -- validates + saves, raises `LogoValidationError`
- `remove_trainer_logo(trainer) -> TrainerBranding` -- removes logo, raises `DoesNotExist`
- `LogoValidationError` -- typed exception for validation failures
- `LogoValidationResult` -- frozen dataclass for validation results

The view now delegates entirely to the service:
```python
try:
    branding = upload_trainer_logo(trainer, image)
except LogoValidationError as exc:
    return Response({'error': exc.message}, status=status.HTTP_400_BAD_REQUEST)
```

### Frontend Duplication Fix
The branding fetch-and-apply logic was duplicated between `splash_screen.dart` and `login_screen.dart` (15 identical lines each). Extracted to `BrandingRepository.syncTraineeBranding()` static method. Both screens now call the shared method.

## Scalability Concerns
| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Branding fetch | Branding is fetched on every app launch and login | Acceptable -- single query, cached in SharedPreferences. Consider adding `ETag`/`If-Modified-Since` headers if trainer count scales to 10K+ |
| 2 | Logo storage | Logos stored via Django `ImageField` (local filesystem by default) | Move to S3/CloudFront before production scale. Already compatible via `DEFAULT_FILE_STORAGE` setting |
| 3 | Theme rebuild | Trainer branding override triggers full `ThemeData` rebuild | Acceptable -- Flutter rebuilds theme efficiently. No hot path concern |

## Technical Debt Introduced
| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `MyBrandingView` returns raw dict for default case instead of using serializer | Low | **FIXED: consolidated to `_DEFAULT_BRANDING_RESPONSE` class constant. Consistent format.** |
| 2 | `BrandingScreen` uses `setState` for loading/error/saving states | Low | Acceptable for ephemeral form state. Consistent with other screens in codebase. Consider `AsyncNotifier` in future refactor |
| 3 | `TrainerBrandingTheme` in theme_provider.dart duplicates hex-to-Color logic from `BrandingModel` | Low | Both are in the mobile layer but serve different purposes (theme cache vs API model). A shared utility could reduce duplication |
| 4 | `UploadProfileImageView` and `ProgramTemplateUploadImageView` still have inline image validation | Medium | Pre-existing tech debt. The new `branding_service.py` pattern can be extended to cover these in a future pass |
| 5 | `rest_framework_dataclasses` rule in `.claude/rules/datatypes.md` is not practiced anywhere in the codebase | Low | Either install the package and migrate serializers, or update the rule to reflect actual practice |

## Technical Debt Reduced
| # | Description |
|---|-------------|
| 1 | Image validation logic extracted from view to service -- reusable pattern for other upload endpoints |
| 2 | Branding fetch logic deduplicated between splash and login screens |
| 3 | Default branding response consolidated from 2 inline dicts to 1 class constant |
| 4 | Unused `dio` imports removed from splash_screen.dart and login_screen.dart |

## Key Architecture Strengths
1. **Clean OneToOne model** -- Keeps `User` model clean, allows independent migration and query patterns
2. **Separate logo endpoint** -- Multipart upload separated from JSON PATCH/PUT avoids mixed content-type complexity
3. **Lazy creation via `get_or_create_for_trainer()`** -- No migration needed for existing trainers, no null checks required
4. **Trainer branding overrides theme with clear priority** -- `hasTrainerBranding` check in `AppThemeState` is explicit and predictable
5. **SharedPreferences cache for offline resilience** -- Trainee sees branded theme even offline after first fetch
6. **Defense-in-depth image validation** -- Content-type + Pillow format + size + dimensions (4 layers)
7. **Typed result classes** -- `BrandingResult` and `LogoValidationResult` prevent stringly-typed errors

## Files Changed in This Review
### Created
- `backend/trainer/services/__init__.py`
- `backend/trainer/services/branding_service.py` -- extracted image validation + logo operations

### Modified
- `backend/trainer/views.py` -- `TrainerBrandingLogoView` now delegates to branding_service
- `backend/users/views.py` -- `MyBrandingView` uses consolidated `_DEFAULT_BRANDING_RESPONSE`
- `mobile/lib/features/settings/data/repositories/branding_repository.dart` -- added `syncTraineeBranding()` static method
- `mobile/lib/features/splash/presentation/screens/splash_screen.dart` -- uses shared `syncTraineeBranding()`, removed unused `dio` import
- `mobile/lib/features/auth/presentation/screens/login_screen.dart` -- uses shared `syncTraineeBranding()`, removed unused `dio` import

## Verification
- Backend: `python -c "from trainer.services.branding_service import ..."` -- all imports pass
- Backend: `python -c "from trainer.views import TrainerBrandingLogoView"` -- view import passes
- Flutter: `flutter analyze` -- zero new errors/warnings from changes (224 pre-existing issues, none in our modified files)

## Architecture Score: 8.5/10
## Recommendation: APPROVE

### Score Justification
- **+2** Clean data model (OneToOne, lazy creation, proper defaults)
- **+2** Good API design (RESTful, consistent errors, proper auth guards)
- **+1.5** Service extraction brings branding in line with project conventions
- **+1.5** Frontend state management well-structured (Riverpod theme provider, SharedPreferences cache)
- **+1** Proper file upload handling with defense-in-depth validation
- **+0.5** Deduplication of branding sync logic across screens
- **-0.5** BrandingScreen uses setState extensively (minor, consistent with codebase)
- **-0.5** Hex-to-Color conversion duplicated between BrandingModel and TrainerBrandingTheme
- **-0.5** Pre-existing image upload tech debt in other views not addressed (out of scope)
