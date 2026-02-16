# Feature: Social & Community -- Announcements, Achievements, Community Feed

## Priority
High

## User Story
As a **trainer**, I want to broadcast announcements to all my trainees, see which trainees earn achievement badges, and have my trainees engage with each other in a moderated community feed, so that my coaching group feels connected and motivated.

As a **trainee**, I want to see announcements from my trainer, earn badges for consistency milestones, and share achievements and updates with other trainees in my group, so that I stay motivated and feel part of a community.

---

## Acceptance Criteria

### Feature 1: Trainer Announcements

**Backend:**

- [ ] **AC-1**: `Announcement` model exists in a new `community` Django app with fields: `id`, `trainer` (FK to User, TRAINER), `title` (CharField max 200), `body` (TextField max 2000), `is_pinned` (BooleanField default False), `created_at` (auto_now_add), `updated_at` (auto_now). Table name: `announcements`. Indexed on `(trainer, -created_at)` and `(trainer, is_pinned)`.
- [ ] **AC-2**: `AnnouncementReadStatus` model exists with fields: `id`, `user` (FK to User), `trainer` (FK to User, TRAINER), `last_read_at` (DateTimeField). Unique constraint on `(user, trainer)`. Table name: `announcement_read_statuses`.
- [ ] **AC-3**: Trainer CRUD endpoints exist under `/api/trainer/announcements/`:
  - `GET /api/trainer/announcements/` -- List own announcements, ordered by `is_pinned DESC, created_at DESC`. Paginated (page size 20).
  - `POST /api/trainer/announcements/` -- Create announcement (title + body required, is_pinned optional). Validates title max 200, body max 2000.
  - `GET /api/trainer/announcements/<id>/` -- Retrieve single announcement (own only).
  - `PUT/PATCH /api/trainer/announcements/<id>/` -- Update announcement (own only).
  - `DELETE /api/trainer/announcements/<id>/` -- Delete announcement (own only). Returns 204.
  - All endpoints require `[IsAuthenticated, IsTrainer]`. Row-level security: `get_queryset` filters by `trainer=request.user`.
- [ ] **AC-4**: Trainee announcement endpoints exist under `/api/community/announcements/`:
  - `GET /api/community/announcements/` -- Returns announcements from the trainee's `parent_trainer`, ordered by `is_pinned DESC, created_at DESC`. Paginated (page size 20). Row-level security: returns empty list if trainee has no `parent_trainer`.
  - `GET /api/community/announcements/unread-count/` -- Returns `{unread_count: int}`. Count of announcements with `created_at > last_read_at` (or all announcements if no `AnnouncementReadStatus` record exists).
  - `POST /api/community/announcements/mark-read/` -- Upserts `AnnouncementReadStatus` with `last_read_at = timezone.now()` for the trainee's trainer. Returns `{last_read_at: datetime}`.
  - All endpoints require `[IsAuthenticated, IsTrainee]`.

**Mobile (Trainer):**

- [ ] **AC-5**: Trainer dashboard has an "Announcements" section showing total announcement count and a "Manage" button that navigates to `/trainer/announcements`.
- [ ] **AC-6**: Announcements management screen lists all trainer's announcements with title, body preview (first 100 chars, ellipsized), pinned indicator (pin icon), and relative timestamp. Pull-to-refresh. Paginated with infinite scroll. FAB to create. Empty state: "No announcements yet. Create one to broadcast to your trainees." with campaign icon.
- [ ] **AC-7**: Create/Edit announcement screen: title field (required, max 200 chars, character counter), body field (required, max 2000 chars, character counter), is_pinned toggle. Submit button shows loading spinner while saving. Success: pop back with snackbar "Announcement created" / "Announcement updated". Error: snackbar with error message, form data preserved.
- [ ] **AC-8**: Swipe-to-delete on announcement cards with confirmation dialog ("Delete this announcement? Your trainees will no longer see it."). Tapping a card opens the edit screen pre-populated.

