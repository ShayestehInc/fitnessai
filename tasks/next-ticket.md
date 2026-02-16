# Feature: Phase 8 Community & Platform Enhancements (7 Features)

## Priority
High

## User Story
As a **trainee**, I want leaderboards, push notifications, rich text posts, image attachments, comment threads, and a real-time feed so that the community experience is engaging and keeps me coming back daily.

As a **trainer**, I want to control leaderboards, broadcast rich announcements, and see an active community so that trainee retention improves.

As an **ambassador**, I want to receive payouts via Stripe Connect so that I get paid for my referrals without manual bank transfers.

As an **admin**, I want to trigger ambassador payouts so that the commission process is streamlined.

---

## Acceptance Criteria

### Feature 1: Leaderboards

- [ ] **AC-1**: `Leaderboard` model exists in `community` app with fields: `trainer` (FK to User, TRAINER, CASCADE), `metric_type` (CharField, choices: `workout_count`, `current_streak`), `time_period` (CharField, choices: `weekly`, `monthly`), `is_enabled` (BooleanField, default True), `created_at`, `updated_at`. Table name: `leaderboards`. UniqueConstraint on `(trainer, metric_type, time_period)`. Index on `(trainer, is_enabled)`.
- [ ] **AC-2**: `leaderboard_opt_in` BooleanField added to `UserProfile` model (default True). Migration adds column with default value -- no data migration needed.
- [ ] **AC-3**: `GET /api/community/leaderboard/` returns ranked leaderboard entries for the trainee's trainer group. Required query params: `metric` (`workout_count` or `current_streak`), `period` (`weekly` or `monthly`). Response: `{metric, period, entries: [{rank, user_id, first_name, last_name, profile_image, value}]}`. Only includes trainees where `leaderboard_opt_in=True` and the corresponding `Leaderboard.is_enabled=True` for the trainer. Returns 400 if metric or period param missing/invalid. Returns empty entries list if trainee has no `parent_trainer`. Requires `[IsAuthenticated, IsTrainee]`. Row-level security: scoped by `parent_trainer`. Leaderboard computation uses aggregate queries on `DailyLog` (workout_count: count distinct dates with non-null `workout_data` in the time window; current_streak: consecutive calendar days ending today with workout_data). Time window: `weekly` = last 7 days, `monthly` = last 30 days.
- [ ] **AC-4**: `GET /api/trainer/leaderboard-settings/` returns list of 4 leaderboard configs (2 metrics x 2 periods) for the trainer. Auto-creates all 4 with `is_enabled=True` on first GET if none exist. `PUT /api/trainer/leaderboard-settings/` accepts `{metric_type, time_period, is_enabled}` to toggle individual configs. Requires `[IsAuthenticated, IsTrainer]`. Row-level security: filters by `trainer=request.user`.
- [ ] **AC-5**: `PUT /api/users/profiles/leaderboard-opt-in/` toggles the trainee's `leaderboard_opt_in` flag. Request body: `{leaderboard_opt_in: bool}`. Response: `{leaderboard_opt_in: bool}`. Requires `[IsAuthenticated, IsTrainee]`.
- [ ] **AC-6**: Mobile leaderboard screen accessible from community feed app bar (trophy icon). Two segmented controls at top: metric selector (Workouts / Streak) and period selector (Weekly / Monthly). List of entries: rank number, avatar with initials fallback, full name, metric value with label ("workouts" or "day streak"). Current user's entry highlighted with primary color background tint. Entries sorted by value descending, rank assigned sequentially. Loading: skeleton shimmer list. Empty: trophy icon + "No participants yet" + "Be the first to log a workout!" Error: error icon + message + Retry. Pull-to-refresh. Semantics labels on all entries.
- [ ] **AC-7**: Trainer settings screen has "Leaderboards" section with 4 toggle switches: "Weekly Workout Count", "Monthly Workout Count", "Weekly Streak", "Monthly Streak". Each toggle calls the PUT endpoint. Loading overlay while saving. Success: switch animates. Error: revert switch with snackbar.
- [ ] **AC-8**: Trainee settings screen has "Leaderboard" tile (between "Achievements" and "Subscription"). Toggle switch: "Show me on leaderboards" with helper text "When off, you won't appear in your group's rankings." Calls PUT endpoint. Optimistic toggle with revert on error.

### Feature 2: Push Notifications (FCM)

