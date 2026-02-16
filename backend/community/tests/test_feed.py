"""
Tests for community feed endpoints: list, create, delete, react.
"""
from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APIClient

from community.models import CommunityPost, PostReaction
from users.models import User


class CommunityFeedTests(TestCase):
    """Tests for /api/community/feed/ endpoints."""

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
        self.trainee2 = User.objects.create_user(
            email='trainee2@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.other_trainer = User.objects.create_user(
            email='other_trainer@test.com',
            password='testpass123',
            role='TRAINER',
        )
        self.other_trainee = User.objects.create_user(
            email='other_trainee@test.com',
            password='testpass123',
            role='TRAINEE',
            parent_trainer=self.other_trainer,
        )
        self.orphan = User.objects.create_user(
            email='orphan@test.com',
            password='testpass123',
            role='TRAINEE',
        )
        self.client = APIClient()
        self.url = '/api/community/feed/'

    def test_list_feed_scoped_to_trainer(self) -> None:
        """Trainee sees only posts from their trainer group."""
        CommunityPost.objects.create(
            author=self.trainee, trainer=self.trainer, content='Hello!',
        )
        CommunityPost.objects.create(
            author=self.other_trainee, trainer=self.other_trainer, content='Other group',
        )

        self.client.force_authenticate(user=self.trainee)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['results']), 1)
        self.assertEqual(response.data['results'][0]['content'], 'Hello!')

    def test_list_feed_no_trainer_returns_empty(self) -> None:
        """Orphan trainee sees empty feed."""
        self.client.force_authenticate(user=self.orphan)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['results'], [])

    def test_create_text_post(self) -> None:
        """Trainee can create a text post."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'content': 'My first post!'}, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['content'], 'My first post!')
        self.assertEqual(response.data['post_type'], 'text')
        self.assertEqual(CommunityPost.objects.count(), 1)

    def test_create_post_whitespace_stripped(self) -> None:
        """Content is whitespace-stripped."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'content': '  hello  '}, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['content'], 'hello')

    def test_create_post_empty_content_rejected(self) -> None:
        """Empty content is rejected."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'content': '   '}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_create_post_no_trainer_rejected(self) -> None:
        """Orphan trainee cannot create posts."""
        self.client.force_authenticate(user=self.orphan)
        response = self.client.post(self.url, {'content': 'Hello!'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_create_post_over_max_length_rejected(self) -> None:
        """Content over 1000 chars is rejected."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'content': 'x' * 1001}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_feed_includes_reactions_and_user_reactions(self) -> None:
        """Feed response includes reaction counts and user's reactions."""
        post = CommunityPost.objects.create(
            author=self.trainee, trainer=self.trainer, content='Hello!',
        )
        PostReaction.objects.create(user=self.trainee, post=post, reaction_type='fire')
        PostReaction.objects.create(user=self.trainee2, post=post, reaction_type='fire')
        PostReaction.objects.create(user=self.trainee2, post=post, reaction_type='heart')

        self.client.force_authenticate(user=self.trainee)
        response = self.client.get(self.url)
        post_data = response.data['results'][0]
        self.assertEqual(post_data['reactions']['fire'], 2)
        self.assertEqual(post_data['reactions']['heart'], 1)
        self.assertEqual(post_data['reactions']['thumbs_up'], 0)
        self.assertIn('fire', post_data['user_reactions'])
        self.assertNotIn('heart', post_data['user_reactions'])


