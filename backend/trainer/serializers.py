"""
Serializers for trainer app.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import TraineeInvitation, TrainerSession, TraineeActivitySummary
from workouts.models import ProgramTemplate

User = get_user_model()


class TraineeListSerializer(serializers.ModelSerializer):
    """Serializer for listing trainees in trainer dashboard."""
    profile_complete = serializers.SerializerMethodField()
    last_activity = serializers.SerializerMethodField()
    current_program = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name',
            'profile_complete', 'last_activity', 'current_program',
            'is_active', 'created_at'
        ]

    def get_profile_complete(self, obj):
        try:
            return obj.profile.onboarding_completed
        except:
            return False

    def get_last_activity(self, obj):
        latest_log = obj.daily_logs.order_by('-date').first()
        if latest_log:
            return latest_log.date
        return None

    def get_current_program(self, obj):
        active_program = obj.programs.filter(is_active=True).first()
        if active_program:
            return {
                'id': active_program.id,
                'name': active_program.name,
                'start_date': active_program.start_date,
                'end_date': active_program.end_date
            }
        return None


class TraineeDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single trainee view."""
    profile = serializers.SerializerMethodField()
    nutrition_goal = serializers.SerializerMethodField()
    programs = serializers.SerializerMethodField()
    recent_activity = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name',
            'phone_number', 'is_active', 'created_at',
            'profile', 'nutrition_goal', 'programs', 'recent_activity'
        ]

    def get_profile(self, obj):
        try:
            profile = obj.profile
            return {
                'sex': profile.sex,
                'age': profile.age,
                'height_cm': profile.height_cm,
                'weight_kg': profile.weight_kg,
                'activity_level': profile.activity_level,
                'goal': profile.goal,
                'diet_type': profile.diet_type,
                'meals_per_day': profile.meals_per_day,
                'onboarding_completed': profile.onboarding_completed
            }
        except:
            return None

    def get_nutrition_goal(self, obj):
        try:
            goal = obj.nutrition_goal
            return {
                'protein_goal': goal.protein_goal,
                'carbs_goal': goal.carbs_goal,
                'fat_goal': goal.fat_goal,
                'calories_goal': goal.calories_goal,
                'is_trainer_adjusted': goal.is_trainer_adjusted
            }
        except:
            return None

    def get_programs(self, obj):
        programs = obj.programs.order_by('-created_at')[:5]
        return [{
            'id': p.id,
            'name': p.name,
            'start_date': p.start_date,
            'end_date': p.end_date,
            'is_active': p.is_active
        } for p in programs]

    def get_recent_activity(self, obj):
        """Get last 7 days of activity summaries."""
        summaries = obj.activity_summaries.order_by('-date')[:7]
        return [{
            'date': s.date,
            'logged_food': s.logged_food,
            'logged_workout': s.logged_workout,
            'calories_consumed': s.calories_consumed,
            'protein_consumed': s.protein_consumed,
            'hit_protein_goal': s.hit_protein_goal
        } for s in summaries]


class TraineeActivitySerializer(serializers.ModelSerializer):
    """Serializer for trainee activity summary."""

    class Meta:
        model = TraineeActivitySummary
        fields = [
            'id', 'date', 'workouts_completed', 'total_sets', 'total_volume',
            'calories_consumed', 'protein_consumed', 'carbs_consumed', 'fat_consumed',
            'logged_food', 'logged_workout', 'hit_protein_goal', 'hit_calorie_goal',
            'steps', 'sleep_hours'
        ]


class TraineeInvitationSerializer(serializers.ModelSerializer):
    """Serializer for trainee invitations."""
    trainer_email = serializers.EmailField(source='trainer.email', read_only=True)
    program_template_name = serializers.CharField(
        source='program_template.name',
        read_only=True,
        allow_null=True
    )
    is_expired = serializers.BooleanField(read_only=True)

    class Meta:
        model = TraineeInvitation
        fields = [
            'id', 'email', 'invitation_code', 'status',
            'trainer_email', 'program_template', 'program_template_name',
            'message', 'expires_at', 'accepted_at', 'created_at', 'is_expired'
        ]
        read_only_fields = ['invitation_code', 'status', 'accepted_at', 'created_at']


class CreateInvitationSerializer(serializers.Serializer):
    """Serializer for creating new invitations."""
    email = serializers.EmailField()
    program_template_id = serializers.IntegerField(required=False, allow_null=True)
    message = serializers.CharField(required=False, allow_blank=True, max_length=1000)
    expires_days = serializers.IntegerField(default=7, min_value=1, max_value=30)

    def validate_email(self, value):
        # Check if user with this email already exists
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError(
                "A user with this email already exists."
            )
        return value

    def validate_program_template_id(self, value):
        if value:
            trainer = self.context['request'].user
            try:
                template = ProgramTemplate.objects.get(
                    id=value,
                    created_by=trainer
                )
            except ProgramTemplate.DoesNotExist:
                raise serializers.ValidationError(
                    "Program template not found or you don't have access."
                )
        return value


class TrainerSessionSerializer(serializers.ModelSerializer):
    """Serializer for trainer impersonation sessions."""
    trainee_email = serializers.EmailField(source='trainee.email', read_only=True)
    trainee_name = serializers.SerializerMethodField()
    is_active = serializers.BooleanField(read_only=True)
    duration_minutes = serializers.IntegerField(read_only=True)

    class Meta:
        model = TrainerSession
        fields = [
            'id', 'trainee', 'trainee_email', 'trainee_name',
            'started_at', 'ended_at', 'is_active', 'is_read_only',
            'duration_minutes', 'actions_log'
        ]
        read_only_fields = [
            'started_at', 'ended_at', 'actions_log'
        ]

    def get_trainee_name(self, obj):
        return f"{obj.trainee.first_name} {obj.trainee.last_name}".strip() or obj.trainee.email


class StartImpersonationSerializer(serializers.Serializer):
    """Serializer for starting impersonation session."""
    is_read_only = serializers.BooleanField(default=True)


class TrainerDashboardStatsSerializer(serializers.Serializer):
    """Serializer for trainer dashboard statistics."""
    total_trainees = serializers.IntegerField()
    active_trainees = serializers.IntegerField()
    trainees_logged_today = serializers.IntegerField()
    trainees_on_track = serializers.IntegerField()
    avg_adherence_rate = serializers.FloatField()
    subscription_tier = serializers.CharField()
    max_trainees = serializers.IntegerField()
    trainees_pending_onboarding = serializers.IntegerField()


class ProgramTemplateSerializer(serializers.ModelSerializer):
    """Serializer for program templates."""
    created_by_email = serializers.EmailField(source='created_by.email', read_only=True)

    class Meta:
        model = ProgramTemplate
        fields = [
            'id', 'name', 'description', 'duration_weeks',
            'schedule_template', 'nutrition_template',
            'difficulty_level', 'goal_type', 'is_public',
            'created_by', 'created_by_email', 'times_used',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'times_used', 'created_at', 'updated_at']


class AssignProgramSerializer(serializers.Serializer):
    """Serializer for assigning a program template to a trainee."""
    trainee_id = serializers.IntegerField()
    start_date = serializers.DateField()
    customize_schedule = serializers.JSONField(required=False, default=dict)
    customize_nutrition = serializers.JSONField(required=False, default=dict)

    def validate_trainee_id(self, value):
        trainer = self.context['request'].user
        try:
            trainee = User.objects.get(
                id=value,
                role=User.Role.TRAINEE,
                parent_trainer=trainer
            )
        except User.DoesNotExist:
            raise serializers.ValidationError(
                "Trainee not found or not assigned to you."
            )
        return value