**Mobile (Trainee):**

- [ ] **AC-9**: Home screen shows "Announcements" section between the header and Nutrition section. Shows latest 3 announcements (pinned first). Each card: title (1 line, ellipsized), body preview (2 lines max), relative timestamp. "View All" link navigates to `/announcements`. Section hidden entirely if trainee has no `parent_trainer`.
- [ ] **AC-10**: Full announcements screen (`/announcements`): all announcements from trainer, paginated infinite scroll. Pinned announcements have pin icon and subtle primary-color-tinted left border. Pull-to-refresh. Empty state: "No announcements from your trainer yet." with megaphone icon. If no `parent_trainer`: "Join a trainer to see announcements." with person_add icon.
- [ ] **AC-11**: Notification bell on home screen header shows unread announcement count badge (red circle with white number, max "99+"). Badge count fetched on home screen load via `/api/community/announcements/unread-count/`. Mark-read called when announcements screen is opened (in `initState`). Tapping bell navigates to `/announcements`.

### Feature 2: Achievement / Badge System

**Backend:**

- [ ] **AC-12**: `Achievement` model exists with fields: `id`, `name` (CharField max 100), `description` (TextField max 500), `icon_name` (CharField max 50 -- Material icon name string), `criteria_type` (TextChoices: `workout_count`, `workout_streak`, `weight_checkin_streak`, `nutrition_streak`, `program_completed`), `criteria_value` (PositiveIntegerField). Table name: `achievements`. Unique constraint on `(criteria_type, criteria_value)`.
- [ ] **AC-13**: `UserAchievement` model exists with fields: `id`, `user` (FK to User), `achievement` (FK to Achievement), `earned_at` (DateTimeField auto_now_add). Table name: `user_achievements`. Unique constraint on `(user, achievement)`. Indexed on `(user, -earned_at)`.
- [ ] **AC-14**: Seed command `python manage.py seed_achievements` creates predefined achievements (idempotent via `get_or_create`):
  - Workout count: First Workout (1), Dedicated 10 (10), Quarter Century (25), Half Century (50), Century Club (100)
  - Workout streak: Hot Streak (3), On Fire (7), Unstoppable (14), Iron Will (30)
  - Weight check-in streak: Consistent Weigh-In (7), Monthly Tracker (30)
  - Nutrition streak: Tracking Starter (3), Nutrition Pro (7), Macro Master (30)
  - Program completed: Program Graduate (1)
  Total: 15 achievements.
- [ ] **AC-15**: `check_and_award_achievements(user: User, trigger: str) -> list[UserAchievement]` service function in `backend/community/services/achievement_service.py`:
  - `trigger` is one of: `workout_completed`, `weight_checkin`, `nutrition_logged`, `program_completed`.
  - Queries relevant data (DailyLog entries for streaks/counts, WeightCheckIn for weight streaks, Program for completion).
  - Streak calculation: consecutive calendar days with relevant activity. Gap of 1+ days resets streak to 0.
  - Workout count: total distinct dates with non-empty `DailyLog.workout_data`.
  - Compares against unearned achievements matching the trigger's `criteria_type`.
  - Creates `UserAchievement` via `get_or_create` (handles concurrent calls via IntegrityError catch).
  - Returns list of newly earned `UserAchievement` objects.
  - Wrapped in try-except so failures never block the parent operation.
- [ ] **AC-16**: Achievement check hooks:
  - Called after workout data is saved to `DailyLog` (trigger: `workout_completed`).
  - Called after `WeightCheckIn` is created (trigger: `weight_checkin`).
  - Called after nutrition data is saved to `DailyLog` (trigger: `nutrition_logged`).
  - Returns newly earned achievements in the API response under a `new_achievements` key so the mobile app can show toast notifications.
