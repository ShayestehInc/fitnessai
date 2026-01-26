from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserProfileViewSet

app_name = 'users'

router = DefaultRouter()
router.register(r'profiles', UserProfileViewSet, basename='profile')

urlpatterns = [
    path('', include(router.urls)),
]
