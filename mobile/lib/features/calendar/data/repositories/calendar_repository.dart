import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/calendar_connection_model.dart';

class CalendarRepository {
  final ApiClient _apiClient;

  CalendarRepository(this._apiClient);

  /// Get all calendar connections for the current user
  Future<List<CalendarConnectionModel>> getConnections() async {
    final response = await _apiClient.dio.get(ApiConstants.calendarConnections);
    final List<dynamic> data = response.data is List
        ? response.data
        : response.data['results'] ?? [];
    return data
        .map((json) => CalendarConnectionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get Google OAuth authorization URL
  Future<String> getGoogleAuthUrl() async {
    final response = await _apiClient.dio.get(ApiConstants.googleAuthUrl);
    return response.data['auth_url'] as String;
  }

  /// Complete Google OAuth callback
  Future<CalendarConnectionModel> completeGoogleCallback({
    required String code,
    required String state,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.googleCallback,
      data: {'code': code, 'state': state},
    );
    return CalendarConnectionModel.fromJson(
        response.data['connection'] as Map<String, dynamic>);
  }

  /// Get Microsoft OAuth authorization URL
  Future<String> getMicrosoftAuthUrl() async {
    final response = await _apiClient.dio.get(ApiConstants.microsoftAuthUrl);
    return response.data['auth_url'] as String;
  }

  /// Complete Microsoft OAuth callback
  Future<CalendarConnectionModel> completeMicrosoftCallback({
    required String code,
    required String state,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.microsoftCallback,
      data: {'code': code, 'state': state},
    );
    return CalendarConnectionModel.fromJson(
        response.data['connection'] as Map<String, dynamic>);
  }

  /// Disconnect a calendar
  Future<void> disconnectCalendar(String provider) async {
    await _apiClient.dio.post(ApiConstants.calendarDisconnect(provider));
  }

  /// Sync calendar events
  Future<SyncResult> syncCalendar(String provider) async {
    final response = await _apiClient.dio.post(ApiConstants.calendarSync(provider));
    return SyncResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get calendar events with optional provider filter.
  ///
  /// Automatically fetches all pages from the paginated backend endpoint
  /// to present a complete event list. Bounded by [maxPages] to prevent
  /// runaway requests (default: 10 pages = ~200 events).
  Future<List<CalendarEventModel>> getEvents({
    String? provider,
    int maxPages = 10,
  }) async {
    final queryParams = <String, dynamic>{};
    if (provider != null) {
      queryParams['provider'] = provider;
    }

    final allEvents = <CalendarEventModel>[];
    String? nextUrl;
    int page = 0;

    do {
      final response = nextUrl != null
          ? await _apiClient.dio.get(nextUrl)
          : await _apiClient.dio.get(
              ApiConstants.calendarEvents,
              queryParameters: queryParams,
            );

      final List<dynamic> data;
      if (response.data is List) {
        data = response.data;
        nextUrl = null;
      } else {
        data = response.data['results'] ?? [];
        nextUrl = response.data['next'] as String?;
      }

      allEvents.addAll(
        data.map(
          (json) =>
              CalendarEventModel.fromJson(json as Map<String, dynamic>),
        ),
      );
      page++;
    } while (nextUrl != null && page < maxPages);

    return allEvents;
  }

  /// Create a calendar event
  Future<CalendarEventModel> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    String? provider,
    List<String>? attendeeEmails,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.calendarEventCreate,
      data: {
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (provider != null) 'provider': provider,
        if (attendeeEmails != null && attendeeEmails.isNotEmpty)
          'attendee_emails': attendeeEmails,
      },
    );
    return CalendarEventModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get trainer availability slots
  Future<List<TrainerAvailabilityModel>> getAvailability() async {
    final response = await _apiClient.dio.get(ApiConstants.trainerAvailability);
    final List<dynamic> data = response.data is List
        ? response.data
        : response.data['results'] ?? [];
    return data
        .map((json) => TrainerAvailabilityModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create availability slot
  Future<TrainerAvailabilityModel> createAvailability({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) async {
    final response = await _apiClient.dio.post(
      ApiConstants.trainerAvailability,
      data: {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': isActive,
      },
    );
    return TrainerAvailabilityModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update availability slot
  Future<TrainerAvailabilityModel> updateAvailability(
    int id, {
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (dayOfWeek != null) data['day_of_week'] = dayOfWeek;
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (isActive != null) data['is_active'] = isActive;

    final response = await _apiClient.dio.patch(
      ApiConstants.trainerAvailabilityDetail(id),
      data: data,
    );
    return TrainerAvailabilityModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete availability slot
  Future<void> deleteAvailability(int id) async {
    await _apiClient.dio.delete(ApiConstants.trainerAvailabilityDetail(id));
  }
}
