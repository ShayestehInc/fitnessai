"""
Tests for the auto_post service.
"""
from __future__ import annotations

from django.test import TestCase

from community.models import CommunityPost
from community.services.auto_post_service import create_auto_post
from users.models import User


class AutoPostServiceTests(TestCase):
    """Tests for create_auto_post service function."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.orphan = User.objects.create_user(
            email='orphan@test.com',
            password='testpass123',
            role='TRAINEE',
        )

    def test_creates_workout_auto_post(self) -> None:
        """Creates a workout_completed auto-post with correct content."""
        post = create_auto_post(
            self.trainee,
            CommunityPost.PostType.WORKOUT_COMPLETED,
            {'workout_name': 'Push Day'},
        )
        self.assertIsNotNone(post)
        self.assertEqual(post.content, 'Just completed Push Day!')
        self.assertEqual(post.post_type, CommunityPost.PostType.WORKOUT_COMPLETED)
        self.assertEqual(post.trainer, self.trainer)

    def test_creates_achievement_auto_post(self) -> None:
        """Creates an achievement_earned auto-post."""
        post = create_auto_post(
            self.trainee,
            CommunityPost.PostType.ACHIEVEMENT_EARNED,
            {'achievement_name': 'First Steps'},
        )
        self.assertIsNotNone(post)
        self.assertEqual(post.content, 'Earned the First Steps badge!')

    def test_returns_none_for_orphan_trainee(self) -> None:
        """Returns None if user has no parent_trainer."""
        post = create_auto_post(
            self.orphan,
            CommunityPost.PostType.WORKOUT_COMPLETED,
            {'workout_name': 'Push Day'},
        )
        self.assertIsNone(post)
        self.assertEqual(CommunityPost.objects.count(), 0)

    def test_missing_template_variable_uses_key_name(self) -> None:
        """Missing metadata keys use the key name as fallback."""
        post = create_auto_post(
            self.trainee,
            CommunityPost.PostType.WORKOUT_COMPLETED,
            {},  # missing 'workout_name'
        )
        self.assertIsNotNone(post)
        self.assertEqual(post.content, 'Just completed workout_name!')

    def test_unknown_post_type_creates_empty_content(self) -> None:
        """Unknown post type results in empty content string."""
        post = create_auto_post(
            self.trainee,
            'unknown_type',
            {},
        )
        self.assertIsNotNone(post)
        self.assertEqual(post.content, '')