- [ ] **AC-9**: `DeviceToken` model exists in `users` app with fields: `user` (FK to User, CASCADE), `token` (CharField max_length=512), `platform` (CharField, choices: `ios`, `android`, `web`), `is_active` (BooleanField, default True), `created_at`, `updated_at`. Table name: `device_tokens`. UniqueConstraint on `(user, token)`. Index on `(user, is_active)`.
- [ ] **AC-10**: `POST /api/users/device-tokens/` registers or updates a device token. Body: `{token: string, platform: string}`. Upsert pattern: if (user, token) exists, update `is_active=True` and `platform`. If not, create. Returns `{id, token, platform, is_active}`. `DELETE /api/users/device-tokens/` removes a token. Body: `{token: string}`. Marks `is_active=False` (soft delete). Returns 204. Both require `[IsAuthenticated]`.
- [ ] **AC-11**: `notification_service.py` in `core/services/` wraps `firebase-admin` SDK. Key functions: `send_push_notification(user_id: int, title: str, body: str, data: dict) -> bool` -- sends to all active tokens for user, returns True if at least one delivery succeeded; `send_push_to_group(user_ids: list[int], title: str, body: str, data: dict) -> int` -- sends to group, returns count of users reached. Both handle `messaging.UnregisteredError` and `messaging.SenderIdMismatchError` by marking token `is_active=False`. Firebase app initialized lazily from `FIREBASE_CREDENTIALS_PATH` env var. Uses `send_each()` for batched delivery (max 500 per batch). All errors logged at WARNING level. Never raises -- returns False/0 on complete failure.
- [ ] **AC-12**: Push notification fired when trainer creates a new announcement (in `TrainerAnnouncementListCreateView.post()` after successful creation). Recipients: all active trainees of that trainer. Title: "New Announcement from {trainer_name}". Body: truncated announcement title (first 100 chars). Data: `{"type": "announcement", "trainer_id": "{id}"}`. Fire-and-forget pattern (does not block response).
- [ ] **AC-13**: Push notification fired when a user earns a new achievement (in `check_and_award_achievements` after successful award). Title: "Achievement Unlocked!". Body: achievement name. Data: `{"type": "achievement", "achievement_id": "{id}"}`.
- [ ] **AC-14**: Push notification fired when someone reacts to your community post (in `ReactionToggleView` after successful create, not on remove). Title: "{reactor_name} reacted to your post". Body: first 50 chars of post content. Data: `{"type": "post_reaction", "post_id": "{id}"}`. Debounce: cache key `push_reaction_{post_id}_{author_id}` with 5-minute TTL (use Django cache framework). Skip if cache key exists.
- [ ] **AC-15**: Mobile requests notification permission on first visit to community feed screen. Shows a custom explanation bottom sheet BEFORE the system prompt: title "Stay in the Loop", body listing 3 benefits (announcements, achievements, reactions), "Enable Notifications" primary button triggers system prompt, "Not Now" text button dismisses. Permission state cached in SharedPreferences key `push_permission_asked`. If already asked, skip the sheet on subsequent visits.
- [ ] **AC-16**: Mobile registers FCM token on successful login and on app launch (if logged in). Uses `firebase_messaging` `getToken()`. Sends to `POST /api/users/device-tokens/` with platform detection. Listens to `onTokenRefresh` stream and re-registers on token change. On logout, calls `DELETE /api/users/device-tokens/` to deactivate current token. All FCM operations wrapped in try-catch -- never blocks auth flow.
- [ ] **AC-17**: Mobile handles foreground notifications with `onMessage` listener. Shows a material banner at top of screen (not system notification): icon + title + body. Auto-dismiss after 4 seconds. Tapping navigates to relevant screen based on `data.type`: `announcement` -> `/community/announcements`, `achievement` -> `/community/achievements`, `post_reaction` -> `/community` (scrolls to post if visible), `comment` -> `/community` (opens comment sheet for post).
- [ ] **AC-18**: Mobile handles background/terminated notifications via `onMessageOpenedApp` and `getInitialMessage()`. Tapping notification navigates to relevant screen via deep link data (same routing as AC-17). `getInitialMessage()` checked once in splash screen flow.
- [ ] **AC-19**: `firebase-admin~=6.4.0` added to `requirements.txt`. `FIREBASE_CREDENTIALS_PATH` env var added to `settings.py` (reads from env, defaults to empty string). `firebase_messaging: ^15.1.0` and `firebase_core: ^3.4.0` added to `pubspec.yaml`.

### Feature 3: Rich Text / Markdown

- [ ] **AC-20**: `content_format` CharField added to `Announcement` model. Choices: `plain`, `markdown`. Default: `plain`. Max length 10.
- [ ] **AC-21**: `content_format` CharField added to `CommunityPost` model. Same choices and default as AC-20.
- [ ] **AC-22**: `AnnouncementSerializer` and `AnnouncementCreateSerializer` include `content_format` field. Validates against allowed choices. Read and write.
- [ ] **AC-23**: `CreatePostSerializer` accepts optional `content_format` field (default `plain`). Validates against allowed choices. `CommunityFeedView.post()` passes it to `CommunityPost.objects.create()`. Feed serialization includes `content_format` in response.
- [ ] **AC-24**: Mobile renders post/announcement content conditionally: if `content_format == 'markdown'`, render with `flutter_markdown` `MarkdownBody` widget (no scrolling -- embedded in card). If `plain`, render with standard `Text` widget. Markdown style inherits from app theme (heading sizes, link color = primary, code block background).
- [ ] **AC-25**: Mobile compose post sheet has a markdown toggle icon button (format icon) in the toolbar area above the text field. When enabled: shows a horizontal markdown toolbar row with 4 buttons: Bold (**), Italic (*), Link ([]()),  Bullet List (-). Each button inserts the corresponding markdown syntax at the current cursor position (wrapping selected text for bold/italic). A "Preview" toggle shows rendered markdown below the input. Toggle state persists within the sheet session but resets on close.
- [ ] **AC-26**: Trainer create/edit announcement form has the same markdown toggle and toolbar (reusable `MarkdownToolbar` widget). Preview mode shows rendered announcement body.
- [ ] **AC-27**: `flutter_markdown: ^0.7.3` added to `pubspec.yaml`.

### Feature 4: Image Attachments on Posts

