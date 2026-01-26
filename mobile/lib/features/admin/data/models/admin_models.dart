/// Admin dashboard statistics model
class AdminDashboardStats {
  final int totalTrainers;
  final int activeTrainers;
  final int totalTrainees;
  final Map<String, int> tierBreakdown;
  final Map<String, int> statusBreakdown;
  final String monthlyRecurringRevenue;
  final String totalPastDue;
  final int paymentsDueToday;
  final int paymentsDueThisWeek;
  final int paymentsDueThisMonth;
  final int pastDueCount;

  const AdminDashboardStats({
    required this.totalTrainers,
    required this.activeTrainers,
    required this.totalTrainees,
    required this.tierBreakdown,
    required this.statusBreakdown,
    required this.monthlyRecurringRevenue,
    required this.totalPastDue,
    required this.paymentsDueToday,
    required this.paymentsDueThisWeek,
    required this.paymentsDueThisMonth,
    required this.pastDueCount,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalTrainers: json['total_trainers'] as int? ?? 0,
      activeTrainers: json['active_trainers'] as int? ?? 0,
      totalTrainees: json['total_trainees'] as int? ?? 0,
      tierBreakdown: Map<String, int>.from(json['tier_breakdown'] ?? {}),
      statusBreakdown: Map<String, int>.from(json['status_breakdown'] ?? {}),
      monthlyRecurringRevenue: json['monthly_recurring_revenue'] as String? ?? '0.00',
      totalPastDue: json['total_past_due'] as String? ?? '0.00',
      paymentsDueToday: json['payments_due_today'] as int? ?? 0,
      paymentsDueThisWeek: json['payments_due_this_week'] as int? ?? 0,
      paymentsDueThisMonth: json['payments_due_this_month'] as int? ?? 0,
      pastDueCount: json['past_due_count'] as int? ?? 0,
    );
  }
}

/// Subscription tier enum
enum SubscriptionTier {
  free('FREE', 'Free', 0, 3),
  starter('STARTER', 'Starter', 29, 10),
  pro('PRO', 'Pro', 79, 50),
  enterprise('ENTERPRISE', 'Enterprise', 199, -1); // -1 = unlimited

  const SubscriptionTier(this.value, this.displayName, this.price, this.maxTrainees);

  final String value;
  final String displayName;
  final int price;
  final int maxTrainees;

  static SubscriptionTier fromString(String value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }
}

/// Subscription status enum
enum SubscriptionStatus {
  active('active', 'Active'),
  pastDue('past_due', 'Past Due'),
  canceled('canceled', 'Canceled'),
  trialing('trialing', 'Trialing'),
  suspended('suspended', 'Suspended');

  const SubscriptionStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

/// Trainer with subscription info
class AdminTrainer {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isActive;
  final String createdAt;
  final int traineeCount;
  final AdminSubscriptionSummary? subscription;

  const AdminTrainer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
    required this.traineeCount,
    this.subscription,
  });

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }

  factory AdminTrainer.fromJson(Map<String, dynamic> json) {
    return AdminTrainer(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      traineeCount: json['trainee_count'] as int? ?? 0,
      subscription: json['subscription'] != null
          ? AdminSubscriptionSummary.fromJson(json['subscription'])
          : null,
    );
  }
}

/// Subscription summary for trainer list
class AdminSubscriptionSummary {
  final int? id;
  final String? tier;
  final String? status;
  final String? nextPaymentDate;
  final String pastDueAmount;

  const AdminSubscriptionSummary({
    this.id,
    this.tier,
    this.status,
    this.nextPaymentDate,
    this.pastDueAmount = '0.00',
  });

  SubscriptionTier get tierEnum => tier != null
      ? SubscriptionTier.fromString(tier!)
      : SubscriptionTier.free;

  SubscriptionStatus get statusEnum => status != null
      ? SubscriptionStatus.fromString(status!)
      : SubscriptionStatus.trialing;

  factory AdminSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionSummary(
      id: json['id'] as int?,
      tier: json['tier'] as String?,
      status: json['status'] as String?,
      nextPaymentDate: json['next_payment_date'] as String?,
      pastDueAmount: json['past_due_amount'] as String? ?? '0.00',
    );
  }
}

/// Full subscription details
class AdminSubscription {
  final int id;
  final String trainerEmail;
  final String trainerName;
  final String tier;
  final String status;
  final int traineeCount;
  final int maxTrainees;
  final String monthlyPrice;
  final String? nextPaymentDate;
  final String? lastPaymentDate;
  final String? lastPaymentAmount;
  final String pastDueAmount;
  final String? pastDueSince;
  final int? daysUntilPayment;
  final int? daysPastDue;
  final int failedPaymentCount;
  final String? trialStart;
  final String? trialEnd;
  final bool trialUsed;
  final String adminNotes;
  final String createdAt;
  final List<PaymentHistoryItem> recentPayments;
  final List<SubscriptionChangeItem> recentChanges;

  const AdminSubscription({
    required this.id,
    required this.trainerEmail,
    required this.trainerName,
    required this.tier,
    required this.status,
    required this.traineeCount,
    required this.maxTrainees,
    required this.monthlyPrice,
    this.nextPaymentDate,
    this.lastPaymentDate,
    this.lastPaymentAmount,
    required this.pastDueAmount,
    this.pastDueSince,
    this.daysUntilPayment,
    this.daysPastDue,
    required this.failedPaymentCount,
    this.trialStart,
    this.trialEnd,
    required this.trialUsed,
    required this.adminNotes,
    required this.createdAt,
    required this.recentPayments,
    required this.recentChanges,
  });

