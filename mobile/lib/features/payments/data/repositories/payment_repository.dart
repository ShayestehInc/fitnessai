import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/payment_models.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  // ============ Stripe Connect (Trainer) ============

  /// Start Stripe Connect onboarding for trainer
  Future<StripeConnectResponse> startStripeOnboarding() async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.stripeConnectOnboard);
      return StripeConnectResponse.fromJson(response.data);
    } on DioException catch (e) {
      return StripeConnectResponse(
        error: e.response?.data?['error'] ?? 'Failed to start Stripe onboarding',
      );
    }
  }

  /// Get Stripe Connect account status for trainer
  Future<StripeConnectStatusResponse> getStripeConnectStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.stripeConnectStatus);
      return StripeConnectStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      return StripeConnectStatusResponse(
        connected: false,
        status: 'error',
        message: e.response?.data?['error'] ?? 'Failed to get status',
      );
    }
  }

  /// Get Stripe Express dashboard URL for trainer
  Future<StripeConnectResponse> getStripeDashboardUrl() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.stripeConnectDashboard);
      return StripeConnectResponse.fromJson(response.data);
    } on DioException catch (e) {
      return StripeConnectResponse(
        error: e.response?.data?['error'] ?? 'Failed to get dashboard URL',
      );
    }
  }

  // ============ Trainer Pricing ============

  /// Get trainer's pricing configuration
  Future<TrainerPricingModel?> getTrainerPricing() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerPricing);
      return TrainerPricingModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error getting trainer pricing: ${e.message}');
      return null;
    }
  }

  /// Update trainer's pricing configuration
  Future<TrainerPricingModel?> updateTrainerPricing({
    double? monthlySubscriptionPrice,
    bool? monthlySubscriptionEnabled,
    double? oneTimeConsultationPrice,
    bool? oneTimeConsultationEnabled,
    String? currency,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (monthlySubscriptionPrice != null) {
        data['monthly_subscription_price'] = monthlySubscriptionPrice.toStringAsFixed(2);
      }
      if (monthlySubscriptionEnabled != null) {
        data['monthly_subscription_enabled'] = monthlySubscriptionEnabled;
      }
      if (oneTimeConsultationPrice != null) {
        data['one_time_consultation_price'] = oneTimeConsultationPrice.toStringAsFixed(2);
      }
      if (oneTimeConsultationEnabled != null) {
        data['one_time_consultation_enabled'] = oneTimeConsultationEnabled;
      }
      if (currency != null) {
        data['currency'] = currency;
      }

      final response = await _apiClient.dio.post(ApiConstants.trainerPricing, data: data);
      return TrainerPricingModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error updating trainer pricing: ${e.message}');
      return null;
    }
  }

  /// Get public pricing info for a trainer (for trainees)
  Future<TrainerPublicPricingModel?> getTrainerPublicPricing(int trainerId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.trainerPublicPricing(trainerId),
      );
      return TrainerPublicPricingModel.fromJson(response.data);
    } on DioException catch (e) {
      print('Error getting trainer public pricing: ${e.message}');
      return null;
    }
  }

  // ============ Trainee Checkout ============

  /// Create subscription checkout session
  Future<CheckoutSessionResponse> createSubscriptionCheckout({
    required int trainerId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'trainer_id': trainerId,
        'payment_type': 'subscription',
      };
      if (successUrl != null) data['success_url'] = successUrl;
      if (cancelUrl != null) data['cancel_url'] = cancelUrl;

      final response = await _apiClient.dio.post(
        ApiConstants.checkoutSubscription,
        data: data,
      );
      return CheckoutSessionResponse.fromJson(response.data);
    } on DioException catch (e) {
      return CheckoutSessionResponse(
        error: e.response?.data?['error'] ?? 'Failed to create checkout session',
      );
    }
  }

  /// Create one-time payment checkout session
  Future<CheckoutSessionResponse> createOneTimeCheckout({
    required int trainerId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'trainer_id': trainerId,
        'payment_type': 'one_time',
      };
      if (successUrl != null) data['success_url'] = successUrl;
      if (cancelUrl != null) data['cancel_url'] = cancelUrl;

      final response = await _apiClient.dio.post(
        ApiConstants.checkoutOneTime,
        data: data,
      );
      return CheckoutSessionResponse.fromJson(response.data);
    } on DioException catch (e) {
      return CheckoutSessionResponse(
        error: e.response?.data?['error'] ?? 'Failed to create checkout session',
      );
    }
  }

  // ============ Trainee Subscriptions ============

  /// Get trainee's subscriptions
  Future<List<TraineeSubscriptionModel>> getTraineeSubscriptions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.traineeSubscription);
      final List<dynamic> data = response.data;
      return data.map((json) => TraineeSubscriptionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting trainee subscriptions: ${e.message}');
      return [];
    }
  }

  /// Cancel a subscription
  Future<bool> cancelSubscription(int subscriptionId) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConstants.traineeSubscription}$subscriptionId/',
      );
      return true;
    } on DioException catch (e) {
      print('Error canceling subscription: ${e.message}');
      return false;
    }
  }

  /// Get trainee's payment history
  Future<List<TraineePaymentModel>> getTraineePayments() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.traineePayments);
      final List<dynamic> data = response.data;
      return data.map((json) => TraineePaymentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting trainee payments: ${e.message}');
      return [];
    }
  }

  // ============ Trainer Views ============

  /// Get trainer's received payments
  Future<List<TraineePaymentModel>> getTrainerPayments() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerPayments);
      final List<dynamic> data = response.data;
      return data.map((json) => TraineePaymentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting trainer payments: ${e.message}');
      return [];
    }
  }

  /// Get trainer's active subscribers
  Future<List<TraineeSubscriptionModel>> getTrainerSubscribers() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.trainerSubscribers);
      final List<dynamic> data = response.data;
      return data.map((json) => TraineeSubscriptionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error getting trainer subscribers: ${e.message}');
      return [];
    }
  }
}