- [ ] **AC-28**: `image` ImageField added to `CommunityPost` model. Nullable, blank. `upload_to` uses UUID-based path function: `community_posts/{uuid_hex}{ext}`. Allowed extensions: `.jpg`, `.jpeg`, `.png`, `.webp`. Default None.
- [ ] **AC-29**: `POST /api/community/feed/` updated to accept `multipart/form-data` (in addition to JSON). Optional `image` field. Validation: max file size 5MB, content-type check (image/jpeg, image/png, image/webp), Pillow `Image.open().verify()` format check, max dimensions 4096x4096. On validation failure: 400 with specific error message ("Image must be under 5MB", "Invalid image format. Use JPEG, PNG, or WebP.", "Image dimensions too large."). UUID filename generation prevents path traversal.
- [ ] **AC-30**: Feed serialization includes `image_url` field. If image exists, returns absolute URL via `request.build_absolute_uri(post.image.url)`. If no image, returns null. Feed `_serialize_posts` method updated to include this field.
- [ ] **AC-31**: Mobile compose post sheet has an "Attach image" icon button (camera icon) next to the markdown toggle. Tapping opens image picker (gallery source). Selected image shows as a thumbnail preview (120dp height, rounded corners) with an "X" remove button overlay. File size displayed below ("2.3 MB"). If over 5MB, show inline error "Image must be under 5MB" and disable Post button. Upload uses `multipart/form-data` via Dio `FormData`. Progress indicator on the image thumbnail during upload.
- [ ] **AC-32**: `CommunityPostCard` displays image below the content text (if `imageUrl` is not null). Image rendered with `ClipRRect` (12dp border radius), constrained max height 250dp, `BoxFit.cover`. Tapping opens full-screen image viewer. Uses `Image.network` with loading placeholder (shimmer rectangle matching container size) and error widget (error icon + "Image could not be loaded" text). `Semantics(image: true, label: 'Post image')`.
- [ ] **AC-33**: Full-screen image viewer screen: dark background, `InteractiveViewer` with min/max scale (1.0 to 4.0), close button (X icon) top-left, hero animation from card using `Hero` tag `post_image_{postId}`. Back gesture (swipe down) dismisses. `Semantics(label: 'Full screen image viewer. Pinch to zoom. Swipe down to close.')`.
- [ ] **AC-34**: Image loading in feed cards shows a shimmer placeholder rectangle matching the container dimensions. Broken/failed images show a subtle error state: grey background + broken image icon + "Image could not be loaded" text. No crash on network timeout or 404.

### Feature 5: Comment Threads

- [ ] **AC-35**: `Comment` model exists in `community` app with fields: `post` (FK to CommunityPost, CASCADE), `author` (FK to User, CASCADE), `content` (TextField, max_length 500), `created_at` (auto_now_add). Table name: `community_comments`. Index on `(post, created_at)`. Index on `(author)`. `ordering = ['created_at']` (oldest first).
- [ ] **AC-36**: `GET /api/community/feed/<post_id>/comments/` returns paginated flat list of comments for a post. Page size 20, ordered oldest first. Each comment: `{id, author: {id, first_name, last_name, profile_image}, content, created_at}`. Row-level security: verify `request.user.parent_trainer == post.trainer` before returning results. Returns 403 if user not in same trainer group. Returns 404 if post not found. Uses `select_related('author')`. Requires `[IsAuthenticated, IsTrainee]`.
- [ ] **AC-37**: `POST /api/community/feed/<post_id>/comments/` creates a comment on a post. Body: `{content: string}`. Content required, max 500 chars, whitespace-stripped, rejects if empty after strip. Row-level security check: `request.user.parent_trainer == post.trainer`. Returns 403 if not in group, 404 if post not found. Returns created comment object (201). Requires `[IsAuthenticated, IsTrainee]`.
- [ ] **AC-38**: `DELETE /api/community/feed/<post_id>/comments/<comment_id>/` deletes a comment. Author can delete own comment. Trainer can delete any comment in their group (`request.user.is_trainer() and post.trainer == request.user`). Returns 204 on success, 403 if no permission, 404 if not found. Requires `[IsAuthenticated]`.
- [ ] **AC-39**: Feed serialization updated to include `comment_count` on each post. Computed via `.annotate(comment_count=Count('comments'))` on the feed queryset. No N+1.
- [ ] **AC-40**: Mobile: `CommunityPostCard` shows a comment icon + count below the reaction bar (or as part of it). Tapping opens a `CommentsBottomSheet` (DraggableScrollableSheet, initialChildSize 0.6, maxChildSize 0.9). Sheet header: "Comments (N)" title + close button. Flat scrollable list of comments. Each comment: author avatar (initials fallback), full name, relative time, content text. Compose input at bottom: TextField + Send icon button. Send disabled when empty/whitespace. Loading: shimmer list. Empty: chat bubble icon + "No comments yet" + "Start the conversation!" Error: inline error + retry.
- [ ] **AC-41**: In the comments bottom sheet, author can delete own comment via long-press context menu with "Delete" option and confirmation dialog. Trainer (via impersonation) sees delete on all comments. Optimistic removal with snackbar "Comment deleted".
- [ ] **AC-42**: Push notification fired when someone comments on your post (in comment creation view, after successful save). Title: "{commenter_name} commented on your post". Body: first 50 chars of comment content. Data: `{"type": "comment", "post_id": "{id}"}`. Debounce: cache key `push_comment_{post_id}_{author_id}` with 5-minute TTL. Skip if cache key exists. Do not notify if commenter is the post author.

### Feature 6: Real-time Feed (WebSocket)