  SubscriptionTier get tierEnum => SubscriptionTier.fromString(tier);
  SubscriptionStatus get statusEnum => SubscriptionStatus.fromString(status);

  bool get isPastDue => status == 'past_due' || double.parse(pastDueAmount) > 0;

  factory AdminSubscription.fromJson(Map<String, dynamic> json) {
    final trainer = json['trainer'] as Map<String, dynamic>?;
    return AdminSubscription(
      id: json['id'] as int,
      trainerEmail: trainer?['email'] as String? ?? '',
      trainerName: '${trainer?['first_name'] ?? ''} ${trainer?['last_name'] ?? ''}'.trim(),
      tier: json['tier'] as String? ?? 'FREE',
      status: json['status'] as String? ?? 'trialing',
      traineeCount: json['trainee_count'] as int? ?? 0,
      maxTrainees: json['max_trainees'] as int? ?? 0,
      monthlyPrice: json['monthly_price'] as String? ?? '0.00',
      nextPaymentDate: json['next_payment_date'] as String?,
      lastPaymentDate: json['last_payment_date'] as String?,
      lastPaymentAmount: json['last_payment_amount'] as String?,
      pastDueAmount: json['past_due_amount'] as String? ?? '0.00',
      pastDueSince: json['past_due_since'] as String?,
      daysUntilPayment: json['days_until_payment'] as int?,
      daysPastDue: json['days_past_due'] as int?,
      failedPaymentCount: json['failed_payment_count'] as int? ?? 0,
      trialStart: json['trial_start'] as String?,
      trialEnd: json['trial_end'] as String?,
      trialUsed: json['trial_used'] as bool? ?? false,
      adminNotes: json['admin_notes'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      recentPayments: (json['recent_payments'] as List?)
              ?.map((p) => PaymentHistoryItem.fromJson(p))
              .toList() ??
          [],
      recentChanges: (json['recent_changes'] as List?)
              ?.map((c) => SubscriptionChangeItem.fromJson(c))
              .toList() ??
          [],
    );
  }
}

/// Subscription list item (lightweight)
class AdminSubscriptionListItem {
  final int id;
  final String trainerEmail;
  final String trainerName;
  final String tier;
  final String status;
  final int traineeCount;
  final int maxTrainees;
  final String monthlyPrice;
  final String? nextPaymentDate;
  final String pastDueAmount;
  final String? pastDueSince;
  final int? daysUntilPayment;
  final int? daysPastDue;
  final String createdAt;

  const AdminSubscriptionListItem({
    required this.id,
    required this.trainerEmail,
    required this.trainerName,
    required this.tier,
    required this.status,
    required this.traineeCount,
    required this.maxTrainees,
    required this.monthlyPrice,
    this.nextPaymentDate,
    required this.pastDueAmount,
    this.pastDueSince,
    this.daysUntilPayment,
    this.daysPastDue,
    required this.createdAt,
  });

  SubscriptionTier get tierEnum => SubscriptionTier.fromString(tier);
  SubscriptionStatus get statusEnum => SubscriptionStatus.fromString(status);

  bool get isPastDue => status == 'past_due' || double.parse(pastDueAmount) > 0;

  factory AdminSubscriptionListItem.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionListItem(
      id: json['id'] as int,
      trainerEmail: json['trainer_email'] as String? ?? '',
      trainerName: json['trainer_name'] as String? ?? '',
      tier: json['tier'] as String? ?? 'FREE',
      status: json['status'] as String? ?? 'trialing',
      traineeCount: json['trainee_count'] as int? ?? 0,
      maxTrainees: json['max_trainees'] as int? ?? 0,
      monthlyPrice: json['monthly_price'] as String? ?? '0.00',
      nextPaymentDate: json['next_payment_date'] as String?,
      pastDueAmount: json['past_due_amount'] as String? ?? '0.00',
      pastDueSince: json['past_due_since'] as String?,
      daysUntilPayment: json['days_until_payment'] as int?,
      daysPastDue: json['days_past_due'] as int?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

/// Payment history item
class PaymentHistoryItem {
  final int id;
  final String amount;
  final String status;
  final String description;
  final String? failureReason;
  final String paymentDate;

  const PaymentHistoryItem({
    required this.id,
    required this.amount,
    required this.status,
    required this.description,
    this.failureReason,
    required this.paymentDate,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] as int,
      amount: json['amount'] as String? ?? '0.00',
      status: json['status'] as String? ?? '',
      description: json['description'] as String? ?? '',
      failureReason: json['failure_reason'] as String?,
      paymentDate: json['payment_date'] as String? ?? '',
    );
  }
}

/// Subscription change history item
class SubscriptionChangeItem {
  final int id;
  final String changeType;
  final String? fromTier;
  final String? toTier;
  final String? fromStatus;
  final String? toStatus;
  final String? changedByEmail;
  final String reason;
  final String createdAt;

  const SubscriptionChangeItem({
    required this.id,
    required this.changeType,
    this.fromTier,
    this.toTier,
    this.fromStatus,
    this.toStatus,
    this.changedByEmail,
    required this.reason,
    required this.createdAt,
  });

  factory SubscriptionChangeItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionChangeItem(
      id: json['id'] as int,
      changeType: json['change_type'] as String? ?? '',
      fromTier: json['from_tier'] as String?,
      toTier: json['to_tier'] as String?,
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String?,
      changedByEmail: json['changed_by_email'] as String?,
      reason: json['reason'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
