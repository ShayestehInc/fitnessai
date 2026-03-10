import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/analytics_models.dart';
import '../../data/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsRepository(apiClient);
});

final correlationsProvider = FutureProvider.autoDispose
    .family<CorrelationOverviewModel, int>((ref, days) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getCorrelations(days: days);
  if (result['success'] == true) {
    return result['data'] as CorrelationOverviewModel;
  }
  throw Exception(result['error'] ?? 'Failed to load correlations');
});

class TraineePatternParams {
  final int traineeId;
  final int days;

  const TraineePatternParams({required this.traineeId, this.days = 30});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TraineePatternParams &&
          traineeId == other.traineeId &&
          days == other.days;

  @override
  int get hashCode => Object.hash(traineeId, days);
}

final traineePatternsProvider = FutureProvider.autoDispose
    .family<TraineePatternsModel, TraineePatternParams>((ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getTraineePatterns(
    traineeId: params.traineeId,
    days: params.days,
  );
  if (result['success'] == true) {
    return result['data'] as TraineePatternsModel;
  }
  throw Exception(result['error'] ?? 'Failed to load trainee patterns');
});

final auditSummaryProvider = FutureProvider.autoDispose
    .family<AuditSummaryModel, int>((ref, days) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getAuditSummary(days: days);
  if (result['success'] == true) {
    return result['data'] as AuditSummaryModel;
  }
  throw Exception(result['error'] ?? 'Failed to load audit summary');
});

class CohortAnalysisParams {
  final int days;
  final double threshold;

  const CohortAnalysisParams({this.days = 30, this.threshold = 0.7});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortAnalysisParams &&
          days == other.days &&
          threshold == other.threshold;

  @override
  int get hashCode => Object.hash(days, threshold);
}

final cohortAnalysisProvider = FutureProvider.autoDispose
    .family<List<CohortComparisonModel>, CohortAnalysisParams>(
        (ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getCohortAnalysis(
    days: params.days,
    threshold: params.threshold,
  );
  if (result['success'] == true) {
    return result['data'] as List<CohortComparisonModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load cohort analysis');
});

class AuditTimelineParams {
  final int days;
  final int limit;
  final int offset;

  const AuditTimelineParams({
    this.days = 30,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditTimelineParams &&
          days == other.days &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(days, limit, offset);
}

final auditTimelineProvider = FutureProvider.autoDispose
    .family<List<AuditTimelineEntryModel>, AuditTimelineParams>(
        (ref, params) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getAuditTimeline(
    days: params.days,
    limit: params.limit,
    offset: params.offset,
  );
  if (result['success'] == true) {
    return result['data'] as List<AuditTimelineEntryModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load audit timeline');
});
