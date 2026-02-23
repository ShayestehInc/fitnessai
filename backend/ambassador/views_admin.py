"""
Ambassador admin views — scoped admin capabilities for ambassadors.

All endpoints are restricted to ambassadors (or platform admins) and filter
data to only include trainers the ambassador referred/created.
"""
from __future__ import annotations

import logging
from decimal import Decimal
from typing import cast

from django.db import transaction
from django.db.models import Count, Q, Sum
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from ambassador.models import AmbassadorProfile, AmbassadorReferral
from ambassador.services.scoping_service import (
    AmbassadorScope,
    get_scope,
    get_scoped_trainers,
)
from core.permissions import IsAmbassadorOrAdmin
from subscriptions.models import Coupon, Subscription, SubscriptionTier
from subscriptions.serializers import (
    CouponCreateSerializer,
    CouponListSerializer,
    CouponSerializer,
    CouponUpdateSerializer,
    SubscriptionListSerializer,
    SubscriptionTierSerializer,
)
from users.models import User

logger = logging.getLogger(__name__)


def _get_ambassador_scope(request: Request) -> AmbassadorScope:
    """
    Build the ambassador scope for the current user.

    Raises:
        AmbassadorProfile.DoesNotExist: If the user has no ambassador profile.
    """
    user = cast(User, request.user)
    return get_scope(user)


# ============ Dashboard ============


class AmbassadorAdminDashboardView(APIView):
    """
    Scoped admin dashboard for ambassadors.
    GET /api/ambassador/admin/dashboard/
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def get(self, request: Request) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        trainer_ids = scope.trainer_ids

        total_trainers = User.objects.filter(
            id__in=trainer_ids, role=User.Role.TRAINER,
        ).count()

        active_trainers = User.objects.filter(
            id__in=trainer_ids, role=User.Role.TRAINER, is_active=True,
        ).count()

        total_trainees = User.objects.filter(
            parent_trainer_id__in=trainer_ids, role=User.Role.TRAINEE,
        ).count()

        # Scoped tier breakdown
        tier_breakdown = dict(
            Subscription.objects.filter(trainer_id__in=trainer_ids)
            .values('tier')
            .annotate(count=Count('id'))
            .values_list('tier', 'count')
        )

        # Scoped MRR
        mrr = Decimal('0.00')
        active_subs = Subscription.objects.filter(
            trainer_id__in=trainer_ids, status='active',
        ).select_related('trainer')
        for sub in active_subs:
            mrr += sub.get_monthly_price()

        return Response({
            'total_trainers': total_trainers,
            'active_trainers': active_trainers,
            'total_trainees': total_trainees,
            'tier_breakdown': tier_breakdown,
            'monthly_recurring_revenue': str(mrr),
            'referral_code': scope.ambassador_profile.referral_code,
            'commission_rate': str(scope.ambassador_profile.commission_rate),
        })


# ============ Trainers ============


class AmbassadorAdminTrainersView(APIView):
    """
    List trainers within the ambassador's scope.
    GET /api/ambassador/admin/trainers/
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def get(self, request: Request) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        trainers = get_scoped_trainers(scope).select_related('subscription')

        search = request.query_params.get('search', '').strip()
        if search:
            trainers = trainers.filter(
                Q(email__icontains=search)
                | Q(first_name__icontains=search)
                | Q(last_name__icontains=search)
            )

        result = []
        for trainer in trainers.order_by('-created_at'):
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
                } if subscription else None,
            })

        return Response(result)


