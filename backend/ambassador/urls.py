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
]

# Admin-facing endpoints (mounted at /api/admin/ambassadors/)
admin_urlpatterns = [
    path('', views.AdminAmbassadorListView.as_view(), name='admin-ambassador-list'),
    path('create/', views.AdminCreateAmbassadorView.as_view(), name='admin-ambassador-create'),
    path('<int:ambassador_id>/', views.AdminAmbassadorDetailView.as_view(), name='admin-ambassador-detail'),
]
