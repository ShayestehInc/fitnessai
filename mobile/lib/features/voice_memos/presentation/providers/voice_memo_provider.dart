import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/voice_memo_model.dart';
import '../../data/repositories/voice_memo_repository.dart';

/// Repository provider for voice memos.
final voiceMemoRepositoryProvider = Provider<VoiceMemoRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VoiceMemoRepository(apiClient);
});

/// Fetches the list of voice memos.
final voiceMemoListProvider =
    FutureProvider.autoDispose<List<VoiceMemoModel>>((ref) async {
  final repo = ref.watch(voiceMemoRepositoryProvider);
  final result = await repo.listMemos();

  if (result['success'] == true) {
    return result['memos'] as List<VoiceMemoModel>;
  }

  throw Exception(result['error'] as String? ?? 'Failed to load voice memos');
});

/// Fetches detail of a specific voice memo by integer id.
final voiceMemoDetailProvider = FutureProvider.autoDispose
    .family<VoiceMemoModel, int>((ref, id) async {
  final repo = ref.watch(voiceMemoRepositoryProvider);
  final result = await repo.getMemoDetail(id);

  if (result['success'] == true) {
    return result['memo'] as VoiceMemoModel;
  }

  throw Exception(result['error'] as String? ?? 'Failed to load memo detail');
});

/// Provider for uploading voice memos.
final uploadVoiceMemoProvider = StateNotifierProvider.autoDispose<
    UploadVoiceMemoNotifier, AsyncValue<VoiceMemoModel?>>((ref) {
  final repo = ref.watch(voiceMemoRepositoryProvider);
  return UploadVoiceMemoNotifier(repo, ref);
});

class UploadVoiceMemoNotifier
    extends StateNotifier<AsyncValue<VoiceMemoModel?>> {
  final VoiceMemoRepository _repo;
  final Ref _ref;

  UploadVoiceMemoNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<VoiceMemoModel?> upload({
    required String filePath,
    int? exerciseId,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repo.uploadMemo(
      filePath: filePath,
      exerciseId: exerciseId,
    );

    if (result['success'] == true) {
      final memo = result['memo'] as VoiceMemoModel;
      state = AsyncValue.data(memo);
      _ref.invalidate(voiceMemoListProvider);
      return memo;
    }

    final error = result['error'] as String? ?? 'Upload failed';
    state = AsyncValue.error(error, StackTrace.current);
    return null;
  }
}

/// Provider for deleting voice memos.
final deleteVoiceMemoProvider = StateNotifierProvider.autoDispose<
    DeleteVoiceMemoNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(voiceMemoRepositoryProvider);
  return DeleteVoiceMemoNotifier(repo, ref);
});

class DeleteVoiceMemoNotifier extends StateNotifier<AsyncValue<void>> {
  final VoiceMemoRepository _repo;
  final Ref _ref;

  DeleteVoiceMemoNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> delete(int memoId) async {
    state = const AsyncValue.loading();

    final result = await _repo.deleteMemo(memoId);

    if (result['success'] == true) {
      state = const AsyncValue.data(null);
      _ref.invalidate(voiceMemoListProvider);
      return true;
    }

    final error = result['error'] as String? ?? 'Delete failed';
    state = AsyncValue.error(error, StackTrace.current);
    return false;
  }
}
