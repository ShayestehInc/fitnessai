import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../exercises/data/models/exercise_model.dart';
import '../models/muscle_reference_model.dart';

class AnatomyRepository {
  final ApiClient _apiClient;

  const AnatomyRepository(this._apiClient);

  Future<List<MuscleReferenceModel>> getMuscleReferences() async {
    final response = await _apiClient.dio.get(ApiConstants.muscles);
    final List<dynamic> data = response.data is List
        ? response.data as List<dynamic>
        : (response.data as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
    return data
        .map((json) => MuscleReferenceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MuscleReferenceModel> getMuscleDetail(String slug) async {
    final response = await _apiClient.dio.get(ApiConstants.muscleDetail(slug));
    return MuscleReferenceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ExerciseModel>> getMuscleExercises(String slug) async {
    final response = await _apiClient.dio.get(ApiConstants.muscleExercises(slug));
    final List<dynamic> data = response.data is List
        ? response.data as List<dynamic>
        : (response.data as Map<String, dynamic>)['results'] as List<dynamic>? ?? [];
    return data
        .map((json) => ExerciseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MuscleCoverageModel> getMuscleCoverage({
    String period = 'week',
    String? sessionDate,
  }) async {
    final queryParams = <String, String>{'period': period};
    if (sessionDate != null) {
      queryParams['session_date'] = sessionDate;
    }
    final response = await _apiClient.dio.get(
      ApiConstants.muscleCoverage,
      queryParameters: queryParams,
    );
    return MuscleCoverageModel.fromJson(response.data as Map<String, dynamic>);
  }
}
