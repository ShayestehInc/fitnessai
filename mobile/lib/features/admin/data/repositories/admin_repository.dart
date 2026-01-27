import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/admin_models.dart';
import '../models/tier_coupon_models.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  /// Get admin dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      print('AdminRepository: Fetching dashboard stats from ${ApiConstants.adminDashboard}');
      final response = await _apiClient.dio.get(ApiConstants.adminDashboard);
      print('AdminRepository: Dashboard response status: ${response.statusCode}');
      print('AdminRepository: Dashboard response data: ${response.data}');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AdminDashboardStats.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to load dashboard'};
    } on DioException catch (e) {
      print('AdminRepository: Dashboard error: ${e.message}');
      print('AdminRepository: Dashboard error response: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? e.response?.data?['error'] ?? 'Failed to load dashboard: ${e.message}',
      };
    } catch (e) {
      print('AdminRepository: Unexpected error: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Get all trainers with subscription info
  Future<Map<String, dynamic>> getTrainers({String? search, bool? activeOnly}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null) queryParams['search'] = search;
      if (activeOnly == true) queryParams['active'] = 'true';

      final response = await _apiClient.dio.get(
        ApiConstants.adminTrainers,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200) {
        final trainers = (response.data as List)
            .map((t) => AdminTrainer.fromJson(t))
            .toList();
        return {'success': true, 'data': trainers};
      }
      return {'success': false, 'error': 'Failed to load trainers'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load trainers',
      };
    }
  }

  /// Get all subscriptions
  Future<Map<String, dynamic>> getSubscriptions({
    String? status,
    String? tier,
    bool? pastDue,
    int? upcomingDays,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (tier != null) queryParams['tier'] = tier;
      if (pastDue == true) queryParams['past_due'] = 'true';
      if (upcomingDays != null) queryParams['upcoming_days'] = upcomingDays.toString();
      if (search != null) queryParams['search'] = search;

      print('AdminRepository: Fetching subscriptions from ${ApiConstants.adminSubscriptions}');
      final response = await _apiClient.dio.get(
        ApiConstants.adminSubscriptions,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      print('AdminRepository: Subscriptions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Handle paginated response (DRF returns {count, results, next, previous})
        final data = response.data;
        List<dynamic> items;
        if (data is Map && data.containsKey('results')) {
          items = data['results'] as List;
        } else if (data is List) {
          items = data;
        } else {
          items = [];
        }

        final subscriptions = items
            .map((s) => AdminSubscriptionListItem.fromJson(s))
            .toList();
        return {'success': true, 'data': subscriptions};
      }
      return {'success': false, 'error': 'Failed to load subscriptions'};
    } on DioException catch (e) {
      print('AdminRepository: Subscriptions error: ${e.message}');
      return {
        'success': false,
        'error': e.response?.data?['detail'] ?? e.response?.data?['error'] ?? 'Failed to load subscriptions',
      };
    } catch (e) {
      print('AdminRepository: Unexpected error: $e');
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  /// Get subscription details
  Future<Map<String, dynamic>> getSubscriptionDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.adminSubscriptions}$id/');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AdminSubscription.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to load subscription details'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load subscription details',
      };
    }
  }

  /// Change subscription tier
  Future<Map<String, dynamic>> changeTier(int subscriptionId, String newTier, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminSubscriptions}$subscriptionId/change-tier/',
        data: {
          'new_tier': newTier,
          if (reason != null) 'reason': reason,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AdminSubscription.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to change tier'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to change tier',
      };
    }
  }

  /// Change subscription status
  Future<Map<String, dynamic>> changeStatus(int subscriptionId, String newStatus, {String? reason}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminSubscriptions}$subscriptionId/change-status/',
        data: {
          'new_status': newStatus,
          if (reason != null) 'reason': reason,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AdminSubscription.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to change status'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to change status',
      };
    }
  }

  /// Update admin notes
  Future<Map<String, dynamic>> updateNotes(int subscriptionId, String notes) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminSubscriptions}$subscriptionId/update-notes/',
        data: {'admin_notes': notes},
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AdminSubscription.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to update notes'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to update notes',
      };
    }
  }

  /// Record manual payment
  Future<Map<String, dynamic>> recordPayment(int subscriptionId, String amount, {String? description}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminSubscriptions}$subscriptionId/record-payment/',
        data: {
          'amount': amount,
          if (description != null) 'description': description,
        },
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AdminSubscription.fromJson(response.data),
        };
      }
      return {'success': false, 'error': 'Failed to record payment'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to record payment',
      };
    }
  }

  /// Get past due subscriptions
  Future<Map<String, dynamic>> getPastDueSubscriptions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminPastDue);
      if (response.statusCode == 200) {
        final subscriptions = (response.data as List)
            .map((s) => AdminSubscriptionListItem.fromJson(s))
            .toList();
        return {'success': true, 'data': subscriptions};
      }
      return {'success': false, 'error': 'Failed to load past due subscriptions'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load past due subscriptions',
      };
    }
  }

  /// Get upcoming payments
  Future<Map<String, dynamic>> getUpcomingPayments({int days = 7}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.adminUpcomingPayments,
        queryParameters: {'days': days},
      );
      if (response.statusCode == 200) {
        final subscriptions = (response.data as List)
            .map((s) => AdminSubscriptionListItem.fromJson(s))
            .toList();
        return {'success': true, 'data': subscriptions};
      }
      return {'success': false, 'error': 'Failed to load upcoming payments'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to load upcoming payments',
      };
    }
  }

  // ============ Subscription Tiers ============

  /// Get all subscription tiers
  Future<List<SubscriptionTierModel>> getTiers() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminTiers);
      final List<dynamic> data = response.data is Map ? response.data['results'] ?? [] : response.data;
      return data.map((json) => SubscriptionTierModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting tiers: ${e.message}');
      return [];
    }
  }

  /// Get public subscription tiers
  Future<List<SubscriptionTierModel>> getPublicTiers() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.publicTiers);
      final List<dynamic> data = response.data;
      return data.map((json) => SubscriptionTierModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting public tiers: ${e.message}');
      return [];
    }
  }

  /// Create a new tier
  Future<SubscriptionTierModel?> createTier({
    required String name,
    required String displayName,
    String? description,
    required double price,
    required int traineeLimit,
    List<String>? features,
    int? sortOrder,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminTiers,
        data: {
          'name': name.toUpperCase(),
          'display_name': displayName,
          'description': description ?? '',
          'price': price.toStringAsFixed(2),
          'trainee_limit': traineeLimit,
          'features': features ?? [],
          'sort_order': sortOrder ?? 0,
        },
      );
      return SubscriptionTierModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error creating tier: ${e.message}');
      return null;
    }
  }

  /// Update a tier
  Future<SubscriptionTierModel?> updateTier(
    int id, {
    String? displayName,
    String? description,
    double? price,
    int? traineeLimit,
    List<String>? features,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['display_name'] = displayName;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price.toStringAsFixed(2);
      if (traineeLimit != null) data['trainee_limit'] = traineeLimit;
      if (features != null) data['features'] = features;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _apiClient.dio.patch(
        '${ApiConstants.adminTiers}$id/',
        data: data,
      );
      return SubscriptionTierModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error updating tier: ${e.message}');
      return null;
    }
  }

  /// Delete a tier
  Future<bool> deleteTier(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.adminTiers}$id/');
      return true;
    } on DioException catch (e) {
      print('Error deleting tier: ${e.message}');
      return false;
    }
  }

  /// Toggle tier active status
  Future<SubscriptionTierModel?> toggleTierActive(int id) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminTiers}$id/toggle-active/',
      );
      return SubscriptionTierModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error toggling tier: ${e.message}');
      return null;
    }
  }

  /// Seed default tiers
  Future<List<SubscriptionTierModel>> seedDefaultTiers() async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminTiers}seed-defaults/',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => SubscriptionTierModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error seeding tiers: ${e.message}');
      return [];
    }
  }

  // ============ Coupons ============

  /// Get all coupons
  Future<List<CouponListItemModel>> getCoupons({
    String? status,
    String? type,
    String? appliesTo,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;
      if (appliesTo != null) params['applies_to'] = appliesTo;
      if (search != null) params['search'] = search;

      final response = await _apiClient.dio.get(
        ApiConstants.adminCoupons,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final List<dynamic> data = response.data is Map ? response.data['results'] ?? [] : response.data;
      return data.map((json) => CouponListItemModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting coupons: ${e.message}');
      return [];
    }
  }

  /// Get a single coupon
  Future<CouponModel?> getCoupon(int id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.adminCoupons}$id/');
      return CouponModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error getting coupon: ${e.message}');
      return null;
    }
  }

  /// Create a coupon
  Future<CouponModel?> createCoupon({
    required String code,
    String? description,
    required String couponType,
    required double discountValue,
    required String appliesTo,
    List<String>? applicableTiers,
    int? maxUses,
    int? maxUsesPerUser,
    DateTime? validFrom,
    DateTime? validUntil,
  }) async {
    try {
      final data = <String, dynamic>{
        'code': code.toUpperCase(),
        'description': description ?? '',
        'coupon_type': couponType,
        'discount_value': discountValue.toString(),
        'applies_to': appliesTo,
        'applicable_tiers': applicableTiers ?? [],
        'max_uses': maxUses ?? 0,
        'max_uses_per_user': maxUsesPerUser ?? 1,
      };

      if (validFrom != null) {
        data['valid_from'] = validFrom.toIso8601String();
      }
      if (validUntil != null) {
        data['valid_until'] = validUntil.toIso8601String();
      }

      final response = await _apiClient.dio.post(
        ApiConstants.adminCoupons,
        data: data,
      );
      return CouponModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error creating coupon: ${e.message}');
      return null;
    }
  }

  /// Update a coupon
  Future<CouponModel?> updateCoupon(
    int id, {
    String? description,
    double? discountValue,
    List<String>? applicableTiers,
    int? maxUses,
    int? maxUsesPerUser,
    DateTime? validUntil,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (discountValue != null) data['discount_value'] = discountValue.toString();
      if (applicableTiers != null) data['applicable_tiers'] = applicableTiers;
      if (maxUses != null) data['max_uses'] = maxUses;
      if (maxUsesPerUser != null) data['max_uses_per_user'] = maxUsesPerUser;
      if (validUntil != null) data['valid_until'] = validUntil.toIso8601String();
      if (status != null) data['status'] = status;

      final response = await _apiClient.dio.patch(
        '${ApiConstants.adminCoupons}$id/',
        data: data,
      );
      return CouponModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error updating coupon: ${e.message}');
      return null;
    }
  }

  /// Revoke a coupon
  Future<CouponModel?> revokeCoupon(int id) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminCoupons}$id/revoke/',
      );
      return CouponModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error revoking coupon: ${e.message}');
      return null;
    }
  }

  /// Reactivate a coupon
  Future<CouponModel?> reactivateCoupon(int id) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.adminCoupons}$id/reactivate/',
      );
      return CouponModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error reactivating coupon: ${e.message}');
      return null;
    }
  }

  /// Delete a coupon
  Future<bool> deleteCoupon(int id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.adminCoupons}$id/');
      return true;
    } on DioException catch (e) {
      print('Error deleting coupon: ${e.message}');
      return false;
    }
  }

  /// Get coupon usages
  Future<List<CouponUsageModel>> getCouponUsages(int couponId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.adminCoupons}$couponId/usages/',
      );
      final List<dynamic> data = response.data;
      return data.map((json) => CouponUsageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting coupon usages: ${e.message}');
      return [];
    }
  }

  /// Validate a coupon code
  Future<ValidateCouponResponse> validateCoupon(String code) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.validateCoupon,
        data: {'code': code},
      );
      return ValidateCouponResponse.fromJson(response.data);
    } on DioException catch (e) {
      return ValidateCouponResponse(
        valid: false,
        error: e.response?.data?['error'] ?? 'Failed to validate coupon',
      );
    }
  }

  // ============ Admin Impersonation ============

  /// Impersonate a trainer (login as trainer)
  Future<Map<String, dynamic>> impersonateTrainer(int trainerId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminImpersonateTrainer(trainerId),
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to impersonate trainer',
      };
    }
  }

  /// End impersonation session
  Future<Map<String, dynamic>> endImpersonation() async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminEndImpersonation,
      );
      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? 'Failed to end impersonation',
      };
    }
  }
}
