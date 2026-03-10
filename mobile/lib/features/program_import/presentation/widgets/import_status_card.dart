import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/program_import_model.dart';

/// Card widget displaying a single program import with status, file name,
/// and creation date. Tappable to navigate to detail/review.
class ImportStatusCard extends StatelessWidget {
  final ProgramImportModel importModel;
  final VoidCallback onTap;

  const ImportStatusCard({
    super.key,
    required this.importModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String formattedDate;
    try {
      final dateTime = DateTime.parse(importModel.createdAt);
      formattedDate = DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (_) {
      formattedDate = importModel.createdAt;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      importModel.fileName ?? 'Imported Program',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.upload_file_rounded,
        color: theme.colorScheme.primary,
        size: 22,
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final config = _statusConfig(importModel.status);

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
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(config.color),
              ),
            ),
            const SizedBox(width: 6),
          ] else ...[
            Icon(config.icon, size: 14, color: config.color),
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

  static _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'uploaded':
        return const _StatusConfig(
          label: 'Uploaded',
          color: Color(0xFF6B7280),
          icon: Icons.cloud_upload_outlined,
          showSpinner: false,
        );
      case 'parsing':
        return const _StatusConfig(
          label: 'Parsing',
          color: Color(0xFF3B82F6),
          icon: Icons.autorenew,
          showSpinner: true,
        );
      case 'parsed':
        return const _StatusConfig(
          label: 'Ready',
          color: Color(0xFFF59E0B),
          icon: Icons.rate_review_outlined,
          showSpinner: false,
        );
      case 'confirmed':
        return const _StatusConfig(
          label: 'Confirmed',
          color: Color(0xFF22C55E),
          icon: Icons.check_circle_outline,
          showSpinner: false,
        );
      case 'failed':
        return const _StatusConfig(
          label: 'Failed',
          color: Color(0xFFEF4444),
          icon: Icons.error_outline,
          showSpinner: false,
        );
      default:
        return _StatusConfig(
          label: status,
          color: const Color(0xFF6B7280),
          icon: Icons.help_outline,
          showSpinner: false,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  final bool showSpinner;

  const _StatusConfig({
    required this.label,
    required this.color,
    required this.icon,
    required this.showSpinner,
  });
}
