import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/feedback_models.dart';
import '../../data/repositories/feedback_repository.dart';

/// Repository provider for session feedback.
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FeedbackRepository(apiClient);
});

/// Fetches feedback history (paginated).
final feedbackListProvider =
    FutureProvider.autoDispose<List<SessionFeedbackModel>>((ref) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  final result = await repo.listFeedback();

  if (result['success'] == true) {
    return result['feedback'] as List<SessionFeedbackModel>;
  }

  throw Exception(result['error'] as String? ?? 'Failed to load feedback');
});

/// Fetches feedback for a specific session.
final feedbackForSessionProvider = FutureProvider.autoDispose
    .family<SessionFeedbackModel?, int>((ref, sessionPk) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  final result = await repo.getFeedbackForSession(sessionPk);

  if (result['success'] == true) {
    return result['feedback'] as SessionFeedbackModel;
  }

  return null;
});

/// Fetches pain events with optional body region filter.
final painEventsProvider = FutureProvider.autoDispose
    .family<List<PainEventModel>, String?>((ref, bodyRegion) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  final result = await repo.listPainEvents(bodyRegion: bodyRegion);

  if (result['success'] == true) {
    return result['pain_events'] as List<PainEventModel>;
  }

  throw Exception(result['error'] as String? ?? 'Failed to load pain events');
});

/// Provider for submitting session feedback.
final submitFeedbackProvider = StateNotifierProvider.autoDispose<
    SubmitFeedbackNotifier, AsyncValue<FeedbackSubmitResult?>>((ref) {
  final repo = ref.watch(feedbackRepositoryProvider);
  return SubmitFeedbackNotifier(repo, ref);
});

class SubmitFeedbackNotifier
    extends StateNotifier<AsyncValue<FeedbackSubmitResult?>> {
  final FeedbackRepository _repo;
  final Ref _ref;

  SubmitFeedbackNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<FeedbackSubmitResult?> submit({
    required int sessionPk,
    required String completionState,
    required Map<String, int> ratings,
    List<String> frictionReasons = const [],
    bool recoveryConcern = false,
    String notes = '',
    List<Map<String, dynamic>> painEvents = const [],
  }) async {
    state = const AsyncValue.loading();

    final result = await _repo.submitFeedback(
      sessionPk: sessionPk,
      completionState: completionState,
      ratings: ratings,
      frictionReasons: frictionReasons,
      recoveryConcern: recoveryConcern,
      notes: notes,
      painEvents: painEvents,
    );

    if (result['success'] == true) {
      final submitResult = result['result'] as FeedbackSubmitResult;
      state = AsyncValue.data(submitResult);
      _ref.invalidate(feedbackListProvider);
      return submitResult;
    }

    final error = result['error'] as String? ?? 'Submit failed';
    state = AsyncValue.error(error, StackTrace.current);
    return null;
  }
}

/// Provider for logging standalone pain events.
final logPainEventProvider = StateNotifierProvider.autoDispose<
    LogPainEventNotifier, AsyncValue<PainEventModel?>>((ref) {
  final repo = ref.watch(feedbackRepositoryProvider);
  return LogPainEventNotifier(repo, ref);
});

class LogPainEventNotifier
    extends StateNotifier<AsyncValue<PainEventModel?>> {
  final FeedbackRepository _repo;
  final Ref _ref;

  LogPainEventNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<PainEventModel?> log({
    required String bodyRegion,
    required int painScore,
    String? side,
    String? sensationType,
    String? onsetPhase,
    String? warmupEffect,
    int? exerciseId,
    int? activeSessionId,
    String notes = '',
  }) async {
    state = const AsyncValue.loading();

    final result = await _repo.logPainEvent(
      bodyRegion: bodyRegion,
      painScore: painScore,
      side: side,
      sensationType: sensationType,
      onsetPhase: onsetPhase,
      warmupEffect: warmupEffect,
      exerciseId: exerciseId,
      activeSessionId: activeSessionId,
      notes: notes,
    );

    if (result['success'] == true) {
      final painEvent = result['pain_event'] as PainEventModel;
      state = AsyncValue.data(painEvent);
      _ref.invalidate(painEventsProvider);
      return painEvent;
    }

    final error = result['error'] as String? ?? 'Log failed';
    state = AsyncValue.error(error, StackTrace.current);
    return null;
  }
}