- [ ] **AC-43**: `channels~=4.1.0`, `channels-redis~=4.2.0`, and `daphne~=4.1.0` added to `requirements.txt`. `INSTALLED_APPS` updated to include `'daphne'` (before `django.contrib.staticfiles`) and `'channels'`. `ASGI_APPLICATION = 'config.asgi.application'` added to `settings.py`. `CHANNEL_LAYERS` configured with Redis backend using `REDIS_URL` env var (default `redis://localhost:6379/0`). `REDIS_URL` env var documented.
- [ ] **AC-44**: `CommunityFeedConsumer` (WebSocket JSON consumer) in `community/consumers.py`. `connect()`: extracts JWT token from query string (`?token=<jwt>`), validates via `rest_framework_simplejwt`, rejects with close code 4001 if invalid/expired. Extracts `parent_trainer_id` from authenticated user. Joins room `community_feed_{trainer_id}`. Accepts connection. `disconnect()`: leaves room. No client-to-server message handling needed (receive is a no-op or rejects).
- [ ] **AC-45**: Room naming convention: `community_feed_{trainer_id}`. Authentication enforces that only users whose `parent_trainer_id` matches can join that room. Trainer themselves can also join their own room (`user.id == trainer_id and user.is_trainer()`).
- [ ] **AC-46**: Server broadcasts to room on 4 events: (1) New post: `{"type": "new_post", "post": {full serialized post object}}`. (2) Reaction update: `{"type": "reaction_update", "post_id": int, "reactions": {fire: N, thumbs_up: N, heart: N}}`. (3) New comment: `{"type": "new_comment", "post_id": int, "comment": {serialized comment}, "comment_count": int}`. (4) Post deleted: `{"type": "post_deleted", "post_id": int}`. All messages include a `timestamp` ISO string.
- [ ] **AC-47**: Broadcasts sent from view layer after successful DB operations. `CommunityFeedView.post()` broadcasts `new_post`. `ReactionToggleView.post()` broadcasts `reaction_update`. `CommentListCreateView.post()` broadcasts `new_comment`. `CommunityPostDeleteView.delete()` broadcasts `post_deleted`. Uses `async_to_sync(channel_layer.group_send)()` in synchronous views. Channel layer obtained via `get_channel_layer()`. Broadcast failures logged at WARNING level but never block the HTTP response.
- [ ] **AC-48**: WebSocket URL: `ws://<host>/ws/community/feed/`. Routing defined in `community/routing.py` with `URLRouter([path('ws/community/feed/', CommunityFeedConsumer.as_asgi())])`. `config/asgi.py` updated with `ProtocolTypeRouter` dispatching HTTP to Django ASGI app and WebSocket to the community routing (wrapped with `AllowedHostsOriginValidator`).
- [ ] **AC-49**: Mobile WebSocket service (`core/services/websocket_service.dart`). Connects when community feed screen mounts (`initState`). Disconnects when screen disposes. Uses `web_socket_channel` `WebSocketChannel.connect()` with JWT token in query string. Reconnection with exponential backoff: 1s, 2s, 4s, 8s, 16s, cap at 30s. After 10 consecutive failures, stop reconnecting and show "Connection lost. Pull to refresh." message. Reset backoff on successful connection. `mounted` guard after every async gap.
- [ ] **AC-50**: Mobile processes incoming WebSocket JSON messages. `new_post`: prepend to feed list (check for duplicate by `id` to prevent double-add from HTTP response + WebSocket). `reaction_update`: find post by `post_id` and update reaction counts in place. `new_comment`: find post by `post_id` and increment `comment_count`. `post_deleted`: remove post from feed list by `post_id`. Unknown message types: log and ignore. All state updates go through the `CommunityFeedNotifier`.
- [ ] **AC-51**: `web_socket_channel: ^3.0.0` added to `pubspec.yaml`.

### Feature 7: Stripe Connect Ambassador Payouts

