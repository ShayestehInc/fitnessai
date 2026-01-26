import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/admin_models.dart';

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
}
