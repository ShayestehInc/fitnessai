import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/announcement_model.dart';

/// Repository for announcement-related API calls.
class AnnouncementRepository {
  final ApiClient _apiClient;

  AnnouncementRepository(this._apiClient);

  /// Fetch trainee's announcements from their trainer.
  Future<List<AnnouncementModel>> getAnnouncements() async {
    final response = await _apiClient.dio.get(ApiConstants.communityAnnouncements);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get unread announcement count.
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(ApiConstants.communityAnnouncementsUnread);
    final data = response.data as Map<String, dynamic>;
    return data['unread_count'] as int? ?? 0;
  }

  /// Mark all announcements as read.
  Future<void> markAllRead() async {
    await _apiClient.dio.post(ApiConstants.communityAnnouncementsMarkRead, data: {});
  }

  // --- Trainer endpoints ---

  /// Fetch trainer's own announcements.
  Future<List<AnnouncementModel>> getTrainerAnnouncements() async {
    final response = await _apiClient.dio.get(ApiConstants.trainerAnnouncements);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new announcement (trainer only).
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.trainerAnnouncements,
      data: {
        'title': title,
        'body': body,
        'is_pinned': isPinned,
      },
    );
    return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update an existing announcement (trainer only).
  Future<AnnouncementModel> updateAnnouncement({
    required int id,
    required String title,
    required String body,
    bool isPinned = false,
  }) async {
    final response = await _apiClient.dio.put(
      ApiConstants.trainerAnnouncementDetail(id),
      data: {
        'title': title,
        'body': body,
        'is_pinned': isPinned,
      },
    );
    return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete an announcement (trainer only).
  Future<void> deleteAnnouncement(int id) async {
    await _apiClient.dio.delete(ApiConstants.trainerAnnouncementDetail(id));
  }
}
