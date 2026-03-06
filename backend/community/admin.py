"""
Admin site registration for community models.
"""
from django.contrib import admin

from .models import (
    Announcement,
    AnnouncementReadStatus,
    Achievement,
    AutoModRule,
    Bookmark,
    BookmarkCollection,
    Comment,
    CommunityConfig,
    CommunityEvent,
    CommunityPost,
    ContentReport,
    Course,
    CourseEnrollment,
    CourseLesson,
    EventRSVP,
    LessonProgress,
    ModerationAction,
    PostImage,
    PostReaction,
    PostVideo,
    Space,
    SpaceMembership,
    UserAchievement,
    UserBan,
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


@admin.register(Space)
class SpaceAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('name', 'trainer', 'emoji', 'visibility', 'is_default', 'sort_order', 'created_at')
    list_filter = ('visibility', 'is_default')
    search_fields = ('name', 'description', 'trainer__email')
    raw_id_fields = ('trainer',)


@admin.register(SpaceMembership)
class SpaceMembershipAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'space', 'role', 'is_muted', 'joined_at')
    list_filter = ('role', 'is_muted')
    raw_id_fields = ('user', 'space')


class PostImageInline(admin.TabularInline):  # type: ignore[type-arg]
    model = PostImage
    extra = 0


class PostVideoInline(admin.TabularInline):  # type: ignore[type-arg]
    model = PostVideo
    extra = 0
    readonly_fields = ('duration', 'file_size')


@admin.register(CommunityPost)
class CommunityPostAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('author', 'trainer', 'space', 'post_type', 'is_pinned', 'created_at')
    list_filter = ('post_type', 'is_pinned', 'created_at')
    search_fields = ('content', 'author__email')
    raw_id_fields = ('author', 'trainer', 'space')
    inlines = [PostImageInline, PostVideoInline]


@admin.register(PostVideo)
class PostVideoAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('post', 'sort_order', 'duration', 'file_size', 'created_at')
    raw_id_fields = ('post',)
    readonly_fields = ('duration', 'file_size')


@admin.register(PostImage)
class PostImageAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('post', 'sort_order')
    raw_id_fields = ('post',)


@admin.register(PostReaction)
class PostReactionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'post', 'reaction_type', 'created_at')
    list_filter = ('reaction_type',)
    raw_id_fields = ('user', 'post')


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('author', 'post', 'parent_comment', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('content', 'author__email')
    raw_id_fields = ('author', 'post', 'parent_comment')


@admin.register(Bookmark)
class BookmarkAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'post', 'collection', 'created_at')
    list_filter = ('created_at',)
    raw_id_fields = ('user', 'post', 'collection')


@admin.register(BookmarkCollection)
class BookmarkCollectionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'name', 'created_at')
    search_fields = ('name', 'user__email')
    raw_id_fields = ('user',)


# ---------------------------------------------------------------------------
# Classroom
# ---------------------------------------------------------------------------

class CourseLessonInline(admin.TabularInline):  # type: ignore[type-arg]
    model = CourseLesson
    extra = 0
    fields = ('title', 'content_type', 'sort_order', 'drip_delay_days', 'estimated_minutes')


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('title', 'trainer', 'status', 'drip_enabled', 'is_mandatory', 'sort_order', 'created_at')
    list_filter = ('status', 'drip_enabled', 'is_mandatory')
    search_fields = ('title', 'description', 'trainer__email')
    raw_id_fields = ('trainer', 'space')
    inlines = [CourseLessonInline]


@admin.register(CourseLesson)
class CourseLessonAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('title', 'course', 'content_type', 'sort_order', 'drip_delay_days')
    list_filter = ('content_type',)
    search_fields = ('title', 'course__title')
    raw_id_fields = ('course',)


@admin.register(CourseEnrollment)
class CourseEnrollmentAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'course', 'enrolled_at', 'completed_at')
    list_filter = ('enrolled_at',)
    raw_id_fields = ('user', 'course')


@admin.register(LessonProgress)
class LessonProgressAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('enrollment', 'lesson', 'status', 'started_at', 'completed_at')
    list_filter = ('status',)
    raw_id_fields = ('enrollment', 'lesson')


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

@admin.register(CommunityEvent)
class CommunityEventAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('title', 'trainer', 'event_type', 'status', 'starts_at', 'ends_at')
    list_filter = ('event_type', 'status')
    search_fields = ('title', 'description', 'trainer__email')
    raw_id_fields = ('trainer', 'space')


@admin.register(EventRSVP)
class EventRSVPAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'event', 'status', 'created_at')
    list_filter = ('status',)
    raw_id_fields = ('user', 'event')


# ---------------------------------------------------------------------------
# Moderation
# ---------------------------------------------------------------------------

@admin.register(ContentReport)
class ContentReportAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('reporter', 'trainer', 'content_type', 'reason', 'status', 'created_at')
    list_filter = ('status', 'reason', 'content_type')
    search_fields = ('reporter__email', 'details')
    raw_id_fields = ('reporter', 'trainer', 'post', 'comment', 'reviewed_by')


@admin.register(ModerationAction)
class ModerationActionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('moderator', 'report', 'action_type', 'created_at')
    list_filter = ('action_type',)
    raw_id_fields = ('moderator', 'report')


@admin.register(UserBan)
class UserBanAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('user', 'trainer', 'is_permanent', 'is_active', 'expires_at', 'created_at')
    list_filter = ('is_permanent', 'is_active')
    search_fields = ('user__email', 'reason')
    raw_id_fields = ('user', 'trainer', 'banned_by')


@admin.register(AutoModRule)
class AutoModRuleAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('trainer', 'rule_type', 'action', 'is_enabled', 'created_at')
    list_filter = ('rule_type', 'action', 'is_enabled')
    raw_id_fields = ('trainer',)


# ---------------------------------------------------------------------------
# Community Config
# ---------------------------------------------------------------------------

@admin.register(CommunityConfig)
class CommunityConfigAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ('trainer', 'feed_enabled', 'courses_enabled', 'events_enabled', 'created_at')
    raw_id_fields = ('trainer',)
