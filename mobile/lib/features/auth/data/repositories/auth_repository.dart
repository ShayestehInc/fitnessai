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
    String? referralCode,
  }) async {
    try {
      final data = <String, dynamic>{
        'email': email,
        'password': password,
        'role': role,
      };
      if (referralCode != null && referralCode.isNotEmpty) {
        data['referral_code'] = referralCode;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: data,
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

  /// Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.profileImage,
        data: formData,
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['user']);
        return {
          'success': true,
          'user': user,
          'profile_image': response.data['profile_image'],
        };
      }

      return {'success': false, 'error': 'Failed to upload image'};
    } on DioException catch (e) {
      final error = e.response?.data['error'] ?? 'Failed to upload image';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove profile image
  Future<Map<String, dynamic>> removeProfileImage() async {
    try {
      final response = await _apiClient.dio.delete(ApiConstants.profileImage);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['user']);
        return {
          'success': true,
          'user': user,
        };
      }

      return {'success': false, 'error': 'Failed to remove image'};
    } on DioException catch (e) {
      final error = e.response?.data['error'] ?? 'Failed to remove image';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Request a password reset email
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.resetPassword,
        data: {'email': email},
      );
      // Djoser returns 204 regardless of whether email exists (no enumeration)
      return {'success': true};
    } on DioException catch (e) {
      // Even on error, don't reveal whether email exists
      if (e.response?.statusCode == 204 || e.response?.statusCode == 200) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': 'Failed to send reset email. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Confirm password reset with uid, token, and new password
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.resetPasswordConfirm,
        data: {
          'uid': uid,
          'token': token,
          'new_password': newPassword,
        },
      );
      return {'success': true};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map) {
          // Extract field errors from Djoser response
          final errors = <String>[];
          for (final entry in data.entries) {
            final value = entry.value;
            if (value is List) {
              errors.addAll(value.map((v) => v.toString()));
            } else if (value is String) {
              errors.add(value);
            }
          }
          if (errors.isNotEmpty) {
            return {'success': false, 'error': errors.join('\n')};
          }
        }
        return {
          'success': false,
          'error': 'Invalid or expired reset link. Please request a new one.',
        };
      }
      return {
        'success': false,
        'error': 'Failed to reset password. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Update user profile (name, business name)
  Future<Map<String, dynamic>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? businessName,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (businessName != null) data['business_name'] = businessName;

      final response = await _apiClient.dio.patch(
        ApiConstants.userMe,
        data: data,
      );

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data['user']);
        return {
          'success': true,
          'user': user,
        };
      }

      return {'success': false, 'error': 'Failed to update profile'};
    } on DioException catch (e) {
      final error = e.response?.data['error'] ?? 'Failed to update profile';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
