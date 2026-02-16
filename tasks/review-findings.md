# Code Review: Phase 8 Community & Platform Enhancements (Round 1)

## Review Date: 2026-02-16

## Files Reviewed
All 43+ changed files across backend and mobile for Pipeline 18.

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `community/views.py:183-184` | `_ALLOWED_IMAGE_TYPES` includes `image/gif` but ticket AC-29 only allows JPEG, PNG, WebP. Also `_MAX_IMAGE_SIZE` is 10MB but ticket says 5MB. Error messages reference 10MB. | Change to `{'image/jpeg', 'image/png', 'image/webp'}` and `5 * 1024 * 1024`. Update error messages. |
| C2 | `community/views.py:665-733` | `_broadcast_new_post`, `_broadcast_post_deleted`, `_broadcast_new_comment`, `_notify_post_comment` all swallow exceptions with `logger.debug()`. CLAUDE.md says "NO exception silencing!" They should log at WARNING. | Change all `logger.debug` to `logger.warning` in broadcast/notify helpers. |
| C3 | `community/models.py:187-192` | `_community_post_image_path` function defined but NOT used. Model uses `upload_to='community_posts/'` string instead of UUID function. User-supplied filenames pass through (Django sanitizes but not defense-in-depth). | Use `upload_to=_community_post_image_path` for the ImageField. |
| C4 | `ambassador_payouts_screen.dart:73` | Mobile reads `resp.data['url']` but backend returns `{'onboarding_url': ..., 'message': ...}`. Key mismatch -- onboarding URL will always be null. | Fix to `resp.data['onboarding_url']`. |
| C5 | `push_notification_service.dart:122-126` | `_getPlatform()` returns `'mobile'` but backend validates platform must be one of `('ios', 'android', 'web')`. Device token registration will always fail with 400. | Use `dart:io` Platform to detect iOS vs Android. |
| C6 | `community/trainer_views.py:194` | `_notify_trainees_announcement` swallows all exceptions with `logger.debug`. | Change to `logger.warning`. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `community/views.py:516-517` | `LeaderboardView.get()` defaults metric_type and time_period if params missing. AC-3 says "Returns 400 if metric or period param missing/invalid". | Add validation and return 400 for missing/invalid params. |
| M2 | `community/views.py:382` | `CommentPagination.page_size = 30` but AC-36 says "Page size 20". | Change to 20. |
| M3 | `community/services/leaderboard_service.py:100` | Uses simple `enumerate` for ranking -- no tie handling. AC says "1, 2, 2, 4 pattern" (dense rank). | Implement dense ranking. |
| M4 | `community/views.py:520-527` | If trainer never visited leaderboard settings, no Leaderboard rows exist, so `is_enabled` check fails -- all leaderboards appear disabled by default. AC-1 says `is_enabled` defaults True. | Treat missing config as enabled. |
| M5 | `ambassador/views.py:706` | N+1 query: `payout.commissions_included.count()` called in loop. | Use `annotate(commission_count=Count('commissions_included'))`. |
| M6 | `community/views.py` | Missing `reaction_update` WebSocket broadcast in `ReactionToggleView` per AC-46 and AC-47. | Add broadcast after reaction toggle. |
| M7 | `community/consumers.py` | Missing `feed_reaction_update` handler method per AC-46. | Add handler. |
| M8 | `community/views.py` | No `timestamp` ISO string in any WebSocket broadcast messages per AC-46. | Add timestamp to all broadcasts. |
| M9 | `community/views.py:459` | `_get_post` returns None for both "not found" and "forbidden". AC-36 says 403 for wrong group, 404 for not found. | Distinguish the two cases. |
| M10 | `leaderboard_screen.dart:134` | Loading uses plain spinner instead of skeleton shimmer list per AC-6. | Add shimmer skeleton. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `leaderboard_screen.dart` | Missing `Semantics` labels on entries per AC-6. | Add Semantics wrapper. |
| m2 | `comments_sheet.dart` | Missing `Semantics` labels on comment tiles per AC-40. | Add Semantics. |
| m3 | `community_post_card.dart:459` | Image viewer minScale 0.5, ticket says 1.0. | Fix minScale. |
| m4 | `community_post_card.dart:444` | Missing Semantics on full-screen image viewer per AC-33. | Add Semantics. |
| m5 | `community_post_card.dart:254` | Image max height 200dp, ticket says 250dp. Border radius 8dp, ticket says 12dp. | Fix to match spec. |
| m6 | `compose_post_sheet.dart` | No 5MB client-side image size validation per AC-31. | Add check after image pick. |
| m7 | `community_ws_service.dart:93-96` | Silent empty catch on message parsing errors. | At minimum log. |

## Security Concerns
- C3: Image upload_to doesn't use UUID function
- No Pillow verify() on image uploads per AC-29
- No push notification debounce for reactions per AC-14

## Performance Concerns
- M5: N+1 on payout history commissions count
- Leaderboard streak: loads 90 days of logs -- acceptable for V1

## Quality Score: 5/10
## Recommendation: REQUEST CHANGES
