import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/event_model.dart';

class EventRepository {
  final ApiClient _apiClient;

  EventRepository(this._apiClient);

  // ── Trainee endpoints ──

  Future<List<CommunityEventModel>> getEvents() async {
    final response = await _apiClient.dio.get(ApiConstants.communityEvents);
    final results = response.data as List<dynamic>;
    return results
        .map((e) =>
            CommunityEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityEventModel> getEventDetail(int eventId) async {
    final response = await _apiClient.dio.get(
      ApiConstants.communityEventDetail(eventId),
    );
    return CommunityEventModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CommunityEventModel> rsvp(int eventId, RsvpStatus status) async {
    final response = await _apiClient.dio.post(
      ApiConstants.communityEventRsvp(eventId),
      data: {'status': status.apiValue},
    );
    return CommunityEventModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ── Trainer endpoints ──

  Future<List<CommunityEventModel>> getTrainerEvents() async {
    final response = await _apiClient.dio.get(ApiConstants.trainerEvents);
    final results = response.data as List<dynamic>;
    return results
        .map((e) =>
            CommunityEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityEventModel> createEvent({
    required String title,
    required String eventType,
    required DateTime startsAt,
    required DateTime endsAt,
    String description = '',
    String meetingUrl = '',
    int? maxAttendees,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.trainerEvents,
      data: {
        'title': title,
        'event_type': eventType,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt.toUtc().toIso8601String(),
        'description': description,
        'meeting_url': meetingUrl,
        if (maxAttendees != null) 'max_attendees': maxAttendees,
      },
    );
    return CommunityEventModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CommunityEventModel> updateEvent(
    int eventId, {
    String? title,
    String? description,
    String? eventType,
    DateTime? startsAt,
    DateTime? endsAt,
    String? meetingUrl,
    int? maxAttendees,
    bool clearMaxAttendees = false,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (eventType != null) data['event_type'] = eventType;
    if (startsAt != null) {
      data['starts_at'] = startsAt.toUtc().toIso8601String();
    }
    if (endsAt != null) {
      data['ends_at'] = endsAt.toUtc().toIso8601String();
    }
    if (meetingUrl != null) data['meeting_url'] = meetingUrl;
    if (clearMaxAttendees) {
      data['max_attendees'] = null;
    } else if (maxAttendees != null) {
      data['max_attendees'] = maxAttendees;
    }

    final response = await _apiClient.dio.put(
      ApiConstants.trainerEventDetail(eventId),
      data: data,
    );
    return CommunityEventModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteEvent(int eventId) async {
    await _apiClient.dio.delete(ApiConstants.trainerEventDetail(eventId));
  }

  Future<CommunityEventModel> updateEventStatus(
    int eventId,
    String newStatus,
  ) async {
    final response = await _apiClient.dio.patch(
      ApiConstants.trainerEventStatus(eventId),
      data: {'status': newStatus},
    );
    return CommunityEventModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
