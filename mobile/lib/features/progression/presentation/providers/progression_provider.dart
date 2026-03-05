import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/progression_models.dart';
import '../../data/repositories/progression_repository.dart';

final progressionRepositoryProvider = Provider<ProgressionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgressionRepository(apiClient);
});

/// Fetches pending progression suggestions for a program.
final progressionSuggestionsProvider = FutureProvider.autoDispose
    .family<List<ProgressionSuggestionModel>, int>((ref, programId) async {
  final repository = ref.watch(progressionRepositoryProvider);
  final result = await repository.fetchSuggestions(programId);
  if (result['success'] == true) {
    return result['data'] as List<ProgressionSuggestionModel>;
  }
  throw Exception(
    result['error'] ?? 'Failed to load progression suggestions',
  );
});

/// Checks deload recommendation for a program.
final deloadCheckProvider = FutureProvider.autoDispose
    .family<DeloadRecommendationModel, int>((ref, programId) async {
  final repository = ref.watch(progressionRepositoryProvider);
  final result = await repository.checkDeload(programId);
  if (result['success'] == true) {
    return result['data'] as DeloadRecommendationModel;
  }
  throw Exception(
    result['error'] ?? 'Failed to check deload status',
  );
});
