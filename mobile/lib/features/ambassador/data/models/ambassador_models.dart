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
    return email.split('@').first;
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
