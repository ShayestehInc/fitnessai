"""
Ambassador views for dashboard, referrals, and admin management.
"""
from __future__ import annotations

import logging
from decimal import Decimal
from typing import Any, cast

from django.db.models import Q, Sum
from django.db.models.functions import TruncMonth
from django.utils import timezone
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import IsAdmin, IsAmbassador
from users.models import User

from .models import AmbassadorCommission, AmbassadorProfile, AmbassadorReferral
from .serializers import (
    AdminCreateAmbassadorSerializer,
    AdminUpdateAmbassadorSerializer,
    AmbassadorCommissionSerializer,
    AmbassadorListSerializer,
    AmbassadorProfileSerializer,
    AmbassadorReferralSerializer,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Ambassador-facing endpoints
# ---------------------------------------------------------------------------


class AmbassadorDashboardView(APIView):
    """
    GET /api/ambassador/dashboard/
    Returns dashboard stats for the authenticated ambassador.
    """
    permission_classes = [IsAuthenticated, IsAmbassador]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)

        try:
            profile = AmbassadorProfile.objects.get(user=user)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        referrals = AmbassadorReferral.objects.filter(ambassador=user)
        active_count = referrals.filter(status=AmbassadorReferral.Status.ACTIVE).count()
        pending_count = referrals.filter(status=AmbassadorReferral.Status.PENDING).count()
        churned_count = referrals.filter(status=AmbassadorReferral.Status.CHURNED).count()

        # Pending earnings (commissions not yet paid)
        pending_earnings = AmbassadorCommission.objects.filter(
            ambassador=user,
            status=AmbassadorCommission.Status.PENDING,
        ).aggregate(total=Sum('commission_amount'))['total'] or Decimal('0.00')

        # Monthly earnings for last 6 months
        six_months_ago = timezone.now() - timezone.timedelta(days=180)
        monthly_data = (
            AmbassadorCommission.objects.filter(
                ambassador=user,
                status__in=[AmbassadorCommission.Status.APPROVED, AmbassadorCommission.Status.PAID],
                created_at__gte=six_months_ago,
            )
            .annotate(month=TruncMonth('created_at'))
            .values('month')
            .annotate(earnings=Sum('commission_amount'))
            .order_by('month')
        )
        monthly_earnings = [
            {
                'month': entry['month'].strftime('%Y-%m'),
                'earnings': str(entry['earnings']),
            }
            for entry in monthly_data
        ]

        # Recent referrals (last 5)
        recent_referrals = referrals.select_related('trainer')[:5]
        recent_serialized = AmbassadorReferralSerializer(recent_referrals, many=True).data

        return Response({
            'total_referrals': profile.total_referrals,
            'active_referrals': active_count,
            'pending_referrals': pending_count,
            'churned_referrals': churned_count,
            'total_earnings': str(profile.total_earnings),
            'pending_earnings': str(pending_earnings),
            'monthly_earnings': monthly_earnings,
            'recent_referrals': recent_serialized,
            'referral_code': profile.referral_code,
            'commission_rate': str(profile.commission_rate),
            'is_active': profile.is_active,
        })


class AmbassadorReferralsView(APIView):
    """
    GET /api/ambassador/referrals/
    Paginated list of ambassador's referred trainers.
    """
    permission_classes = [IsAuthenticated, IsAmbassador]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        referrals = AmbassadorReferral.objects.filter(
            ambassador=user,
        ).select_related('trainer')

        # Filter by status
        status_filter = request.query_params.get('status', '').upper()
        if status_filter in ['PENDING', 'ACTIVE', 'CHURNED']:
            referrals = referrals.filter(status=status_filter)

        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(referrals, request)

        if page is not None:
            serializer = AmbassadorReferralSerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)

        serializer = AmbassadorReferralSerializer(referrals, many=True)
        return Response(serializer.data)


class AmbassadorReferralCodeView(APIView):
    """
    GET /api/ambassador/referral-code/
    Returns the ambassador's referral code and a shareable message.
    """
    permission_classes = [IsAuthenticated, IsAmbassador]

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)

        try:
            profile = AmbassadorProfile.objects.get(user=user)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        share_message = (
            f"Join FitnessAI and grow your training business! "
            f"Use my referral code {profile.referral_code} when you sign up."
        )

        return Response({
            'referral_code': profile.referral_code,
            'share_message': share_message,
        })


