"""
Views for trainer app.
"""
from __future__ import annotations

import os
import uuid
from typing import Any, cast

from rest_framework import generics, status, views
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.conf import settings
from django.core.files.storage import default_storage
from django.utils import timezone
from django.db.models import Count, Q, Avg, QuerySet
from datetime import timedelta

from core.permissions import IsTrainer
from users.models import User, UserProfile
from .models import TraineeInvitation, TrainerSession, TraineeActivitySummary
from .serializers import (
    TraineeListSerializer, TraineeDetailSerializer,
    TraineeActivitySerializer, TraineeInvitationSerializer,
    CreateInvitationSerializer, TrainerSessionSerializer,
    StartImpersonationSerializer, TrainerDashboardStatsSerializer,
    ProgramTemplateSerializer, AssignProgramSerializer
)
from workouts.models import ProgramTemplate, Program


class TrainerDashboardView(views.APIView):
    """
    GET: Returns trainer dashboard overview.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        trainees = User.objects.filter(
            parent_trainer=trainer,
            role=User.Role.TRAINEE
        )

        today = timezone.now().date()

        # Get recent activity
        recent_trainees = TraineeListSerializer(
            trainees.order_by('-created_at')[:10],
            many=True
        ).data

        # Get trainees needing attention (no activity in 3+ days)
        three_days_ago = today - timedelta(days=3)
        inactive_trainee_ids = []
        for trainee in trainees:
            latest_activity = trainee.activity_summaries.order_by('-date').first()
            if not latest_activity or latest_activity.date < three_days_ago:
                inactive_trainee_ids.append(trainee.id)

        inactive_trainees = TraineeListSerializer(
            trainees.filter(id__in=inactive_trainee_ids[:5]),
            many=True
        ).data

        return Response({
            'recent_trainees': recent_trainees,
            'inactive_trainees': inactive_trainees,
            'today': str(today)
        })


class TrainerStatsView(views.APIView):
    """
    GET: Returns trainer statistics for dashboard.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        trainees = User.objects.filter(
            parent_trainer=trainer,
            role=User.Role.TRAINEE
        )

        today = timezone.now().date()
        total_trainees = trainees.count()
        active_trainees = trainees.filter(is_active=True).count()

        # Count trainees who logged today
        logged_today = TraineeActivitySummary.objects.filter(
            trainee__in=trainees,
            date=today
        ).filter(
            Q(logged_food=True) | Q(logged_workout=True)
        ).count()

        # Count trainees on track (hit goals in last 7 days avg)
        week_ago = today - timedelta(days=7)
        on_track = TraineeActivitySummary.objects.filter(
            trainee__in=trainees,
            date__gte=week_ago,
            hit_protein_goal=True
        ).values('trainee').distinct().count()

        # Calculate average adherence rate
        total_summaries = TraineeActivitySummary.objects.filter(
            trainee__in=trainees,
            date__gte=week_ago
        ).count()

        hit_goals = TraineeActivitySummary.objects.filter(
            trainee__in=trainees,
            date__gte=week_ago,
            hit_protein_goal=True
        ).count()

        avg_adherence = (hit_goals / total_summaries * 100) if total_summaries > 0 else 0

        # Subscription info
        try:
            subscription = trainer.subscription
            tier = subscription.tier
            max_trainees = subscription.get_max_trainees()
        except:
            tier = 'NONE'
            max_trainees = 0

        # Pending onboarding
        pending_onboarding = 0
        for trainee in trainees:
            try:
                if not trainee.profile.onboarding_completed:
                    pending_onboarding += 1
            except:
                pending_onboarding += 1

        stats = {
            'total_trainees': total_trainees,
            'active_trainees': active_trainees,
            'trainees_logged_today': logged_today,
            'trainees_on_track': on_track,
            'avg_adherence_rate': round(avg_adherence, 1),
            'subscription_tier': tier,
            'max_trainees': max_trainees if max_trainees != float('inf') else -1,
            'trainees_pending_onboarding': pending_onboarding
        }

        serializer = TrainerDashboardStatsSerializer(stats)
        return Response(serializer.data)


class TraineeListView(generics.ListAPIView[User]):
    """
    GET: List all trainees for the authenticated trainer.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TraineeListSerializer

    def get_queryset(self) -> QuerySet[User]:
        user = cast(User, self.request.user)
        return User.objects.filter(
            parent_trainer=user,
            role=User.Role.TRAINEE
        ).order_by('-created_at')


class TraineeDetailView(generics.RetrieveAPIView[User]):
    """
    GET: Retrieve detailed information about a specific trainee.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TraineeDetailSerializer

    def get_queryset(self) -> QuerySet[User]:
        user = cast(User, self.request.user)
        return User.objects.filter(
            parent_trainer=user,
            role=User.Role.TRAINEE
        )


