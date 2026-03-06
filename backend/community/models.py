"""
Community models: Announcements, Achievements, Community Feed, Leaderboards,
Comments, Spaces, Bookmarks, Classroom, Events, Moderation, Community Config.
"""
from __future__ import annotations

import os
import uuid

from django.db import models


# ---------------------------------------------------------------------------
# Community Roles
# ---------------------------------------------------------------------------

class CommunityRole(models.TextChoices):
    MEMBER = 'member', 'Member'
    TRUSTED = 'trusted', 'Trusted'
    MODERATOR = 'moderator', 'Moderator'
    ADMIN = 'admin', 'Admin'


# ---------------------------------------------------------------------------
# Spaces
# ---------------------------------------------------------------------------

class Space(models.Model):
    """
    Sub-community within a trainer's group.
    Trainer creates spaces; trainees join them.
    """
    class Visibility(models.TextChoices):
        PUBLIC = 'public', 'Public to Cohort'
        PRIVATE = 'private', 'Invite Only'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='spaces',
        limit_choices_to={'role': 'TRAINER'},
    )
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default='')
    cover_image = models.ImageField(upload_to='spaces/covers/', blank=True)
    emoji = models.CharField(max_length=10, default='💬')
    visibility = models.CharField(
        max_length=20,
        choices=Visibility.choices,
        default=Visibility.PUBLIC,
    )
    is_default = models.BooleanField(
        default=False,
        help_text='If True, trainees auto-join this space on signup.',
    )
    sort_order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_spaces'
        ordering = ['sort_order', 'name']
        constraints = [
            models.UniqueConstraint(
                fields=['trainer', 'name'],
                name='unique_trainer_space_name',
            ),
        ]
        indexes = [
            models.Index(fields=['trainer', 'sort_order']),
        ]

    def __str__(self) -> str:
        return f"{self.emoji} {self.name} ({self.trainer.email})"


class SpaceMembership(models.Model):
    """
    Membership of a user in a space, with a community role.
    """
    space = models.ForeignKey(
        Space,
        on_delete=models.CASCADE,
        related_name='memberships',
    )
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='space_memberships',
    )
    role = models.CharField(
        max_length=20,
        choices=CommunityRole.choices,
        default=CommunityRole.MEMBER,
    )
    joined_at = models.DateTimeField(auto_now_add=True)
    is_muted = models.BooleanField(default=False)

    class Meta:
        db_table = 'community_space_memberships'
        constraints = [
            models.UniqueConstraint(
                fields=['space', 'user'],
                name='unique_space_user_membership',
            ),
        ]
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['space', 'role']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} in {self.space.name} ({self.role})"


