import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/space_model.dart';
import '../../data/repositories/space_repository.dart';

// ---------------------------------------------------------------------------
// Spaces list
// ---------------------------------------------------------------------------

class SpacesState {
  final List<SpaceModel> spaces;
  final bool isLoading;
  final String? error;

  const SpacesState({
    this.spaces = const [],
    this.isLoading = false,
    this.error,
  });

  SpacesState copyWith({
    List<SpaceModel>? spaces,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SpacesState(
      spaces: spaces ?? this.spaces,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final spacesProvider =
    StateNotifierProvider<SpacesNotifier, SpacesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SpacesNotifier(SpaceRepository(apiClient));
});

class SpacesNotifier extends StateNotifier<SpacesState> {
  final SpaceRepository _repo;

  SpacesNotifier(this._repo) : super(const SpacesState());

  Future<void> loadSpaces() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final spaces = await _repo.getSpaces();
      state = state.copyWith(spaces: spaces, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load spaces',
      );
    }
  }

  Future<bool> createSpace({
    required String name,
    String description = '',
    String emoji = '💬',
    String visibility = 'public',
    bool isDefault = false,
    String? coverImagePath,
  }) async {
    try {
      final space = await _repo.createSpace(
        name: name,
        description: description,
        emoji: emoji,
        visibility: visibility,
        isDefault: isDefault,
        coverImagePath: coverImagePath,
      );
      state = state.copyWith(spaces: [...state.spaces, space]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> joinSpace(int spaceId) async {
    try {
      await _repo.joinSpace(spaceId);
      state = state.copyWith(
        spaces: state.spaces.map((s) {
          if (s.id == spaceId) {
            return s.copyWith(isMember: true, memberCount: s.memberCount + 1);
          }
          return s;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> leaveSpace(int spaceId) async {
    try {
      await _repo.leaveSpace(spaceId);
      state = state.copyWith(
        spaces: state.spaces.map((s) {
          if (s.id == spaceId) {
            return s.copyWith(
              isMember: false,
              memberCount: (s.memberCount - 1).clamp(0, 999999),
            );
          }
          return s;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Current space filter (selected in UI)
// ---------------------------------------------------------------------------

final currentSpaceIdProvider = StateProvider<int?>((ref) => null);

// ---------------------------------------------------------------------------
// Space members
// ---------------------------------------------------------------------------

class SpaceMembersState {
  final List<SpaceMembershipModel> members;
  final bool isLoading;
  final String? error;

  const SpaceMembersState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  SpaceMembersState copyWith({
    List<SpaceMembershipModel>? members,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SpaceMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final spaceMembersProvider = StateNotifierProvider.family<
    SpaceMembersNotifier, SpaceMembersState, int>((ref, spaceId) {
  final apiClient = ref.watch(apiClientProvider);
  return SpaceMembersNotifier(SpaceRepository(apiClient), spaceId);
});

class SpaceMembersNotifier extends StateNotifier<SpaceMembersState> {
  final SpaceRepository _repo;
  final int _spaceId;

  SpaceMembersNotifier(this._repo, this._spaceId)
      : super(const SpaceMembersState());

  Future<void> loadMembers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final members = await _repo.getMembers(_spaceId);
      state = state.copyWith(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load members',
      );
    }
  }
}
