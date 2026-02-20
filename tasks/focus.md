# Pipeline 24 Focus: Message Search

## Priority
Add full-text message search across all conversations on both the Django backend and Next.js web dashboard. Trainers need to quickly find past messages with trainees — whether it's a specific workout instruction, a nutrition note, or a scheduling discussion.

## Why This Feature
1. **Core messaging expectation** — Every messaging platform (Slack, WhatsApp, iMessage, Discord) has search. Users expect it.
2. **High daily utility** — Trainers managing 10-50+ trainees need to find past conversations and specific messages quickly. Scrolling through history is not viable.
3. **Builds on completed foundation** — Pipelines 20-23 shipped full messaging with real-time WebSocket, images, edit/delete. Search is the natural next step.
4. **Manageable scope** — Backend search endpoint + web UI. No new models needed — just query the existing Message table.

## Scope
- Backend: New search endpoint that searches across ALL conversations for the authenticated user, with pagination and conversation context
- Web: Global search UI in the messages page — search bar, results list with conversation context, click-to-navigate to specific message
- Both: Highlight matching text in results, show message context (sender, timestamp, conversation)

## What NOT to build
- Mobile (Flutter) search — defer to next pipeline
- Full-text search indexes (PostgreSQL tsvector) — icontains is sufficient for current scale
- Advanced filters (date range, sender filter, has:image) — future enhancement
- Search within a single conversation only — do global search across all conversations
