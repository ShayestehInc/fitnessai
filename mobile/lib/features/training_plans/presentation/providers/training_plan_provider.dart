import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/training_plan_models.dart';
import '../../data/repositories/training_plan_repository.dart';

final trainingPlanRepositoryProvider =
    Provider<TrainingPlanRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainingPlanRepository(apiClient);
});

/// State for the plans list screen.
class TrainingPlansState {
  final List<TrainingPlanModel> plans;
  final bool isLoading;
  final String? error;
  final String? statusFilter;

  const TrainingPlansState({
    this.plans = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
  });

  TrainingPlansState copyWith({
    List<TrainingPlanModel>? plans,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) {
    return TrainingPlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class TrainingPlansNotifier extends StateNotifier<TrainingPlansState> {
  final TrainingPlanRepository _repository;

  TrainingPlansNotifier(this._repository) : super(const TrainingPlansState());

  Future<void> loadPlans({String? status}) async {
    state = state.copyWith(isLoading: true, error: null, statusFilter: status);
    final result = await _repository.listPlans(status: status);
    if (result['success'] == true) {
      state = state.copyWith(
        plans: result['data'] as List<TrainingPlanModel>,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void setStatusFilter(String? status) {
    loadPlans(status: status);
  }
}

final trainingPlansProvider =
    StateNotifierProvider<TrainingPlansNotifier, TrainingPlansState>((ref) {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  return TrainingPlansNotifier(repository);
});

/// Fetches full plan detail by ID.
final planDetailProvider = FutureProvider.autoDispose
    .family<TrainingPlanModel, int>((ref, planId) async {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  final result = await repository.getPlanDetail(planId);
  if (result['success'] == true) {
    return result['data'] as TrainingPlanModel;
  }
  throw Exception(result['error'] ?? 'Failed to load plan');
});

/// Fetches session detail by ID.
final sessionDetailProvider = FutureProvider.autoDispose
    .family<PlanSessionModel, int>((ref, sessionId) async {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  final result = await repository.getSessionDetail(sessionId);
  if (result['success'] == true) {
    return result['data'] as PlanSessionModel;
  }
  throw Exception(result['error'] ?? 'Failed to load session');
});

/// Fetches available split templates.
final splitTemplatesProvider =
    FutureProvider.autoDispose<List<SplitTemplateModel>>((ref) async {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  final result = await repository.listSplitTemplates();
  if (result['success'] == true) {
    return result['data'] as List<SplitTemplateModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load templates');
});

/// Fetches available modalities.
final modalitiesProvider =
    FutureProvider.autoDispose<List<ModalityModel>>((ref) async {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  final result = await repository.listModalities();
  if (result['success'] == true) {
    return result['data'] as List<ModalityModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load modalities');
});