- [ ] **AC-17**: Trainee achievement endpoints under `/api/community/achievements/`:
  - `GET /api/community/achievements/` -- All achievements with earned status for current user. Response: `[{id, name, description, icon_name, criteria_type, criteria_value, earned: bool, earned_at: datetime|null}]`. Ordered by `criteria_type`, `criteria_value`.
  - `GET /api/community/achievements/recent/` -- 5 most recently earned achievements for current user.
  - Both require `[IsAuthenticated, IsTrainee]`.

**Mobile (Trainee):**

- [ ] **AC-18**: Settings screen (trainee) has a new "ACHIEVEMENTS" section between "TRACKING" and "SUBSCRIPTION". Tile: `emoji_events` icon, title "Achievements", subtitle "{earned}/{total} earned". Tapping navigates to `/achievements`.
- [ ] **AC-19**: Achievements screen (`/achievements`): GridView with 3 columns. Each badge shows icon (from `icon_name` mapped to Material Icons), name, earned status. Earned badges: colored icon with primary color tint, "Earned {relative_date}" subtitle. Unearned badges: grayscale icon with 0.3 opacity, locked overlay icon. Tapping opens a detail bottom sheet with full description, criteria explanation, and earned date if applicable. Pull-to-refresh. Loading: 6 shimmer circles. Error: inline error card with retry. Empty: "No achievements available yet." with trophy icon.
- [ ] **AC-20**: When the API response from a workout/nutrition/weight action includes `new_achievements`, a toast SnackBar appears: trophy icon + "Achievement Unlocked: {name}". Auto-dismiss after 4 seconds. If multiple achievements earned simultaneously, show one toast per achievement with 500ms stagger.

### Feature 3: Community Feed

**Backend:**

- [ ] **AC-21**: `CommunityPost` model exists with fields: `id`, `author` (FK to User), `trainer` (FK to User, TRAINER -- the group scope), `content` (TextField max 1000), `post_type` (TextChoices: `text`, `workout_completed`, `achievement_earned`, `weight_milestone`), `metadata` (JSONField default dict), `created_at` (auto_now_add). Table name: `community_posts`. Indexed on `(trainer, -created_at)`. `on_delete=CASCADE` for both FKs.
- [ ] **AC-22**: `PostReaction` model exists with fields: `id`, `user` (FK to User), `post` (FK to CommunityPost, on_delete CASCADE), `reaction_type` (TextChoices: `fire`, `thumbs_up`, `heart`), `created_at` (auto_now_add). Table name: `post_reactions`. Unique constraint on `(user, post, reaction_type)`. Indexed on `(post, reaction_type)`.
- [ ] **AC-23**: Feed endpoint `GET /api/community/feed/`: Returns posts scoped to trainee's `parent_trainer`. Ordered by `-created_at`. Paginated (page size 20). Each post includes: `id`, `author` object (`id`, `first_name`, `last_name`, `profile_image`), `content`, `post_type`, `metadata`, `created_at`, `reactions` (dict of counts: `{fire: N, thumbs_up: N, heart: N}`), `user_reactions` (list of reaction_types the current user has given). Uses `select_related('author')` and aggregated annotation for reaction counts (no N+1). Returns empty list if trainee has no `parent_trainer`.
- [ ] **AC-24**: Create post endpoint `POST /api/community/feed/`: Body `{content: string}`. `post_type` auto-set to `text`. `trainer` auto-set from `request.user.parent_trainer`. Content required, max 1000 chars, whitespace-stripped. Returns 400 if trainee has no `parent_trainer` with error "You must be part of a trainer's group to post." Requires `[IsAuthenticated, IsTrainee]`.
- [ ] **AC-25**: Delete post endpoint `DELETE /api/community/feed/<id>/`: Author can delete own post. Trainer can delete any post in their group (for moderation -- requires `[IsAuthenticated]` and custom permission check: `post.author == request.user OR (request.user.is_trainer() and post.trainer == request.user)`). Returns 204.
- [ ] **AC-26**: Reaction toggle endpoint `POST /api/community/feed/<post_id>/react/`: Body `{reaction_type: "fire"|"thumbs_up"|"heart"}`. If user already has this reaction, deletes it (toggle off). If not, creates it (toggle on). Returns updated `{reactions: {fire: N, ...}, user_reactions: [...]}`. User must be in the same trainer group as the post (row-level security).
- [ ] **AC-27**: Auto-post service (`backend/community/services/auto_post_service.py`):
  - `create_auto_post(user: User, post_type: str, metadata: dict) -> CommunityPost | None`: Creates a community post if user has `parent_trainer`. Returns None silently if no `parent_trainer`.
  - Auto-post content templates: `workout_completed` -> "Just completed {workout_name}!", `achievement_earned` -> "Earned the {achievement_name} badge!", `weight_milestone` -> "Hit a weight milestone!".
  - Called after workout completion and after achievement is earned.

