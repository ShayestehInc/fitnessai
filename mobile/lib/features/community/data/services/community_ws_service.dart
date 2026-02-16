import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/community_post_model.dart';
import '../../presentation/providers/community_feed_provider.dart';

/// Provider that manages the WebSocket connection for the community feed.
final communityWsServiceProvider = Provider<CommunityWsService>((ref) {
  final service = CommunityWsService(ref);
  ref.onDispose(() => service.disconnect());
  return service;
});

/// Service handling the WebSocket connection for real-time community feed updates.
class CommunityWsService {
  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  CommunityWsService(this._ref);

  bool get isConnected => _isConnected;

  /// Connect to the community feed WebSocket.
  Future<void> connect() async {
    if (_isConnected) return;

    final apiClient = _ref.read(apiClientProvider);
    final token = await apiClient.getAccessToken();
    if (token == null) return;

    final wsUrl = '${ApiConstants.wsCommunityFeed}?token=$token';

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
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  void _onMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'new_post':
          final postData = data['post'] as Map<String, dynamic>?;
          if (postData != null) {
            final post = CommunityPostModel.fromJson(postData);
            _ref.read(communityFeedProvider.notifier).onNewPost(post);
          }
        case 'post_deleted':
          final postId = data['post_id'] as int?;
          if (postId != null) {
            _ref.read(communityFeedProvider.notifier).onPostDeleted(postId);
          }
        case 'new_comment':
          final postId = data['post_id'] as int?;
          if (postId != null) {
            _ref.read(communityFeedProvider.notifier).onNewComment(postId);
          }
        case 'reaction_update':
          final postId = data['post_id'] as int?;
          final reactions = data['reactions'] as Map<String, dynamic>?;
          if (postId != null && reactions != null) {
            _ref.read(communityFeedProvider.notifier).onReactionUpdate(
              postId,
              ReactionCounts(
                fire: (reactions['fire'] as num?)?.toInt() ?? 0,
                thumbsUp: (reactions['thumbs_up'] as num?)?.toInt() ?? 0,
                heart: (reactions['heart'] as num?)?.toInt() ?? 0,
              ),
            );
          }
      }
    } catch (_) {
      // Ignore malformed messages
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
    // Exponential backoff: 3s, 6s, 12s, 24s, 48s
    final delay = _reconnectDelay * (1 << _reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect();
    });
  }
}
