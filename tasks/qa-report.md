# QA Report: Message Editing and Deletion (Pipeline 23)

## QA Date: 2026-02-19

## Test Results
- Total: 72
- Passed: 72
- Failed: 0
- Skipped: 0

## Failed Tests
None.

## Acceptance Criteria Verification

### Backend AC Coverage

- [x] AC-1: Message model has `edited_at` and `is_deleted` fields with migration -- **PASS** (MessageModelTest: test_edited_at_default_is_null, test_is_deleted_default_is_false; MessageSerializerTest: test_serializer_includes_edited_at_and_is_deleted)
- [x] AC-2: PATCH `/api/messaging/conversations/<id>/messages/<message_id>/` edits message -- **PASS** (EditMessageViewTest: test_patch_returns_200_with_edited_message)
- [x] AC-3: DELETE soft-deletes message, no time limit -- **PASS** (DeleteMessageViewTest: test_delete_returns_204; DeleteMessageServiceTest: test_delete_has_no_time_limit)
- [x] AC-4: Edit 403 if not sender, 400 if >15 min, 400 if deleted -- **PASS** (EditMessageViewTest: test_patch_403_for_non_sender, test_patch_400_for_expired_window, test_patch_400_for_deleted_message)
- [x] AC-5: Delete 403 if not sender, 400 if already deleted -- **PASS** (DeleteMessageViewTest: test_delete_403_for_non_sender, test_delete_400_for_already_deleted)
- [x] AC-6: Soft-deleted has is_deleted=True, content='', image=None -- **PASS** (DeleteMessageServiceTest: test_successful_delete, test_delete_clears_content_and_image)
- [x] AC-7: Edit updates content and sets edited_at -- **PASS** (EditMessageServiceTest: test_successful_edit_within_window; MessageSerializerTest: test_serializer_shows_edited_at_after_edit)
- [x] AC-8: ConversationDetailView returns deleted messages correctly -- **PASS** (ConversationDetailDeletedMessageTest: test_deleted_message_in_timeline; MessageSerializerTest: test_serializer_deleted_message_shows_empty_content, test_serializer_preserves_timestamp_on_deleted_message)
- [x] AC-9: WebSocket broadcasts chat.message_edited -- **PASS** (EditMessageViewTest: test_patch_broadcasts_websocket_event)
- [x] AC-10: WebSocket broadcasts chat.message_deleted -- **PASS** (DeleteMessageViewTest: test_delete_broadcasts_websocket_event)
- [x] AC-11: Conversation list preview shows "This message was deleted" -- **PASS** (ConversationListSerializerTest: test_preview_shows_deleted_text_when_last_message_deleted)
- [x] AC-12: Row-level security (participant check) -- **PASS** (EditMessageServiceTest: test_edit_by_non_participant_raises_permission_error; DeleteMessageServiceTest: test_delete_by_non_participant_raises_permission_error; EditMessageViewTest: test_patch_403_for_non_participant; DeleteMessageViewTest: test_delete_403_for_non_participant; CrossConversationSecurityTest: all 3 tests)
- [x] AC-13: Impersonation guard -- **PASS** (EditMessageViewTest: test_patch_403_for_impersonation; DeleteMessageViewTest: test_delete_403_for_impersonation; EdgeCaseTests: test_edge_case_11_impersonating_admin_edit_forbidden, test_edge_case_11_impersonating_admin_delete_forbidden)
- [x] AC-14: Frozen dataclass results -- **PASS** (EditMessageServiceTest: test_edit_returns_frozen_dataclass; DeleteMessageServiceTest: test_delete_returns_frozen_dataclass)
- [x] AC-15: Rate limiting on edit endpoint -- **PASS** (verified via code inspection: EditMessageView has `throttle_scope = 'messaging'` which maps to 30/minute in settings)

## Edge Cases Verification

| # | Edge Case | Status | Test |
|---|-----------|--------|------|
| 1 | Edit deleted message -> 400 | PASS | test_edge_case_1_edit_already_deleted |
| 2 | Edit >15 min message -> 400 | PASS | test_edge_case_2_edit_message_older_than_15_minutes |
| 3 | Edit/delete other's message -> 403 | PASS | test_edge_case_3_edit_other_users_message, test_edge_case_3_delete_other_users_message |
| 4 | Concurrent edits -> last-write-wins | PASS | test_edge_case_4_concurrent_edits_last_write_wins |
| 5 | Edit image message -> image preserved | PASS | test_edge_case_5_edit_image_message_preserves_image |
| 6 | Delete image message -> both cleared | PASS | test_edge_case_6_delete_image_message_clears_both |
| 7 | Edit empty content text-only -> 400 | PASS | test_edge_case_7_edit_empty_content_text_only |
| 8 | Edit empty content image msg -> allowed | PASS | test_edge_case_8_edit_empty_content_image_message |
| 9 | WS disconnected -> HTTP polling picks up | N/A | Not testable in unit tests (verified by code: changes persist to DB) |
| 10 | Last message deleted -> preview updates | PASS | test_edge_case_10_last_message_deleted_updates_preview |
| 11 | Impersonating admin -> 403 | PASS | test_edge_case_11_impersonating_admin_edit_forbidden, test_edge_case_11_impersonating_admin_delete_forbidden |

## Test Categories Breakdown

| Category | Count | Details |
|----------|-------|---------|
| Service: edit_message() | 13 | Success, permissions, deleted, expired, empty, >2000, boundary, non-existent, image, whitespace, frozen |
| Service: delete_message() | 8 | Success, clears content/image, permissions, already deleted, non-existent, no time limit, frozen |
| View: EditMessageView | 10 | 200, 403 (impersonation, non-sender, non-participant), 400 (expired, deleted, empty), 404, WS broadcast, 401 |
| View: DeleteMessageView | 8 | 204, 403 (impersonation, non-sender, non-participant), 400, 404, WS broadcast, 401 |
| Serializer: MessageSerializer | 5 | Fields presence, edited_at, deleted state, timestamp preservation |
| Serializer: ConversationList | 2 | Deleted preview, normal preview |
| Model: Message | 4 | Default values, __str__ |
| Edge cases | 13 | All 11 ticket edge cases (some split into edit+delete) |
| Boundary: edit window | 2 | At 15 min boundary, just before |
| Cross-conversation security | 3 | Edit/delete wrong conversation, message not found |
| Trainee edit/delete | 4 | Service and API for both edit and delete |

## Bugs Found Outside Tests
None. All service layer functions, views, serializers, and models are functioning correctly.

## Confidence Level: HIGH

All 72 tests pass. Every backend acceptance criterion (AC-1 through AC-15) is verified. All 11 edge cases from the ticket are covered (edge case 9 is not unit-testable but is inherently handled by database persistence). Row-level security, impersonation guards, WebSocket broadcasts, frozen dataclass returns, and boundary conditions are all tested.
