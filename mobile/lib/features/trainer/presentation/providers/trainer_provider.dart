import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/trainee_model.dart';
import '../../data/models/trainer_stats_model.dart';
import '../../data/models/invitation_model.dart';
import '../../data/models/impersonation_session_model.dart';
import '../../data/repositories/trainer_repository.dart';

// Repository provider
final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerRepository(apiClient);
});

// Stats provider
final trainerStatsProvider = FutureProvider.autoDispose<TrainerStatsModel?>((ref) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getStats();
  if (result['success']) {
    return result['data'] as TrainerStatsModel;
  }
  return null;
});

// Trainees list provider
final traineesProvider = FutureProvider.autoDispose<List<TraineeModel>>((ref) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getTrainees();
  if (result['success']) {
    return result['data'] as List<TraineeModel>;
  }
  return [];
});

// Single trainee detail provider
final traineeDetailProvider = FutureProvider.autoDispose.family<TraineeDetailModel?, int>((ref, traineeId) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getTraineeDetail(traineeId);
  if (result['success']) {
    return result['data'] as TraineeDetailModel;
  }
  return null;
});

// Trainee activity provider
final traineeActivityProvider = FutureProvider.autoDispose.family<List<ActivitySummary>, int>((ref, traineeId) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getTraineeActivity(traineeId);
  if (result['success']) {
    return result['data'] as List<ActivitySummary>;
  }
  return [];
});

// Invitations provider
final invitationsProvider = FutureProvider.autoDispose<List<InvitationModel>>((ref) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getInvitations();
  if (result['success']) {
    return result['data'] as List<InvitationModel>;
  }
  return [];
});

// Impersonation state
class ImpersonationState {
  final bool isImpersonating;
  final ImpersonationSessionModel? session;
  final ImpersonatedTrainee? trainee;
  final String? originalAccessToken;
  final String? originalRefreshToken;
  final String? impersonationAccessToken;
  final String? impersonationRefreshToken;

  const ImpersonationState({
    this.isImpersonating = false,
    this.session,
    this.trainee,
    this.originalAccessToken,
    this.originalRefreshToken,
    this.impersonationAccessToken,
    this.impersonationRefreshToken,
  });

  ImpersonationState copyWith({
    bool? isImpersonating,
    ImpersonationSessionModel? session,
    ImpersonatedTrainee? trainee,
    String? originalAccessToken,
    String? originalRefreshToken,
    String? impersonationAccessToken,
    String? impersonationRefreshToken,
  }) {
    return ImpersonationState(
      isImpersonating: isImpersonating ?? this.isImpersonating,
      session: session ?? this.session,
      trainee: trainee ?? this.trainee,
      originalAccessToken: originalAccessToken ?? this.originalAccessToken,
      originalRefreshToken: originalRefreshToken ?? this.originalRefreshToken,
      impersonationAccessToken: impersonationAccessToken ?? this.impersonationAccessToken,
      impersonationRefreshToken: impersonationRefreshToken ?? this.impersonationRefreshToken,
    );
  }

  ImpersonationState clear() {
    return const ImpersonationState();
  }
}

class ImpersonationNotifier extends StateNotifier<ImpersonationState> {
  final TrainerRepository _repository;
  final ApiClient _apiClient;
  final AuthNotifier _authNotifier;

  ImpersonationNotifier(this._repository, this._apiClient, this._authNotifier)
      : super(const ImpersonationState());

  Future<Map<String, dynamic>> startImpersonation(int traineeId, {bool isReadOnly = true}) async {
    // Store original tokens
    final originalAccess = await _apiClient.getAccessToken();
    final originalRefresh = await _apiClient.getRefreshToken();

    final result = await _repository.startImpersonation(traineeId, isReadOnly: isReadOnly);

    if (result['success']) {
      final response = result['data'] as ImpersonationResponse;

      // Save impersonation tokens
      await _apiClient.saveTokens(response.access, response.refresh);

      state = state.copyWith(
        isImpersonating: true,
        session: response.session,
        trainee: response.trainee,
        originalAccessToken: originalAccess,
        originalRefreshToken: originalRefresh,
        impersonationAccessToken: response.access,
        impersonationRefreshToken: response.refresh,
      );

      // Refresh auth state to load the impersonated user's profile
      await _authNotifier.refreshCurrentUser();

      return {'success': true};
    }

    return result;
  }

  Future<Map<String, dynamic>> endImpersonation() async {
    final result = await _repository.endImpersonation(
      sessionId: state.session?.id,
    );

    // Restore original tokens regardless of API result
    if (state.originalAccessToken != null && state.originalRefreshToken != null) {
      await _apiClient.saveTokens(
        state.originalAccessToken!,
        state.originalRefreshToken!,
      );
    }

    state = state.clear();

    // Refresh auth state to restore the original user's profile
    await _authNotifier.refreshCurrentUser();

    return result;
  }
}

final impersonationProvider = StateNotifierProvider<ImpersonationNotifier, ImpersonationState>((ref) {
  final repository = ref.watch(trainerRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final authNotifier = ref.watch(authStateProvider.notifier);
  return ImpersonationNotifier(repository, apiClient, authNotifier);
});

// Analytics providers
final adherenceAnalyticsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, int>((ref, days) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getAdherenceAnalytics(days: days);
  if (result['success']) {
    return result['data'];
  }
  return null;
});

final progressAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(trainerRepositoryProvider);
  final result = await repository.getProgressAnalytics();
  if (result['success']) {
    return result['data'];
  }
  return null;
});
