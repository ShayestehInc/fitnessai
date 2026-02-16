"""
URL configuration for community app (trainee-facing).
"""
from django.urls import path

from .views import (
    TraineeAnnouncementListView,
    AnnouncementUnreadCountView,
    AnnouncementMarkReadView,
    AchievementListView,
    AchievementRecentView,
    CommunityFeedView,
    CommunityPostDeleteView,
    ReactionToggleView,
    CommentListCreateView,
    CommentDeleteView,
    LeaderboardView,
)

urlpatterns = [
    # Announcements (trainee-facing)
    path('announcements/', TraineeAnnouncementListView.as_view(), name='community-announcements'),
    path('announcements/unread-count/', AnnouncementUnreadCountView.as_view(), name='community-announcements-unread'),
    path('announcements/mark-read/', AnnouncementMarkReadView.as_view(), name='community-announcements-mark-read'),

    # Achievements
    path('achievements/', AchievementListView.as_view(), name='community-achievements'),
    path('achievements/recent/', AchievementRecentView.as_view(), name='community-achievements-recent'),

    # Community Feed
    path('feed/', CommunityFeedView.as_view(), name='community-feed'),
    path('feed/<int:pk>/', CommunityPostDeleteView.as_view(), name='community-post-delete'),
    path('feed/<int:post_id>/react/', ReactionToggleView.as_view(), name='community-post-react'),

    # Comments
    path('feed/<int:post_id>/comments/', CommentListCreateView.as_view(), name='community-post-comments'),
    path(
        'feed/<int:post_id>/comments/<int:comment_id>/',
        CommentDeleteView.as_view(),
        name='community-comment-delete',
    ),

    # Leaderboard
    path('leaderboard/', LeaderboardView.as_view(), name='community-leaderboard'),
]
