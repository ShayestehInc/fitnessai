# Code Review: Video Workout Layout — End-to-End Activation

## Review Date: 2026-03-08

## Files Reviewed
- `backend/trainer/models.py` (layout_type enum addition)
- `backend/trainer/migrations/0008_alter_workoutlayoutconfig_layout_type.py`
- `web/src/components/trainees/layout-config-selector.tsx`
- `web/src/components/exercises/exercise-video-player.tsx` (NEW)
- `web/src/components/exercises/exercise-detail-panel.tsx`
- `mobile/lib/features/workout_log/presentation/widgets/video_workout_layout.dart`
- `tasks/focus.md`, `tasks/next-ticket.md`

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 1 | `layout-config-selector.tsx:22-45` | **Web layout values do NOT match backend enum values.** The web sends `"default"`, `"compact"`, `"detailed"` but the backend expects `"classic"`, `"card"`, `"minimal"`. Only `"video"` matches on both sides. This means: (a) selecting Default/Compact/Detailed on the web sends an invalid value to the backend, which Django will reject with a validation error since it uses `TextChoices` enforcement on the serializer; (b) when the backend returns `layout_type: "classic"`, the web won't match it to any option so nothing appears selected. **This is a pre-existing bug, but the current diff does NOT fix it and the new "video" option masks it — a trainer might think the selector works because "video" saves fine, then be confused when the other 3 options fail.** | Change web values to `"classic"`, `"card"`, `"minimal"`, `"video"` to match the backend `LayoutType` TextChoices exactly. Also update labels to match: "Classic", "Card", "Minimal", "Video". |
| 2 | `layout-config-selector.tsx:53-68` | **Web reads `data.layout` but backend serializer returns `layout_type`.** The serializer's `fields` list is `['layout_type', 'config_options', ...]`. The web query types the response as `{ layout: string }` and reads `data.layout` (line 61), and the mutation sends `{ layout: value }` (line 68). Neither matches the backend field name `layout_type`. GET will never populate `selected` correctly (it stays "default"), and PATCH sends a field the serializer ignores, so the layout never actually persists. | Change web to use `layout_type` as the field name: type the response as `{ layout_type: string }`, read `data.layout_type`, and send `{ layout_type: value }` in the mutation. |
| 3 | `exercise-video-player.tsx:47` | **`iframe.onError` does not fire for YouTube embed load failures.** The `onError` handler on an `<iframe>` element does not trigger when the page inside the iframe returns a 4xx/5xx or fails to load a video. It only fires if the iframe `src` URL itself cannot be fetched (e.g., DNS failure). A deleted YouTube video or a private video will render the iframe fine (HTTP 200) but show YouTube's "Video unavailable" screen. The user sees YouTube's error page, not the component's error state. | For YouTube embeds, consider using the YouTube IFrame API's `onError` event via `postMessage`, or accept this limitation and document it. At minimum, remove the misleading `onError` so developers don't assume it works. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 4 | `exercise-video-player.tsx:10-14` | **YouTube regex misses common URL formats.** Does not match: `youtube.com/embed/ID`, `youtube.com/watch?v=ID&t=123`, `youtube.com/shorts/ID`, `youtube-nocookie.com/embed/ID`, URLs with `www.` prefix with additional path segments. A trainer pasting an embed URL or Shorts URL gets a raw `<video>` tag pointed at a YouTube page, which silently fails. | Expand regex: `/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})/` and strip query params from the ID match. |
| 5 | `exercise-video-player.tsx:17-19` | **`isDirectVideoUrl` regex fails for URLs with query strings before the extension or with fragment identifiers.** E.g., `https://cdn.example.com/video.mp4?token=abc` works, but `https://cdn.example.com/serve?file=video&format=mp4` does not and falls to the unknown-format branch. Also does not handle `.m3u8` (HLS) or `.mpd` (DASH) which some CDNs serve. | Consider broadening the check or relying solely on the fallback branch (try as video, error on failure), which already handles unknown formats identically. The `isDirectVideoUrl` function is dead logic since both branches produce the same `<video>` element. |
| 6 | `video_workout_layout.dart:194` | **Swallowed exception in video init.** `catch (_)` silently eats the error. Per project rule: "NO exception silencing!" If video init fails due to a codec issue, network timeout, or malformed URL, no diagnostic info is available. | Change to `catch (e, st)` and log the error: `debugPrint('Video init failed: $e\n$st');` or use the project's logger. |
| 7 | `video_workout_layout.dart:1019-1023` | **`_formatMuscleGroup` crashes on empty string.** `w[0].toUpperCase()` throws `RangeError` if `group` is an empty string or contains consecutive underscores (producing empty split segments). | Add a guard: `.where((w) => w.isNotEmpty)` before the `.map()`. |
| 8 | `migration 0008:16` | **`help_text` not updated for the new 'video' choice.** It still reads: "classic (table), card (swipe), minimal (list)" — no mention of video. This misleads anyone reading the schema or Django admin. | Update to: "classic (table), card (swipe), minimal (list), video (demo videos)". |
| 9 | `video_workout_layout.dart:84` | **`SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light)` is set in `initState` but never restored in `dispose()`.** When the user exits the video layout, the status bar stays light (white icons) which may be invisible on a light-themed screen. | Save the previous overlay style and restore it in `dispose()`, or use `AnnotatedRegion<SystemUiOverlayStyle>` widget instead of imperative call. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| 10 | `exercise-video-player.tsx` | **No `loading="lazy"` on YouTube iframe.** If the exercise detail panel renders off-screen or in a list, the iframe loads immediately, consuming bandwidth and slowing the page. | Add `loading="lazy"` attribute to the iframe. |
| 11 | `exercise-video-player.tsx:43-44` | **YouTube embed allows autoplay in the `allow` attribute.** The video does not autoplay (no `?autoplay=1` in the URL), but the `allow` policy permits it. If the URL is ever modified to include autoplay, it will auto-play with sound (no `mute` param), which is jarring. | Either remove `autoplay` from the `allow` list, or add `?autoplay=1&mute=1` if autoplay is desired. |
| 12 | `exercise-video-player.tsx` | **No `aria-label` on the error state or video elements.** Screen readers get no context about what failed or what the video shows. | Add `role="alert"` to the error container, `aria-label="Exercise demonstration video"` to the video/iframe. |
| 13 | `exercise-video-player.tsx:54-69` / `73-86` | **Duplicated `<video>` JSX block.** The "direct video URL" branch (lines 54-69) and the "unknown format" fallback branch (lines 73-86) are identical. | Extract into a shared helper component or just remove the `isDirectVideoUrl` check entirely — the fallback handles both cases. |
| 14 | `video_workout_layout.dart:723-724` | **Hardcoded "Lb" unit.** Not all users use pounds. Should respect the user's unit preference (metric vs imperial). | Read the unit preference from the user profile/settings provider and display "kg" or "Lb" accordingly. |
| 15 | `layout-config-selector.tsx:109` | **Description string "Choose how workouts appear for this trainee" is not localized.** Other strings in the component use `t()`. | Use `t("trainees.layoutDescription")` or equivalent. |
| 16 | `video_workout_layout.dart:258-263` | **Swipe gesture threshold of 200 pixels/second is low.** Accidental brushes while logging sets could trigger exercise navigation. | Increase to 400-500 px/s, or add a minimum horizontal distance requirement. |

