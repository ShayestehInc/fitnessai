"""
Admin site registration for community models.
"""
from django.contrib import admin

from .models import (
    Announcement,
    AnnouncementReadStatus,
    Achievement,
    UserAchievement,
    CommunityPost,
    PostReaction,
)


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('title', 'trainer', 'is_pinned', 'created_at')
    list_filter = ('is_pinned', 'created_at')
    search_fields = ('title', 'body', 'trainer__email')
    raw_id_fields = ('trainer',)


@admin.register(AnnouncementReadStatus)
class AnnouncementReadStatusAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'trainer', 'last_read_at')
    raw_id_fields = ('user', 'trainer')


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('name', 'criteria_type', 'criteria_value', 'icon_name')
    list_filter = ('criteria_type',)
    search_fields = ('name', 'description')


@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'achievement', 'earned_at')
    list_filter = ('earned_at',)
    raw_id_fields = ('user', 'achievement')


@admin.register(CommunityPost)
class CommunityPostAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('author', 'trainer', 'post_type', 'created_at')
    list_filter = ('post_type', 'created_at')
    search_fields = ('content', 'author__email')
    raw_id_fields = ('author', 'trainer')


@admin.register(PostReaction)
class PostReactionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'post', 'reaction_type', 'created_at')
    list_filter = ('reaction_type',)
    raw_id_fields = ('user', 'post')