class TraineeActivityView(generics.ListAPIView[TraineeActivitySummary]):
    """
    GET: Get activity summaries for a specific trainee.
    Query params: ?days=30 (default 30)
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TraineeActivitySerializer

    def get_queryset(self) -> QuerySet[TraineeActivitySummary]:
        trainee_id = self.kwargs['pk']
        days = int(self.request.query_params.get('days', 30))
        user = cast(User, self.request.user)

        # Verify trainer owns this trainee
        if not User.objects.filter(
            id=trainee_id,
            parent_trainer=user
        ).exists():
            return TraineeActivitySummary.objects.none()

        start_date = timezone.now().date() - timedelta(days=days)
        return TraineeActivitySummary.objects.filter(
            trainee_id=trainee_id,
            date__gte=start_date
        ).order_by('-date')


class TraineeProgressView(views.APIView):
    """
    GET: Get progress analytics for a specific trainee.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        # Verify trainer owns this trainee
        try:
            trainee = User.objects.get(
                id=pk,
                parent_trainer=user,
                role=User.Role.TRAINEE
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get weight progress
        weight_checkins = trainee.weight_checkins.order_by('date')[:30]
        weight_progress = [{
            'date': str(w.date),
            'weight_kg': w.weight_kg
        } for w in weight_checkins]

        # Get workout volume progress (last 4 weeks)
        four_weeks_ago = timezone.now().date() - timedelta(weeks=4)
        volume_data = TraineeActivitySummary.objects.filter(
            trainee=trainee,
            date__gte=four_weeks_ago,
            logged_workout=True
        ).values('date').annotate(
            total_volume=Avg('total_volume')
        ).order_by('date')

        volume_progress = [{
            'date': str(v['date']),
            'volume': v['total_volume']
        } for v in volume_data]

        # Get adherence over time
        adherence_data = TraineeActivitySummary.objects.filter(
            trainee=trainee,
            date__gte=four_weeks_ago
        ).order_by('date')

        adherence_progress = [{
            'date': str(a.date),
            'logged_food': a.logged_food,
            'logged_workout': a.logged_workout,
            'hit_protein': a.hit_protein_goal
        } for a in adherence_data]

        return Response({
            'weight_progress': weight_progress,
            'volume_progress': volume_progress,
            'adherence_progress': adherence_progress
        })


class RemoveTraineeView(views.APIView):
    """
    POST: Remove a trainee from trainer (unassign, not delete).
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            trainee = User.objects.get(
                id=pk,
                parent_trainer=user,
                role=User.Role.TRAINEE
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        trainee.parent_trainer = None
        trainee.save()

        return Response({
            'message': f'Trainee {trainee.email} has been removed.'
        })


class UpdateTraineeGoalsView(views.APIView):
    """
    PATCH: Update trainee's fitness goals and activity level.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def patch(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            trainee = User.objects.get(
                id=pk,
                parent_trainer=user,
                role=User.Role.TRAINEE
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Get or create profile
        profile, _ = UserProfile.objects.get_or_create(user=trainee)

        # Update fields
        goal = request.data.get('goal')
        activity_level = request.data.get('activity_level')

        if goal:
            profile.goal = goal
        if activity_level:
            profile.activity_level = activity_level

        profile.save()

        return Response({
            'message': 'Goals updated successfully',
            'goal': profile.goal,
            'activity_level': profile.activity_level,
        })


class InvitationListCreateView(generics.ListCreateAPIView[TraineeInvitation]):
    """
    GET: List all invitations sent by the trainer.
    POST: Create a new invitation.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get_serializer_class(self) -> type:
        if self.request.method == 'POST':
            return CreateInvitationSerializer
        return TraineeInvitationSerializer

    def get_queryset(self) -> QuerySet[TraineeInvitation]:
        user = cast(User, self.request.user)
        return TraineeInvitation.objects.filter(
            trainer=user
        ).order_by('-created_at')

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        expires_days = data.pop('expires_days', 7)

        invitation = TraineeInvitation.objects.create(
            trainer=user,
            email=data['email'],
            message=data.get('message', ''),
            program_template_id=data.get('program_template_id'),
            expires_at=timezone.now() + timedelta(days=expires_days)
        )

        return Response(
            TraineeInvitationSerializer(invitation).data,
            status=status.HTTP_201_CREATED
        )


class InvitationDetailView(generics.RetrieveDestroyAPIView[TraineeInvitation]):
    """
    GET: Get invitation details.
    DELETE: Cancel/delete an invitation.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TraineeInvitationSerializer

    def get_queryset(self) -> QuerySet[TraineeInvitation]:
        user = cast(User, self.request.user)
        return TraineeInvitation.objects.filter(
            trainer=user
        )

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        instance = self.get_object()
        if instance.status == TraineeInvitation.Status.PENDING:
            instance.status = TraineeInvitation.Status.CANCELLED
            instance.save()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ResendInvitationView(views.APIView):
    """
    POST: Resend an invitation (reset expiration).
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        try:
            invitation = TraineeInvitation.objects.get(
                id=pk,
                trainer=user
            )
        except TraineeInvitation.DoesNotExist:
            return Response(
                {'error': 'Invitation not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        if invitation.status != TraineeInvitation.Status.PENDING:
            return Response(
                {'error': 'Can only resend pending invitations'},
                status=status.HTTP_400_BAD_REQUEST
            )

        invitation.expires_at = timezone.now() + timedelta(days=7)
        invitation.save()

        # TODO: Send email notification

        return Response(TraineeInvitationSerializer(invitation).data)


class StartImpersonationView(views.APIView):
    """
    POST: Start an impersonation session (login as trainee).
    Returns a special JWT token for the trainee.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, trainee_id: int) -> Response:
        user = cast(User, request.user)
        serializer = StartImpersonationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Verify trainer owns this trainee
        try:
            trainee = User.objects.get(
                id=trainee_id,
                parent_trainer=user,
                role=User.Role.TRAINEE
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainee not found or not assigned to you'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Create session record
        session = TrainerSession.objects.create(
            trainer=user,
            trainee=trainee,
            is_read_only=serializer.validated_data['is_read_only']
        )

        # Generate tokens for trainee with impersonation metadata
        refresh = RefreshToken.for_user(trainee)
        refresh['impersonating'] = True
        refresh['original_user_id'] = user.id
        refresh['session_id'] = session.id
        refresh['is_read_only'] = session.is_read_only

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'session': TrainerSessionSerializer(session).data,
            'trainee': {
                'id': trainee.id,
                'email': trainee.email,
                'first_name': trainee.first_name,
                'last_name': trainee.last_name
            }
        })


