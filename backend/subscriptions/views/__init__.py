"""
Subscriptions views package.
Re-exports all views for backward compatibility.
"""

# Admin views
from .admin_views import (
    IsAdminUser,
    AdminUsersListView,
    AdminUserDetailView,
    AdminCreateUserView,
    AdminDashboardView,
    AdminSubscriptionViewSet,
    AdminTrainersView,
    AdminImpersonateTrainerView,
    AdminEndImpersonationView,
    AdminPastDueView,
    AdminUpcomingPaymentsView,
    AdminSubscriptionTierViewSet,
    PublicSubscriptionTiersView,
    AdminCouponViewSet,
)

# Trainer views
from .trainer_views import (
    IsTrainer,
    TrainerCouponViewSet,
    ValidateCouponView,
    TrainerPricingView,
    TrainerPublicPricingView,
    TrainerPaymentHistoryView,
    TrainerSubscribersView,
)

# Payment views
from .payment_views import (
    StripeConnectOnboardView,
    StripeConnectStatusView,
    StripeConnectDashboardView,
    CreateSubscriptionCheckoutView,
    CreateOneTimeCheckoutView,
    StripeWebhookView,
)

# Trainee views
from .trainee_views import (
    IsTrainee,
    TraineeSubscriptionView,
    TraineePaymentHistoryView,
)

__all__ = [
    # Admin views
    'IsAdminUser',
    'AdminUsersListView',
    'AdminUserDetailView',
    'AdminCreateUserView',
    'AdminDashboardView',
    'AdminSubscriptionViewSet',
    'AdminTrainersView',
    'AdminImpersonateTrainerView',
    'AdminEndImpersonationView',
    'AdminPastDueView',
    'AdminUpcomingPaymentsView',
    'AdminSubscriptionTierViewSet',
    'PublicSubscriptionTiersView',
    'AdminCouponViewSet',
    # Trainer views
    'IsTrainer',
    'TrainerCouponViewSet',
    'ValidateCouponView',
    'TrainerPricingView',
    'TrainerPublicPricingView',
    'TrainerPaymentHistoryView',
    'TrainerSubscribersView',
    # Payment views
    'StripeConnectOnboardView',
    'StripeConnectStatusView',
    'StripeConnectDashboardView',
    'CreateSubscriptionCheckoutView',
    'CreateOneTimeCheckoutView',
    'StripeWebhookView',
    # Trainee views
    'IsTrainee',
    'TraineeSubscriptionView',
    'TraineePaymentHistoryView',
]
