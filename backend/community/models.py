"""
Community models: Announcements, Achievements, Community Feed, Leaderboards, Comments.
"""
from __future__ import annotations

import os
import uuid

from django.db import models


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
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_posts'
        indexes = [
            models.Index(fields=['trainer', '-created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f"{self.author.email}: {self.content[:50]}"


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
    Flat comment on a community post.
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
    content = models.TextField(max_length=500)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'community_comments'
        indexes = [
            models.Index(fields=['post', 'created_at']),
            models.Index(fields=['author']),
        ]
        ordering = ['created_at']

    def __str__(self) -> str:
        return f"{self.author.email}: {self.content[:50]}"
