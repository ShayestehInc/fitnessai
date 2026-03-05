import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/share_card_model.dart';
import '../../data/repositories/sharing_repository.dart';

final sharingRepositoryProvider = Provider<SharingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SharingRepository(apiClient);
});

/// Fetches share card data for a given workout log ID.
/// Automatically disposes when no longer watched.
final shareCardProvider = FutureProvider.autoDispose
    .family<ShareCardModel, int>((ref, logId) async {
  final repository = ref.watch(sharingRepositoryProvider);
  final result = await repository.fetchShareCard(logId);

  if (result['success'] == true) {
    return result['data'] as ShareCardModel;
  }

  throw Exception(result['error'] ?? 'Failed to load share card');
});
