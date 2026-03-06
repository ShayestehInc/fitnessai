import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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

  /// Stream subscriptions that must be cancelled on deactivation to prevent
  /// duplicate listeners after login -> logout -> login cycles.
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  PushNotificationService(this._ref);

  /// Initialize FCM, local notifications, and register device token.
  /// Call after successful login (needs auth token for registration).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        debugPrint('Firebase initialization failed: $e');
        _initialized = false;
        return;
      }
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

    // Listen for token refresh (cancel previous subscription first to
    // avoid duplicates after logout -> login cycles).
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _registerToken(newToken);
    });

    // Handle foreground messages
    _foregroundMessageSub?.cancel();
    _foregroundMessageSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated tap
    _messageOpenedSub?.cancel();
    _messageOpenedSub =
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
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  /// Deactivate the current token on logout.
  /// Cancels stream subscriptions and resets _initialized so the next
  /// login re-registers the token without creating duplicate listeners.
  Future<void> deactivateToken() async {
    // Cancel stream subscriptions to prevent duplicate listeners on re-login.
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundMessageSub?.cancel();
    _foregroundMessageSub = null;
    _messageOpenedSub?.cancel();
    _messageOpenedSub = null;

    if (_currentToken == null) {
      _initialized = false;
      return;
    }
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.dio.delete(
        ApiConstants.deviceToken,
        data: {'token': _currentToken},
      );
    } catch (e) {
      debugPrint('FCM token deactivation failed: $e');
    }
    _currentToken = null;
    _initialized = false;
  }

  /// Show a local notification when a push arrives while app is in foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final title = notification.title ?? '';
    final body = notification.body ?? '';

    // Don't show a blank notification -- nothing useful for the user.
    if (title.isEmpty && body.isEmpty) return;

    final data = message.data;

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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
            router.push('/community/events/$eventId');
          }
          break;
        case 'announcement':
          router.push('/community/announcements');
          break;
        case 'community_comment':
        case 'community_activity':
          router.push('/community');
          break;
        case 'churn_alert':
          final traineeId = data['trainee_id'] as String?;
          if (traineeId != null) {
            router.push('/trainer/trainees/$traineeId');
          }
          break;
        case 're_engagement':
          router.push('/home');
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Notification deep-link navigation failed: $e');
    }
  }

  /// Encode notification data as JSON string for local notification payload.
  String _buildPayload(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Parse the JSON payload string back to a map.
  Map<String, dynamic> _parsePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }
}
