"""
URL configuration for Fitness AI project.
"""
from django.contrib import admin
from django.urls import path, include
from subscriptions.urls import payment_urlpatterns

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('djoser.urls')),
    path('api/auth/', include('djoser.urls.jwt')),
    path('api/users/', include('users.urls')),
    path('api/workouts/', include('workouts.urls')),
    path('api/trainer/', include('trainer.urls')),
    path('api/features/', include('features.urls')),

    # Admin API endpoints
    path('api/admin/', include('subscriptions.urls')),

    # Payment API endpoints (Stripe Connect)
    path('api/payments/', include(payment_urlpatterns)),

    # Calendar integration
    path('api/calendar/', include('calendars.urls')),
]
