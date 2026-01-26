import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/payment_models.dart';
import '../../data/repositories/payment_repository.dart';

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// Repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentRepository(apiClient);
});

// ============ Stripe Connect State (Trainer) ============

class StripeConnectState {
  final bool isLoading;
  final StripeConnectStatusResponse? status;
  final String? error;
  final String? onboardingUrl;

  StripeConnectState({
    this.isLoading = false,
    this.status,
    this.error,
    this.onboardingUrl,
  });

  StripeConnectState copyWith({
    bool? isLoading,
    StripeConnectStatusResponse? status,
    String? error,
    String? onboardingUrl,
  }) {
    return StripeConnectState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      error: error,
      onboardingUrl: onboardingUrl,
    );
  }

  bool get isConnected => status?.connected ?? false;
  bool get isReadyForPayments => status?.isReadyForPayments ?? false;
}

class StripeConnectNotifier extends StateNotifier<StripeConnectState> {
  final PaymentRepository _repository;

  StripeConnectNotifier(this._repository) : super(StripeConnectState());

  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    final status = await _repository.getStripeConnectStatus();
    state = state.copyWith(isLoading: false, status: status);
  }

  Future<bool> startOnboarding() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await _repository.startStripeOnboarding();

    if (response.error != null) {
      state = state.copyWith(isLoading: false, error: response.error);
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      onboardingUrl: response.onboardingUrl,
    );

    // Open onboarding URL
    if (response.onboardingUrl != null) {
      final uri = Uri.parse(response.onboardingUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    return false;
  }

  Future<void> openDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await _repository.getStripeDashboardUrl();

    if (response.dashboardUrl != null) {
      final uri = Uri.parse(response.dashboardUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to open dashboard');
    }

    state = state.copyWith(isLoading: false);
  }
}

final stripeConnectProvider =
    StateNotifierProvider<StripeConnectNotifier, StripeConnectState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return StripeConnectNotifier(repository);
});

// ============ Trainer Pricing State ============

class TrainerPricingState {
  final bool isLoading;
  final bool isSaving;
  final TrainerPricingModel? pricing;
  final String? error;
  final String? successMessage;

  TrainerPricingState({
    this.isLoading = false,
    this.isSaving = false,
    this.pricing,
    this.error,
    this.successMessage,
  });

  TrainerPricingState copyWith({
    bool? isLoading,
    bool? isSaving,
    TrainerPricingModel? pricing,
    String? error,
    String? successMessage,
  }) {
    return TrainerPricingState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      pricing: pricing ?? this.pricing,
      error: error,
      successMessage: successMessage,
    );
  }
}

class TrainerPricingNotifier extends StateNotifier<TrainerPricingState> {
  final PaymentRepository _repository;

  TrainerPricingNotifier(this._repository) : super(TrainerPricingState());

  Future<void> loadPricing() async {
    state = state.copyWith(isLoading: true, error: null);
    final pricing = await _repository.getTrainerPricing();
    state = state.copyWith(isLoading: false, pricing: pricing);
  }

  Future<bool> updatePricing({
    double? monthlySubscriptionPrice,
    bool? monthlySubscriptionEnabled,
    double? oneTimeConsultationPrice,
    bool? oneTimeConsultationEnabled,
  }) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);

    final pricing = await _repository.updateTrainerPricing(
      monthlySubscriptionPrice: monthlySubscriptionPrice,
      monthlySubscriptionEnabled: monthlySubscriptionEnabled,
      oneTimeConsultationPrice: oneTimeConsultationPrice,
      oneTimeConsultationEnabled: oneTimeConsultationEnabled,
    );

    if (pricing != null) {
      state = state.copyWith(
        isSaving: false,
        pricing: pricing,
        successMessage: 'Pricing updated successfully',
      );
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update pricing',
      );
      return false;
    }
  }
}

final trainerPricingProvider =
    StateNotifierProvider<TrainerPricingNotifier, TrainerPricingState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return TrainerPricingNotifier(repository);
});

