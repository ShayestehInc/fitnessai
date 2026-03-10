import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/auto_tag_model.dart';
import '../../data/repositories/auto_tag_repository.dart';

final autoTagRepositoryProvider = Provider<AutoTagRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AutoTagRepository(apiClient);
});

final autoTagDraftProvider = FutureProvider.autoDispose
    .family<AutoTagDraftModel?, int>((ref, exerciseId) async {
  final repository = ref.watch(autoTagRepositoryProvider);
  final result = await repository.getAutoTagDraft(exerciseId);
  if (result['success'] == true) {
    return result['data'] as AutoTagDraftModel?;
  }
  throw Exception(result['error'] ?? 'Failed to load auto-tag draft');
});

final tagHistoryProvider = FutureProvider.autoDispose
    .family<List<TagHistoryEntryModel>, int>((ref, exerciseId) async {
  final repository = ref.watch(autoTagRepositoryProvider);
  final result = await repository.getTagHistory(exerciseId);
  if (result['success'] == true) {
    return result['data'] as List<TagHistoryEntryModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load tag history');
});
