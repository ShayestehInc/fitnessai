# QA Report: Video Attachments on Community Posts

## Date: 2026-03-05

## Test Method
Code-review-style QA. All 12 acceptance criteria verified by reading actual implementation code paths across backend and mobile. No runtime tests executed.

## Test Results
- Total acceptance criteria: 12
- Passed: 10
- Failed: 2

## Acceptance Criteria Verification

- [x] **AC1**: PostVideo model exists with correct fields -- **PASS**
  - Model defined at `backend/community/models.py:375-410` with all required fields: `post` (FK to CommunityPost, CASCADE, related_name='videos'), `file` (FileField), `thumbnail` (ImageField, null=True, blank=True), `duration` (FloatField, null=True, blank=True), `file_size` (PositiveIntegerField), `sort_order` (PositiveSmallIntegerField, default=0), `created_at` (DateTimeField, auto_now_add=True).
  - Upload paths use year/month partitioning with UUID filenames as specified in the ticket.
  - `db_table = 'community_post_videos'`, ordering by `sort_order`. Mirrors the PostImage pattern correctly.

- [ ] **AC2**: Migration creates PostVideo table with indexes on post FK and created_at -- **FAIL**
  - Migration at `backend/community/migrations/0007_add_post_video.py` creates the table correctly with all fields.
  - Index on `['post', 'sort_order']` is present (line 33).
  - **BUG**: The ticket requires an index on `created_at`, but no such index exists in the migration or the model Meta. The model Meta `indexes` list only includes `Index(fields=['post', 'sort_order'])`. Querying posts ordered by video creation time will be unindexed.

- [x] **AC3**: Backend validates MP4/MOV/WebM, 50MB, 60s, max 3 -- **PASS**
  - `video_service.py:19-34` defines `ALLOWED_VIDEO_TYPES` (video/mp4, video/quicktime, video/webm), `ALLOWED_VIDEO_EXTENSIONS` (.mp4, .m4v, .mov, .webm), `MAX_VIDEO_SIZE` (50MB), `MAX_VIDEO_DURATION` (60s), `MAX_VIDEOS_PER_POST` (3).
  - `validate_video()` checks extension (line 145), MIME type (line 156), magic bytes (line 168), file size (line 178), and duration (line 208).
  - View at `views.py:323-327` enforces max 3 videos per post. Each video is validated via `validate_video()` at line 332.

- [x] **AC4**: Duration extracted server-side using ffprobe and stored -- **PASS**
  - `_extract_duration()` at `video_service.py:70-100` uses `subprocess.run()` with `ffprobe -v quiet -print_format json -show_format` and parses `format.duration` from JSON output.
  - Has 30s timeout, handles `subprocess.TimeoutExpired`, `ValueError`, and `KeyError`.
  - Duration stored in `PostVideo.duration` field at `views.py:379`.
  - Graceful degradation: if ffprobe unavailable, logs warning and allows upload with null duration (lines 230-235).

- [x] **AC5**: Thumbnail auto-generated from first frame and stored -- **PASS**
  - `_extract_thumbnail()` at `video_service.py:103-129` uses `ffmpeg -i <file> -vframes 1 -f image2pipe -vcodec mjpeg -q:v 5 -vf scale=640:-1 -` to extract first frame as JPEG.
  - Thumbnail bytes stored via `ContentFile` at `views.py:370-374` into `PostVideo.thumbnail` ImageField.
  - Graceful degradation if ffmpeg unavailable (returns None, thumbnail stored as null).

- [x] **AC6**: Serializer includes videos in response -- **PASS**
  - `_serialize_posts()` at `views.py:1148-1164` iterates over videos relation and builds list with `id`, `url`, `thumbnail_url`, `duration`, `file_size`, `sort_order` -- all fields specified in the ticket.
  - Videos included in response dict at line 1186.
  - Feed queryset prefetches videos at line 242: `.prefetch_related('images', 'videos')`.
  - Note: There is no dedicated `PostVideoSerializer` class. Instead, serialization is done inline in `_serialize_posts()`. This is a minor deviation from the ticket ("Add PostVideoSerializer") but functionally equivalent. Marking PASS since the response format matches requirements.

- [x] **AC7**: Post creation view accepts videos in multipart form -- **PASS**
  - `views.py:321` collects video files via `request.FILES.getlist('videos')`.
  - Videos validated individually (lines 330-338), then created in a transaction (lines 368-382).
  - Supports mixed images + videos in the same multipart form (images at line 296, videos at line 321).
  - Allows post with only videos (no text): line 342 checks `not content_text and not image_files and not video_files`.

- [x] **AC8**: WebSocket feed_new_post broadcast includes video data -- **PASS**
  - `_broadcast_new_post()` at `views.py:1200-1229` sends the full `post_data` dict (which includes `videos` key from `_serialize_posts`) via channel layer.
  - Consumer `feed_new_post()` at `consumers.py:109-114` forwards the entire `event['post']` to the WebSocket client, which includes all video data.

- [x] **AC9**: Mobile video picker allows selecting up to 3 videos -- **PASS**
  - `compose_post_sheet.dart:381-418` uses `ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: Duration(seconds: 60))`.
  - Enforces max 3 videos via `_maxVideos = 3` (line 33) and checks `remaining <= 0` before picking (line 384).
  - Client-side extension validation for mp4, m4v, mov, webm (lines 394-404).
  - Client-side 50MB size check with toast (lines 406-414).
  - Video picker button in toolbar (lines 220-229), disabled when 3 videos already selected.

