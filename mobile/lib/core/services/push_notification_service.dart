import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for the push notification service.
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Handles Firebase Cloud Messaging initialization and token registration.
class PushNotificationService {
  final Ref _ref;
  String? _currentToken;
  bool _initialized = false;

  PushNotificationService(this._ref);

  /// Initialize FCM and register device token.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase may already be initialized
    }

    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    // Get FCM token
    final token = await messaging.getToken();
    if (token != null) {
      _currentToken = token;
      await _registerToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Register the FCM token with the backend.
  Future<void> _registerToken(String token) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.dio.post(
        ApiConstants.deviceToken,
        data: {
          'token': token,
          'platform': _getPlatform(),
        },
      );
    } catch (_) {
      // Token registration is best-effort; will retry on next app launch
    }
  }

  /// Deactivate the current token on logout.
  Future<void> deactivateToken() async {
    if (_currentToken == null) return;
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.dio.delete(
        ApiConstants.deviceToken,
        data: {'token': _currentToken},
      );
    } catch (_) {
      // Best-effort deactivation
    }
    _currentToken = null;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Foreground messages can be displayed as in-app banners or snackbars.
    // The actual display logic depends on the app's navigation state.
    // For now, we just log the event type.
    final data = message.data;
    final eventType = data['event_type'] as String?;

    if (eventType == 'new_post' || eventType == 'new_comment') {
      // The WebSocket service will handle real-time feed updates.
      // Push notifications are a fallback when the app is backgrounded.
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to the appropriate screen based on the notification data.
    // This would integrate with the router, but since go_router navigation
    // requires BuildContext, this is handled at the widget layer.
    final data = message.data;
    final _ = data['event_type'] as String?;
    // Navigation handling would be done via a stream/callback
    // that the app shell listens to.
  }

  String _getPlatform() {
    // Dart doesn't have a clean way to check iOS vs Android without
    // importing dart:io, so we use a simple approach.
    return 'mobile';
  }
}
