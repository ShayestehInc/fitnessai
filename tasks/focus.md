# Pipeline 21 Focus: File/Image Attachments in Direct Messages

## Priority
Add image attachment support to the direct messaging system across all three stacks (Django backend, Flutter mobile, Next.js web). This is the single highest-impact follow-up to the messaging system shipped in Pipeline 20.

## Why This Feature
1. **Messaging without images feels incomplete** — Trainers need to share form check photos, meal plans, progress photos, and quick visual feedback with clients
2. **Patterns already exist** — Community feed has full image upload/display pipeline (backend UUID paths, mobile ImagePicker + InteractiveViewer, validation)
3. **Infrastructure is in place** — WebSocket broadcasts, multipart upload, image storage all proven
4. **Direct impact on engagement** — Visual communication is higher-engagement than text-only
5. **Natural follow-up** — Pipeline 20 shipped messaging; this completes the messaging experience

## Scope
- Backend: Add `image` field to Message model, multipart upload on send endpoint, image URL in serializer, WebSocket broadcast includes image
- Mobile: Image picker button in chat input, image display in message bubbles, full-screen viewer, client-side compression/validation
- Web: Image upload button in message input, image display in message bubbles, lightbox/modal viewer
- Thumbnails: Generate thumbnail for conversation list preview

## What NOT to build
- Video attachments (future phase)
- Multiple images per message (one image per message for v1)
- File attachments (PDF, docs — future phase)
- Image editing/cropping before send
- Image compression on backend (client-side only)
