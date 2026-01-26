"""
Custom serializers for User model with email-based authentication.
"""
from djoser.serializers import UserCreateSerializer as BaseUserCreateSerializer
from djoser.serializers import UserSerializer as BaseUserSerializer
from rest_framework import serializers
from .models import User, UserProfile


class UserCreateSerializer(BaseUserCreateSerializer):
    """Custom user creation serializer that includes role field."""
    role = serializers.ChoiceField(
        choices=User.Role.choices,
        default=User.Role.TRAINEE,
        required=False
    )

    class Meta(BaseUserCreateSerializer.Meta):
        model = User
        fields = ['email', 'password', 'role', 'first_name', 'last_name']
        extra_kwargs = {
            'password': {'write_only': True},
        }

    def create(self, validated_data: dict) -> User:
        role = validated_data.pop('role', User.Role.TRAINEE)
        user = User.objects.create_user(**validated_data)
        user.role = role
        user.save()
        return user


class TrainerSerializer(serializers.ModelSerializer):
    """Minimal serializer for trainer info."""
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'profile_image']


class UserSerializer(BaseUserSerializer):
    """Custom user serializer that includes role field and trainer info."""
    role = serializers.CharField(read_only=True)
    onboarding_completed = serializers.SerializerMethodField()
    trainer = serializers.SerializerMethodField()

    class Meta(BaseUserSerializer.Meta):
        model = User
        fields = ['id', 'email', 'role', 'first_name', 'last_name', 'is_active', 'onboarding_completed', 'trainer']

    def get_onboarding_completed(self, obj) -> bool:
        """Check if user has completed onboarding."""
        try:
            return obj.profile.onboarding_completed
        except UserProfile.DoesNotExist:
            return False

    def get_trainer(self, obj):
        """Get assigned trainer info for trainees."""
        if obj.parent_trainer:
            return TrainerSerializer(obj.parent_trainer).data
        return None


class UserProfileSerializer(serializers.ModelSerializer):
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


class OnboardingStepSerializer(serializers.Serializer):
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
