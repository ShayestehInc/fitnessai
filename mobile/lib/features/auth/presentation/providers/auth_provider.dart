import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.login(email, password);
    
    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String,
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.register(
      email: email,
      password: password,
      role: role,
    );
    
    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String,
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }

  /// Update the user's onboarding completed status
  void markOnboardingCompleted() {
    if (state.user != null) {
      state = state.copyWith(
        user: UserModel(
          id: state.user!.id,
          email: state.user!.email,
          role: state.user!.role,
          firstName: state.user!.firstName,
          lastName: state.user!.lastName,
          onboardingCompleted: true,
          trainer: state.user!.trainer,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.deleteAccount();

    if (result['success'] == true) {
      state = AuthState();
      return {'success': true};
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String,
      );
      return result;
    }
  }
}
