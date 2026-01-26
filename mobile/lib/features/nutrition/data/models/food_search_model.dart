/// Model for food search results from MyFitnessPal API
class FoodSearchResult {
  final String id;
  final String name;
  final String brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;
  final String servingUnit;

  const FoodSearchResult({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    // Parse serving info
    final servingDescription = json['serving_description'] as String? ?? '';
    final servingSizes = json['serving_sizes'] as Map<String, dynamic>? ?? {};
    final serving = servingSizes['serving'] as Map<String, dynamic>? ?? {};

    // Try to get nutrition from nested serving or directly from item
    final nutritionServing = serving.isNotEmpty ? serving : json;

    return FoodSearchResult(
      id: (json['food_id'] ?? json['id'] ?? '').toString(),
      name: json['food_name'] as String? ??
            json['name'] as String? ??
            json['item'] as String? ??
            'Unknown Food',
      brand: json['brand_name'] as String? ??
             json['brand'] as String? ??
             '',
      calories: _parseDouble(nutritionServing['calories'] ?? json['nf_calories']),
      protein: _parseDouble(nutritionServing['protein'] ?? json['nf_protein']),
      carbs: _parseDouble(nutritionServing['carbohydrate'] ?? nutritionServing['carbs'] ?? json['nf_total_carbohydrate']),
      fat: _parseDouble(nutritionServing['fat'] ?? json['nf_total_fat']),
      servingSize: (serving['metric_serving_amount'] ?? serving['serving_size'] ?? '1').toString(),
      servingUnit: serving['metric_serving_unit'] as String? ??
                   serving['serving_unit'] as String? ??
                   servingDescription,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get displayServingSize {
    if (servingSize.isEmpty || servingUnit.isEmpty) {
      return '1 serving';
    }
    return '$servingSize $servingUnit';
  }

  String get displayName {
    if (brand.isEmpty) return name;
    return '$name ($brand)';
  }

  @override
  String toString() {
    return 'FoodSearchResult(name: $name, calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }
}

/// Wrapper for search response
class FoodSearchResponse {
  final List<FoodSearchResult> results;
  final int totalCount;
  final String? error;

  const FoodSearchResponse({
    required this.results,
    this.totalCount = 0,
    this.error,
  });

  factory FoodSearchResponse.success(List<FoodSearchResult> results) {
    return FoodSearchResponse(
      results: results,
      totalCount: results.length,
    );
  }

  factory FoodSearchResponse.error(String message) {
    return FoodSearchResponse(
      results: [],
      error: message,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => results.isEmpty;
}