**Mobile (Trainee):**

- [ ] **AC-28**: Bottom navigation "Forums" tab renamed to "Community". Icon: `people_outlined` / `people` (active). Route changed from `/forums` to `/community`. The `ForumsScreen` placeholder is replaced.
- [ ] **AC-29**: Community feed screen: scrollable list with pull-to-refresh and infinite scroll. Each post card: author avatar (CircleAvatar with initials fallback), author first name, relative timestamp, content text, post type indicator for auto-posts (subtle label + icon above content: workout icon for `workout_completed`, trophy for `achievement_earned`, scale for `weight_milestone`), reaction bar at bottom.
- [ ] **AC-30**: Compose text post via FAB (edit/pencil icon). Opens a bottom sheet with TextField (max 1000 chars, character counter, `maxLines: 5`), "Post" button. Empty content validation. Loading state on submit (disabled field + spinner on button). Success: dismiss sheet, prepend to feed, snackbar "Posted!". Error: snackbar with error, content preserved. Sheet dismissed on successful post.
- [ ] **AC-31**: Reaction buttons (fire, thumbs up, heart) below each post with counts. Tapping toggles (optimistic update). Active reactions: filled icon + primary color. Inactive: outlined icon + muted color. Count updates immediately. Reverts on API error with snackbar "Couldn't update reaction."
- [ ] **AC-32**: Auto-posts have distinct visual: slightly tinted background (`primary.withOpacity(0.05)`), type label above content ("Workout Completed" / "Achievement Earned" / "Weight Milestone") with matching icon. Not composed by user -- no delete option for auto-posts except by trainer.
- [ ] **AC-33**: Long-press on own text post shows "Delete" option. Confirmation dialog: "Delete this post? This cannot be undone." Trainer (via impersonation) can delete any post. Optimistic removal with undo snackbar (5 seconds).

**Mobile (Trainer):**

- [ ] **AC-34**: Trainer dashboard shows a "Community" info card with "Posts today: N" stat. Tapping shows a snackbar "Use Login as Trainee to moderate the community feed." (Trainer moderation is via impersonation for V1.)

---

## Edge Cases

1. **Trainee with no parent_trainer**: Announcements show "Join a trainer to see announcements" empty state. Community feed shows "Join a trainer to connect with the community" empty state. Cannot create posts (API 400). Achievements system works independently (user still earns badges).

2. **Trainer with zero trainees**: Announcements CRUD works normally (pre-create before inviting). Community feed has no posts. Dashboard community card shows "0 posts today."

3. **Trainee switches trainers (parent_trainer changed)**: Trainee sees new trainer's announcements and community. Old posts remain in DB but are invisible (filtered by current `parent_trainer`). Achievement data persists (user-owned, not trainer-scoped). `AnnouncementReadStatus` for old trainer becomes inert.

4. **Concurrent reaction toggle**: Two users toggling the same reaction simultaneously. `unique_together` constraint prevents duplicates. `get_or_create` + `delete` pattern handles race conditions. IntegrityError caught and treated as a no-op.

