import 'package:flutter/material.dart';
import '../../data/models/decision_log_model.dart';

class DecisionCard extends StatefulWidget {
  final DecisionLogModel decision;
  final VoidCallback? onUndo;
  final bool isUndoing;

  const DecisionCard({
    super.key,
    required this.decision,
    this.onUndo,
    this.isUndoing = false,
  });

  @override
  State<DecisionCard> createState() => _DecisionCardState();
}

class _DecisionCardState extends State<DecisionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decision = widget.decision;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, decision),
              const SizedBox(height: 8),
              Text(
                decision.finalChoiceSummary,
                style: theme.textTheme.bodyMedium,
                maxLines: _isExpanded ? null : 2,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
              if (_isExpanded) ...[
                const Divider(height: 24),
                _buildExpandedContent(theme, decision),
              ],
              const SizedBox(height: 8),
              _buildFooter(theme, decision),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, DecisionLogModel decision) {
    return Row(
      children: [
        _DecisionTypeBadge(type: decision.decisionType, label: decision.decisionTypeDisplay),
        const SizedBox(width: 8),
        _ActorBadge(actorType: decision.actorType, label: decision.actorTypeDisplay),
        const Spacer(),
        Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme, DecisionLogModel decision) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decision.context.isNotEmpty) ...[
          Text('Context', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          ...decision.context.entries.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
        if (decision.reasonCodes.isNotEmpty) ...[
          Text('Reason Codes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: decision.reasonCodes.map((code) {
              return Chip(
                label: Text(code, style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (decision.inputsSnapshot.isNotEmpty) ...[
          Text('Inputs', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          ...decision.inputsSnapshot.entries.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (decision.canUndo) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.isUndoing ? null : widget.onUndo,
              icon: widget.isUndoing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.undo, size: 18),
              label: Text(widget.isUndoing ? 'Undoing...' : 'Undo Decision'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, DecisionLogModel decision) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          _formatTimestamp(decision.timestamp),
          style: theme.textTheme.labelSmall,
        ),
        if (decision.canUndo) ...[
          const Spacer(),
          Icon(Icons.undo, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            'Undoable',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
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
}

class _DecisionTypeBadge extends StatelessWidget {
  final String type;
  final String label;

  const _DecisionTypeBadge({required this.type, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(type);
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

  Color _colorForType(String type) {
    switch (type) {
      case 'exercise_swap':
        return Colors.blue;
      case 'load_assignment':
        return Colors.orange;
      case 'deload_trigger':
        return Colors.purple;
      case 'progression':
        return Colors.green;
      case 'plan_generation':
        return Colors.teal;
      case 'modality_selection':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class _ActorBadge extends StatelessWidget {
  final String actorType;
  final String label;

  const _ActorBadge({required this.actorType, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
