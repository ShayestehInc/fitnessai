"""
Views for calendar integration.
"""
import secrets
from rest_framework import generics, status, views
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.conf import settings
from django.core.cache import cache

from core.permissions import IsTrainer
from .models import CalendarConnection, CalendarEvent, TrainerAvailability
from .serializers import (
    CalendarConnectionSerializer, CalendarEventSerializer,
    TrainerAvailabilitySerializer, OAuthCallbackSerializer,
    CreateEventSerializer
)
from .services import GoogleCalendarService, MicrosoftCalendarService, CalendarSyncService


class CalendarConnectionListView(generics.ListAPIView):
    """
    GET: List all calendar connections for the authenticated trainer.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = CalendarConnectionSerializer

    def get_queryset(self):
        return CalendarConnection.objects.filter(user=self.request.user)


class GoogleAuthURLView(views.APIView):
    """
    GET: Generate Google OAuth authorization URL.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        service = GoogleCalendarService()

        if not service.client_id:
            return Response(
                {'error': 'Google Calendar integration not configured'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        # Generate state token for CSRF protection
        state = secrets.token_urlsafe(32)
        cache_key = f"google_oauth_state_{request.user.id}"
        cache.set(cache_key, state, timeout=600)  # 10 minutes

        auth_url = service.get_authorization_url(state)

        return Response({
            'auth_url': auth_url,
            'provider': 'google'
        })


class GoogleCallbackView(views.APIView):
    """
    POST: Handle Google OAuth callback.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request):
        serializer = OAuthCallbackSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        code = serializer.validated_data['code']
        state = serializer.validated_data['state']

        # Verify state
        cache_key = f"google_oauth_state_{request.user.id}"
        stored_state = cache.get(cache_key)

        if not stored_state or stored_state != state:
            return Response(
                {'error': 'Invalid state parameter'},
                status=status.HTTP_400_BAD_REQUEST
            )

        cache.delete(cache_key)

        service = GoogleCalendarService()

        try:
            # Exchange code for tokens
            token_data = service.exchange_code(code)

            # Get user info
            user_info = service.get_user_info(token_data['access_token'])

            # Create or update connection
            connection, _ = CalendarConnection.objects.update_or_create(
                user=request.user,
                provider=CalendarConnection.Provider.GOOGLE,
                defaults={
                    'calendar_email': user_info.get('email', ''),
                    'calendar_name': 'Google Calendar',
                    'scopes': service.SCOPES,
                }
            )

            connection.update_tokens(
                access_token=token_data['access_token'],
                refresh_token=token_data.get('refresh_token'),
                expires_in=token_data.get('expires_in', 3600)
            )

            return Response({
                'message': 'Google Calendar connected successfully',
                'connection': CalendarConnectionSerializer(connection).data
            })

        except Exception as e:
            return Response(
                {'error': f'Failed to connect Google Calendar: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class MicrosoftAuthURLView(views.APIView):
    """
    GET: Generate Microsoft OAuth authorization URL.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def get(self, request):
        service = MicrosoftCalendarService()

        if not service.client_id:
            return Response(
                {'error': 'Microsoft Calendar integration not configured'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )

        # Generate state token for CSRF protection
        state = secrets.token_urlsafe(32)
        cache_key = f"microsoft_oauth_state_{request.user.id}"
        cache.set(cache_key, state, timeout=600)  # 10 minutes

        auth_url = service.get_authorization_url(state)

        return Response({
            'auth_url': auth_url,
            'provider': 'microsoft'
        })


class MicrosoftCallbackView(views.APIView):
    """
    POST: Handle Microsoft OAuth callback.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request):
        serializer = OAuthCallbackSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        code = serializer.validated_data['code']
        state = serializer.validated_data['state']

        # Verify state
        cache_key = f"microsoft_oauth_state_{request.user.id}"
        stored_state = cache.get(cache_key)

        if not stored_state or stored_state != state:
            return Response(
                {'error': 'Invalid state parameter'},
                status=status.HTTP_400_BAD_REQUEST
            )

        cache.delete(cache_key)

        service = MicrosoftCalendarService()

        try:
            # Exchange code for tokens
            token_data = service.exchange_code(code)

            # Get user info
            user_info = service.get_user_info(token_data['access_token'])

            # Create or update connection
            connection, _ = CalendarConnection.objects.update_or_create(
                user=request.user,
                provider=CalendarConnection.Provider.MICROSOFT,
                defaults={
                    'calendar_email': user_info.get('mail') or user_info.get('userPrincipalName', ''),
                    'calendar_name': 'Microsoft Outlook',
                    'scopes': service.SCOPES,
                }
            )

            connection.update_tokens(
                access_token=token_data['access_token'],
                refresh_token=token_data.get('refresh_token'),
                expires_in=token_data.get('expires_in', 3600)
            )

            return Response({
                'message': 'Microsoft Calendar connected successfully',
                'connection': CalendarConnectionSerializer(connection).data
            })

        except Exception as e:
            return Response(
                {'error': f'Failed to connect Microsoft Calendar: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class DisconnectCalendarView(views.APIView):
    """
    POST: Disconnect a calendar connection.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request, provider):
        try:
            connection = CalendarConnection.objects.get(
                user=request.user,
                provider=provider
            )
        except CalendarConnection.DoesNotExist:
            return Response(
                {'error': 'Calendar connection not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Revoke token if possible
        if provider == CalendarConnection.Provider.GOOGLE:
            service = GoogleCalendarService()
            service.revoke_token(connection.access_token)

        # Delete connection
        connection.delete()

        return Response({
            'message': f'{connection.get_provider_display()} disconnected successfully'
        })


class SyncCalendarView(views.APIView):
    """
    POST: Manually trigger calendar sync.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request, provider):
        try:
            connection = CalendarConnection.objects.get(
                user=request.user,
                provider=provider,
                status=CalendarConnection.Status.CONNECTED
            )
        except CalendarConnection.DoesNotExist:
            return Response(
                {'error': 'No active calendar connection found'},
                status=status.HTTP_404_NOT_FOUND
            )

        try:
            sync_service = CalendarSyncService(connection)
            synced_count = sync_service.sync_events()

            return Response({
                'message': f'Synced {synced_count} events',
                'synced_count': synced_count,
                'last_synced_at': connection.last_synced_at
            })

        except Exception as e:
            return Response(
                {'error': f'Sync failed: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class CalendarEventsView(generics.ListAPIView):
    """
    GET: List synced calendar events.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = CalendarEventSerializer

    def get_queryset(self):
        connections = CalendarConnection.objects.filter(
            user=self.request.user,
            status=CalendarConnection.Status.CONNECTED
        )

        queryset = CalendarEvent.objects.filter(connection__in=connections)

        # Filter by provider if specified
        provider = self.request.query_params.get('provider')
        if provider:
            queryset = queryset.filter(connection__provider=provider)

        return queryset.order_by('start_time')


class CreateCalendarEventView(views.APIView):
    """
    POST: Create a new event on a connected calendar.
    """
    permission_classes = [IsAuthenticated, IsTrainer]

    def post(self, request):
        serializer = CreateEventSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data = serializer.validated_data
        provider = data.get('provider')

        # Find a connected calendar
        connections = CalendarConnection.objects.filter(
            user=request.user,
            status=CalendarConnection.Status.CONNECTED
        )

        if provider:
            connections = connections.filter(provider=provider)

        connection = connections.first()

        if not connection:
            return Response(
                {'error': 'No connected calendar found'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            sync_service = CalendarSyncService(connection)
            access_token = sync_service.ensure_valid_token()

            if connection.provider == CalendarConnection.Provider.GOOGLE:
                service = GoogleCalendarService()
                result = service.create_event(
                    access_token=access_token,
                    summary=data['title'],
                    start_time=data['start_time'],
                    end_time=data['end_time'],
                    description=data.get('description', ''),
                    location=data.get('location', ''),
                    attendees=data.get('attendee_emails', [])
                )
            else:
                service = MicrosoftCalendarService()
                result = service.create_event(
                    access_token=access_token,
                    subject=data['title'],
                    start_time=data['start_time'],
                    end_time=data['end_time'],
                    body=data.get('description', ''),
                    location=data.get('location', ''),
                    attendees=data.get('attendee_emails', [])
                )

            return Response({
                'message': 'Event created successfully',
                'event_id': result.get('id'),
                'event_link': result.get('htmlLink') or result.get('webLink')
            })

        except Exception as e:
            return Response(
                {'error': f'Failed to create event: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class TrainerAvailabilityListCreateView(generics.ListCreateAPIView):
    """
    GET: List trainer's availability slots.
    POST: Create a new availability slot.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TrainerAvailabilitySerializer

    def get_queryset(self):
        return TrainerAvailability.objects.filter(trainer=self.request.user)

    def perform_create(self, serializer):
        serializer.save(trainer=self.request.user)


class TrainerAvailabilityDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET/PUT/PATCH/DELETE: Manage a specific availability slot.
    """
    permission_classes = [IsAuthenticated, IsTrainer]
    serializer_class = TrainerAvailabilitySerializer

    def get_queryset(self):
        return TrainerAvailability.objects.filter(trainer=self.request.user)