# ---------------------------------------------------------------------------
# Admin-facing endpoints
# ---------------------------------------------------------------------------


class AdminAmbassadorListView(APIView):
    """
    GET /api/admin/ambassadors/
    List all ambassadors with stats.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request: Request) -> Response:
        queryset = AmbassadorProfile.objects.select_related('user').all()

        # Search
        search = request.query_params.get('search', '').strip()
        if search:
            queryset = queryset.filter(
                Q(user__email__icontains=search) |
                Q(user__first_name__icontains=search) |
                Q(user__last_name__icontains=search)
            )

        # Filter by active status
        active_filter = request.query_params.get('is_active', '').lower()
        if active_filter == 'true':
            queryset = queryset.filter(is_active=True)
        elif active_filter == 'false':
            queryset = queryset.filter(is_active=False)

        queryset = queryset.order_by('-created_at')

        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(queryset, request)

        if page is not None:
            serializer = AmbassadorListSerializer(page, many=True)
            return paginator.get_paginated_response(serializer.data)

        serializer = AmbassadorListSerializer(queryset, many=True)
        return Response(serializer.data)


class AdminCreateAmbassadorView(APIView):
    """
    POST /api/admin/ambassadors/
    Create a new ambassador account.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request: Request) -> Response:
        serializer = AdminCreateAmbassadorSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated = cast(dict[str, Any], serializer.validated_data)

        # Create user with AMBASSADOR role
        user = User.objects.create_user(
            email=validated['email'],
            password=None,  # Admin sets password via separate flow or email reset
            first_name=validated['first_name'],
            last_name=validated['last_name'],
        )
        user.role = User.Role.AMBASSADOR
        user.save(update_fields=['role'])

        # Create ambassador profile with referral code
        profile = AmbassadorProfile.objects.create(
            user=user,
            commission_rate=validated.get('commission_rate', Decimal('0.20')),
        )

        logger.info("Admin created ambassador: %s (code: %s)", user.email, profile.referral_code)

        return Response(
            AmbassadorProfileSerializer(profile).data,
            status=status.HTTP_201_CREATED,
        )


class AdminAmbassadorDetailView(APIView):
    """
    GET /api/admin/ambassadors/<id>/
    PUT /api/admin/ambassadors/<id>/
    Ambassador detail with referral list and commission history.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def _get_profile(self, ambassador_id: int) -> AmbassadorProfile | None:
        try:
            return AmbassadorProfile.objects.select_related('user').get(id=ambassador_id)
        except AmbassadorProfile.DoesNotExist:
            return None

    def get(self, request: Request, ambassador_id: int) -> Response:
        profile = self._get_profile(ambassador_id)
        if not profile:
            return Response(
                {'error': 'Ambassador not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        referrals = AmbassadorReferral.objects.filter(
            ambassador=profile.user,
        ).select_related('trainer').order_by('-referred_at')

        commissions = AmbassadorCommission.objects.filter(
            ambassador=profile.user,
        ).select_related('referral__trainer').order_by('-created_at')[:50]

        return Response({
            'profile': AmbassadorProfileSerializer(profile).data,
            'referrals': AmbassadorReferralSerializer(referrals, many=True).data,
            'commissions': AmbassadorCommissionSerializer(commissions, many=True).data,
        })

    def put(self, request: Request, ambassador_id: int) -> Response:
        profile = self._get_profile(ambassador_id)
        if not profile:
            return Response(
                {'error': 'Ambassador not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = AdminUpdateAmbassadorSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated = cast(dict[str, Any], serializer.validated_data)

        if 'commission_rate' in validated:
            profile.commission_rate = validated['commission_rate']
        if 'is_active' in validated:
            profile.is_active = validated['is_active']

        profile.save()

        logger.info(
            "Admin updated ambassador %s: rate=%s, active=%s",
            profile.user.email, profile.commission_rate, profile.is_active,
        )

        return Response(AmbassadorProfileSerializer(profile).data)
