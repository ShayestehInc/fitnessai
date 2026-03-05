import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/checkin_models.dart';
import '../../data/repositories/checkin_repository.dart';

final checkinRepositoryProvider = Provider<CheckInRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CheckInRepository(apiClient);
});

/// Fetches all check-in templates for the current trainer.
final templatesProvider =
    FutureProvider.autoDispose<List<CheckInTemplateModel>>((ref) async {
  final repository = ref.watch(checkinRepositoryProvider);
  final result = await repository.fetchTemplates();

  if (result['success'] == true) {
    return result['data'] as List<CheckInTemplateModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load templates');
});

/// Fetches pending check-in assignments for the current trainee.
final pendingCheckInsProvider =
    FutureProvider.autoDispose<List<CheckInAssignmentModel>>((ref) async {
  final repository = ref.watch(checkinRepositoryProvider);
  final result = await repository.fetchPendingAssignments();

  if (result['success'] == true) {
    return result['data'] as List<CheckInAssignmentModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load pending check-ins');
});

/// Fetches check-in responses, optionally filtered by trainee ID.
final responsesProvider = FutureProvider.autoDispose
    .family<List<CheckInResponseModel>, int?>((ref, traineeId) async {
  final repository = ref.watch(checkinRepositoryProvider);
  final result = await repository.fetchResponses(traineeId: traineeId);

  if (result['success'] == true) {
    return result['data'] as List<CheckInResponseModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load responses');
});
