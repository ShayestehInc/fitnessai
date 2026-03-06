# Ship Decision: Video Attachments on Community Posts

## Verdict: SHIP
## Confidence: HIGH
## Quality Score: 8/10

## Summary
11 of 12 acceptance criteria fully pass; AC10 is partially met (compose video previews show icon+size instead of thumbnail+duration badge, but functionality is complete). The feature is production-ready with robust 3-layer file validation, proper security hardening, clean architecture, and polished mobile UX with accessibility support.

## Acceptance Criteria Verification
- AC1: PostVideo model with file, thumbnail, duration, file_size, sort_order, post FK -- PASS
- AC2: Migration creates table with indexes on (post, sort_order) and created_at -- PASS
- AC3: 3-layer validation (extension + MIME + magic bytes), 50MB limit, 60s duration, max 3 per post -- PASS
- AC4: ffprobe extracts duration via subprocess, stored in PostVideo.duration -- PASS
- AC5: ffmpeg extracts first frame as JPEG thumbnail, stored in PostVideo.thumbnail -- PASS
- AC6: _serialize_posts includes videos list with id, url, thumbnail_url, duration, file_size, sort_order -- PASS
- AC7: CommunityFeedView.post() accepts multipart 'videos' alongside 'images' -- PASS
- AC8: _broadcast_new_post sends full post_data (including videos) via WebSocket -- PASS
- AC9: Mobile video picker with 3-video limit, gallery source, extension + size validation -- PASS
- AC10: Delete button and upload progress bar present; compose previews show icon+file size instead of video thumbnail with duration badge -- PARTIAL (functional, UX gap)
- AC11: VideoPlayerCard with tap-to-play/pause, thumbnail preview, no autoplay, muted start, duration badge -- PASS
- AC12: FullscreenVideoPlayer with play/pause, seek bar, time display, mute toggle, landscape support, close button -- PASS

## Critical/High Issues Resolved
1. Magic bytes validation added (3-layer defense: extension + MIME + magic bytes)
2. Temp file extension uses actual file extension, not hardcoded .mp4
3. ffprobe unavailable: fallback 15MB size cap enforced to limit abuse
4. Post+video creation wrapped in transaction.atomic()
5. MediaUploadThrottle (20/hour) applied to POST requests
6. DATA_UPLOAD_MAX_MEMORY_SIZE and FILE_UPLOAD_MAX_MEMORY_SIZE set in settings
7. Video files and thumbnails deleted from storage on post deletion
8. N+1 query fixed in bookmark service (added post__videos to prefetch)
9. Feed queryset prefetches 'videos' alongside 'images'
10. All 6 accessibility Semantics labels added to video player controls
11. Video starts muted in feed (setVolume(0) before play)
12. Client-side extension validation in compose sheet

## Remaining Concerns
- Compose sheet video previews show generic icon instead of actual video thumbnail (requires video_thumbnail package for client-side extraction; server thumbnails display correctly in feed after posting)
- Synchronous video processing in request cycle (acceptable at current scale; 30s ffprobe timeout limits blast radius; future: Celery for async processing)
- Fullscreen player creates new controller, re-downloading video (bandwidth cost; acceptable for MVP)
- Single video selection per picker tap (image_picker limitation; user taps button multiple times for multiple videos)

## What Was Built
Video attachments on community posts -- full stack implementation:
- Backend: PostVideo model, migration, video_service.py with 3-layer validation + ffprobe/ffmpeg metadata extraction, multipart upload endpoint, WebSocket broadcast, admin registration, rate limiting, file cleanup on delete
- Mobile: PostVideoModel, video upload via multipart FormData with progress callback, VideoPlayerCard (inline player with tap-to-play, muted start, thumbnail, duration badge, error retry), FullscreenVideoPlayer (landscape, seek, mute, auto-hide controls), compose sheet with video picker + previews + progress bar
- Security: Magic bytes validation, upload-specific throttle, fallback size cap without ffprobe, framework upload limits, atomic transactions
- Docker: ffmpeg added to Dockerfile system dependencies