- [ ] **AC-52**: `AmbassadorStripeAccount` model exists in `ambassador` app with fields: `ambassador_profile` (OneToOneField to AmbassadorProfile, CASCADE, related_name `stripe_account`), `stripe_account_id` (CharField max 255, unique, nullable), `charges_enabled` (BooleanField default False), `payouts_enabled` (BooleanField default False), `details_submitted` (BooleanField default False), `onboarding_completed` (BooleanField default False), `created_at`, `updated_at`. Table name: `ambassador_stripe_accounts`. Index on `(ambassador_profile)`.
- [ ] **AC-53**: `PayoutRecord` model exists in `ambassador` app with fields: `ambassador_profile` (FK to AmbassadorProfile, CASCADE), `amount` (DecimalField, max_digits 10, decimal_places 2), `stripe_transfer_id` (CharField max 255, nullable, blank), `status` (CharField, choices: `pending`, `completed`, `failed`, default `pending`), `error_message` (TextField, blank), `commissions_included` (ManyToManyField to AmbassadorCommission, blank), `created_at`. Table name: `ambassador_payout_records`. Index on `(ambassador_profile, -created_at)`.
- [ ] **AC-54**: `GET /api/ambassador/connect/status/` returns the ambassador's Stripe Connect account status. Response: `{has_account: bool, stripe_account_id: str|null, payouts_enabled: bool, charges_enabled: bool, details_submitted: bool, onboarding_completed: bool}`. Returns `{has_account: false, ...nulls...}` if no `AmbassadorStripeAccount` exists. Requires `[IsAuthenticated, IsAmbassador]`.
- [ ] **AC-55**: `POST /api/ambassador/connect/onboard/` creates a Stripe Connect Express account via `stripe.Account.create(type='express', ...)` using the ambassador's email. Stores the `stripe_account_id` in `AmbassadorStripeAccount` (create if needed). Generates an account link via `stripe.AccountLink.create(account=acct_id, type='account_onboarding', return_url=..., refresh_url=...)`. Returns `{onboarding_url: str, stripe_account_id: str}`. If account already exists but onboarding incomplete, generates a fresh account link. Requires `[IsAuthenticated, IsAmbassador]`.
- [ ] **AC-56**: `GET /api/ambassador/connect/return/` called when ambassador returns from Stripe onboarding in their browser. Fetches the Stripe account via `stripe.Account.retrieve(acct_id)` and updates `AmbassadorStripeAccount` fields (`charges_enabled`, `payouts_enabled`, `details_submitted`, `onboarding_completed` = `details_submitted and payouts_enabled`). Returns redirect or JSON status. Requires `[IsAuthenticated, IsAmbassador]`.
- [ ] **AC-57**: `POST /api/admin/ambassadors/<ambassador_id>/payout/` triggers a payout for an ambassador. Service function `PayoutService.create_payout(ambassador_profile_id: int) -> PayoutResult`: (1) validates ambassador has a `AmbassadorStripeAccount` with `payouts_enabled=True`, (2) locks and fetches all APPROVED commissions via `select_for_update()` inside `transaction.atomic()`, (3) if none found returns error, (4) sums commission amounts, (5) creates Stripe Transfer via `stripe.Transfer.create(amount=amount_in_cents, currency='usd', destination=stripe_account_id)`, (6) marks all commissions as PAID, (7) creates `PayoutRecord` with `completed` status and links commissions via M2M, (8) refreshes ambassador's cached stats. On Stripe error: creates `PayoutRecord` with `failed` status and `error_message`, does NOT mark commissions as paid (they remain APPROVED for retry). Returns `{total_amount, commissions_paid, stripe_transfer_id, payout_record_id}`. Requires `[IsAuthenticated, IsAdmin]`.
- [ ] **AC-58**: `GET /api/ambassador/payouts/` returns paginated list of `PayoutRecord` for the ambassador. Each: `{id, amount, status, stripe_transfer_id, error_message, commissions_count, created_at}`. Ordered by `-created_at`. Page size 20. Requires `[IsAuthenticated, IsAmbassador]`. Row-level security: `ambassador_profile__user=request.user`.
- [ ] **AC-59**: Mobile ambassador dashboard shows a "Stripe Connect" card. If no account or not completed: card shows bank icon + "Connect your bank account to receive payouts" + "Set Up" primary button that launches `url_launcher` to open `onboarding_url` in external browser. If account connected and payouts enabled: card shows green checkmark + "Bank account connected" + "View Payouts" button navigating to payout history screen. If account exists but restricted: card shows warning icon + "Account verification pending" + "Complete Setup" button. Fetch status on dashboard load via `GET /api/ambassador/connect/status/`.
- [ ] **AC-60**: Mobile ambassador payout history screen. Paginated list with infinite scroll. Each payout card: amount (large, bold), date (relative), status badge (green "Completed", amber "Pending", red "Failed"), commissions count, stripe transfer ID (truncated, monospace). Empty state: wallet icon + "No payouts yet" + "Payouts will appear here once triggered by admin." Loading: skeleton shimmer list. Error: error card + retry. Pull-to-refresh.
- [ ] **AC-61**: Admin ambassador detail screen shows "Trigger Payout" button. Only visible when: (a) ambassador has a connected Stripe account with `payouts_enabled=True`, and (b) ambassador has at least 1 APPROVED commission. Button shows total payout amount: "Pay Out $X.XX (N commissions)". Tapping opens confirmation dialog: "Transfer $X.XX to {ambassador_name}'s bank account? This will mark N commissions as paid." Confirm button with loading spinner. Success: snackbar "Payout of $X.XX initiated" + refresh detail. Error: snackbar with error message.

---

## Edge Cases

1. **Leaderboard with zero eligible users**: All trainees opted out or trainer disabled the metric. API returns empty `entries` list. Mobile shows "No participants yet" empty state with trophy icon.

2. **Leaderboard tie-breaking**: Two users with the same workout count get the same rank. Next rank skips (1, 2, 2, 4 pattern). Implemented via SQL `DENSE_RANK()` or application-level ranking.

3. **Push notification to user with no active device tokens**: `send_push_notification` returns False silently. No crash, no retry, no error log (this is normal for users who declined permissions).

4. **Push notification with expired/invalid FCM token**: Firebase returns `messaging.UnregisteredError` -- handler marks token `is_active=False`. Next push skips this token. Logged at DEBUG level only.

5. **Markdown content with malicious HTML/script tags**: `flutter_markdown` does not render raw HTML by default -- safe by design. No server-side sanitization needed. If a user types `<script>alert(1)</script>`, it renders as literal text.

6. **Image upload exceeding 5MB**: Backend returns 400 with `{"image": ["Image must be under 5MB."]}` before any processing. Mobile also validates client-side and disables Post button.

7. **Image upload with spoofed MIME type**: Backend validates with both content-type header check AND `Pillow Image.open().verify()`. If Pillow rejects, returns 400 "Invalid image format." UUID filename prevents path traversal.

8. **Comment on a deleted post**: API returns 404 "Post not found." If post was deleted while user was viewing comments, the WebSocket `post_deleted` message closes the comment sheet.

9. **WebSocket connection with expired JWT**: Consumer rejects with close code 4001 and message "Authentication failed." Mobile catches close, refreshes JWT token, and reconnects.

10. **WebSocket reconnection flooding**: Exponential backoff: 1s -> 2s -> 4s -> 8s -> 16s -> 30s (cap). After 10 failures, stop reconnecting. Show "Connection lost. Pull to refresh." No more reconnect attempts until user pulls to refresh or navigates away and back.

