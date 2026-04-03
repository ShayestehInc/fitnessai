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
  final String? taskId;
  final String? progressStep;
  final List<String> completedSteps;

  const QuickBuildState({
    this.isLoading = false,
    this.error,
    this.result,
    this.taskId,
    this.progressStep,
    this.completedSteps = const [],
  });

  QuickBuildState copyWith({
    bool? isLoading,
    String? error,
    QuickBuildResult? result,
    String? taskId,
    String? progressStep,
    List<String>? completedSteps,
  }) {
    return QuickBuildState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      taskId: taskId ?? this.taskId,
      progressStep: progressStep,
      completedSteps: completedSteps ?? this.completedSteps,
    );
  }
}

class QuickBuildNotifier extends StateNotifier<QuickBuildState> {
  final TrainingPlanRepository _repository;

  QuickBuildNotifier(this._repository) : super(const QuickBuildState());

  Future<void> build(BuilderBrief brief) async {
    state = state.copyWith(isLoading: true, error: null);

    // Step 1: Submit the build request
    final submitResult = await _repository.submitQuickBuild(brief);
    if (submitResult['success'] != true) {
      state = QuickBuildState(error: submitResult['error'] as String?);
      return;
    }

    final taskId = submitResult['task_id'] as String;
    state = state.copyWith(taskId: taskId, progressStep: 'Submitting...');

    // Step 2: Poll for result
    await _pollForResult(taskId);
  }

  Future<void> _pollForResult(String taskId) async {
    const maxAttempts = 120; // 2 min max
    const pollInterval = Duration(seconds: 1);

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(pollInterval);

      // Stop polling if the notifier was disposed
      if (!mounted) return;

      final statusResult = await _repository.getQuickBuildStatus(taskId);
      if (!mounted) return;

      if (statusResult['success'] != true) {
        state = QuickBuildState(error: statusResult['error'] as String?);
        return;
      }

      final taskStatus = statusResult['status'] as String;

      if (taskStatus == 'completed') {
        state = QuickBuildState(
          result: statusResult['data'] as QuickBuildResult,
        );
        return;
      } else if (taskStatus == 'failed') {
        state = QuickBuildState(
          error: statusResult['error'] as String? ?? 'Build failed',
        );
        return;
      }

      // Still running — update progress
      state = state.copyWith(
        progressStep: statusResult['progress_step'] as String?,
        completedSteps: statusResult['completed_steps'] as List<String>? ?? state.completedSteps,
      );
    }

    state = const QuickBuildState(error: 'Build timed out. Please try again.');
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
    // Preserve history before setting loading state
    final previousHistory = List<BuilderStepResult>.from(state.stepHistory);
    final currentStep = state.currentStepResult?.currentStep;
    state = state.copyWith(isLoading: true, error: null);

    // Step 1: Submit advance request
    final submitResult = await _repository.submitBuilderAdvance(
      state.planId!,
      override: override,
      currentStep: currentStep,
    );
    if (submitResult['success'] != true) {
      state = state.copyWith(
        isLoading: false,
        error: submitResult['error'] as String?,
      );
      return;
    }

    // Step 2: Poll for result
    final taskId = submitResult['task_id'] as String;
    const maxAttempts = 120;
    const pollInterval = Duration(seconds: 1);

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(pollInterval);
      if (!mounted) return;

      final statusResult = await _repository.getBuilderAdvanceStatus(taskId);
      if (!mounted) return;

      if (statusResult['success'] != true) {
        state = state.copyWith(
          isLoading: false,
          error: statusResult['error'] as String?,
        );
        return;
      }

      final taskStatus = statusResult['status'] as String;

      if (taskStatus == 'completed') {
        final step = statusResult['data'] as BuilderStepResult;
        state = AdvancedBuilderState(
          planId: state.planId,
          currentStepResult: step,
          stepHistory: [...previousHistory, step],
        );
        return;
      } else if (taskStatus == 'failed') {
        state = state.copyWith(
          isLoading: false,
          error: statusResult['error'] as String? ?? 'Step failed',
        );
        return;
      }
    }

    state = state.copyWith(
      isLoading: false,
      error: 'Step timed out. Please try again.',
    );
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