class EndImpersonationView(views.APIView):
    """
    POST: End an impersonation session.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        session_id = request.data.get('session_id')

        if not session_id:
            # Try to find active session for this user
            user = cast(User, request.user)
            session = TrainerSession.objects.filter(
                trainee=user,
                ended_at__isnull=True
            ).order_by('-started_at').first()
        else:
            session = TrainerSession.objects.filter(
                id=session_id,
                ended_at__isnull=True
            ).first()

        if not session:
            return Response(
                {'error': 'No active impersonation session found'},
                status=status.HTTP_404_NOT_FOUND
            )

        session.end_session()

        return Response({
            'message': 'Impersonation session ended',
            'session': TrainerSessionSerializer(session).data
        })


class ProgramTemplateListCreateView(generics.ListCreateAPIView[ProgramTemplate]):
    """
    GET: List program templates.
    POST: Create a new program template.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = ProgramTemplateSerializer

    def get_queryset(self) -> QuerySet[ProgramTemplate]:
        user = cast(User, self.request.user)
        # Return trainer's own templates + public templates
        return ProgramTemplate.objects.filter(
            Q(created_by=user) | Q(is_public=True)
        ).order_by('-created_at')

    def perform_create(self, serializer: Any) -> None:
        user = cast(User, self.request.user)
        serializer.save(created_by=user)