5. **Achievement double-award prevention**: `unique_together` on `UserAchievement(user, achievement)` prevents duplicates. Service uses `get_or_create`. Concurrent `check_and_award_achievements` calls are safe -- IntegrityError is caught and ignored.

6. **Very long content at max length**: Backend enforces 200 char title / 2000 char body (announcements), 1000 char content (posts). Mobile enforces same with character counters. Counter turns amber at 90% capacity. Content over limit rejected with validation error.

7. **Deleted user's posts in feed**: `on_delete=CASCADE` removes posts and reactions when user account is deleted. Feed updates on next fetch. Deactivated users' posts remain visible but they cannot create new ones.

8. **Paginated feed with new posts**: Pull-to-refresh resets to page 1. Posts already loaded on later pages may shift. Acceptable for V1 (no real-time updates).

9. **Auto-post for user without parent_trainer**: Workout completed but no `parent_trainer` -- `create_auto_post` returns None silently. Achievement is still awarded. No error.

10. **Empty achievement table (seed not run)**: Achievements endpoint returns empty list. Mobile shows "No achievements available yet." empty state. `check_and_award_achievements` returns empty list gracefully.

11. **Announcement pinning limit**: No explicit limit on pinned announcements. If trainer pins 20 announcements, they all show first in the list. This is by design -- the trainer controls their content curation.

12. **User reacts and immediately navigates away**: Optimistic reaction update is in local state. If the API call fails after navigation, the stale state is corrected on next feed load. No ghost reactions persist.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Network error loading announcements | Error card with "Couldn't load announcements" + Retry button | Log error, show inline error widget |
| Network error creating announcement | Snackbar "Failed to create announcement. Please try again." | Keep form data, re-enable submit button |
| Network error loading community feed | Error card with "Couldn't load the feed" + Retry button | Log error, show inline error widget |
| Network error creating post | Snackbar "Failed to post. Please try again." | Keep content in compose sheet, re-enable Post button |
| Network error toggling reaction | Silently revert optimistic update, snackbar "Couldn't update reaction." | Revert count and active state to pre-toggle values |
| Network error loading achievements | Error card with "Couldn't load achievements" + Retry button | Log error, show inline error widget |
| 400 from create post (no parent_trainer) | Snackbar "You need to be part of a trainer's group to post." | Parse validation error from API response |
| 404 from delete post (already deleted) | Snackbar "This post has already been removed." | Remove post from local state |
| 403 from delete post (not author/trainer) | Snackbar "You don't have permission to delete this post." | No local state change |
| Achievement check fails (DB error) | No user-visible effect | Log error, do not block parent operation (workout save succeeds) |
| Unread count fetch fails | Bell icon shows no badge (defaults to 0) | Log error, fail silently |

---

## UX Requirements

### Loading States
- **Announcements list (trainer/trainee)**: 3 shimmer skeleton cards matching card layout (title bar + 2-line body placeholder + timestamp).
- **Community feed**: 3 shimmer skeleton post cards (avatar circle + name bar + 3-line content + reaction bar).
- **Achievements grid**: 6 shimmer circles in 3x2 grid matching badge size.
- **Create announcement / create post**: Submit button replaces text with `CircularProgressIndicator` (16dp), all form fields disabled via `fieldset` pattern.
- **Reaction toggle**: Immediate optimistic update. No loading indicator.

### Empty States
- **Announcements (trainee, has trainer)**: Megaphone icon + "No announcements from your trainer yet."
- **Announcements (trainee, no trainer)**: Person_add icon + "Join a trainer to see announcements."
- **Announcements (trainer)**: Campaign icon + "No announcements yet." + "Create Announcement" button.
- **Community feed (has trainer)**: Groups icon + "No posts yet. Be the first to share!" + compose FAB visible.
- **Community feed (no trainer)**: Group_add icon + "Join a trainer to connect with the community."
- **Achievements (no achievements seeded)**: Emoji_events icon + "No achievements available yet."
- **Achievements (none earned)**: Full grid in grayscale. Header: "Complete workouts, log nutrition, and stay consistent to earn badges!"

