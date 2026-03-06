import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/space_model.dart';

/// Repository for Space API calls.
class SpaceRepository {
  final ApiClient _apiClient;

  SpaceRepository(this._apiClient);

  /// Fetch all spaces for the current trainer group.
  Future<List<SpaceModel>> getSpaces() async {
    final response = await _apiClient.dio.get(ApiConstants.communitySpaces);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SpaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create a new space (trainer only).
  Future<SpaceModel> createSpace({
    required String name,
    String description = '',
    String emoji = '💬',
    String visibility = 'public',
    bool isDefault = false,
    int sortOrder = 0,
    String? coverImagePath,
  }) async {
    if (coverImagePath != null) {
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'emoji': emoji,
        'visibility': visibility,
        'is_default': isDefault,
        'sort_order': sortOrder,
        'cover_image': await MultipartFile.fromFile(coverImagePath),
      });
      final response = await _apiClient.dio.post(
        ApiConstants.communitySpaces,
        data: formData,
      );
      return SpaceModel.fromJson(response.data as Map<String, dynamic>);
    }

    final response = await _apiClient.dio.post(
      ApiConstants.communitySpaces,
      data: {
        'name': name,
        'description': description,
        'emoji': emoji,
        'visibility': visibility,
        'is_default': isDefault,
        'sort_order': sortOrder,
      },
    );
    return SpaceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get space detail.
  Future<SpaceModel> getSpace(int spaceId) async {
    final response = await _apiClient.dio.get(
      ApiConstants.communitySpaceDetail(spaceId),
    );
    return SpaceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update a space (trainer only).
  Future<SpaceModel> updateSpace({
    required int spaceId,
    String? name,
    String? description,
    String? emoji,
    String? visibility,
    bool? isDefault,
    int? sortOrder,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (emoji != null) data['emoji'] = emoji;
    if (visibility != null) data['visibility'] = visibility;
    if (isDefault != null) data['is_default'] = isDefault;
    if (sortOrder != null) data['sort_order'] = sortOrder;

    final response = await _apiClient.dio.put(
      ApiConstants.communitySpaceDetail(spaceId),
      data: data,
    );
    return SpaceModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a space (trainer only).
  Future<void> deleteSpace(int spaceId) async {
    await _apiClient.dio.delete(ApiConstants.communitySpaceDetail(spaceId));
  }

  /// Join a space.
  Future<void> joinSpace(int spaceId) async {
    await _apiClient.dio.post(ApiConstants.communitySpaceJoin(spaceId));
  }

  /// Leave a space.
  Future<void> leaveSpace(int spaceId) async {
    await _apiClient.dio.post(ApiConstants.communitySpaceLeave(spaceId));
  }

  /// Get space members.
  Future<List<SpaceMembershipModel>> getMembers(int spaceId) async {
    final response = await _apiClient.dio.get(
      ApiConstants.communitySpaceMembers(spaceId),
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => SpaceMembershipModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
