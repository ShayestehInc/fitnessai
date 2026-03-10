import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ModalityBadgeWidget extends StatelessWidget {
  final String name;

  const ModalityBadgeWidget({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _badgeColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_badgeIcon, size: 12, color: _badgeColor),
          const SizedBox(width: 4),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color get _badgeColor {
    final normalized = name.toLowerCase();
    if (normalized.contains('drop')) return const Color(0xFFEF4444);
    if (normalized.contains('super')) return const Color(0xFF8B5CF6);
    if (normalized.contains('rest') && normalized.contains('pause')) {
      return const Color(0xFFF59E0B);
    }
    if (normalized.contains('myo')) return const Color(0xFFEC4899);
    if (normalized.contains('cluster')) return const Color(0xFF14B8A6);
    if (normalized.contains('giant')) return const Color(0xFF6366F1);
    if (normalized.contains('emom')) return const Color(0xFF3B82F6);
    return AppTheme.mutedForeground;
  }

  IconData get _badgeIcon {
    final normalized = name.toLowerCase();
    if (normalized.contains('drop')) return Icons.trending_down;
    if (normalized.contains('super')) return Icons.link;
    if (normalized.contains('rest') && normalized.contains('pause')) {
      return Icons.pause_circle_outline;
    }
    if (normalized.contains('myo')) return Icons.flash_on;
    if (normalized.contains('cluster')) return Icons.scatter_plot;
    if (normalized.contains('giant')) return Icons.view_stream;
    if (normalized.contains('emom')) return Icons.timer;
    return Icons.style;
  }
}
