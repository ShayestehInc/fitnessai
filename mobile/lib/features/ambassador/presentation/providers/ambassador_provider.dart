import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ambassador_models.dart';
import '../../data/repositories/ambassador_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final ambassadorRepositoryProvider = Provider<AmbassadorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AmbassadorRepository(apiClient);
});

// Ambassador Dashboard State

class AmbassadorDashboardState {
  final AmbassadorDashboardData? data;
  final bool isLoading;
  final String? error;

  const AmbassadorDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  AmbassadorDashboardState copyWith({
    AmbassadorDashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return AmbassadorDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AmbassadorDashboardNotifier extends StateNotifier<AmbassadorDashboardState> {
  final AmbassadorRepository _repository;

  AmbassadorDashboardNotifier(this._repository) : super(const AmbassadorDashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getDashboard();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update the ambassador's referral code.
  ///
  /// Rethrows exceptions so that the calling dialog can catch and display
  /// errors inline without polluting the dashboard-level error state.
  Future<void> updateReferralCode(String code) async {
    await _repository.updateReferralCode(code);
    await loadDashboard();
  }
}

final ambassadorDashboardProvider =
    StateNotifierProvider<AmbassadorDashboardNotifier, AmbassadorDashboardState>((ref) {
  final repo = ref.watch(ambassadorRepositoryProvider);
  return AmbassadorDashboardNotifier(repo);
});

// Ambassador Referrals State

class AmbassadorReferralsState {
  final List<AmbassadorReferral> referrals;
  final bool isLoading;
  final String? error;

  const AmbassadorReferralsState({
    this.referrals = const [],
    this.isLoading = false,
    this.error,
  });

  AmbassadorReferralsState copyWith({
    List<AmbassadorReferral>? referrals,
    bool? isLoading,
    String? error,
  }) {
    return AmbassadorReferralsState(
      referrals: referrals ?? this.referrals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AmbassadorReferralsNotifier extends StateNotifier<AmbassadorReferralsState> {
  final AmbassadorRepository _repository;

  AmbassadorReferralsNotifier(this._repository) : super(const AmbassadorReferralsState());

  Future<void> loadReferrals({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final referrals = await _repository.getReferrals(status: status);
      state = state.copyWith(referrals: referrals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final ambassadorReferralsProvider =
    StateNotifierProvider<AmbassadorReferralsNotifier, AmbassadorReferralsState>((ref) {
  final repo = ref.watch(ambassadorRepositoryProvider);
  return AmbassadorReferralsNotifier(repo);
});

// Admin Ambassadors State

class AdminAmbassadorsState {
  final List<AmbassadorProfile> ambassadors;
  final bool isLoading;
  final String? error;

  const AdminAmbassadorsState({
    this.ambassadors = const [],
    this.isLoading = false,
    this.error,
  });

  AdminAmbassadorsState copyWith({
    List<AmbassadorProfile>? ambassadors,
    bool? isLoading,
    String? error,
  }) {
    return AdminAmbassadorsState(
      ambassadors: ambassadors ?? this.ambassadors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AdminAmbassadorsNotifier extends StateNotifier<AdminAmbassadorsState> {
  final AmbassadorRepository _repository;

  AdminAmbassadorsNotifier(this._repository) : super(const AdminAmbassadorsState());

  Future<void> loadAmbassadors({String? search, bool? isActive}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ambassadors = await _repository.getAmbassadors(search: search, isActive: isActive);
      state = state.copyWith(ambassadors: ambassadors, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<AmbassadorProfile?> createAmbassador({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required double commissionRate,
  }) async {
    try {
      final profile = await _repository.createAmbassador(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
        commissionRate: commissionRate,
      );
      await loadAmbassadors();
      return profile;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> updateAmbassador(int id, {double? commissionRate, bool? isActive}) async {
    try {
      await _repository.updateAmbassador(id, commissionRate: commissionRate, isActive: isActive);
      await loadAmbassadors();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final adminAmbassadorsProvider =
    StateNotifierProvider<AdminAmbassadorsNotifier, AdminAmbassadorsState>((ref) {
  final repo = ref.watch(ambassadorRepositoryProvider);
  return AdminAmbassadorsNotifier(repo);
});
