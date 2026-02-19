"""
WebSocket URL routing for the messaging app.
"""
from django.urls import path

from .consumers import DirectMessageConsumer

websocket_urlpatterns = [
    path(
        'ws/messaging/<int:conversation_id>/',
        DirectMessageConsumer.as_asgi(),
    ),
]
