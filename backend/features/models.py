"""
Feature request and voting models for trainer feedback system.
"""
from django.db import models


class FeatureRequest(models.Model):
    """Feature request submitted by trainers."""

    class Status(models.TextChoices):
        SUBMITTED = 'submitted', 'Submitted'
        UNDER_REVIEW = 'under_review', 'Under Review'
        PLANNED = 'planned', 'Planned'
        IN_DEVELOPMENT = 'in_development', 'In Development'
        RELEASED = 'released', 'Released'
        DECLINED = 'declined', 'Declined'

    class Category(models.TextChoices):
        TRAINER_TOOLS = 'trainer_tools', 'Trainer Tools'
        TRAINEE_APP = 'trainee_app', 'Trainee App'
        NUTRITION = 'nutrition', 'Nutrition'
        WORKOUTS = 'workouts', 'Workouts'
        ANALYTICS = 'analytics', 'Analytics'
        INTEGRATIONS = 'integrations', 'Integrations'
        OTHER = 'other', 'Other'

    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.CharField(
        max_length=20,
        choices=Category.choices,
        default=Category.OTHER
    )
    submitted_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='submitted_features'
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.SUBMITTED
    )
    admin_notes = models.TextField(
        blank=True,
        help_text="Internal notes visible to admins only"
    )
    public_response = models.TextField(
        blank=True,
        help_text="Public response from team"
    )
    target_release = models.CharField(
        max_length=50,
        blank=True,
        help_text="Target release version or quarter"
    )
    upvotes = models.PositiveIntegerField(default=0)
    downvotes = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'feature_requests'
        ordering = ['-upvotes', '-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['category']),
            models.Index(fields=['submitted_by']),
            models.Index(fields=['-upvotes', '-created_at']),
        ]

    def __str__(self) -> str:
        return f"{self.title} ({self.status})"

    @property
    def vote_score(self) -> int:
        return self.upvotes - self.downvotes

    def update_vote_counts(self):
        """Recalculate vote counts from actual votes."""
        self.upvotes = self.votes.filter(vote_type=FeatureVote.VoteType.UP).count()
        self.downvotes = self.votes.filter(vote_type=FeatureVote.VoteType.DOWN).count()
        self.save(update_fields=['upvotes', 'downvotes'])


class FeatureVote(models.Model):
    """Vote on a feature request."""

    class VoteType(models.TextChoices):
        UP = 'up', 'Upvote'
        DOWN = 'down', 'Downvote'

    feature = models.ForeignKey(
        FeatureRequest,
        on_delete=models.CASCADE,
        related_name='votes'
    )
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='feature_votes'
    )
    vote_type = models.CharField(
        max_length=10,
        choices=VoteType.choices
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'feature_votes'
        unique_together = [['feature', 'user']]
        indexes = [
            models.Index(fields=['feature', 'vote_type']),
        ]

    def __str__(self) -> str:
        return f"{self.user.email} {self.vote_type} on {self.feature.title}"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Update cached vote counts
        self.feature.update_vote_counts()

    def delete(self, *args, **kwargs):
        feature = self.feature
        super().delete(*args, **kwargs)
        # Update cached vote counts
        feature.update_vote_counts()


class FeatureComment(models.Model):
    """Comment on a feature request."""

    feature = models.ForeignKey(
        FeatureRequest,
        on_delete=models.CASCADE,
        related_name='comments'
    )
    user = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='feature_comments'
    )
    content = models.TextField()
    is_admin_response = models.BooleanField(
        default=False,
        help_text="True if this is an official response from the team"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'feature_comments'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['feature', 'created_at']),
        ]

    def __str__(self) -> str:
        user_email = self.user.email if self.user else 'deleted user'
        return f"Comment by {user_email} on {self.feature.title}"
