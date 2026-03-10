import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/voice_memo_model.dart';
import 'memo_status_badge.dart';

/// Card widget for displaying a voice memo in a list.
///
/// Shows a mic icon, truncated transcript preview, formatted timestamp,
/// and a status badge. Taps are forwarded via [onTap].
class VoiceMemoCard extends StatelessWidget {
  final VoiceMemoModel memo;
  final VoidCallback onTap;

  const VoiceMemoCard({
    super.key,
    required this.memo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = _formatDate(memo.createdAt);

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
                      memo.transcript ?? 'Processing...',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
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
              MemoStatusBadge(status: memo.status),
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
        Icons.mic_rounded,
        color: theme.colorScheme.primary,
        size: 22,
      ),
    );
  }

  static String _formatDate(String raw) {
    try {
      final dateTime = DateTime.parse(raw);
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (_) {
      return raw;
    }
  }
}
