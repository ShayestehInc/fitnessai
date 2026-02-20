# Code Review: Image Attachments in Direct Messages (Pipeline 21)

## Review Date: 2026-02-19
## Round: 1

## Files Reviewed

### Backend
- `backend/messaging/models.py`
- `backend/messaging/serializers.py`
- `backend/messaging/views.py`
- `backend/messaging/services/messaging_service.py`
- `backend/messaging/migrations/0003_add_image_to_message.py`

### Mobile (Flutter)
- `mobile/lib/features/messaging/data/models/message_model.dart`
- `mobile/lib/features/messaging/data/repositories/messaging_repository.dart`
- `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart`
- `mobile/lib/features/messaging/presentation/widgets/chat_input.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart`
- `mobile/lib/features/messaging/presentation/widgets/message_image_viewer.dart` (NEW)
- `mobile/lib/features/messaging/presentation/screens/chat_screen.dart`
- `mobile/lib/features/messaging/presentation/screens/new_conversation_screen.dart`

### Web (Next.js)
- `web/src/types/messaging.ts`
- `web/src/hooks/use-messaging.ts`
- `web/src/components/messaging/message-bubble.tsx`
- `web/src/components/messaging/chat-input.tsx`
- `web/src/components/messaging/image-modal.tsx` (NEW)
- `web/src/components/messaging/chat-view.tsx`
- `web/src/components/messaging/new-conversation-view.tsx`

---

## Critical Issues (must fix before merge)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| C1 | `messaging_service.py:241-246` | **Dead code**: `last_message_image_subquery` variable is declared but never used. The actual `annotated_last_message_has_image` annotation on line 256 uses a completely different nested Subquery approach instead. | Remove the unused variable OR use it properly (see C3). |
| C2 | `messaging_service.py:16` | **Unused import**: `Length` is imported from `django.db.models.functions` but never used anywhere in the file. | Remove `Length` from the import statement. |
| C3 | `messaging_service.py:256-273` | **Fragile annotation logic**: `annotated_last_message_has_image` uses a nested `pk__in=Subquery(...)` pattern that checks whether ANY message in the conversation has an image, not whether the LAST message specifically has an image. It works accidentally because the serializer only checks it when the preview is empty (implying an image-only last message per validation constraints). This is fragile — any future change to validation could break this implicit relationship. The name is also misleading. | Use the declared `last_message_image_subquery` to get the image field of the most recent message, then check if it's non-empty/non-null using a chained `.annotate()` call. |
| C4 | `views.py:46-64` | **Imports after function definitions**: All model/serializer/service imports appear AFTER the `_validate_message_image()` function definition. This violates PEP 8 import ordering and makes the file confusing to read. | Move all imports to the top of the file, grouped with the existing imports. |

## Major Issues (should fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| M1 | `messaging_provider.dart:313-338` | **AC-23 not implemented: No optimistic image send on mobile.** `ChatNotifier.sendMessage()` waits for the full API response before adding the message to the list. The `localImagePath` field exists on `MessageModel` but is never used. For image uploads on slow connections, the user stares at a spinner for seconds with no chat feedback. | Create an optimistic `MessageModel` with `localImagePath` set using a temporary negative ID, add it to messages immediately, then replace it with the server response on success or mark as `isSendFailed` on error. |
| M2 | `chat-input.tsx:68-69` | **Object URL memory leak on web.** `URL.createObjectURL()` is called on image select, and `URL.revokeObjectURL()` on remove/submit. But if the component unmounts while an image is selected (user navigates away), the object URL leaks. | Add a `useEffect` cleanup: `useEffect(() => () => { if (imagePreviewUrl) URL.revokeObjectURL(imagePreviewUrl); }, [imagePreviewUrl])`. |
| M3 | `messaging_service.py:96,318` | **Weak typing on `image` parameter**: Both `send_message()` and `send_message_to_trainee()` use `Any | None` for the `image` parameter. Per project rules ("Type hints on everything"), this should use `UploadedFile | None`. | Import `UploadedFile` from `django.core.files.uploadedfile` and use it as the type hint. |

## Minor Issues (nice to fix)

