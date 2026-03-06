# Security Audit: Video Attachments on Community Posts

## Audit Date: 2026-03-05

## Files Reviewed
- `backend/community/services/video_service.py` -- validation logic (magic bytes, size, duration, ffprobe/ffmpeg subprocess)
- `backend/community/views.py` -- upload endpoint (CommunityFeedView.post, CommunityPostDeleteView.delete)
- `backend/community/models.py` -- PostVideo model, upload_to path functions
- `backend/community/serializers/core_serializers.py` -- CreatePostSerializer
- `backend/community/migrations/0007_add_post_video.py`
- `mobile/lib/features/community/data/repositories/community_feed_repository.dart`
- `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart`
- `backend/config/settings.py` -- throttle rates, upload size limits
- `backend/core/throttles.py` -- custom throttle classes

## Checklist
- [x] No secrets, API keys, passwords, or tokens in source code or docs
- [x] All user input sanitized (especially file uploads)
- [x] Authentication checked on video upload endpoint (`IsAuthenticated, IsTrainee`)
- [x] Authorization -- correct role/permission guards (trainee must have `parent_trainer`)
- [x] No IDOR vulnerabilities (feed scoped to `trainer=user.parent_trainer`)
- [x] File uploads validated (type, size, content/magic bytes) -- **3 layers: extension, MIME, magic bytes**
- [x] No path traversal in upload paths (UUID-based paths, extension validated against allowlist)
- [x] Rate limiting on upload endpoint -- **FIXED: added `MediaUploadThrottle` (20/hour)**
- [x] Error messages don't leak internals (all errors are user-facing strings, no tracebacks)
- [x] CORS policy appropriate (no changes to CORS config)

---

## Critical Issues (must fix before merge)

None found.

## High Issues

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 1 | **High** | `backend/community/services/video_service.py:230-236` | **Duration check bypass when ffprobe unavailable.** If `ffprobe` is not installed on the server, `_extract_duration()` returns `None` and the video is accepted regardless of actual duration. An attacker could upload a 10-minute video that passes all other checks. The only guard was a `logger.warning()` call. | **FIXED.** Added `_FALLBACK_MAX_SIZE_NO_FFPROBE = 15 MB` constant. When duration is `None` (ffprobe unavailable), videos above 15 MB are rejected with a clear error message. This limits the blast radius: a 15 MB video at typical mobile bitrates caps out around 30-40 seconds. |
| 2 | **High** | `backend/community/views.py` (CommunityFeedView) | **No upload-specific rate limit.** The endpoint inherited only the global `UserRateThrottle` (120/min). At 50 MB per video, 3 videos per post, an attacker could upload 120 * 150 MB = 18 GB/minute of data, exhausting disk and bandwidth. | **FIXED.** Added `MediaUploadThrottle` (scope: `media_upload`, rate: `20/hour`) applied via `get_throttles()` override on POST only. Also added `DATA_UPLOAD_MAX_MEMORY_SIZE = 60 MB` and `FILE_UPLOAD_MAX_MEMORY_SIZE = 10 MB` to `settings.py` to enforce framework-level upload caps. |
| 3 | **High** | `backend/community/views.py:434-440` | **Video files not deleted on post deletion.** When a post was deleted, image files were cleaned up but video files and thumbnails were left as orphans on storage. Orphaned files remain accessible via their direct URL (if storage serves static files) and consume disk space indefinitely. | **FIXED.** Added a loop to delete `post.videos` file and thumbnail fields before `post.delete()`. |

## Medium Issues

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 4 | **Medium** | `backend/community/views.py:309-313` | **Image validation relies only on client-provided content_type.** Images are validated by `content_type in _ALLOWED_IMAGE_TYPES` which is client-controlled. However, `PostImage.image` is a Django `ImageField` that runs Pillow validation on save, rejecting non-image files. The MIME check is a first-pass filter. | No code fix needed -- Pillow validation provides server-side defense-in-depth. |
| 5 | **Medium** | `backend/community/services/video_service.py:76-100` | **Subprocess calls use list args (safe), but no resource caps on ffprobe.** The subprocess calls use `[arg, ...]` form (no shell=True), preventing command injection. The 30-second timeout is good. However, a crafted video could cause ffprobe to consume excessive memory during parsing. | No code fix -- the 30s timeout mitigates runaway processes. For additional hardening, consider setting `ulimit` or running ffprobe in a sandbox in future. |
| 6 | **Medium** | `backend/community/models.py:384` | **PostVideo.file uses FileField, not a custom validator at model level.** The validation happens in `video_service.py` before save, which is correct. However, if a developer creates a PostVideo via Django admin or shell without calling `validate_video()`, the file goes unsanitized. | Recommend adding a model-level `FileField` validator as defense-in-depth. Low priority since admin access implies trust. |

## Low Issues

| # | Severity | File:Line | Issue | Fix |
|---|----------|-----------|-------|-----|
| 7 | **Low** | `backend/community/views.py:373` | **Thumbnail filename includes original video filename.** `name=f"thumb_{vid_file.name}.jpg"` passes the original name. However, `_post_video_thumbnail_path()` ignores it entirely and generates a UUID path. Safe, but the transient inclusion of user input in an intermediate string is worth noting. | No fix needed. |
| 8 | **Low** | `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart:420` | **Extension validation via string split, not path parsing.** `picked.path.split('.').last` could fail on filenames with no extension (returns the full filename) or multiple dots. However, the server performs authoritative validation, so this is cosmetic. | No fix needed -- server-side validation is the authority. |
| 9 | **Low** | `backend/community/migrations/0007_add_post_video.py:18` | **Migration upload_to differs from model.** Migration uses `'community/posts/videos/%Y/%m/'` (strftime) while model uses a callable with UUID. This is normal Django behavior (migrations snapshot the schema, runtime uses the callable). | No fix needed. |

