import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/progress_photo_model.dart';

class ProgressPhotoRepository {
  final ApiClient _apiClient;

  ProgressPhotoRepository(this._apiClient);

  /// Fetch progress photos with optional category and date range filters.
  Future<Map<String, dynamic>> fetchPhotos({
    String? category,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.progressPhotos,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data as List<dynamic>
            : (response.data is Map && response.data.containsKey('results'))
                ? response.data['results'] as List<dynamic>
                : [];
        final photos = data
            .map(
              (json) =>
                  ProgressPhotoModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return {'success': true, 'photos': photos};
      }

      return {'success': false, 'error': 'Failed to fetch progress photos'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to fetch progress photos',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upload a new progress photo with optional measurements and notes.
  Future<Map<String, dynamic>> uploadPhoto({
    required String filePath,
    required String category,
    required String date,
    Map<String, double> measurements = const {},
    String notes = '',
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'photo': await MultipartFile.fromFile(filePath),
        'category': category,
        'date': date,
        'notes': notes,
      };

      // Flatten measurements into top-level form fields so the API can
      // reconstruct the JSON object server-side, or send as JSON string.
      if (measurements.isNotEmpty) {
        formDataMap['measurements'] =
            measurements.map((k, v) => MapEntry(k, v.toString())).toString();
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _apiClient.dio.post(
        ApiConstants.progressPhotos,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final photo = ProgressPhotoModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'photo': photo};
      }

      return {'success': false, 'error': 'Failed to upload photo'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to upload photo',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Compare two progress photos by their IDs.
  Future<Map<String, dynamic>> comparePhotos({
    required int photo1Id,
    required int photo2Id,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.progressPhotosCompare,
        queryParameters: {
          'photo1': photo1Id,
          'photo2': photo2Id,
        },
      );

      if (response.statusCode == 200) {
        final result = PhotoComparisonResult.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'comparison': result};
      }

      return {'success': false, 'error': 'Failed to compare photos'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to compare photos',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete a progress photo by ID.
  Future<Map<String, dynamic>> deletePhoto(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.progressPhotos}$id/',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }

      return {'success': false, 'error': 'Failed to delete photo'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Photo not found'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to delete photo',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
