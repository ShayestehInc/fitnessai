import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_models.dart';
import '../../data/models/tier_coupon_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminRepository(apiClient);
});

/// Admin dashboard state
class AdminDashboardState {
  final AdminDashboardStats? stats;
  final List<AdminSubscriptionListItem> pastDueSubscriptions;
  final List<AdminSubscriptionListItem> upcomingPayments;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.stats,
    this.pastDueSubscriptions = const [],
    this.upcomingPayments = const [],
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    AdminDashboardStats? stats,
    List<AdminSubscriptionListItem>? pastDueSubscriptions,
    List<AdminSubscriptionListItem>? upcomingPayments,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      stats: stats ?? this.stats,
      pastDueSubscriptions: pastDueSubscriptions ?? this.pastDueSubscriptions,
      upcomingPayments: upcomingPayments ?? this.upcomingPayments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminDashboardNotifier(repository);
});

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminRepository _repository;

  AdminDashboardNotifier(this._repository) : super(const AdminDashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load all data in parallel with timeout
      final results = await Future.wait([
        _repository.getDashboardStats(),
        _repository.getPastDueSubscriptions(),
        _repository.getUpcomingPayments(days: 7),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () => [
          {'success': false, 'error': 'Request timed out'},
          {'success': false, 'error': 'Request timed out'},
          {'success': false, 'error': 'Request timed out'},
        ],
      );

      final statsResult = results[0];
      final pastDueResult = results[1];
      final upcomingResult = results[2];

      state = state.copyWith(
        isLoading: false,
        stats: statsResult['success'] == true
            ? statsResult['data'] as AdminDashboardStats
            : null,
        pastDueSubscriptions: pastDueResult['success'] == true
            ? pastDueResult['data'] as List<AdminSubscriptionListItem>
            : [],
        upcomingPayments: upcomingResult['success'] == true
            ? upcomingResult['data'] as List<AdminSubscriptionListItem>
            : [],
        error: statsResult['success'] != true ? statsResult['error'] as String? : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard: ${e.toString()}',
      );
    }
  }
}

/// Trainers list state
class AdminTrainersState {
  final List<AdminTrainer> trainers;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const AdminTrainersState({
    this.trainers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  AdminTrainersState copyWith({
    List<AdminTrainer>? trainers,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return AdminTrainersState(
      trainers: trainers ?? this.trainers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final adminTrainersProvider =
    StateNotifierProvider<AdminTrainersNotifier, AdminTrainersState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminTrainersNotifier(repository);
});

class AdminTrainersNotifier extends StateNotifier<AdminTrainersState> {
  final AdminRepository _repository;

  AdminTrainersNotifier(this._repository) : super(const AdminTrainersState());

  Future<void> loadTrainers({String? search}) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: search ?? '');

    final result = await _repository.getTrainers(search: search);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        trainers: result['data'] as List<AdminTrainer>,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }
}

/// Subscriptions list state
class AdminSubscriptionsState {
  final List<AdminSubscriptionListItem> subscriptions;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? tierFilter;
  final String searchQuery;

  const AdminSubscriptionsState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.tierFilter,
    this.searchQuery = '',
  });

  AdminSubscriptionsState copyWith({
    List<AdminSubscriptionListItem>? subscriptions,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? tierFilter,
    String? searchQuery,
  }) {
    return AdminSubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter,
      tierFilter: tierFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final adminSubscriptionsProvider =
    StateNotifierProvider<AdminSubscriptionsNotifier, AdminSubscriptionsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminSubscriptionsNotifier(repository);
});

class AdminSubscriptionsNotifier extends StateNotifier<AdminSubscriptionsState> {
  final AdminRepository _repository;

  AdminSubscriptionsNotifier(this._repository) : super(const AdminSubscriptionsState());

  Future<void> loadSubscriptions({
    String? status,
    String? tier,
    String? search,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      statusFilter: status,
      tierFilter: tier,
      searchQuery: search ?? '',
    );

    try {
      final result = await _repository.getSubscriptions(
        status: status,
        tier: tier,
        search: search,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => {'success': false, 'error': 'Request timed out'},
      );

      if (result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          subscriptions: result['data'] as List<AdminSubscriptionListItem>,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['error'] as String?,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load subscriptions: ${e.toString()}',
      );
    }
  }
}

