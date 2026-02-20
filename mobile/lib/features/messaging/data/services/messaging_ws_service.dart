import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/message_model.dart';
import '../../presentation/providers/messaging_provider.dart';

/// Provider that manages the WebSocket connection for a specific conversation.
final messagingWsServiceProvider =
    Provider.family<MessagingWsService, int>((ref, conversationId) {
  final service = MessagingWsService(ref, conversationId);
  ref.onDispose(() => service.disconnect());
  return service;
});

/// Service handling WebSocket connection for real-time messaging.
class MessagingWsService {
  final Ref _ref;
  final int conversationId;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _typingDebounceTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  MessagingWsService(this._ref, this.conversationId);

  bool get isConnected => _isConnected;

  /// Connect to the conversation WebSocket.
  Future<void> connect() async {
    if (_isConnected) return;

    final apiClient = _ref.read(apiClientProvider);
    final token = await apiClient.getAccessToken();
    if (token == null) return;

    final wsUrl =
        '${ApiConstants.wsMessaging(conversationId)}?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      _reconnectAttempts = 0;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Disconnect from the WebSocket.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  /// Send typing indicator.
  void sendTyping({bool isTyping = true}) {
    if (!_isConnected || _channel == null) return;

    _channel!.sink.add(jsonEncode({
      'type': 'typing',
      'is_typing': isTyping,
    }));

    // Auto-stop typing after 3 seconds of inactivity
    _typingDebounceTimer?.cancel();
    if (isTyping) {
      _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
        sendTyping(isTyping: false);
      });
    }
  }

  void _onMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'new_message':
          final messageData = data['message'] as Map<String, dynamic>?;
          if (messageData != null) {
            final message = MessageModel.fromJson(messageData);
            _ref
                .read(chatProvider(conversationId).notifier)
                .onNewMessage(message);
          }
        case 'typing_indicator':
          final userId = data['user_id'] as int?;
          final isTyping = data['is_typing'] as bool? ?? false;
          if (userId != null) {
            _ref
                .read(chatProvider(conversationId).notifier)
                .onTypingIndicator(userId, isTyping);
          }
        case 'read_receipt':
          final readerId = data['reader_id'] as int?;
          final readAtStr = data['read_at'] as String?;
          if (readerId != null && readAtStr != null) {
            _ref
                .read(chatProvider(conversationId).notifier)
                .onReadReceipt(readerId, DateTime.parse(readAtStr));
          }
        case 'message_edited':
          final messageId = data['message_id'] as int?;
          final content = data['content'] as String?;
          final editedAtStr = data['edited_at'] as String?;
          if (messageId != null && content != null && editedAtStr != null) {
            _ref
                .read(chatProvider(conversationId).notifier)
                .onMessageEdited(messageId, content, DateTime.parse(editedAtStr));
          }
        case 'message_deleted':
          final messageId = data['message_id'] as int?;
          if (messageId != null) {
            _ref
                .read(chatProvider(conversationId).notifier)
                .onMessageDeleted(messageId);
          }
        case 'pong':
          break;
      }
    } catch (e) {
      // Intentionally silent — malformed WS messages are non-fatal
    }
  }

  void _onError(Object error) {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _onDone() {
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    final delay = _reconnectDelay * (1 << _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }
}
