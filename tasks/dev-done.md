# Dev Done: Video Attachments on Community Posts

## Files Created
- `backend/community/services/video_service.py` — Video validation + metadata extraction service (ffprobe/ffmpeg)
- `backend/community/migrations/0007_add_post_video.py` — PostVideo table migration
- `mobile/lib/features/community/data/models/post_video_model.dart` — PostVideoModel with formattedDuration
- `mobile/lib/features/community/presentation/widgets/video_player_card.dart` — Inline video player card
- `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart` — Immersive fullscreen player

## Files Modified
- `backend/community/models.py` — Added PostVideo model with file, thumbnail, duration, file_size, sort_order
- `backend/community/views.py` — Extended CommunityFeedView.post() for video upload, _serialize_posts for video output, prefetch_related('videos')
- `backend/community/serializers/core_serializers.py` — CreatePostSerializer allows blank content (media-only posts)
- `backend/community/admin.py` — PostVideo admin + inline on CommunityPost
- `backend/Dockerfile` — Added ffmpeg to system dependencies
- `mobile/lib/features/community/data/models/community_post_model.dart` — Added videos field, hasVideo getter
- `mobile/lib/features/community/data/repositories/community_feed_repository.dart` — Video upload via multipart, onUploadProgress callback
- `mobile/lib/features/community/presentation/providers/community_feed_provider.dart` — Pass videoPaths + progress callback
- `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart` — Video picker, previews, upload progress bar
- `mobile/lib/features/community/presentation/widgets/community_post_card.dart` — Render VideoPlayerCard for videos

## Key Decisions
1. Used subprocess ffprobe/ffmpeg for video metadata (no Python package dependency). Graceful degradation if unavailable.
2. Videos stored as FileField (not ImageField) with separate thumbnail ImageField.
3. Max 3 videos per post, 50MB each, 60s max duration. Server validates all three constraints.
4. Client-side pre-validation: file size check before upload, maxDuration on picker.
5. Inline player: tap to play/pause, no autoplay. Fullscreen on long-press or icon tap.
6. Upload progress: Dio's onSendProgress piped through provider to compose sheet's LinearProgressIndicator.
7. Media-only posts allowed (content can be empty if images or videos attached).

## How to Test
1. Create a post with video: compose → tap "Video" chip → pick from gallery → post
2. Verify video appears in feed with thumbnail and duration badge
3. Tap video to play inline, tap again to pause
4. Long-press or tap fullscreen icon for immersive player
5. Test video > 50MB rejected client-side
6. Test video > 60s rejected server-side (if ffprobe available)
7. Test post with both images and videos
8. Test video-only post (no text, no images)
9. Test upload progress bar appears during large video upload
