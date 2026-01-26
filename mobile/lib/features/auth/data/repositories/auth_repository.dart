import 'package:dio/dio.dart';
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
}