class PostDeleteTests(TestCase):
    """Tests for DELETE /api/community/feed/<id>/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com', password='testpass123', role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com', password='testpass123', role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.trainee2 = User.objects.create_user(
            email='trainee2@test.com', password='testpass123', role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.client = APIClient()

    def test_author_can_delete_own_post(self) -> None:
        """Author can delete their own post."""
        post = CommunityPost.objects.create(
            author=self.trainee, trainer=self.trainer, content='Delete me',
        )
        self.client.force_authenticate(user=self.trainee)
        response = self.client.delete(f'/api/community/feed/{post.id}/')
        self.assertEqual(response.status_code, 204)
        self.assertFalse(CommunityPost.objects.filter(id=post.id).exists())

    def test_non_author_cannot_delete(self) -> None:
        """Non-author trainee cannot delete another's post."""
        post = CommunityPost.objects.create(
            author=self.trainee, trainer=self.trainer, content='Not yours',
        )
        self.client.force_authenticate(user=self.trainee2)
        response = self.client.delete(f'/api/community/feed/{post.id}/')
        self.assertEqual(response.status_code, 403)

    def test_trainer_can_delete_any_post_in_group(self) -> None:
        """Trainer can delete any post in their group (moderation)."""
        post = CommunityPost.objects.create(
            author=self.trainee, trainer=self.trainer, content='Inappropriate',
        )
        self.client.force_authenticate(user=self.trainer)
        response = self.client.delete(f'/api/community/feed/{post.id}/')
        self.assertEqual(response.status_code, 204)

    def test_delete_nonexistent_returns_404(self) -> None:
        """Deleting nonexistent post returns 404."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.delete('/api/community/feed/99999/')
        self.assertEqual(response.status_code, 404)


class ReactionToggleTests(TestCase):
    """Tests for POST /api/community/feed/<id>/react/."""

    def setUp(self) -> None:
        self.trainer = User.objects.create_user(
            email='trainer@test.com', password='testpass123', role='TRAINER',
        )
        self.trainee = User.objects.create_user(
            email='trainee@test.com', password='testpass123', role='TRAINEE',
            parent_trainer=self.trainer,
        )
        self.other_trainer = User.objects.create_user(
            email='other@test.com', password='testpass123', role='TRAINER',
        )
        self.outside_trainee = User.objects.create_user(
            email='outside@test.com', password='testpass123', role='TRAINEE',
            parent_trainer=self.other_trainer,
        )
        self.post = CommunityPost.objects.create(
            author=self.trainee, trainer=self.trainer, content='React to me!',
        )
        self.client = APIClient()
        self.url = f'/api/community/feed/{self.post.id}/react/'

    def test_toggle_on(self) -> None:
        """First reaction creates it."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'reaction_type': 'fire'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['reactions']['fire'], 1)
        self.assertIn('fire', response.data['user_reactions'])

    def test_toggle_off(self) -> None:
        """Second reaction on same type removes it."""
        PostReaction.objects.create(user=self.trainee, post=self.post, reaction_type='fire')

        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'reaction_type': 'fire'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['reactions']['fire'], 0)
        self.assertNotIn('fire', response.data['user_reactions'])

    def test_invalid_reaction_type_rejected(self) -> None:
        """Invalid reaction_type is rejected."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(self.url, {'reaction_type': 'invalid'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_outside_group_blocked(self) -> None:
        """Trainee from different group cannot react."""
        self.client.force_authenticate(user=self.outside_trainee)
        response = self.client.post(self.url, {'reaction_type': 'fire'}, format='json')
        self.assertEqual(response.status_code, 403)

    def test_react_to_nonexistent_post_returns_404(self) -> None:
        """Reacting to nonexistent post returns 404."""
        self.client.force_authenticate(user=self.trainee)
        response = self.client.post(
            '/api/community/feed/99999/react/',
            {'reaction_type': 'fire'},
            format='json',
        )
        self.assertEqual(response.status_code, 404)

    def test_multiple_reaction_types(self) -> None:
        """User can have multiple different reaction types on same post."""
        self.client.force_authenticate(user=self.trainee)
        self.client.post(self.url, {'reaction_type': 'fire'}, format='json')
        response = self.client.post(self.url, {'reaction_type': 'heart'}, format='json')
        self.assertEqual(response.data['reactions']['fire'], 1)
        self.assertEqual(response.data['reactions']['heart'], 1)
        self.assertIn('fire', response.data['user_reactions'])
        self.assertIn('heart', response.data['user_reactions'])
