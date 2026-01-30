import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,  // Use email instead of username
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'] as String;
        final refreshToken = response.data['refresh'] as String;
        
        await _apiClient.saveTokens(accessToken, refreshToken);
        
        // Get user info (using djoser endpoint)
        try {
          final userResponse = await _apiClient.dio.get('${ApiConstants.apiBaseUrl}/auth/users/me/');
          final user = UserModel.fromJson(userResponse.data);

          return {
            'success': true,
            'user': user,
            'access_token': accessToken,
            'refresh_token': refreshToken,
          };
        } catch (e) {
          print('Error fetching user info: $e');
          // If user endpoint fails, return error
          return {
            'success': false,
            'error': 'Failed to fetch user profile. Please try again.',
          };
        }
      }

      return {'success': false, 'error': 'Login failed'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Login failed',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (response.statusCode == 201) {
        // Auto-login after registration
        return await login(email, password);
      }

      return {'success': false, 'error': 'Registration failed'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data ?? 'Registration failed',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _apiClient.dio.delete(ApiConstants.deleteAccount);

      if (response.statusCode == 200) {
        await _apiClient.clearTokens();
        return {'success': true};
      }

      return {'success': false, 'error': 'Failed to delete account'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to delete account',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Set tokens directly (for admin impersonation) and load user
  Future<Map<String, dynamic>> setTokensAndLoadUser(
    String accessToken,
    String refreshToken,
  ) async {
    try {
      // Save the new tokens
      await _apiClient.saveTokens(accessToken, refreshToken);

      // Fetch user info with new tokens
      final userResponse = await _apiClient.dio.get(
        '${ApiConstants.apiBaseUrl}/auth/users/me/',
      );
      final user = UserModel.fromJson(userResponse.data);

      return {
        'success': true,
        'user': user,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to load user',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get current user from API (used after token changes like impersonation)
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final userResponse = await _apiClient.dio.get(
        '${ApiConstants.apiBaseUrl}/auth/users/me/',
      );
      final user = UserModel.fromJson(userResponse.data);

      return {
        'success': true,
        'user': user,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['detail'] ?? 'Failed to load user',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      // Sign out first to ensure account picker shows
      await googleSignIn.signOut();

      final account = await googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'error': 'Sign-in cancelled'};
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        return {'success': false, 'error': 'Failed to get ID token from Google'};
      }

      final response = await _apiClient.dio.post(
        ApiConstants.googleLogin,
        data: {'id_token': idToken},
      );

      await _apiClient.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );

      final user = UserModel.fromJson(response.data['user']);

      return {
        'success': true,
        'user': user,
      };
    } on DioException catch (e) {
      final error = e.response?.data['error'] ?? 'Google sign-in failed';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign in with Apple
  Future<Map<String, dynamic>> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;

      if (idToken == null) {
        return {'success': false, 'error': 'Failed to get ID token from Apple'};
      }

      final response = await _apiClient.dio.post(
        ApiConstants.appleLogin,
        data: {'id_token': idToken},
      );

      await _apiClient.saveTokens(
        response.data['access'],
        response.data['refresh'],
      );

      final user = UserModel.fromJson(response.data['user']);

      return {
        'success': true,
        'user': user,
      };
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {'success': false, 'error': 'Sign-in cancelled'};
      }
      return {'success': false, 'error': 'Apple sign-in failed: ${e.message}'};
    } on DioException catch (e) {
      final error = e.response?.data['error'] ?? 'Apple sign-in failed';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
