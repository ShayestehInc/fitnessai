import 'package:dio/dio.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/food_lookup_model.dart';

class BarcodeRepository {
  final ApiClient _apiClient;

  BarcodeRepository(this._apiClient);

  /// Look up a food product by its barcode string.
  /// Returns a [FoodLookupModel] with `found == true` if the product exists,
  /// or `found == false` when the barcode is unrecognised.
  Future<FoodLookupModel> lookupBarcode(String barcode) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.barcodeLookup,
        queryParameters: {'barcode': barcode},
      );

      if (response.statusCode == 200) {
        return FoodLookupModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      return FoodLookupModel(barcode: barcode, found: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return FoodLookupModel(barcode: barcode, found: false);
      }
      throw Exception(
        e.response?.data?['error']?.toString() ??
            'Failed to look up barcode',
      );
    }
  }

  /// Send scanned food data to the confirm-and-save endpoint to persist
  /// it as a nutrition log entry.
  Future<Map<String, dynamic>> confirmAndSaveFood({
    required FoodLookupModel food,
    required double servings,
    String? date,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.confirmAndSaveLog,
        data: {
          'parsed_data': {
            'foods': [
              {
                'name': food.productName,
                'brand': food.brand,
                'calories': (food.calories * servings).round(),
                'protein': (food.protein * servings).round(),
                'carbs': (food.carbs * servings).round(),
                'fat': (food.fat * servings).round(),
                'fiber': (food.fiber * servings).round(),
                'sugar': (food.sugar * servings).round(),
                'serving_size': food.servingSize,
                'servings': servings,
                'barcode': food.barcode,
              },
            ],
          },
          'confirm': true,
          if (date != null) 'date': date,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'error': 'Failed to save food entry'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error']?.toString() ?? 'Failed to save food entry',
      };
    }
  }
}
