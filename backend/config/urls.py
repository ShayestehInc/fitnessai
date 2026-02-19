"""
URL configuration for Fitness AI project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from ambassador.urls import admin_urlpatterns as ambassador_admin_urlpatterns
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
    path('api/admin/ambassadors/', include((ambassador_admin_urlpatterns, 'ambassador-admin'))),

    # Payment API endpoints (Stripe Connect)
    path('api/payments/', include((payment_urlpatterns, 'payments'))),

    # Ambassador endpoints
    path('api/ambassador/', include('ambassador.urls')),

    # Calendar integration
    path('api/calendar/', include('calendars.urls')),

    # Community (trainee-facing: announcements, achievements, feed)
    path('api/community/', include('community.urls')),

    # Direct messaging (trainer-trainee)
    path('api/messaging/', include('messaging.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
