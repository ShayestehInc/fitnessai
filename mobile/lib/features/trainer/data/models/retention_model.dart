// Data models for retention analytics.
// Uses plain classes (not Freezed) since the analytics providers return raw
// maps — consistent with adherence/progress analytics pattern.

class RetentionSummaryModel {
  final int totalTrainees;
  final int atRiskCount;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final double avgEngagement;
  final double retentionRate;

  const RetentionSummaryModel({
    required this.totalTrainees,
    required this.atRiskCount,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.avgEngagement,
    required this.retentionRate,
  });

  factory RetentionSummaryModel.fromJson(Map<String, dynamic> json) {
    return RetentionSummaryModel(
      totalTrainees: (json['total_trainees'] as num?)?.toInt() ?? 0,
      atRiskCount: (json['at_risk_count'] as num?)?.toInt() ?? 0,
      criticalCount: (json['critical_count'] as num?)?.toInt() ?? 0,
      highCount: (json['high_count'] as num?)?.toInt() ?? 0,
      mediumCount: (json['medium_count'] as num?)?.toInt() ?? 0,
      lowCount: (json['low_count'] as num?)?.toInt() ?? 0,
      avgEngagement: (json['avg_engagement'] as num?)?.toDouble() ?? 0.0,
      retentionRate: (json['retention_rate'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class TraineeEngagementModel {
  final int traineeId;
  final String traineeEmail;
  final String traineeName;
  final double engagementScore;
  final double churnRiskScore;
  final String riskTier;
  final int? daysSinceLastActivity;
  final double workoutConsistency;
  final double nutritionConsistency;
  final String? lastActiveDate;

  const TraineeEngagementModel({
    required this.traineeId,
    required this.traineeEmail,
    required this.traineeName,
    required this.engagementScore,
    required this.churnRiskScore,
    required this.riskTier,
    this.daysSinceLastActivity,
    required this.workoutConsistency,
    required this.nutritionConsistency,
    this.lastActiveDate,
  });

  factory TraineeEngagementModel.fromJson(Map<String, dynamic> json) {
    return TraineeEngagementModel(
      traineeId: (json['trainee_id'] as num?)?.toInt() ?? 0,
      traineeEmail: json['trainee_email'] as String? ?? '',
      traineeName: json['trainee_name'] as String? ?? '',
      engagementScore: (json['engagement_score'] as num?)?.toDouble() ?? 0.0,
      churnRiskScore: (json['churn_risk_score'] as num?)?.toDouble() ?? 0.0,
      riskTier: json['risk_tier'] as String? ?? 'low',
      daysSinceLastActivity: (json['days_since_last_activity'] as num?)?.toInt(),
      workoutConsistency: (json['workout_consistency'] as num?)?.toDouble() ?? 0.0,
      nutritionConsistency: (json['nutrition_consistency'] as num?)?.toDouble() ?? 0.0,
      lastActiveDate: json['last_active_date'] as String?,
    );
  }
}

class RetentionAnalyticsModel {
  final int periodDays;
  final RetentionSummaryModel summary;
  final List<TraineeEngagementModel> trainees;

  const RetentionAnalyticsModel({
    required this.periodDays,
    required this.summary,
    required this.trainees,
  });

  factory RetentionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return RetentionAnalyticsModel(
      periodDays: (json['period_days'] as num?)?.toInt() ?? 14,
      summary: RetentionSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      trainees: (json['trainees'] as List<dynamic>?)
              ?.map((e) => TraineeEngagementModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
