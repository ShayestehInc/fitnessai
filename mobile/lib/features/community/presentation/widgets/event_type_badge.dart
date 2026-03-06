import 'package:flutter/material.dart';

class EventTypeBadge extends StatelessWidget {
  final String eventType;

  const EventTypeBadge({super.key, required this.eventType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) get _config {
    switch (eventType) {
      case 'live_session':
        return ('Live Session', Colors.red);
      case 'q_and_a':
        return ('Q&A', Colors.blue);
      case 'workshop':
        return ('Workshop', Colors.purple);
      case 'challenge':
        return ('Challenge', Colors.orange);
      default:
        return ('Event', Colors.grey);
    }
  }
}

class EventStatusBadge extends StatelessWidget {
  final String status;

  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) get _config {
    switch (status) {
      case 'live':
        return ('Happening Now', Colors.green, Icons.circle);
      case 'cancelled':
        return ('Cancelled', Colors.red, Icons.cancel_outlined);
      case 'completed':
        return ('Ended', Colors.grey, Icons.check_circle_outline);
      default:
        return ('Scheduled', Colors.blue, Icons.schedule);
    }
  }
}
