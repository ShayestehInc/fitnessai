# Pipeline 18 Focus: Phase 8 Enhancements (Items 1-7)

## Priority
Build 7 enhancement features that complete the platform's feature set.

## Items to Build

1. **Leaderboards** — Opt-in, trainer-controlled rankings. Trainee can opt in/out. Trainer configures which metrics to rank (workout count, streak, weight loss %). Weekly/monthly/all-time views. Scoped to trainer's group.

2. **Push Notifications** — For announcements (trainer → trainees), achievements (system → user), community posts (reactions on your post). Backend: Firebase Cloud Messaging integration. Mobile: notification permission, foreground/background handling, deep linking to relevant screen.

3. **Rich Text / Markdown in Announcements and Posts** — Trainer announcements support basic markdown (bold, italic, links, lists). Community posts support the same. Render with a markdown widget in Flutter.

4. **Image / Video Attachments on Community Posts** — Users can attach one image to community posts. Image upload to cloud storage (S3 or similar). Image preview in feed. No video in V1 (too complex for storage/streaming).

5. **Comment Threads on Community Posts** — Users can comment on community feed posts. Flat comments (no nesting). Author + trainer can delete comments. Comment count shown on post card.

6. **Real-time Feed Updates (WebSocket)** — Django Channels for WebSocket support. Live updates to community feed (new posts, new reactions, new comments appear without refresh). Connection management, reconnection logic.

7. **Stripe Connect Payout to Ambassadors** — Ambassador earnings paid out via Stripe Connect. Connect account onboarding flow. Payout scheduling (manual trigger by admin). Dashboard showing payout history.

## Context
- Backend: Django REST Framework with PostgreSQL, existing Stripe integration
- Mobile: Flutter 3.0+ with Riverpod
- Community app just built in Pipeline 17 (models: Announcement, CommunityPost, PostReaction, Achievement, UserAchievement)
- Existing: TrainerNotification model, Stripe Connect basics in subscriptions app
- Ambassador model exists with commission tracking

## Scoping Guidance
This is 7 features — the Product Planner should scope aggressively. Some features can be simplified:
- Leaderboards: start with workout count + streak only (2 metrics)
- Push notifications: FCM only (no APNs directly — use FCM for both platforms)
- Rich text: basic markdown rendering only (no WYSIWYG editor)
- Image attachments: single image per post, simple upload
- Comments: flat only (no nesting, no editing)
- WebSocket: community feed only (not announcements or achievements)
- Stripe Connect: manual admin-triggered payouts only (no automated scheduling)

## What NOT to build
- Trainee web access (item 8 — explicitly excluded)
- Video uploads or streaming
- Nested comment threads
- WYSIWYG rich text editor
- Automated payout scheduling
- Push notification preferences per category (V1: all or nothing)
