# Security Audit: Progress Photos

## Audit Date
2026-03-09

## Files Audited
- `backend/workouts/views.py` (ProgressPhotoViewSet, lines 1832-1973)
- `backend/workouts/serializers.py` (ProgressPhotoSerializer, lines 513-536)
- `backend/workouts/models.py` (ProgressPhoto model, lines 756-800)
- `backend/workouts/tests/test_progress_photos.py`
- `web/src/hooks/use-progress-photos.ts`
- `web/src/components/progress-photos/upload-dialog.tsx`
- `web/src/components/progress-photos/photo-detail-dialog.tsx`
- `mobile/lib/features/progress_photos/data/repositories/progress_photo_repository.dart`
- All other files in `git diff HEAD~3..HEAD`

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs (test fixtures use `testpass123` / `MockTrainee123!` which is acceptable for test-only code)
- [x] No secrets in git history for these changes
- [x] All user input sanitized (after fix — see below)
- [x] Authentication checked on all new endpoints — `IsAuthenticated` on ViewSet
- [x] Authorization — correct role/permission guards: trainee-only CUD, trainer read-only scoped to own trainees
- [x] No IDOR vulnerabilities — `get_queryset()` filters by `trainee=user` (trainee) or `trainee__parent_trainer=user` (trainer); compare endpoint also uses scoped queryset
- [x] File uploads validated (after fix — see below)
- [ ] Rate limiting on sensitive endpoints — no rate limiting on upload endpoint (Low severity)
- [x] Error messages don't leak internals — generic error strings used
- [x] CORS policy appropriate — no changes to CORS config

## Vulnerabilities Found

| # | Severity | Type | File:Line | Issue | Fix |
|---|----------|------|-----------|-------|-----|
| 1 | **HIGH** | File Upload — No server-side type validation | `serializers.py:513-535` | `ProgressPhotoSerializer` had zero validation on the uploaded `photo` file. Frontend validates JPEG/PNG/WebP and 10MB limit, but this is trivially bypassed. An attacker could upload arbitrary files (SVG with embedded JS, HTML files, executables) by sending a direct API request. Django's `ImageField` checks the file is a valid image via Pillow but does not restrict content types — some image formats (SVG, TIFF) could carry payloads. | **FIXED** — Added `validate_photo()` method that checks `content_type` against allowlist (JPEG, PNG, WebP) and enforces 10MB size limit server-side. |
| 2 | **HIGH** | Injection — No validation on `measurements` JSONField | `serializers.py:522` | The `measurements` field accepted arbitrary JSON without validation. An attacker could store XSS payloads in measurement keys/values (e.g., `{"<script>alert(1)</script>": 0}`), arbitrary large objects consuming storage, or unexpected data types. The frontend renders measurement keys via `MEASUREMENT_LABELS[key] ?? key` — an unrecognized key would be rendered directly. While React escapes HTML in JSX, the arbitrary keys bypass the allowlist intent and could cause UI confusion. | **FIXED** — Added `validate_measurements()` method with allowlisted keys, numeric value validation, range checking (0-500), and max field count (10). |
| 3 | **MEDIUM** | Data Validation — No server-side `notes` length limit | `serializers.py:523` | The `notes` field has a 500-char limit on the web frontend (`maxLength={500}`) but the backend `TextField` has no `max_length`. An attacker could send megabytes of text via direct API call, consuming database storage. | **FIXED** — Added `validate_notes()` method enforcing a 1000-character server-side limit. |
| 4 | **LOW** | Missing Rate Limiting | `views.py:1838` | No rate limiting on the photo upload endpoint. An attacker could flood the server with upload requests, consuming disk space and bandwidth. | **NOT FIXED** — Recommend adding `throttle_classes` (e.g., `UserRateThrottle` with `10/hour` for uploads) in a future pass. Low severity because authentication is required. |
| 5 | **INFO** | Upload Path — Predictable directory structure | `models.py:774` | `upload_to='progress_photos/%Y/%m/'` uses a date-based path. Django appends random suffixes to prevent overwrites, so this is not exploitable, but the directory structure reveals upload timing. | **NOT FIXED** — Acceptable risk. Django handles filename collisions safely. |

## Auth & Authz Assessment

The authorization model is solid:

1. **Trainee isolation**: `get_queryset()` filters by `trainee=user` — trainees can only see/modify their own photos. Verified by test `TraineeIsolationTests`.
2. **Trainer scoping**: Trainers can only read photos where `trainee__parent_trainer=user`. A trainer cannot see another trainer's trainees' photos. Verified by `TrainerCannotSeeOtherTrainerTraineeTests`.
3. **Trainer CUD blocked**: `create()`, `update()`, `destroy()` all explicitly check `user.is_trainee()` and return 403 for trainers. Verified by `TrainerCannotCUDTests`.
4. **Compare endpoint uses scoped queryset**: The `compare` action fetches photos via `self.get_queryset()`, which applies role-based filtering. A user cannot compare photos they don't have access to. Verified by `test_compare_photo_not_belonging_to_user`.
5. **Trainee field auto-set**: `perform_create()` sets `trainee=self.request.user`, preventing a trainee from uploading photos attributed to another user. The `trainee` field is in `read_only_fields`. Verified by `test_create_photo_auto_assigns_trainee`.
6. **Unauthenticated access blocked**: 401 returned. Verified by `UnauthenticatedAccessTests`.

## Frontend Security Notes

- **Web `upload-dialog.tsx`**: Properly validates file type and size client-side (defense-in-depth). Uses `FormData` for multipart upload — no injection risk.
- **Web `photo-detail-dialog.tsx`**: Renders `photo.notes` in a `<p>` tag — React auto-escapes HTML, so XSS via notes is not possible. Measurement values rendered via `{value}` in JSX — also safe due to React escaping. After the backend fix, measurement keys are now restricted to the allowlist, eliminating the stored XSS vector via unknown keys.
- **Mobile**: Uses Dio's `FormData` for uploads — standard pattern, no security concerns. The repository returns typed models, preventing injection.

## Security Score: 8/10

Score justification: The auth/authz model is excellent with comprehensive test coverage. The two HIGH issues (file type validation and measurement injection) have been fixed. Rate limiting is missing but low-risk given authentication requirements. No secrets were leaked.

## Recommendation: CONDITIONAL PASS

Condition: The fixes to `ProgressPhotoSerializer` (file validation, measurement validation, notes length limit) must be included in the final build. With those fixes applied (they are committed), this passes. The remaining rate-limiting concern is low-severity and can be addressed in a future iteration.