11. **Ambassador Stripe Connect payout with restricted account**: `payouts_enabled` check catches this. Returns 400 "Ambassador's Stripe account cannot receive payouts. Complete account verification first."

12. **Admin triggers payout with $0 approved commissions**: `select_for_update()` finds 0 rows. Returns 400 "No approved commissions to pay out."

13. **Race condition: two admins trigger payout simultaneously**: `select_for_update()` inside `transaction.atomic()` blocks the second transaction. Second admin finds 0 APPROVED commissions (already set to PAID by first) and gets "No approved commissions to pay out."

14. **WebSocket message for post not in current view (paginated)**: `new_post` always prepends to list (it is new). `reaction_update` / `new_comment` for unknown `post_id` are silently discarded. No crash.

15. **Firebase credentials file missing**: `notification_service.py` initializes Firebase lazily. If `FIREBASE_CREDENTIALS_PATH` is empty or file doesn't exist, logs WARNING on first push attempt and returns False. All subsequent calls fast-fail until app restart.

---

## Error States

| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Leaderboard API fails | "Could not load leaderboard" + Retry button | Log error, return 500 |
| FCM token registration fails | Nothing (silent) | Log warning, retry on next app launch |
| Push notification delivery fails | Nothing (silent) | Mark invalid tokens inactive, log at DEBUG |
| Image upload too large (client) | "Image must be under 5MB" inline error, Post button disabled | Prevent upload entirely |
| Image upload too large (server) | Snackbar "Image must be under 5MB" | Return 400, reject before storage |
| Image upload invalid format | Snackbar "Invalid image format. Use JPEG, PNG, or WebP." | Return 400, file not stored |
| Comment creation fails | Snackbar "Failed to post comment" | Return error, no partial state |
| Comment on deleted post | Snackbar "This post has been removed" + auto-close comment sheet | Return 404 |
| WebSocket connection refused | No visible change initially; after backoff exhaustion: "Connection lost. Pull to refresh." | Reconnect with exponential backoff, REST still works |
| WebSocket auth failure | No visible change, reconnects with fresh token | Close code 4001, token refresh, reconnect |
| Stripe Connect onboarding abandoned | "Complete your account setup" CTA on next dashboard visit | Account exists with `onboarding_completed=False` |
| Stripe Transfer API failure | Admin sees snackbar with Stripe error message | PayoutRecord created with `failed` status, commissions remain APPROVED |
| Markdown with broken syntax | Renders partially/literally (graceful degradation) | `flutter_markdown` handles gracefully, no crash |
| Redis down (WebSocket) | No real-time updates, REST endpoints still work | Channel layer raises, logged at ERROR, no crash |

---

## UX Requirements

### Loading States
- **Leaderboard**: 8 shimmer skeleton rows (rank circle + name bar + value bar).
- **Comments sheet**: 5 shimmer rows (avatar + name + content).
- **Image in feed**: Shimmer rectangle matching container dimensions (16:9 aspect ratio placeholder).
- **Payout history**: 4 shimmer cards (amount + date + status badge).
- **All new screens**: Never a blank white screen during load. Always skeleton or spinner.

### Empty States
- **Leaderboard (no participants)**: Trophy icon + "No participants yet" + "Be the first to log a workout this week!"
- **Leaderboard (disabled by trainer)**: Lock icon + "Your trainer hasn't enabled this leaderboard."
- **Comments**: Chat bubble icon + "No comments yet" + "Start the conversation!"
- **Payout history**: Wallet icon + "No payouts yet" + "Payouts will appear here once triggered by admin."
- **Image attachment (compose)**: No placeholder. Button visible. After attach: preview shown.

### Error States
- All list screens: inline error card with icon + message + "Retry" button (consistent with existing pattern).
- All action errors: Snackbar with 4-second auto-dismiss (consistent with existing pattern).
- WebSocket: no error UI during backoff. Only "Connection lost" after exhaustion.

### Success Feedback
- **Leaderboard opt-in toggle**: Switch animates + "You'll appear on leaderboards" / "You won't appear on leaderboards" snackbar.
- **Comment posted**: Comment appears in list + auto-scroll to bottom.
- **Comment deleted**: Animated removal + snackbar "Comment deleted".
- **Image attached**: Preview appears immediately.
- **Stripe Connect started**: External browser opens. "Complete setup in Stripe and return here" instruction text.
- **Payout triggered**: Snackbar "Payout of $X.XX initiated" + detail screen refreshes.

### Accessibility
- All new screens: `Semantics` labels on interactive elements.
- Leaderboard entries: `Semantics(label: 'Rank {rank}. {name}. {value} {metric_label}.')`.
- Comment list items: `Semantics(label: '{name} commented: {content}. {time_ago}.')`.
- Image viewer: `Semantics(label: 'Full screen image viewer. Pinch to zoom. Swipe down to close.')`.
- Markdown toolbar buttons: `Semantics(label: 'Bold', button: true)` etc.
- Push notification permission sheet: all text is in semantic tree. Buttons have labels.

### Mobile Behavior
- All new list screens: pull-to-refresh + infinite scroll pagination.
- Comment compose: sticky input at bottom of sheet. Send button disabled when empty. Auto-scroll to new comment.
- Image preview in compose: 120dp max height, 12dp border radius, "X" to remove.
- Markdown toolbar: horizontal scrollable row, 40dp height, icons only (no text labels to save space).
- 48dp minimum touch targets on all new interactive elements.
- Safe area insets respected on all new screens.

---

## Technical Approach

### Backend Changes

