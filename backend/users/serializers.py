"""
Custom serializers for User model with email-based authentication.
"""
from __future__ import annotations

from typing import Any

from djoser.serializers import UserCreateSerializer as BaseUserCreateSerializer
from djoser.serializers import UserSerializer as BaseUserSerializer
from rest_framework import serializers

from .models import User, UserProfile


class UserCreateSerializer(BaseUserCreateSerializer):  # type: ignore[misc]
    """Custom user creation serializer that includes role field and optional referral code."""

    role = serializers.ChoiceField(
        choices=[(User.Role.TRAINEE, 'Trainee'), (User.Role.TRAINER, 'Trainer')],
        default=User.Role.TRAINEE,
        required=False,
    )
    referral_code = serializers.CharField(
        max_length=8,
        required=False,
        allow_blank=True,
        help_text="Optional ambassador referral code",
    )

    class Meta(BaseUserCreateSerializer.Meta):  # type: ignore[misc]
        model = User
        fields = ['email', 'password', 'role', 'first_name', 'last_name', 'referral_code']
        extra_kwargs = {
            'password': {'write_only': True},
        }

    def create(self, validated_data: dict[str, Any]) -> User:
        import logging
        from ambassador.services.referral_service import ReferralService

        logger = logging.getLogger(__name__)

        role = validated_data.pop('role', User.Role.TRAINEE)
        referral_code = validated_data.pop('referral_code', '').strip()
        user = User.objects.create_user(role=role, **validated_data)

        # Process referral code for trainers (silently ignore failures)
        if referral_code and role == User.Role.TRAINER:
            result = ReferralService.process_referral_code(user, referral_code)
            if not result.success:
                logger.info("Referral code '%s' not applied: %s", referral_code, result.message)

        return user


class TrainerSerializer(serializers.ModelSerializer[User]):
    """Minimal serializer for trainer info."""

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'profile_image']


class UserSerializer(BaseUserSerializer):  # type: ignore[misc]
    """Custom user serializer that includes role field and trainer info."""

    role = serializers.CharField(read_only=True)
    onboarding_completed = serializers.SerializerMethodField()
    trainer = serializers.SerializerMethodField()
    profile_image = serializers.SerializerMethodField()

    class Meta(BaseUserSerializer.Meta):  # type: ignore[misc]
        model = User
        fields = ['id', 'email', 'role', 'first_name', 'last_name', 'business_name', 'is_active', 'onboarding_completed', 'trainer', 'profile_image']

    def get_profile_image(self, obj: User) -> str | None:
        """Get full URL for profile image."""
        if obj.profile_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_image.url)
            return obj.profile_image.url
        return None

    def get_onboarding_completed(self, obj: User) -> bool:
        """Check if user has completed onboarding."""
        try:
            return bool(obj.profile.onboarding_completed)
        except UserProfile.DoesNotExist:
            return False

    def get_trainer(self, obj: User) -> dict[str, Any] | None:
        """Get assigned trainer info for trainees."""
        if obj.parent_trainer:
            result: dict[str, Any] = TrainerSerializer(obj.parent_trainer).data
            return result
        return None


class UserProfileSerializer(serializers.ModelSerializer[UserProfile]):
    """Serializer for UserProfile model."""

    user_email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = UserProfile
        fields = [
            'id', 'user', 'user_email', 'sex', 'age', 'height_cm', 'weight_kg',
            'activity_level', 'goal', 'check_in_days', 'diet_type', 'meals_per_day',
            'onboarding_completed', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']


class OnboardingStepSerializer(serializers.Serializer[dict[str, Any]]):
    """Serializer for partial onboarding updates."""

    # User fields (stored on User model)
    first_name = serializers.CharField(max_length=150, required=False)
    last_name = serializers.CharField(max_length=150, required=False)
    # Profile fields
    sex = serializers.ChoiceField(choices=UserProfile.Sex.choices, required=False)
    age = serializers.IntegerField(min_value=13, max_value=120, required=False)
    height_cm = serializers.FloatField(min_value=50, max_value=300, required=False)
    weight_kg = serializers.FloatField(min_value=20, max_value=500, required=False)
    activity_level = serializers.ChoiceField(choices=UserProfile.ActivityLevel.choices, required=False)
    goal = serializers.ChoiceField(choices=UserProfile.Goal.choices, required=False)
    check_in_days = serializers.ListField(child=serializers.CharField(), required=False)
    diet_type = serializers.ChoiceField(choices=UserProfile.DietType.choices, required=False)
    meals_per_day = serializers.IntegerField(min_value=2, max_value=6, required=False)
