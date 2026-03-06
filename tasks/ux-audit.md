# UX Audit: Video Attachments on Community Posts

## Audit Date: 2026-03-05

## Files Audited
- `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart`
- `mobile/lib/features/community/presentation/widgets/video_player_card.dart`
- `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart`
- `mobile/lib/features/community/presentation/widgets/community_post_card.dart`
- `mobile/lib/features/community/presentation/widgets/image_carousel.dart`
- `mobile/lib/features/community/data/models/post_video_model.dart`

---

## Usability Issues

| # | Severity | Screen/Component | Issue | Recommendation | Fixed? |
|---|----------|-----------------|-------|----------------|--------|
| 1 | Major | VideoPlayerCard | No loading indicator when user taps play -- video initializes silently with no visual feedback, making it feel broken or laggy on slow connections | Added `_isLoading` state with a white CircularProgressIndicator spinner inside a dark circle overlay during initialization | Yes |
| 2 | Major | ComposePostSheet | Upload progress bar only appeared when `_uploadProgress > 0`, leaving a gap between tap and first progress event where only the button spinner provided feedback | Changed to show indeterminate progress bar immediately when submitting, with "Preparing upload..." text until actual progress starts | Yes |
| 3 | Major | VideoPlayerCard | Error overlay "Tap to retry" used `theme.colorScheme.onError` (designed for colored error backgrounds) on a semi-transparent black overlay, resulting in poor contrast and inconsistent appearance across themes | Redesigned error overlay: white70 icon/text, descriptive "Video failed to load" label, and a visible pill-shaped "Tap to retry" button with semi-transparent white background | Yes |
| 4 | Minor | VideoPlayerCard | Fullscreen mode only discoverable via long-press (hidden gesture) or a small icon that appears after playback starts. Many users will never find it. | Kept existing pattern but ensured the fullscreen icon has adequate touch target padding. Long-press discoverability remains a known limitation -- consider adding a tooltip or onboarding hint in a future iteration. | Partial |
| 5 | Minor | ComposePostSheet | Remove buttons on image/video previews were only 14px icon + 2px padding = ~18px total touch area, well below the 48dp minimum recommended by Material Design | Enlarged touch target with outer Padding of 4px and inner padding of 4px around icon, improving effective hit area to ~30px (closer to minimum; constrained by 80px preview height) | Yes |
| 6 | Minor | VideoPlayerCard | Mute and fullscreen GestureDetectors had tight padding (4px), making them hard to tap accurately on mobile devices | Added outer Padding(4) + inner padding(6) and `HitTestBehavior.opaque` to expand effective touch area | Yes |

## Accessibility Issues

| # | WCAG Level | Issue | Fix | Fixed? |
|---|------------|-------|-----|--------|
| 1 | A | VideoPlayerCard: No Semantics on play, mute, fullscreen controls -- screen readers cannot identify interactive elements | Added Semantics with descriptive labels: "Play video", "Unmute video", "Open fullscreen video" | Yes |
| 2 | A | VideoPlayerCard: No overall Semantics label on the video container | Added Semantics wrapper: "Video attachment. Tap to play, long press for fullscreen." | Yes |
| 3 | A | ComposePostSheet: Image/video remove buttons lack Semantics labels | Added Semantics: "Remove image N" and "Remove video N" with button role | Yes |
| 4 | A | FullscreenVideoPlayer: Close button lacks tooltip/semantic label | Added Semantics wrapper with label "Close fullscreen video" and tooltip "Close" | Yes |
| 5 | A | FullscreenVideoPlayer: Play/pause and mute buttons lack tooltips for assistive technology | Added tooltip: "Play"/"Pause" and "Mute"/"Unmute" to IconButtons | Yes |
| 6 | A | FullscreenVideoPlayer: Seek bar lacks semantic label | Added Semantics wrapper with label "Video seek bar" and slider role | Yes |

## Missing States Checklist

- [x] Loading / skeleton -- VideoPlayerCard now shows spinner during init; compose sheet shows indeterminate progress bar immediately
- [x] Empty / zero data -- ImageCarousel returns SizedBox.shrink for empty list; video list simply hidden when empty; compose sheet allows text-only posts
- [x] Error / failure -- VideoPlayerCard has error overlay with "Video failed to load" + retry; fullscreen has error with retry; compose has toast on failure; image load failures show broken_image icon
- [x] Success / confirmation -- Compose shows "Posted!" toast on success; delete shows "Post deleted" toast
- [x] Offline / degraded -- Network errors caught in video player init with retry option; upload failure shows error toast with "Failed to create post. Please try again."
- [x] Permission denied -- Not directly applicable to video playback; gallery picker handles OS permissions natively

## Positive Observations

- Compose sheet enforces clear limits (10 images, 3 videos, 50MB video / 5MB image caps) with actionable error messages
- Video format validation catches unsupported types with helpful message ("Use MP4, MOV, or WebM")
- Feed video starts muted (standard social media pattern) with easy unmute via bottom-left icon
- Fullscreen player supports landscape rotation and properly restores portrait on dispose
- Controls auto-hide after 3 seconds with tap-to-toggle -- matches YouTube/Instagram patterns
- Post deletion has confirmation dialog with cancel option (undo safety)
- Video preview in compose shows file size and "VIDEO" badge -- clear visual distinction from image thumbnails
- Duration badge shown before playback starts (bottom-right) -- sets user expectations
- Empty file check added by linter in video picker -- catches corrupt/zero-byte files

## Remaining Recommendations (Not Fixed -- Require Design Decisions)

1. **Fullscreen discoverability (Medium impact)**: The long-press gesture to enter fullscreen is hidden. Consider adding a subtle "pinch to expand" hint or a brief tooltip on first video playback to educate users.

2. **Video thumbnail generation (Medium impact)**: When no `thumbnailUrl` is provided from the server, the placeholder is a plain gray box with a camera icon. Consider generating a client-side thumbnail from the first frame of the video.

3. **Video progress bar in feed (Low impact)**: The inline video player has no seek bar or progress indicator. Users can only play/pause. Consider adding a thin progress bar at the bottom of the inline player for longer videos.

---

## Overall UX Score: 7/10

The video attachment feature has solid core functionality with proper validation, error handling, and state management. All critical accessibility gaps (6 missing Semantics labels) have been fixed. The loading feedback gap during video initialization and upload preparation have been addressed. Touch targets on overlay controls have been enlarged. The main remaining UX concern is fullscreen discoverability relying on a hidden long-press gesture. With the fixes applied in this audit, the video UX is production-ready.

## Summary of Fixes Applied

1. **compose_post_sheet.dart**: Enlarged image/video remove button touch targets with outer padding; added Semantics labels ("Remove image N", "Remove video N"); changed upload progress to show indeterminate bar immediately with "Preparing upload..." text
2. **video_player_card.dart**: Added `_isLoading` state with white spinner during video init; added Semantics to overall card, play button, mute button, fullscreen button; enlarged mute/fullscreen touch targets with padding and opaque hit behavior; redesigned error overlay with visible retry button, descriptive copy ("Video failed to load"), and better contrast
3. **fullscreen_video_player.dart**: Added Semantics and tooltip to close button; added tooltips to play/pause and mute buttons; added Semantics wrapper to seek bar; linter fixed `late final` to `late` on controller for retry support; linter updated retry to properly dispose and recreate controller
