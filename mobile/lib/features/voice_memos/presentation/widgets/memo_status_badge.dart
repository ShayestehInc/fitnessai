import 'package:flutter/material.dart';

import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';

/// Status badge for voice memo processing states.
class MemoStatusBadge extends StatelessWidget {
  final String status;

  const MemoStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.showSpinner) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: config.color,
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(
              config.icon,
              size: 14,
              color: config.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            config.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeConfig _badgeConfig(String status) {
    switch (status) {
      case 'uploaded':
        return const _BadgeConfig(
          label: 'Uploaded',
          color: Color(0xFF6B7280),
          icon: Icons.cloud_upload_outlined,
          showSpinner: false,
        );
      case 'transcribing':
        return const _BadgeConfig(
          label: 'Transcribing',
          color: Color(0xFF3B82F6),
          icon: Icons.hearing,
          showSpinner: true,
        );
      case 'transcribed':
        return const _BadgeConfig(
          label: 'Transcribed',
          color: Color(0xFFF59E0B),
          icon: Icons.text_snippet_outlined,
          showSpinner: false,
        );
      case 'parsed':
        return const _BadgeConfig(
          label: 'Parsed',
          color: Color(0xFF22C55E),
          icon: Icons.check_circle_outline,
          showSpinner: false,
        );
      case 'failed':
        return const _BadgeConfig(
          label: 'Failed',
          color: Color(0xFFEF4444),
          icon: Icons.error_outline,
          showSpinner: false,
        );
      default:
        return _BadgeConfig(
          label: status,
          color: const Color(0xFF6B7280),
          icon: Icons.help_outline,
          showSpinner: false,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color color;
  final IconData icon;
  final bool showSpinner;

  const _BadgeConfig({
    required this.label,
    required this.color,
    required this.icon,
    required this.showSpinner,
  });
}
