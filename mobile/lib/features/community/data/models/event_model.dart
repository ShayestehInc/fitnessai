class CommunityEventModel {
  final int id;
  final String title;
  final String description;
  final String eventType;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;
  final String meetingUrl;
  final int? maxAttendees;
  final bool isRecurring;
  final int? spaceId;
  final Map<String, int> attendeeCounts;
  final String? myRsvp;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.meetingUrl,
    this.maxAttendees,
    required this.isRecurring,
    this.spaceId,
    required this.attendeeCounts,
    this.myRsvp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityEventModel.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['attendee_counts'] as Map<String, dynamic>?;
    final counts = <String, int>{
      'going': 0,
      'maybe': 0,
      'not_going': 0,
    };
    if (countsRaw != null) {
      for (final entry in countsRaw.entries) {
        counts[entry.key] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    return CommunityEventModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'other',
      status: json['status'] as String? ?? 'scheduled',
      startsAt: DateTime.parse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.parse(json['ends_at'] as String? ?? ''),
      meetingUrl: json['meeting_url'] as String? ?? '',
      maxAttendees: json['max_attendees'] as int?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      spaceId: json['space'] as int?,
      attendeeCounts: counts,
      myRsvp: json['my_rsvp'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  int get goingCount => attendeeCounts['going'] ?? 0;
  int get maybeCount => attendeeCounts['maybe'] ?? 0;

  bool get isCancelled => status == 'cancelled';
  bool get isLive => status == 'live';
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get isVirtual => meetingUrl.isNotEmpty;
  bool get isPast => endsAt.isBefore(DateTime.now());
  bool get isHappeningNow =>
      startsAt.isBefore(DateTime.now()) && endsAt.isAfter(DateTime.now());

  bool get isAtCapacity =>
      maxAttendees != null && goingCount >= maxAttendees!;

  bool get canJoinVirtual {
    if (!isVirtual || isCancelled) return false;
    final now = DateTime.now();
    final joinWindow = startsAt.subtract(const Duration(minutes: 15));
    return now.isAfter(joinWindow) && now.isBefore(endsAt);
  }

  String get eventTypeLabel {
    switch (eventType) {
      case 'live_session':
        return 'Live Session';
      case 'q_and_a':
        return 'Q&A';
      case 'workshop':
        return 'Workshop';
      case 'challenge':
        return 'Challenge';
      default:
        return 'Event';
    }
  }

  CommunityEventModel copyWith({
    String? myRsvp,
    Map<String, int>? attendeeCounts,
    String? status,
    bool clearRsvp = false,
  }) {
    return CommunityEventModel(
      id: id,
      title: title,
      description: description,
      eventType: eventType,
      status: status ?? this.status,
      startsAt: startsAt,
      endsAt: endsAt,
      meetingUrl: meetingUrl,
      maxAttendees: maxAttendees,
      isRecurring: isRecurring,
      spaceId: spaceId,
      attendeeCounts: attendeeCounts ?? this.attendeeCounts,
      myRsvp: clearRsvp ? null : (myRsvp ?? this.myRsvp),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

enum RsvpStatus {
  going,
  maybe,
  notGoing;

  String get apiValue {
    switch (this) {
      case RsvpStatus.going:
        return 'going';
      case RsvpStatus.maybe:
        return 'maybe';
      case RsvpStatus.notGoing:
        return 'not_going';
    }
  }

  static RsvpStatus? fromApi(String? value) {
    switch (value) {
      case 'going':
        return RsvpStatus.going;
      case 'maybe':
        return RsvpStatus.maybe;
      case 'not_going':
        return RsvpStatus.notGoing;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case RsvpStatus.going:
        return 'Going';
      case RsvpStatus.maybe:
        return 'Interested';
      case RsvpStatus.notGoing:
        return 'Not Going';
    }
  }
}