**New packages (`requirements.txt`):**
- `firebase-admin~=6.4.0` -- FCM push notifications
- `channels~=4.1.0` -- WebSocket support via Django Channels
- `channels-redis~=4.2.0` -- Redis channel layer backend
- `daphne~=4.1.0` -- ASGI server needed by Channels

**New models (migrations):**

1. `community/migrations/XXXX_add_leaderboard_content_format_image_comment.py`:
   - New `Leaderboard` model
   - New `Comment` model
   - Add `content_format` to `Announcement` (CharField, default `plain`)
   - Add `content_format` to `CommunityPost` (CharField, default `plain`)
   - Add `image` to `CommunityPost` (ImageField, nullable)

2. `users/migrations/XXXX_add_leaderboard_opt_in_device_token.py`:
   - Add `leaderboard_opt_in` to `UserProfile` (BooleanField, default True)
   - New `DeviceToken` model

3. `ambassador/migrations/XXXX_add_stripe_account_payout_record.py`:
   - New `AmbassadorStripeAccount` model
   - New `PayoutRecord` model

All migrations are additive only. New fields have defaults. New models have no data dependencies. Fully backward-compatible. Reversible.

**New files:**

| File | Purpose |
|------|---------|
| `core/services/notification_service.py` | FCM wrapper: `send_push_notification()`, `send_push_to_group()` |
| `community/services/leaderboard_service.py` | Compute leaderboard rankings from DailyLog aggregate queries |
| `community/consumers.py` | WebSocket consumer: JWT auth, room join, broadcast handlers |
| `community/routing.py` | WebSocket URL routing |
| `ambassador/services/payout_service.py` | Stripe Connect account creation, Transfer, PayoutRecord management |

**Modified files:**

| File | Changes |
|------|---------|
| `backend/config/settings.py` | Add `daphne`, `channels` to INSTALLED_APPS. Add `ASGI_APPLICATION`, `CHANNEL_LAYERS`, `FIREBASE_CREDENTIALS_PATH`, `REDIS_URL` |
| `backend/config/asgi.py` | ProtocolTypeRouter with HTTP + WebSocket, JWT auth middleware |
| `backend/config/urls.py` | No change needed if new endpoints added to existing app URL files |
| `backend/community/models.py` | Add `Leaderboard`, `Comment` models. Add `content_format` and `image` fields to existing models |
| `backend/community/serializers.py` | Add `content_format` to existing serializers. New `CommentSerializer`, `LeaderboardEntrySerializer` |
| `backend/community/views.py` | Add `LeaderboardView`, `CommentListCreateView`, `CommentDeleteView`. Update `CommunityFeedView` for multipart + image + comment_count annotation. Add push notification calls. Add WebSocket broadcasts |
| `backend/community/urls.py` | Add leaderboard, comment URL patterns |
| `backend/users/models.py` | Add `leaderboard_opt_in` to `UserProfile`. Add `DeviceToken` model |
| `backend/users/views.py` | Add `DeviceTokenView`, `LeaderboardOptInView` |
| `backend/users/urls.py` | Add device-token and leaderboard-opt-in URL patterns |
| `backend/trainer/views.py` | Add `LeaderboardSettingsView`. Add push notification call in `TrainerAnnouncementListCreateView.post()` |
| `backend/trainer/urls.py` | Add leaderboard-settings URL pattern |
| `backend/ambassador/models.py` | Add `AmbassadorStripeAccount`, `PayoutRecord` models |
| `backend/ambassador/views.py` | Add `AmbassadorConnectStatusView`, `AmbassadorConnectOnboardView`, `AmbassadorConnectReturnView`, `AmbassadorPayoutHistoryView`, `AdminTriggerPayoutView` |
| `backend/ambassador/urls.py` | Add connect and payout URL patterns |
| `backend/requirements.txt` | Add 4 new packages |

### Mobile Changes

**New packages (`pubspec.yaml`):**
- `firebase_messaging: ^15.1.0` -- FCM push notifications
- `firebase_core: ^3.4.0` -- Firebase initialization
- `flutter_markdown: ^0.7.3` -- Markdown rendering in posts/announcements
- `web_socket_channel: ^3.0.0` -- WebSocket client for real-time feed

**New files:**

| File | Purpose |
|------|---------|
| `core/services/push_notification_service.dart` | FCM init, token management, foreground/background handling, deep link routing |
| `core/services/websocket_service.dart` | WebSocket connection manager, reconnection backoff, message parsing |
| `features/community/presentation/screens/leaderboard_screen.dart` | Leaderboard UI with metric/period selectors |
| `features/community/presentation/screens/image_viewer_screen.dart` | Full-screen pinch-to-zoom image viewer |
| `features/community/presentation/widgets/comment_sheet.dart` | Comments DraggableScrollableSheet with compose input |
| `features/community/presentation/widgets/markdown_toolbar.dart` | Reusable markdown editing toolbar (bold/italic/link/list) |
| `features/community/presentation/widgets/markdown_content.dart` | Conditional markdown/plain text renderer widget |
| `features/community/presentation/providers/leaderboard_provider.dart` | Leaderboard state management |
| `features/community/presentation/providers/comment_provider.dart` | Comment state management |
| `features/community/data/models/leaderboard_model.dart` | LeaderboardEntry model |
| `features/community/data/models/comment_model.dart` | Comment model |
| `features/community/data/repositories/leaderboard_repository.dart` | Leaderboard API calls |
| `features/community/data/repositories/comment_repository.dart` | Comment API calls |
| `features/ambassador/presentation/screens/ambassador_connect_screen.dart` | Stripe Connect onboarding CTA |
| `features/ambassador/presentation/screens/ambassador_payout_history_screen.dart` | Payout history list |
| `features/ambassador/data/models/payout_model.dart` | PayoutRecord model |
| `features/ambassador/data/repositories/payout_repository.dart` | Payout and Connect API calls |

