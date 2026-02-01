"""
Trainer views for coupon management and pricing.
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
from django.db.models.query import QuerySet

import stripe
from django.conf import settings

from subscriptions.models import (
    StripeAccount, TrainerPricing, TraineePayment, TraineeSubscription,
    Coupon
)
from subscriptions.serializers import (
    TrainerPricingSerializer,
    TrainerPricingUpdateSerializer,
    TraineePaymentSerializer,
    TraineeSubscriptionSerializer,
    TrainerPublicPricingSerializer,
    CouponSerializer,
    CouponListSerializer,
    CouponCreateSerializer,
    CouponUpdateSerializer,
    ApplyCouponSerializer,
)
from users.models import User

logger = logging.getLogger(__name__)

# Initialize Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


class IsTrainer(BasePermission):
    """Permission class to check if user is a trainer."""
    def has_permission(self, request: Request, view: APIView) -> bool:
        return bool(request.user.is_authenticated and request.user.role == 'TRAINER')


# ============ Coupon Management (Trainer) ============

class TrainerCouponViewSet(viewsets.ModelViewSet[Coupon]):
    """
    Trainer viewset for managing their coupons.
    GET /api/payments/trainer/coupons/ - List trainer's coupons
    POST /api/payments/trainer/coupons/ - Create a coupon for trainees
    GET /api/payments/trainer/coupons/{id}/ - Get coupon details
    PUT /api/payments/trainer/coupons/{id}/ - Update coupon
    DELETE /api/payments/trainer/coupons/{id}/ - Delete coupon
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get_queryset(self) -> QuerySet[Coupon]:
        user = cast(User, self.request.user)
        return Coupon.objects.filter(
            created_by_trainer=user
        ).order_by('-created_at')

    def get_serializer_class(self) -> type[BaseSerializer[Any]]:
        if self.action == 'create':
            return CouponCreateSerializer
        if self.action in ['update', 'partial_update']:
            return CouponUpdateSerializer
        if self.action == 'list':
            return CouponListSerializer
        return CouponSerializer

    def perform_create(self, serializer: BaseSerializer[Coupon]) -> None:
        # Force trainee coaching coupons only
        user = cast(User, self.request.user)
        serializer.save(
            created_by_trainer=user,
            applies_to=Coupon.AppliesTo.TRAINEE_COACHING
        )

    @action(detail=True, methods=['post'], url_path='revoke')
    def revoke(self, request: Request, pk: int | None = None) -> Response:
        """Revoke a coupon."""
        coupon = self.get_object()
        coupon.revoke()
        return Response(CouponSerializer(coupon).data)

    @action(detail=True, methods=['post'], url_path='reactivate')
    def reactivate(self, request: Request, pk: int | None = None) -> Response:
        """Reactivate a revoked coupon."""
        coupon = self.get_object()
        if coupon.status == Coupon.Status.EXHAUSTED:
            return Response(
                {'error': 'Cannot reactivate exhausted coupon'},
                status=status.HTTP_400_BAD_REQUEST
            )
        coupon.status = Coupon.Status.ACTIVE
        coupon.save()
        return Response(CouponSerializer(coupon).data)


class ValidateCouponView(APIView):
    """
    Validate a coupon code.
    POST /api/payments/coupons/validate/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        serializer = ApplyCouponSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        code = serializer.validated_data['code']

        try:
            coupon = Coupon.objects.get(code=code)
        except Coupon.DoesNotExist:
            return Response(
                {'valid': False, 'error': 'Coupon not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        user = cast(User, request.user)
        can_use, message = coupon.can_be_used_by(user)

        if can_use:
            return Response({
                'valid': True,
                'coupon': CouponSerializer(coupon).data,
                'message': 'Coupon is valid'
            })
        else:
            return Response({
                'valid': False,
                'error': message
            }, status=status.HTTP_400_BAD_REQUEST)


class TrainerPricingView(APIView):
    """
    Get or update trainer's pricing.
    GET /api/payments/pricing/
    POST /api/payments/pricing/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        pricing, created = TrainerPricing.objects.get_or_create(trainer=trainer)
        serializer = TrainerPricingSerializer(pricing)
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        trainer = cast(User, request.user)
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

    def get(self, request: Request, trainer_id: int) -> Response:
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


class TrainerPaymentHistoryView(APIView):
    """
    Get trainer's received payments.
    GET /api/payments/trainer/payments/
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
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

    def get(self, request: Request) -> Response:
        trainer = cast(User, request.user)
        subscriptions = TraineeSubscription.objects.filter(
            trainer=trainer,
            status=TraineeSubscription.Status.ACTIVE
        ).select_related('trainee').order_by('-created_at')

        serializer = TraineeSubscriptionSerializer(subscriptions, many=True)
        return Response(serializer.data)
