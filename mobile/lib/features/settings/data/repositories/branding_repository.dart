import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../models/branding_model.dart';

/// Typed result for branding API operations.
class BrandingResult {
  final bool success;
  final BrandingModel? branding;
  final String? error;

  const BrandingResult({required this.success, this.branding, this.error});
}

/// Repository for trainer branding API calls.
class BrandingRepository {
  final ApiClient _apiClient;

  BrandingRepository(this._apiClient);

  /// Fetch trainer's own branding config (trainer-facing).
  Future<BrandingResult> getTrainerBranding() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerBranding);

      if (response.statusCode == 200) {
        final branding = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return BrandingResult(success: true, branding: branding);
      }

      return const BrandingResult(success: false, error: 'Failed to fetch branding');
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to fetch branding';
      return BrandingResult(success: false, error: error.toString());
    } on FormatException catch (e) {
      return BrandingResult(success: false, error: 'Invalid response format: $e');
    }
  }

  /// Update trainer's branding config (app_name, primary_color, secondary_color).
  Future<BrandingResult> updateTrainerBranding(BrandingModel branding) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.trainerBranding,
        data: branding.toJson(),
      );

      if (response.statusCode == 200) {
        final updated = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return BrandingResult(success: true, branding: updated);
      }

      return const BrandingResult(success: false, error: 'Failed to save branding');
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ??
          e.response?.data?['primary_color']?.first ??
          e.response?.data?['secondary_color']?.first ??
          'Failed to save branding';
      return BrandingResult(success: false, error: error.toString());
    } on FormatException catch (e) {
      return BrandingResult(success: false, error: 'Invalid response format: $e');
    }
  }

  /// Upload trainer logo image.
  Future<BrandingResult> uploadLogo(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.trainerBrandingLogo,
        data: formData,
      );

      if (response.statusCode == 200) {
        final updated = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return BrandingResult(success: true, branding: updated);
      }

      return const BrandingResult(success: false, error: 'Failed to upload logo');
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to upload logo';
      return BrandingResult(success: false, error: error.toString());
    } on FormatException catch (e) {
      return BrandingResult(success: false, error: 'Invalid response format: $e');
    }
  }

  /// Remove trainer logo.
  Future<BrandingResult> removeLogo() async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.trainerBrandingLogo,
      );

      if (response.statusCode == 200) {
        final updated = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return BrandingResult(success: true, branding: updated);
      }

      return const BrandingResult(success: false, error: 'Failed to remove logo');
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to remove logo';
      return BrandingResult(success: false, error: error.toString());
    } on FormatException catch (e) {
      return BrandingResult(success: false, error: 'Invalid response format: $e');
    }
  }

  /// Fetch trainee's parent trainer branding (trainee-facing).
  Future<BrandingResult> getMyBranding() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.myBranding);

      if (response.statusCode == 200) {
        final branding = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return BrandingResult(success: true, branding: branding);
      }

      return const BrandingResult(success: false, error: 'Failed to fetch branding');
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to fetch branding';
      return BrandingResult(success: false, error: error.toString());
    } on FormatException catch (e) {
      return BrandingResult(success: false, error: 'Invalid response format: $e');
    }
  }

  /// Fetch and apply trainer branding for the current trainee to the theme.
  ///
  /// On network or parse failure, cached branding from SharedPreferences
  /// persists silently. This is non-critical UI customization.
  ///
  /// Shared between splash_screen and login_screen to avoid duplication.
  static Future<void> syncTraineeBranding({
    required ApiClient apiClient,
    required ThemeNotifier themeNotifier,
  }) async {
    try {
      final repository = BrandingRepository(apiClient);
      final result = await repository.getMyBranding();

      if (result.success && result.branding != null) {
        final branding = result.branding!;
        if (branding.isCustomized) {
          await themeNotifier.applyTrainerBranding(
            primaryColor: branding.primaryColorValue,
            secondaryColor: branding.secondaryColorValue,
            appName: branding.appName,
            logoUrl: branding.logoUrl,
          );
        } else {
          await themeNotifier.clearTrainerBranding();
        }
      }
      // On failure, cached branding from SharedPreferences persists
    } on DioException {
      // Network error -- branding is non-critical, cached values used
    } on FormatException {
      // Parse error -- branding is non-critical, cached values used
    }
  }
}
