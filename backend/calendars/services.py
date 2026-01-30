"""
Calendar integration services for Google and Microsoft.
"""
import requests
from datetime import datetime, timedelta
from urllib.parse import urlencode
from django.conf import settings
from django.utils import timezone
from .models import CalendarConnection, CalendarEvent


# =============================================================================
# Google Calendar Service
# =============================================================================

class GoogleCalendarService:
    """Service for Google Calendar OAuth and API operations."""

    AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth'
    TOKEN_URL = 'https://oauth2.googleapis.com/token'
    CALENDAR_API_URL = 'https://www.googleapis.com/calendar/v3'
    USERINFO_URL = 'https://www.googleapis.com/oauth2/v2/userinfo'

    SCOPES = [
        'https://www.googleapis.com/auth/calendar.readonly',
        'https://www.googleapis.com/auth/calendar.events',
        'https://www.googleapis.com/auth/userinfo.email',
    ]

    def __init__(self):
        self.client_id = getattr(settings, 'GOOGLE_CALENDAR_CLIENT_ID', '')
        self.client_secret = getattr(settings, 'GOOGLE_CALENDAR_CLIENT_SECRET', '')
        self.redirect_uri = getattr(settings, 'GOOGLE_CALENDAR_REDIRECT_URI', '')

    def get_authorization_url(self, state: str) -> str:
        """Generate OAuth authorization URL."""
        params = {
            'client_id': self.client_id,
            'redirect_uri': self.redirect_uri,
            'response_type': 'code',
            'scope': ' '.join(self.SCOPES),
            'access_type': 'offline',
            'prompt': 'consent',
            'state': state,
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    def exchange_code(self, code: str) -> dict:
        """Exchange authorization code for tokens."""
        data = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'code': code,
            'grant_type': 'authorization_code',
            'redirect_uri': self.redirect_uri,
        }

        response = requests.post(self.TOKEN_URL, data=data)
        response.raise_for_status()
        return response.json()

    def refresh_access_token(self, refresh_token: str) -> dict:
        """Refresh an expired access token."""
        data = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'refresh_token': refresh_token,
            'grant_type': 'refresh_token',
        }

        response = requests.post(self.TOKEN_URL, data=data)
        response.raise_for_status()
        return response.json()

    def get_user_info(self, access_token: str) -> dict:
        """Get user info (email) from Google."""
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get(self.USERINFO_URL, headers=headers)
        response.raise_for_status()
        return response.json()

    def get_calendar_list(self, access_token: str) -> list:
        """Get list of user's calendars."""
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get(
            f"{self.CALENDAR_API_URL}/users/me/calendarList",
            headers=headers
        )
        response.raise_for_status()
        return response.json().get('items', [])

    def get_events(
        self,
        access_token: str,
        calendar_id: str = 'primary',
        time_min: datetime = None,
        time_max: datetime = None,
        max_results: int = 100
    ) -> list:
        """Fetch events from a calendar."""
        headers = {'Authorization': f'Bearer {access_token}'}

        if not time_min:
            time_min = timezone.now()
        if not time_max:
            time_max = time_min + timedelta(days=30)

        params = {
            'timeMin': time_min.isoformat(),
            'timeMax': time_max.isoformat(),
            'maxResults': max_results,
            'singleEvents': 'true',
            'orderBy': 'startTime',
        }

        response = requests.get(
            f"{self.CALENDAR_API_URL}/calendars/{calendar_id}/events",
            headers=headers,
            params=params
        )
        response.raise_for_status()
        return response.json().get('items', [])

    def create_event(
        self,
        access_token: str,
        summary: str,
        start_time: datetime,
        end_time: datetime,
        description: str = '',
        location: str = '',
        attendees: list = None,
        calendar_id: str = 'primary'
    ) -> dict:
        """Create an event on the calendar."""
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
        }

        event_data = {
            'summary': summary,
            'description': description,
            'location': location,
            'start': {
                'dateTime': start_time.isoformat(),
                'timeZone': 'UTC',
            },
            'end': {
                'dateTime': end_time.isoformat(),
                'timeZone': 'UTC',
            },
        }

        if attendees:
            event_data['attendees'] = [{'email': email} for email in attendees]

        response = requests.post(
            f"{self.CALENDAR_API_URL}/calendars/{calendar_id}/events",
            headers=headers,
            json=event_data
        )
        response.raise_for_status()
        return response.json()

    def revoke_token(self, token: str) -> bool:
        """Revoke an access or refresh token."""
        try:
            response = requests.post(
                'https://oauth2.googleapis.com/revoke',
                params={'token': token}
            )
            return response.status_code == 200
        except Exception:
            return False