| # | File:Line | Issue | Suggested Fix |
|---|-----------|-------|---------------|
| m1 | `message_bubble.dart:156-158` | **No shimmer/skeleton for image loading (AC-21 deviation)**: Uses `CircularProgressIndicator` instead of a shimmer/skeleton matching image dimensions as specified in the ticket. | Acceptable for v1. Consider shimmer in a follow-up. |
| m2 | `message-bubble.tsx:46-52` | **No skeleton loading state for web images (AC-34)**: Uses native `loading="lazy"` but no explicit skeleton/loading state while the image loads. Images pop in without a placeholder. | Add an `onLoad` handler to toggle a skeleton placeholder. |
| m3 | `message_image_viewer.dart:21-25` | **AppBar has no title**: The fullscreen image viewer has an empty AppBar. Screen readers won't announce what this screen is. | Add a title like `'Image'` or make it semantically labeled. |
| m4 | `chat_input.dart:147-149` | **`setState(() {})` on every keystroke**: Rebuilds the entire widget on each character typed to update the counter and send button state. | Consider `ValueNotifier` for the counter. Minor for this widget size. |
| m5 | `messaging_provider.dart:59-64,280-284,307-309` | **Provider catch blocks don't log exceptions**: `loadConversations()`, `loadMessages()`, and `loadMore()` catch all exceptions and set generic error strings without logging. Per project rules ("NO exception silencing"). | Add `debugPrint` logging in each catch block. |

---

## Security Concerns

1. **content_type spoofing (Low risk)**: `_validate_message_image()` checks `content_type` from the upload header, which can be spoofed. However, Django's `ImageField` validates actual image data with Pillow on save, providing defense-in-depth. **Acceptable.**

2. **Direct media URL access (Informational)**: Images stored in `message_images/` are served via Django's media URL. Anyone with the UUID-based URL can access the image without authentication. Row-level security is on the API endpoints, not the media files. Standard pattern for v1, but worth noting for future hardening (signed URLs).

3. **No new secrets leaked**: Reviewed all changed files, no API keys, passwords, or tokens.

## Performance Concerns

1. **No thumbnail generation**: Full-size images are served for 300px-tall bubbles. Mobile compresses client-side (85%/1920px) but web sends full resolution up to 5MB. Consider server-side thumbnails in a future iteration.

2. **Complex annotation subquery (C3)**: The current nested `pk__in=Subquery(...)` is more complex than needed. Using the simpler `last_message_image_subquery` approach would generate a more efficient SQL query.

---

## Acceptance Criteria Verification

### Backend (all passing)
- [x] AC-1: image ImageField with UUID path
- [x] AC-2: Migration adds image column
- [x] AC-3: Multipart form data with at-least-one validation
- [x] AC-4: JPEG/PNG/WebP, 5MB validation
- [x] AC-5: image SerializerMethodField with absolute URL
- [x] AC-6: SendMessageResult has image_url
- [x] AC-7: WebSocket broadcast includes image via serializer
- [x] AC-8: StartConversationView accepts multipart
- [x] AC-9: Backward compatible (JSON still works)
- [x] AC-10: Rate limiting unchanged
- [x] AC-11: Row-level security unchanged
- [x] AC-12: Impersonation guard unchanged
- [x] AC-13: Push notification "Sent a photo"

### Mobile
- [x] AC-14: Camera picker button
- [x] AC-15: ImagePicker 1920x1920, 85% quality
- [x] AC-16: Thumbnail preview with X remove
- [x] AC-17: Image-only, text-only, image+text
- [x] AC-18: Multipart FormData via Dio
- [x] AC-19: Rounded corners, 75% width, 300px max height
- [x] AC-20: InteractiveViewer fullscreen 1x-4x
- [ ] AC-21: **PARTIAL** — Uses spinner, not shimmer/skeleton
- [x] AC-22: Image error state
- [ ] AC-23: **FAIL** — Optimistic send not implemented (see M1)
- [ ] AC-24: **PARTIAL** — Model supports `isSendFailed` but no retry UI
- [x] AC-25: Client-side 5MB validation
- [x] AC-26: Accessibility semantics
- [x] AC-27: imageUrl field on MessageModel

### Web
- [x] AC-28: Paperclip button
- [x] AC-29: File input accepts JPEG/PNG/WebP
- [x] AC-30: Thumbnail preview with remove
- [x] AC-31: FormData with multipart
- [x] AC-32: Rounded corners, 70% width, 300px max height
- [x] AC-33: Click opens modal
- [ ] AC-34: **PARTIAL** — Uses lazy loading, no skeleton
- [x] AC-35: 5MB toast
- [x] AC-36: Message type updated
- [x] AC-37: "Sent a photo" in conversation list

---

## Quality Score: 6/10

The implementation covers all three stacks correctly with proper API design, validation, accessibility, and consistent patterns. However, the dead code (C1-C2), fragile annotation logic (C3), import ordering (C4), missing optimistic send (M1), memory leak (M2), and weak typing (M3) bring the score below the merge threshold.

## Recommendation: REQUEST CHANGES

Fix C1-C4 (dead code, unused import, annotation logic, import ordering) and M1-M3 (optimistic send, URL memory leak, type hints) before merge. Minor issues can be addressed in audit stages.
