import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/video_message_model.dart';

/// Repository for dual capture video messages (v6.5 §22).
class VideoMessageRepository {
  final ApiClient _apiClient;

  VideoMessageRepository(this._apiClient);

  /// Start a new recording session.
  Future<Map<String, dynamic>> startRecording({
    required String captureMode,
    Map<String, dynamic>? screenRouteContext,
    int? traineeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'capture_mode': captureMode,
      };
      if (screenRouteContext != null) {
        body['screen_route_context'] = screenRouteContext;
      }
      if (traineeId != null) body['trainee_id'] = traineeId;

      final response = await _apiClient.dio.post(
        ApiConstants.videoMessageStart,
        data: body,
      );
      if (response.statusCode == 201) {
        return {
          'success': true,
          'result': VideoMessageStartResult.fromJson(
            response.data as Map<String, dynamic>,
          ),
        };
      }
      return {'success': false, 'error': 'Failed to start recording'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Start recording failed',
      };
    }
  }

  /// Upload a recorded video file to the backend.
  Future<Map<String, dynamic>> uploadVideoFile({
    required String assetId,
    required String filePath,
    required double durationSeconds,
    String orientation = 'portrait',
  }) async {
    try {
      final formData = FormData.fromMap({
        'video_file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
        'duration_seconds': durationSeconds,
        'orientation': orientation,
      });

      final response = await _apiClient.dio.post(
        ApiConstants.videoMessageUpload(assetId),
        data: formData,
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Video upload failed',
      };
    }
  }

  /// Complete upload of a recording (when URI is already known).
  Future<Map<String, dynamic>> completeUpload({
    required String assetId,
    required String rawUploadUri,
    required double durationSeconds,
    String orientation = 'portrait',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.videoMessageComplete(assetId),
        data: {
          'raw_upload_uri': rawUploadUri,
          'duration_seconds': durationSeconds,
          'orientation': orientation,
        },
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Upload completion failed',
      };
    }
  }

  /// Get video message details.
  Future<Map<String, dynamic>> getDetail(String assetId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.videoMessageDetail(assetId),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'asset': VideoMessageModel.fromJson(
            response.data as Map<String, dynamic>,
          ),
        };
      }
      return {'success': false, 'error': 'Failed to get details'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Get details failed',
      };
    }
  }

  /// Delete a video message asset.
  Future<Map<String, dynamic>> deleteAsset(String assetId) async {
    try {
      await _apiClient.dio.delete(
        ApiConstants.videoMessageDetail(assetId),
      );
      return {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? 'Delete failed',
      };
    }
  }
}
