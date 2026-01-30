"""
URL configuration for calendar integration.
"""
from django.urls import path
from .views import (
    CalendarConnectionListView,
    GoogleAuthURLView, GoogleCallbackView,
    MicrosoftAuthURLView, MicrosoftCallbackView,
    DisconnectCalendarView, SyncCalendarView,
    CalendarEventsView, CreateCalendarEventView,
    TrainerAvailabilityListCreateView, TrainerAvailabilityDetailView
)

urlpatterns = [
    # Calendar connections
    path('connections/', CalendarConnectionListView.as_view(), name='calendar-connections'),

    # Google OAuth
    path('google/auth/', GoogleAuthURLView.as_view(), name='google-auth'),
    path('google/callback/', GoogleCallbackView.as_view(), name='google-callback'),

    # Microsoft OAuth
    path('microsoft/auth/', MicrosoftAuthURLView.as_view(), name='microsoft-auth'),
    path('microsoft/callback/', MicrosoftCallbackView.as_view(), name='microsoft-callback'),

    # Calendar management
    path('<str:provider>/disconnect/', DisconnectCalendarView.as_view(), name='calendar-disconnect'),
    path('<str:provider>/sync/', SyncCalendarView.as_view(), name='calendar-sync'),

    # Events
    path('events/', CalendarEventsView.as_view(), name='calendar-events'),
    path('events/create/', CreateCalendarEventView.as_view(), name='calendar-event-create'),

    # Availability
    path('availability/', TrainerAvailabilityListCreateView.as_view(), name='availability-list'),
    path('availability/<int:pk>/', TrainerAvailabilityDetailView.as_view(), name='availability-detail'),
]
