# Pipeline 20 Focus: In-App Direct Messaging (Trainer-to-Trainee)

## Priority
Build a complete real-time direct messaging system between trainers and trainees. This is the single highest-impact feature for trainer engagement and client retention.

## Why This Feature
1. **Trainers are the paying customers** — they need private communication with clients about progress, missed workouts, goal adjustments, and motivation
2. **Dead UI already exists** — "Send Message" button on mobile trainee detail screen does nothing (line 128-129 of trainee_detail_screen.dart)
3. **All infrastructure is in place** — Django Channels WebSocket, FCM push notifications, real-time patterns proven in community feed
4. **Direct impact on retention** — Trainers who can message clients retain more clients and stay on the platform longer

## Scope
- Backend: New `messaging` Django app with Conversation + Message models, REST API + WebSocket
- Mobile: New messaging feature module for both trainer and trainee roles
- Web: Messages page in trainer dashboard with conversation list + chat view
- Real-time: WebSocket for instant message delivery + typing indicators
- Push notifications: FCM when recipient is offline
- Read receipts + unread badges

## What NOT to build
- Group messaging / group chats
- Image/file/video attachments in messages
- Message editing or deletion after send
- Message search
- Auto-messages / scheduled messages
- Trainee-to-trainee messaging
