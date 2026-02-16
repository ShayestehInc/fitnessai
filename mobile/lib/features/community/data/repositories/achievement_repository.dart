import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/achievement_model.dart';

/// Repository for achievement-related API calls.
class AchievementRepository {
  final ApiClient _apiClient;

  AchievementRepository(this._apiClient);

  /// Fetch all achievements with earned status for the current user.
  Future<List<AchievementModel>> getAchievements() async {
    final response = await _apiClient.dio.get(ApiConstants.communityAchievements);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the 5 most recently earned achievements.
  Future<List<NewAchievementModel>> getRecentAchievements() async {
    final response = await _apiClient.dio.get(ApiConstants.communityAchievementsRecent);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => NewAchievementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
