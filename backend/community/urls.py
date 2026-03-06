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
    SpaceListCreateView,
    SpaceDetailView,
    SpaceJoinView,
    SpaceLeaveView,
    SpaceMembersView,
    BookmarkToggleView,
    BookmarkListView,
    BookmarkCollectionListCreateView,
    # Phase 2 — Classroom
    TraineeCourseListView,
    TraineeCourseDetailView,
    TraineeCourseEnrollView,
    TraineeMyEnrollmentsView,
    TraineeLessonProgressView,
    # Phase 3 — Events
    TraineeEventListView,
    TraineeEventDetailView,
    TraineeEventRSVPView,
    # Phase 4 — Reports
    TraineeReportContentView,
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

    # Spaces
    path('spaces/', SpaceListCreateView.as_view(), name='community-spaces'),
    path('spaces/<int:pk>/', SpaceDetailView.as_view(), name='community-space-detail'),
    path('spaces/<int:pk>/join/', SpaceJoinView.as_view(), name='community-space-join'),
    path('spaces/<int:pk>/leave/', SpaceLeaveView.as_view(), name='community-space-leave'),
    path('spaces/<int:pk>/members/', SpaceMembersView.as_view(), name='community-space-members'),

    # Bookmarks
    path('bookmarks/toggle/', BookmarkToggleView.as_view(), name='community-bookmark-toggle'),
    path('bookmarks/', BookmarkListView.as_view(), name='community-bookmarks'),
    path('bookmark-collections/', BookmarkCollectionListCreateView.as_view(), name='community-bookmark-collections'),

    # Courses (trainee-facing)
    path('courses/', TraineeCourseListView.as_view(), name='community-courses'),
    path('courses/<int:pk>/', TraineeCourseDetailView.as_view(), name='community-course-detail'),
    path('courses/<int:pk>/enroll/', TraineeCourseEnrollView.as_view(), name='community-course-enroll'),
    path('my-enrollments/', TraineeMyEnrollmentsView.as_view(), name='community-my-enrollments'),
    path(
        'courses/<int:course_id>/lessons/<int:lesson_id>/progress/',
        TraineeLessonProgressView.as_view(),
        name='community-lesson-progress',
    ),

    # Events (trainee-facing)
    path('events/', TraineeEventListView.as_view(), name='community-events'),
    path('events/<int:pk>/', TraineeEventDetailView.as_view(), name='community-event-detail'),
    path('events/<int:pk>/rsvp/', TraineeEventRSVPView.as_view(), name='community-event-rsvp'),

    # Content reporting (trainee-facing)
    path('report/', TraineeReportContentView.as_view(), name='community-report'),
]
