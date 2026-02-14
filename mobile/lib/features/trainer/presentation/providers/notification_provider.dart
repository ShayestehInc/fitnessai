import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trainer_notification_model.dart';
import 'trainer_provider.dart';

/// Provider for unread notification count (used for badge display).
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getUnreadNotificationCount();
  if (result['success'] == true) {
    return result['data'] as int;
  }
  return 0;
});

/// Provider for paginated notification list.
final notificationsProvider =
    AsyncNotifierProvider.autoDispose<NotificationsNotifier, List<TrainerNotificationModel>>(
  NotificationsNotifier.new,
);

class NotificationsNotifier extends AutoDisposeAsyncNotifier<List<TrainerNotificationModel>> {
  int _currentPage = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<TrainerNotificationModel>> build() async {
    _currentPage = 1;
    _hasMore = true;
    return _fetchPage(1);
  }

  Future<List<TrainerNotificationModel>> _fetchPage(int page) async {
    final repository = ref.read(trainerRepositoryProvider);
    final result = await repository.getNotifications(page: page);
    if (result['success'] == true) {
      _hasMore = result['has_next'] as bool? ?? false;
      return result['data'] as List<TrainerNotificationModel>;
    }
    throw Exception(result['error'] ?? 'Failed to load notifications');
  }

  /// Load more notifications (pagination).
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final currentState = state;
    if (currentState is! AsyncData<List<TrainerNotificationModel>>) return;

    _currentPage++;
    final newPage = await _fetchPage(_currentPage);
    state = AsyncData([...currentState.value, ...newPage]);
  }

  /// Mark a single notification as read (optimistic update).
  Future<bool> markRead(int notificationId) async {
    final currentState = state;
    if (currentState is! AsyncData<List<TrainerNotificationModel>>) return false;

    // Optimistic update
    final updated = currentState.value.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = AsyncData(updated);

    final repository = ref.read(trainerRepositoryProvider);
    final result = await repository.markNotificationRead(notificationId);
    if (result['success'] != true) {
      // Revert on failure
      state = currentState;
      return false;
    }

    ref.invalidate(unreadNotificationCountProvider);
    return true;
  }

  /// Mark all notifications as read.
  Future<bool> markAllRead() async {
    final currentState = state;
    if (currentState is! AsyncData<List<TrainerNotificationModel>>) return false;

    // Optimistic update
    final updated = currentState.value.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();
    state = AsyncData(updated);

    final repository = ref.read(trainerRepositoryProvider);
    final result = await repository.markAllNotificationsRead();
    if (result['success'] != true) {
      state = currentState;
      return false;
    }

    ref.invalidate(unreadNotificationCountProvider);
    return true;
  }

  /// Delete a notification (optimistic removal).
  Future<bool> deleteNotification(int notificationId) async {
    final currentState = state;
    if (currentState is! AsyncData<List<TrainerNotificationModel>>) return false;

    // Optimistic removal
    final updated = currentState.value.where((n) => n.id != notificationId).toList();
    state = AsyncData(updated);

    final repository = ref.read(trainerRepositoryProvider);
    final result = await repository.deleteNotification(notificationId);
    if (result['success'] != true) {
      state = currentState;
      return false;
    }

    ref.invalidate(unreadNotificationCountProvider);
    return true;
  }
}