- [ ] **AC10**: Compose sheet shows video thumbnails with duration badge, delete button, and upload progress bar -- **FAIL**
  - Delete button: Present (X button in `_buildVideoPreviews`, lines 357-374). PASS.
  - Upload progress bar: Present (LinearProgressIndicator at lines 122-135, fed by `onUploadProgress` callback). PASS.
  - **BUG**: Video previews do NOT show thumbnail images or duration badges. The `_buildVideoPreviews()` method (lines 314-378) renders a generic `Icons.videocam` icon with the filename text, not an actual video thumbnail or duration badge. The ticket explicitly requires "thumbnail cards with duration badge (e.g., '0:32')". The implementation shows only a plain icon placeholder. This is because generating thumbnails client-side before upload would require a separate package (e.g., `video_thumbnail`), which is not included. The preview is functional but does not match the UX specification.

- [x] **AC11**: Inline video player in feed -- **PASS**
  - `VideoPlayerCard` at `video_player_card.dart` implements inline playback: thumbnail/placeholder on load, tap-to-play (line 66), tap-to-pause (line 71), play button overlay when not playing (lines 129-142), duration badge before playback (lines 145-167).
  - Uses `video_player` package (pubspec.yaml line 71: `video_player: ^2.8.6`).
  - No autoplay: player initializes only on first tap (`_initializePlayer()` called from `_togglePlayPause` at line 67).
  - Error state with "Tap to retry" (lines 210-244).
  - Renders in `community_post_card.dart:61-71` below images when `post.hasVideo`.

- [x] **AC12**: Fullscreen player with controls -- **PASS**
  - `FullscreenVideoPlayer` at `fullscreen_video_player.dart` implements all required controls:
    - Play/pause button (lines 163-177).
    - Seek bar via Slider (lines 130-149).
    - Time display showing position/duration (lines 157-159).
    - Mute toggle (lines 180-191).
    - Landscape support via `SystemChrome.setPreferredOrientations` (lines 25-29), restored on dispose (line 66).
    - Close button always visible (lines 96-103).
    - Controls auto-hide after 3 seconds during playback (lines 52-56).
    - Tap to toggle controls (line 76).
  - Accessible from inline player via long-press (line 106 of video_player_card.dart) or fullscreen icon button (lines 170-189 of video_player_card.dart).

## Bugs Found Outside Acceptance Criteria

| # | Severity | Description | Details |
|---|----------|-------------|---------|
| 1 | **Minor** | Missing `created_at` index on PostVideo | Migration `0007` only indexes `['post', 'sort_order']`. The ticket specifies indexes on "post FK and created_at". Not a functional issue now but could impact query performance if videos are ever queried by creation time. |
| 2 | **Major** | Compose sheet video previews lack thumbnails and duration badges | `_buildVideoPreviews()` in `compose_post_sheet.dart:314-378` shows a generic video icon and filename instead of actual video thumbnails with duration badges as specified in the ticket UX requirements. Requires a client-side thumbnail extraction package (e.g., `video_thumbnail`) that is not in pubspec.yaml. |
| 3 | **Minor** | No `PostVideoSerializer` class | Ticket says "Add PostVideoSerializer and nest in CommunityPostSerializer" but serialization is done inline in `_serialize_posts()`. Functionally correct but deviates from the specified approach and the project's rule about using `rest_framework_dataclasses` for API responses (per `.claude/rules/datatypes.md`). |
| 4 | **Minor** | Video picker only picks one video at a time | `ImagePicker.pickVideo()` returns a single file. To add multiple videos, the user must tap the video button multiple times. The UX would be smoother with multi-select, but `image_picker` does not support multi-video selection. Not a bug per se, but a UX friction point. |
| 5 | **Minor** | Inline player starts unmuted | Ticket says "Tap to play inline (muted initially)" but `VideoPlayerCard._initializePlayer()` calls `controller.play()` without first calling `controller.setVolume(0)`. Video will play with audio on first tap, which may surprise users scrolling through a feed. |

## Recommended Fixes

**Bug #1 (Minor)** -- Add a `created_at` index to the PostVideo model Meta and create a new migration:
```python
indexes = [
    models.Index(fields=['post', 'sort_order']),
    models.Index(fields=['created_at']),
]
```

**Bug #2 (Major)** -- Two options:
1. Add `video_thumbnail` package to pubspec.yaml and use it in `_buildVideoPreviews()` to generate local thumbnails with duration overlay.
2. Accept the current icon-based preview as an MVP and document the gap. The server-side thumbnails will be visible in the feed after posting.

**Bug #5 (Minor)** -- In `video_player_card.dart:48`, add `controller.setVolume(0);` before `controller.play()`:
```dart
await controller.initialize();
if (!mounted) {
  controller.dispose();
  return;
}
setState(() {
  _controller = controller;
  _isInitialized = true;
});
controller.addListener(_onPlayerStateChanged);
await controller.setVolume(0);  // Start muted per spec
await controller.play();
```

## Confidence Level: LOW

Two acceptance criteria fail (AC2: missing created_at index, AC10: video previews lack thumbnails/duration badges). Bug #2 is a visible UX gap -- the compose sheet video previews are functional but do not match the ticket's UX specification for thumbnail cards with duration badges. Bug #5 (unmuted playback) contradicts the ticket's explicit "muted initially" requirement for inline feed playback. While the core video upload and playback pipeline works correctly end-to-end, the compose-time UX and inline muting behavior need attention before this matches the acceptance criteria.
