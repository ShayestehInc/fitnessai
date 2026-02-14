import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/branding_model.dart';

/// Repository for trainer branding API calls.
class BrandingRepository {
  final ApiClient _apiClient;

  BrandingRepository(this._apiClient);

  /// Fetch trainer's own branding config (trainer-facing).
  Future<Map<String, dynamic>> getTrainerBranding() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerBranding);

      if (response.statusCode == 200) {
        final branding = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'branding': branding};
      }

      return {'success': false, 'error': 'Failed to fetch branding'};
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to fetch branding';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update trainer's branding config (app_name, primary_color, secondary_color).
  Future<Map<String, dynamic>> updateTrainerBranding(BrandingModel branding) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.trainerBranding,
        data: branding.toJson(),
      );

      if (response.statusCode == 200) {
        final updated = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'branding': updated};
      }

      return {'success': false, 'error': 'Failed to save branding'};
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ??
          e.response?.data?['primary_color']?.first ??
          e.response?.data?['secondary_color']?.first ??
          'Failed to save branding';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upload trainer logo image.
  Future<Map<String, dynamic>> uploadLogo(String filePath) async {
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
        return {'success': true, 'branding': updated};
      }

      return {'success': false, 'error': 'Failed to upload logo'};
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to upload logo';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Remove trainer logo.
  Future<Map<String, dynamic>> removeLogo() async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.trainerBrandingLogo,
      );

      if (response.statusCode == 200) {
        final updated = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'branding': updated};
      }

      return {'success': false, 'error': 'Failed to remove logo'};
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to remove logo';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch trainee's parent trainer branding (trainee-facing).
  Future<Map<String, dynamic>> getMyBranding() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.myBranding);

      if (response.statusCode == 200) {
        final branding = BrandingModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'branding': branding};
      }

      return {'success': false, 'error': 'Failed to fetch branding'};
    } on DioException catch (e) {
      final error = e.response?.data?['error'] ?? 'Failed to fetch branding';
      return {'success': false, 'error': error};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