class ProgramTemplateDetailView(generics.RetrieveUpdateDestroyAPIView[ProgramTemplate]):
    """
    GET: Retrieve a program template.
    PUT/PATCH: Update a program template.
    DELETE: Delete a program template.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = ProgramTemplateSerializer

    def get_queryset(self) -> QuerySet[ProgramTemplate]:
        user = cast(User, self.request.user)
        return ProgramTemplate.objects.filter(
            created_by=user
        )


class AssignProgramTemplateView(views.APIView):
    """
    POST: Assign a program template to a trainee.
    Creates a new Program from the template.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)
        serializer = AssignProgramSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        try:
            template = ProgramTemplate.objects.get(
                Q(id=pk) & (Q(created_by=user) | Q(is_public=True))
            )
        except ProgramTemplate.DoesNotExist:
            return Response(
                {'error': 'Program template not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        trainee = User.objects.get(id=serializer.validated_data['trainee_id'])
        start_date = serializer.validated_data['start_date']
        end_date = start_date + timedelta(weeks=template.duration_weeks)

        # Create program from template
        program = Program.objects.create(
            trainee=trainee,
            name=template.name,
            description=template.description,
            start_date=start_date,
            end_date=end_date,
            schedule=template.schedule_template,
            is_active=True,
            created_by=user
        )

        # Increment usage counter
        template.times_used += 1
        template.save(update_fields=['times_used'])

        return Response({
            'message': f'Program assigned to {trainee.email}',
            'program_id': program.id,
            'program_name': program.name
        }, status=status.HTTP_201_CREATED)


class ProgramTemplateUploadImageView(views.APIView):
    """
    POST: Upload an image for a program template.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)

        # Get the template
        try:
            template = ProgramTemplate.objects.get(id=pk, created_by=user)
        except ProgramTemplate.DoesNotExist:
            return Response(
                {'error': 'Program template not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if image file was provided
        if 'image' not in request.FILES:
            return Response(
                {'error': 'No image file provided. Use "image" as the field name.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        image_file = request.FILES['image']

        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if image_file.content_type not in allowed_types:
            return Response(
                {'error': f'Invalid file type. Allowed types: {", ".join(allowed_types)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate file size (max 10MB)
        max_size = 10 * 1024 * 1024
        if image_file.size > max_size:
            return Response(
                {'error': 'File size too large. Maximum size is 10MB.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate unique filename
        file_extension = os.path.splitext(image_file.name)[1].lower()
        if not file_extension:
            ext_map = {
                'image/jpeg': '.jpg',
                'image/png': '.png',
                'image/gif': '.gif',
                'image/webp': '.webp',
            }
            file_extension = ext_map.get(image_file.content_type, '.jpg')

        unique_filename = f"program-templates/{uuid.uuid4().hex}{file_extension}"

        # Delete old image if it exists and is stored locally
        if template.image_url:
            old_url = template.image_url
            if old_url.startswith(settings.MEDIA_URL) or '/media/' in old_url:
                old_path = old_url.replace(settings.MEDIA_URL, '').lstrip('/')
                if default_storage.exists(old_path):
                    default_storage.delete(old_path)

        # Save the new image
        saved_path = default_storage.save(unique_filename, image_file)

        # Build the full URL
        image_url = request.build_absolute_uri(f"{settings.MEDIA_URL}{saved_path}")

        # Update template with new image URL
        template.image_url = image_url
        template.save(update_fields=['image_url', 'updated_at'])

        return Response({
            'success': True,
            'image_url': image_url,
            'message': 'Image uploaded successfully'
        }, status=status.HTTP_200_OK)


class ProgramUploadImageView(views.APIView):
    """
    POST: Upload an image for a program.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request: Request, pk: int) -> Response:
        user = cast(User, request.user)

        # Get the program
        try:
            program = Program.objects.get(id=pk, created_by=user)
        except Program.DoesNotExist:
            return Response(
                {'error': 'Program not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Check if image file was provided
        if 'image' not in request.FILES:
            return Response(
                {'error': 'No image file provided. Use "image" as the field name.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        image_file = request.FILES['image']

        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if image_file.content_type not in allowed_types:
            return Response(
                {'error': f'Invalid file type. Allowed types: {", ".join(allowed_types)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Validate file size (max 10MB)
        max_size = 10 * 1024 * 1024
        if image_file.size > max_size:
            return Response(
                {'error': 'File size too large. Maximum size is 10MB.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Generate unique filename
        file_extension = os.path.splitext(image_file.name)[1].lower()
        if not file_extension:
            ext_map = {
                'image/jpeg': '.jpg',
                'image/png': '.png',
                'image/gif': '.gif',
                'image/webp': '.webp',
            }
            file_extension = ext_map.get(image_file.content_type, '.jpg')

        unique_filename = f"programs/{uuid.uuid4().hex}{file_extension}"

        # Delete old image if it exists and is stored locally
        if program.image_url:
            old_url = program.image_url
            if old_url.startswith(settings.MEDIA_URL) or '/media/' in old_url:
                old_path = old_url.replace(settings.MEDIA_URL, '').lstrip('/')
                if default_storage.exists(old_path):
                    default_storage.delete(old_path)

        # Save the new image
        saved_path = default_storage.save(unique_filename, image_file)

        # Build the full URL
        image_url = request.build_absolute_uri(f"{settings.MEDIA_URL}{saved_path}")

        # Update program with new image URL
        program.image_url = image_url
        program.save(update_fields=['image_url', 'updated_at'])

        return Response({
            'success': True,
            'image_url': image_url,
            'message': 'Image uploaded successfully'
        }, status=status.HTTP_200_OK)


class AdherenceAnalyticsView(views.APIView):
    """
    GET: Get adherence analytics across all trainees.
    Query params: ?days=30
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        days = int(request.query_params.get('days', 30))
        start_date = timezone.now().date() - timedelta(days=days)

        trainees = User.objects.filter(
            parent_trainer=user,
            role=User.Role.TRAINEE,
            is_active=True
        )

        # Overall adherence stats
        summaries = TraineeActivitySummary.objects.filter(
            trainee__in=trainees,
            date__gte=start_date
        )

        total_days = summaries.count()
        food_logged_days = summaries.filter(logged_food=True).count()
        workout_logged_days = summaries.filter(logged_workout=True).count()
        protein_hit_days = summaries.filter(hit_protein_goal=True).count()

        # Per-trainee adherence
        trainee_adherence = []
        for trainee in trainees:
            trainee_summaries = summaries.filter(trainee=trainee)
            trainee_total = trainee_summaries.count()

            if trainee_total > 0:
                adherence_rate = trainee_summaries.filter(
                    Q(logged_food=True) | Q(logged_workout=True)
                ).count() / trainee_total * 100
            else:
                adherence_rate = 0

            trainee_adherence.append({
                'trainee_id': trainee.id,
                'trainee_email': trainee.email,
                'trainee_name': f"{trainee.first_name} {trainee.last_name}".strip(),
                'adherence_rate': round(adherence_rate, 1),
                'days_tracked': trainee_total
            })

        return Response({
            'period_days': days,
            'total_tracking_days': total_days,
            'food_logged_rate': round(food_logged_days / total_days * 100, 1) if total_days > 0 else 0,
            'workout_logged_rate': round(workout_logged_days / total_days * 100, 1) if total_days > 0 else 0,
            'protein_goal_rate': round(protein_hit_days / total_days * 100, 1) if total_days > 0 else 0,
            'trainee_adherence': sorted(trainee_adherence, key=lambda x: -x['adherence_rate'])
        })


class ProgressAnalyticsView(views.APIView):
    """
    GET: Get progress analytics across all trainees.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        trainees = User.objects.filter(
            parent_trainer=user,
            role=User.Role.TRAINEE,
            is_active=True
        )

        progress_data = []
        for trainee in trainees:
            # Get weight change
            checkins = trainee.weight_checkins.order_by('date')
            first_weight = checkins.first()
            last_weight = checkins.last()

            weight_change = None
            if first_weight and last_weight and first_weight.id != last_weight.id:
                weight_change = round(last_weight.weight_kg - first_weight.weight_kg, 1)

            # Get goal (if profile exists)
            try:
                goal = trainee.profile.goal
            except:
                goal = None

            progress_data.append({
                'trainee_id': trainee.id,
                'trainee_email': trainee.email,
                'trainee_name': f"{trainee.first_name} {trainee.last_name}".strip(),
                'current_weight': last_weight.weight_kg if last_weight else None,
                'weight_change': weight_change,
                'goal': goal
            })

        return Response({
            'trainee_progress': progress_data
        })


class GenerateMCPTokenView(views.APIView):
    """
    POST: Generate a JWT token for MCP server integration.

    This endpoint allows trainers to get a token for use with
    the Fitness AI MCP server (for Claude Desktop integration).
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request) -> Response:
        trainer = cast(User, request.user)

        # Generate tokens
        refresh = RefreshToken.for_user(trainer)

        # Add custom claims for MCP
        refresh['mcp_server'] = True
        refresh['email'] = trainer.email
        refresh['role'] = trainer.role
        refresh['trainer_id'] = trainer.id

        access_token = str(refresh.access_token)

        return Response({
            'access_token': access_token,
            'refresh_token': str(refresh),
            'trainer_email': trainer.email,
            'message': 'Use the access_token as TRAINER_JWT_TOKEN in your MCP server configuration.',
            'note': 'Access tokens expire after the configured JWT lifetime. Use refresh_token to get new access tokens.',
        })


class AIChatView(views.APIView):
    """
    POST: Send a message to AI assistant and get a response.

    The AI has access to trainer's trainees data and can help with:
    - Analyzing trainee progress
    - Suggesting program modifications
    - Drafting messages to trainees
    - Identifying trainees needing attention
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request) -> Response:
        from .ai_chat import get_ai_chat

        user = cast(User, request.user)
        message = request.data.get('message', '').strip()
        if not message:
            return Response(
                {'error': 'Message is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Optional: specific trainee to focus on
        trainee_id = request.data.get('trainee_id')
        if trainee_id:
            try:
                trainee_id = int(trainee_id)
                # Verify trainee belongs to this trainer
                if not User.objects.filter(
                    id=trainee_id,
                    parent_trainer=user,
                    role=User.Role.TRAINEE
                ).exists():
                    return Response(
                        {'error': 'Trainee not found'},
                        status=status.HTTP_404_NOT_FOUND
                    )
            except (ValueError, TypeError):
                trainee_id = None

        # Optional: conversation history for multi-turn chat
        conversation_history = request.data.get('conversation_history', [])

        # Get AI chat instance and send message
        ai_chat = get_ai_chat(user)
        result = ai_chat.chat(
            message=message,
            conversation_history=conversation_history,
            trainee_id=trainee_id,
        )

        if result.get('error'):
            return Response(
                {'error': result['error']},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response({
            'response': result['response'],
            'trainee_context_used': result.get('trainee_context_used'),
            'provider': result.get('provider'),
            'model': result.get('model'),
            'usage': result.get('usage'),
        })


class AIChatTraineeContextView(views.APIView):
    """
    GET: Get trainee context that would be sent to AI.

    Useful for debugging and understanding what data AI has access to.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request, trainee_id: int) -> Response:
        from .ai_chat import TraineeContextBuilder

        user = cast(User, request.user)
        # Verify trainee belongs to this trainer
        if not User.objects.filter(
            id=trainee_id,
            parent_trainer=user,
            role=User.Role.TRAINEE
        ).exists():
            return Response(
                {'error': 'Trainee not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        context_builder = TraineeContextBuilder(user)
        summary = context_builder.get_trainee_summary(trainee_id)

        return Response(summary)


class AIProvidersView(views.APIView):
    """
    GET: List available AI providers and their configuration status.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        from .ai_chat import get_available_providers
        from .ai_config import get_ai_config

        providers = get_available_providers()
        current_config = get_ai_config()

        return Response({
            'providers': providers,
            'current': {
                'provider': current_config.provider.value,
                'model': current_config.model_name,
            }
        })


class MarkMissedDayView(views.APIView):
    """
    POST: Mark a workout day as missed for a trainee's program.

    Request body:
    {
        "date": "2026-01-15",
        "action": "skip" | "push"
    }

    - skip: Mark as missed, schedule stays the same
    - push: Mark as missed AND shift all future workouts by 1 day
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request, program_id: int) -> Response:
        from datetime import datetime

        user = cast(User, request.user)
        # Get the program and verify trainer owns the trainee
        try:
            program = Program.objects.select_related('trainee').get(id=program_id)
            if program.trainee.parent_trainer != user:
                return Response(
                    {'error': 'Program not found or not authorized'},
                    status=status.HTTP_404_NOT_FOUND
                )
        except Program.DoesNotExist:
            return Response(
                {'error': 'Program not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Validate request data
        date_str = request.data.get('date')
        action = request.data.get('action', 'skip')

        if not date_str:
            return Response(
                {'error': 'Date is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            missed_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': 'Invalid date format. Use YYYY-MM-DD'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if action not in ['skip', 'push']:
            return Response(
                {'error': 'Action must be "skip" or "push"'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if date is within program range
        if missed_date < program.start_date:
            return Response(
                {'error': 'Date is before program start date'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Add to missed_dates if not already there
        missed_dates = program.missed_dates or []
        if date_str not in missed_dates:
            missed_dates.append(date_str)
            program.missed_dates = missed_dates

        if action == 'push':
            # Shift start_date forward by 1 day
            # This effectively pushes all workouts forward
            program.start_date = program.start_date + timedelta(days=1)

            # Also extend end_date by 1 day to maintain program duration
            program.end_date = program.end_date + timedelta(days=1)

        program.save()

        return Response({
            'message': f'Day marked as missed. Action: {action}',
            'missed_dates': program.missed_dates,
            'start_date': str(program.start_date),
            'end_date': str(program.end_date),
        })
