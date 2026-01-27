import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for managing API base URL configuration
class ApiConfigService {
  static const String _baseUrlKey = 'api_base_url';
  static const String defaultBaseUrl = 'http://localhost:8000';

  static String? _cachedBaseUrl;

  /// Get the current base URL
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    final prefs = await SharedPreferences.getInstance();
    _cachedBaseUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  /// Get the cached base URL synchronously (returns default if not loaded)
  static String getBaseUrlSync() {
    return _cachedBaseUrl ?? defaultBaseUrl;
  }

  /// Set a new base URL
  static Future<void> setBaseUrl(String url) async {
    // Remove trailing slash if present
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, cleanUrl);
    _cachedBaseUrl = cleanUrl;
  }

  /// Reset to default URL
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    _cachedBaseUrl = defaultBaseUrl;
  }

  /// Initialize the service (call at app startup)
  static Future<void> initialize() async {
    await getBaseUrl();
  }
}

/// Provider for the current base URL
final apiBaseUrlProvider = StateProvider<String>((ref) {
  return ApiConfigService.getBaseUrlSync();
});

/// Notifier to update the base URL
class ApiConfigNotifier extends StateNotifier<String> {
  ApiConfigNotifier() : super(ApiConfigService.getBaseUrlSync());

  Future<void> setBaseUrl(String url) async {
    await ApiConfigService.setBaseUrl(url);
    state = url;
  }

  Future<void> resetToDefault() async {
    await ApiConfigService.resetToDefault();
    state = ApiConfigService.defaultBaseUrl;
  }
}

final apiConfigProvider = StateNotifierProvider<ApiConfigNotifier, String>((ref) {
  return ApiConfigNotifier();
});
