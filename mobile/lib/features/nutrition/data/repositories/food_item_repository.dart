import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/nutrition_models.dart';

class FoodItemRepository {
  final ApiClient _apiClient;

  const FoodItemRepository(this._apiClient);

  /// Search food items by query (minimum 2 characters).
  Future<Map<String, dynamic>> search(String query) async {
    if (query.length < 2) {
      return {'success': true, 'items': <FoodItemModel>[]};
    }

    try {
      final response = await _apiClient.dio.get(
        ApiConstants.foodItems,
        queryParameters: {'search': query},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> results =
            data is Map ? (data['results'] as List<dynamic>? ?? []) : [];
        final items =
            results.map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>)).toList();
        return {'success': true, 'items': items};
      }
      return {'success': false, 'error': 'Search failed'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Search failed',
      };
    }
  }

  /// Look up a food item by barcode.
  Future<Map<String, dynamic>> getByBarcode(String barcode) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.foodItemBarcode(barcode),
      );

      if (response.statusCode == 200) {
        final item = FoodItemModel.fromJson(response.data as Map<String, dynamic>);
        return {'success': true, 'item': item};
      }
      return {'success': false, 'error': 'Food not found'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'No food item found for this barcode.'};
      }
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Barcode lookup failed',
      };
    }
  }

  /// Get recently used food items for current trainee.
  Future<Map<String, dynamic>> getRecent() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.recentFoodItems);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>? ?? [];
        final items =
            data.map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>)).toList();
        return {'success': true, 'items': items};
      }
      return {'success': false, 'error': 'Failed to load recent foods'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to load recent foods',
      };
    }
  }

  /// Create a custom food item (trainer only).
  Future<Map<String, dynamic>> create({
    required String name,
    String brand = '',
    double servingSize = 1.0,
    String servingUnit = 'g',
    int calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    String barcode = '',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.foodItems,
        data: {
          'name': name,
          'brand': brand,
          'serving_size': servingSize,
          'serving_unit': servingUnit,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
          'barcode': barcode,
        },
      );

      if (response.statusCode == 201) {
        final item = FoodItemModel.fromJson(response.data as Map<String, dynamic>);
        return {'success': true, 'item': item};
      }
      return {'success': false, 'error': 'Failed to create food item'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error']?.toString() ?? 'Failed to create food item',
      };
    }
  }
}
