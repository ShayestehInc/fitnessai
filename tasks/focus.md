# Pipeline 23 Focus: Message Editing and Deletion

## Priority
Add edit and delete capabilities to direct messages across all three stacks (Django backend, Flutter mobile, Next.js web). Users can edit their own messages within a 15-minute window and soft-delete their own messages at any time.

## Why This Feature
1. **Core messaging expectation** — Every modern messaging platform (iMessage, WhatsApp, Slack, Discord) supports edit/delete. Users expect it.
2. **Builds on solid foundation** — Pipelines 20-22 shipped full messaging with WebSocket real-time delivery on both mobile and web. Edit/delete is the natural next step.
3. **Backend + frontend work needed** — Full-stack feature touching models, views, services, WebSocket consumers, mobile UI, and web UI.
4. **High user value** — Correcting typos, removing accidentally sent messages, and cleaning up conversations are daily needs.

## Scope
- Backend: New fields on Message model, edit/delete endpoints, service functions, WebSocket broadcast events
- Mobile: Long-press context menu on messages, edit bottom sheet, delete confirmation, optimistic updates
- Web: Hover action menu on messages, inline edit, delete confirmation, WebSocket event handling
- Both platforms: "(edited)" indicator, "[This message was deleted]" placeholder

## What NOT to build
- Message history/audit trail UI (store original_content for future audit, but no UI to view edit history)
- Admin force-delete (future feature)
- Bulk delete (future feature)
- Unsend (different from delete — would remove for all parties retroactively)
