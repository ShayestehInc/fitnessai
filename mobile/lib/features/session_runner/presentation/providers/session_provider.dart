import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/session_models.dart';
import '../../data/repositories/session_repository.dart';

part 'session_provider.freezed.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SessionRepository(apiClient);
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
class SessionState with _$SessionState {
  const factory SessionState({
    ActiveSessionModel? activeSession,
    SessionSummaryModel? summary,
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool isResting,
    @Default(0) int restSecondsRemaining,
    @Default(0) int restSecondsTotal,
    @Default(0) int currentSlotIndex,
    @Default(false) bool isLoggingSet,
  }) = _SessionState;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

final sessionNotifierProvider =
    StateNotifierProvider.autoDispose<SessionNotifier, SessionState>(
  (ref) {
    final repo = ref.watch(sessionRepositoryProvider);
    return SessionNotifier(repo);
  },
);

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionRepository _repo;
  Timer? _restTimer;

  SessionNotifier(this._repo) : super(const SessionState());

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> loadActiveSession() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.getActiveSession();

    if (!mounted) return;

    if (result['success'] == true) {
      final session = result['data'] as ActiveSessionModel?;
      state = state.copyWith(
        isLoading: false,
        activeSession: session,
        currentSlotIndex: session?.currentSlotIndex ?? 0,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<void> loadSessionDetail(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.getSessionDetail(sessionId);

    if (!mounted) return;

    if (result['success'] == true) {
      final session = result['data'] as ActiveSessionModel;
      state = state.copyWith(
        isLoading: false,
        activeSession: session,
        currentSlotIndex: session.currentSlotIndex,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
    }
  }

  Future<bool> startSession(String planSessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.startSession(planSessionId);

    if (!mounted) return false;

    if (result['success'] == true) {
      final session = result['data'] as ActiveSessionModel;
      state = state.copyWith(
        isLoading: false,
        activeSession: session,
        currentSlotIndex: session.currentSlotIndex,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> logSet({
    required String slotId,
    required int setNumber,
    required int completedReps,
    required double loadValue,
    required String loadUnit,
    double? rpe,
    String? notes,
  }) async {
    final session = state.activeSession;
    if (session == null) return false;

    state = state.copyWith(isLoggingSet: true, error: null);

    final restActualSeconds =
        state.isResting ? state.restSecondsTotal - state.restSecondsRemaining : null;

    _cancelRestTimer();

    final result = await _repo.logSet(
      sessionId: session.activeSessionId,
      slotId: slotId,
      setNumber: setNumber,
      completedReps: completedReps,
      loadValue: loadValue,
      loadUnit: loadUnit,
      rpe: rpe,
      restActualSeconds: restActualSeconds,
      notes: notes,
    );

    if (!mounted) return false;

    if (result['success'] == true) {
      final updated = result['data'] as ActiveSessionModel;
      state = state.copyWith(
        isLoggingSet: false,
        activeSession: updated,
        currentSlotIndex: updated.currentSlotIndex,
      );

      // Auto-start rest timer if there are pending sets
      if (updated.pendingSets > 0) {
        _autoStartRest(updated);
      }

      return true;
    } else {
      state = state.copyWith(
        isLoggingSet: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> skipSet({
    required String slotId,
    required int setNumber,
    String? reason,
  }) async {
    final session = state.activeSession;
    if (session == null) return false;

    state = state.copyWith(isLoggingSet: true, error: null);

    _cancelRestTimer();

    final result = await _repo.skipSet(
      sessionId: session.activeSessionId,
      slotId: slotId,
      setNumber: setNumber,
      reason: reason,
    );

    if (!mounted) return false;

    if (result['success'] == true) {
      final updated = result['data'] as ActiveSessionModel;
      state = state.copyWith(
        isLoggingSet: false,
        activeSession: updated,
        currentSlotIndex: updated.currentSlotIndex,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoggingSet: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> completeSession() async {
    final session = state.activeSession;
    if (session == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    _cancelRestTimer();

    final result = await _repo.completeSession(session.activeSessionId);

    if (!mounted) return false;

    if (result['success'] == true) {
      final summary = result['data'] as SessionSummaryModel;
      state = state.copyWith(
        isLoading: false,
        summary: summary,
        activeSession: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  Future<bool> abandonSession({String? reason}) async {
    final session = state.activeSession;
    if (session == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    _cancelRestTimer();

    final result = await _repo.abandonSession(
      session.activeSessionId,
      reason: reason,
    );

    if (!mounted) return false;

    if (result['success'] == true) {
      state = state.copyWith(
        isLoading: false,
        activeSession: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }

  void startRestTimer(int totalSeconds) {
    _cancelRestTimer();
    state = state.copyWith(
      isResting: true,
      restSecondsRemaining: totalSeconds,
      restSecondsTotal: totalSeconds,
    );
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickRestTimer();
    });
  }

  void skipRestTimer() {
    _cancelRestTimer();
  }

  void setCurrentSlotIndex(int index) {
    final session = state.activeSession;
    if (session == null) return;
    if (index < 0 || index >= session.slots.length) return;
    state = state.copyWith(currentSlotIndex: index);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _tickRestTimer() {
    if (!mounted) {
      _restTimer?.cancel();
      return;
    }
    final remaining = state.restSecondsRemaining - 1;
    if (remaining <= 0) {
      _cancelRestTimer();
    } else {
      state = state.copyWith(restSecondsRemaining: remaining);
    }
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    if (mounted) {
      state = state.copyWith(
        isResting: false,
        restSecondsRemaining: 0,
        restSecondsTotal: 0,
      );
    }
  }

  void _autoStartRest(ActiveSessionModel session) {
    // Find current slot and its last completed set to get rest prescription
    final currentSlot = session.currentSlot;
    if (currentSlot == null) return;

    final completedSets =
        currentSlot.sets.where((s) => s.isCompleted).toList();
    if (completedSets.isEmpty) return;

    final lastCompleted = completedSets.last;
    final restSeconds = lastCompleted.restPrescribedSeconds;
    if (restSeconds != null && restSeconds > 0) {
      startRestTimer(restSeconds);
    }
  }
}
