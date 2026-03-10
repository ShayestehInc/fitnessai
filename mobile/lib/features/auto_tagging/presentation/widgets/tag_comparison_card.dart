import 'package:flutter/material.dart';

class TagComparisonCard extends StatelessWidget {
  final Map<String, dynamic>? currentTags;
  final Map<String, dynamic>? proposedTags;

  const TagComparisonCard({
    super.key,
    this.currentTags,
    this.proposedTags,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allKeys = <String>{
      ...?currentTags?.keys,
      ...?proposedTags?.keys,
    }.toList()
      ..sort();

    if (allKeys.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No tag data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Proposed',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...allKeys.map((key) => _buildTagRow(theme, key)),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(ThemeData theme, String key) {
    final currentVal = currentTags?[key];
    final proposedVal = proposedTags?[key];
    final isChanged = currentVal?.toString() != proposedVal?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatKey(key),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildTagValue(
                  theme,
                  currentVal,
                  isChanged: false,
                ),
              ),
              if (isChanged)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                const SizedBox(width: 32),
              Expanded(
                child: _buildTagValue(
                  theme,
                  proposedVal,
                  isChanged: isChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagValue(
    ThemeData theme,
    dynamic value, {
    required bool isChanged,
  }) {
    if (value == null) {
      return Text(
        '-',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      );
    }

    final displayText = _formatValue(value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isChanged
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        displayText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isChanged ? theme.colorScheme.primary : null,
          fontWeight: isChanged ? FontWeight.w600 : null,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      if (value.isEmpty) return 'None';
      return value.join(', ');
    }
    if (value is Map) {
      if (value.isEmpty) return 'None';
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }
}
