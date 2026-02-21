"""
URL configuration for trainer app.
"""
from django.urls import path
from .views import (
    TrainerDashboardView, TrainerStatsView,
    TraineeListView, TraineeDetailView, TraineeActivityView,
    TraineeProgressView, RemoveTraineeView, UpdateTraineeGoalsView,
    InvitationListCreateView, InvitationDetailView, ResendInvitationView,
    StartImpersonationView, EndImpersonationView,
    ProgramTemplateListCreateView, ProgramTemplateDetailView,
    AssignProgramTemplateView, ProgramTemplateUploadImageView, ProgramUploadImageView,
    GenerateProgramView,
    AdherenceAnalyticsView, AdherenceTrendView, ProgressAnalyticsView, RevenueAnalyticsView,
    GenerateMCPTokenView, AIChatView, AIChatTraineeContextView, AIProvidersView,
    MarkMissedDayView,
    TraineeLayoutConfigView,
    TrainerBrandingView, TrainerBrandingLogoView,
)
from .notification_views import (
    NotificationListView, UnreadCountView,
    MarkNotificationReadView, MarkAllReadView, DeleteNotificationView,
)
from .export_views import (
    PaymentExportView, SubscriberExportView, TraineeExportView,
)
from community.trainer_views import (
    TrainerAnnouncementListCreateView,
    TrainerAnnouncementDetailView,
    TrainerLeaderboardSettingsView,
)

urlpatterns = [
    # Dashboard
    path('dashboard/', TrainerDashboardView.as_view(), name='trainer-dashboard'),
    path('dashboard/stats/', TrainerStatsView.as_view(), name='trainer-stats'),

    # Trainee management
    path('trainees/', TraineeListView.as_view(), name='trainee-list'),
    path('trainees/<int:pk>/', TraineeDetailView.as_view(), name='trainee-detail'),
    path('trainees/<int:pk>/activity/', TraineeActivityView.as_view(), name='trainee-activity'),
    path('trainees/<int:pk>/progress/', TraineeProgressView.as_view(), name='trainee-progress'),
    path('trainees/<int:pk>/remove/', RemoveTraineeView.as_view(), name='trainee-remove'),
    path('trainees/<int:pk>/goals/', UpdateTraineeGoalsView.as_view(), name='trainee-goals'),
    path('trainees/<int:trainee_id>/layout-config/', TraineeLayoutConfigView.as_view(), name='trainee-layout-config'),

    # Invitations
    path('invitations/', InvitationListCreateView.as_view(), name='invitation-list-create'),
    path('invitations/<int:pk>/', InvitationDetailView.as_view(), name='invitation-detail'),
    path('invitations/<int:pk>/resend/', ResendInvitationView.as_view(), name='invitation-resend'),

    # Login as trainee (Impersonation)
    path('impersonate/<int:trainee_id>/start/', StartImpersonationView.as_view(), name='impersonate-start'),
    path('impersonate/end/', EndImpersonationView.as_view(), name='impersonate-end'),

    # Program templates
    path('program-templates/', ProgramTemplateListCreateView.as_view(), name='program-template-list-create'),
    path('program-templates/generate/', GenerateProgramView.as_view(), name='program-template-generate'),
    path('program-templates/<int:pk>/', ProgramTemplateDetailView.as_view(), name='program-template-detail'),
    path('program-templates/<int:pk>/assign/', AssignProgramTemplateView.as_view(), name='program-template-assign'),
    path('program-templates/<int:pk>/upload-image/', ProgramTemplateUploadImageView.as_view(), name='program-template-upload-image'),

    # Program management
    path('programs/<int:pk>/upload-image/', ProgramUploadImageView.as_view(), name='program-upload-image'),
    path('programs/<int:program_id>/mark-missed/', MarkMissedDayView.as_view(), name='program-mark-missed'),

    # Analytics
    path('analytics/adherence/', AdherenceAnalyticsView.as_view(), name='analytics-adherence'),
    path('analytics/adherence/trends/', AdherenceTrendView.as_view(), name='analytics-adherence-trends'),
    path('analytics/progress/', ProgressAnalyticsView.as_view(), name='analytics-progress'),
    path('analytics/revenue/', RevenueAnalyticsView.as_view(), name='analytics-revenue'),

    # CSV Exports
    path('export/payments/', PaymentExportView.as_view(), name='export-payments'),
    path('export/subscribers/', SubscriberExportView.as_view(), name='export-subscribers'),
    path('export/trainees/', TraineeExportView.as_view(), name='export-trainees'),

    # MCP Server Integration
    path('mcp/token/', GenerateMCPTokenView.as_view(), name='mcp-token'),

    # Branding
    path('branding/', TrainerBrandingView.as_view(), name='trainer-branding'),
    path('branding/logo/', TrainerBrandingLogoView.as_view(), name='trainer-branding-logo'),

    # Notifications
    path('notifications/', NotificationListView.as_view(), name='notification-list'),
    path('notifications/unread-count/', UnreadCountView.as_view(), name='notification-unread-count'),
    path('notifications/mark-all-read/', MarkAllReadView.as_view(), name='notification-mark-all-read'),
    path('notifications/<int:pk>/read/', MarkNotificationReadView.as_view(), name='notification-mark-read'),
    path('notifications/<int:pk>/', DeleteNotificationView.as_view(), name='notification-delete'),

    # AI Chat
    path('ai/chat/', AIChatView.as_view(), name='ai-chat'),
    path('ai/context/<int:trainee_id>/', AIChatTraineeContextView.as_view(), name='ai-context'),
    path('ai/providers/', AIProvidersView.as_view(), name='ai-providers'),

    # Announcements (trainer CRUD)
    path('announcements/', TrainerAnnouncementListCreateView.as_view(), name='trainer-announcements'),
    path('announcements/<int:pk>/', TrainerAnnouncementDetailView.as_view(), name='trainer-announcement-detail'),

    # Leaderboard settings
    path('leaderboard-settings/', TrainerLeaderboardSettingsView.as_view(), name='trainer-leaderboard-settings'),
]
