from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserProfileViewSet, GoogleLoginView, AppleLoginView, UploadProfileImageView, UpdateUserProfileView

app_name = 'users'

router = DefaultRouter()
router.register(r'profiles', UserProfileViewSet, basename='profile')

urlpatterns = [
    path('', include(router.urls)),
    path('auth/google/', GoogleLoginView.as_view(), name='google-login'),
    path('auth/apple/', AppleLoginView.as_view(), name='apple-login'),
    path('profile-image/', UploadProfileImageView.as_view(), name='profile-image'),
    path('me/', UpdateUserProfileView.as_view(), name='user-me'),
]
