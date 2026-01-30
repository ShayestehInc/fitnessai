import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late final Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': ApiConstants.contentType,
          'ngrok-skip-browser-warning': 'true',  // Bypass ngrok interstitial
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (object) => print('API: $object'),
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
          }
          print('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('API Response: ${response.statusCode} for ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('API Error: ${error.response?.statusCode} for ${error.requestOptions.path}');
          print('API Error message: ${error.message}');

          // Don't try to refresh token for auth endpoints (login, register, refresh)
          final path = error.requestOptions.path;
          final isAuthEndpoint = path.contains('/auth/jwt/create') ||
                                  path.contains('/auth/jwt/refresh') ||
                                  path.contains('/auth/users/') ||
                                  path.contains('/auth/google') ||
                                  path.contains('/auth/apple');

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            // Try to refresh token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the request
              final opts = error.requestOptions;
              final token = await _getToken();
              if (token != null) {
                opts.headers[ApiConstants.authorization] = '${ApiConstants.bearer} $token';
              }
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access'] as String;
        await prefs.setString(_tokenKey, newToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
}
