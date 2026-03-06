# Architecture Review: Video Attachments on Community Posts

## Review Date
2026-03-05

## Files Reviewed
- `backend/community/models.py` (lines 360-411) -- PostVideo model, upload path helpers
- `backend/community/views.py` (lines 224-392, 1078-1197) -- CommunityFeedView, _serialize_posts
- `backend/community/services/video_service.py` -- validation + metadata extraction service
- `backend/community/serializers/core_serializers.py` -- CreatePostSerializer
- `backend/community/migrations/0007_add_post_video.py` -- migration
- `backend/community/admin.py` -- PostVideo admin registration
- `backend/community/services/bookmark_service.py` -- bookmark queries
- `mobile/lib/features/community/data/models/post_video_model.dart` -- PostVideoModel
- `mobile/lib/features/community/data/models/community_post_model.dart` -- videos field
- `mobile/lib/features/community/data/repositories/community_feed_repository.dart` -- video upload
- `mobile/lib/features/community/presentation/providers/community_feed_provider.dart` -- videoPaths param
- `mobile/lib/features/community/presentation/widgets/video_player_card.dart` -- inline player
- `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart` -- fullscreen player
- `mobile/lib/features/community/presentation/widgets/community_post_card.dart` -- video rendering

---

## Architectural Alignment

- [x] Follows existing layered architecture
- [x] Models/schemas in correct locations
- [x] No business logic in routers/views (video validation is in `services/video_service.py`)
- [x] Consistent with existing patterns

**Positive observations:**
1. `PostVideo` model mirrors the `PostImage` pattern exactly: FK to `CommunityPost`, `sort_order`, year/month-partitioned upload paths with UUID filenames.
2. Video validation logic is properly isolated in `services/video_service.py` with a frozen dataclass return type (`VideoMetadata`). Follows project convention of returning dataclasses from services (not dicts).
3. The view layer (`CommunityFeedView.post()`) handles only request/response orchestration: calls `validate_video()` from the service, creates model instances in a transaction, and serializes. Correct layering.
4. Admin registration includes `PostVideoInline` on `CommunityPost` and a standalone `PostVideoAdmin`, consistent with `PostImage` admin setup.
5. Flutter side follows repository -> provider -> widget pattern correctly. `PostVideoModel` is in data/models, repository handles multipart upload, provider passes through, `VideoPlayerCard` is a presentation widget.
6. Three-layer validation (extension, MIME type, magic bytes) in the service is thorough and defensive.

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | New table only; no existing columns modified. Existing posts have empty `videos` relation. |
| Migrations reversible | PASS | Single `CreateModel` + `AddIndex` operations. Django can reverse automatically. |
| Indexes added for new queries | PASS | Composite index on `(post, sort_order)` for ordered fetch. Index on `created_at` for admin. |
| No N+1 query patterns | FIXED | Feed queryset correctly prefetches `'videos'`. Bookmark service was missing `'post__videos'` -- fixed (see below). |

**PostVideo vs PostImage consistency:**
- PostVideo adds `file_size`, `duration`, `thumbnail`, and `created_at` fields that PostImage lacks. Appropriate for video-specific metadata.
- PostVideo uses `PositiveSmallIntegerField` for `sort_order` (max 3 videos) vs PostImage's `PositiveIntegerField` (max 10 images). Slightly inconsistent but functionally correct since constraint is enforced at application level.
- PostVideo uses `FileField` (not `ImageField`) for the video file -- correct.

---

## Issues Found and Fixed

### 1. FIXED -- N+1 query in bookmark_service.py (Major)

**File:** `backend/community/services/bookmark_service.py`, line 40

**Before:** `get_user_bookmarks()` prefetched `post__images` but NOT `post__videos`. When `_serialize_posts()` accessed `post.videos.all()` for bookmarked posts, each post triggered a separate database query.

**Fix:** Added `'post__videos'` to the `prefetch_related()` call:
```python
).prefetch_related('post__images', 'post__videos')
```

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Video player lifecycle in feed | Multiple `VideoPlayerCard` widgets in a scrolling feed each hold their own `VideoPlayerController`. No visibility-based pausing when scrolled offscreen. | Mitigated by tap-to-play design (no autoplay). Controllers are only created on user tap. Acceptable for now. Consider `VisibilityDetector` to auto-dispose offscreen controllers if video usage grows significantly. |
| 2 | Inline serialization | Videos serialized as inline dicts in `_serialize_posts()` rather than via a `PostVideoSerializer` class. | Consistent with how PostImage and all other nested data are serialized in the same function. Not a scalability issue. |
| 3 | Large video uploads in request cycle | 50MB uploads processed synchronously (validation + ffprobe + storage). | Django's file upload handling streams to temp files. ffprobe processing has a 30s timeout. Acceptable for current scale. Future: consider async processing via Celery for thumbnails/duration extraction. |

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | Unused `_VIDEO_MAGIC_BYTES` dict in `video_service.py` | Low | The dict at module level (line 28-31) is defined but never referenced. Actual magic byte checks are hardcoded in `_validate_magic_bytes()`. Remove the unused dict to avoid confusion. |
| 2 | Inline video serialization matches existing pattern | Low | The ticket called for a `PostVideoSerializer`, but inline dict construction in `_serialize_posts()` is consistent with existing PostImage serialization. If the team refactors to use DRF serializer classes for post output, videos should be included. Not a regression. |
| 3 | No client-side duration pre-check | Low | Ticket mentioned "client-side pre-check if possible" for duration. Currently only server validates. Could add `video_player` initialization on selected file to check duration before upload. |

---

## Architecture Score: 8/10

The implementation is architecturally sound. It follows established patterns (`PostImage`), properly separates concerns (validation in service, orchestration in view, models in models.py), and the data model is clean and backward-compatible. The one real issue (N+1 in bookmark service) has been fixed. The remaining items are low-severity debt that aligns with existing patterns. Flutter code follows the repository/provider/widget pattern correctly, and the video player lifecycle is acceptable given the tap-to-play design.

## Recommendation: APPROVE

The architecture is clean, the data model is additive and well-indexed, business logic is in services, and the implementation is consistent with the existing PostImage pattern throughout the stack. The N+1 query fix was the only architectural issue requiring correction.
