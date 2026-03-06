"""
Service layer for Space operations: create, join, leave, defaults.
"""
from __future__ import annotations

from dataclasses import dataclass

from django.db import IntegrityError

from users.models import User

from ..models import CommunityRole, Space, SpaceMembership


@dataclass(frozen=True)
class SpaceResult:
    space: Space
    created: bool


def create_space(
    *,
    trainer: User,
    name: str,
    description: str = '',
    emoji: str = '💬',
    visibility: str = 'public',
    is_default: bool = False,
    sort_order: int = 0,
) -> Space:
    """
    Create a new space for a trainer.
    Raises IntegrityError if name already exists for this trainer.
    """
    space = Space.objects.create(
        trainer=trainer,
        name=name,
        description=description,
        emoji=emoji,
        visibility=visibility,
        is_default=is_default,
        sort_order=sort_order,
    )
    # Trainer is auto-joined as admin
    SpaceMembership.objects.create(
        space=space,
        user=trainer,
        role=CommunityRole.ADMIN,
    )
    return space


def join_space(*, space: Space, user: User) -> SpaceMembership:
    """
    Join a user to a space. Returns existing membership if already joined.
    Raises ValueError if space is private and user is not invited.
    """
    if space.visibility == Space.Visibility.PRIVATE:
        # For private spaces, only trainer/admin can add members
        # If user is trying to self-join, reject
        if user != space.trainer and not user.is_admin():
            raise ValueError("This space is invite-only.")

    try:
        membership = SpaceMembership.objects.create(
            space=space,
            user=user,
            role=CommunityRole.MEMBER,
        )
    except IntegrityError:
        # Already a member
        membership = SpaceMembership.objects.get(space=space, user=user)

    return membership


def leave_space(*, space: Space, user: User) -> None:
    """
    Remove a user from a space.
    Raises ValueError if user is the trainer (owner) of the space.
    """
    if user == space.trainer:
        raise ValueError("The space owner cannot leave their own space.")

    deleted_count, _ = SpaceMembership.objects.filter(
        space=space, user=user,
    ).delete()

    if deleted_count == 0:
        raise ValueError("You are not a member of this space.")


def create_default_space(trainer: User) -> Space:
    """
    Create a default 'General' space for a trainer if it doesn't exist.
    """
    space, created = Space.objects.get_or_create(
        trainer=trainer,
        name='General',
        defaults={
            'description': 'General discussion',
            'emoji': '💬',
            'visibility': Space.Visibility.PUBLIC,
            'is_default': True,
            'sort_order': 0,
        },
    )
    if created:
        SpaceMembership.objects.get_or_create(
            space=space,
            user=trainer,
            defaults={'role': CommunityRole.ADMIN},
        )
    return space


def auto_join_defaults(*, trainer: User, trainee: User) -> list[SpaceMembership]:
    """
    Auto-join a trainee to all default spaces for a given trainer.
    Called during trainee onboarding.
    """
    default_spaces = Space.objects.filter(
        trainer=trainer,
        is_default=True,
    )
    memberships: list[SpaceMembership] = []
    for space in default_spaces:
        membership, _ = SpaceMembership.objects.get_or_create(
            space=space,
            user=trainee,
            defaults={'role': CommunityRole.MEMBER},
        )
        memberships.append(membership)
    return memberships


def get_space_members(space: Space) -> list[SpaceMembership]:
    """Get all members of a space with user data."""
    return list(
        SpaceMembership.objects.filter(space=space)
        .select_related('user')
        .order_by('role', 'joined_at')
    )
