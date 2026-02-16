/// Single entry on the leaderboard.
class LeaderboardEntry {
  final int rank;
  final int userId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final int value;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.value,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      value: json['value'] as int? ?? 0,
    );
  }

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : 'Anonymous';
  }

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final result = '$first$last'.toUpperCase();
    return result.isNotEmpty ? result : '?';
  }
}

/// Full leaderboard response from the API.
class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final bool enabled;

  const LeaderboardResponse({
    required this.entries,
    this.myRank,
    this.enabled = true,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      myRank: json['my_rank'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
