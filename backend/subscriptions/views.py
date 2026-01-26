"""
Admin views for subscription and trainer management.
"""
import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.views import APIView
from django.db.models import Sum, Count, Q
from django.utils import timezone
from django.conf import settings
from datetime import timedelta
from decimal import Decimal

import stripe

from .models import (
    Subscription, PaymentHistory, SubscriptionChange,
    StripeAccount, TrainerPricing, TraineePayment, TraineeSubscription
)
from .serializers import (
    SubscriptionSerializer,
    SubscriptionListSerializer,
    PaymentHistorySerializer,
    SubscriptionChangeSerializer,
    AdminChangeTierSerializer,
    AdminChangeStatusSerializer,
    AdminUpdateNotesSerializer,
    StripeAccountSerializer,
    TrainerPricingSerializer,
    TrainerPricingUpdateSerializer,
    TraineePaymentSerializer,
    TraineeSubscriptionSerializer,
    CreateCheckoutSessionSerializer,
    TrainerPublicPricingSerializer,
)
from users.models import User

logger = logging.getLogger(__name__)

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


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


# ============ Stripe Connect / Payment Views ============

class IsTrainer(BasePermission):
    """Permission class to check if user is a trainer."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.is_trainer()


class IsTrainee(BasePermission):
    """Permission class to check if user is a trainee."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.is_trainee()


class StripeConnectOnboardView(APIView):
    """
    Create Stripe Connect account and return onboarding URL.
    POST /api/payments/connect/onboard/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request):
        trainer = request.user

        # Get or create StripeAccount
        stripe_account, created = StripeAccount.objects.get_or_create(
            trainer=trainer,
            defaults={'status': StripeAccount.Status.PENDING}
        )

        try:
            # Create Stripe Connect account if not exists
            if not stripe_account.stripe_account_id:
                account = stripe.Account.create(
                    type='express',
                    country='US',  # Default to US, can be made configurable
                    email=trainer.email,
                    capabilities={
                        'card_payments': {'requested': True},
                        'transfers': {'requested': True},
                    },
                    business_type='individual',
                    metadata={
                        'trainer_id': str(trainer.id),
                        'trainer_email': trainer.email,
                    }
                )
                stripe_account.stripe_account_id = account.id
                stripe_account.save()
            else:
                # Retrieve existing account
                account = stripe.Account.retrieve(stripe_account.stripe_account_id)

            # Create account link for onboarding
            account_link = stripe.AccountLink.create(
                account=stripe_account.stripe_account_id,
                refresh_url=settings.STRIPE_CONNECT_REFRESH_URL,
                return_url=settings.STRIPE_CONNECT_RETURN_URL,
                type='account_onboarding',
            )

            return Response({
                'onboarding_url': account_link.url,
                'stripe_account_id': stripe_account.stripe_account_id,
            })

        except stripe.error.StripeError as e:
            logger.error(f"Stripe Connect error for trainer {trainer.id}: {str(e)}")
            return Response(
                {'error': 'Failed to create Stripe account. Please try again.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class StripeConnectStatusView(APIView):
    """
    Get status of trainer's Stripe Connect account.
    GET /api/payments/connect/status/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        trainer = request.user

        try:
            stripe_account = StripeAccount.objects.get(trainer=trainer)
        except StripeAccount.DoesNotExist:
            return Response({
                'connected': False,
                'status': 'not_started',
                'message': 'Stripe account not connected. Start onboarding to receive payments.',
            })

        # Fetch latest status from Stripe
        if stripe_account.stripe_account_id:
            try:
                account = stripe.Account.retrieve(stripe_account.stripe_account_id)

                # Update local status
                stripe_account.charges_enabled = account.charges_enabled
                stripe_account.payouts_enabled = account.payouts_enabled
                stripe_account.details_submitted = account.details_submitted

                if account.charges_enabled and account.payouts_enabled:
                    stripe_account.status = StripeAccount.Status.ACTIVE
                    stripe_account.onboarding_completed = True
                elif account.details_submitted:
                    stripe_account.status = StripeAccount.Status.RESTRICTED
                else:
                    stripe_account.status = StripeAccount.Status.PENDING

                stripe_account.save()

            except stripe.error.StripeError as e:
                logger.error(f"Error fetching Stripe account: {str(e)}")

        serializer = StripeAccountSerializer(stripe_account)
        return Response({
            'connected': True,
            **serializer.data
        })


