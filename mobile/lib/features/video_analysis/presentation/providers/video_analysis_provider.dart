import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/video_analysis_model.dart';
import '../../data/repositories/video_analysis_repository.dart';

/// Repository provider for video analysis.
final videoAnalysisRepositoryProvider =
    Provider<VideoAnalysisRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VideoAnalysisRepository(apiClient);
});

/// Fetches the list of video analyses.
final videoAnalysisListProvider =
    FutureProvider.autoDispose<List<VideoAnalysisModel>>((ref) async {
  final repo = ref.watch(videoAnalysisRepositoryProvider);
  final result = await repo.listAnalyses();

  if (result['success'] == true) {
    return result['analyses'] as List<VideoAnalysisModel>;
  }

  throw Exception(
    result['error'] as String? ?? 'Failed to load video analyses',
  );
});

/// Fetches detail of a specific video analysis.
final videoAnalysisDetailProvider = FutureProvider.autoDispose
    .family<VideoAnalysisModel, int>((ref, analysisId) async {
  final repo = ref.watch(videoAnalysisRepositoryProvider);
  final result = await repo.getDetail(analysisId);

  if (result['success'] == true) {
    return result['analysis'] as VideoAnalysisModel;
  }

  throw Exception(
    result['error'] as String? ?? 'Failed to load analysis detail',
  );
});

/// Provider for uploading a video for analysis.
final uploadVideoAnalysisProvider = StateNotifierProvider.autoDispose<
    UploadVideoAnalysisNotifier, AsyncValue<VideoAnalysisModel?>>((ref) {
  final repo = ref.watch(videoAnalysisRepositoryProvider);
  return UploadVideoAnalysisNotifier(repo, ref);
});

class UploadVideoAnalysisNotifier
    extends StateNotifier<AsyncValue<VideoAnalysisModel?>> {
  final VideoAnalysisRepository _repo;
  final Ref _ref;

  UploadVideoAnalysisNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<VideoAnalysisModel?> upload({
    required String filePath,
    int? exerciseId,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repo.uploadVideo(
      filePath: filePath,
      exerciseId: exerciseId,
    );

    if (result['success'] == true) {
      final analysis = result['analysis'] as VideoAnalysisModel;
      state = AsyncValue.data(analysis);
      _ref.invalidate(videoAnalysisListProvider);
      return analysis;
    }

    final error = result['error'] as String? ?? 'Upload failed';
    state = AsyncValue.error(error, StackTrace.current);
    return null;
  }
}

/// Provider for confirming suggestions on an analysis.
final confirmSuggestionsProvider = StateNotifierProvider.autoDispose
    .family<ConfirmSuggestionsNotifier, AsyncValue<void>, int>((ref, id) {
  final repo = ref.watch(videoAnalysisRepositoryProvider);
  return ConfirmSuggestionsNotifier(repo, ref, id);
});

class ConfirmSuggestionsNotifier extends StateNotifier<AsyncValue<void>> {
  final VideoAnalysisRepository _repo;
  final Ref _ref;
  final int _analysisId;

  ConfirmSuggestionsNotifier(this._repo, this._ref, this._analysisId)
      : super(const AsyncValue.data(null));

  Future<bool> confirm() async {
    state = const AsyncValue.loading();

    final result = await _repo.confirmSuggestions(_analysisId);

    if (result['success'] == true) {
      state = const AsyncValue.data(null);
      _ref.invalidate(videoAnalysisDetailProvider(_analysisId));
      _ref.invalidate(videoAnalysisListProvider);
      return true;
    }

    final error = result['error'] as String? ?? 'Confirmation failed';
    state = AsyncValue.error(error, StackTrace.current);
    return false;
  }
}
