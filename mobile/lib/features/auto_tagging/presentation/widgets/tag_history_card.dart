import 'package:flutter/material.dart';
import '../../data/models/auto_tag_model.dart';

class TagHistoryCard extends StatelessWidget {
  final TagHistoryEntryModel entry;
  final bool isFirst;
  final bool isLast;

  const TagHistoryCard({
    super.key,
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeline(theme),
          const SizedBox(width: 12),
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final color = _colorForAction(entry.action, theme);

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          if (!isFirst)
            Container(
              width: 2,
              height: 8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ActionBadge(action: entry.action, label: entry.actionDisplay),
                const Spacer(),
                Text(
                  _formatTimestamp(entry.appliedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (entry.appliedBy != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.appliedBy!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.tags.entries.take(6).map((e) {
                  return _TagChip(
                    label: '${_formatKey(e.key)}: ${_formatValue(e.value)}',
                  );
                }).toList(),
              ),
              if (entry.tags.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${entry.tags.length - 6} more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _colorForAction(String action, ThemeData theme) {
    switch (action) {
      case 'auto_tag':
        return Colors.blue;
      case 'applied':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'manual':
        return Colors.orange;
      case 'reverted':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return timestamp;
    }
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is List) return value.join(', ');
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }
}

class _ActionBadge extends StatelessWidget {
  final String action;
  final String label;

  const _ActionBadge({required this.action, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _colorForAction(action);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _colorForAction(String action) {
    switch (action) {
      case 'auto_tag':
        return Colors.blue;
      case 'applied':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'manual':
        return Colors.orange;
      case 'reverted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
