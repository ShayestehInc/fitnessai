import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

/// State for admin impersonating a trainer
class AdminImpersonationState {
  final bool isImpersonating;
  final int? trainerId;
  final String? trainerEmail;
  final String? trainerName;
  final String? originalAccessToken;
  final String? originalRefreshToken;

  const AdminImpersonationState({
    this.isImpersonating = false,
    this.trainerId,
    this.trainerEmail,
    this.trainerName,
    this.originalAccessToken,
    this.originalRefreshToken,
  });

  AdminImpersonationState copyWith({
    bool? isImpersonating,
    int? trainerId,
    String? trainerEmail,
    String? trainerName,
    String? originalAccessToken,
    String? originalRefreshToken,
  }) {
    return AdminImpersonationState(
      isImpersonating: isImpersonating ?? this.isImpersonating,
      trainerId: trainerId ?? this.trainerId,
      trainerEmail: trainerEmail ?? this.trainerEmail,
      trainerName: trainerName ?? this.trainerName,
      originalAccessToken: originalAccessToken ?? this.originalAccessToken,
      originalRefreshToken: originalRefreshToken ?? this.originalRefreshToken,
    );
  }

  AdminImpersonationState clear() {
    return const AdminImpersonationState();
  }
}

/// Notifier for admin impersonation
class AdminImpersonationNotifier extends StateNotifier<AdminImpersonationState> {
  final AdminRepository _repository;
  final ApiClient _apiClient;
  final AuthNotifier _authNotifier;

  AdminImpersonationNotifier(this._repository, this._apiClient, this._authNotifier)
      : super(const AdminImpersonationState());

  /// Start impersonating a trainer
  Future<Map<String, dynamic>> startImpersonation({
    required int trainerId,
    required String trainerEmail,
    String? trainerName,
  }) async {
    // Store original admin tokens
    final originalAccess = await _apiClient.getAccessToken();
    final originalRefresh = await _apiClient.getRefreshToken();

    final result = await _repository.impersonateTrainer(trainerId);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final accessToken = data['access'] as String;
      final refreshToken = data['refresh'] as String;

      // Save trainer tokens
      await _apiClient.saveTokens(accessToken, refreshToken);

      state = state.copyWith(
        isImpersonating: true,
        trainerId: trainerId,
        trainerEmail: trainerEmail,
        trainerName: trainerName ?? trainerEmail,
        originalAccessToken: originalAccess,
        originalRefreshToken: originalRefresh,
      );

      // Refresh auth state to load the impersonated user's profile
      await _authNotifier.refreshCurrentUser();

      return {'success': true};
    }

    return result;
  }

  /// End impersonation and return to admin account
  Future<Map<String, dynamic>> endImpersonation() async {
    // Call backend to end impersonation (optional, for audit logging)
    try {
      await _repository.endImpersonation();
    } catch (e) {
      // Ignore errors - we still want to restore tokens
    }

    // Restore original admin tokens
    if (state.originalAccessToken != null && state.originalRefreshToken != null) {
      await _apiClient.saveTokens(
        state.originalAccessToken!,
        state.originalRefreshToken!,
      );
    }

    state = state.clear();

    // Refresh auth state to restore the original user's profile
    await _authNotifier.refreshCurrentUser();

    return {'success': true};
  }

  /// Check if currently impersonating
  bool get isImpersonating => state.isImpersonating;
}

/// Provider for admin impersonation
final adminImpersonationProvider =
    StateNotifierProvider<AdminImpersonationNotifier, AdminImpersonationState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final authNotifier = ref.watch(authStateProvider.notifier);
  return AdminImpersonationNotifier(repository, apiClient, authNotifier);
});
