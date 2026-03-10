import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_models.dart';
import '../providers/analytics_provider.dart';
import '../widgets/audit_summary_card.dart';

class AuditTrailScreen extends ConsumerStatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(auditSummaryProvider(_days));
    final timelineParams = AuditTimelineParams(days: _days);
    final timelineAsync = ref.watch(auditTimelineProvider(timelineParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today, size: 20),
            onSelected: (days) => setState(() => _days = days),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 14, child: Text('Last 14 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(auditSummaryProvider(_days));
          ref.invalidate(auditTimelineProvider(AuditTimelineParams(days: _days)));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summaryAsync.when(
              data: (summary) => _buildSummarySection(theme, summary),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _buildSummaryError(theme),
            ),
            const SizedBox(height: 24),
            Text('Timeline', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            timelineAsync.when(
              data: (entries) => _buildTimeline(theme, entries),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _buildTimelineError(theme, e.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, AuditSummaryModel summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AuditSummaryCard(
                label: 'Total Decisions',
                value: '${summary.totalDecisions}',
                icon: Icons.history,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AuditSummaryCard(
                label: 'Last 7 Days',
                value: '${summary.recentDecisions7d}',
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AuditSummaryCard(
                label: 'Reverted',
                value: '${summary.revertedCount}',
                icon: Icons.undo,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        if (summary.byType.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('By Type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: summary.byType.map((item) {
              return Chip(
                label: Text(
                  '${(item.decisionType ?? 'unknown').replaceAll('_', ' ')}: ${item.count}',
                  style: const TextStyle(fontSize: 12),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
        if (summary.byActor.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('By Actor', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: summary.byActor.map((item) {
              return Chip(
                label: Text(
                  '${(item.actorType ?? 'unknown')}: ${item.count}',
                  style: const TextStyle(fontSize: 12),
                ),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline(ThemeData theme, List<AuditTimelineEntryModel> entries) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No audit entries in this period',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      children: entries
          .map((entry) => _AuditTimelineEntry(entry: entry))
          .toList(),
    );
  }

  Widget _buildSummaryError(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Failed to load summary',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineError(ThemeData theme, String error) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(error, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(auditTimelineProvider(AuditTimelineParams(days: _days))),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _AuditTimelineEntry extends StatelessWidget {
  final AuditTimelineEntryModel entry;

  const _AuditTimelineEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isReverted
                        ? Colors.orange
                        : theme.colorScheme.primary,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.decisionType.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        if (entry.isReverted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REVERTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatTimestamp(entry.timestamp),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.description,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.actorType}${entry.actorEmail != null ? ' (${entry.actorEmail})' : ''}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return timestamp;
    }
  }
}
