"""
Admin views for subscription and trainer management.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.views import APIView
from rest_framework.serializers import BaseSerializer
from django.db.models import Sum, Count, Q
from django.db.models.query import QuerySet
from django.utils import timezone
from django.conf import settings
from datetime import timedelta
from decimal import Decimal

from rest_framework_simplejwt.tokens import RefreshToken

from subscriptions.models import (
    Subscription, PaymentHistory, SubscriptionChange,
    SubscriptionTier, Coupon
)
from subscriptions.serializers import (
    SubscriptionSerializer,
    SubscriptionListSerializer,
    PaymentHistorySerializer,
    SubscriptionChangeSerializer,
    AdminChangeTierSerializer,
    AdminChangeStatusSerializer,
    AdminUpdateNotesSerializer,
    SubscriptionTierSerializer,
    SubscriptionTierCreateUpdateSerializer,
    CouponSerializer,
    CouponListSerializer,
    CouponCreateSerializer,
    CouponUpdateSerializer,
)
from users.models import User

logger = logging.getLogger(__name__)


class IsAdminUser(BasePermission):
    """Permission class to check if user is admin."""
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user.is_authenticated and request.user.is_admin())


class AdminUsersListView(APIView):
    """
    List all Admin and Trainer users.
    GET /api/admin/users/
    Query params: ?role=ADMIN|TRAINER&search=...
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request: Request) -> Response:
        role_filter = request.query_params.get('role', '').upper()
        search = request.query_params.get('search', '').strip()

        # Get admins and trainers
        queryset = User.objects.filter(role__in=[User.Role.ADMIN, User.Role.TRAINER])

        if role_filter in ['ADMIN', 'TRAINER']:
            queryset = queryset.filter(role=role_filter)

        if search:
            queryset = queryset.filter(
                Q(email__icontains=search) |
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search)
            )

        users = queryset.order_by('-created_at')

        result = []
        for user in users:
            result.append({
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'role': user.role,
                'is_active': user.is_active,
                'created_at': user.created_at.isoformat(),
                'trainee_count': user.get_active_trainees_count() if user.role == User.Role.TRAINER else 0,
            })

        return Response(result)


