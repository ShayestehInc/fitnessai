import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/announcement_model.dart';
import '../../data/repositories/announcement_repository.dart';

// ---------------------------------------------------------------------------
// Trainee announcement state
// ---------------------------------------------------------------------------

class AnnouncementState {
  final List<AnnouncementModel> announcements;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const AnnouncementState({
    this.announcements = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  AnnouncementState copyWith({
    List<AnnouncementModel>? announcements,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, AnnouncementState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnnouncementNotifier(AnnouncementRepository(apiClient));
});

class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  final AnnouncementRepository _repo;

  AnnouncementNotifier(this._repo) : super(const AnnouncementState());

  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repo.getAnnouncements(),
        _repo.getUnreadCount(),
      ]);
      final announcements = results[0] as List<AnnouncementModel>;
      final unreadCount = results[1] as int;
      state = state.copyWith(
        announcements: announcements,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load announcements',
      );
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _repo.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Silent failure for badge count
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllRead();
      state = state.copyWith(unreadCount: 0);
    } catch (_) {
      // Non-critical
    }
  }
}

// ---------------------------------------------------------------------------
// Trainer announcement state
// ---------------------------------------------------------------------------

class TrainerAnnouncementState {
  final List<AnnouncementModel> announcements;
  final bool isLoading;
  final String? error;

  const TrainerAnnouncementState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
  });

  TrainerAnnouncementState copyWith({
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerAnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final trainerAnnouncementProvider =
    StateNotifierProvider<TrainerAnnouncementNotifier, TrainerAnnouncementState>(
        (ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerAnnouncementNotifier(AnnouncementRepository(apiClient));
});

class TrainerAnnouncementNotifier
    extends StateNotifier<TrainerAnnouncementState> {
  final AnnouncementRepository _repo;

  TrainerAnnouncementNotifier(this._repo)
      : super(const TrainerAnnouncementState());

  Future<void> loadAnnouncements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final announcements = await _repo.getTrainerAnnouncements();
      state = state.copyWith(
        announcements: announcements,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load announcements',
      );
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    try {
      await _repo.createAnnouncement(
        title: title,
        body: body,
        isPinned: isPinned,
      );
      await loadAnnouncements();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAnnouncement({
    required int id,
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    try {
      await _repo.updateAnnouncement(
        id: id,
        title: title,
        body: body,
        isPinned: isPinned,
      );
      await loadAnnouncements();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAnnouncement(int id) async {
    try {
      await _repo.deleteAnnouncement(id);
      await loadAnnouncements();
      return true;
    } catch (_) {
      return false;
    }
  }
}
