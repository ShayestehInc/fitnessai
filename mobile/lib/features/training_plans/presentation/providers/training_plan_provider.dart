import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/builder_models.dart';
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
    .family<TrainingPlanModel, String>((ref, planId) async {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  final result = await repository.getPlanDetail(planId);
  if (result['success'] == true) {
    return result['data'] as TrainingPlanModel;
  }
  throw Exception(result['error'] ?? 'Failed to load plan');
});

/// Fetches session detail by ID.
final sessionDetailProvider = FutureProvider.autoDispose
    .family<PlanSessionModel, String>((ref, sessionId) async {
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

// ---------------------------------------------------------------------------
// Builder Providers
// ---------------------------------------------------------------------------

/// State for the Quick Build flow.
class QuickBuildState {
  final bool isLoading;
  final String? error;
  final QuickBuildResult? result;

  const QuickBuildState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  QuickBuildState copyWith({
    bool? isLoading,
    String? error,
    QuickBuildResult? result,
  }) {
    return QuickBuildState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

class QuickBuildNotifier extends StateNotifier<QuickBuildState> {
  final TrainingPlanRepository _repository;

  QuickBuildNotifier(this._repository) : super(const QuickBuildState());

  Future<void> build(BuilderBrief brief) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.quickBuild(brief);
    if (result['success'] == true) {
      state = QuickBuildState(
        result: result['data'] as QuickBuildResult,
      );
    } else {
      state = QuickBuildState(error: result['error'] as String?);
    }
  }

  void reset() {
    state = const QuickBuildState();
  }
}

final quickBuildProvider =
    StateNotifierProvider.autoDispose<QuickBuildNotifier, QuickBuildState>(
        (ref) {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  return QuickBuildNotifier(repository);
});

/// State for the Advanced Builder flow.
class AdvancedBuilderState {
  final bool isLoading;
  final String? error;
  final String? planId;
  final BuilderStepResult? currentStepResult;
  final List<BuilderStepResult> stepHistory;

  const AdvancedBuilderState({
    this.isLoading = false,
    this.error,
    this.planId,
    this.currentStepResult,
    this.stepHistory = const [],
  });

  AdvancedBuilderState copyWith({
    bool? isLoading,
    String? error,
    String? planId,
    BuilderStepResult? currentStepResult,
    List<BuilderStepResult>? stepHistory,
  }) {
    return AdvancedBuilderState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      planId: planId ?? this.planId,
      currentStepResult: currentStepResult ?? this.currentStepResult,
      stepHistory: stepHistory ?? this.stepHistory,
    );
  }
}

class AdvancedBuilderNotifier extends StateNotifier<AdvancedBuilderState> {
  final TrainingPlanRepository _repository;

  AdvancedBuilderNotifier(this._repository)
      : super(const AdvancedBuilderState());

  Future<void> start(BuilderBrief brief) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.builderStart(brief);
    if (result['success'] == true) {
      final step = result['data'] as BuilderStepResult;
      state = AdvancedBuilderState(
        planId: step.planId,
        currentStepResult: step,
        stepHistory: [step],
      );
    } else {
      state = AdvancedBuilderState(error: result['error'] as String?);
    }
  }

  Future<void> advance({Map<String, dynamic>? override}) async {
    if (state.planId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.builderAdvance(
      state.planId!,
      override: override,
    );
    if (result['success'] == true) {
      final step = result['data'] as BuilderStepResult;
      state = state.copyWith(
        isLoading: false,
        currentStepResult: step,
        stepHistory: [...state.stepHistory, step],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  void goBack() {
    if (state.stepHistory.length <= 1) return;
    final newHistory = List<BuilderStepResult>.from(state.stepHistory)
      ..removeLast();
    state = state.copyWith(
      currentStepResult: newHistory.last,
      stepHistory: newHistory,
    );
  }

  void reset() {
    state = const AdvancedBuilderState();
  }
}

final advancedBuilderProvider = StateNotifierProvider.autoDispose<
    AdvancedBuilderNotifier, AdvancedBuilderState>((ref) {
  final repository = ref.watch(trainingPlanRepositoryProvider);
  return AdvancedBuilderNotifier(repository);
});
