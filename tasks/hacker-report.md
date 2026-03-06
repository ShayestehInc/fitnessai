# Hacker Report: Video Attachments on Community Posts

## Dead Buttons & Non-Functional UI
| # | Severity | Screen/Component | Element | Expected | Actual |
|---|----------|-----------------|---------|----------|--------|
| 1 | Low | `video_service.py` | `_VIDEO_MAGIC_BYTES` dict | Used for validation | Defined but never referenced anywhere; the actual magic-byte check uses inline logic in `_validate_magic_bytes()`. Dead code. **FIXED** -- removed. |

## Visual Misalignments & Layout Bugs
| # | Severity | Screen/Component | Issue | Fix |
|---|----------|-----------------|-------|-----|
| 1 | Low | `community_post_card.dart` | Video list rendering used `.map()` + `.indexOf()` causing O(n^2) lookup per video. Not a visual bug per se, but causes unnecessary work per frame rebuild for posts with multiple videos. | **FIXED** -- replaced with indexed `for` loop. |

## Broken Flows & Logic Bugs
| # | Severity | Flow | Steps to Reproduce | Expected | Actual |
|---|----------|------|--------------------|---------|----|
| 1 | Critical | Fullscreen video retry | Open fullscreen on a video URL that fails to load, then tap "Retry" | Controller is disposed and recreated, video retries loading | `_controller` was declared `late final` -- cannot be reassigned after first initialization. The retry handler called `_initialize()` which reuses the same failed controller without disposing/recreating it. On a failed controller, `initialize()` would throw again or behave unpredictably. **FIXED** -- changed to `late` (non-final), retry now disposes old controller, creates a fresh `VideoPlayerController`, resets `_isInitialized`, and calls `_initialize()`. |
| 2 | Major | Zero-byte video upload (mobile) | Select a 0-byte video file from the gallery | Error toast shown, file rejected | 0-byte file passes the size check (only `> 50MB` is rejected) and gets added to `_videoPaths`. On submit, it would be uploaded and the backend magic-byte check would reject it with a confusing error ("File content does not match a supported video format"). **FIXED** -- added explicit `fileSize == 0` check in `_pickVideo()` with clear error message. |
| 3 | Major | Zero-byte video upload (backend) | POST a 0-byte video file to `/api/community/feed/` | 400 error with clear message | File passes extension and MIME type checks, then fails at magic-byte validation with the misleading message "File content does not match a supported video format." **FIXED** -- added explicit 0-byte check at the top of `validate_video()` returning "Video file is empty (0 bytes)." |
| 4 | Low | Negative duration from server | Server returns a negative `duration` value for a video | Duration badge hidden or shows "0:00" | `formattedDuration` would produce output like "-1:-40" because `.round()` on a negative float produces a negative int, then `~/` and `%` with negative operands produce negative minutes and seconds. **FIXED** -- added `duration! <= 0` guard in `formattedDuration` getter, returning empty string for non-positive durations. |
| 5 | Info | Fullscreen `_onStateChanged` performance | Play video in fullscreen mode | Efficient rebuilds only when UI-visible state changes | `_onStateChanged` calls `setState(() {})` on every `VideoPlayerController` listener tick (~30-60 times/sec during playback). This rebuilds the entire fullscreen widget tree every frame even when controls are hidden. Not a crash but a performance concern. **NOT FIXED** -- would require restructuring to use `ValueListenableBuilder` or conditional `setState` only when controls are visible. Documenting for future improvement. |

## Product Improvement Suggestions
| # | Impact | Area | Suggestion | Rationale |
|---|--------|------|------------|-----------|
| 1 | High | Video Player Card | Add a thin progress bar overlay at the bottom of inline feed videos showing playback position | Users have no way to see how far into a video they are without opening fullscreen. Instagram/TikTok/Twitter all show a progress indicator on inline videos. |
| 2 | High | Compose Post Sheet | Show actual video thumbnail preview instead of just an icon + file size label | Users see a camera icon and "12.3MB" which is unhelpful for confirming the right video was selected. Use `video_thumbnail` package to generate a local preview frame. |
| 3 | Medium | Fullscreen Player | Support double-tap left/right to seek +/- 10 seconds | Standard gesture on YouTube, Instagram, and most video players. Users expect this interaction pattern. |
| 4 | Medium | Video Player Card | Auto-pause video when it scrolls off-screen using visibility detection | Multiple videos in the feed keep playing when scrolled away, wasting bandwidth and battery. Use `VisibilityDetector` to pause when <50% visible and resume when scrolled back. |
| 5 | Medium | Compose Post Sheet | Allow re-ordering videos after selection via drag handles | Users might want to control the display order of multiple videos. Currently locked to pick order with no way to rearrange. |
| 6 | Low | Fullscreen Player | Add swipe-down-to-dismiss gesture | Common iOS/Android pattern for dismissing fullscreen media viewers. Currently requires tapping the small X button in the top-left corner. |
| 7 | Low | Video Player Card | Show file size badge alongside duration badge for large videos | Helps users on metered connections decide whether to play a video. A "12MB" badge next to "0:45" sets expectations. |

## Summary
- Dead UI elements found: 1 (unused `_VIDEO_MAGIC_BYTES` dict)
- Visual bugs found: 1 (O(n^2) video index lookup)
- Logic bugs found: 4 (fullscreen retry crash, zero-byte mobile bypass, zero-byte backend bypass, negative duration display)
- Performance concerns: 1 (fullscreen setState flood -- documented, not fixed)
- Improvements suggested: 7
- Items fixed by hacker: 5

## Files Changed
- `mobile/lib/features/community/presentation/widgets/fullscreen_video_player.dart` -- Fixed `late final` to `late`, fixed retry to dispose old controller and create a new one before calling `_initialize()`.
- `mobile/lib/features/community/presentation/widgets/community_post_card.dart` -- Replaced `.map()` + `.indexOf()` with indexed `for` loop for video rendering.
- `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart` -- Added zero-byte video file validation in `_pickVideo()`.
- `mobile/lib/features/community/data/models/post_video_model.dart` -- Added `duration! <= 0` guard in `formattedDuration` getter.
- `backend/community/services/video_service.py` -- Removed dead `_VIDEO_MAGIC_BYTES` dict; added explicit zero-byte file rejection at top of `validate_video()`.

## Chaos Score: 7/10
The video feature is solid overall. The fullscreen retry crash (Critical) was the most dangerous find -- using `late final` on a controller that needs to be recreated on retry is a guaranteed crash on any retry attempt. The zero-byte file bypasses were defense-in-depth gaps (backend magic-byte check would catch it, but with confusing errors). The negative duration edge case shows good defensive coding was needed in the model layer. No dead buttons, broken navigation, or broken form submissions found -- the feature is well-wired and the compose/upload flow handles errors properly with progress indication and toast feedback.