### Error States
- Inline error cards with icon + message + Retry button (consistent with existing home screen error pattern from `_buildRecentWorkoutsSection`).
- Snackbar for action errors (create, delete, react) -- 4-second auto-dismiss.

### Success Feedback
- **Announcement created**: Pop back + snackbar "Announcement created".
- **Announcement updated**: Pop back + snackbar "Announcement updated".
- **Announcement deleted**: Animated removal from list + snackbar "Announcement deleted".
- **Post created**: Dismiss sheet, prepend to feed + snackbar "Posted!"
- **Post deleted**: Animated removal + snackbar "Post deleted" with 5s undo.
- **Achievement earned**: SnackBar with trophy icon + "Achievement Unlocked: {name}" (4s auto-dismiss, staggered if multiple).

### Mobile Behavior
- All lists use pull-to-refresh.
- Community feed and announcements use infinite scroll pagination (consistent with existing workout history pattern).
- Achievement grid: 3 columns, `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount`.
- Compose post uses bottom sheet (not full screen) for quick access.
- Character counters turn amber at 90% of max length (consistent with program builder pattern).
- Reaction buttons: 48dp minimum touch targets.
- All interactive elements have `Semantics` labels for accessibility.
- Announcement cards on home screen are dismissible (swipe right to dismiss from view, not delete).

---

## Technical Approach

### New Django App: `community`

Create a new `community` Django app to house all social/community models. This keeps Phase 7 features cleanly separated from `trainer` and `workouts` apps.

**Files to create:**
- `backend/community/__init__.py`
- `backend/community/apps.py` -- Django AppConfig
- `backend/community/models.py` -- `Announcement`, `AnnouncementReadStatus`, `Achievement`, `UserAchievement`, `CommunityPost`, `PostReaction`
- `backend/community/serializers.py` -- Serializers for all models
- `backend/community/views.py` -- Views for trainee-facing community endpoints
- `backend/community/urls.py` -- URL patterns under `/api/community/`
- `backend/community/admin.py` -- Admin site registration
- `backend/community/services/__init__.py`
- `backend/community/services/achievement_service.py` -- `check_and_award_achievements()`
- `backend/community/services/auto_post_service.py` -- `create_auto_post()`
- `backend/community/management/__init__.py`
- `backend/community/management/commands/__init__.py`
- `backend/community/management/commands/seed_achievements.py` -- Seed command
- `backend/community/migrations/` -- Auto-generated

**Trainer announcement views** go in `backend/trainer/` (consistent with existing trainer notification views pattern):
- `backend/trainer/announcement_views.py` -- Trainer CRUD for announcements

**Files to modify:**
- `backend/config/settings.py` -- Add `'community'` to `INSTALLED_APPS`
- `backend/config/urls.py` -- Add `path('api/community/', include('community.urls'))`
- `backend/trainer/urls.py` -- Add announcement CRUD URL patterns
- `backend/trainer/serializers.py` -- Add `AnnouncementSerializer` for trainer CRUD
- Workout save views/services -- Add `check_and_award_achievements()` call + `create_auto_post()` call after workout save
- Nutrition save views/services -- Add `check_and_award_achievements()` call after nutrition save
- Weight check-in view -- Add `check_and_award_achievements()` call after weight save

### Mobile