class AmbassadorAdminCreateTrainerView(APIView):
    """
    Create a new trainer under the ambassador's umbrella.
    POST /api/ambassador/admin/trainers/create/

    Creates the trainer user, a FREE subscription, and an ACTIVE AmbassadorReferral.
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def post(self, request: Request) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        email = request.data.get('email', '').strip().lower()
        password = request.data.get('password', '')
        first_name = request.data.get('first_name', '').strip()
        last_name = request.data.get('last_name', '').strip()

        if not email:
            return Response(
                {'error': 'Email is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not password or len(password) < 8:
            return Response(
                {'error': 'Password must be at least 8 characters.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if User.objects.filter(email=email).exists():
            return Response(
                {'error': 'A user with this email already exists.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = cast(User, request.user)
        profile = scope.ambassador_profile

        try:
            with transaction.atomic():
                trainer = User.objects.create_user(
                    email=email,
                    password=password,
                    role=User.Role.TRAINER,
                    first_name=first_name,
                    last_name=last_name,
                )

                Subscription.objects.create(
                    trainer=trainer,
                    tier='FREE',
                    status='active',
                )

                AmbassadorReferral.objects.create(
                    ambassador=user,
                    trainer=trainer,
                    ambassador_profile=profile,
                    referral_code_used=profile.referral_code,
                    status=AmbassadorReferral.Status.ACTIVE,
                )

                profile.refresh_cached_stats()
        except Exception:
            logger.exception("Failed to create trainer for ambassador %s", user.email)
            return Response(
                {'error': 'Failed to create trainer.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        logger.info(
            "Ambassador %s created trainer %s",
            user.email, trainer.email,
        )

        return Response({
            'success': True,
            'trainer': {
                'id': trainer.id,
                'email': trainer.email,
                'first_name': trainer.first_name,
                'last_name': trainer.last_name,
                'created_at': trainer.created_at.isoformat(),
            },
        }, status=status.HTTP_201_CREATED)


class AmbassadorAdminTrainerDetailView(APIView):
    """
    View or edit a trainer within the ambassador's scope.
    GET/PATCH /api/ambassador/admin/trainers/<id>/
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def get(self, request: Request, trainer_id: int) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not scope.trainer_belongs_to_ambassador(trainer_id):
            return Response(
                {'error': 'You do not have access to this trainer.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            trainer = User.objects.select_related('subscription').get(
                id=trainer_id, role=User.Role.TRAINER,
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainer not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        subscription = getattr(trainer, 'subscription', None)
        return Response({
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
            } if subscription else None,
        })

    def patch(self, request: Request, trainer_id: int) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not scope.trainer_belongs_to_ambassador(trainer_id):
            return Response(
                {'error': 'You do not have access to this trainer.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            trainer = User.objects.get(id=trainer_id, role=User.Role.TRAINER)
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainer not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if 'first_name' in request.data:
            trainer.first_name = request.data['first_name'].strip()
        if 'last_name' in request.data:
            trainer.last_name = request.data['last_name'].strip()
        if 'is_active' in request.data:
            trainer.is_active = request.data['is_active']

        trainer.save()

        user = cast(User, request.user)
        logger.info(
            "Ambassador %s updated trainer %s",
            user.email, trainer.email,
        )

        return Response({
            'id': trainer.id,
            'email': trainer.email,
            'first_name': trainer.first_name,
            'last_name': trainer.last_name,
            'is_active': trainer.is_active,
            'created_at': trainer.created_at.isoformat(),
        })


# ============ Subscriptions ============


class AmbassadorAdminSubscriptionsView(APIView):
    """
    View subscriptions for trainers within the ambassador's scope.
    GET /api/ambassador/admin/subscriptions/
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def get(self, request: Request) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        queryset = Subscription.objects.filter(
            trainer_id__in=scope.trainer_ids,
        ).select_related('trainer').order_by('-created_at')

        status_filter = request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        tier_filter = request.query_params.get('tier')
        if tier_filter:
            queryset = queryset.filter(tier=tier_filter)

        search = request.query_params.get('search', '').strip()
        if search:
            queryset = queryset.filter(trainer__email__icontains=search)

        serializer = SubscriptionListSerializer(queryset, many=True)
        return Response(serializer.data)


# ============ Tiers (read-only) ============


class AmbassadorAdminTiersView(APIView):
    """
    List all active subscription tiers (read-only).
    GET /api/ambassador/admin/tiers/
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def get(self, request: Request) -> Response:
        tiers = SubscriptionTier.objects.filter(
            is_active=True,
        ).order_by('sort_order', 'price')
        serializer = SubscriptionTierSerializer(tiers, many=True)
        return Response(serializer.data)


# ============ Coupons ============


class AmbassadorAdminCouponsView(APIView):
    """
    Coupon management for ambassadors.

    GET: List all coupons (can see all, but can only edit/delete own).
    POST: Create a new coupon owned by this ambassador.
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def get(self, request: Request) -> Response:
        queryset = Coupon.objects.all().order_by('-created_at')

        status_filter = request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        search = request.query_params.get('search', '').strip()
        if search:
            queryset = queryset.filter(code__icontains=search)

        serializer = CouponListSerializer(queryset, many=True)
        return Response(serializer.data)

    def post(self, request: Request) -> Response:
        serializer = CouponCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = cast(User, request.user)
        coupon = serializer.save(created_by_ambassador=user)
        return Response(
            CouponSerializer(coupon).data,
            status=status.HTTP_201_CREATED,
        )


class AmbassadorAdminCouponDetailView(APIView):
    """
    View, update, or delete a specific coupon.
    GET/PATCH/DELETE /api/ambassador/admin/coupons/<id>/

    Ambassadors can only edit/delete coupons they created.
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def _get_coupon(self, coupon_id: int) -> Coupon | None:
        try:
            return Coupon.objects.get(id=coupon_id)
        except Coupon.DoesNotExist:
            return None

    def _is_owner(self, coupon: Coupon, user: User) -> bool:
        return coupon.created_by_ambassador_id == user.id

    def get(self, request: Request, coupon_id: int) -> Response:
        coupon = self._get_coupon(coupon_id)
        if not coupon:
            return Response(
                {'error': 'Coupon not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(CouponSerializer(coupon).data)

    def patch(self, request: Request, coupon_id: int) -> Response:
        coupon = self._get_coupon(coupon_id)
        if not coupon:
            return Response(
                {'error': 'Coupon not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        user = cast(User, request.user)
        if not self._is_owner(coupon, user):
            return Response(
                {'error': 'You can only edit coupons you created.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = CouponUpdateSerializer(coupon, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        serializer.save()
        return Response(CouponSerializer(coupon).data)

    def delete(self, request: Request, coupon_id: int) -> Response:
        coupon = self._get_coupon(coupon_id)
        if not coupon:
            return Response(
                {'error': 'Coupon not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        user = cast(User, request.user)
        if not self._is_owner(coupon, user):
            return Response(
                {'error': 'You can only delete coupons you created.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        coupon.delete()
        return Response({'success': True, 'message': 'Coupon deleted.'})


# ============ Impersonation ============


class AmbassadorAdminImpersonateView(APIView):
    """
    Impersonate a trainer within the ambassador's scope.
    POST /api/ambassador/admin/impersonate/<trainer_id>/
    """
    permission_classes = [IsAuthenticated, IsAmbassadorOrAdmin]

    def post(self, request: Request, trainer_id: int) -> Response:
        try:
            scope = _get_ambassador_scope(request)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not scope.trainer_belongs_to_ambassador(trainer_id):
            return Response(
                {'error': 'You do not have access to this trainer.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            trainer = User.objects.get(id=trainer_id, role=User.Role.TRAINER)
        except User.DoesNotExist:
            return Response(
                {'error': 'Trainer not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        user = cast(User, request.user)
        refresh = RefreshToken.for_user(trainer)
        refresh['impersonating'] = True
        refresh['original_user_id'] = user.id
        refresh['is_ambassador_impersonation'] = True

        logger.info(
            "Ambassador %s started impersonating trainer %s",
            user.email, trainer.email,
        )

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
            'message': f'Now logged in as {trainer.email}',
        })