# =============================================================================
# Microsoft Calendar Service
# =============================================================================

class MicrosoftCalendarService:
    """Service for Microsoft Graph Calendar OAuth and API operations."""

    AUTH_URL = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
    TOKEN_URL = 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
    GRAPH_API_URL = 'https://graph.microsoft.com/v1.0'

    SCOPES = [
        'offline_access',
        'User.Read',
        'Calendars.ReadWrite',
    ]

    def __init__(self):
        self.client_id = getattr(settings, 'MICROSOFT_CALENDAR_CLIENT_ID', '')
        self.client_secret = getattr(settings, 'MICROSOFT_CALENDAR_CLIENT_SECRET', '')
        self.redirect_uri = getattr(settings, 'MICROSOFT_CALENDAR_REDIRECT_URI', '')

    def get_authorization_url(self, state: str) -> str:
        """Generate OAuth authorization URL."""
        params = {
            'client_id': self.client_id,
            'redirect_uri': self.redirect_uri,
            'response_type': 'code',
            'scope': ' '.join(self.SCOPES),
            'response_mode': 'query',
            'state': state,
        }
        return f"{self.AUTH_URL}?{urlencode(params)}"

    def exchange_code(self, code: str) -> dict:
        """Exchange authorization code for tokens."""
        data = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'code': code,
            'grant_type': 'authorization_code',
            'redirect_uri': self.redirect_uri,
            'scope': ' '.join(self.SCOPES),
        }

        response = requests.post(self.TOKEN_URL, data=data)
        response.raise_for_status()
        return response.json()

    def refresh_access_token(self, refresh_token: str) -> dict:
        """Refresh an expired access token."""
        data = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'refresh_token': refresh_token,
            'grant_type': 'refresh_token',
            'scope': ' '.join(self.SCOPES),
        }

        response = requests.post(self.TOKEN_URL, data=data)
        response.raise_for_status()
        return response.json()

    def get_user_info(self, access_token: str) -> dict:
        """Get user info from Microsoft Graph."""
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get(f"{self.GRAPH_API_URL}/me", headers=headers)
        response.raise_for_status()
        return response.json()

    def get_calendars(self, access_token: str) -> list:
        """Get list of user's calendars."""
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get(
            f"{self.GRAPH_API_URL}/me/calendars",
            headers=headers
        )
        response.raise_for_status()
        return response.json().get('value', [])

    def get_events(
        self,
        access_token: str,
        calendar_id: str = None,
        time_min: datetime = None,
        time_max: datetime = None,
        max_results: int = 100
    ) -> list:
        """Fetch events from a calendar."""
        headers = {'Authorization': f'Bearer {access_token}'}

        if not time_min:
            time_min = timezone.now()
        if not time_max:
            time_max = time_min + timedelta(days=30)

        # Use default calendar if not specified
        endpoint = f"{self.GRAPH_API_URL}/me/calendar/events"
        if calendar_id:
            endpoint = f"{self.GRAPH_API_URL}/me/calendars/{calendar_id}/events"

        params = {
            '$filter': f"start/dateTime ge '{time_min.isoformat()}' and end/dateTime le '{time_max.isoformat()}'",
            '$top': max_results,
            '$orderby': 'start/dateTime',
        }

        response = requests.get(endpoint, headers=headers, params=params)
        response.raise_for_status()
        return response.json().get('value', [])

    def create_event(
        self,
        access_token: str,
        subject: str,
        start_time: datetime,
        end_time: datetime,
        body: str = '',
        location: str = '',
        attendees: list = None,
        calendar_id: str = None
    ) -> dict:
        """Create an event on the calendar."""
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
        }

        event_data = {
            'subject': subject,
            'body': {
                'contentType': 'text',
                'content': body,
            },
            'start': {
                'dateTime': start_time.strftime('%Y-%m-%dT%H:%M:%S'),
                'timeZone': 'UTC',
            },
            'end': {
                'dateTime': end_time.strftime('%Y-%m-%dT%H:%M:%S'),
                'timeZone': 'UTC',
            },
        }

        if location:
            event_data['location'] = {'displayName': location}

        if attendees:
            event_data['attendees'] = [
                {
                    'emailAddress': {'address': email},
                    'type': 'required'
                }
                for email in attendees
            ]

        endpoint = f"{self.GRAPH_API_URL}/me/calendar/events"
        if calendar_id:
            endpoint = f"{self.GRAPH_API_URL}/me/calendars/{calendar_id}/events"

        response = requests.post(endpoint, headers=headers, json=event_data)
        response.raise_for_status()
        return response.json()


