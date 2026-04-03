import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/video_message_model.dart';
import '../../data/repositories/video_message_repository.dart';

/// Repository provider for video messages.
final videoMessageRepositoryProvider =
    Provider<VideoMessageRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VideoMessageRepository(apiClient);
});

/// State for an active recording session.
class RecordingSessionState {
  final String? assetId;
  final bool isStarting;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  const RecordingSessionState({
    this.assetId,
    this.isStarting = false,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
  });

  RecordingSessionState copyWith({
    String? assetId,
    bool? isStarting,
    bool? isUploading,
    double? uploadProgress,
    String? error,
  }) {
    return RecordingSessionState(
      assetId: assetId ?? this.assetId,
      isStarting: isStarting ?? this.isStarting,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
    );
  }
}

/// Notifier managing the recording session lifecycle.
final recordingSessionProvider = StateNotifierProvider.autoDispose<
    RecordingSessionNotifier, RecordingSessionState>((ref) {
  final repo = ref.watch(videoMessageRepositoryProvider);
  return RecordingSessionNotifier(repo);
});

class RecordingSessionNotifier extends StateNotifier<RecordingSessionState> {
  final VideoMessageRepository _repo;

  RecordingSessionNotifier(this._repo)
      : super(const RecordingSessionState());

  /// Call backend to create a pending asset when recording starts.
  Future<String?> startSession({
    required String captureMode,
    int? traineeId,
  }) async {
    state = state.copyWith(isStarting: true, error: null);

    final result = await _repo.startRecording(
      captureMode: captureMode,
      traineeId: traineeId,
    );

    if (result['success'] == true) {
      final startResult = result['result'] as VideoMessageStartResult;
      state = state.copyWith(
        assetId: startResult.assetId,
        isStarting: false,
      );
      return startResult.assetId;
    }

    state = state.copyWith(
      isStarting: false,
      error: result['error'] as String?,
    );
    return null;
  }

  /// Upload the recorded video file to the backend.
  Future<bool> uploadVideo({
    required String filePath,
    required double durationSeconds,
    String orientation = 'portrait',
  }) async {
    final assetId = state.assetId;
    if (assetId == null) {
      state = state.copyWith(error: 'No active recording session');
      return false;
    }

    state = state.copyWith(isUploading: true, error: null);

    final result = await _repo.uploadVideoFile(
      assetId: assetId,
      filePath: filePath,
      durationSeconds: durationSeconds,
      orientation: orientation,
    );

    if (result['success'] == true) {
      state = state.copyWith(isUploading: false, uploadProgress: 1.0);
      return true;
    }

    state = state.copyWith(
      isUploading: false,
      error: result['error'] as String?,
    );
    return false;
  }

  /// Discard the current session (delete the backend asset).
  Future<void> discardSession() async {
    final assetId = state.assetId;
    if (assetId != null) {
      await _repo.deleteAsset(assetId);
    }
    state = const RecordingSessionState();
  }

  /// Reset state for a new recording.
  void reset() {
    state = const RecordingSessionState();
  }
}
