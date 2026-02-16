# Code Review: Social & Community (Pipeline 17, Round 1)

## Review Date: 2026-02-16

## Files Reviewed
All 34 new files and 11 modified files from the community feature implementation.

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `backend/community/views.py:134` | `AchievementWithStatusSerializer` is used to serialize manually-constructed dicts, but these dicts are never validated — the serializer's `.data` is accessed directly without `.is_valid()`. This is fine for read-only output serialization, but the pattern constructs dicts manually in a loop (N iterations), building an array then passing it through the serializer. This is actually an N+1-like concern: the view fetches all achievements, then all user achievements, but builds a Python list of dicts and passes them through a `Serializer(data=..., many=True)` without calling `.is_valid()` first. `Serializer.data` on an unvalidated serializer raises. | Use the serializer correctly: either call `.is_valid()` first and use `.data`, or instantiate with `instance=` not `data=` for output serialization. Better: since these are plain dicts, just return `Response(data)` directly (the serializer isn't adding value here — it's just passthrough). |
| C2 | `mobile/lib/features/community/presentation/providers/community_feed_provider.dart:112-134` | `toggleReaction` is NOT optimistic — it awaits the API call, then updates state. The ticket (AC-31) requires optimistic updates with rollback on error. Current UX: user taps reaction, nothing happens for 200-500ms (network latency), then count changes. | Implement optimistic update: update local state immediately before the API call, then on API error revert to the previous state and show a snackbar. |
| C3 | `mobile/lib/features/community/presentation/widgets/community_post_card.dart:175-177` | `_confirmDelete` calls `deletePost` directly without a confirmation dialog. Ticket AC-33 requires: "Long-press on own text post shows Delete option. Confirmation dialog: 'Delete this post? This cannot be undone.'" The current implementation uses a PopupMenuButton but no confirmation dialog — tapping "Delete" immediately deletes. | Add a confirmation dialog before calling `deletePost`. Show AlertDialog with "Delete this post?" title, "This cannot be undone." content, Cancel and Delete actions. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `backend/community/views.py:200-201` | `PageNumberPagination` is instantiated inline in `CommunityFeedView.get()` with `paginator.page_size = 20`. This is a non-standard DRF pattern that may not respect `DEFAULT_PAGINATION_CLASS` settings. Should use a proper class-level paginator. | Define `class FeedPagination(PageNumberPagination): page_size = 20` at module level and set `pagination_class = FeedPagination` on the view or use it consistently. |
| M2 | `backend/community/views.py:186-210` | The `CommunityFeedView.get()` method imports `PageNumberPagination` inside the method body. Imports should be at module level. | Move import to top of file. |
| M3 | `backend/community/views.py:234-290` | The `_serialize_posts` static method manually builds JSON dicts with author data, reaction counts, and user reactions. This bypasses DRF serializers entirely. While it avoids N+1 queries, it duplicates profile_image URL logic and is fragile (if User model changes, this breaks silently). Also, `author.profile_image` access may trigger a lazy load if not properly prefetched. | This is acceptable for performance but add a comment explaining why serializers are bypassed. The `select_related('author')` on line 196 should cover the profile_image concern. |
| M4 | `mobile/lib/features/community/presentation/screens/community_feed_screen.dart:153-154` | `announcementState.announcements.where((a) => a.isPinned).first` will throw `StateError` if the pinned announcement is filtered away between the `any()` check on line 105 and this `first` call (race condition with async state update). | Use `firstOrNull` or wrap in try-catch, or use the same `firstWhere` with `orElse`. |
| M5 | `mobile/lib/features/community/presentation/widgets/reaction_bar.dart:75` | `GestureDetector` is used for reaction buttons instead of `InkWell` or `Material` + `InkResponse`. No ripple feedback, and the touch target may be smaller than 48dp minimum. | Use `InkWell` with `borderRadius` for proper Material ripple and ensure minimum 48dp touch target with `SizedBox` constraint or `ConstrainedBox`. |
| M6 | `mobile/lib/features/community/presentation/screens/community_feed_screen.dart:92-93` | Loading state only shows `CircularProgressIndicator`. Ticket specifies: "3 shimmer skeleton post cards (avatar circle + name bar + 3-line content + reaction bar)." | Add shimmer skeleton loading state matching the specification. |
| M7 | `backend/community/views.py:152` | In `AchievementListView.get()`, `AchievementWithStatusSerializer(data, many=True)` is called with plain dicts as `data` parameter. For output serialization in DRF, using `data=` without validation will raise errors. Should use `instance=` or just return the list directly. | Either use `serializer = AchievementWithStatusSerializer(instance=data, many=True)` or just `return Response(data)`. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `backend/community/views.py:7` | `cast` imported from `typing` but `Any` is already imported. Clean, but `cast(User, ...)` is used everywhere — consider using `get_object_or_404` patterns or a mixin. | Keep as-is. Minor style preference. |
| m2 | `mobile/lib/features/community/presentation/screens/achievements_screen.dart:81-109` | `SingleChildScrollView` wrapping `GridView.builder` with `shrinkWrap: true` and `NeverScrollableScrollPhysics`. This works but is not as performant as a `CustomScrollView` with `SliverGrid`. | For 15 items this is fine. Flag for future if achievement count grows. |
| m3 | `backend/community/services/auto_post_service.py:73-77` | `_SafeFormatDict` inherits from bare `dict` with `type: ignore`. The `__missing__` method returns the key name for missing template variables, which means content like "Just completed workout_name!" if metadata is missing. | This is intentional and documented. The fallback is acceptable. |
| m4 | `mobile/lib/features/community/presentation/widgets/compose_post_sheet.dart:73` | `onChanged: (_) => setState(() {})` — triggers a full rebuild of the widget on every keystroke just to update the button state. | Use a `ValueListenableBuilder` on the controller instead, or a `ValueNotifier<bool>` for the canSubmit state. |
| m5 | `backend/community/trainer_views.py:36-50` | `create` method uses a separate `AnnouncementCreateSerializer` for validation then manually calls `Announcement.objects.create()`. Could use the `ModelSerializer.save()` pattern with `perform_create` override. | Works fine, just slightly verbose. Low priority. |
| m6 | `mobile/lib/features/trainer/presentation/screens/trainer_announcements_screen.dart:44` | FAB navigation path is `/trainer/announcements/create` but the route in the router is also `/trainer/announcements/create`. This works, but the route naming is slightly inconsistent — the list screen route is `trainer-announcements-screen`. | Rename for consistency if desired. Non-blocking. |

## Security Concerns
- Row-level security is properly enforced: all views filter by `user.parent_trainer` or `trainer=request.user`.
- `CommunityPostDeleteView` correctly checks both author and group trainer ownership.
- `ReactionToggleView` validates the user is in the same trainer group before allowing reaction.
- No secrets or API keys in any committed code.
- Input validation with max lengths on all user-input fields.

## Performance Concerns
- `_serialize_posts` uses batch queries for reaction counts and user reactions (2 queries total, not N+1). Good.
- `AchievementListView` uses 2 queries: one for all achievements, one for user's earned achievements. Good.
- `CommunityFeedView` uses `select_related('author')`. Good.
- Mobile community feed uses pagination with infinite scroll. Good.

## Quality Score: 6/10
## Recommendation: REQUEST CHANGES

The implementation is solid architecturally but has three critical issues: (C1) serializer misuse that will raise at runtime, (C2) missing optimistic reaction updates per the ticket, and (C3) missing delete confirmation dialog. Several major issues around UX polish (loading skeletons, touch targets) need attention.
