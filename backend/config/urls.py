"""
URL configuration for Fitness AI project.
"""
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('djoser.urls')),
    path('api/auth/', include('djoser.urls.jwt')),
    path('api/users/', include('users.urls')),
    path('api/workouts/', include('workouts.urls')),
    path('api/subscriptions/', include('subscriptions.urls')),
    path('api/trainer/', include('trainer.urls')),
    path('api/features/', include('features.urls')),
]
