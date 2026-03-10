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
    RetentionAnalyticsView, AtRiskTraineesView,
    GenerateMCPTokenView, AIChatView, AIChatTraineeContextView, AIProvidersView,
    MarkMissedDayView,
    TraineeLayoutConfigView,
    TrainerBrandingView, TrainerBrandingLogoView,
)
from .ai_chat_views import (
    AIChatThreadListCreateView,
    AIChatThreadDetailView,
    AIChatThreadSendView,
)
from .digest_views import (
    DigestGenerateView,
    DigestHistoryView,
    DigestDetailView,
    DigestPreferenceView,
    DraftMessageView,
)
from .notification_views import (
    NotificationListView, UnreadCountView,
    MarkNotificationReadView, MarkAllReadView, DeleteNotificationView,
)
from .export_views import (
    PaymentExportView, SubscriberExportView, TraineeExportView,
)
from .correlation_views import (
    CohortAnalysisView,
    CorrelationOverviewView,
    TraineePatternsView,
)
from .audit_views import (
    AuditSummaryView,
    AuditTimelineView,
    DecisionLogExportView,
    TraineeNutritionExportView,
    TraineeProgressExportView,
    TraineeWorkoutExportView,
)
from community.trainer_views import (
    TrainerAnnouncementListCreateView,
    TrainerAnnouncementDetailView,
    TrainerLeaderboardSettingsView,
    # Phase 2 — Classroom
    TrainerCourseListCreateView,
    TrainerCourseDetailView,
    TrainerLessonListCreateView,
    TrainerLessonDetailView,
    # Phase 3 — Events
    TrainerEventListCreateView,
    TrainerEventDetailView,
    TrainerEventStatusView,
    # Phase 4 — Moderation
    TrainerReportListView,
    TrainerReportReviewView,
    TrainerBanListCreateView,
    TrainerUnbanView,
    TrainerAutoModRuleListCreateView,
    TrainerAutoModRuleDetailView,
    # Phase 5 — Community Config
    TrainerCommunityConfigView,
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
    path('analytics/retention/', RetentionAnalyticsView.as_view(), name='analytics-retention'),
    path('analytics/at-risk/', AtRiskTraineesView.as_view(), name='analytics-at-risk'),

    # Correlation analytics (v6.5 Step 15)
    path('analytics/correlations/', CorrelationOverviewView.as_view(), name='analytics-correlations'),
    path('analytics/trainee/<int:trainee_id>/patterns/', TraineePatternsView.as_view(), name='analytics-trainee-patterns'),
    path('analytics/cohort/', CohortAnalysisView.as_view(), name='analytics-cohort'),

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

    # AI Chat (legacy stateless endpoint)
    path('ai/chat/', AIChatView.as_view(), name='ai-chat'),
    path('ai/context/<int:trainee_id>/', AIChatTraineeContextView.as_view(), name='ai-context'),
    path('ai/providers/', AIProvidersView.as_view(), name='ai-providers'),

    # AI Chat Threads (persistent)
    path('ai/threads/', AIChatThreadListCreateView.as_view(), name='ai-thread-list-create'),
    path('ai/threads/<int:thread_id>/', AIChatThreadDetailView.as_view(), name='ai-thread-detail'),
    path('ai/threads/<int:thread_id>/send/', AIChatThreadSendView.as_view(), name='ai-thread-send'),

    # Daily Digest
    path('ai/daily-digest/generate/', DigestGenerateView.as_view(), name='digest-generate'),
    path('ai/daily-digest/history/', DigestHistoryView.as_view(), name='digest-history'),
    path('ai/daily-digest/preferences/', DigestPreferenceView.as_view(), name='digest-preferences'),
    path('ai/daily-digest/<str:digest_id>/', DigestDetailView.as_view(), name='digest-detail'),

    # Message Drafting
    path('ai/draft-message/', DraftMessageView.as_view(), name='draft-message'),

    # Announcements (trainer CRUD)
    path('announcements/', TrainerAnnouncementListCreateView.as_view(), name='trainer-announcements'),
    path('announcements/<int:pk>/', TrainerAnnouncementDetailView.as_view(), name='trainer-announcement-detail'),

    # Leaderboard settings
    path('leaderboard-settings/', TrainerLeaderboardSettingsView.as_view(), name='trainer-leaderboard-settings'),

    # Courses (trainer CRUD)
    path('courses/', TrainerCourseListCreateView.as_view(), name='trainer-courses'),
    path('courses/<int:pk>/', TrainerCourseDetailView.as_view(), name='trainer-course-detail'),
    path('courses/<int:course_id>/lessons/', TrainerLessonListCreateView.as_view(), name='trainer-course-lessons'),
    path('courses/<int:course_id>/lessons/<int:pk>/', TrainerLessonDetailView.as_view(), name='trainer-lesson-detail'),

    # Events (trainer CRUD)
    path('events/', TrainerEventListCreateView.as_view(), name='trainer-events'),
    path('events/<int:pk>/', TrainerEventDetailView.as_view(), name='trainer-event-detail'),
    path('events/<int:pk>/status/', TrainerEventStatusView.as_view(), name='trainer-event-status'),

    # Moderation
    path('moderation/reports/', TrainerReportListView.as_view(), name='trainer-reports'),
    path('moderation/reports/<int:pk>/review/', TrainerReportReviewView.as_view(), name='trainer-report-review'),
    path('moderation/bans/', TrainerBanListCreateView.as_view(), name='trainer-bans'),
    path('moderation/bans/<int:user_id>/', TrainerUnbanView.as_view(), name='trainer-unban'),
    path('moderation/rules/', TrainerAutoModRuleListCreateView.as_view(), name='trainer-automod-rules'),
    path('moderation/rules/<int:pk>/', TrainerAutoModRuleDetailView.as_view(), name='trainer-automod-rule-detail'),

    # Community Config (Admin Builder)
    path('community-config/', TrainerCommunityConfigView.as_view(), name='trainer-community-config'),

    # Audit trail (v6.5 Step 16)
    path('audit/summary/', AuditSummaryView.as_view(), name='audit-summary'),
    path('audit/timeline/', AuditTimelineView.as_view(), name='audit-timeline'),

    # Comprehensive exports (v6.5 Step 16)
    path('export/decision-logs/', DecisionLogExportView.as_view(), name='export-decision-logs'),
    path('export/trainee/<int:trainee_id>/workout-history/', TraineeWorkoutExportView.as_view(), name='export-trainee-workout'),
    path('export/trainee/<int:trainee_id>/nutrition-history/', TraineeNutritionExportView.as_view(), name='export-trainee-nutrition'),
    path('export/trainee/<int:trainee_id>/progress/', TraineeProgressExportView.as_view(), name='export-trainee-progress'),
]
