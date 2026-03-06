import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../router/app_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Provider for the push notification service.
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

/// Android notification channel ID.
const _channelId = 'fitnessai_default';
const _channelName = 'FitnessAI Notifications';

/// Handles Firebase Cloud Messaging initialization, token registration,
/// foreground local notification display, and notification tap deep linking.
class PushNotificationService {
  final Ref _ref;
  String? _currentToken;
  bool _initialized = false;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  PushNotificationService(this._ref);

  /// Initialize FCM, local notifications, and register device token.
  /// Call after successful login (needs auth token for registration).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase may already be initialized
    }

    await _initLocalNotifications();

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

    // Check if app was opened from a terminated-state notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Initialize flutter_local_notifications for foreground display.
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          importance: Importance.high,
        ),
      );
    }
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

  /// Show a local notification when a push arrives while app is in foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;

    _localNotifications.show(
      message.hashCode,
      notification.title ?? '',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _buildPayload(data),
    );
  }

  /// Handle notification tap from background/terminated state.
  void _handleMessageOpenedApp(RemoteMessage message) {
    _navigateFromNotification(message.data);
  }

  /// Handle tap on a local notification displayed in foreground.
  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final data = _parsePayload(payload);
    _navigateFromNotification(data);
  }

  /// Navigate to the appropriate screen based on notification data.
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    try {
      final router = _ref.read(routerProvider);

      switch (type) {
        case 'community_event_created':
        case 'community_event_updated':
        case 'community_event_cancelled':
        case 'community_event_reminder':
          final eventId = data['event_id'] as String?;
          if (eventId != null) {
            router.push('/community-event-detail/$eventId');
          }
          break;
        case 'announcement':
          router.push('/announcements');
          break;
        case 'community_comment':
        case 'community_activity':
          router.push('/community');
          break;
        default:
          break;
      }
    } catch (_) {
      // Navigation may fail if router not ready; ignore
    }
  }

  /// Encode notification data as a simple key=value payload string.
  String _buildPayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Parse the payload string back to a map.
  Map<String, dynamic> _parsePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final idx = pair.indexOf('=');
      if (idx > 0) {
        map[pair.substring(0, idx)] = pair.substring(idx + 1);
      }
    }
    return map;
  }

  String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }
}
