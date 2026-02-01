"""
Payment/Stripe related views.
"""
from __future__ import annotations

import logging
from typing import Any, cast

from datetime import datetime, timezone as tz

from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.views import APIView
from django.utils import timezone
from django.conf import settings
from decimal import Decimal

import stripe

from subscriptions.models import (
    StripeAccount, TrainerPricing, TraineePayment, TraineeSubscription
)
from subscriptions.serializers import (
    StripeAccountSerializer,
    CreateCheckoutSessionSerializer,
)
from users.models import User

logger = logging.getLogger(__name__)

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


class IsTrainer(BasePermission):
    """Permission class to check if user is a trainer."""
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user.is_authenticated and request.user.role == 'TRAINER')


class IsTrainee(BasePermission):
    """Permission class to check if user is a trainee."""
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user.is_authenticated and request.user.is_trainee())


class StripeConnectOnboardView(APIView):
    """
    Create Stripe Connect account and return onboarding URL.
    POST /api/payments/connect/onboard/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request: Request) -> Response:
        trainer = cast(User, request.user)

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

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)

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
                stripe_account.charges_enabled = bool(account.charges_enabled)
                stripe_account.payouts_enabled = bool(account.payouts_enabled)
                stripe_account.details_submitted = bool(account.details_submitted)

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

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)

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


class CreateSubscriptionCheckoutView(APIView):
    """
    Create Stripe Checkout session for subscription.
    POST /api/payments/checkout/subscription/
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def post(self, request: Request) -> Response:
        trainee = cast(User, request.user)
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

    def post(self, request: Request) -> Response:
        trainee = cast(User, request.user)
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


class StripeWebhookView(APIView):
    """
    Handle Stripe webhook events.
    POST /api/payments/webhook/
    """
    permission_classes = []  # No authentication for webhooks

    def post(self, request: Request) -> Response:
        payload = request.body
        sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')

        try:
            event = stripe.Webhook.construct_event(  # type: ignore[no-untyped-call]
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

    def _handle_checkout_completed(self, session: dict[str, Any]) -> None:
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

    def _handle_invoice_paid(self, invoice: dict[str, Any]) -> None:
        """Handle successful invoice payment (recurring)."""
        subscription_id = invoice.get('subscription')
        if not subscription_id:
            return

        try:
            subscription = TraineeSubscription.objects.get(stripe_subscription_id=subscription_id)

            # Update period dates
            if invoice.get('period_start'):
                subscription.current_period_start = datetime.fromtimestamp(
                    invoice['period_start'], tz=tz.utc
                )
            if invoice.get('period_end'):
                subscription.current_period_end = datetime.fromtimestamp(
                    invoice['period_end'], tz=tz.utc
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

    def _handle_invoice_payment_failed(self, invoice: dict[str, Any]) -> None:
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

    def _handle_subscription_deleted(self, subscription_data: dict[str, Any]) -> None:
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

    def _handle_subscription_updated(self, subscription_data: dict[str, Any]) -> None:
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
                subscription.current_period_start = datetime.fromtimestamp(
                    subscription_data['current_period_start'], tz=tz.utc
                )
            if subscription_data.get('current_period_end'):
                subscription.current_period_end = datetime.fromtimestamp(
                    subscription_data['current_period_end'], tz=tz.utc
                )

            subscription.save()
            logger.info(f"Subscription {subscription_id} updated")

        except TraineeSubscription.DoesNotExist:
            logger.warning(f"Subscription not found: {subscription_id}")

    def _handle_account_updated(self, account: dict[str, Any]) -> None:
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
