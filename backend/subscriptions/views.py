"""
Admin views for subscription and trainer management.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.views import APIView
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal

from .models import Subscription, PaymentHistory, SubscriptionChange
from .serializers import (
    SubscriptionSerializer,
    SubscriptionListSerializer,
    PaymentHistorySerializer,
    SubscriptionChangeSerializer,
    AdminChangeTierSerializer,
    AdminChangeStatusSerializer,
    AdminUpdateNotesSerializer,
)
from users.models import User


class IsAdminUser(BasePermission):
    """Permission class to check if user is admin."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.is_admin()


class AdminDashboardView(APIView):
    """
    Admin dashboard with overview statistics.
    GET /api/admin/dashboard/
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
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


class AdminSubscriptionViewSet(viewsets.ModelViewSet):
    """
    Admin viewset for managing subscriptions.
    """
    permission_classes = [IsAuthenticated, IsAdminUser]
    serializer_class = SubscriptionSerializer

    def get_queryset(self):
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

    def get_serializer_class(self):
        if self.action == 'list':
            return SubscriptionListSerializer
        return SubscriptionSerializer

    @action(detail=True, methods=['post'], url_path='change-tier')
    def change_tier(self, request, pk=None):
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
        SubscriptionChange.objects.create(
            subscription=subscription,
            change_type=change_type,
            from_tier=old_tier,
            to_tier=new_tier,
            changed_by=request.user,
            reason=reason
        )

        return Response(SubscriptionSerializer(subscription).data)

    @action(detail=True, methods=['post'], url_path='change-status')
    def change_status(self, request, pk=None):
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
        SubscriptionChange.objects.create(
            subscription=subscription,
            change_type='admin_adjust',
            from_status=old_status,
            to_status=new_status,
            changed_by=request.user,
            reason=reason
        )

        return Response(SubscriptionSerializer(subscription).data)

    @action(detail=True, methods=['post'], url_path='update-notes')
    def update_notes(self, request, pk=None):
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
    def payment_history(self, request, pk=None):
        """
        Get full payment history for a subscription.
        GET /api/admin/subscriptions/{id}/payment-history/
        """
        subscription = self.get_object()
        payments = subscription.payments.all()
        serializer = PaymentHistorySerializer(payments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'], url_path='change-history')
    def change_history(self, request, pk=None):
        """
        Get full change history for a subscription.
        GET /api/admin/subscriptions/{id}/change-history/
        """
        subscription = self.get_object()
        changes = subscription.changes.all()
        serializer = SubscriptionChangeSerializer(changes, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='record-payment')
    def record_payment(self, request, pk=None):
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

    def get(self, request):
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


class AdminPastDueView(APIView):
    """
    List all past due subscriptions.
    GET /api/admin/past-due/
    """
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get(self, request):
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

    def get(self, request):
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
