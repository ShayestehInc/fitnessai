import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/triage_models.dart';
import '../../data/repositories/triage_repository.dart';

/// Repository provider for pain triage.
final triageRepositoryProvider = Provider<TriageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TriageRepository(apiClient);
});

/// State for the triage flow.
class TriageState {
  final bool isLoading;
  final String? error;
  final TriageStartResult? startResult;
  final RemedyLadderResult? ladderResult;
  final TriageFinalizeResult? finalResult;
  final int currentStep; // 0=round1, 1=round2, 2=ladder, 3=proceed

  const TriageState({
    this.isLoading = false,
    this.error,
    this.startResult,
    this.ladderResult,
    this.finalResult,
    this.currentStep = 0,
  });

  TriageState copyWith({
    bool? isLoading,
    String? error,
    TriageStartResult? startResult,
    RemedyLadderResult? ladderResult,
    TriageFinalizeResult? finalResult,
    int? currentStep,
  }) {
    return TriageState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      startResult: startResult ?? this.startResult,
      ladderResult: ladderResult ?? this.ladderResult,
      finalResult: finalResult ?? this.finalResult,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Notifier managing the pain triage workflow.
final triageNotifierProvider =
    StateNotifierProvider.autoDispose<TriageNotifier, TriageState>((ref) {
  final repo = ref.watch(triageRepositoryProvider);
  return TriageNotifier(repo);
});

class TriageNotifier extends StateNotifier<TriageState> {
  final TriageRepository _repo;

  TriageNotifier(this._repo) : super(const TriageState());

  /// Step 1: Start the triage flow.
  Future<bool> startTriage({
    required String painEventId,
    required String activeSessionId,
    String? activeSetLogId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.startTriage(
      painEventId: painEventId,
      activeSessionId: activeSessionId,
      activeSetLogId: activeSetLogId,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        startResult: result['result'] as TriageStartResult,
        currentStep: 1,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  /// Step 2: Submit round 2 answers.
  Future<bool> submitRound2({
    required String loadSensitivity,
    required String romSensitivity,
    required String tempoSensitivity,
    bool supportHelps = false,
    String previousTrigger = '',
  }) async {
    final triageId = state.startResult?.triageResponseId;
    if (triageId == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.submitRound2(
      triageResponseId: triageId,
      loadSensitivity: loadSensitivity,
      romSensitivity: romSensitivity,
      tempoSensitivity: tempoSensitivity,
      supportHelps: supportHelps,
      previousTrigger: previousTrigger,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        ladderResult: result['result'] as RemedyLadderResult,
        currentStep: 2,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  /// Step 3: Record intervention attempt.
  Future<bool> recordIntervention({
    required int stepOrder,
    required bool applied,
    required String result,
  }) async {
    final triageId = state.startResult?.triageResponseId;
    if (triageId == null) return false;

    final apiResult = await _repo.recordIntervention(
      triageResponseId: triageId,
      stepOrder: stepOrder,
      applied: applied,
      result: result,
    );

    return apiResult['success'] == true;
  }

  /// Step 4: Finalize with proceed decision.
  Future<bool> finalizeTriage({
    required String proceedDecision,
  }) async {
    final triageId = state.startResult?.triageResponseId;
    if (triageId == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.finalizeTriage(
      triageResponseId: triageId,
      proceedDecision: proceedDecision,
    );

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        finalResult: result['result'] as TriageFinalizeResult,
        currentStep: 3,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  /// Move to the proceed card step.
  void goToProceedStep() {
    state = state.copyWith(currentStep: 2);
  }

  /// Reset state.
  void reset() {
    state = const TriageState();
  }
}
