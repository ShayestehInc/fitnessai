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

# Payment URLs (Stripe Connect)
payment_urlpatterns = [
    # Stripe Connect (Trainer onboarding)
    path('connect/onboard/', views.StripeConnectOnboardView.as_view(), name='stripe-connect-onboard'),
    path('connect/status/', views.StripeConnectStatusView.as_view(), name='stripe-connect-status'),
    path('connect/dashboard/', views.StripeConnectDashboardView.as_view(), name='stripe-connect-dashboard'),

    # Trainer pricing
    path('pricing/', views.TrainerPricingView.as_view(), name='trainer-pricing'),
    path('trainers/<int:trainer_id>/pricing/', views.TrainerPublicPricingView.as_view(), name='trainer-public-pricing'),

    # Trainee checkout
    path('checkout/subscription/', views.CreateSubscriptionCheckoutView.as_view(), name='checkout-subscription'),
    path('checkout/one-time/', views.CreateOneTimeCheckoutView.as_view(), name='checkout-one-time'),

    # Trainee subscription management
    path('my-subscription/', views.TraineeSubscriptionView.as_view(), name='trainee-subscription'),
    path('my-subscription/<int:subscription_id>/', views.TraineeSubscriptionView.as_view(), name='trainee-subscription-detail'),
    path('my-payments/', views.TraineePaymentHistoryView.as_view(), name='trainee-payments'),

    # Trainer payment views
    path('trainer/payments/', views.TrainerPaymentHistoryView.as_view(), name='trainer-payments'),
    path('trainer/subscribers/', views.TrainerSubscribersView.as_view(), name='trainer-subscribers'),

    # Webhooks
    path('webhook/', views.StripeWebhookView.as_view(), name='stripe-webhook'),
]
