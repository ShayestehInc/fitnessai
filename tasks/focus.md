# Focus: Video Attachments on Community Posts

## Priority
High — Last remaining community media feature. Videos are the most engaging content type.

## Context
Community posts already support multi-image attachments (up to 10 images, 5MB each, JPEG/PNG/WebP).
Video support follows the same patterns: PostVideo model, multipart upload, inline playback, fullscreen viewer.

## Scope
- Backend: PostVideo model, video validation (MP4/MOV/WebM, 50MB, 60s duration), upload handling in views, serializer updates
- Mobile: Video picker integration, upload with progress, inline video player in feed, fullscreen playback, thumbnail generation
- WebSocket: Include video data in real-time post broadcasts

## Success Criteria
- User can attach up to 3 videos per post (alongside images)
- Videos validated server-side (type, size, duration)
- Inline video player in feed with play/pause, muted autoplay disabled
- Tap video for fullscreen with controls
- Video thumbnails shown in feed before playback
- Upload progress indicator during post creation
