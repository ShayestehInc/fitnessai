"""
URL configuration for the messaging app.
"""
from django.urls import path

from .views import (
    ConversationDetailView,
    ConversationListView,
    MessageDetailView,
    MarkReadView,
    SearchMessagesView,
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

    # Edit (PATCH) or delete (DELETE) a specific message — RESTful single resource endpoint
    path(
        'conversations/<int:conversation_id>/messages/<int:message_id>/',
        MessageDetailView.as_view(),
        name='messaging-message-detail',
    ),

    # Mark conversation as read
    path(
        'conversations/<int:conversation_id>/read/',
        MarkReadView.as_view(),
        name='messaging-mark-read',
    ),

    # Search messages across all conversations
    path(
        'search/',
        SearchMessagesView.as_view(),
        name='messaging-search',
    ),

    # Unread count across all conversations
    path(
        'unread-count/',
        UnreadCountView.as_view(),
        name='messaging-unread-count',
    ),
]
