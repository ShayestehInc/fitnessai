"""
URL configuration for features app.
"""
from django.urls import path
from .views import (
    FeatureRequestListCreateView, FeatureRequestDetailView,
    FeatureVoteView, FeatureCommentListCreateView, AdminUpdateStatusView
)

urlpatterns = [
    # Feature requests
    path('', FeatureRequestListCreateView.as_view(), name='feature-list-create'),
    path('<int:pk>/', FeatureRequestDetailView.as_view(), name='feature-detail'),
    path('<int:pk>/vote/', FeatureVoteView.as_view(), name='feature-vote'),
    path('<int:pk>/comments/', FeatureCommentListCreateView.as_view(), name='feature-comments'),

    # Admin only
    path('<int:pk>/status/', AdminUpdateStatusView.as_view(), name='feature-admin-status'),
]
