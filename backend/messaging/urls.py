"""
URL configuration for the messaging app.
"""
from django.urls import path

from .views import (
    ConversationDetailView,
    ConversationListView,
    DeleteMessageView,
    EditMessageView,
    MarkReadView,
    SendMessageView,
    StartConversationView,
    UnreadCountView,
)

urlpatterns = [
    # Conversation list
    path(
        'conversations/',
        ConversationListView.as_view(),
        name='messaging-conversations',
    ),

    # Start new conversation (trainer -> trainee)
    path(
        'conversations/start/',
        StartConversationView.as_view(),
        name='messaging-start-conversation',
    ),

    # Messages in a conversation
    path(
        'conversations/<int:conversation_id>/messages/',
        ConversationDetailView.as_view(),
        name='messaging-conversation-messages',
    ),

    # Send message in a conversation
    path(
        'conversations/<int:conversation_id>/send/',
        SendMessageView.as_view(),
        name='messaging-send-message',
    ),

    # Edit a message (PATCH)
    path(
        'conversations/<int:conversation_id>/messages/<int:message_id>/',
        EditMessageView.as_view(),
        name='messaging-edit-message',
    ),

    # Delete a message (DELETE)
    path(
        'conversations/<int:conversation_id>/messages/<int:message_id>/delete/',
        DeleteMessageView.as_view(),
        name='messaging-delete-message',
    ),

    # Mark conversation as read
    path(
        'conversations/<int:conversation_id>/read/',
        MarkReadView.as_view(),
        name='messaging-mark-read',
    ),

    # Unread count across all conversations
    path(
        'unread-count/',
        UnreadCountView.as_view(),
        name='messaging-unread-count',
    ),
]