class Announcement(models.Model):
    """
    Trainer broadcast announcement visible to all their trainees.
    """
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='announcements',
        limit_choices_to={'role': 'TRAINER'},
    )
    class ContentFormat(models.TextChoices):
        PLAIN = 'plain', 'Plain'
        MARKDOWN = 'markdown', 'Markdown'

    title = models.CharField(max_length=200)
    body = models.TextField(max_length=2000)
    is_pinned = models.BooleanField(default=False)
    content_format = models.CharField(
        max_length=10,
        choices=ContentFormat.choices,
        default=ContentFormat.PLAIN,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'announcements'
        indexes = [
            models.Index(fields=['trainer', '-created_at']),
            models.Index(fields=['trainer', 'is_pinned']),
        ]
        ordering = ['-is_pinned', '-created_at']

    def __str__(self) -> str:
        return f"{self.trainer.email}: {self.title}"


class AnnouncementReadStatus(models.Model):
    """
    Tracks when a trainee last read announcements from a specific trainer.
    One row per (user, trainer) pair. Announcements with created_at > last_read_at
    are considered unread.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='announcement_read_statuses',
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='announcement_readers',
        limit_choices_to={'role': 'TRAINER'},
    )
    last_read_at = models.DateTimeField()

    class Meta:
        db_table = 'announcement_read_statuses'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'trainer'],
                name='unique_user_trainer_read_status',
            ),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} read {self.trainer.email} at {self.last_read_at}"


class Achievement(models.Model):
    """
    Predefined achievement / badge that users can earn.
    """
    class CriteriaType(models.TextChoices):
        WORKOUT_COUNT = 'workout_count', 'Workout Count'
        WORKOUT_STREAK = 'workout_streak', 'Workout Streak'
        WEIGHT_CHECKIN_STREAK = 'weight_checkin_streak', 'Weight Check-in Streak'
        NUTRITION_STREAK = 'nutrition_streak', 'Nutrition Streak'
        PROGRAM_COMPLETED = 'program_completed', 'Program Completed'

    name = models.CharField(max_length=100)
    description = models.TextField(max_length=500)
    icon_name = models.CharField(
        max_length=50,
        help_text="Material icon name string (e.g. 'fitness_center')",
    )
    criteria_type = models.CharField(
        max_length=30,
        choices=CriteriaType.choices,
    )
    criteria_value = models.PositiveIntegerField()

    class Meta:
        db_table = 'achievements'
        constraints = [
            models.UniqueConstraint(
                fields=['criteria_type', 'criteria_value'],
                name='unique_criteria_type_value',
            ),
        ]
        ordering = ['criteria_type', 'criteria_value']

    def __str__(self) -> str:
        return f"{self.name} ({self.criteria_type}={self.criteria_value})"


class UserAchievement(models.Model):
    """
    Records that a user has earned a specific achievement.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='user_achievements',
    )
    achievement = models.ForeignKey(
        Achievement,
        on_delete=models.CASCADE,
        related_name='user_achievements',
    )
    earned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_achievements'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'achievement'],
                name='unique_user_achievement',
            ),
        ]
        indexes = [
            models.Index(fields=['user', '-earned_at']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} earned {self.achievement.name}"


def _community_post_image_path(instance: object, filename: str) -> str:
    """Generate UUID-based upload path for community post images."""
    ext = os.path.splitext(filename)[1].lower()
    return f"community_posts/{uuid.uuid4().hex}{ext}"


class CommunityPost(models.Model):
    """
    Post in the community feed, scoped by trainer (the implicit group).
    Optionally belongs to a Space for sub-community filtering.
    """
    class PostType(models.TextChoices):
        TEXT = 'text', 'Text'
        WORKOUT_COMPLETED = 'workout_completed', 'Workout Completed'
        ACHIEVEMENT_EARNED = 'achievement_earned', 'Achievement Earned'
        WEIGHT_MILESTONE = 'weight_milestone', 'Weight Milestone'

    author = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='community_posts',
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='community_group_posts',
        limit_choices_to={'role': 'TRAINER'},
        help_text="The trainer whose group this post belongs to",
    )
    space = models.ForeignKey(
        Space,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='posts',
        help_text="Optional space this post belongs to",
    )

    class ContentFormat(models.TextChoices):
        PLAIN = 'plain', 'Plain'
        MARKDOWN = 'markdown', 'Markdown'

    content = models.TextField(max_length=1000)
    post_type = models.CharField(
        max_length=30,
        choices=PostType.choices,
        default=PostType.TEXT,
    )
    content_format = models.CharField(
        max_length=10,
        choices=ContentFormat.choices,
        default=ContentFormat.PLAIN,
    )
    image = models.ImageField(
        upload_to=_community_post_image_path,
        null=True,
        blank=True,
        default=None,
        help_text="Deprecated: use PostImage instead. Kept for migration.",
    )
    is_pinned = models.BooleanField(default=False)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_posts'
        indexes = [
            models.Index(fields=['trainer', '-created_at']),
            models.Index(fields=['space', '-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.author.email}: {self.content[:50]}"


def _post_image_upload_path(instance: object, filename: str) -> str:
    """Generate upload path for post images with year/month partitioning."""
    from django.utils import timezone
    now = timezone.now()
    ext = os.path.splitext(filename)[1].lower()
    return f"community/posts/{now.year}/{now.month:02d}/{uuid.uuid4().hex}{ext}"


class PostImage(models.Model):
    """
    Image attached to a community post. Supports multiple images per post.
    """
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='images',
    )
    image = models.ImageField(upload_to=_post_image_upload_path)
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        db_table = 'community_post_images'
        ordering = ['sort_order']
        indexes = [
            models.Index(fields=['post', 'sort_order']),
        ]

    def __str__(self) -> str:
        return f"Image {self.sort_order} on post {self.post_id}"


def _post_video_upload_path(instance: object, filename: str) -> str:
    """Generate upload path for post videos with year/month partitioning."""
    from django.utils import timezone
    now = timezone.now()
    ext = os.path.splitext(filename)[1].lower()
    return f"community/posts/videos/{now.year}/{now.month:02d}/{uuid.uuid4().hex}{ext}"


def _post_video_thumbnail_path(instance: object, filename: str) -> str:
    """Generate upload path for video thumbnails."""
    from django.utils import timezone
    now = timezone.now()
    return f"community/posts/thumbnails/{now.year}/{now.month:02d}/{uuid.uuid4().hex}.jpg"


class PostVideo(models.Model):
    """
    Video attached to a community post. Supports up to 3 videos per post.
    """
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='videos',
    )
    file = models.FileField(upload_to=_post_video_upload_path)
    thumbnail = models.ImageField(
        upload_to=_post_video_thumbnail_path,
        null=True,
        blank=True,
    )
    duration = models.FloatField(
        null=True,
        blank=True,
        help_text="Video duration in seconds.",
    )
    file_size = models.PositiveIntegerField(
        help_text="File size in bytes.",
    )
    sort_order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_post_videos'
        ordering = ['sort_order']
        indexes = [
            models.Index(fields=['post', 'sort_order']),
        ]

    def __str__(self) -> str:
        dur = f"{self.duration:.1f}s" if self.duration else "unknown"
        return f"Video {self.sort_order} on post {self.post_id} ({dur})"


class PostReaction(models.Model):
    """
    Reaction on a community post (fire, thumbs_up, heart).
    """
    class ReactionType(models.TextChoices):
        FIRE = 'fire', 'Fire'
        THUMBS_UP = 'thumbs_up', 'Thumbs Up'
        HEART = 'heart', 'Heart'

    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='post_reactions',
    )
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='reactions',
    )
    reaction_type = models.CharField(
        max_length=20,
        choices=ReactionType.choices,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'post_reactions'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'post', 'reaction_type'],
                name='unique_user_post_reaction',
            ),
        ]
        indexes = [
            models.Index(fields=['post', 'reaction_type']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} {self.reaction_type} on post {self.post_id}"


class Leaderboard(models.Model):
    """
    Trainer-configurable leaderboard. 2 metrics x 2 periods = 4 per trainer.
    """
    class MetricType(models.TextChoices):
        WORKOUT_COUNT = 'workout_count', 'Workout Count'
        CURRENT_STREAK = 'current_streak', 'Current Streak'

    class TimePeriod(models.TextChoices):
        WEEKLY = 'weekly', 'Weekly'
        MONTHLY = 'monthly', 'Monthly'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='leaderboards',
        limit_choices_to={'role': 'TRAINER'},
    )
    metric_type = models.CharField(
        max_length=20,
        choices=MetricType.choices,
    )
    time_period = models.CharField(
        max_length=10,
        choices=TimePeriod.choices,
    )
    is_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'leaderboards'
        constraints = [
            models.UniqueConstraint(
                fields=['trainer', 'metric_type', 'time_period'],
                name='unique_trainer_metric_period',
            ),
        ]
        indexes = [
            models.Index(fields=['trainer', 'is_enabled']),
        ]

    def __str__(self) -> str:
        return f"{self.trainer.email}: {self.metric_type} {self.time_period} ({'on' if self.is_enabled else 'off'})"


