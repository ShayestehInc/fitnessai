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
    AssignProgramTemplateView, AdherenceAnalyticsView, ProgressAnalyticsView,
    GenerateMCPTokenView, AIChatView, AIChatTraineeContextView, AIProvidersView
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

    # Invitations
    path('invitations/', InvitationListCreateView.as_view(), name='invitation-list-create'),
    path('invitations/<int:pk>/', InvitationDetailView.as_view(), name='invitation-detail'),
    path('invitations/<int:pk>/resend/', ResendInvitationView.as_view(), name='invitation-resend'),

    # Login as trainee (Impersonation)
    path('impersonate/<int:trainee_id>/start/', StartImpersonationView.as_view(), name='impersonate-start'),
    path('impersonate/end/', EndImpersonationView.as_view(), name='impersonate-end'),

    # Program templates
    path('program-templates/', ProgramTemplateListCreateView.as_view(), name='program-template-list-create'),
    path('program-templates/<int:pk>/', ProgramTemplateDetailView.as_view(), name='program-template-detail'),
    path('program-templates/<int:pk>/assign/', AssignProgramTemplateView.as_view(), name='program-template-assign'),

    # Analytics
    path('analytics/adherence/', AdherenceAnalyticsView.as_view(), name='analytics-adherence'),
    path('analytics/progress/', ProgressAnalyticsView.as_view(), name='analytics-progress'),

    # MCP Server Integration
    path('mcp/token/', GenerateMCPTokenView.as_view(), name='mcp-token'),

    # AI Chat
    path('ai/chat/', AIChatView.as_view(), name='ai-chat'),
    path('ai/context/<int:trainee_id>/', AIChatTraineeContextView.as_view(), name='ai-context'),
    path('ai/providers/', AIProvidersView.as_view(), name='ai-providers'),
]