**Files to create:**
- `mobile/lib/features/community/` -- New feature directory
  - `data/models/announcement_model.dart` -- Announcement, AnnouncementUnreadCount
  - `data/models/achievement_model.dart` -- Achievement, UserAchievement
  - `data/models/community_post_model.dart` -- CommunityPost, PostReaction
  - `data/repositories/announcement_repository.dart` -- CRUD + unread + mark-read
  - `data/repositories/achievement_repository.dart` -- List + recent
  - `data/repositories/community_feed_repository.dart` -- Feed + create + delete + react
  - `presentation/providers/announcement_provider.dart` -- StateNotifier for announcement list + unread count
  - `presentation/providers/achievement_provider.dart` -- StateNotifier for achievement grid
  - `presentation/providers/community_feed_provider.dart` -- StateNotifier for feed + compose + reactions
  - `presentation/screens/announcements_screen.dart` -- Trainee full announcements list
  - `presentation/screens/achievements_screen.dart` -- Trainee badge grid
  - `presentation/screens/community_feed_screen.dart` -- Community feed (replaces ForumsScreen)
  - `presentation/widgets/announcement_card.dart` -- Reusable announcement card
  - `presentation/widgets/achievement_badge.dart` -- Badge grid item (earned/locked states)
  - `presentation/widgets/community_post_card.dart` -- Feed post card
  - `presentation/widgets/compose_post_sheet.dart` -- Bottom sheet for creating posts
  - `presentation/widgets/reaction_bar.dart` -- Fire/thumbs_up/heart row with counts
- `mobile/lib/features/trainer/presentation/screens/trainer_announcements_screen.dart` -- Trainer announcement management list
- `mobile/lib/features/trainer/presentation/screens/create_announcement_screen.dart` -- Create/edit announcement form

**Files to modify:**
- `mobile/lib/core/constants/api_constants.dart` -- Add 10 new endpoint constants:
  - `trainerAnnouncements`, `trainerAnnouncementDetail(id)`
  - `communityAnnouncements`, `communityAnnouncementsUnreadCount`, `communityAnnouncementsMarkRead`
  - `communityAchievements`, `communityAchievementsRecent`
  - `communityFeed`, `communityFeedDelete(id)`, `communityFeedReact(postId)`
- `mobile/lib/core/router/app_router.dart` -- Add routes: `/announcements`, `/achievements`, `/trainer/announcements`, `/trainer/announcements/create`. Change `/forums` to `/community` in the StatefulShellRoute.
- `mobile/lib/shared/widgets/main_navigation_shell.dart` -- Rename "Forums" to "Community", icon `forum_outlined` -> `people_outlined`, `forum` -> `people`.
- `mobile/lib/features/home/presentation/screens/home_screen.dart` -- Add announcements section above Nutrition. Update bell icon with unread badge count. Add `_buildAnnouncementsSection()`.
- `mobile/lib/features/home/presentation/providers/home_provider.dart` -- Add `List<AnnouncementSummary> recentAnnouncements` and `int unreadAnnouncementCount` to `HomeState`. Fetch on `loadDashboardData()`.
- `mobile/lib/features/settings/presentation/screens/settings_screen.dart` -- Add achievements tile to trainee settings between TRACKING and SUBSCRIPTION sections.
- `mobile/lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` -- Add "Announcements" and "Community" summary sections.

### URL Structure

**Trainer endpoints (under `/api/trainer/`):**
```
GET/POST    /api/trainer/announcements/
GET/PUT/PATCH/DELETE  /api/trainer/announcements/<id>/
```

**Community endpoints (under `/api/community/`):**
```
GET         /api/community/announcements/
GET         /api/community/announcements/unread-count/
POST        /api/community/announcements/mark-read/
GET         /api/community/achievements/
GET         /api/community/achievements/recent/
GET/POST    /api/community/feed/
DELETE      /api/community/feed/<id>/
POST        /api/community/feed/<id>/react/
```

### Migration Considerations
- All 6 new models go in `community` app's `0001_initial.py` migration.
- No schema changes to existing models (User, DailyLog, WeightCheckIn, etc.).
- `seed_achievements` must be run after migration to populate the achievements table.
- All ForeignKeys use `on_delete=CASCADE` except `Announcement.trainer` and `CommunityPost.trainer` which should use `on_delete=CASCADE` (if trainer is deleted, their announcements and community group are deleted).
- Migrations are forward-only with no cross-app dependencies on data.

