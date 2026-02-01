"""
Trainee views for subscription and payment management.
"""
from __future__ import annotations

import logging
from typing import cast

from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, BasePermission
from rest_framework.views import APIView
from django.utils import timezone
from django.conf import settings

import stripe

from subscriptions.models import (
    StripeAccount, TraineePayment, TraineeSubscription
)
from subscriptions.serializers import (
    TraineePaymentSerializer,
    TraineeSubscriptionSerializer,
)
from users.models import User

logger = logging.getLogger(__name__)

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


class IsTrainee(BasePermission):
    """Permission class to check if user is a trainee."""
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user.is_authenticated and request.user.is_trainee())


class TraineeSubscriptionView(APIView):
    """
    Get trainee's active subscriptions.
    GET /api/payments/my-subscription/
    DELETE /api/payments/my-subscription/<subscription_id>/
    """
    permission_classes = [IsAuthenticated, IsTrainee]

    def get(self, request: Request) -> Response:
        trainee = cast(User, request.user)
        subscriptions = TraineeSubscription.objects.filter(
            trainee=trainee
        ).select_related('trainer').order_by('-created_at')

        serializer = TraineeSubscriptionSerializer(subscriptions, many=True)
        return Response(serializer.data)

    def delete(self, request: Request, subscription_id: int | None = None) -> Response:
        """Cancel a subscription."""
        if not subscription_id:
            return Response({'error': 'Subscription ID required'}, status=status.HTTP_400_BAD_REQUEST)

        trainee = cast(User, request.user)

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
                stripe_sub_id: str = subscription.stripe_subscription_id
                stripe.Subscription.cancel(
                    stripe_sub_id,
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

    def get(self, request: Request) -> Response:
        trainee = cast(User, request.user)
        payments = TraineePayment.objects.filter(
            trainee=trainee
        ).select_related('trainer').order_by('-created_at')

        serializer = TraineePaymentSerializer(payments, many=True)
        return Response(serializer.data)
