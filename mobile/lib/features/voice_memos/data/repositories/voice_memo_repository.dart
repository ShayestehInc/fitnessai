import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/voice_memo_model.dart';

class VoiceMemoRepository {
  final ApiClient _apiClient;

  VoiceMemoRepository(this._apiClient);

  /// Upload an audio file as a voice memo via multipart POST.
  Future<Map<String, dynamic>> uploadMemo({
    required String filePath,
    int? dailyLogId,
    int? exerciseId,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'audio_file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      };

      if (dailyLogId != null) {
        formDataMap['daily_log'] = dailyLogId;
      }
      if (exerciseId != null) {
        formDataMap['exercise_id'] = exerciseId;
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _apiClient.dio.post(
        ApiConstants.voiceMemoUpload,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final memo = VoiceMemoModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'memo': memo};
      }

      return {'success': false, 'error': 'Failed to upload voice memo'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to upload voice memo',
      };
    }
  }

  /// List voice memos (paginated).
  Future<Map<String, dynamic>> listMemos({int page = 1}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.voiceMemoList,
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results = data is List
            ? data
            : (data is Map && data.containsKey('results'))
                ? data['results'] as List<dynamic>
                : [];

        final memos = results
            .map((json) =>
                VoiceMemoModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final hasNext = data is Map && data['next'] != null;

        return {'success': true, 'memos': memos, 'has_next': hasNext};
      }

      return {'success': false, 'error': 'Failed to fetch voice memos'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to fetch voice memos',
      };
    }
  }

  /// Get detail of a specific voice memo.
  Future<Map<String, dynamic>> getMemoDetail(int id) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.voiceMemoDetail(id.toString()),
      );

      if (response.statusCode == 200) {
        final memo = VoiceMemoModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return {'success': true, 'memo': memo};
      }

      return {'success': false, 'error': 'Failed to fetch memo detail'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Voice memo not found'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to fetch memo detail',
      };
    }
  }

  /// Delete a voice memo.
  Future<Map<String, dynamic>> deleteMemo(int id) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.voiceMemoDetail(id.toString()),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }

      return {'success': false, 'error': 'Failed to delete voice memo'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Voice memo not found'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to delete voice memo',
      };
    }
  }
}
