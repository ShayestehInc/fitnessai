import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/video_analysis_model.dart';

class VideoAnalysisRepository {
  final ApiClient _apiClient;

  VideoAnalysisRepository(this._apiClient);

  /// Fetch paginated list of video analyses.
  Future<Map<String, dynamic>> listAnalyses({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.videoAnalysisList,
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is List
            ? data
            : (data is Map && data.containsKey('results'))
                ? data['results'] as List<dynamic>
                : [];

        final analyses = results
            .map((json) =>
                VideoAnalysisModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final hasNext = data is Map && data['next'] != null;

        return {
          'success': true,
          'analyses': analyses,
          'has_next': hasNext,
        };
      }

      return {'success': false, 'error': 'Failed to fetch video analyses'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to fetch video analyses',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Fetch detail of a specific video analysis.
  Future<Map<String, dynamic>> getDetail(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.videoAnalysisDetail('$id'),
      );

      if (response.statusCode == 200) {
        final analysis = VideoAnalysisModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'analysis': analysis};
      }

      return {'success': false, 'error': 'Failed to fetch analysis detail'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Video analysis not found'};
      }
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to fetch analysis detail',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Upload a video file for analysis with an optional exercise ID.
  Future<Map<String, dynamic>> uploadVideo({
    required String filePath,
    int? exerciseId,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'video_file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      };

      if (exerciseId != null) {
        formDataMap['exercise_id'] = exerciseId;
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _apiClient.dio.post(
        ApiConstants.videoAnalysisUpload,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final analysis = VideoAnalysisModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'analysis': analysis};
      }

      return {'success': false, 'error': 'Failed to upload video'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to upload video',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Confirm the AI suggestions for a completed analysis.
  Future<Map<String, dynamic>> confirmSuggestions(int id) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.videoAnalysisConfirm('$id'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final analysis = VideoAnalysisModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'analysis': analysis};
      }

      return {'success': false, 'error': 'Failed to confirm suggestions'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? 'Failed to confirm suggestions',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