---

## Detailed Security Analysis

### 1. Secrets Audit

| Location | Finding |
|----------|---------|
| All changed backend files | No API keys, tokens, passwords, or secrets. **PASS** |
| All changed mobile files | No embedded secrets. **PASS** |
| Migration file | No sensitive data. **PASS** |

### 2. File Upload Validation (3 Layers)

| Layer | Check | Bypass Risk | Status |
|-------|-------|-------------|--------|
| **Extension** | `os.path.splitext(filename)[1].lower() in ALLOWED_VIDEO_EXTENSIONS` | Low -- attacker must use `.mp4/.mov/.webm/.m4v` extension | **PASS** |
| **MIME type** | `video_file.content_type in ALLOWED_VIDEO_TYPES` | Medium -- client-controlled, but combined with other checks | **PASS** |
| **Magic bytes** | `_validate_magic_bytes()` checks for `ftyp` box (MP4/MOV) or EBML header (WebM) | Low -- requires valid container header | **PASS** |

A file must pass all three checks to be accepted. An attacker would need to craft a file with a valid video container header, correct extension, and correct MIME type -- which essentially means it's a video file.

### 3. Subprocess Safety (ffprobe/ffmpeg)

| Aspect | Finding |
|--------|---------|
| Shell injection | **SAFE.** Uses list form `['ffprobe', '-v', 'quiet', ...]`, not `shell=True`. User input never enters command arguments -- only the temp file path (system-generated). |
| Path injection | **SAFE.** Temp file path is from `tempfile.NamedTemporaryFile()`. The `suffix` parameter uses the validated extension (`.mp4`, `.mov`, `.webm`). |
| Timeout | **SAFE.** Both ffprobe and ffmpeg have `timeout=30` seconds. |
| Temp file cleanup | **SAFE.** Uses `NamedTemporaryFile(delete=True)` in a `with` block. File is cleaned up even on exceptions. |

### 4. IDOR Analysis

| Endpoint | Scoping | Status |
|----------|---------|--------|
| GET /api/community/feed/ | `CommunityPost.objects.filter(trainer=trainer)` where `trainer = user.parent_trainer` | **PASS** |
| POST /api/community/feed/ | Post created with `trainer=user.parent_trainer` | **PASS** |
| DELETE /api/community/feed/:id/ | Checks `post.author == user` or `post.trainer == user` (trainer) | **PASS** |
| Video URLs in responses | Served via Django's file storage; access depends on storage backend config (S3 signed URLs vs. public). Not within scope of this feature's code. | **NOTE** |

### 5. Video Count Limit Enforcement

| Layer | Limit | Enforcement |
|-------|-------|-------------|
| Backend | `MAX_VIDEOS_PER_POST = 3` | Checked in `CommunityFeedView.post()` before any validation or DB writes | **PASS** |
| Mobile | `_maxVideos = 3` | UI disables video picker when 3 videos selected | **PASS** |
| Mobile | `_maxVideoSizeBytes = 50 MB` | Checked before adding to list | **PASS** |

### 6. Content-Type Headers on Served Videos

Video files are stored via Django's `FileField`. The Content-Type header when serving depends on the storage backend:
- **Local storage (development):** Django's `FileResponse` uses the file extension to determine Content-Type. `.mp4` -> `video/mp4`. Safe.
- **S3/Cloud storage (production):** Content-Type is set at upload time by `django-storages`. Typically inferred from file extension. Safe.

No X-Content-Type-Options header concern for video files since browsers don't execute video MIME types.

---

## Code Fixes Applied

### Fix 1: Duration bypass mitigation
**File:** `backend/community/services/video_service.py`
**Change:** Added `_FALLBACK_MAX_SIZE_NO_FFPROBE = 15 MB`. When ffprobe is unavailable and duration cannot be verified, videos exceeding 15 MB are rejected.

### Fix 2: Upload-specific rate limiting
**Files:** `backend/core/throttles.py`, `backend/community/views.py`, `backend/config/settings.py`
**Changes:**
- Created `MediaUploadThrottle(UserRateThrottle)` with scope `media_upload`
- Applied to `CommunityFeedView` POST requests via `get_throttles()` override
- Added `'media_upload': '20/hour'` to throttle rates
- Added `DATA_UPLOAD_MAX_MEMORY_SIZE = 60 MB` and `FILE_UPLOAD_MAX_MEMORY_SIZE = 10 MB` to settings

### Fix 3: Video file cleanup on post deletion
**File:** `backend/community/views.py`
**Change:** Added loop in `CommunityPostDeleteView.delete()` to delete video files and thumbnails from storage before deleting the post model.

---

## Security Score: 8/10

Deductions:
- -1 for the three High issues found (all now fixed)
- -1 for medium issues (image validation relies on client MIME + Pillow, no model-level video validator)

## Recommendation: PASS

All Critical and High issues have been resolved. The video upload feature implements defense-in-depth with 3-layer file validation (extension + MIME + magic bytes), safe subprocess handling, proper auth/authz scoping, upload-specific rate limiting, and framework-level upload size caps. The remaining medium/low issues are documented with rationale for why they are acceptable.
