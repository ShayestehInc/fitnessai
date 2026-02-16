class AmbassadorUser {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isActive;
  final String? createdAt;

  const AmbassadorUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.isActive = true,
    this.createdAt,
  });

  factory AmbassadorUser.fromJson(Map<String, dynamic> json) {
    return AmbassadorUser(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
    );
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) {
      return '$firstName ${lastName ?? ''}'.trim();
    }
    final localPart = email.split('@').first;
    return localPart.isNotEmpty ? localPart : email;
  }

  String get initials {
    final name = displayName;
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

class AmbassadorProfile {
  final int id;
  final AmbassadorUser user;
  final String referralCode;
  final String commissionRate;
  final bool isActive;
  final int totalReferrals;
  final String totalEarnings;
  final String? createdAt;
  final String? updatedAt;

  const AmbassadorProfile({
    required this.id,
    required this.user,
    required this.referralCode,
    required this.commissionRate,
    required this.isActive,
    required this.totalReferrals,
    required this.totalEarnings,
    this.createdAt,
    this.updatedAt,
  });

  factory AmbassadorProfile.fromJson(Map<String, dynamic> json) {
    return AmbassadorProfile(
      id: json['id'] as int,
      user: AmbassadorUser.fromJson(json['user'] as Map<String, dynamic>),
      referralCode: json['referral_code'] as String,
      commissionRate: json['commission_rate']?.toString() ?? '0.20',
      isActive: json['is_active'] as bool? ?? true,
      totalReferrals: json['total_referrals'] as int? ?? 0,
      totalEarnings: json['total_earnings']?.toString() ?? '0.00',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  double get commissionPercent => (double.tryParse(commissionRate) ?? 0.20) * 100;
}

class AmbassadorReferral {
  final int id;
  final AmbassadorUser trainer;
  final String referralCodeUsed;
  final String status;
  final String referredAt;
  final String? activatedAt;
  final String? churnedAt;
  final String trainerSubscriptionTier;
  final String totalCommissionEarned;

  const AmbassadorReferral({
    required this.id,
    required this.trainer,
    required this.referralCodeUsed,
    required this.status,
    required this.referredAt,
    this.activatedAt,
    this.churnedAt,
    required this.trainerSubscriptionTier,
    required this.totalCommissionEarned,
  });

  factory AmbassadorReferral.fromJson(Map<String, dynamic> json) {
    return AmbassadorReferral(
      id: json['id'] as int,
      trainer: AmbassadorUser.fromJson(json['trainer'] as Map<String, dynamic>),
      referralCodeUsed: json['referral_code_used'] as String,
      status: json['status'] as String,
      referredAt: json['referred_at'] as String,
      activatedAt: json['activated_at'] as String?,
      churnedAt: json['churned_at'] as String?,
      trainerSubscriptionTier: json['trainer_subscription_tier'] as String? ?? 'FREE',
      totalCommissionEarned: json['total_commission_earned']?.toString() ?? '0.00',
    );
  }
}

class MonthlyEarnings {
  final String month;
  final String earnings;

  const MonthlyEarnings({required this.month, required this.earnings});

  factory MonthlyEarnings.fromJson(Map<String, dynamic> json) {
    return MonthlyEarnings(
      month: json['month'] as String,
      earnings: json['earnings']?.toString() ?? '0.00',
    );
  }
}

class AmbassadorDashboardData {
  final int totalReferrals;
  final int activeReferrals;
  final int pendingReferrals;
  final int churnedReferrals;
  final String totalEarnings;
  final String pendingEarnings;
  final List<MonthlyEarnings> monthlyEarnings;
  final List<AmbassadorReferral> recentReferrals;
  final String referralCode;
  final String commissionRate;
  final bool isActive;

  const AmbassadorDashboardData({
    required this.totalReferrals,
    required this.activeReferrals,
    required this.pendingReferrals,
    required this.churnedReferrals,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.monthlyEarnings,
    required this.recentReferrals,
    required this.referralCode,
    required this.commissionRate,
    required this.isActive,
  });

  factory AmbassadorDashboardData.fromJson(Map<String, dynamic> json) {
    return AmbassadorDashboardData(
      totalReferrals: json['total_referrals'] as int? ?? 0,
      activeReferrals: json['active_referrals'] as int? ?? 0,
      pendingReferrals: json['pending_referrals'] as int? ?? 0,
      churnedReferrals: json['churned_referrals'] as int? ?? 0,
      totalEarnings: json['total_earnings']?.toString() ?? '0.00',
      pendingEarnings: json['pending_earnings']?.toString() ?? '0.00',
      monthlyEarnings: (json['monthly_earnings'] as List<dynamic>?)
              ?.map((e) => MonthlyEarnings.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentReferrals: (json['recent_referrals'] as List<dynamic>?)
              ?.map((e) => AmbassadorReferral.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      referralCode: json['referral_code'] as String? ?? '',
      commissionRate: json['commission_rate']?.toString() ?? '0.20',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  double get commissionPercent => (double.tryParse(commissionRate) ?? 0.20) * 100;
}

class ReferralCodeData {
  final String referralCode;
  final String shareMessage;

  const ReferralCodeData({required this.referralCode, required this.shareMessage});

  factory ReferralCodeData.fromJson(Map<String, dynamic> json) {
    return ReferralCodeData(
      referralCode: json['referral_code'] as String,
      shareMessage: json['share_message'] as String,
    );
  }
}

class AmbassadorCommission {
  final int id;
  final String trainerEmail;
  final String commissionRate;
  final String baseAmount;
  final String commissionAmount;
  final String status;
  final String periodStart;
  final String periodEnd;
  final String createdAt;

  const AmbassadorCommission({
    required this.id,
    required this.trainerEmail,
    required this.commissionRate,
    required this.baseAmount,
    required this.commissionAmount,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  factory AmbassadorCommission.fromJson(Map<String, dynamic> json) {
    return AmbassadorCommission(
      id: json['id'] as int,
      trainerEmail: json['trainer_email'] as String? ?? '',
      commissionRate: json['commission_rate']?.toString() ?? '0.00',
      baseAmount: json['base_amount']?.toString() ?? '0.00',
      commissionAmount: json['commission_amount']?.toString() ?? '0.00',
      status: json['status'] as String? ?? 'PENDING',
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class BulkCommissionActionResult {
  final String message;
  final int processedCount;
  final int skippedCount;

  const BulkCommissionActionResult({
    required this.message,
    required this.processedCount,
    required this.skippedCount,
  });

  factory BulkCommissionActionResult.fromJson(Map<String, dynamic> json) {
    // The backend uses 'approved_count' for approve and 'paid_count' for pay.
    // We normalise both into processedCount.
    final approved = json['approved_count'] as int?;
    final paid = json['paid_count'] as int?;
    return BulkCommissionActionResult(
      message: json['message'] as String? ?? '',
      processedCount: approved ?? paid ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
    );
  }
}

class AmbassadorDetailData {
  final AmbassadorProfile profile;
  final List<AmbassadorReferral> referrals;
  final List<AmbassadorCommission> commissions;

  const AmbassadorDetailData({
    required this.profile,
    required this.referrals,
    required this.commissions,
  });

  int get referralsCount => referrals.length;
  int get commissionsCount => commissions.length;

  factory AmbassadorDetailData.fromJson(Map<String, dynamic> json) {
    return AmbassadorDetailData(
      profile: AmbassadorProfile.fromJson(json['profile'] as Map<String, dynamic>),
      referrals: (json['referrals'] as List<dynamic>?)
              ?.map((e) => AmbassadorReferral.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      commissions: (json['commissions'] as List<dynamic>?)
              ?.map((e) => AmbassadorCommission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
