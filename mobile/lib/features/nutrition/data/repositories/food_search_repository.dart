import 'package:dio/dio.dart';
import '../models/food_search_model.dart';

class FoodSearchRepository {
  static const String _rapidApiKey = '1fb7331d98msh718d5660408a97ap1f4f92jsnaaeac6cf4df5';
  static const String _rapidApiHost = 'myfitnesspal2.p.rapidapi.com';
  static const String _baseUrl = 'https://myfitnesspal2.p.rapidapi.com';

  final Dio _dio;

  FoodSearchRepository() : _dio = Dio() {
    _dio.options.headers = {
      'x-rapidapi-key': _rapidApiKey,
      'x-rapidapi-host': _rapidApiHost,
    };
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Search for foods by query
  Future<FoodSearchResponse> searchFood(String query) async {
    if (query.isEmpty) {
      return FoodSearchResponse.success([]);
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/searchFood',
        queryParameters: {
          'query': query,
          'page': '1',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle different response structures
        List<dynamic> items = [];

        if (data is Map<String, dynamic>) {
          // Try different possible response structures
          if (data.containsKey('items')) {
            items = data['items'] as List<dynamic>? ?? [];
          } else if (data.containsKey('foods')) {
            items = data['foods'] as List<dynamic>? ?? [];
          } else if (data.containsKey('results')) {
            items = data['results'] as List<dynamic>? ?? [];
          } else if (data.containsKey('food')) {
            final food = data['food'];
            if (food is List) {
              items = food;
            } else if (food is Map) {
              items = [food];
            }
          } else if (data.containsKey('data')) {
            final nestedData = data['data'];
            if (nestedData is List) {
              items = nestedData;
            } else if (nestedData is Map && nestedData.containsKey('foods')) {
              items = nestedData['foods'] as List<dynamic>? ?? [];
            }
          }
        } else if (data is List) {
          items = data;
        }

        final results = items
            .map((item) {
              try {
                return FoodSearchResult.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing food item: $e');
                return null;
              }
            })
            .whereType<FoodSearchResult>()
            .toList();

        return FoodSearchResponse.success(results);
      }

      return FoodSearchResponse.error('Search failed: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return FoodSearchResponse.error('Request timed out. Please try again.');
      }

      final errorMessage = e.response?.data?['message'] ??
                           e.response?.data?['error'] ??
                           e.message ??
                           'Search failed';
      return FoodSearchResponse.error(errorMessage.toString());
    } catch (e) {
      return FoodSearchResponse.error('Unexpected error: $e');
    }
  }

  /// Get details for a specific food by ID
  Future<FoodSearchResult?> getFoodDetails(String foodId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/getFood',
        queryParameters: {
          'food_id': foodId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          // Try different response structures
          Map<String, dynamic>? foodData;

          if (data.containsKey('food')) {
            foodData = data['food'] as Map<String, dynamic>?;
          } else if (data.containsKey('item')) {
            foodData = data['item'] as Map<String, dynamic>?;
          } else {
            foodData = data;
          }

          if (foodData != null) {
            return FoodSearchResult.fromJson(foodData);
          }
        }
      }

      return null;
    } catch (e) {
      print('Error getting food details: $e');
      return null;
    }
  }
}
