"""
Custom permissions for role-based access control.
"""
from rest_framework import permissions
from typing import Any


class IsTrainer(permissions.BasePermission):
    """Permission check for Trainer role."""

    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.is_trainer()
        )


class IsTrainee(permissions.BasePermission):
    """Permission check for Trainee role."""

    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.is_trainee()
        )


class IsAdmin(permissions.BasePermission):
    """Permission check for Admin role."""

    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.is_admin()
        )


class IsTrainerOrAdmin(permissions.BasePermission):
    """Permission check for Trainer or Admin roles."""

    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.is_trainer() or request.user.is_admin())
        )


class IsAmbassador(permissions.BasePermission):
    """Permission check for Ambassador role."""

    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.is_ambassador()
        )


class IsAmbassadorOrAdmin(permissions.BasePermission):
    """Permission check for Ambassador or Admin roles."""

    def has_permission(self, request: Any, view: Any) -> bool:
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.is_ambassador() or request.user.is_admin())
        )
