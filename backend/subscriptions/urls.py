from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'subscriptions'

router = DefaultRouter()
router.register(r'subscriptions', views.AdminSubscriptionViewSet, basename='admin-subscriptions')

urlpatterns = [
    # Admin dashboard
    path('dashboard/', views.AdminDashboardView.as_view(), name='admin-dashboard'),

    # Admin views
    path('trainers/', views.AdminTrainersView.as_view(), name='admin-trainers'),
    path('past-due/', views.AdminPastDueView.as_view(), name='admin-past-due'),
    path('upcoming-payments/', views.AdminUpcomingPaymentsView.as_view(), name='admin-upcoming-payments'),

    # Subscription CRUD with router
    path('', include(router.urls)),
]