// ============ Trainee Subscription State ============

class TraineeSubscriptionState {
  final bool isLoading;
  final List<TraineeSubscriptionModel> subscriptions;
  final List<TraineePaymentModel> payments;
  final String? error;

  TraineeSubscriptionState({
    this.isLoading = false,
    this.subscriptions = const [],
    this.payments = const [],
    this.error,
  });

  TraineeSubscriptionState copyWith({
    bool? isLoading,
    List<TraineeSubscriptionModel>? subscriptions,
    List<TraineePaymentModel>? payments,
    String? error,
  }) {
    return TraineeSubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      subscriptions: subscriptions ?? this.subscriptions,
      payments: payments ?? this.payments,
      error: error,
    );
  }

  List<TraineeSubscriptionModel> get activeSubscriptions =>
      subscriptions.where((s) => s.isActiveStatus).toList();
}

class TraineeSubscriptionNotifier extends StateNotifier<TraineeSubscriptionState> {
  final PaymentRepository _repository;

  TraineeSubscriptionNotifier(this._repository) : super(TraineeSubscriptionState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    final subscriptions = await _repository.getTraineeSubscriptions();
    final payments = await _repository.getTraineePayments();

    state = state.copyWith(
      isLoading: false,
      subscriptions: subscriptions,
      payments: payments,
    );
  }

  Future<bool> cancelSubscription(int subscriptionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final success = await _repository.cancelSubscription(subscriptionId);

    if (success) {
      // Reload data
      await loadData();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel subscription',
      );
      return false;
    }
  }
}

final traineeSubscriptionProvider =
    StateNotifierProvider<TraineeSubscriptionNotifier, TraineeSubscriptionState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return TraineeSubscriptionNotifier(repository);
});

// ============ Checkout State ============

class CheckoutState {
  final bool isLoading;
  final String? error;
  final String? checkoutUrl;

  CheckoutState({
    this.isLoading = false,
    this.error,
    this.checkoutUrl,
  });

  CheckoutState copyWith({
    bool? isLoading,
    String? error,
    String? checkoutUrl,
  }) {
    return CheckoutState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      checkoutUrl: checkoutUrl,
    );
  }
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final PaymentRepository _repository;

  CheckoutNotifier(this._repository) : super(CheckoutState());

  Future<bool> startSubscriptionCheckout(int trainerId) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.createSubscriptionCheckout(
      trainerId: trainerId,
    );

    if (response.error != null) {
      state = state.copyWith(isLoading: false, error: response.error);
      return false;
    }

    state = state.copyWith(isLoading: false, checkoutUrl: response.checkoutUrl);

    // Open checkout URL
    if (response.checkoutUrl != null) {
      final uri = Uri.parse(response.checkoutUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    return false;
  }

  Future<bool> startOneTimeCheckout(int trainerId) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.createOneTimeCheckout(
      trainerId: trainerId,
    );

    if (response.error != null) {
      state = state.copyWith(isLoading: false, error: response.error);
      return false;
    }

    state = state.copyWith(isLoading: false, checkoutUrl: response.checkoutUrl);

    // Open checkout URL
    if (response.checkoutUrl != null) {
      final uri = Uri.parse(response.checkoutUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    }

    return false;
  }

  void reset() {
    state = CheckoutState();
  }
}

final checkoutProvider =
    StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return CheckoutNotifier(repository);
});

// ============ Trainer Payments State ============

class TrainerPaymentsState {
  final bool isLoading;
  final List<TraineePaymentModel> payments;
  final List<TraineeSubscriptionModel> subscribers;
  final String? error;

  TrainerPaymentsState({
    this.isLoading = false,
    this.payments = const [],
    this.subscribers = const [],
    this.error,
  });

  TrainerPaymentsState copyWith({
    bool? isLoading,
    List<TraineePaymentModel>? payments,
    List<TraineeSubscriptionModel>? subscribers,
    String? error,
  }) {
    return TrainerPaymentsState(
      isLoading: isLoading ?? this.isLoading,
      payments: payments ?? this.payments,
      subscribers: subscribers ?? this.subscribers,
      error: error,
    );
  }