### Row-Level Security Summary

| Endpoint | Security Rule |
|----------|---------------|
| `GET /api/community/announcements/` | Filter by `trainer = user.parent_trainer` |
| `GET /api/community/feed/` | Filter by `trainer = user.parent_trainer` |
| `POST /api/community/feed/` | Auto-set `trainer = user.parent_trainer`; reject 400 if null |
| `DELETE /api/community/feed/<id>/` | `post.author == user` OR `(user.is_trainer() and post.trainer == user)` |
| `POST /api/community/feed/<id>/react/` | Post's `trainer == user.parent_trainer` |
| `GET /api/trainer/announcements/` | Filter by `trainer = request.user` |
| `PUT/DELETE /api/trainer/announcements/<id>/` | `announcement.trainer == request.user` |
| `GET /api/community/achievements/` | Achievements are global; `earned` flag is per-user via LEFT JOIN on `UserAchievement` |

### Key Design Decisions

1. **New `community` Django app**: Keeps social features cleanly separated from trainer management and workout/nutrition tracking. Follows the project's app-per-domain pattern (users, workouts, trainer, subscriptions, ambassador).

2. **Trainer announcement views in `trainer` app, trainee-facing views in `community` app**: Consistent with how `TrainerNotification` views live in `trainer/notification_views.py`. The trainer manages announcements in their dashboard context; trainees consume them in the community context.

3. **`AnnouncementReadStatus` for unread tracking**: A single row per (user, trainer) with a `last_read_at` timestamp is much more efficient than tracking per-announcement read status. Announcements with `created_at > last_read_at` are unread. This scales to thousands of announcements without bloating a join table.

4. **Community feed scoped by `trainer` FK, not a separate "group" model**: The trainer IS the group. Every trainer's trainees form an implicit community. This avoids over-engineering a group/channel system for V1. If multi-group support is needed later, the `trainer` FK can be replaced with a `group` FK without changing the feed logic.

5. **Achievement checking is synchronous but non-blocking**: The `check_and_award_achievements` function runs after the primary operation (workout save, etc.) succeeds. It's wrapped in try-except so failures never block the user's action. Newly earned achievements are returned in the response so the mobile app can show toast notifications without a separate API call.

6. **Auto-posts are write-and-forget**: Created silently. If `create_auto_post` fails (no parent_trainer, DB error), it fails silently. The primary action (workout save, achievement award) is never blocked.

7. **Reaction toggle pattern (create-or-delete)**: Instead of a separate "add reaction" and "remove reaction" endpoint, a single `react` endpoint toggles. This matches common UX patterns (tap to like, tap again to unlike) and reduces mobile client complexity.

8. **No comments in V1**: Reactions are enough social signal for an initial launch. Comments add significant complexity (threading, moderation, notifications, rich text). Reactions provide 80% of the engagement value with 20% of the complexity.

---

## Out of Scope

- Push notifications for announcements, achievements, or community posts (in-app only for V1)
- Rich text / markdown in announcements or posts
- Image / video attachments on posts
- Comment threads on community posts (reactions only for V1)
- Leaderboards (Phase 7 item, deferred to future pipeline)
- Real-time updates / WebSocket for feed (pull-to-refresh only)
- Blocking / muting users in community feed
- Post editing (delete and re-create for V1)
- Trainer-custom achievements (pre-defined only)
- Retroactive achievement awarding for past activity before this feature ships
- Web dashboard community views (mobile-only for V1)
- Dedicated trainer community moderation screen (uses impersonation flow for V1)
- Community post reporting / flagging system
- Achievement progress percentages (earned: yes/no only, no "3 of 10 workouts" progress bars)
