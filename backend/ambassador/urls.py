"""
URL configuration for ambassador app.
"""
from django.urls import path

from . import views

app_name = 'ambassador'

# Ambassador-facing endpoints (mounted at /api/ambassador/)
urlpatterns = [
    path('dashboard/', views.AmbassadorDashboardView.as_view(), name='ambassador-dashboard'),
    path('referrals/', views.AmbassadorReferralsView.as_view(), name='ambassador-referrals'),
    path('referral-code/', views.AmbassadorReferralCodeView.as_view(), name='ambassador-referral-code'),

    # Stripe Connect
    path('connect/status/', views.AmbassadorConnectStatusView.as_view(), name='ambassador-connect-status'),
    path('connect/onboard/', views.AmbassadorConnectOnboardView.as_view(), name='ambassador-connect-onboard'),
    path('connect/return/', views.AmbassadorConnectReturnView.as_view(), name='ambassador-connect-return'),

    # Payout history
    path('payouts/', views.AmbassadorPayoutHistoryView.as_view(), name='ambassador-payouts'),
]

# Admin-facing endpoints (mounted at /api/admin/ambassadors/)
admin_urlpatterns = [
    path('', views.AdminAmbassadorListView.as_view(), name='admin-ambassador-list'),
    path('create/', views.AdminCreateAmbassadorView.as_view(), name='admin-ambassador-create'),
    path('<int:ambassador_id>/', views.AdminAmbassadorDetailView.as_view(), name='admin-ambassador-detail'),
    path(
        '<int:ambassador_id>/commissions/<int:commission_id>/approve/',
        views.AdminCommissionApproveView.as_view(),
        name='admin-commission-approve',
    ),
    path(
        '<int:ambassador_id>/commissions/<int:commission_id>/pay/',
        views.AdminCommissionPayView.as_view(),
        name='admin-commission-pay',
    ),
    path(
        '<int:ambassador_id>/commissions/bulk-approve/',
        views.AdminBulkApproveCommissionsView.as_view(),
        name='admin-commission-bulk-approve',
    ),
    path(
        '<int:ambassador_id>/commissions/bulk-pay/',
        views.AdminBulkPayCommissionsView.as_view(),
        name='admin-commission-bulk-pay',
    ),
    path(
        '<int:ambassador_id>/payout/',
        views.AdminTriggerPayoutView.as_view(),
        name='admin-ambassador-payout',
    ),
]
