# Feature: Video Attachments on Community Posts

## Priority
High

## User Story
As a trainee or trainer, I want to attach short videos to community posts so that I can share workout clips, form checks, and progress videos with the community.

## Acceptance Criteria
- [ ] AC1: PostVideo model with file field, thumbnail field, duration, file_size, sort_order, and FK to CommunityPost
- [ ] AC2: Migration creates PostVideo table with indexes on post FK and created_at
- [ ] AC3: Backend validates video uploads: MP4/MOV/WebM only, max 50MB per file, max 60s duration, max 3 videos per post
- [ ] AC4: Video duration extracted server-side using ffprobe (via python-ffmpeg or moviepy) and stored
- [ ] AC5: Thumbnail auto-generated server-side from first frame and stored in thumbnail field
- [ ] AC6: CommunityPostSerializer includes `videos` nested list with id, url, thumbnail_url, duration, sort_order
- [ ] AC7: Post creation view accepts `videos` in multipart form alongside existing `images`
- [ ] AC8: WebSocket `feed_new_post` broadcast includes video data
- [ ] AC9: Mobile video picker allows selecting up to 3 videos from gallery (image_picker or file_picker)
- [ ] AC10: Mobile compose sheet shows video thumbnails with duration badge, delete button, and upload progress bar
- [ ] AC11: Mobile feed renders inline video player (video_player package) with play/pause overlay, no autoplay
- [ ] AC12: Mobile tap-to-fullscreen video with native controls (play, pause, seek, mute, fullscreen exit)

## Edge Cases
1. User selects a video larger than 50MB — client-side validation rejects with toast, never uploads
2. User selects a video longer than 60s — server-side validation rejects with 400 and clear error message; client-side pre-check if possible
3. User selects unsupported format (AVI, FLV) — server-side 400 with format error; client-side filter in picker
4. User mixes images and videos in same post — both should work, images shown in carousel, videos shown below
5. Video upload fails mid-stream (network drop) — post creation fails, user sees error toast, can retry
6. Server-side ffprobe unavailable — graceful degradation: skip duration/thumbnail extraction, store video without metadata, log warning
7. Very large video on slow connection — progress indicator shows upload %, user can see it's working
8. Video file is corrupt or zero-duration — server rejects with 400 "Invalid video file"
9. Post with only videos (no images, no text) — allowed, content can be empty string
10. Concurrent video + image uploads in same post — multipart form handles both file lists

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Video too large (>50MB) | Toast: "Video must be under 50MB" | Client prevents upload |
| Video too long (>60s) | Toast: "Video must be 60 seconds or less" | Server returns 400 |
| Invalid format | Toast: "Unsupported video format. Use MP4, MOV, or WebM" | Server returns 400 |
| Too many videos (>3) | Toast: "Maximum 3 videos per post" | Client prevents selection |
| Upload network failure | Toast: "Failed to upload. Please try again." | Dio error caught |
| ffprobe missing on server | No user impact | Log warning, store video without thumbnail/duration |
| Corrupt video file | Toast: "Could not process video file" | Server returns 400 |

## UX Requirements
- **Compose sheet**: Video picker button next to existing image picker. Selected videos show as thumbnail cards with duration badge (e.g., "0:32") and X to remove. Upload progress bar per video during submission.
- **Feed card**: Videos render below images (if both present). Single video: full-width player. Multiple videos: horizontal scroll or stacked. Play button overlay on thumbnail. Tap to play inline (muted initially), tap again to pause. Long-press or fullscreen button for immersive view.
- **Fullscreen player**: Standard video controls (play/pause, seek bar, time display, mute toggle). Landscape support. Swipe down or X to dismiss.
- **Loading state**: Thumbnail placeholder with spinner while video loads. Shimmer during feed load.
- **Error state**: Broken video icon if video fails to load, with "Tap to retry" text.
- **Empty state**: N/A (videos are optional on posts).

## Technical Approach

### Backend
- **New model**: `PostVideo` in `backend/community/models.py` (mirrors PostImage pattern)
  - Fields: `post` (FK), `file` (FileField), `thumbnail` (ImageField, nullable), `duration` (FloatField, nullable), `file_size` (PositiveIntegerField), `sort_order` (PositiveSmallIntegerField), `created_at`
  - Upload path: `community/posts/videos/{year}/{month:02d}/{uuid}.{ext}`
  - Thumbnail path: `community/posts/thumbnails/{year}/{month:02d}/{uuid}.jpg`
- **New migration**: Add PostVideo table
- **Video processing service**: `backend/community/services/video_service.py`
  - `validate_video(file) -> VideoMetadata` — checks MIME type, file size, extracts duration via subprocess ffprobe
  - `generate_thumbnail(file) -> bytes` — extracts first frame via subprocess ffprobe/ffmpeg
  - Returns dataclass with duration, file_size, is_valid, error_message
- **View changes**: `backend/community/views.py` — extend `CommunityFeedView.post()` to handle `videos` file list
- **Serializer changes**: Add `PostVideoSerializer` and nest in `CommunityPostSerializer`
- **Dependency**: `ffmpeg` must be available in Docker image (add to Dockerfile if missing). No Python package needed — use subprocess.

### Mobile
- **New dependency**: `video_player` package in `pubspec.yaml`
- **Model update**: Add `PostVideoModel` in community models, add `videos` list to `CommunityPostModel`
- **Repository update**: Include videos in multipart form data for post creation
- **New widget**: `VideoPlayerCard` — inline player with play/pause overlay, thumbnail preview
- **New widget**: `FullscreenVideoPlayer` — immersive player with native controls
- **Compose sheet update**: Add video picker button, video preview cards with duration, progress indicator
- **Post card update**: Render videos section below images

### Files to create
- `backend/community/services/video_service.py`
- `backend/community/migrations/NNNN_add_post_video.py` (auto-generated)
- `mobile/lib/features/community/presentation/widgets/video_player_card.dart`
- `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart`
- `mobile/lib/features/community/data/models/post_video_model.dart`

### Files to modify
- `backend/community/models.py` — add PostVideo model
- `backend/community/serializers/` — add PostVideoSerializer, update post serializer
- `backend/community/views.py` — extend post creation for videos
- `mobile/lib/features/community/data/models/community_post_model.dart` — add videos field
- `mobile/lib/features/community/data/repositories/community_feed_repository.dart` — add video upload
- `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart` — video picker + preview
- `mobile/lib/features/community/presentation/widgets/community_post_card.dart` — render videos
- `mobile/pubspec.yaml` — add video_player dependency

## Out of Scope
- Video transcoding / adaptive bitrate streaming (CDN concern for later)
- Video trimming in-app (users trim before selecting)
- Video recording from camera (only gallery pick for now)
- Web dashboard video upload (mobile-only this pipeline)
- Video in direct messages
- Video compression on-device beyond what the OS provides
