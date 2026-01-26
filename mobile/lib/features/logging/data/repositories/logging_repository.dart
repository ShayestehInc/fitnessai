import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/parsed_log_model.dart';

class LoggingRepository {
  final ApiClient _apiClient;

  LoggingRepository(this._apiClient);

  /// Parse natural language input (Step 1: Verification)
  Future<Map<String, dynamic>> parseNaturalLanguage(String userInput, {String? date}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.parseNaturalLanguage,
        data: {
          'user_input': userInput,
          if (date != null) 'date': date,
        },
      );

      if (response.statusCode == 200) {
        final parsedData = ParsedLogModel.fromJson(response.data);
        return {
          'success': true,
          'data': parsedData,
        };
      }

      return {'success': false, 'error': 'Failed to parse input'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to parse input',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Confirm and save parsed log (Step 2: Save to DB)
  Future<Map<String, dynamic>> confirmAndSave(
    Map<String, dynamic> parsedData, {
    String? date,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.confirmAndSaveLog,
        data: {
          'parsed_data': parsedData,
          'confirm': true,
          if (date != null) 'date': date,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
        };
      }

      return {'success': false, 'error': 'Failed to save log'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? 'Failed to save log',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
