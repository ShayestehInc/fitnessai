import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../providers/lift_provider.dart';
import '../widgets/lift_set_row.dart';

/// Per-exercise set history screen with date filters.
/// Shows all sets for a given exercise with load, reps, RPE, and date.
class LiftHistoryScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  final String exerciseName;

  const LiftHistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  ConsumerState<LiftHistoryScreen> createState() => _LiftHistoryScreenState();
}

class _LiftHistoryScreenState extends ConsumerState<LiftHistoryScreen> {
  String? _dateFrom;
  String? _dateTo;

  LiftSetLogsParams get _params => LiftSetLogsParams(
        exerciseId: widget.exerciseId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(
              start: DateTime.parse(_dateFrom!),
              end: DateTime.parse(_dateTo!),
            )
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _dateFrom = range.start.toIso8601String().substring(0, 10);
        _dateTo = range.end.toIso8601String().substring(0, 10);
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(liftSetLogsProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, size: 20),
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_dateFrom != null || _dateTo != null) _buildFilterChip(theme),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: AdaptiveSpinner()),
              error: (error, _) => _buildErrorState(theme, error),
              data: (logs) {
                if (logs.isEmpty) return _buildEmptyState(theme);
                return _buildLogsList(logs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ThemeData theme) {
    final label = _dateFrom != null && _dateTo != null
        ? '$_dateFrom to $_dateTo'
        : _dateFrom ?? _dateTo ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.zinc900,
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.foreground,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            child: const Icon(Icons.close, size: 16, color: AppTheme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<dynamic> logs) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(liftSetLogsProvider(_params));
      },
      color: AppTheme.primary,
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return LiftSetRow(setLog: logs[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Sets Recorded',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log some sets for ${widget.exerciseName} and they will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.destructive,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load History',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(liftSetLogsProvider(_params)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