class Comment(models.Model):
    """
    Comment on a community post. Supports one level of threading via parent_comment.
    """
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='comments',
    )
    author = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='post_comments',
    )
    parent_comment = models.ForeignKey(
        'self',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='replies',
        help_text="Parent comment for threaded replies (one level deep).",
    )
    content = models.TextField(max_length=500)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_comments'
        indexes = [
            models.Index(fields=['post', 'created_at']),
            models.Index(fields=['author']),
            models.Index(fields=['parent_comment']),
        ]
        ordering = ['created_at']

    def __str__(self) -> str:
        return f"{self.author.email}: {self.content[:50]}"


# ---------------------------------------------------------------------------
# Bookmarks
# ---------------------------------------------------------------------------

class BookmarkCollection(models.Model):
    """
    Named collection for organizing bookmarked posts.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='bookmark_collections',
    )
    name = models.CharField(max_length=200)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_bookmark_collections'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'name'],
                name='unique_user_bookmark_collection_name',
            ),
        ]
        ordering = ['name']

    def __str__(self) -> str:
        return f"{self.user.email}: {self.name}"


class Bookmark(models.Model):
    """
    Saved / bookmarked community post.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='bookmarks',
    )
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        related_name='bookmarks',
    )
    collection = models.ForeignKey(
        BookmarkCollection,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='bookmarks',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_bookmarks'
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'post'],
                name='unique_user_post_bookmark',
            ),
        ]
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.user.email} bookmarked post {self.post_id}"


