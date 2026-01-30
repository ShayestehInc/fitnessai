class CalendarConnectionModel {
  final int id;
  final String provider;
  final String providerDisplay;
  final String status;
  final String? calendarEmail;
  final String? calendarName;
  final bool syncEnabled;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;

  CalendarConnectionModel({
    required this.id,
    required this.provider,
    required this.providerDisplay,
    required this.status,
    this.calendarEmail,
    this.calendarName,
    required this.syncEnabled,
    this.lastSyncedAt,
    required this.createdAt,
  });

  factory CalendarConnectionModel.fromJson(Map<String, dynamic> json) {
    return CalendarConnectionModel(
      id: json['id'] as int,
      provider: json['provider'] as String,
      providerDisplay: json['provider_display'] as String? ?? json['provider'] as String,
      status: json['status'] as String,
      calendarEmail: json['calendar_email'] as String?,
      calendarName: json['calendar_name'] as String?,
      syncEnabled: json['sync_enabled'] as bool? ?? true,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isConnected => status == 'connected';
  bool get isGoogle => provider == 'google';
  bool get isMicrosoft => provider == 'microsoft';
}

class CalendarEventModel {
  final int id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String eventType;
  final bool isAllDay;
  final String? externalEventId;
  final DateTime? syncedAt;

  CalendarEventModel({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.eventType,
    required this.isAllDay,
    this.externalEventId,
    this.syncedAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      eventType: json['event_type'] as String,
      isAllDay: json['is_all_day'] as bool? ?? false,
      externalEventId: json['external_event_id'] as String?,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }
}

class TrainerAvailabilityModel {
  final int id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  TrainerAvailabilityModel({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory TrainerAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return TrainerAvailabilityModel(
      id: json['id'] as int,
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
    };
  }

  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 0 && dayOfWeek < 7) {
      return days[dayOfWeek];
    }
    return 'Unknown';
  }
}
