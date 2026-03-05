import 'package:json_annotation/json_annotation.dart';

part 'food_lookup_model.g.dart';

@JsonSerializable()
class FoodLookupModel {
  final String barcode;
  @JsonKey(name: 'product_name')
  final String productName;
  final String brand;
  @JsonKey(name: 'serving_size')
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  @JsonKey(name: 'image_url')
  final String imageUrl;
  final bool found;

  const FoodLookupModel({
    required this.barcode,
    this.productName = '',
    this.brand = '',
    this.servingSize = '100g',
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.imageUrl = '',
    this.found = false,
  });

  factory FoodLookupModel.fromJson(Map<String, dynamic> json) =>
      _$FoodLookupModelFromJson(json);

  Map<String, dynamic> toJson() => _$FoodLookupModelToJson(this);
}
