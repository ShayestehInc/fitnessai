"""
User views for profile management and onboarding.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from .models import User, UserProfile
from .serializers import UserProfileSerializer, OnboardingStepSerializer
from workouts.services.macro_calculator import MacroCalculatorService
from workouts.models import NutritionGoal


class UserProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet for UserProfile CRUD operations.
    Users can only access their own profile.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Return only the current user's profile."""
        return UserProfile.objects.filter(user=self.request.user)

    def get_object(self):
        """Get or create profile for current user."""
        profile, _ = UserProfile.objects.get_or_create(user=self.request.user)
        return profile

    def list(self, request, *args, **kwargs):
        """Return current user's profile (singleton pattern)."""
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='onboarding')
    def update_onboarding(self, request):
        """
        Update profile during onboarding (partial updates).

        POST /api/users/profiles/onboarding/
        Body: { "first_name": "John", "sex": "male", "age": 30, ... }
        """
        profile, _ = UserProfile.objects.get_or_create(user=request.user)

        serializer = OnboardingStepSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # Separate user fields from profile fields
        user_fields = ['first_name', 'last_name']

        # Update user fields (name)
        for field in user_fields:
            if field in serializer.validated_data:
                setattr(request.user, field, serializer.validated_data[field])
        request.user.save()

        # Update profile fields
        for field, value in serializer.validated_data.items():
            if field not in user_fields:
                setattr(profile, field, value)
        profile.save()

        return Response(UserProfileSerializer(profile).data)

    @action(detail=False, methods=['delete'], url_path='delete-account')
    def delete_account(self, request):
        """
        Delete the current user's account.

        DELETE /api/users/profiles/delete-account/
        """
        user = request.user
        user.delete()
        return Response({'success': True, 'message': 'Account deleted successfully'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], url_path='complete-onboarding')
    def complete_onboarding(self, request):
        """
        Complete onboarding and calculate nutrition goals.

        POST /api/users/profiles/complete-onboarding/

        This endpoint:
        1. Validates all required profile fields are present
        2. Calculates personalized macro goals
        3. Creates/updates NutritionGoal record
        4. Marks onboarding as complete
        """
        profile, _ = UserProfile.objects.get_or_create(user=request.user)

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
            trainee=request.user,
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