  double get totalRevenue => payments
      .where((p) => p.isSucceeded)
      .fold(0.0, (sum, p) => sum + p.amountValue);

  int get activeSubscriberCount => subscribers.length;
}

class TrainerPaymentsNotifier extends StateNotifier<TrainerPaymentsState> {
  final PaymentRepository _repository;

  TrainerPaymentsNotifier(this._repository) : super(TrainerPaymentsState());

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    final payments = await _repository.getTrainerPayments();
    final subscribers = await _repository.getTrainerSubscribers();

    state = state.copyWith(
      isLoading: false,
      payments: payments,
      subscribers: subscribers,
    );
  }
}

final trainerPaymentsProvider =
    StateNotifierProvider<TrainerPaymentsNotifier, TrainerPaymentsState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return TrainerPaymentsNotifier(repository);
});

// ============ Trainer Public Pricing Provider ============

final trainerPublicPricingProvider =
    FutureProvider.family<TrainerPublicPricingModel?, int>((ref, trainerId) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getTrainerPublicPricing(trainerId);
});

// ============ Trainer Coupons State ============

class TrainerCoupon {
  final int id;
  final String code;
  final String description;
  final String couponType;
  final String discountValue;
  final String status;
  final int maxUses;
  final int currentUses;
  final String? validFrom;
  final String? validUntil;
  final bool isValid;
  final String? createdAt;

  TrainerCoupon({
    required this.id,
    required this.code,
    this.description = '',
    required this.couponType,
    required this.discountValue,
    required this.status,
    this.maxUses = 0,
    this.currentUses = 0,
    this.validFrom,
    this.validUntil,
    this.isValid = false,
    this.createdAt,
  });

  factory TrainerCoupon.fromJson(Map<String, dynamic> json) {
    return TrainerCoupon(
      id: json['id'] as int,
      code: json['code'] as String,
      description: json['description'] as String? ?? '',
      couponType: json['coupon_type'] as String,
      discountValue: json['discount_value']?.toString() ?? '0',
      status: json['status'] as String,
      maxUses: json['max_uses'] as int? ?? 0,
      currentUses: json['current_uses'] as int? ?? 0,
      validFrom: json['valid_from'] as String?,
      validUntil: json['valid_until'] as String?,
      isValid: json['is_valid'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

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

class TrainerCouponsState {
  final List<TrainerCoupon> coupons;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? statusFilter;

  TrainerCouponsState({
    this.coupons = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.statusFilter,
  });

  TrainerCouponsState copyWith({
    List<TrainerCoupon>? coupons,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? statusFilter,
  }) {
    return TrainerCouponsState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      statusFilter: statusFilter,
    );
  }
}

class TrainerCouponsNotifier extends StateNotifier<TrainerCouponsState> {
  final PaymentRepository _repository;

  TrainerCouponsNotifier(this._repository) : super(TrainerCouponsState());

  Future<void> loadCoupons({String? status}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: status);

    final result = await _repository.getTrainerCoupons(status: status);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'] as List<dynamic>;
      final coupons = data.map((json) => TrainerCoupon.fromJson(json as Map<String, dynamic>)).toList();
      state = state.copyWith(
        isLoading: false,
        coupons: coupons,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<bool> createCoupon(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.createTrainerCoupon(data);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadCoupons(status: state.statusFilter);
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> revokeCoupon(int id) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.revokeTrainerCoupon(id);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadCoupons(status: state.statusFilter);
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> reactivateCoupon(int id) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.reactivateTrainerCoupon(id);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadCoupons(status: state.statusFilter);
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> deleteCoupon(int id) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.deleteTrainerCoupon(id);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadCoupons(status: state.statusFilter);
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }
}

final trainerCouponsProvider =
    StateNotifierProvider<TrainerCouponsNotifier, TrainerCouponsState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return TrainerCouponsNotifier(repository);
});