# ---------------------------------------------------------------------------
# Classroom (Phase 2)
# ---------------------------------------------------------------------------

def _course_cover_upload_path(instance: object, filename: str) -> str:
    """Generate upload path for course cover images."""
    ext = os.path.splitext(filename)[1].lower()
    return f"community/courses/covers/{uuid.uuid4().hex}{ext}"


def _lesson_content_upload_path(instance: object, filename: str) -> str:
    """Generate upload path for lesson content files (video/pdf)."""
    ext = os.path.splitext(filename)[1].lower()
    return f"community/courses/lessons/{uuid.uuid4().hex}{ext}"


class Course(models.Model):
    """
    A structured course created by a trainer.
    Contains ordered lessons with optional drip scheduling.
    """
    class Status(models.TextChoices):
        DRAFT = 'draft', 'Draft'
        PUBLISHED = 'published', 'Published'
        ARCHIVED = 'archived', 'Archived'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='courses',
        limit_choices_to={'role': 'TRAINER'},
    )
    space = models.ForeignKey(
        Space,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='courses',
        help_text="Optional space this course belongs to.",
    )
    title = models.CharField(max_length=200)
    description = models.TextField(max_length=2000, blank=True, default='')
    cover_image = models.ImageField(
        upload_to=_course_cover_upload_path,
        blank=True,
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    drip_enabled = models.BooleanField(
        default=False,
        help_text="If True, lessons unlock based on drip_delay_days after enrollment.",
    )
    is_mandatory = models.BooleanField(
        default=False,
        help_text="If True, all trainees are auto-enrolled on publish.",
    )
    sort_order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'community_courses'
        ordering = ['sort_order', '-created_at']
        indexes = [
            models.Index(fields=['trainer', 'status']),
            models.Index(fields=['trainer', 'sort_order']),
        ]

    def __str__(self) -> str:
        return f"{self.title} ({self.trainer.email})"


class CourseLesson(models.Model):
    """
    A single lesson within a course.
    Supports text, video URL, or file attachment.
    """
    class ContentType(models.TextChoices):
        TEXT = 'text', 'Text / Markdown'
        VIDEO = 'video', 'Video URL'
        FILE = 'file', 'File Attachment'

    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='lessons',
    )
    title = models.CharField(max_length=200)
    content_type = models.CharField(
        max_length=20,
        choices=ContentType.choices,
        default=ContentType.TEXT,
    )
    text_content = models.TextField(blank=True, default='')
    video_url = models.URLField(blank=True, default='')
    file_attachment = models.FileField(
        upload_to=_lesson_content_upload_path,
        blank=True,
    )
    sort_order = models.PositiveIntegerField(default=0)
    drip_delay_days = models.PositiveIntegerField(
        default=0,
        help_text="Days after enrollment before this lesson unlocks (0 = immediate).",
    )
    estimated_minutes = models.PositiveIntegerField(
        default=0,
        help_text="Estimated time to complete this lesson in minutes.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'community_course_lessons'
        ordering = ['sort_order']
        indexes = [
            models.Index(fields=['course', 'sort_order']),
        ]

    def __str__(self) -> str:
        return f"Lesson {self.sort_order}: {self.title} ({self.course.title})"


class CourseEnrollment(models.Model):
    """
    Tracks a trainee's enrollment in a course.
    """
    course = models.ForeignKey(
        Course,
        on_delete=models.CASCADE,
        related_name='enrollments',
    )
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='course_enrollments',
    )
    enrolled_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'community_course_enrollments'
        constraints = [
            models.UniqueConstraint(
                fields=['course', 'user'],
                name='unique_course_enrollment',
            ),
        ]
        indexes = [
            models.Index(fields=['user', '-enrolled_at']),
            models.Index(fields=['course']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} enrolled in {self.course.title}"


class LessonProgress(models.Model):
    """
    Tracks a trainee's progress through a specific lesson.
    """
    class ProgressStatus(models.TextChoices):
        NOT_STARTED = 'not_started', 'Not Started'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'

    enrollment = models.ForeignKey(
        CourseEnrollment,
        on_delete=models.CASCADE,
        related_name='lesson_progress',
    )
    lesson = models.ForeignKey(
        CourseLesson,
        on_delete=models.CASCADE,
        related_name='progress_records',
    )
    status = models.CharField(
        max_length=20,
        choices=ProgressStatus.choices,
        default=ProgressStatus.NOT_STARTED,
    )
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'community_lesson_progress'
        constraints = [
            models.UniqueConstraint(
                fields=['enrollment', 'lesson'],
                name='unique_lesson_progress',
            ),
        ]
        indexes = [
            models.Index(fields=['enrollment', 'lesson']),
        ]

    def __str__(self) -> str:
        return f"{self.enrollment.user.email} - {self.lesson.title} ({self.status})"


# ---------------------------------------------------------------------------
# Events (Phase 3)
# ---------------------------------------------------------------------------

class CommunityEvent(models.Model):
    """
    A live session or scheduled event created by a trainer.
    """
    class EventType(models.TextChoices):
        LIVE_SESSION = 'live_session', 'Live Session'
        Q_AND_A = 'q_and_a', 'Q&A'
        WORKSHOP = 'workshop', 'Workshop'
        CHALLENGE = 'challenge', 'Challenge'
        OTHER = 'other', 'Other'

    class EventStatus(models.TextChoices):
        SCHEDULED = 'scheduled', 'Scheduled'
        LIVE = 'live', 'Live Now'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='community_events',
        limit_choices_to={'role': 'TRAINER'},
    )
    space = models.ForeignKey(
        Space,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='events',
        help_text="Optional space this event belongs to.",
    )
    title = models.CharField(max_length=200)
    description = models.TextField(max_length=2000, blank=True, default='')
    event_type = models.CharField(
        max_length=20,
        choices=EventType.choices,
        default=EventType.LIVE_SESSION,
    )
    status = models.CharField(
        max_length=20,
        choices=EventStatus.choices,
        default=EventStatus.SCHEDULED,
    )
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    meeting_url = models.URLField(
        blank=True, default='',
        help_text="External meeting link (Zoom, Google Meet, etc.)",
    )
    max_attendees = models.PositiveIntegerField(
        null=True, blank=True,
        help_text="Maximum attendees (null = unlimited).",
    )
    is_recurring = models.BooleanField(default=False)
    recurrence_rule = models.JSONField(
        default=dict, blank=True,
        help_text="Recurrence config: {frequency, interval, days_of_week, end_date}",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'community_events'
        ordering = ['starts_at']
        indexes = [
            models.Index(fields=['trainer', 'status']),
            models.Index(fields=['trainer', 'starts_at']),
            models.Index(fields=['space', 'starts_at']),
        ]

    def __str__(self) -> str:
        return f"{self.title} ({self.starts_at})"


class EventRSVP(models.Model):
    """
    RSVP for a community event.
    """
    class RSVPStatus(models.TextChoices):
        GOING = 'going', 'Going'
        MAYBE = 'maybe', 'Maybe'
        NOT_GOING = 'not_going', 'Not Going'

    event = models.ForeignKey(
        CommunityEvent,
        on_delete=models.CASCADE,
        related_name='rsvps',
    )
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='event_rsvps',
    )
    status = models.CharField(
        max_length=20,
        choices=RSVPStatus.choices,
        default=RSVPStatus.GOING,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'community_event_rsvps'
        constraints = [
            models.UniqueConstraint(
                fields=['event', 'user'],
                name='unique_event_rsvp',
            ),
        ]
        indexes = [
            models.Index(fields=['event', 'status']),
            models.Index(fields=['user']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} {self.status} for {self.event.title}"


# ---------------------------------------------------------------------------
# Moderation (Phase 4)
# ---------------------------------------------------------------------------

class ContentReport(models.Model):
    """
    Report of a post or comment by a user.
    """
    class ReportReason(models.TextChoices):
        SPAM = 'spam', 'Spam'
        HARASSMENT = 'harassment', 'Harassment'
        INAPPROPRIATE = 'inappropriate', 'Inappropriate Content'
        MISINFORMATION = 'misinformation', 'Misinformation'
        OTHER = 'other', 'Other'

    class ReportStatus(models.TextChoices):
        PENDING = 'pending', 'Pending Review'
        REVIEWED = 'reviewed', 'Reviewed'
        DISMISSED = 'dismissed', 'Dismissed'
        ACTION_TAKEN = 'action_taken', 'Action Taken'

    class ContentTypeChoice(models.TextChoices):
        POST = 'post', 'Post'
        COMMENT = 'comment', 'Comment'

    reporter = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='content_reports',
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='received_reports',
        limit_choices_to={'role': 'TRAINER'},
        help_text="Trainer who owns the community where the report was filed.",
    )
    content_type = models.CharField(
        max_length=20,
        choices=ContentTypeChoice.choices,
    )
    post = models.ForeignKey(
        CommunityPost,
        on_delete=models.CASCADE,
        null=True, blank=True,
        related_name='reports',
    )
    comment = models.ForeignKey(
        Comment,
        on_delete=models.CASCADE,
        null=True, blank=True,
        related_name='reports',
    )
    reason = models.CharField(
        max_length=30,
        choices=ReportReason.choices,
    )
    details = models.TextField(max_length=1000, blank=True, default='')
    status = models.CharField(
        max_length=20,
        choices=ReportStatus.choices,
        default=ReportStatus.PENDING,
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='reviewed_reports',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_content_reports'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['trainer', 'status']),
            models.Index(fields=['reporter']),
            models.Index(fields=['status', '-created_at']),
        ]

    def __str__(self) -> str:
        return f"Report by {self.reporter.email} ({self.reason}) - {self.status}"


class ModerationAction(models.Model):
    """
    Records an action taken by a moderator/trainer on reported content.
    """
    class ActionType(models.TextChoices):
        WARN = 'warn', 'Warn User'
        REMOVE_CONTENT = 'remove_content', 'Remove Content'
        MUTE = 'mute', 'Mute User'
        BAN = 'ban', 'Ban User'
        DISMISS = 'dismiss', 'Dismiss Report'

    report = models.ForeignKey(
        ContentReport,
        on_delete=models.CASCADE,
        related_name='actions',
    )
    moderator = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='moderation_actions',
    )
    action_type = models.CharField(
        max_length=20,
        choices=ActionType.choices,
    )
    reason = models.TextField(max_length=500, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_moderation_actions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['report']),
            models.Index(fields=['moderator']),
        ]

    def __str__(self) -> str:
        return f"{self.action_type} by {self.moderator.email} on report {self.report_id}"


