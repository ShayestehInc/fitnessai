"""
WebSocket URL routing for the community app.
"""
from django.urls import path

from .consumers import CommunityFeedConsumer

websocket_urlpatterns = [
    path('ws/community/feed/', CommunityFeedConsumer.as_asgi()),
]
