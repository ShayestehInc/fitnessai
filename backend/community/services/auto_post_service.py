"""
Auto-post service for creating community feed posts automatically
after significant user actions (workout completion, achievement earned, etc.).

Failures are silent — auto-posts should never block the parent operation.
"""
from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from community.models import CommunityPost

if TYPE_CHECKING:
    from users.models import User

logger = logging.getLogger(__name__)

_CONTENT_TEMPLATES: dict[str, str] = {
    CommunityPost.PostType.WORKOUT_COMPLETED: "Just completed {workout_name}!",
    CommunityPost.PostType.ACHIEVEMENT_EARNED: "Earned the {achievement_name} badge!",
    CommunityPost.PostType.WEIGHT_MILESTONE: "Hit a weight milestone!",
}


def create_auto_post(
    user: User,
    post_type: str,
    metadata: dict[str, object],
) -> CommunityPost | None:
    """
    Create an auto-generated community post if the user has a parent_trainer.

    Parameters
    ----------
    user : User
        The trainee whose action triggered the auto-post.
    post_type : str
        One of ``CommunityPost.PostType`` values.
    metadata : dict
        Template variables and extra info stored on the post.

    Returns
    -------
    CommunityPost | None
        The created post, or ``None`` if the user has no trainer or creation failed.
    """
    try:
        trainer = user.parent_trainer
        if trainer is None:
            return None

        template = _CONTENT_TEMPLATES.get(post_type, "")
        content = template.format_map(_SafeFormatDict(metadata))

        post = CommunityPost.objects.create(
            author=user,
            trainer=trainer,
            content=content,
            post_type=post_type,
            metadata=metadata,
        )
        return post

    except Exception:
        logger.exception(
            "Auto-post creation failed for user %s post_type %s",
            user.id, post_type,
        )
        return None


class _SafeFormatDict(dict):  # type: ignore[type-arg]
    """Dict subclass that returns the key name for missing format keys instead of raising."""

    def __missing__(self, key: str) -> str:
        return key
