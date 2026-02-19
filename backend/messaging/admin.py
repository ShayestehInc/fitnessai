"""
Admin site registration for messaging models.
"""
from django.contrib import admin

from .models import Conversation, Message


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('id', 'trainer', 'trainee', 'last_message_at', 'is_archived', 'created_at')
    list_filter = ('is_archived', 'created_at')
    search_fields = ('trainer__email', 'trainee__email')
    raw_id_fields = ('trainer', 'trainee')
    readonly_fields = ('created_at', 'updated_at')


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('id', 'conversation', 'sender', 'short_content', 'is_read', 'created_at')
    list_filter = ('is_read', 'created_at')
    search_fields = ('content', 'sender__email')
    raw_id_fields = ('conversation', 'sender')
    readonly_fields = ('created_at',)

    @admin.display(description='Content')
    def short_content(self, obj: Message) -> str:
        return obj.content[:80] if obj.content else ''
