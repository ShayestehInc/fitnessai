"""
Ambassador views for dashboard, referrals, and admin management.
"""
from __future__ import annotations

import logging
from datetime import timedelta
from decimal import Decimal
from typing import Any, cast

from django.db import IntegrityError, transaction
from django.db.models import Case, Count, Q, QuerySet, Sum, When
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

from .models import (
    AmbassadorCommission,
    AmbassadorProfile,
    AmbassadorReferral,
    AmbassadorStripeAccount,
    PayoutRecord,
)
from .serializers import (
    AdminCreateAmbassadorSerializer,
    AdminUpdateAmbassadorSerializer,
    AmbassadorCommissionSerializer,
    AmbassadorListSerializer,
    AmbassadorProfileSerializer,
    AmbassadorReferralSerializer,
    BulkCommissionActionSerializer,
    CustomReferralCodeSerializer,
)
from .services.commission_service import CommissionService
from .services.payout_service import PayoutService

logger = logging.getLogger(__name__)


def _annotate_referrals_with_commission(
    queryset: QuerySet[AmbassadorReferral],
) -> QuerySet[AmbassadorReferral]:
    """Annotate referral queryset with total earned commission.

    Centralises the annotation so it is not duplicated across multiple views.
    """
    return queryset.annotate(
        _total_commission=Sum(
            Case(
                When(
                    commissions__status__in=[
                        AmbassadorCommission.Status.APPROVED,
                        AmbassadorCommission.Status.PAID,
                    ],
                    then='commissions__commission_amount',
                ),
                default=Decimal('0.00'),
            )
        )
    )


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

        # Single query for all status counts + total
        status_counts = AmbassadorReferral.objects.filter(ambassador=user).aggregate(
            total_count=Count('id'),
            active_count=Count(Case(When(status=AmbassadorReferral.Status.ACTIVE, then=1))),
            pending_count=Count(Case(When(status=AmbassadorReferral.Status.PENDING, then=1))),
            churned_count=Count(Case(When(status=AmbassadorReferral.Status.CHURNED, then=1))),
        )
        total_count = status_counts['total_count']
        active_count = status_counts['active_count']
        pending_count = status_counts['pending_count']
        churned_count = status_counts['churned_count']

        # Pending earnings (commissions not yet paid)
        pending_earnings = AmbassadorCommission.objects.filter(
            ambassador=user,
            status=AmbassadorCommission.Status.PENDING,
        ).aggregate(total=Sum('commission_amount'))['total'] or Decimal('0.00')

        # Monthly earnings for last 6 months
        six_months_ago = timezone.now() - timedelta(days=180)
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

        # Recent referrals (last 5) with annotated commission totals to avoid N+1
        recent_referrals = (
            _annotate_referrals_with_commission(
                AmbassadorReferral.objects.filter(ambassador=user)
                .select_related('trainer', 'trainer__subscription')
            )
            .order_by('-referred_at')[:5]
        )
        recent_serialized = AmbassadorReferralSerializer(recent_referrals, many=True).data

        return Response({
            'total_referrals': total_count,
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
        referrals = _annotate_referrals_with_commission(
            AmbassadorReferral.objects.filter(ambassador=user)
            .select_related('trainer', 'trainer__subscription')
        )

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

    PUT /api/ambassador/referral-code/
    Updates the ambassador's referral code to a custom value.
    """
    permission_classes = [IsAuthenticated, IsAmbassador]

    def _get_profile(self, user: User) -> AmbassadorProfile | None:
        try:
            return AmbassadorProfile.objects.get(user=user)
        except AmbassadorProfile.DoesNotExist:
            return None

    def _build_share_message(self, referral_code: str) -> str:
        return (
            f"Join FitnessAI and grow your training business! "
            f"Use my referral code {referral_code} when you sign up."
        )

    def get(self, request: Request) -> Response:
        user = cast(User, request.user)
        profile = self._get_profile(user)

        if profile is None:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({
            'referral_code': profile.referral_code,
            'share_message': self._build_share_message(profile.referral_code),
        })

    def put(self, request: Request) -> Response:
        user = cast(User, request.user)
        profile = self._get_profile(user)

        if profile is None:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = CustomReferralCodeSerializer(
            data=request.data,
            context={'profile_id': profile.id},
        )
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated = cast(dict[str, Any], serializer.validated_data)
        new_code = validated['referral_code']

        profile.referral_code = new_code
        try:
            # The DB unique constraint is the real guard against concurrent
            # claims; the serializer check is just a user-friendly fast path.
            profile.save(update_fields=['referral_code'])
        except IntegrityError:
            return Response(
                {'referral_code': ['This referral code is already in use.']},
                status=status.HTTP_400_BAD_REQUEST,
            )

        logger.info(
            "Ambassador %s updated referral code to %s",
            user.email, new_code,
        )

        return Response({
            'referral_code': profile.referral_code,
            'share_message': self._build_share_message(profile.referral_code),
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

        with transaction.atomic():
            # Create user with AMBASSADOR role and temporary password
            user = User(
                email=validated['email'],
                first_name=validated['first_name'],
                last_name=validated['last_name'],
                role=User.Role.AMBASSADOR,
            )
            user.set_password(validated['password'])
            user.save()

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

        referrals = (
            _annotate_referrals_with_commission(
                AmbassadorReferral.objects.filter(ambassador=profile.user)
                .select_related('trainer', 'trainer__subscription')
            )
            .order_by('-referred_at')
        )

        commissions = AmbassadorCommission.objects.filter(
            ambassador=profile.user,
        ).select_related('referral__trainer').order_by('-created_at')

        # Paginate referrals
        referral_paginator = PageNumberPagination()
        referral_paginator.page_size = 50
        referral_paginator.page_query_param = 'referral_page'
        referral_page = referral_paginator.paginate_queryset(referrals, request)
        referral_data = AmbassadorReferralSerializer(
            referral_page if referral_page is not None else referrals, many=True,
        ).data
        # Reuse the count the paginator already computed to avoid a duplicate COUNT query.
        referrals_total = (
            referral_paginator.page.paginator.count
            if referral_paginator.page is not None
            else referrals.count()
        )

        # Paginate commissions
        commission_paginator = PageNumberPagination()
        commission_paginator.page_size = 50
        commission_paginator.page_query_param = 'commission_page'
        commission_page = commission_paginator.paginate_queryset(commissions, request)
        commission_data = AmbassadorCommissionSerializer(
            commission_page if commission_page is not None else commissions, many=True,
        ).data
        commissions_total = (
            commission_paginator.page.paginator.count
            if commission_paginator.page is not None
            else commissions.count()
        )

        return Response({
            'profile': AmbassadorProfileSerializer(profile).data,
            'referrals': referral_data,
            'referrals_count': referrals_total,
            'commissions': commission_data,
            'commissions_count': commissions_total,
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

        update_fields: list[str] = []
        if 'commission_rate' in validated:
            profile.commission_rate = validated['commission_rate']
            update_fields.append('commission_rate')
        if 'is_active' in validated:
            profile.is_active = validated['is_active']
            update_fields.append('is_active')

        if update_fields:
            # auto_now=True on updated_at ensures the timestamp is included
            # automatically by Django whenever update_fields is specified.
            profile.save(update_fields=update_fields)

        logger.info(
            "Admin updated ambassador %s: rate=%s, active=%s",
            profile.user.email, profile.commission_rate, profile.is_active,
        )

        return Response(AmbassadorProfileSerializer(profile).data)


class AdminCommissionApproveView(APIView):
    """
    POST /api/admin/ambassadors/<ambassador_id>/commissions/<commission_id>/approve/
    Approve a single PENDING commission.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request: Request, ambassador_id: int, commission_id: int) -> Response:
        result = CommissionService.approve_commission(
            commission_id=commission_id,
            ambassador_profile_id=ambassador_id,
        )

        if not result.success:
            return Response(
                {'error': result.message},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({'message': result.message})


class AdminCommissionPayView(APIView):
    """
    POST /api/admin/ambassadors/<ambassador_id>/commissions/<commission_id>/pay/
    Mark a single APPROVED commission as PAID.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request: Request, ambassador_id: int, commission_id: int) -> Response:
        result = CommissionService.pay_commission(
            commission_id=commission_id,
            ambassador_profile_id=ambassador_id,
        )

        if not result.success:
            return Response(
                {'error': result.message},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({'message': result.message})


class AdminBulkApproveCommissionsView(APIView):
    """
    POST /api/admin/ambassadors/<ambassador_id>/commissions/bulk-approve/
    Bulk approve all PENDING commissions in the provided list.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request: Request, ambassador_id: int) -> Response:
        serializer = BulkCommissionActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated = cast(dict[str, Any], serializer.validated_data)
        result = CommissionService.bulk_approve(
            commission_ids=validated['commission_ids'],
            ambassador_profile_id=ambassador_id,
        )

        return Response({
            'message': result.message,
            'approved_count': result.processed_count,
            'skipped_count': result.skipped_count,
        })


class AdminBulkPayCommissionsView(APIView):
    """
    POST /api/admin/ambassadors/<ambassador_id>/commissions/bulk-pay/
    Bulk mark all APPROVED commissions as PAID in the provided list.
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request: Request, ambassador_id: int) -> Response:
        serializer = BulkCommissionActionSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated = cast(dict[str, Any], serializer.validated_data)
        result = CommissionService.bulk_pay(
            commission_ids=validated['commission_ids'],
            ambassador_profile_id=ambassador_id,
        )

        return Response({
            'message': result.message,
            'paid_count': result.processed_count,
            'skipped_count': result.skipped_count,
        })


# ---------------------------------------------------------------------------
# Stripe Connect (Ambassador-facing)
# ---------------------------------------------------------------------------


class AmbassadorConnectStatusView(APIView):
    """
    GET /api/ambassador/connect/status/
    Returns the ambassador's Stripe Connect account status.
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

        result = PayoutService.get_connect_status(profile.id)

        return Response({
            'has_account': result.has_account,
            'stripe_account_id': result.stripe_account_id,
            'charges_enabled': result.charges_enabled,
            'payouts_enabled': result.payouts_enabled,
            'details_submitted': result.details_submitted,
            'onboarding_completed': result.onboarding_completed,
        })


class AmbassadorConnectOnboardView(APIView):
    """
    POST /api/ambassador/connect/onboard/
    Creates a Stripe Express account (if needed) and returns an onboarding link.
    Body: { "return_url": "...", "refresh_url": "..." }
    """
    permission_classes = [IsAuthenticated, IsAmbassador]

    def post(self, request: Request) -> Response:
        user = cast(User, request.user)

        try:
            profile = AmbassadorProfile.objects.get(user=user)
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        from django.conf import settings as django_settings

        return_url = request.data.get(
            'return_url',
            f'{django_settings.FRONTEND_URL}/ambassador/stripe-connect/return',
        )
        refresh_url = request.data.get(
            'refresh_url',
            f'{django_settings.FRONTEND_URL}/ambassador/stripe-connect/refresh',
        )

        try:
            result = PayoutService.create_connect_account(
                ambassador_profile_id=profile.id,
                return_url=return_url,
                refresh_url=refresh_url,
            )
        except RuntimeError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response({
            'onboarding_url': result.onboarding_url,
            'message': result.message,
        })


class AmbassadorConnectReturnView(APIView):
    """
    GET /api/ambassador/connect/return/
    Called after ambassador returns from Stripe onboarding.
    Syncs account status from Stripe.
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

        try:
            result = PayoutService.sync_account_status(profile.id)
        except (AmbassadorStripeAccount.DoesNotExist, RuntimeError) as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'has_account': result.has_account,
            'charges_enabled': result.charges_enabled,
            'payouts_enabled': result.payouts_enabled,
            'details_submitted': result.details_submitted,
            'onboarding_completed': result.onboarding_completed,
        })


class AmbassadorPayoutHistoryView(APIView):
    """
    GET /api/ambassador/payouts/
    Paginated list of payout records for the ambassador.
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

        payouts = (
            PayoutRecord.objects.filter(ambassador_profile=profile)
            .order_by('-created_at')
        )

        paginator = PageNumberPagination()
        paginator.page_size = 20
        page = paginator.paginate_queryset(payouts, request)

        data = []
        for payout in (page if page is not None else payouts):
            data.append({
                'id': payout.id,
                'amount': str(payout.amount),
                'status': payout.status,
                'stripe_transfer_id': payout.stripe_transfer_id,
                'error_message': payout.error_message,
                'commission_count': payout.commissions_included.count(),
                'created_at': payout.created_at,
            })

        if paginator.page is not None:
            return paginator.get_paginated_response(data)
        return Response(data)


# ---------------------------------------------------------------------------
# Admin Payout Trigger
# ---------------------------------------------------------------------------

class AdminTriggerPayoutView(APIView):
    """
    POST /api/admin/ambassadors/<ambassador_id>/payout/
    Trigger a payout of approved commissions to the ambassador.
    Body (optional): { "commission_ids": [1, 2, 3] }
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request: Request, ambassador_id: int) -> Response:
        commission_ids = request.data.get('commission_ids')

        try:
            result = PayoutService.execute_payout(
                ambassador_profile_id=ambassador_id,
                commission_ids=commission_ids,
            )
        except AmbassadorProfile.DoesNotExist:
            return Response(
                {'error': 'Ambassador profile not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except RuntimeError as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        if not result.success:
            return Response(
                {'error': result.message},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            'message': result.message,
            'payout_record_id': result.payout_record_id,
            'amount': str(result.amount),
        })
