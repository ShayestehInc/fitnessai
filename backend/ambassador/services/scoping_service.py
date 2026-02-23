"""
Scoping service for ambassador admin capabilities.

Provides the core scoping logic that limits ambassadors to only
manage trainers they've referred/created.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from django.db.models.query import QuerySet

from ambassador.models import AmbassadorProfile, AmbassadorReferral
from users.models import User

if TYPE_CHECKING:
    pass


@dataclass(frozen=True)
class AmbassadorScope:
    """Immutable scope for an ambassador's admin capabilities."""
    ambassador_profile: AmbassadorProfile
    trainer_ids: frozenset[int]

    def trainer_belongs_to_ambassador(self, trainer_id: int) -> bool:
        """Check if a trainer is within this ambassador's scope."""
        return trainer_id in self.trainer_ids


def get_scope(user: User) -> AmbassadorScope:
    """
    Build an AmbassadorScope for the given ambassador user.

    Includes trainers from referrals with PENDING or ACTIVE status.

    Raises:
        AmbassadorProfile.DoesNotExist: If user has no ambassador profile.
    """
    profile = AmbassadorProfile.objects.get(user=user)
    trainer_ids = frozenset(
        AmbassadorReferral.objects.filter(
            ambassador=user,
            status__in=[AmbassadorReferral.Status.PENDING, AmbassadorReferral.Status.ACTIVE],
        ).values_list('trainer_id', flat=True)
    )
    return AmbassadorScope(
        ambassador_profile=profile,
        trainer_ids=trainer_ids,
    )


def get_scoped_trainers(scope: AmbassadorScope) -> QuerySet[User]:
    """Return a queryset of trainers within the ambassador's scope."""
    return User.objects.filter(
        id__in=scope.trainer_ids,
        role=User.Role.TRAINER,
    )
