import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/achievement_model.dart';
import '../../data/repositories/achievement_repository.dart';

class AchievementState {
  final List<AchievementModel> achievements;
  final bool isLoading;
  final String? error;

  const AchievementState({
    this.achievements = const [],
    this.isLoading = false,
    this.error,
  });

  AchievementState copyWith({
    List<AchievementModel>? achievements,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AchievementState(
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get earnedCount => achievements.where((a) => a.earned).length;
  int get totalCount => achievements.length;
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AchievementNotifier(AchievementRepository(apiClient));
});

class AchievementNotifier extends StateNotifier<AchievementState> {
  final AchievementRepository _repo;

  AchievementNotifier(this._repo) : super(const AchievementState());

  Future<void> loadAchievements() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final achievements = await _repo.getAchievements();
      state = state.copyWith(
        achievements: achievements,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load achievements',
      );
    }
  }
}