---

## Security Concerns

- **XSS via video_url (Medium):** The `videoUrl` prop is rendered directly into an `<iframe src>` and `<video src>`. If a trainer or admin stores a `javascript:` URL or a `data:text/html,...` URL as `video_url`, the iframe could execute arbitrary JS in the context of the page. The `extractYouTubeId` regex would not match, and `isDirectVideoUrl` would not match, so it falls to the raw `<video src={videoUrl}>` — `<video>` tags do not execute JS from `src`, but `<iframe>` paths could be manipulated if the regex is bypassed. **Recommendation:** Validate `video_url` on the backend to only allow `https://` URLs. Reject `javascript:`, `data:`, `blob:`, and `file:` schemes.
- **YouTube no-cookie domain is good** — using `youtube-nocookie.com` for embeds is a privacy-positive choice.

## Performance Concerns

- **Mobile video controller lifecycle is well-managed.** The `dispose()` properly cleans up controllers, and `didUpdateWidget` correctly handles exercise changes by disposing the old controller before creating a new one. The `mounted` check after async `initialize()` prevents use-after-dispose.
- **TextEditingController sync (`_syncControllers`)** only appends, never shrinks. If sets are removed (unlikely but possible), the controller lists will have stale entries that won't be garbage collected. Low risk.
- **Web video player has no preload control.** Direct `<video>` elements default to browser-chosen preloading, which on some browsers means downloading the entire file. Add `preload="metadata"` to limit initial download.

---

## Quality Score: 4/10

The backend change is clean and correct. The mobile widget is well-crafted with proper lifecycle management. However, the web integration has two critical data contract mismatches (wrong field values and wrong field names) that make the layout selector completely non-functional — it cannot read from or write to the backend. These are not edge cases; the feature fundamentally does not work on web.

## Recommendation: BLOCK

**Rationale:** Critical issues #1 and #2 mean the web layout config selector is broken for ALL layout types, not just video. Selecting any option sends data the backend either rejects or ignores. The feature cannot be shipped until the web values and field names match the backend API contract. Issue #3 (iframe onError) is a false safety net that should be documented or addressed. Fix all 3 critical issues and the 6 major issues before re-review.
