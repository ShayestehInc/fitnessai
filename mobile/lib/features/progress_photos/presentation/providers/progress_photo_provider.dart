import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/progress_photo_model.dart';
import '../../data/repositories/progress_photo_repository.dart';

/// Repository provider for progress photos.
final progressPhotoRepositoryProvider =
    Provider<ProgressPhotoRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgressPhotoRepository(apiClient);
});

/// Currently selected category filter for the gallery.
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

/// Fetches progress photos filtered by category and optional trainee ID.
/// Uses a family provider keyed by trainee ID to avoid global state leaks.
/// Pass `null` for the trainee's own photos, or a trainee ID for trainer view.
final photosProvider = FutureProvider.autoDispose
    .family<List<ProgressPhotoModel>, int?>((ref, traineeId) async {
  final repo = ref.watch(progressPhotoRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);

  final result = await repo.fetchPhotos(
    category: category == 'all' ? null : category,
    traineeId: traineeId,
  );

  if (result['success'] == true) {
    return result['photos'] as List<ProgressPhotoModel>;
  }

  throw Exception(result['error'] as String? ?? 'Failed to load photos');
});

/// Provider for uploading a progress photo.
final uploadPhotoProvider =
    StateNotifierProvider.autoDispose<UploadPhotoNotifier, AsyncValue<void>>(
  (ref) {
    final repo = ref.watch(progressPhotoRepositoryProvider);
    return UploadPhotoNotifier(repo, ref);
  },
);

class UploadPhotoNotifier extends StateNotifier<AsyncValue<void>> {
  final ProgressPhotoRepository _repo;
  final Ref _ref;

  UploadPhotoNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<bool> upload({
    required String filePath,
    required String category,
    required String date,
    Map<String, double> measurements = const {},
    String notes = '',
  }) async {
    state = const AsyncValue.loading();

    final result = await _repo.uploadPhoto(
      filePath: filePath,
      category: category,
      date: date,
      measurements: measurements,
      notes: notes,
    );

    if (result['success'] == true) {
      state = const AsyncValue.data(null);
      // Invalidate both own photos and any trainee-scoped photos.
      _ref.invalidate(photosProvider);
      return true;
    }

    final error = result['error'] as String? ?? 'Upload failed';
    state = AsyncValue.error(error, StackTrace.current);
    return false;
  }
}

/// Provider for comparing two progress photos.
final comparePhotosProvider = FutureProvider.autoDispose
    .family<PhotoComparisonResult, ({int photo1Id, int photo2Id})>(
  (ref, params) async {
    final repo = ref.watch(progressPhotoRepositoryProvider);

    final result = await repo.comparePhotos(
      photo1Id: params.photo1Id,
      photo2Id: params.photo2Id,
    );

    if (result['success'] == true) {
      return result['comparison'] as PhotoComparisonResult;
    }

    throw Exception(result['error'] as String? ?? 'Comparison failed');
  },
);

/// Provider for deleting a progress photo.
final deletePhotoProvider =
    StateNotifierProvider.autoDispose
        .family<DeletePhotoNotifier, AsyncValue<void>, int?>(
  (ref, traineeId) {
    final repo = ref.watch(progressPhotoRepositoryProvider);
    return DeletePhotoNotifier(repo, ref, traineeId);
  },
);

class DeletePhotoNotifier extends StateNotifier<AsyncValue<void>> {
  final ProgressPhotoRepository _repo;
  final Ref _ref;
  final int? _traineeId;

  DeletePhotoNotifier(this._repo, this._ref, this._traineeId)
      : super(const AsyncValue.data(null));

  Future<bool> delete(int photoId) async {
    state = const AsyncValue.loading();

    final result = await _repo.deletePhoto(photoId);

    if (result['success'] == true) {
      state = const AsyncValue.data(null);
      _ref.invalidate(photosProvider);
      return true;
    }

    final error = result['error'] as String? ?? 'Delete failed';
    state = AsyncValue.error(error, StackTrace.current);
    return false;
  }
}
