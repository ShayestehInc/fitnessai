from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserProfileViewSet, GoogleLoginView, AppleLoginView,
    UploadProfileImageView, UpdateUserProfileView, MyBrandingView,
    DeviceTokenView, LeaderboardOptInView,
)

app_name = 'users'

router = DefaultRouter()
router.register(r'profiles', UserProfileViewSet, basename='profile')

urlpatterns = [
    path('', include(router.urls)),
    path('auth/google/', GoogleLoginView.as_view(), name='google-login'),
    path('auth/apple/', AppleLoginView.as_view(), name='apple-login'),
    path('profile-image/', UploadProfileImageView.as_view(), name='profile-image'),
    path('me/', UpdateUserProfileView.as_view(), name='user-me'),
    path('my-branding/', MyBrandingView.as_view(), name='my-branding'),
    path('device-token/', DeviceTokenView.as_view(), name='device-token'),
    path('leaderboard-opt-in/', LeaderboardOptInView.as_view(), name='leaderboard-opt-in'),
]
