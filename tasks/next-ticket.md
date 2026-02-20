# Feature: Image Attachments in Direct Messages

## Priority
High

## User Story
As a **trainer**, I want to **send images in direct messages to my trainees** so that I can share form check photos, meal plan images, progress comparison screenshots, and visual feedback without leaving the app.

As a **trainee**, I want to **send images in direct messages to my trainer** so that I can share progress photos, food photos, and questions about exercises with visual context.

## Acceptance Criteria

### Backend
- [ ] AC-1: Message model has an optional `image` ImageField with UUID-based upload path (`message_images/{uuid}.{ext}`)
- [ ] AC-2: Database migration adds nullable `image` column to `messaging_message` table
- [ ] AC-3: SendMessageView accepts multipart form data (image + content). Either content or image (or both) must be provided — a completely empty message (no text, no image) is rejected.
- [ ] AC-4: Image validation: JPEG/PNG/WebP only, max 5MB, validated in view before save
- [ ] AC-5: MessageSerializer includes `image` field as absolute URL (SerializerMethodField with request.build_absolute_uri) — returns null when no image
- [ ] AC-6: SendMessageResult dataclass includes `image_url: str | None` field
- [ ] AC-7: WebSocket broadcast of new_message includes image URL in message payload
- [ ] AC-8: StartConversationView also accepts multipart (can send first message with image)
- [ ] AC-9: Existing text-only messages continue to work identically (backward compatible)
- [ ] AC-10: Rate limiting unchanged (30/min applies to image messages too)
- [ ] AC-11: Row-level security unchanged — only conversation participants can see message images
- [ ] AC-12: Impersonation guard unchanged — impersonating users cannot send images
- [ ] AC-13: Push notification for image-only messages shows "Sent a photo" instead of empty content

### Mobile (Flutter)
- [ ] AC-14: Chat input has an image picker button (camera_alt icon) next to the text field
- [ ] AC-15: Tapping image picker opens ImagePicker with gallery source, max 1920x1920, 85% quality compression
- [ ] AC-16: Selected image shows as a thumbnail preview above the text input with an X button to remove
- [ ] AC-17: User can send image-only (no text), text-only, or image+text messages
- [ ] AC-18: Image upload uses multipart form data via ApiClient
- [ ] AC-19: Message bubble displays image with rounded corners (12px radius), max width 75% of screen, max height 300px, BoxFit.cover
- [ ] AC-20: Tapping an image in a message bubble opens full-screen InteractiveViewer (pinch-to-zoom 1.0x-4.0x, black background) — reuse existing pattern from community feed
- [ ] AC-21: Image loading state: shimmer/skeleton placeholder matching image dimensions
- [ ] AC-22: Image error state: broken image icon with "Failed to load image" text
- [ ] AC-23: Optimistic send: image message appears immediately with local file, replaces with server URL on confirmation
- [ ] AC-24: Send failure: message shows retry indicator (same as text message failure)
- [ ] AC-25: Client-side file size validation (5MB max) — shows error snackbar if too large
- [ ] AC-26: Accessibility: image messages have Semantics label "Photo message" or "Photo message with text: [content]"
- [ ] AC-27: MessageModel updated with optional `imageUrl` field

### Web (Next.js)
- [ ] AC-28: Message input has a paperclip/image button for attaching images
- [ ] AC-29: File input accepts image/jpeg, image/png, image/webp only
- [ ] AC-30: Selected image shows as a thumbnail preview above the input area with remove button
- [ ] AC-31: Image upload uses FormData with multipart fetch
- [ ] AC-32: Message bubble displays image with rounded corners, max-width 70%, max-height 300px, object-fit cover
- [ ] AC-33: Clicking an image opens a modal/dialog with the full-size image and close button
- [ ] AC-34: Image loading state: skeleton placeholder
- [ ] AC-35: Client-side file size validation (5MB max) — shows toast if too large
- [ ] AC-36: Message type interface updated with optional `image` field (string URL or null)
- [ ] AC-37: Conversation list preview shows "Sent a photo" for image-only messages

## Edge Cases
1. **Empty message with image** — Must be allowed. Content can be empty string if image is present.
2. **Image + text** — Both displayed: image above text in the message bubble.
3. **Large image file (>5MB)** — Client-side validation rejects with clear error message before upload. Server-side validation as backup.
4. **Unsupported file type (GIF, SVG, BMP)** — Client-side filter on file picker + server-side validation with clear error.
5. **Network failure during image upload** — Message shows as failed with retry option. Image data preserved locally for retry.
6. **Very slow upload on poor connection** — Upload progress indicator on mobile (LinearProgressIndicator). Web shows loading state.
7. **Conversation archived (trainee removed) then image URL accessed** — Image still serves from storage (no cascade delete on files), but row-level security prevents new messages.
8. **Image URL in conversation list preview** — Shows "Sent a photo" text, not raw URL.
9. **Multiple rapid image sends** — Rate limiter at 30/min applies equally to image messages.
10. **WebSocket broadcast with image** — Image URL included in message payload; receiving clients fetch image via URL, no binary data over WebSocket.
11. **Image-only message pushed as notification** — Push notification body shows "Sent a photo" instead of empty/null.
12. **Message with both text and image where text hits 2000 char limit** — Enforce independently: image presence doesn't change text limit.

