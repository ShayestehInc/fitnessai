import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final pushService = ref.watch(pushNotificationServiceProvider);
  return AuthNotifier(repository, pushService);
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
  final PushNotificationService _pushService;

  AuthNotifier(this._repository, this._pushService) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.login(email, password);

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      // Register device for push notifications after successful login
      unawaited(_pushService.initialize());
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
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.register(
      email: email,
      password: password,
      role: role,
      referralCode: referralCode,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      unawaited(_pushService.initialize());
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String,
      );
    }
  }

  Future<void> logout() async {
    await _pushService.deactivateToken();
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
          businessName: state.user!.businessName,
          onboardingCompleted: true,
          profileImage: state.user!.profileImage,
          trainer: state.user!.trainer,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    await _pushService.deactivateToken();
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

  /// Set tokens directly and load user (for admin/trainer impersonation).
  /// Deactivates the current push token first so the device is not left
  /// registered under the previous user, which would cause the impersonator
  /// to receive the impersonated user's notifications after ending the session.
  Future<void> setTokensAndLoadUser(
    String accessToken,
    String refreshToken,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    // Deactivate push token for the current user before switching identity.
    await _pushService.deactivateToken();

    final result = await _repository.setTokensAndLoadUser(
      accessToken,
      refreshToken,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      unawaited(_pushService.initialize());
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  /// Refresh the current user from the API (used after token changes like impersonation)
  Future<void> refreshCurrentUser() async {
    final result = await _repository.getCurrentUser();

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
      );
    }
  }

  /// Sign in with Google
  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.loginWithGoogle();

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      unawaited(_pushService.initialize());
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  /// Sign in with Apple
  Future<void> loginWithApple() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.loginWithApple();

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      unawaited(_pushService.initialize());
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  /// Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.uploadProfileImage(filePath);

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      return {'success': true};
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
      return result;
    }
  }

  /// Remove profile image
  Future<Map<String, dynamic>> removeProfileImage() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.removeProfileImage();

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      return {'success': true};
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
      return result;
    }
  }

  /// Update user profile (name, business name)
  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? businessName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      businessName: businessName,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        user: result['user'] as UserModel,
        isLoading: false,
      );
      return {'success': true};
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
      return result;
    }
  }
}