class StripeConnectDashboardView(APIView):
    """
    Get Stripe Express dashboard login link for trainer.
    GET /api/payments/connect/dashboard/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        trainer = request.user

        try:
            stripe_account = StripeAccount.objects.get(trainer=trainer)
        except StripeAccount.DoesNotExist:
            return Response(
                {'error': 'Stripe account not connected'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if not stripe_account.stripe_account_id:
            return Response(
                {'error': 'Stripe account not configured'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            login_link = stripe.Account.create_login_link(
                stripe_account.stripe_account_id
            )
            return Response({'dashboard_url': login_link.url})
        except stripe.error.StripeError as e:
            logger.error(f"Error creating login link: {str(e)}")
            return Response(
                {'error': 'Failed to create dashboard link'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TrainerPricingView(APIView):
    """
    Get or update trainer's pricing.
    GET /api/payments/pricing/
    POST /api/payments/pricing/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        trainer = request.user
        pricing, created = TrainerPricing.objects.get_or_create(trainer=trainer)
        serializer = TrainerPricingSerializer(pricing)
        return Response(serializer.data)

    def post(self, request):
        trainer = request.user
        pricing, created = TrainerPricing.objects.get_or_create(trainer=trainer)

        serializer = TrainerPricingUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data

        # Update fields
        if 'monthly_subscription_price' in data:
            pricing.monthly_subscription_price = data['monthly_subscription_price']
        if 'monthly_subscription_enabled' in data:
            pricing.monthly_subscription_enabled = data['monthly_subscription_enabled']
        if 'one_time_consultation_price' in data:
            pricing.one_time_consultation_price = data['one_time_consultation_price']
        if 'one_time_consultation_enabled' in data:
            pricing.one_time_consultation_enabled = data['one_time_consultation_enabled']
        if 'currency' in data:
            pricing.currency = data['currency']

        # Create/update Stripe Price for subscription if needed
        if pricing.monthly_subscription_enabled and pricing.monthly_subscription_price > 0:
            try:
                stripe_account = StripeAccount.objects.get(trainer=trainer)
                if stripe_account.is_ready_for_payments():
                    # Create a new price in Stripe
                    price = stripe.Price.create(
                        unit_amount=int(pricing.monthly_subscription_price * 100),
                        currency=pricing.currency,
                        recurring={'interval': 'month'},
                        product_data={
                            'name': f"Coaching with {trainer.first_name} {trainer.last_name}".strip(),
                        },
                        stripe_account=stripe_account.stripe_account_id,
                    )
                    pricing.stripe_monthly_price_id = price.id
            except (StripeAccount.DoesNotExist, stripe.error.StripeError) as e:
                logger.warning(f"Could not create Stripe price: {str(e)}")

        pricing.save()
        return Response(TrainerPricingSerializer(pricing).data)