## Error States
| Trigger | User Sees | System Does |
|---------|-----------|-------------|
| Image >5MB selected | Snackbar/toast: "Image must be under 5MB" | Rejects locally, no API call |
| Invalid file type selected | Snackbar/toast: "Only JPEG, PNG, and WebP images are supported" | Rejects locally, no API call |
| Image upload fails (network) | Message shows failed state with retry icon | Preserves image locally, retry sends same file |
| Server rejects image (validation) | Snackbar/toast with server error message | 400 response, message not created |
| Image URL fails to load (broken) | Broken image icon with "Failed to load" text | Error handler on Image widget |
| Image picker permission denied | Platform permission dialog / settings redirect | No crash, graceful degradation |

## UX Requirements
- **Image picker button:** Icon button (camera_alt on mobile, Paperclip or ImageIcon on web) positioned to the left of the text field send button
- **Thumbnail preview:** Shows selected image above the text input area. Approx 80px tall, rounded corners, X close button in top-right corner
- **Message bubble with image:** Image rendered above any text content. Rounded corners matching bubble shape. Images are tappable for full-screen view.
- **Full-screen viewer (mobile):** Black background, pinch-to-zoom (InteractiveViewer), back button to close. Reuse community feed pattern.
- **Image modal (web):** Dialog/modal with image at natural size (up to viewport), close button, click outside to dismiss.
- **Loading state:** Shimmer skeleton matching approximate image aspect ratio (16:9 default) in message bubble
- **Empty state:** N/A — this is an enhancement to existing messaging
- **Error state:** Broken image icon with muted text
- **Success feedback:** Image appears in chat instantly (optimistic on mobile, after upload on web)
- **Upload progress (mobile):** Small LinearProgressIndicator at bottom of image preview during upload
- **Mobile behavior:** ImagePicker with gallery source, compressed to 85% quality, max 1920x1920px

## Technical Approach

### Backend Changes
- **Files to modify:**
  - `backend/messaging/models.py` — Add `image` ImageField to Message, add `_message_image_path` upload path function
  - `backend/messaging/serializers.py` — Add `image` SerializerMethodField to MessageSerializer, update SendMessageSerializer to make content optional when image present
  - `backend/messaging/views.py` — Add MultiPartParser to SendMessageView and StartConversationView, add image validation constants and logic, pass image to service
  - `backend/messaging/services/messaging_service.py` — Update `send_message()` to accept optional `image` parameter, update SendMessageResult dataclass with `image_url` field
  - `backend/messaging/consumers.py` — No changes needed (serialized message already includes all fields via MessageSerializer)

- **Migration:** `python manage.py makemigrations messaging` for the new nullable image field

- **Validation pattern (from community feed):**
  ```python
  _ALLOWED_IMAGE_TYPES = {'image/jpeg', 'image/png', 'image/webp'}
  _MAX_IMAGE_SIZE = 5 * 1024 * 1024  # 5MB
  ```

### Mobile Changes
- **Files to modify:**
  - `mobile/lib/features/messaging/data/models/message_model.dart` — Add `imageUrl` field
  - `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` — Update `sendMessage` to use multipart when image present
  - `mobile/lib/features/messaging/presentation/widgets/chat_input.dart` — Add image picker button, selected image preview with remove
  - `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` — Add image display with tap-to-fullscreen, loading/error states
  - `mobile/lib/features/messaging/presentation/providers/chat_provider.dart` — Handle image attachment state in notifier

- **New files:**
  - `mobile/lib/features/messaging/presentation/widgets/message_image_viewer.dart` — Full-screen image viewer widget

### Web Changes
- **Files to modify:**
  - `web/src/types/messaging.ts` — Add `image: string | null` to Message interface
  - `web/src/components/messaging/message-bubble.tsx` — Add image display with click-to-open-modal
  - `web/src/components/messaging/chat-view.tsx` — Update send function for multipart FormData, add image state management
  - `web/src/components/messaging/message-input.tsx` — Add image picker button and preview strip

- **New files:**
  - `web/src/components/messaging/image-modal.tsx` — Full-screen image viewer dialog

### Dependencies
- No new packages needed. `image_picker` already in mobile pubspec. Web uses native file input + existing Dialog component.

### Key Design Decisions
1. **One image per message** — Simplest UX, matches iMessage/WhatsApp pattern. Multiple images = send multiple messages.
2. **Image stored on Message model** — ImageField on Message directly, not a separate Attachment model. Simpler for v1.
3. **No backend thumbnail generation** — Client-side compression (85% quality, 1920x1920 max) is sufficient. Full image served everywhere.
4. **Multipart form data for send** — Same endpoint URL, just accepts both JSON and multipart. Existing text-only sends via JSON still work (backward compatible).
5. **Image URL in WebSocket broadcast** — Receiving clients fetch image via HTTP URL, no binary data over WebSocket.

## Out of Scope
- Video attachments
- Multiple images per message
- File attachments (PDF, documents)
- Image editing/cropping/annotation
- Backend image processing (thumbnails, resize)
- Image search within messages
- Image forwarding between conversations
- Drag-and-drop image upload (web) — file input button only for v1