class UserBan(models.Model):
    """
    Ban record for a user in a trainer's community.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='community_bans',
    )
    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='issued_bans',
        limit_choices_to={'role': 'TRAINER'},
    )
    banned_by = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='bans_issued',
    )
    reason = models.TextField(max_length=500)
    is_permanent = models.BooleanField(default=False)
    expires_at = models.DateTimeField(
        null=True, blank=True,
        help_text="When the ban expires (null if permanent).",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_user_bans'
        indexes = [
            models.Index(fields=['user', 'trainer', 'is_active']),
            models.Index(fields=['trainer', 'is_active']),
        ]

    def __str__(self) -> str:
        perm = "permanent" if self.is_permanent else f"until {self.expires_at}"
        return f"{self.user.email} banned from {self.trainer.email} ({perm})"


class AutoModRule(models.Model):
    """
    Auto-moderation rule configured by a trainer.
    """
    class RuleType(models.TextChoices):
        WORD_FILTER = 'word_filter', 'Word Filter'
        LINK_FILTER = 'link_filter', 'Link Filter'
        SPAM_DETECTION = 'spam_detection', 'Spam Detection'

    class RuleAction(models.TextChoices):
        FLAG = 'flag', 'Flag for Review'
        REMOVE = 'remove', 'Auto-Remove'
        MUTE_AUTHOR = 'mute_author', 'Mute Author'

    trainer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='auto_mod_rules',
        limit_choices_to={'role': 'TRAINER'},
    )
    rule_type = models.CharField(
        max_length=20,
        choices=RuleType.choices,
    )
    config = models.JSONField(
        default=dict,
        help_text="Rule config: {words: [...]} for word_filter, {max_links: N} for link_filter, etc.",
    )
    action = models.CharField(
        max_length=20,
        choices=RuleAction.choices,
        default=RuleAction.FLAG,
    )
    is_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'community_auto_mod_rules'
        indexes = [
            models.Index(fields=['trainer', 'is_enabled']),
        ]

    def __str__(self) -> str:
        return f"{self.rule_type} → {self.action} ({self.trainer.email})"


# ---------------------------------------------------------------------------
# Community Config (Phase 5 — Admin Builder)
# ---------------------------------------------------------------------------

class CommunityConfig(models.Model):
    """
    Trainer-level community configuration.
    One row per trainer — controls which features are enabled,
    branding, and community-wide settings.
    """
    trainer = models.OneToOneField(
        'users.User',
        on_delete=models.CASCADE,
        related_name='community_config',
        limit_choices_to={'role': 'TRAINER'},
    )

    # Feature toggles
    feed_enabled = models.BooleanField(default=True)
    spaces_enabled = models.BooleanField(default=True)
    courses_enabled = models.BooleanField(default=False)
    events_enabled = models.BooleanField(default=False)
    leaderboard_enabled = models.BooleanField(default=True)
    achievements_enabled = models.BooleanField(default=True)
    bookmarks_enabled = models.BooleanField(default=True)

    # Posting rules
    trainee_can_post = models.BooleanField(
        default=True,
        help_text="If False, only trainer/moderators can post.",
    )
    trainee_can_comment = models.BooleanField(default=True)
    trainee_can_react = models.BooleanField(default=True)
    post_approval_required = models.BooleanField(
        default=False,
        help_text="If True, trainee posts require moderator approval.",
    )

    # Branding
    community_name = models.CharField(
        max_length=100,
        blank=True, default='',
        help_text="Custom name for the community (default: trainer's name).",
    )
    welcome_message = models.TextField(
        max_length=1000,
        blank=True, default='',
        help_text="Welcome message shown to new members.",
    )

    # Guidelines
    community_guidelines = models.TextField(
        max_length=5000,
        blank=True, default='',
        help_text="Community rules / guidelines shown to members.",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'community_config'

    def __str__(self) -> str:
        return f"Community config for {self.trainer.email}"
