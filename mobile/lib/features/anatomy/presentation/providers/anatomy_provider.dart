import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../../data/models/muscle_reference_model.dart';
import '../../data/repositories/anatomy_repository.dart';

final anatomyRepositoryProvider = Provider<AnatomyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnatomyRepository(apiClient);
});

final muscleReferencesProvider =
    FutureProvider.autoDispose<List<MuscleReferenceModel>>((ref) async {
  final repo = ref.watch(anatomyRepositoryProvider);
  return repo.getMuscleReferences();
});

final muscleDetailProvider = FutureProvider.autoDispose
    .family<MuscleReferenceModel, String>((ref, slug) async {
  final repo = ref.watch(anatomyRepositoryProvider);
  return repo.getMuscleDetail(slug);
});

final muscleExercisesProvider = FutureProvider.autoDispose
    .family<List<ExerciseModel>, String>((ref, slug) async {
  final repo = ref.watch(anatomyRepositoryProvider);
  return repo.getMuscleExercises(slug);
});

final muscleCoverageProvider = FutureProvider.autoDispose
    .family<MuscleCoverageModel, String>((ref, period) async {
  final repo = ref.watch(anatomyRepositoryProvider);
  return repo.getMuscleCoverage(period: period);
});