class AdminUserDetailView(APIView):
    """
    Get, update, or delete an Admin/Trainer user.
    GET /api/admin/users/<id>/
    PATCH /api/admin/users/<id>/
    DELETE /api/admin/users/<id>/
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_user(self, user_id: int) -> User | None:
        try:
            return User.objects.get(
                id=user_id,
                role__in=[User.Role.ADMIN, User.Role.TRAINER]
            )
        except User.DoesNotExist:
            return None

    def get(self, request: Request, user_id: int) -> Response:
        user = self.get_user(user_id)
        if not user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        return Response({
            'id': user.id,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'role': user.role,
            'is_active': user.is_active,
            'created_at': user.created_at.isoformat(),
            'trainee_count': user.get_active_trainees_count() if user.role == User.Role.TRAINER else 0,
        })

    def patch(self, request: Request, user_id: int) -> Response:
        user = self.get_user(user_id)
        if not user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        current_user = cast(User, request.user)
        # Prevent self-demotion or self-deactivation
        if user.id == current_user.id:
            if 'role' in request.data and request.data['role'] != user.role:
                return Response(
                    {'error': 'You cannot change your own role'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            if 'is_active' in request.data and not request.data['is_active']:
                return Response(
                    {'error': 'You cannot deactivate your own account'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        # Update fields
        if 'first_name' in request.data:
            user.first_name = request.data['first_name'].strip()
        if 'last_name' in request.data:
            user.last_name = request.data['last_name'].strip()
        if 'is_active' in request.data:
            user.is_active = request.data['is_active']
        if 'role' in request.data:
            new_role = request.data['role'].upper()
            if new_role in ['ADMIN', 'TRAINER']:
                user.role = new_role

        # Update password if provided
        if 'password' in request.data and request.data['password']:
            password = request.data['password']
            if len(password) < 8:
                return Response(
                    {'error': 'Password must be at least 8 characters'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            user.set_password(password)

        user.save()

        logger.info(f"Admin {current_user.email} updated user {user.email}")

        return Response({
            'id': user.id,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'role': user.role,
            'is_active': user.is_active,
            'created_at': user.created_at.isoformat(),
        })

    def delete(self, request: Request, user_id: int) -> Response:
        user = self.get_user(user_id)
        if not user:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        current_user = cast(User, request.user)
        # Prevent self-deletion
        if user.id == current_user.id:
            return Response(
                {'error': 'You cannot delete your own account'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if trainer has trainees
        if user.role == User.Role.TRAINER:
            trainee_count = user.get_active_trainees_count()
            if trainee_count > 0:
                return Response(
                    {'error': f'Cannot delete trainer with {trainee_count} active trainees. Reassign or remove trainees first.'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        email = user.email
        user.delete()

        logger.info(f"Admin {current_user.email} deleted user {email}")

        return Response({'success': True, 'message': f'User {email} deleted'})


class AdminCreateUserView(APIView):
    """
    Admin endpoint to create Admin or Trainer accounts.
    POST /api/admin/users/create/
    Body: {"email": "...", "password": "...", "role": "ADMIN"|"TRAINER", "first_name": "...", "last_name": "..."}
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request: Request) -> Response:
        email = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')
        role = request.data.get('role', '').upper()
        first_name = request.data.get('first_name', '').strip()
        last_name = request.data.get('last_name', '').strip()

        # Validation
        if not email:
            return Response(
                {'error': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not password:
            return Response(
                {'error': 'Password is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(password) < 8:
            return Response(
                {'error': 'Password must be at least 8 characters'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if role not in ['ADMIN', 'TRAINER']:
            return Response(
                {'error': 'Role must be ADMIN or TRAINER'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user already exists
        if User.objects.filter(email=email).exists():
            return Response(
                {'error': 'A user with this email already exists'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Create the user
            user = User.objects.create_user(
                email=email,
                password=password,
                role=role,
                first_name=first_name,
                last_name=last_name,
            )

            # If creating a trainer, create a FREE subscription for them
            if role == 'TRAINER':
                Subscription.objects.create(
                    trainer=user,
                    tier='FREE',
                    status='active',
                )

            current_user = cast(User, request.user)
            logger.info(f"Admin {current_user.email} created {role} account: {email}")

            return Response({
                'success': True,
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'role': user.role,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'created_at': user.created_at.isoformat(),
                }
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            logger.error(f"Error creating user: {str(e)}")
            return Response(
                {'error': 'Failed to create user'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AdminDashboardView(APIView):
    """
    Admin dashboard with overview statistics.
    GET /api/admin/dashboard/
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request: Request) -> Response:
        today = timezone.now().date()
        week_end = today + timedelta(days=7)
        month_end = today + timedelta(days=30)

        # Total counts
        total_trainers = User.objects.filter(role=User.Role.TRAINER).count()
        active_trainers = User.objects.filter(role=User.Role.TRAINER, is_active=True).count()
        total_trainees = User.objects.filter(role=User.Role.TRAINEE).count()

        # Subscription tier breakdown
        tier_breakdown = dict(
            Subscription.objects.values('tier')
            .annotate(count=Count('id'))
            .values_list('tier', 'count')
        )

        # Subscription status breakdown
        status_breakdown = dict(
            Subscription.objects.values('status')
            .annotate(count=Count('id'))
            .values_list('status', 'count')
        )

        # Monthly recurring revenue (MRR)
        mrr = Decimal('0.00')
        active_subs = Subscription.objects.filter(status='active')
        for sub in active_subs:
            mrr += sub.get_monthly_price()

        # Total past due
        total_past_due = Subscription.objects.aggregate(
            total=Sum('past_due_amount')
        )['total'] or Decimal('0.00')

        # Payment due counts
        payments_due_today = Subscription.objects.filter(
            next_payment_date=today,
            status='active'
        ).count()

        payments_due_this_week = Subscription.objects.filter(
            next_payment_date__gte=today,
            next_payment_date__lte=week_end,
            status='active'
        ).count()

        payments_due_this_month = Subscription.objects.filter(
            next_payment_date__gte=today,
            next_payment_date__lte=month_end,
            status='active'
        ).count()

        # Past due count
        past_due_count = Subscription.objects.filter(
            Q(status='past_due') | Q(past_due_amount__gt=0)
        ).count()

        data = {
            'total_trainers': total_trainers,
            'active_trainers': active_trainers,
            'total_trainees': total_trainees,
            'tier_breakdown': tier_breakdown,
            'status_breakdown': status_breakdown,
            'monthly_recurring_revenue': str(mrr),
            'total_past_due': str(total_past_due),
            'payments_due_today': payments_due_today,
            'payments_due_this_week': payments_due_this_week,
            'payments_due_this_month': payments_due_this_month,
            'past_due_count': past_due_count,
        }

        return Response(data)


class AdminSubscriptionViewSet(viewsets.ModelViewSet[Subscription]):
    """
    Admin viewset for managing subscriptions.
    """
    permission_classes = [IsAuthenticated, IsAdminUser]
    serializer_class = SubscriptionSerializer

    def get_queryset(self) -> QuerySet[Subscription]:
        queryset = Subscription.objects.select_related('trainer').all()

        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by tier
        tier_filter = self.request.query_params.get('tier')
        if tier_filter:
            queryset = queryset.filter(tier=tier_filter)

        # Filter for past due
        past_due = self.request.query_params.get('past_due')
        if past_due == 'true':
            queryset = queryset.filter(
                Q(status='past_due') | Q(past_due_amount__gt=0)
            )

        # Filter for upcoming payments
        upcoming = self.request.query_params.get('upcoming_days')
        if upcoming:
            try:
                days = int(upcoming)
                end_date = timezone.now().date() + timedelta(days=days)
                queryset = queryset.filter(
                    next_payment_date__lte=end_date,
                    next_payment_date__gte=timezone.now().date()
                )
            except ValueError:
                pass

        # Search by email
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(trainer__email__icontains=search)

        return queryset.order_by('-created_at')

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'list':
            return SubscriptionListSerializer
        return SubscriptionSerializer

    @action(detail=True, methods=['post'], url_path='change-tier')
    def change_tier(self, request: Request, pk: int | None = None) -> Response:
        """
        Change a subscription's tier (upgrade/downgrade).
        POST /api/admin/subscriptions/{id}/change-tier/
        Body: {"new_tier": "PRO", "reason": "Customer requested upgrade"}
        """
        subscription = self.get_object()
        serializer = AdminChangeTierSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        old_tier = subscription.tier
        new_tier = serializer.validated_data['new_tier']
        reason = serializer.validated_data.get('reason', '')

        if old_tier == new_tier:
            return Response(
                {'error': 'New tier is the same as current tier'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Determine change type
        tier_order = ['FREE', 'STARTER', 'PRO', 'ENTERPRISE']
        old_idx = tier_order.index(old_tier)
        new_idx = tier_order.index(new_tier)
        change_type = 'upgrade' if new_idx > old_idx else 'downgrade'

        # Update tier
        subscription.tier = new_tier
        subscription.save()

        # Log the change
        user = cast(User, request.user)
        SubscriptionChange.objects.create(
            subscription=subscription,
            change_type=change_type,
            from_tier=old_tier,
            to_tier=new_tier,
            changed_by=user,
            reason=reason
        )

        return Response(SubscriptionSerializer(subscription).data)

    @action(detail=True, methods=['post'], url_path='change-status')
    def change_status(self, request: Request, pk: int | None = None) -> Response:
        """
        Change a subscription's status.
        POST /api/admin/subscriptions/{id}/change-status/
        Body: {"new_status": "active", "reason": "Payment received"}
        """
        subscription = self.get_object()
        serializer = AdminChangeStatusSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        old_status = subscription.status
        new_status = serializer.validated_data['new_status']
        reason = serializer.validated_data.get('reason', '')

        if old_status == new_status:
            return Response(
                {'error': 'New status is the same as current status'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update status
        subscription.status = new_status

        # Clear past due if activating
        if new_status == 'active' and old_status == 'past_due':
            subscription.past_due_amount = Decimal('0.00')
            subscription.past_due_since = None
            subscription.failed_payment_count = 0

        subscription.save()

        # Log the change
        user = cast(User, request.user)
        SubscriptionChange.objects.create(
            subscription=subscription,
            change_type='admin_adjust',
            from_status=old_status,
            to_status=new_status,
            changed_by=user,
            reason=reason
        )

        return Response(SubscriptionSerializer(subscription).data)

    @action(detail=True, methods=['post'], url_path='update-notes')
    def update_notes(self, request: Request, pk: int | None = None) -> Response:
        """
        Update admin notes for a subscription.
        POST /api/admin/subscriptions/{id}/update-notes/
        Body: {"admin_notes": "Customer called about billing issue"}
        """
        subscription = self.get_object()
        serializer = AdminUpdateNotesSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        subscription.admin_notes = serializer.validated_data.get('admin_notes', '')
        subscription.save()

        return Response(SubscriptionSerializer(subscription).data)

    @action(detail=True, methods=['get'], url_path='payment-history')
    def payment_history(self, request: Request, pk: int | None = None) -> Response:
        """
        Get full payment history for a subscription.
        GET /api/admin/subscriptions/{id}/payment-history/
        """
        subscription = self.get_object()
        payments = subscription.payments.all()
        serializer = PaymentHistorySerializer(payments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='change-history')
    def change_history(self, request: Request, pk: int | None = None) -> Response:
        """
        Get full change history for a subscription.
        GET /api/admin/subscriptions/{id}/change-history/
        """
        subscription = self.get_object()
        changes = subscription.changes.all()
        serializer = SubscriptionChangeSerializer(changes, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='record-payment')
    def record_payment(self, request: Request, pk: int | None = None) -> Response:
        """
        Manually record a payment (for offline payments).
        POST /api/admin/subscriptions/{id}/record-payment/
        Body: {"amount": "79.00", "description": "Manual payment via check"}
        """
        subscription = self.get_object()
        amount = request.data.get('amount')
        description = request.data.get('description', 'Manual payment')

        if not amount:
            return Response(
                {'error': 'Amount is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            amount = Decimal(amount)
        except:
            return Response(
                {'error': 'Invalid amount format'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create payment record
        PaymentHistory.objects.create(
            subscription=subscription,
            amount=amount,
            status='succeeded',
            description=description
        )

        # Update subscription
        subscription.last_payment_date = timezone.now().date()
        subscription.last_payment_amount = amount

        # If past due and payment covers it
        if amount >= subscription.past_due_amount:
            subscription.past_due_amount = Decimal('0.00')
            subscription.past_due_since = None
            subscription.failed_payment_count = 0
            if subscription.status == 'past_due':
                subscription.status = 'active'
        else:
            subscription.past_due_amount -= amount

        subscription.save()

        return Response(SubscriptionSerializer(subscription).data)


class AdminTrainersView(APIView):
    """
    List all trainers with their subscription info.
    GET /api/admin/trainers/
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request: Request) -> Response:
        trainers = User.objects.filter(role=User.Role.TRAINER).select_related('subscription')

        # Search filter
        search = request.query_params.get('search')
        if search:
            trainers = trainers.filter(
                Q(email__icontains=search) |
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search)
            )

        # Status filter
        active_only = request.query_params.get('active')
        if active_only == 'true':
            trainers = trainers.filter(is_active=True)

        result = []
        for trainer in trainers:
            subscription = getattr(trainer, 'subscription', None)
            result.append({
                'id': trainer.id,
                'email': trainer.email,
                'first_name': trainer.first_name,
                'last_name': trainer.last_name,
                'is_active': trainer.is_active,
                'created_at': trainer.created_at.isoformat(),
                'trainee_count': trainer.get_active_trainees_count(),
                'subscription': {
                    'id': subscription.id if subscription else None,
                    'tier': subscription.tier if subscription else None,
                    'status': subscription.status if subscription else None,
                    'next_payment_date': subscription.next_payment_date.isoformat() if subscription and subscription.next_payment_date else None,
                    'past_due_amount': str(subscription.past_due_amount) if subscription else '0.00',
                } if subscription else None
            })

        return Response(result)


class AdminImpersonateTrainerView(APIView):
    """
    POST: Admin impersonates a trainer.
    Returns JWT tokens for the trainer account.
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request: Request, trainer_id: int) -> Response:
        try:
            trainer = User.objects.get(id=trainer_id, role=User.Role.TRAINER)
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainer not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Generate tokens for trainer with impersonation metadata
        current_user = cast(User, request.user)
        refresh = RefreshToken.for_user(trainer)
        refresh['impersonating'] = True
        refresh['original_user_id'] = current_user.id
        refresh['is_admin_impersonation'] = True

        logger.info(f"Admin {current_user.email} started impersonating trainer {trainer.email}")

        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'trainer': {
                'id': trainer.id,
                'email': trainer.email,
                'first_name': trainer.first_name,
                'last_name': trainer.last_name,
                'role': trainer.role,
            },
            'message': f'Now logged in as {trainer.email}'
        })


class AdminEndImpersonationView(APIView):
    """
    POST: End admin impersonation session and return to admin account.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        # The frontend should have stored the original admin tokens
        # This endpoint just logs the end of impersonation
        user = cast(User, request.user)
        logger.info(f"Impersonation session ended for user {user.email}")

        return Response({
            'message': 'Impersonation session ended',
            'return_to_admin': True
        })


class AdminPastDueView(APIView):
    """
    List all past due subscriptions.
    GET /api/admin/past-due/
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request: Request) -> Response:
        past_due_subs = Subscription.objects.filter(
            Q(status='past_due') | Q(past_due_amount__gt=0)
        ).select_related('trainer').order_by('-past_due_since')

        serializer = SubscriptionListSerializer(past_due_subs, many=True)
        return Response(serializer.data)


class AdminUpcomingPaymentsView(APIView):
    """
    List upcoming payments.
    GET /api/admin/upcoming-payments/?days=7
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request: Request) -> Response:
        days = int(request.query_params.get('days', 7))
        today = timezone.now().date()
        end_date = today + timedelta(days=days)

        upcoming = Subscription.objects.filter(
            next_payment_date__gte=today,
            next_payment_date__lte=end_date,
            status='active'
        ).select_related('trainer').order_by('next_payment_date')

        serializer = SubscriptionListSerializer(upcoming, many=True)
        return Response(serializer.data)


# ============ Subscription Tier Management (Admin) ============

class AdminSubscriptionTierViewSet(viewsets.ModelViewSet[SubscriptionTier]):
    """
    Admin viewset for managing subscription tiers.
    GET /api/admin/tiers/ - List all tiers
    POST /api/admin/tiers/ - Create a new tier
    GET /api/admin/tiers/{id}/ - Get tier details
    PUT /api/admin/tiers/{id}/ - Update tier
    DELETE /api/admin/tiers/{id}/ - Delete tier
    """
    permission_classes = [IsAuthenticated, IsAdminUser]
    queryset = SubscriptionTier.objects.all().order_by('sort_order', 'price')

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action in ['create', 'update', 'partial_update']:
            return SubscriptionTierCreateUpdateSerializer
        return SubscriptionTierSerializer

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        tier = self.get_object()
        # Check if any subscriptions use this tier
        subscription_count = Subscription.objects.filter(tier=tier.name).count()
        if subscription_count > 0:
            return Response(
                {'error': f'Cannot delete tier with {subscription_count} active subscriptions. Deactivate it instead.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        return super().destroy(request, *args, **kwargs)

    @action(detail=False, methods=['post'], url_path='seed-defaults')
    def seed_defaults(self, request: Request) -> Response:
        """
        Seed default tiers if they don't exist.
        POST /api/admin/tiers/seed-defaults/
        """
        SubscriptionTier.seed_default_tiers()
        tiers = SubscriptionTier.objects.all().order_by('sort_order')
        serializer = SubscriptionTierSerializer(tiers, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='toggle-active')
    def toggle_active(self, request: Request, pk: int | None = None) -> Response:
        """
        Toggle tier active status.
        POST /api/admin/tiers/{id}/toggle-active/
        """
        tier = self.get_object()
        tier.is_active = not tier.is_active
        tier.save()
        return Response(SubscriptionTierSerializer(tier).data)


class PublicSubscriptionTiersView(APIView):
    """
    List active subscription tiers (public).
    GET /api/admin/tiers/public/
    """
    permission_classes = []  # Public endpoint

    def get(self, request: Request) -> Response:
        tiers = SubscriptionTier.objects.filter(is_active=True).order_by('sort_order', 'price')
        serializer = SubscriptionTierSerializer(tiers, many=True)
        return Response(serializer.data)


# ============ Coupon Management (Admin) ============

class AdminCouponViewSet(viewsets.ModelViewSet[Coupon]):
    """
    Admin viewset for managing all coupons.
    GET /api/admin/coupons/ - List all coupons
    POST /api/admin/coupons/ - Create a new coupon
    GET /api/admin/coupons/{id}/ - Get coupon details
    PUT /api/admin/coupons/{id}/ - Update coupon
    DELETE /api/admin/coupons/{id}/ - Delete coupon
    """
    permission_classes = [IsAuthenticated, IsAdminUser]
    queryset = Coupon.objects.all().order_by('-created_at')

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'create':
            return CouponCreateSerializer
        if self.action in ['update', 'partial_update']:
            return CouponUpdateSerializer
        if self.action == 'list':
            return CouponListSerializer
        return CouponSerializer

    def perform_create(self, serializer: BaseSerializer[Coupon]) -> None:
        user = cast(User, self.request.user)
        serializer.save(created_by_admin=user)

    def get_queryset(self) -> QuerySet[Coupon]:
        queryset = super().get_queryset()

        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by type
        type_filter = self.request.query_params.get('type')
        if type_filter:
            queryset = queryset.filter(coupon_type=type_filter)

        # Filter by applies_to
        applies_to = self.request.query_params.get('applies_to')
        if applies_to:
            queryset = queryset.filter(applies_to=applies_to)

        # Search by code
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(code__icontains=search)

        return queryset

    @action(detail=True, methods=['post'], url_path='revoke')
    def revoke(self, request: Request, pk: int | None = None) -> Response:
        """
        Revoke a coupon.
        POST /api/admin/coupons/{id}/revoke/
        """
        coupon = self.get_object()
        coupon.revoke()
        return Response(CouponSerializer(coupon).data)

    @action(detail=True, methods=['post'], url_path='reactivate')
    def reactivate(self, request: Request, pk: int | None = None) -> Response:
        """
        Reactivate a revoked coupon.
        POST /api/admin/coupons/{id}/reactivate/
        """
        coupon = self.get_object()
        if coupon.status == Coupon.Status.EXHAUSTED:
            return Response(
                {'error': 'Cannot reactivate exhausted coupon'},
                status=status.HTTP_400_BAD_REQUEST
            )
        coupon.status = Coupon.Status.ACTIVE
        coupon.save()
        return Response(CouponSerializer(coupon).data)

    @action(detail=True, methods=['get'], url_path='usages')
    def usages(self, request: Request, pk: int | None = None) -> Response:
        """
        Get all usages of a coupon.
        GET /api/admin/coupons/{id}/usages/
        """
        coupon = self.get_object()
        usages = coupon.usages.all().select_related('user')

        data = []
        for usage in usages:
            data.append({
                'id': usage.id,
                'user_email': usage.user.email,
                'user_name': f"{usage.user.first_name} {usage.user.last_name}".strip(),
                'discount_amount': str(usage.discount_amount),
                'used_at': usage.used_at.isoformat(),
            })

        return Response(data)
