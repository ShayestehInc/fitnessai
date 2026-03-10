import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/decision_log_model.dart';
import '../../data/repositories/decision_log_repository.dart';

final decisionLogRepositoryProvider = Provider<DecisionLogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DecisionLogRepository(apiClient);
});

class DecisionLogFilterParams {
  final String? decisionType;
  final String? actorType;
  final String? dateFrom;
  final String? dateTo;
  final int page;

  const DecisionLogFilterParams({
    this.decisionType,
    this.actorType,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecisionLogFilterParams &&
          runtimeType == other.runtimeType &&
          decisionType == other.decisionType &&
          actorType == other.actorType &&
          dateFrom == other.dateFrom &&
          dateTo == other.dateTo &&
          page == other.page;

  @override
  int get hashCode => Object.hash(decisionType, actorType, dateFrom, dateTo, page);
}

final decisionLogListProvider = FutureProvider.autoDispose
    .family<List<DecisionLogModel>, DecisionLogFilterParams>((ref, params) async {
  final repository = ref.watch(decisionLogRepositoryProvider);
  final result = await repository.listDecisionLogs(
    decisionType: params.decisionType,
    actorType: params.actorType,
    dateFrom: params.dateFrom,
    dateTo: params.dateTo,
    page: params.page,
  );
  if (result['success'] == true) {
    return result['data'] as List<DecisionLogModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load decision logs');
});

final decisionLogDetailProvider = FutureProvider.autoDispose
    .family<DecisionLogModel, String>((ref, id) async {
  final repository = ref.watch(decisionLogRepositoryProvider);
  final result = await repository.getDetail(id);
  if (result['success'] == true) {
    return result['data'] as DecisionLogModel;
  }
  throw Exception(result['error'] ?? 'Failed to load decision detail');
});
