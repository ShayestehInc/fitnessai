# Dev Done: Image Attachments in Direct Messages (Pipeline 21)

## Implementation Date
2026-02-19

## Summary
Added image attachment support to direct messages across all three stacks: Django backend, Flutter mobile, and Next.js web dashboard. Users can now send image-only, text-only, or combined text+image messages. Follows existing image upload patterns from the community feed feature.

## Files Changed

### Backend (Django)
| File | Change |
|------|--------|
| `backend/messaging/models.py` | Added `_message_image_path()` UUID upload path, `image` ImageField on Message. Made `content` blank/optional. Updated `__str__`. |
| `backend/messaging/serializers.py` | Added `image` SerializerMethodField on MessageSerializer. Made `content` optional in send serializers. Updated conversation list preview to show "Sent a photo". |
| `backend/messaging/views.py` | Added `MultiPartParser` to send views. Added `_validate_message_image()` helper (JPEG/PNG/WebP, 5MB). Image validation + at-least-one-of-content-or-image check. |
| `backend/messaging/services/messaging_service.py` | Updated `SendMessageResult` with `image_url`. Updated `send_message()` and `send_message_to_trainee()` for optional image. Updated push notification for "Sent a photo". Added `annotated_last_message_has_image` annotation. |
| `backend/messaging/migrations/0003_add_image_to_message.py` | Auto-generated migration for image field + content blank. |

### Mobile (Flutter)
| File | Change |
|------|--------|
| `mobile/lib/features/messaging/data/models/message_model.dart` | Added `imageUrl`, `localImagePath`, `hasImage` to MessageModel. |
| `mobile/lib/features/messaging/data/repositories/messaging_repository.dart` | Updated `sendMessage()` and `startConversation()` for multipart uploads. |
| `mobile/lib/features/messaging/presentation/providers/messaging_provider.dart` | Updated `sendMessage()` and `startConversation()` notifiers for optional image. |
| `mobile/lib/features/messaging/presentation/widgets/chat_input.dart` | Added image picker button, preview strip, 5MB client-side validation. |
| `mobile/lib/features/messaging/presentation/widgets/message_bubble.dart` | Added image display, tap-to-fullscreen, loading/error states, accessibility. |
| `mobile/lib/features/messaging/presentation/widgets/message_image_viewer.dart` | **NEW** Full-screen InteractiveViewer (pinch-to-zoom 1.0x-4.0x). |
| `mobile/lib/features/messaging/presentation/screens/chat_screen.dart` | Updated ChatInput callback for imagePath. |
| `mobile/lib/features/messaging/presentation/screens/new_conversation_screen.dart` | Updated ChatInput callback and _handleSend for imagePath. |

### Web (Next.js)
| File | Change |
|------|--------|
| `web/src/types/messaging.ts` | Added `image: string \| null` to Message interface. |
| `web/src/hooks/use-messaging.ts` | Updated `useSendMessage` and `useStartConversation` for FormData image uploads. |
| `web/src/components/messaging/message-bubble.tsx` | Added image display with click-to-modal, error state. |
| `web/src/components/messaging/chat-input.tsx` | Added paperclip image button, file input, preview strip, client-side validation with toast. |
| `web/src/components/messaging/image-modal.tsx` | **NEW** Dialog-based full-size image viewer. |
| `web/src/components/messaging/chat-view.tsx` | Updated handleSend for optional image File. |
| `web/src/components/messaging/new-conversation-view.tsx` | Updated handleSend for optional image File. |

## Key Decisions
1. Image stored directly on Message model (ImageField), not a separate Attachment model
2. No backend thumbnail generation — client-side compression sufficient (85% quality, 1920x1920 max on mobile)
3. Same endpoint URLs accept both JSON and multipart — backward compatible
4. "Sent a photo" text used for push notifications and conversation list preview when message is image-only
5. Image validation in view layer following existing community feed pattern

## Test Results
- Django: 289 tests pass (2 pre-existing MCP import errors, same as main)
- Flutter analyze: 6 warnings (all pre-existing from Pipeline 20, none new)
- No regressions

## How to Test
1. **Backend**: POST multipart to `/api/messaging/conversations/{id}/send/` with `image` file → 201 with image URL
2. **Mobile**: Chat → tap camera icon → select image → preview appears → send → image in bubble → tap for fullscreen
3. **Web**: Chat → click paperclip → select image → preview appears → send → image in bubble → click for modal
4. **Edge cases**: Image-only (no text), image+text, >5MB rejection, invalid type rejection
