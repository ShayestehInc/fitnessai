"""
User views for profile management and onboarding.
"""
from __future__ import annotations

from typing import Any, cast

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import QuerySet

from .models import DeviceToken, User, UserProfile
from .serializers import UserProfileSerializer, OnboardingStepSerializer, UserSerializer
from .social_auth import verify_google_token, verify_apple_token, SocialAuthError
from core.permissions import IsTrainee
from trainer.models import TrainerBranding
from trainer.serializers import TrainerBrandingSerializer
from workouts.services.macro_calculator import MacroCalculatorService
from workouts.models import NutritionGoal


class UserProfileViewSet(viewsets.ModelViewSet[UserProfile]):
    """
    ViewSet for UserProfile CRUD operations.
    Users can only access their own profile.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self) -> QuerySet[UserProfile]:
        """Return only the current user's profile."""
        user = cast(User, self.request.user)
        return UserProfile.objects.filter(user=user)

    def get_object(self) -> UserProfile:
        """Get or create profile for current user."""
        user = cast(User, self.request.user)
        profile, _ = UserProfile.objects.get_or_create(user=user)
        return profile

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Return current user's profile (singleton pattern)."""
        user = cast(User, request.user)
        profile, _ = UserProfile.objects.get_or_create(user=user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='onboarding')
    def update_onboarding(self, request: Request) -> Response:
        """
        Update profile during onboarding (partial updates).

        POST /api/users/profiles/onboarding/
        Body: { "first_name": "John", "sex": "male", "age": 30, ... }
        """
        user = cast(User, request.user)
        profile, _ = UserProfile.objects.get_or_create(user=user)

        serializer = OnboardingStepSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data = cast(dict[str, Any], serializer.validated_data)

        # Separate user fields from profile fields
        user_fields = ['first_name', 'last_name']

        # Update user fields (name)
        for field in user_fields:
            if field in validated_data:
                setattr(user, field, validated_data[field])
        user.save()

        # Update profile fields
        for field, value in validated_data.items():
            if field not in user_fields:
                setattr(profile, field, value)
        profile.save()

        return Response(UserProfileSerializer(profile).data)

    @action(detail=False, methods=['delete'], url_path='delete-account')
    def delete_account(self, request: Request) -> Response:
        """
        Delete the current user's account.

        DELETE /api/users/profiles/delete-account/
        """
        user = cast(User, request.user)
        user.delete()
        return Response({'success': True, 'message': 'Account deleted successfully'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], url_path='complete-onboarding')
    def complete_onboarding(self, request: Request) -> Response:
        """
        Complete onboarding and calculate nutrition goals.

        POST /api/users/profiles/complete-onboarding/

        This endpoint:
        1. Validates all required profile fields are present
        2. Calculates personalized macro goals
        3. Creates/updates NutritionGoal record
        4. Marks onboarding as complete
        """
        user = cast(User, request.user)
        profile, _ = UserProfile.objects.get_or_create(user=user)

        # Validate required fields
        required_fields = ['sex', 'age', 'height_cm', 'weight_kg']
        missing_fields = [f for f in required_fields if not getattr(profile, f)]

        if missing_fields:
            return Response(
                {'error': f'Missing required fields: {", ".join(missing_fields)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Calculate macro goals
        calculator = MacroCalculatorService()
        goals = calculator.calculate_goals_from_profile(profile)

        if not goals:
            return Response(
                {'error': 'Could not calculate nutrition goals. Please complete your profile.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create or update NutritionGoal
        nutrition_goal, _ = NutritionGoal.objects.update_or_create(
            trainee=user,
            defaults={
                'protein_goal': goals.protein,
                'carbs_goal': goals.carbs,
                'fat_goal': goals.fat,
                'calories_goal': goals.calories,
                'per_meal_protein': goals.per_meal_protein,
                'per_meal_carbs': goals.per_meal_carbs,
                'per_meal_fat': goals.per_meal_fat,
                'is_trainer_adjusted': False,
            }
        )

        # Mark onboarding as complete
        profile.onboarding_completed = True
        profile.save()

        return Response({
            'profile': UserProfileSerializer(profile).data,
            'nutrition_goals': {
                'protein_goal': nutrition_goal.protein_goal,
                'carbs_goal': nutrition_goal.carbs_goal,
                'fat_goal': nutrition_goal.fat_goal,
                'calories_goal': nutrition_goal.calories_goal,
                'per_meal_protein': nutrition_goal.per_meal_protein,
                'per_meal_carbs': nutrition_goal.per_meal_carbs,
                'per_meal_fat': nutrition_goal.per_meal_fat,
            }
        })


class GoogleLoginView(APIView):
    """
    Handle Google Sign-In authentication.

    Users cannot self-register via social login. An Admin or Trainer must
    first create their account. This endpoint only authenticates existing users.
    """
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        id_token = request.data.get('id_token')

        if not id_token:
            return Response(
                {'error': 'ID token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Verify token with Google
            user_info = verify_google_token(id_token)
        except SocialAuthError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Look up existing user - DO NOT create new users
        try:
            user = User.objects.get(email=user_info['email'])
        except User.DoesNotExist:
            return Response(
                {'error': 'Account not found. Please contact your trainer or admin.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user is active
        if not user.is_active:
            return Response(
                {'error': 'Your account has been deactivated.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update name if not set (first social login)
        if not user.first_name and user_info.get('first_name'):
            user.first_name = user_info['first_name']
            user.last_name = user_info.get('last_name', '')
            user.save()

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data,
        })


class AppleLoginView(APIView):
    """
    Handle Apple Sign-In authentication.

    Users cannot self-register via social login. An Admin or Trainer must
    first create their account. This endpoint only authenticates existing users.
    """
    permission_classes = [AllowAny]

    def post(self, request: Request) -> Response:
        id_token = request.data.get('id_token')

        if not id_token:
            return Response(
                {'error': 'ID token is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Verify token with Apple
            user_info = verify_apple_token(id_token)
        except SocialAuthError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Look up existing user - DO NOT create new users
        try:
            user = User.objects.get(email=user_info['email'])
        except User.DoesNotExist:
            return Response(
                {'error': 'Account not found. Please contact your trainer or admin.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user is active
        if not user.is_active:
            return Response(
                {'error': 'Your account has been deactivated.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data,
        })


class UpdateUserProfileView(APIView):
    """
    Update user profile information (name, business name).

    PATCH /api/users/me/
    Body: { "first_name": "John", "last_name": "Doe", "business_name": "Fit Pro" }
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request: Request) -> Response:
        user = cast(User, request.user)

        # Update allowed fields
        allowed_fields = ['first_name', 'last_name']

        # business_name only for trainers
        if user.role == User.Role.TRAINER:
            allowed_fields.append('business_name')

        for field in allowed_fields:
            if field in request.data:
                setattr(user, field, request.data[field])

        user.save()

        return Response({
            'success': True,
            'user': UserSerializer(user, context={'request': request}).data,
        })

    def get(self, request: Request) -> Response:
        """Get current user info."""
        user = cast(User, request.user)
        return Response(UserSerializer(user, context={'request': request}).data)


class UploadProfileImageView(APIView):
    """
    Upload profile image for the current user.

    POST /api/users/profile-image/
    Content-Type: multipart/form-data
    Body: { "image": <file> }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        image = request.FILES.get('image')

        if not image:
            return Response(
                {'error': 'No image provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if image.content_type not in allowed_types:
            return Response(
                {'error': 'Invalid file type. Allowed: JPEG, PNG, GIF, WebP'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate file size (max 5MB)
        max_size = 5 * 1024 * 1024  # 5MB
        if image.size > max_size:
            return Response(
                {'error': 'File too large. Maximum size is 5MB'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Delete old image if exists
        if user.profile_image:
            user.profile_image.delete(save=False)

        # Save new image
        user.profile_image = image
        user.save()

        # Return updated user data with full URL
        return Response({
            'success': True,
            'profile_image': request.build_absolute_uri(user.profile_image.url),
            'user': UserSerializer(user, context={'request': request}).data,
        })

    def delete(self, request: Request) -> Response:
        """Remove profile image for the current user."""
        user = cast(User, request.user)

        if user.profile_image:
            user.profile_image.delete(save=False)
            user.profile_image = None
            user.save()

        return Response({
            'success': True,
            'user': UserSerializer(user, context={'request': request}).data,
        })


class MyBrandingView(APIView):
    """
    GET: Trainee fetches their parent trainer's branding configuration.

    Returns default branding values if:
    - Trainee has no parent trainer
    - Parent trainer has no branding configured

    Requires IsTrainee permission. Row-level security: trainee can only see
    their own trainer's branding.
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    _DEFAULT_BRANDING_RESPONSE: dict[str, str | None] = {
        'app_name': '',
        'primary_color': TrainerBranding.DEFAULT_PRIMARY_COLOR,
        'secondary_color': TrainerBranding.DEFAULT_SECONDARY_COLOR,
        'logo_url': None,
    }

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainer = user.parent_trainer

        if trainer is None:
            return Response(self._DEFAULT_BRANDING_RESPONSE)

        branding = TrainerBranding.objects.filter(trainer=trainer).first()
        if branding is None:
            return Response(self._DEFAULT_BRANDING_RESPONSE)

        serializer = TrainerBrandingSerializer(branding, context={'request': request})
        return Response(serializer.data)


class DeviceTokenView(APIView):
    """
    POST /api/users/device-token/
    Register or update an FCM device token.
    Body: { "token": "...", "platform": "ios"|"android"|"web" }

    DELETE /api/users/device-token/
    Deactivate a device token (on logout).
    Body: { "token": "..." }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)
        token = request.data.get('token', '').strip()
        platform = request.data.get('platform', '').strip().lower()

        if not token:
            return Response(
                {'error': 'Token is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if platform not in ('ios', 'android', 'web'):
            return Response(
                {'error': 'Platform must be ios, android, or web.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(token) > 512:
            return Response(
                {'error': 'Token exceeds maximum length.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        device_token, created = DeviceToken.objects.update_or_create(
            user=user,
            token=token,
            defaults={
                'platform': platform,
                'is_active': True,
            },
        )

        return Response(
            {
                'id': device_token.id,
                'platform': device_token.platform,
                'is_active': device_token.is_active,
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    def delete(self, request: Request) -> Response:
        user = cast(User, request.user)
        token = request.data.get('token', '').strip()

        if not token:
            return Response(
                {'error': 'Token is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        updated = DeviceToken.objects.filter(
            user=user, token=token,
        ).update(is_active=False)

        if updated == 0:
            return Response(
                {'error': 'Token not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({'success': True})


class LeaderboardOptInView(APIView):
    """
    GET  /api/users/leaderboard-opt-in/ -- get current opt-in status.
    PUT  /api/users/leaderboard-opt-in/ -- update opt-in status.
    Body: { "opt_in": true|false }
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        profile, _ = UserProfile.objects.get_or_create(user=user)
        return Response({'leaderboard_opt_in': profile.leaderboard_opt_in})

    def put(self, request: Request) -> Response:
        user = cast(User, request.user)
        opt_in = request.data.get('opt_in')

        if not isinstance(opt_in, bool):
            return Response(
                {'error': 'opt_in must be a boolean.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        profile, _ = UserProfile.objects.get_or_create(user=user)
        profile.leaderboard_opt_in = opt_in
        profile.save(update_fields=['leaderboard_opt_in', 'updated_at'])

        return Response({'leaderboard_opt_in': profile.leaderboard_opt_in})
