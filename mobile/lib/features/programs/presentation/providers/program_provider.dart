import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/program_model.dart';
import '../../data/repositories/program_repository.dart';

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgramRepository(apiClient);
});

final programTemplatesProvider = FutureProvider.autoDispose<List<ProgramTemplateModel>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  final result = await repository.getProgramTemplates();
  if (result['success']) {
    return result['data'] as List<ProgramTemplateModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load program templates');
});

final traineeProgramsProvider = FutureProvider.autoDispose.family<List<TraineeProgramModel>, int>((ref, traineeId) async {
  final repository = ref.watch(programRepositoryProvider);
  final result = await repository.getTraineePrograms(traineeId);
  if (result['success']) {
    return result['data'] as List<TraineeProgramModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load trainee programs');
});

/// All programs created by the trainer (assigned to their trainees)
final trainerProgramsProvider = FutureProvider.autoDispose<List<TraineeProgramModel>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  final result = await repository.getAllTrainerPrograms();
  if (result['success']) {
    return result['data'] as List<TraineeProgramModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load trainer programs');
});

/// Trainer's custom templates (non-public)
final myTemplatesProvider = FutureProvider.autoDispose<List<ProgramTemplateModel>>((ref) async {
  final repository = ref.watch(programRepositoryProvider);
  final result = await repository.getMyTemplates();
  if (result['success']) {
    return result['data'] as List<ProgramTemplateModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load templates');
});
