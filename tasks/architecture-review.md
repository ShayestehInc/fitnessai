# Architecture Review: Social & Community (Pipeline 17)

## Review Date: 2026-02-16

## Files Reviewed
- All backend `community/` files (models, views, serializers, services, urls, admin, apps, migrations, tests)
- All mobile `features/community/` files (models, repositories, providers, screens, widgets)
- Modified backend files: `config/settings.py`, `config/urls.py`, `trainer/urls.py`, `workouts/views.py`, `workouts/survey_views.py`
- Modified mobile files: `api_constants.dart`, `app_router.dart`, `main_navigation_shell.dart`, `home_screen.dart`, `settings_screen.dart`, `trainer_dashboard_screen.dart`

---

## Architectural Alignment

- [x] Follows existing layered architecture (views handle request/response, serializers handle validation, services handle business logic)
- [x] Models/schemas in correct locations (new `community` app, matching app-per-domain pattern)
- [x] No business logic in routers/views (achievement checking and auto-post creation in `services/`)
- [x] Consistent with existing patterns (Repository pattern on mobile, StateNotifier for state, go_router for navigation)
- [x] Mobile follows feature-first architecture (`features/community/data/`, `features/community/presentation/`)
- [x] API constants centralized in `api_constants.dart`
- [x] Routes centralized in `app_router.dart`

---

## Data Model Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Schema changes backward-compatible | PASS | All new tables (no existing table modifications). Forward-only migration. |
| Migrations reversible | PASS | Single `0001_initial.py` creates all 6 tables + indexes + constraints. Can be reversed by dropping the `community` app tables. |
| Indexes added for new queries | PASS | `(trainer, -created_at)` on Announcement and CommunityPost. `(trainer, is_pinned)` on Announcement. `(post, reaction_type)` on PostReaction. `(user, -earned_at)` on UserAchievement. |
| No N+1 query patterns | PASS | Feed uses batch reaction aggregation (2 queries for reactions + user_reactions). Achievements uses batch UserAchievement fetch. Announcements use standard queryset. |
| Unique constraints | PASS | `(user, trainer)` on AnnouncementReadStatus. `(criteria_type, criteria_value)` on Achievement. `(user, achievement)` on UserAchievement. `(user, post, reaction_type)` on PostReaction. |
| CASCADE behavior | PASS | All FKs use `on_delete=CASCADE` -- when a trainer or user is deleted, all their community data is cleaned up. Consistent with existing patterns. |
| Default ordering | PASS | Announcement: `[-is_pinned, -created_at]`. CommunityPost: `[-created_at]`. Achievement: `[criteria_type, criteria_value]`. Matches query patterns. |

---

## API Design Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| RESTful endpoints | PASS | Standard REST: GET/POST for collections, GET/PUT/DELETE for detail. Feed combines GET (list) and POST (create) on same path -- acceptable for resource-oriented design. |
| Consistent error format | PASS | All errors return `{error: str}` dict. DRF validation errors use standard format. |
| Pagination | PASS | Feed uses `PageNumberPagination` with page_size=20. Announcements use DRF default pagination. |
| URL naming | PASS | Consistent with existing patterns: `/api/community/` for trainee, `/api/trainer/` for trainer. |
| Response structure | PASS | Feed responses include `count`, `next`, `previous`, `results` (standard DRF pagination). Reaction toggle returns updated state. |
| Idempotency | PASS | Reaction toggle is naturally idempotent. Mark-read uses `update_or_create`. Achievement award uses `get_or_create`. |

---

## Frontend Patterns Assessment

| Concern | Status | Notes |
|---------|--------|-------|
| Riverpod StateNotifier | PASS | All 3 providers use StateNotifier pattern: CommunityFeedNotifier, AnnouncementNotifier, AchievementNotifier. Consistent with project convention. |
| Repository pattern | PASS | Screen -> Provider -> Repository -> ApiClient.dio. All 3 repositories follow this pattern. |
| Immutable state classes | PASS | All state classes have `copyWith()` methods with `clearError` pattern. |
| Route registration | PASS | New routes added to `app_router.dart` within existing StatefulShellRoute.indexedStack. |
| Feature-first structure | PASS | `data/models/`, `data/repositories/`, `presentation/providers/`, `presentation/screens/`, `presentation/widgets/`. |
| Widget file length | PASS | All widget files under 150 lines. Screens under 200 lines. |

---

## Scalability Concerns

| # | Area | Issue | Recommendation |
|---|------|-------|----------------|
| 1 | Feed reaction counts | `CommunityFeedView._serialize_posts()` runs 2 aggregate queries per page load (reaction counts + user reactions). With 20 posts per page, this is efficient. At 100+ posts per page it could become slow. | Current page_size=20 is fine. If the page size grows, consider annotating reactions directly in the queryset using `Count` with `filter` parameter on the main post query. LOW concern. |
| 2 | Achievement streak calculation | `_consecutive_days()` fetches all dates from DailyLog/WeightCheckIn and iterates backward. For a user with years of history, the date set grows large but iteration is O(streak_length). | Date set fetch is one query; iteration is bounded by actual streak length. Acceptable for V1. If needed, add an upper bound on date fetch (last 365 days). LOW concern. |
| 3 | Announcement unread count | `AnnouncementUnreadCountView.get()` makes 2 queries: one to find the read status, one to count unread announcements. | Could be combined into a single query with a subquery. LOW concern -- announcement count per trainer is typically small (<100). |

**No scalability blockers.** All concerns are LOW severity and well within acceptable performance for the expected user base.

---

## Technical Debt Introduced

| # | Description | Severity | Suggested Resolution |
|---|-------------|----------|---------------------|
| 1 | `AchievementWithStatusSerializer`, `CommunityPostSerializer`, `PostAuthorSerializer`, `UnreadCountSerializer`, `MarkReadResponseSerializer`, `ReactionResponseSerializer` in `serializers.py` are defined but unused by views (views return plain dicts instead) | Low | Remove unused serializers or switch views to use them. The current approach of returning plain dicts via `Response(data)` works but diverges from the DRF convention of using serializers for all output. Keeping both creates confusion about which is canonical. |
| 2 | Trainer announcement views in `community/trainer_views.py` instead of `trainer/` app | Low | The deviation is documented in `dev-done.md`. It keeps community code cohesive but breaks the pattern where trainer-facing views live in the `trainer` app. Acceptable tradeoff for V1; consistent with how URLs are still registered under `/api/trainer/`. |

---

## Architecture Score: 9/10

### Strengths:
- Clean separation: new `community` app with no cyclic dependencies on existing apps
- Business logic in services (achievement checking, auto-post), not in views
- Fire-and-forget pattern for non-critical operations (achievements, auto-posts)
- Proper database constraints for data integrity (unique together, cascading deletes)
- Comprehensive indexes matching all query patterns
- Mobile follows repository pattern consistently
- No N+1 query issues in feed rendering (batch aggregation)

### Minor Concerns:
- Unused serializers should be cleaned up
- Trainer views location is a minor deviation from convention

---

## Recommendation: APPROVE

The architecture is sound. New `community` app is cleanly separated. Data model is well-designed with proper indexes, constraints, and cascade behavior. Business logic is in services. No N+1 queries. Mobile follows project conventions exactly. No architectural blockers.

---

**Audit completed by:** Architecture Auditor Agent
**Date:** 2026-02-16
**Pipeline:** 17 -- Social & Community
