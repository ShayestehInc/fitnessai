/// Shared timestamp formatting utilities for messaging widgets.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Format hour to 12-hour clock, handling midnight (0) and noon (12) correctly.
int _to12Hour(int hour) {
  if (hour == 0) return 12;
  if (hour > 12) return hour - 12;
  return hour;
}

String _amPm(int hour) => hour >= 12 ? 'PM' : 'AM';

/// Format a timestamp for the conversation list tile (short form).
///
/// Shows: "Now", "5m", "2:30 PM" (today), "Yesterday", "Feb 15", "Feb 15, 2025".
String formatConversationTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24 && dt.day == now.day) {
    final hour = _to12Hour(dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min ${_amPm(dt.hour)}';
  }
  if (diff.inDays == 1 || (diff.inDays == 0 && dt.day != now.day)) {
    return 'Yesterday';
  }
  if (dt.year == now.year) {
    return '${_months[dt.month - 1]} ${dt.day}';
  }
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// Format a timestamp for a message bubble (includes time for older messages).
///
/// Shows: "Just now", "5m ago", "2:30 PM", "Yesterday 2:30 PM",
///        "Feb 15 2:30 PM", "Feb 15, 2025 2:30 PM".
String formatMessageTimestamp(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';

  final hour = _to12Hour(dt.hour);
  final min = dt.minute.toString().padLeft(2, '0');
  final time = '$hour:$min ${_amPm(dt.hour)}';

  if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
    return time;
  }
  if (diff.inDays == 1 || (diff.inDays == 0 && dt.day != now.day)) {
    return 'Yesterday $time';
  }
  if (dt.year == now.year) {
    return '${_months[dt.month - 1]} ${dt.day} $time';
  }
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} $time';
}