class TrainerPublicPricingView(APIView):
    """
    Get public pricing info for a trainer (for trainees to view).
    GET /api/payments/trainers/<trainer_id>/pricing/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, trainer_id):
        try:
            trainer = User.objects.get(id=trainer_id, role=User.Role.TRAINER)
            pricing = TrainerPricing.objects.get(trainer=trainer)
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainer not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except TrainerPricing.DoesNotExist:
            return Response(
                {'error': 'Trainer has not set up pricing'},
                status=status.HTTP_404_NOT_FOUND
            )

        serializer = TrainerPublicPricingSerializer(pricing)
        return Response(serializer.data)


class CreateSubscriptionCheckoutView(APIView):
    """
    Create Stripe Checkout session for subscription.
    POST /api/payments/checkout/subscription/
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request):
        trainee = request.user
        serializer = CreateCheckoutSessionSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        trainer_id = serializer.validated_data['trainer_id']

        try:
            trainer = User.objects.get(id=trainer_id, role=User.Role.TRAINER)
            pricing = TrainerPricing.objects.get(trainer=trainer)
            stripe_account = StripeAccount.objects.get(trainer=trainer)
        except User.DoesNotExist:
            return Response({'error': 'Trainer not found'}, status=status.HTTP_404_NOT_FOUND)
        except TrainerPricing.DoesNotExist:
            return Response({'error': 'Trainer has not set up pricing'}, status=status.HTTP_400_BAD_REQUEST)
        except StripeAccount.DoesNotExist:
            return Response({'error': 'Trainer has not connected Stripe'}, status=status.HTTP_400_BAD_REQUEST)

        if not stripe_account.is_ready_for_payments():
            return Response({'error': 'Trainer account is not ready for payments'}, status=status.HTTP_400_BAD_REQUEST)

        if not pricing.monthly_subscription_enabled:
            return Response({'error': 'Monthly subscription is not available'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if trainee already has active subscription with this trainer
        existing_sub = TraineeSubscription.objects.filter(
            trainee=trainee,
            trainer=trainer,
            status=TraineeSubscription.Status.ACTIVE
        ).first()

        if existing_sub:
            return Response(
                {'error': 'You already have an active subscription with this trainer'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Calculate platform fee
            amount_cents = int(pricing.monthly_subscription_price * 100)
            platform_fee_cents = int(amount_cents * settings.STRIPE_PLATFORM_FEE_PERCENT / 100)

            # Get or set success/cancel URLs
            success_url = serializer.validated_data.get('success_url', settings.STRIPE_CHECKOUT_SUCCESS_URL)
            cancel_url = serializer.validated_data.get('cancel_url', settings.STRIPE_CHECKOUT_CANCEL_URL)

            # Create Checkout session
            session = stripe.checkout.Session.create(
                mode='subscription',
                payment_method_types=['card'],
                line_items=[{
                    'price_data': {
                        'currency': pricing.currency,
                        'unit_amount': amount_cents,
                        'recurring': {'interval': 'month'},
                        'product_data': {
                            'name': f"Monthly Coaching - {trainer.first_name} {trainer.last_name}".strip(),
                            'description': f"Monthly coaching subscription with {trainer.email}",
                        },
                    },
                    'quantity': 1,
                }],
                subscription_data={
                    'application_fee_percent': settings.STRIPE_PLATFORM_FEE_PERCENT,
                    'metadata': {
                        'trainee_id': str(trainee.id),
                        'trainer_id': str(trainer.id),
                        'payment_type': 'subscription',
                    },
                },
                success_url=success_url + '?session_id={CHECKOUT_SESSION_ID}',
                cancel_url=cancel_url,
                customer_email=trainee.email,
                metadata={
                    'trainee_id': str(trainee.id),
                    'trainer_id': str(trainer.id),
                    'payment_type': 'subscription',
                },
                stripe_account=stripe_account.stripe_account_id,
            )

            # Create pending payment record
            TraineePayment.objects.create(
                trainee=trainee,
                trainer=trainer,
                payment_type=TraineePayment.Type.SUBSCRIPTION,
                status=TraineePayment.Status.PENDING,
                amount=pricing.monthly_subscription_price,
                platform_fee=Decimal(platform_fee_cents) / 100,
                currency=pricing.currency,
                stripe_checkout_session_id=session.id,
                description=f"Monthly subscription - {trainer.email}",
            )

            return Response({
                'checkout_url': session.url,
                'session_id': session.id,
            })

        except stripe.error.StripeError as e:
            logger.error(f"Stripe checkout error: {str(e)}")
            return Response(
                {'error': 'Failed to create checkout session'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CreateOneTimeCheckoutView(APIView):
    """
    Create Stripe Checkout session for one-time payment.
    POST /api/payments/checkout/one-time/
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request):
        trainee = request.user
        serializer = CreateCheckoutSessionSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        trainer_id = serializer.validated_data['trainer_id']

        try:
            trainer = User.objects.get(id=trainer_id, role=User.Role.TRAINER)
            pricing = TrainerPricing.objects.get(trainer=trainer)
            stripe_account = StripeAccount.objects.get(trainer=trainer)
        except User.DoesNotExist:
            return Response({'error': 'Trainer not found'}, status=status.HTTP_404_NOT_FOUND)
        except TrainerPricing.DoesNotExist:
            return Response({'error': 'Trainer has not set up pricing'}, status=status.HTTP_400_BAD_REQUEST)
        except StripeAccount.DoesNotExist:
            return Response({'error': 'Trainer has not connected Stripe'}, status=status.HTTP_400_BAD_REQUEST)

        if not stripe_account.is_ready_for_payments():
            return Response({'error': 'Trainer account is not ready for payments'}, status=status.HTTP_400_BAD_REQUEST)

        if not pricing.one_time_consultation_enabled:
            return Response({'error': 'One-time consultation is not available'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Calculate platform fee
            amount_cents = int(pricing.one_time_consultation_price * 100)
            platform_fee_cents = int(amount_cents * settings.STRIPE_PLATFORM_FEE_PERCENT / 100)

            # Get or set success/cancel URLs
            success_url = serializer.validated_data.get('success_url', settings.STRIPE_CHECKOUT_SUCCESS_URL)
            cancel_url = serializer.validated_data.get('cancel_url', settings.STRIPE_CHECKOUT_CANCEL_URL)

            # Create Checkout session
            session = stripe.checkout.Session.create(
                mode='payment',
                payment_method_types=['card'],
                line_items=[{
                    'price_data': {
                        'currency': pricing.currency,
                        'unit_amount': amount_cents,
                        'product_data': {
                            'name': f"Consultation - {trainer.first_name} {trainer.last_name}".strip(),
                            'description': f"One-time consultation with {trainer.email}",
                        },
                    },
                    'quantity': 1,
                }],
                payment_intent_data={
                    'application_fee_amount': platform_fee_cents,
                    'metadata': {
                        'trainee_id': str(trainee.id),
                        'trainer_id': str(trainer.id),
                        'payment_type': 'one_time',
                    },
                },
                success_url=success_url + '?session_id={CHECKOUT_SESSION_ID}',
                cancel_url=cancel_url,
                customer_email=trainee.email,
                metadata={
                    'trainee_id': str(trainee.id),
                    'trainer_id': str(trainer.id),
                    'payment_type': 'one_time',
                },
                stripe_account=stripe_account.stripe_account_id,
            )

            # Create pending payment record
            TraineePayment.objects.create(
                trainee=trainee,
                trainer=trainer,
                payment_type=TraineePayment.Type.ONE_TIME,
                status=TraineePayment.Status.PENDING,
                amount=pricing.one_time_consultation_price,
                platform_fee=Decimal(platform_fee_cents) / 100,
                currency=pricing.currency,
                stripe_checkout_session_id=session.id,
                description=f"One-time consultation - {trainer.email}",
            )

            return Response({
                'checkout_url': session.url,
                'session_id': session.id,
            })

        except stripe.error.StripeError as e:
            logger.error(f"Stripe checkout error: {str(e)}")
            return Response(
                {'error': 'Failed to create checkout session'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TraineeSubscriptionView(APIView):
    """
    Get trainee's active subscriptions.
    GET /api/payments/my-subscription/
    DELETE /api/payments/my-subscription/<subscription_id>/
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request):
        trainee = request.user
        subscriptions = TraineeSubscription.objects.filter(
            trainee=trainee
        ).select_related('trainer').order_by('-created_at')

        serializer = TraineeSubscriptionSerializer(subscriptions, many=True)
        return Response(serializer.data)

    def delete(self, request, subscription_id=None):
        """Cancel a subscription."""
        if not subscription_id:
            return Response({'error': 'Subscription ID required'}, status=status.HTTP_400_BAD_REQUEST)

        trainee = request.user

        try:
            subscription = TraineeSubscription.objects.get(
                id=subscription_id,
                trainee=trainee,
                status=TraineeSubscription.Status.ACTIVE
            )
        except TraineeSubscription.DoesNotExist:
            return Response({'error': 'Subscription not found'}, status=status.HTTP_404_NOT_FOUND)

        try:
            # Cancel in Stripe
            if subscription.stripe_subscription_id:
                stripe_account = StripeAccount.objects.get(trainer=subscription.trainer)
                stripe.Subscription.delete(
                    subscription.stripe_subscription_id,
                    stripe_account=stripe_account.stripe_account_id,
                )

            # Update local record
            subscription.status = TraineeSubscription.Status.CANCELED
            subscription.canceled_at = timezone.now()
            subscription.save()

            return Response({'message': 'Subscription canceled successfully'})

        except stripe.error.StripeError as e:
            logger.error(f"Error canceling subscription: {str(e)}")
            return Response(
                {'error': 'Failed to cancel subscription'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TraineePaymentHistoryView(APIView):
    """
    Get trainee's payment history.
    GET /api/payments/my-payments/
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request):
        trainee = request.user
        payments = TraineePayment.objects.filter(
            trainee=trainee
        ).select_related('trainer').order_by('-created_at')

        serializer = TraineePaymentSerializer(payments, many=True)
        return Response(serializer.data)


class TrainerPaymentHistoryView(APIView):
    """
    Get trainer's received payments.
    GET /api/payments/trainer/payments/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        trainer = request.user
        payments = TraineePayment.objects.filter(
            trainer=trainer
        ).select_related('trainee').order_by('-created_at')

        serializer = TraineePaymentSerializer(payments, many=True)
        return Response(serializer.data)


class TrainerSubscribersView(APIView):
    """
    Get trainer's active subscribers.
    GET /api/payments/trainer/subscribers/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        trainer = request.user
        subscriptions = TraineeSubscription.objects.filter(
            trainer=trainer,
            status=TraineeSubscription.Status.ACTIVE
        ).select_related('trainee').order_by('-created_at')

        serializer = TraineeSubscriptionSerializer(subscriptions, many=True)
        return Response(serializer.data)


class StripeWebhookView(APIView):
    """
    Handle Stripe webhook events.
    POST /api/payments/webhook/
    """
    permission_classes = []  # No authentication for webhooks

    def post(self, request):
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')

        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
            )
        except ValueError:
            logger.error("Invalid Stripe webhook payload")
            return Response({'error': 'Invalid payload'}, status=status.HTTP_400_BAD_REQUEST)
        except stripe.error.SignatureVerificationError:
            logger.error("Invalid Stripe webhook signature")
            return Response({'error': 'Invalid signature'}, status=status.HTTP_400_BAD_REQUEST)

        event_type = event['type']
        data = event['data']['object']

        logger.info(f"Received Stripe webhook: {event_type}")

        # Handle different event types
        if event_type == 'checkout.session.completed':
            self._handle_checkout_completed(data)
        elif event_type == 'invoice.paid':
            self._handle_invoice_paid(data)
        elif event_type == 'invoice.payment_failed':
            self._handle_invoice_payment_failed(data)
        elif event_type == 'customer.subscription.deleted':
            self._handle_subscription_deleted(data)
        elif event_type == 'customer.subscription.updated':
            self._handle_subscription_updated(data)
        elif event_type == 'account.updated':
            self._handle_account_updated(data)

        return Response({'received': True})

    def _handle_checkout_completed(self, session):
        """Handle successful checkout completion."""
        session_id = session['id']
        metadata = session.get('metadata', {})
        payment_type = metadata.get('payment_type')
        trainee_id = metadata.get('trainee_id')
        trainer_id = metadata.get('trainer_id')

        # Update payment record
        try:
            payment = TraineePayment.objects.get(stripe_checkout_session_id=session_id)
            payment.status = TraineePayment.Status.SUCCEEDED
            payment.paid_at = timezone.now()

            if session.get('payment_intent'):
                payment.stripe_payment_intent_id = session['payment_intent']

            payment.save()

            # Create subscription record if this is a subscription
            if payment_type == 'subscription' and session.get('subscription'):
                trainee = User.objects.get(id=trainee_id)
                trainer = User.objects.get(id=trainer_id)

                TraineeSubscription.objects.update_or_create(
                    trainee=trainee,
                    trainer=trainer,
                    defaults={
                        'status': TraineeSubscription.Status.ACTIVE,
                        'stripe_subscription_id': session['subscription'],
                        'amount': payment.amount,
                        'currency': payment.currency,
                        'current_period_start': timezone.now(),
                    }
                )

            logger.info(f"Payment {session_id} marked as succeeded")

        except TraineePayment.DoesNotExist:
            logger.warning(f"Payment record not found for session {session_id}")

    def _handle_invoice_paid(self, invoice):
        """Handle successful invoice payment (recurring)."""
        subscription_id = invoice.get('subscription')
        if not subscription_id:
            return

        try:
            subscription = TraineeSubscription.objects.get(stripe_subscription_id=subscription_id)

            # Update period dates
            if invoice.get('period_start'):
                subscription.current_period_start = timezone.datetime.fromtimestamp(
                    invoice['period_start'], tz=timezone.utc
                )
            if invoice.get('period_end'):
                subscription.current_period_end = timezone.datetime.fromtimestamp(
                    invoice['period_end'], tz=timezone.utc
                )

            subscription.status = TraineeSubscription.Status.ACTIVE
            subscription.save()

            # Create payment record for renewal
            TraineePayment.objects.create(
                trainee=subscription.trainee,
                trainer=subscription.trainer,
                payment_type=TraineePayment.Type.SUBSCRIPTION,
                status=TraineePayment.Status.SUCCEEDED,
                amount=subscription.amount,
                currency=subscription.currency,
                stripe_payment_intent_id=invoice.get('payment_intent', ''),
                description=f"Subscription renewal - {subscription.trainer.email}",
                paid_at=timezone.now(),
            )

            logger.info(f"Invoice paid for subscription {subscription_id}")

        except TraineeSubscription.DoesNotExist:
            logger.warning(f"Subscription not found: {subscription_id}")

    def _handle_invoice_payment_failed(self, invoice):
        """Handle failed invoice payment."""
        subscription_id = invoice.get('subscription')
        if not subscription_id:
            return

        try:
            subscription = TraineeSubscription.objects.get(stripe_subscription_id=subscription_id)
            subscription.status = TraineeSubscription.Status.PAST_DUE
            subscription.save()

            logger.info(f"Subscription {subscription_id} marked as past due")

        except TraineeSubscription.DoesNotExist:
            logger.warning(f"Subscription not found: {subscription_id}")

    def _handle_subscription_deleted(self, subscription_data):
        """Handle subscription cancellation."""
        subscription_id = subscription_data['id']

        try:
            subscription = TraineeSubscription.objects.get(stripe_subscription_id=subscription_id)
            subscription.status = TraineeSubscription.Status.CANCELED
            subscription.canceled_at = timezone.now()
            subscription.save()

            logger.info(f"Subscription {subscription_id} canceled")

        except TraineeSubscription.DoesNotExist:
            logger.warning(f"Subscription not found: {subscription_id}")

    def _handle_subscription_updated(self, subscription_data):
        """Handle subscription updates."""
        subscription_id = subscription_data['id']
        stripe_status = subscription_data.get('status')

        try:
            subscription = TraineeSubscription.objects.get(stripe_subscription_id=subscription_id)

            # Map Stripe status to our status
            status_map = {
                'active': TraineeSubscription.Status.ACTIVE,
                'past_due': TraineeSubscription.Status.PAST_DUE,
                'canceled': TraineeSubscription.Status.CANCELED,
                'unpaid': TraineeSubscription.Status.PAST_DUE,
                'paused': TraineeSubscription.Status.PAUSED,
            }

            if stripe_status in status_map:
                subscription.status = status_map[stripe_status]

            # Update period dates
            if subscription_data.get('current_period_start'):
                subscription.current_period_start = timezone.datetime.fromtimestamp(
                    subscription_data['current_period_start'], tz=timezone.utc
                )
            if subscription_data.get('current_period_end'):
                subscription.current_period_end = timezone.datetime.fromtimestamp(
                    subscription_data['current_period_end'], tz=timezone.utc
                )

            subscription.save()
            logger.info(f"Subscription {subscription_id} updated")

        except TraineeSubscription.DoesNotExist:
            logger.warning(f"Subscription not found: {subscription_id}")

    def _handle_account_updated(self, account):
        """Handle Stripe Connect account updates."""
        account_id = account['id']

        try:
            stripe_account = StripeAccount.objects.get(stripe_account_id=account_id)
            stripe_account.charges_enabled = account.get('charges_enabled', False)
            stripe_account.payouts_enabled = account.get('payouts_enabled', False)
            stripe_account.details_submitted = account.get('details_submitted', False)

            if stripe_account.charges_enabled and stripe_account.payouts_enabled:
                stripe_account.status = StripeAccount.Status.ACTIVE
                stripe_account.onboarding_completed = True
            elif stripe_account.details_submitted:
                stripe_account.status = StripeAccount.Status.RESTRICTED
            else:
                stripe_account.status = StripeAccount.Status.PENDING

            stripe_account.save()
            logger.info(f"Stripe account {account_id} updated")

        except StripeAccount.DoesNotExist:
            logger.warning(f"Stripe account not found: {account_id}")
