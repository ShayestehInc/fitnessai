import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExerciseRepository(apiClient);
});

final exercisesProvider = FutureProvider.autoDispose.family<List<ExerciseModel>, ExerciseFilter>((ref, filter) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  final result = await repository.getExercises(
    muscleGroup: filter.muscleGroup,
    equipment: filter.equipment,
    search: filter.search,
    difficultyLevel: filter.difficultyLevel,
  );
  if (result['success']) {
    return result['data'] as List<ExerciseModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load exercises');
});

final selectedMuscleGroupProvider = StateProvider<String?>((ref) => null);
final exerciseSearchProvider = StateProvider<String>((ref) => '');

class ExerciseFilter {
  final String? muscleGroup;
  final String? equipment;
  final String? search;
  final String? difficultyLevel;

  const ExerciseFilter({this.muscleGroup, this.equipment, this.search, this.difficultyLevel});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilter &&
          runtimeType == other.runtimeType &&
          muscleGroup == other.muscleGroup &&
          equipment == other.equipment &&
          search == other.search &&
          difficultyLevel == other.difficultyLevel;

  @override
  int get hashCode => Object.hash(muscleGroup, equipment, search, difficultyLevel);
}
