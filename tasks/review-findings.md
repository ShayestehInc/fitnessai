# Code Review: Video Attachments on Community Posts

## Review Date: 2026-03-05

## Files Reviewed
- `backend/community/services/video_service.py` (full file, 188 lines)
- `backend/community/migrations/0007_add_post_video.py` (full file, 36 lines)
- `backend/community/models.py` (lines 360-410 -- PostVideo model)
- `backend/community/views.py` (lines 220-390 -- CommunityFeedView, lines 1075-1195 -- _serialize_posts)
- `backend/community/admin.py` (full file, 241 lines)
- `backend/community/serializers/core_serializers.py` (full file, 173 lines)
- `mobile/lib/features/community/data/models/post_video_model.dart` (full file, 38 lines)
- `mobile/lib/features/community/data/models/community_post_model.dart` (full file, 270 lines)
- `mobile/lib/features/community/data/repositories/community_feed_repository.dart` (full file, 193 lines)
- `mobile/lib/features/community/presentation/providers/community_feed_provider.dart` (full file, 295 lines)
- `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart` (full file, 447 lines)
- `mobile/lib/features/community/presentation/widgets/video_player_card.dart` (full file, 242 lines)
- `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart` (full file, 229 lines)
- `mobile/lib/features/community/presentation/widgets/community_post_card.dart` (full file, 475 lines)

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `backend/community/services/video_service.py:121` | **Content-Type trust without verification.** `video_file.content_type` is set by the client HTTP header, not by inspecting the file's actual magic bytes. An attacker can upload any file (executable, HTML with XSS payload, etc.) with `Content-Type: video/mp4` and it will pass validation, be stored on the server, and served to users. This is the #1 file-upload vulnerability (CWE-434). | Validate the actual file content, not just the header. At minimum, read the first 12 bytes and check for known magic bytes (`ftyp` for MP4 at offset 4, `RIFF` for WebM, etc.). Better: rely on the ffprobe duration extraction -- if ffprobe cannot parse it as a video, reject it. Currently, if ffprobe is unavailable, duration is None and validation passes (line 162 only checks `if duration is not None`), so a non-video file sails through. Add: `if duration is None and _ffprobe_available(): return VideoMetadata(is_valid=False, ...)` to reject files ffprobe cannot parse. |
| C2 | `backend/community/services/video_service.py:147` | **Temp file suffix is always `.mp4` regardless of actual format.** A `.mov` or `.webm` file is saved to a temp file with `.mp4` suffix. This can cause ffprobe to misparse the container format, producing incorrect duration or failing silently. More importantly, if the file is actually malicious, the wrong extension may bypass OS-level security checks. | Use the actual file extension: `ext = os.path.splitext(video_file.name or 'video.mp4')[1] or '.mp4'` and pass `suffix=ext` to `NamedTemporaryFile`. |
| C3 | `backend/community/services/video_service.py:55,88` | **Command injection via crafted filenames in subprocess calls.** The `file_path` argument passed to `subprocess.run` comes from `tempfile.NamedTemporaryFile`, which generates safe names. However, the function signatures accept any `str`. If a future caller passes user-controlled input directly (e.g., an in-place file path), shell metacharacters in the path could cause unexpected behavior. The current usage is safe because `NamedTemporaryFile` generates random names, but the functions lack input validation and the API is fragile. | This is low-risk given current usage, but add a guard: `if not os.path.isfile(file_path): raise ValueError(...)`. Also consider adding `shell=False` comment to document the safety assumption (it's already False by default with list args, which is correct). |

---

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `backend/community/services/video_service.py:161-162` | **Duration check is bypassed when ffprobe is unavailable.** If ffprobe is not installed on the server, `duration` is None and the duration check at line 162 (`if duration is not None and duration > MAX_VIDEO_DURATION`) is skipped entirely. This means a 10-minute video will be accepted and stored, consuming storage and bandwidth. The 60-second limit becomes unenforced. | Either (a) require ffprobe and fail validation if it's unavailable: `if duration is None: return VideoMetadata(is_valid=False, error_message='Server cannot validate video duration.')`, or (b) make the behavior configurable with a `REQUIRE_DURATION_CHECK` setting and default to strict. |
| M2 | `backend/community/views.py:316-338` | **Video validation runs synchronously in the request cycle.** Each video is written to a temp file, processed by ffprobe, then processed by ffmpeg for thumbnail extraction. For 3 videos of 50MB each, this means 150MB of disk I/O + 6 subprocess calls (3 ffprobe + 3 ffmpeg) in the request thread. With a 30s timeout per subprocess call, worst case is 180 seconds blocking. This will cause request timeouts and poor UX. | Move video processing to a background task (Celery/Django-Q). Accept the upload, create the post with a `processing` status, return 201 immediately, and process videos asynchronously. Update the post status when processing completes. At minimum, set lower subprocess timeouts (e.g., 10s) and add overall request-level timeout awareness. |
| M3 | `backend/community/views.py:348-379` | **Post creation and video creation are not atomic.** If the post is created successfully (line 348) but a PostVideo creation fails (e.g., disk full, S3 error at line 372), the post exists with partial or no video attachments. The user sees a post with missing videos. | Wrap lines 348-379 in `from django.db import transaction; with transaction.atomic():`. This ensures either everything is created or nothing is. |
| M4 | `mobile/lib/features/community/presentation/widgets/video_player_card.dart:30-55` | **Video player is initialized on first tap but never released when scrolling off-screen.** In a feed with multiple video posts, each tapped video keeps its `VideoPlayerController` alive until the widget is disposed (which only happens when the entire post list is destroyed). Memory and network connections accumulate. | Use `VisibilityDetector` or `WidgetsBindingObserver` to pause and dispose the controller when the card scrolls off-screen. Alternatively, implement a global video controller manager that ensures only one video plays at a time and releases previous controllers. |
| M5 | `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart:30` | **New VideoPlayerController created for fullscreen, re-downloading the video.** When the user taps fullscreen, line 30 creates a brand new `VideoPlayerController.networkUrl` for the same URL, re-downloading the video from scratch. The inline player is paused but not disposed, so two controllers exist simultaneously for the same video. | Pass the existing `VideoPlayerController` from `VideoPlayerCard` to `FullscreenVideoPlayer` instead of creating a new one. This avoids re-downloading and double memory usage. |
| M6 | `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart:381-405` | **No video format or content validation on mobile.** The `_pickVideo` method only checks file size (line 393-394). It does not verify the file is actually a video. The user could pick a non-video file if the gallery picker malfunctions or a file manager is used. The backend will reject it, but the user gets no client-side feedback until after uploading potentially 50MB. | Check the file extension (`.mp4`, `.mov`, `.webm`) before adding to `_videoPaths`. Also consider checking MIME type via `lookupMimeType` from the `mime` package. |
| M7 | `backend/community/views.py:317-321` | **Import inside the request handler.** `from .services.video_service import MAX_VIDEOS_PER_POST, validate_video` is imported inside the `post()` method body. While Python caches imports, this is a code smell and inconsistent with the top-of-file import style used everywhere else in this file. | Move the import to the top of the file with the other imports. |

---

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `backend/community/services/video_service.py:71` | **`import json` inside function body.** This import belongs at the top of the file. | Move `import json` to the module-level imports. |
| m2 | `backend/community/models.py:360-365` | **`_post_video_upload_path` and `_post_video_thumbnail_path` have inconsistent behavior.** The video path preserves the original file extension (line 364), but the thumbnail path hardcodes `.jpg` (line 372). This is fine since thumbnails are always JPEG, but the inconsistency could confuse future developers. | Add a brief comment on line 372 explaining why `.jpg` is hardcoded. |
| m3 | `mobile/lib/features/community/presentation/widgets/video_player_card.dart:97-98` | **Aspect ratio falls back to 16:9 when not initialized, then snaps to actual ratio.** When the video initializes, the aspect ratio can change (e.g., vertical video is 9:16), causing a jarring layout jump. | If the video has duration metadata, consider also sending aspect ratio from the backend, or use `AnimatedContainer` to smooth the transition. |
| m4 | `mobile/lib/features/community/presentation/widgets/community_post_card.dart:63-70` | **`indexOf` inside `map` is O(n^2).** `post.videos.indexOf(video)` inside the map callback scans the list for each element. With max 3 videos this is negligible, but it's an antipattern. | Use `for (int i = 0; i < post.videos.length; i++)` or `.asMap().entries.map()` instead. |
| m5 | `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart:25-29` | **Orientation lock includes landscape but never resets on error.** If `_initialize()` throws (line 43), dispose runs and resets to portrait (line 66-67). But if the user pops via the back button before initialization completes, the orientation change has already been applied. The dispose handler does reset, so this is minor. | No change needed, but add a comment clarifying the orientation lifecycle. |
| m6 | `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart:52` | **Controls timer uses `Future.delayed` which cannot be cancelled.** If the user taps multiple times quickly, multiple delayed futures accumulate, each toggling `_showControls`. | Use a cancellable `Timer` instead: `_controlsTimer?.cancel(); _controlsTimer = Timer(...)`. |
| m7 | `backend/community/migrations/0007_add_post_video.py:18` | **Migration uses `FileField(upload_to='...')` with a static string, but model uses dynamic `_post_video_upload_path`.** The migration's `upload_to` value (`'community/posts/videos/%Y/%m/'`) does not match the model's callable `_post_video_upload_path` (which generates UUID-based names). This is harmless because Django uses the model definition at runtime, not the migration's, but it's confusing. | Update the migration to reference the callable for consistency, or add a comment explaining the discrepancy. |
| m8 | `mobile/lib/features/community/data/models/post_video_model.dart:22` | **`url` field is non-nullable but the server could theoretically return null for a video still being processed.** | If async video processing is ever added (see M2), this will need to be nullable. For now, fine. |

---

## Security Concerns

1. **C1 is a security issue.** Client-controlled Content-Type without server-side magic byte validation means arbitrary file upload. An attacker uploads an HTML file as `video/mp4`, then accesses the stored URL directly. If the storage serves it with `Content-Type: text/html` (or the browser sniffs it), this becomes a stored XSS vector. **Mitigation:** Set `Content-Disposition: attachment` on all video file responses, and validate magic bytes server-side.
2. **No IDOR risk.** Post creation correctly scopes to the user's trainer (views.py:269-274). Video files are attached to the post in the same request, not via a separate endpoint. The feed query (views.py:236) correctly filters by trainer.
3. **No secrets in code.** No API keys, tokens, or passwords found in any changed file.
4. **File size limits enforced.** 50MB per video, 5MB per image, 3 videos max, 10 images max -- all checked server-side.
5. **Subprocess safety.** `subprocess.run` uses list arguments (not `shell=True`), which prevents shell injection. Timeouts are set at 30 seconds.
6. **CSRF protection.** Django REST Framework handles CSRF via JWT auth, no concerns.

## Performance Concerns

1. **M2 (synchronous video processing)** is the biggest performance concern. Three 50MB video uploads processed synchronously in the request cycle will cause timeouts.
2. **M4 (video controller memory)** can cause memory issues on mobile when users scroll through many video posts without disposing controllers.
3. **M5 (double video download for fullscreen)** wastes bandwidth and memory.
4. **Feed query is well-optimized.** `prefetch_related('images', 'videos')` (views.py:238) avoids N+1 queries for video data. Reaction counts and user reactions are batched in `_serialize_posts`. The index on `(post, sort_order)` in the migration supports the ordering.

---

## Quality Score: 6/10

The implementation is well-structured and follows existing codebase patterns closely. The backend model, migration, admin registration, and serialization are clean. The mobile UI is polished with proper loading/error/retry states in the video player. The compose sheet correctly handles video selection with size limits and upload progress. The feed query properly prefetches video data to avoid N+1 queries.

However, there are significant issues:
- **C1 (trusting client Content-Type)** is a real security vulnerability that enables arbitrary file upload.
- **M1 (duration bypass without ffprobe)** means the 60-second limit is silently unenforced in environments without ffprobe.
- **M2 (synchronous processing)** will cause request timeouts with large videos.
- **M3 (non-atomic post+video creation)** can leave orphaned posts without their videos.
- **M4/M5 (mobile memory management)** will degrade performance in feeds with many videos.

The code quality is good -- naming is clear, error handling is present in most places, and the feature is functionally complete. But the security and reliability gaps prevent approval.

## Recommendation: REQUEST CHANGES

**Must fix before re-review:**
- C1 (Content-Type validation bypass -- security vulnerability)
- C2 (wrong temp file extension -- correctness)
- M1 (duration check bypass without ffprobe)
- M3 (non-atomic post+video creation)

**Should fix:**
- M2 (synchronous video processing -- will cause timeouts)
- M4 (video controller memory leak in feed scroll)
- M5 (double video download for fullscreen)
- M6 (no client-side format validation)
- M7 (import inside request handler)
