import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/progression_profile_model.dart';
import '../../data/repositories/progression_profile_repository.dart';

final progressionProfileRepositoryProvider =
    Provider<ProgressionProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgressionProfileRepository(apiClient);
});

/// State for the progression profile screen.
class ProgressionProfileState {
  final List<ProgressionProfileModel> profiles;
  final ProgressionProfileModel? selectedProfile;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ProgressionProfileState({
    this.profiles = const [],
    this.selectedProfile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ProgressionProfileState copyWith({
    List<ProgressionProfileModel>? profiles,
    ProgressionProfileModel? selectedProfile,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return ProgressionProfileState(
      profiles: profiles ?? this.profiles,
      selectedProfile: selectedProfile ?? this.selectedProfile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class ProgressionProfileNotifier
    extends StateNotifier<ProgressionProfileState> {
  final ProgressionProfileRepository _repository;

  ProgressionProfileNotifier(this._repository)
      : super(const ProgressionProfileState());

  Future<void> loadProfiles() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.listProfiles();
    if (result['success'] == true) {
      final profiles = result['data'] as List<ProgressionProfileModel>;
      state = state.copyWith(
        profiles: profiles,
        isLoading: false,
        selectedProfile: profiles.isNotEmpty ? profiles.first : null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<void> loadProfile(int profileId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getProfile(profileId);
    if (result['success'] == true) {
      state = state.copyWith(
        selectedProfile: result['data'] as ProgressionProfileModel,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void selectProfile(ProgressionProfileModel profile) {
    state = state.copyWith(selectedProfile: profile);
  }

  Future<bool> updateProfile(
    int profileId, {
    String? strategy,
    Map<String, dynamic>? config,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    final result = await _repository.updateProfile(
      profileId,
      strategy: strategy,
      config: config,
    );
    if (result['success'] == true) {
      final updated = result['data'] as ProgressionProfileModel;
      final updatedList = state.profiles.map((p) {
        return p.id == profileId ? updated : p;
      }).toList();
      state = state.copyWith(
        profiles: updatedList,
        selectedProfile: updated,
        isSaving: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }
}

final progressionProfileProvider = StateNotifierProvider<
    ProgressionProfileNotifier, ProgressionProfileState>((ref) {
  final repository = ref.watch(progressionProfileRepositoryProvider);
  return ProgressionProfileNotifier(repository);
});

/// State for the suggestions list screen.
class ProgressionSuggestionsListState {
  final List<ProgressionPlanSuggestionModel> suggestions;
  final bool isLoading;
  final String? error;

  const ProgressionSuggestionsListState({
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
  });

  ProgressionSuggestionsListState copyWith({
    List<ProgressionPlanSuggestionModel>? suggestions,
    bool? isLoading,
    String? error,
  }) {
    return ProgressionSuggestionsListState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProgressionSuggestionsListNotifier
    extends StateNotifier<ProgressionSuggestionsListState> {
  final ProgressionProfileRepository _repository;

  ProgressionSuggestionsListNotifier(this._repository)
      : super(const ProgressionSuggestionsListState());

  Future<void> loadSuggestions() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.listSuggestions();
    if (result['success'] == true) {
      state = state.copyWith(
        suggestions:
            result['data'] as List<ProgressionPlanSuggestionModel>,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<bool> approveSuggestion(int suggestionId) async {
    final result = await _repository.approveSuggestion(suggestionId);
    if (result['success'] == true) {
      _updateSuggestionStatus(suggestionId, 'approved');
      return true;
    }
    return false;
  }

  Future<bool> dismissSuggestion(int suggestionId) async {
    final result = await _repository.dismissSuggestion(suggestionId);
    if (result['success'] == true) {
      _updateSuggestionStatus(suggestionId, 'dismissed');
      return true;
    }
    return false;
  }

  void _updateSuggestionStatus(int id, String newStatus) {
    final updated = state.suggestions.where((s) => s.id != id).toList();
    state = state.copyWith(suggestions: updated);
  }
}

final progressionSuggestionsListProvider = StateNotifierProvider<
    ProgressionSuggestionsListNotifier,
    ProgressionSuggestionsListState>((ref) {
  final repository = ref.watch(progressionProfileRepositoryProvider);
  return ProgressionSuggestionsListNotifier(repository);
});
