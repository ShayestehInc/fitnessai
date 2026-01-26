import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_coupon_models.freezed.dart';
part 'tier_coupon_models.g.dart';

/// Subscription tier model for admin management
@freezed
class SubscriptionTierModel with _$SubscriptionTierModel {
  const SubscriptionTierModel._();

  const factory SubscriptionTierModel({
    required int id,
    required String name,
    @JsonKey(name: 'display_name') required String displayName,
    @Default('') String description,
    required String price,
    @JsonKey(name: 'trainee_limit') @Default(0) int traineeLimit,
    @JsonKey(name: 'trainee_limit_display') String? traineeLimitDisplay,
    @Default([]) List<String> features,
    @JsonKey(name: 'stripe_price_id') String? stripePriceId,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _SubscriptionTierModel;

  factory SubscriptionTierModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionTierModelFromJson(json);

  double get priceValue => double.tryParse(price) ?? 0.0;
  String get formattedPrice => priceValue == 0 ? 'Free' : '\$${priceValue.toStringAsFixed(2)}/mo';
  bool get isUnlimited => traineeLimit == 0;
}

/// Coupon model
@freezed
class CouponModel with _$CouponModel {
  const CouponModel._();

  const factory CouponModel({
    required int id,
    required String code,
    @Default('') String description,
    @JsonKey(name: 'coupon_type') required String couponType,
    @JsonKey(name: 'discount_value') required String discountValue,
    @JsonKey(name: 'applies_to') required String appliesTo,
    required String status,
    @JsonKey(name: 'created_by_trainer') int? createdByTrainer,
    @JsonKey(name: 'created_by_trainer_email') String? createdByTrainerEmail,
    @JsonKey(name: 'created_by_admin') int? createdByAdmin,
    @JsonKey(name: 'created_by_admin_email') String? createdByAdminEmail,
    @JsonKey(name: 'applicable_tiers') @Default([]) List<String> applicableTiers,
    @JsonKey(name: 'max_uses') @Default(0) int maxUses,
    @JsonKey(name: 'max_uses_per_user') @Default(1) int maxUsesPerUser,
    @JsonKey(name: 'current_uses') @Default(0) int currentUses,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'valid_from') String? validFrom,
    @JsonKey(name: 'valid_until') String? validUntil,
    @JsonKey(name: 'stripe_coupon_id') String? stripeCouponId,
    @JsonKey(name: 'is_valid') @Default(false) bool isValid,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _CouponModel;

  factory CouponModel.fromJson(Map<String, dynamic> json) =>
      _$CouponModelFromJson(json);

  double get discountValueNum => double.tryParse(discountValue) ?? 0.0;

  String get discountDisplay {
    switch (couponType) {
      case 'percent':
        return '${discountValueNum.toStringAsFixed(0)}% off';
      case 'fixed':
        return '\$${discountValueNum.toStringAsFixed(2)} off';
      case 'free_trial':
        return '${discountValueNum.toStringAsFixed(0)} days free';
      default:
        return discountValue;
    }
  }

  String get typeDisplay {
    switch (couponType) {
      case 'percent':
        return 'Percentage';
      case 'fixed':
        return 'Fixed Amount';
      case 'free_trial':
        return 'Free Trial';
      default:
        return couponType;
    }
  }

  String get appliesToDisplay {
    switch (appliesTo) {
      case 'trainer':
        return 'Trainer Subscriptions';
      case 'trainee':
        return 'Trainee Coaching';
      case 'both':
        return 'All';
      default:
        return appliesTo;
    }
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isRevoked => status == 'revoked';
  bool get isExhausted => status == 'exhausted';

  String get usageDisplay {
    if (maxUses == 0) {
      return '$currentUses used (unlimited)';
    }
    return '$currentUses / $maxUses used';
  }
}

/// Coupon list item (lightweight)
@freezed
class CouponListItemModel with _$CouponListItemModel {
  const CouponListItemModel._();

  const factory CouponListItemModel({
    required int id,
    required String code,
    @Default('') String description,
    @JsonKey(name: 'coupon_type') required String couponType,
    @JsonKey(name: 'discount_value') required String discountValue,
    @JsonKey(name: 'applies_to') required String appliesTo,
    required String status,
    @JsonKey(name: 'max_uses') @Default(0) int maxUses,
    @JsonKey(name: 'current_uses') @Default(0) int currentUses,
    @JsonKey(name: 'valid_from') String? validFrom,
    @JsonKey(name: 'valid_until') String? validUntil,
    @JsonKey(name: 'is_valid') @Default(false) bool isValid,
    @JsonKey(name: 'created_by_name') String? createdByName,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _CouponListItemModel;

  factory CouponListItemModel.fromJson(Map<String, dynamic> json) =>
      _$CouponListItemModelFromJson(json);

  double get discountValueNum => double.tryParse(discountValue) ?? 0.0;

  String get discountDisplay {
    switch (couponType) {
      case 'percent':
        return '${discountValueNum.toStringAsFixed(0)}%';
      case 'fixed':
        return '\$${discountValueNum.toStringAsFixed(2)}';
      case 'free_trial':
        return '${discountValueNum.toStringAsFixed(0)} days';
      default:
        return discountValue;
    }
  }

  bool get isActive => status == 'active';
}

/// Coupon usage record
@freezed
class CouponUsageModel with _$CouponUsageModel {
  const factory CouponUsageModel({
    required int id,
    @JsonKey(name: 'user_email') String? userEmail,
    @JsonKey(name: 'user_name') String? userName,
    @JsonKey(name: 'discount_amount') @Default('0.00') String discountAmount,
    @JsonKey(name: 'used_at') String? usedAt,
  }) = _CouponUsageModel;

  factory CouponUsageModel.fromJson(Map<String, dynamic> json) =>
      _$CouponUsageModelFromJson(json);
}

/// Validate coupon response
@freezed
class ValidateCouponResponse with _$ValidateCouponResponse {
  const factory ValidateCouponResponse({
    @Default(false) bool valid,
    CouponModel? coupon,
    String? message,
    String? error,
  }) = _ValidateCouponResponse;

  factory ValidateCouponResponse.fromJson(Map<String, dynamic> json) =>
      _$ValidateCouponResponseFromJson(json);
}