# =============================================================================
# Calendar Sync Service
# =============================================================================

class CalendarSyncService:
    """Service for syncing calendar events to local database."""

    def __init__(self, connection: CalendarConnection):
        self.connection = connection
        if connection.provider == CalendarConnection.Provider.GOOGLE:
            self.service = GoogleCalendarService()
        else:
            self.service = MicrosoftCalendarService()

    def ensure_valid_token(self) -> str:
        """Ensure we have a valid access token, refreshing if needed."""
        if not self.connection.is_token_expired:
            return self.connection.access_token

        try:
            token_data = self.service.refresh_access_token(self.connection.refresh_token)
            self.connection.update_tokens(
                access_token=token_data['access_token'],
                refresh_token=token_data.get('refresh_token'),
                expires_in=token_data.get('expires_in', 3600)
            )
            return self.connection.access_token
        except Exception as e:
            self.connection.mark_expired()
            raise Exception(f"Failed to refresh token: {str(e)}")

    def sync_events(self, days_ahead: int = 30) -> int:
        """Sync events from external calendar to local database."""
        try:
            access_token = self.ensure_valid_token()

            time_min = timezone.now()
            time_max = time_min + timedelta(days=days_ahead)

            if self.connection.provider == CalendarConnection.Provider.GOOGLE:
                events = self.service.get_events(
                    access_token,
                    self.connection.calendar_id or 'primary',
                    time_min,
                    time_max
                )
                synced_count = self._sync_google_events(events)
            else:
                events = self.service.get_events(
                    access_token,
                    self.connection.calendar_id,
                    time_min,
                    time_max
                )
                synced_count = self._sync_microsoft_events(events)

            self.connection.last_synced_at = timezone.now()
            self.connection.sync_error = ''
            self.connection.save()

            return synced_count

        except Exception as e:
            self.connection.mark_error(str(e))
            raise

    def _sync_google_events(self, events: list) -> int:
        """Sync Google Calendar events."""
        synced = 0
        for event in events:
            external_id = event.get('id')
            if not external_id:
                continue

            start = event.get('start', {})
            end = event.get('end', {})

            # Handle all-day events
            if 'date' in start:
                start_time = datetime.fromisoformat(start['date'])
                end_time = datetime.fromisoformat(end['date'])
                all_day = True
            else:
                start_time = datetime.fromisoformat(
                    start['dateTime'].replace('Z', '+00:00')
                )
                end_time = datetime.fromisoformat(
                    end['dateTime'].replace('Z', '+00:00')
                )
                all_day = False

            CalendarEvent.objects.update_or_create(
                connection=self.connection,
                external_id=external_id,
                defaults={
                    'title': event.get('summary', 'No Title'),
                    'description': event.get('description', ''),
                    'location': event.get('location', ''),
                    'start_time': start_time,
                    'end_time': end_time,
                    'all_day': all_day,
                    'external_link': event.get('htmlLink', ''),
                    'is_recurring': bool(event.get('recurringEventId')),
                }
            )
            synced += 1

        return synced

    def _sync_microsoft_events(self, events: list) -> int:
        """Sync Microsoft Calendar events."""
        synced = 0
        for event in events:
            external_id = event.get('id')
            if not external_id:
                continue

            start = event.get('start', {})
            end = event.get('end', {})

            start_time = datetime.fromisoformat(
                start['dateTime'].replace('Z', '+00:00')
            )
            end_time = datetime.fromisoformat(
                end['dateTime'].replace('Z', '+00:00')
            )

            location = event.get('location', {})
            location_str = location.get('displayName', '') if location else ''

            CalendarEvent.objects.update_or_create(
                connection=self.connection,
                external_id=external_id,
                defaults={
                    'title': event.get('subject', 'No Title'),
                    'description': event.get('bodyPreview', ''),
                    'location': location_str,
                    'start_time': start_time,
                    'end_time': end_time,
                    'all_day': event.get('isAllDay', False),
                    'external_link': event.get('webLink', ''),
                    'is_recurring': event.get('type') == 'occurrence',
                }
            )
            synced += 1

        return synced