**Modified files:**

| File | Changes |
|------|---------|
| `core/constants/api_constants.dart` | Add ~20 new endpoint constants (leaderboard, device-tokens, comments, connect, payouts, leaderboard-settings, leaderboard-opt-in) |
| `core/router/app_router.dart` | Add routes: leaderboard, image viewer, payout history, ambassador connect return |
| `features/community/data/models/community_post_model.dart` | Add `imageUrl`, `contentFormat`, `commentCount` fields to `CommunityPostModel`. Update `fromJson()` and `copyWith()` |
| `features/community/presentation/screens/community_feed_screen.dart` | Add leaderboard trophy icon in app bar. Integrate WebSocket service. Handle WebSocket messages |
| `features/community/presentation/widgets/community_post_card.dart` | Add image display, comment count tap area, markdown rendering via `MarkdownContent` widget |
| `features/community/presentation/widgets/compose_post_sheet.dart` | Add image picker, markdown toggle, markdown toolbar, content_format param, multipart upload |
| `features/community/presentation/providers/community_feed_provider.dart` | WebSocket message handling, image upload support, comment_count tracking |
| `features/community/data/repositories/community_feed_repository.dart` | Update `createPost()` for multipart form data, add comment endpoints |
| `features/settings/presentation/screens/settings_screen.dart` | Add "Leaderboard" opt-in toggle for trainees |
| `features/trainer/presentation/screens/create_announcement_screen.dart` | Add markdown toggle and toolbar |
| `features/ambassador/presentation/screens/ambassador_dashboard_screen.dart` | Add Stripe Connect card with status and CTA |
| `features/admin/presentation/screens/admin_ambassador_detail_screen.dart` | Add "Trigger Payout" button with confirmation dialog |
| `pubspec.yaml` | Add 4 new dependencies |

### Row-Level Security Summary

| Endpoint | Security Rule |
|----------|---------------|
| `GET /api/community/leaderboard/` | Scoped by `parent_trainer`. Only opt-in users. Only enabled metrics. |
| `GET/PUT /api/trainer/leaderboard-settings/` | Filter by `trainer=request.user` |
| `PUT /api/users/profiles/leaderboard-opt-in/` | User's own profile only |
| `POST/DELETE /api/users/device-tokens/` | User's own tokens only |
| `GET/POST /api/community/feed/<post_id>/comments/` | `user.parent_trainer == post.trainer` |
| `DELETE /api/community/feed/<post_id>/comments/<id>/` | Author or group trainer |
| `GET/POST /api/ambassador/connect/*` | Ambassador's own account only |
| `GET /api/ambassador/payouts/` | `ambassador_profile__user=request.user` |
| `POST /api/admin/ambassadors/<id>/payout/` | Admin only |
| WebSocket `community_feed_{trainer_id}` | JWT auth + `parent_trainer_id == trainer_id` |

### Key Design Decisions

1. **Leaderboard computed on read, not materialized**: For V1 with small group sizes (max ~50 trainees per trainer), computing rankings from DailyLog aggregates per request is fast enough. No need for a materialized view or cache layer. If performance becomes an issue, add a 5-minute cache later.

2. **Push notifications are fire-and-forget**: The notification service never blocks the primary operation. If FCM fails, the user still gets their workout saved / announcement created / etc. Push is a best-effort enhancement.

3. **Reaction and comment push debouncing via Django cache**: Using the default cache framework (LocMemCache in dev, Redis in prod) with 5-minute TTL keys prevents notification spam. Simple and effective.

4. **Image upload via Django ImageField, not presigned S3 URLs**: For V1 simplicity, images go through Django (Pillow validation, UUID naming) and are stored on disk or via `django-storages` in production. Presigned URL flow can be added later for large-scale usage.

5. **WebSocket for community feed only**: Not announcements (low frequency, trainee polls on screen open) or achievements (one-time events, push notification is sufficient). Community feed benefits most from real-time because users are actively scrolling and want to see new content appear.

6. **Stripe Connect Express accounts for ambassadors**: Express accounts handle identity verification and payout scheduling on Stripe's side, minimizing our compliance burden. Admin triggers the Transfer; Stripe handles the payout to the ambassador's bank.

7. **PayoutRecord tracks M2M to commissions**: Rather than a FK on each commission pointing to its payout, a M2M on PayoutRecord allows bulk payout tracking and makes it easy to show "which commissions were included in this payout."

8. **Comment model in community app, not a separate app**: Comments are tightly coupled to CommunityPost. No need for a generic "comments" app. If other models need comments later, we can extract then.

---

## Out of Scope

- Video attachments on posts (complex storage/streaming)
- Nested/threaded comment replies (flat only)
- WYSIWYG rich text editor (basic markdown toolbar only)
- Automated payout scheduling (manual admin trigger only)
- Push notification per-category preferences (V1: all or nothing)
- Trainee web access to community features
- Comment editing (create and delete only)
- Leaderboard caching/materialized views (compute on read)
- APNs direct integration (FCM handles both platforms)
- Image cropping/resizing on client (upload as-is)
- Multiple images per post (single image only)
- Blocking/muting users in community feed
- Rich text in comments (plain text only)
- Real-time updates for announcements or achievements (WebSocket for feed only)
- Push notification sounds or custom notification channels