/// Subscription detail state
class AdminSubscriptionDetailState {
  final AdminSubscription? subscription;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const AdminSubscriptionDetailState({
    this.subscription,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  AdminSubscriptionDetailState copyWith({
    AdminSubscription? subscription,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return AdminSubscriptionDetailState(
      subscription: subscription ?? this.subscription,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

final adminSubscriptionDetailProvider = StateNotifierProvider.family<
    AdminSubscriptionDetailNotifier, AdminSubscriptionDetailState, int>((ref, id) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminSubscriptionDetailNotifier(repository, id);
});

class AdminSubscriptionDetailNotifier extends StateNotifier<AdminSubscriptionDetailState> {
  final AdminRepository _repository;
  final int _subscriptionId;

  AdminSubscriptionDetailNotifier(this._repository, this._subscriptionId)
      : super(const AdminSubscriptionDetailState());

  Future<void> loadSubscription() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSubscriptionDetail(_subscriptionId);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        subscription: result['data'] as AdminSubscription,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<bool> changeTier(String newTier, {String? reason}) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.changeTier(_subscriptionId, newTier, reason: reason);

    if (result['success'] == true) {
      state = state.copyWith(
        isSaving: false,
        subscription: result['data'] as AdminSubscription,
      );
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> changeStatus(String newStatus, {String? reason}) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.changeStatus(_subscriptionId, newStatus, reason: reason);

    if (result['success'] == true) {
      state = state.copyWith(
        isSaving: false,
        subscription: result['data'] as AdminSubscription,
      );
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> updateNotes(String notes) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.updateNotes(_subscriptionId, notes);

    if (result['success'] == true) {
      state = state.copyWith(
        isSaving: false,
        subscription: result['data'] as AdminSubscription,
      );
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> recordPayment(String amount, {String? description}) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.recordPayment(_subscriptionId, amount, description: description);

    if (result['success'] == true) {
      state = state.copyWith(
        isSaving: false,
        subscription: result['data'] as AdminSubscription,
      );
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

/// Subscription Tiers state
class AdminTiersState {
  final List<SubscriptionTierModel> tiers;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const AdminTiersState({
    this.tiers = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  AdminTiersState copyWith({
    List<SubscriptionTierModel>? tiers,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return AdminTiersState(
      tiers: tiers ?? this.tiers,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

final adminTiersProvider =
    StateNotifierProvider<AdminTiersNotifier, AdminTiersState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminTiersNotifier(repository);
});

class AdminTiersNotifier extends StateNotifier<AdminTiersState> {
  final AdminRepository _repository;

  AdminTiersNotifier(this._repository) : super(const AdminTiersState());

  Future<void> loadTiers() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getTiers();

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        tiers: result['data'] as List<SubscriptionTierModel>,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<bool> createTier(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.createTier(data);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadTiers();
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> updateTier(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.updateTier(id, data);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadTiers();
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> toggleTierActive(int id) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.toggleTierActive(id);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadTiers();
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> deleteTier(int id) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.deleteTier(id);

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadTiers();
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> seedDefaultTiers() async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await _repository.seedDefaultTiers();

    if (result['success'] == true) {
      state = state.copyWith(isSaving: false);
      await loadTiers();
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

/// Admin Coupons state
class AdminCouponsState {
  final List<CouponListItemModel> coupons;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? statusFilter;

  const AdminCouponsState({
    this.coupons = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.statusFilter,
  });

  AdminCouponsState copyWith({
    List<CouponListItemModel>? coupons,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? statusFilter,
  }) {
    return AdminCouponsState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      statusFilter: statusFilter,
    );
  }
}

final adminCouponsProvider =
    StateNotifierProvider<AdminCouponsNotifier, AdminCouponsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminCouponsNotifier(repository);
});

class AdminCouponsNotifier extends StateNotifier<AdminCouponsState> {
  final AdminRepository _repository;

  AdminCouponsNotifier(this._repository) : super(const AdminCouponsState());

  Future<void> loadCoupons({String? status}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: status);

    final result = await _repository.getCoupons(status: status);

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        coupons: result['data'] as List<CouponListItemModel>,
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

    final result = await _repository.createCoupon(data);

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

    final result = await _repository.revokeCoupon(id);

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

    final result = await _repository.reactivateCoupon(id);

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

    final result = await _repository.deleteCoupon(id);

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

/// Coupon detail state
class CouponDetailState {
  final CouponModel? coupon;
  final List<CouponUsageModel> usages;
  final bool isLoading;
  final String? error;

  const CouponDetailState({
    this.coupon,
    this.usages = const [],
    this.isLoading = false,
    this.error,
  });

  CouponDetailState copyWith({
    CouponModel? coupon,
    List<CouponUsageModel>? usages,
    bool? isLoading,
    String? error,
  }) {
    return CouponDetailState(
      coupon: coupon ?? this.coupon,
      usages: usages ?? this.usages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final couponDetailProvider = StateNotifierProvider.family<
    CouponDetailNotifier, CouponDetailState, int>((ref, id) {
  final repository = ref.watch(adminRepositoryProvider);
  return CouponDetailNotifier(repository, id);
});

class CouponDetailNotifier extends StateNotifier<CouponDetailState> {
  final AdminRepository _repository;
  final int _couponId;

  CouponDetailNotifier(this._repository, this._couponId)
      : super(const CouponDetailState());

  Future<void> loadCoupon() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getCoupon(_couponId),
        _repository.getCouponUsages(_couponId),
      ]);

      final couponResult = results[0];
      final usagesResult = results[1];

      state = state.copyWith(
        isLoading: false,
        coupon: couponResult['success'] == true
            ? couponResult['data'] as CouponModel
            : null,
        usages: usagesResult['success'] == true
            ? usagesResult['data'] as List<CouponUsageModel>
            : [],
        error: couponResult['success'] != true
            ? couponResult['error'] as String?
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load coupon: ${e.toString()}',
      );
    }
  }
}
