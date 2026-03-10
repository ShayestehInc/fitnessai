import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/decision_log_provider.dart';
import '../widgets/decision_card.dart';

class DecisionLogScreen extends ConsumerStatefulWidget {
  const DecisionLogScreen({super.key});

  @override
  ConsumerState<DecisionLogScreen> createState() => _DecisionLogScreenState();
}

class _DecisionLogScreenState extends ConsumerState<DecisionLogScreen> {
  String? _selectedDecisionType;
  String? _selectedActorType;
  String? _dateFrom;
  String? _dateTo;
  int _currentPage = 1;
  String? _undoingId;

  DecisionLogFilterParams get _params => DecisionLogFilterParams(
        decisionType: _selectedDecisionType,
        actorType: _selectedActorType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        page: _currentPage,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logsAsync = ref.watch(decisionLogListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(decisionLogListProvider(_params));
        },
        child: logsAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return _buildEmptyState(theme);
            }
            return Column(
              children: [
                if (_hasActiveFilters) _buildActiveFiltersBar(theme),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == logs.length) {
                        return _buildPaginationControls(theme);
                      }
                      return DecisionCard(
                        decision: logs[index],
                        isUndoing: _undoingId == logs[index].id,
                        onUndo: logs[index].canUndo
                            ? () => _undoDecision(logs[index].id)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(theme, e.toString()),
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedDecisionType != null ||
      _selectedActorType != null ||
      _dateFrom != null ||
      _dateTo != null;

  Widget _buildActiveFiltersBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (_selectedDecisionType != null)
                  _FilterChip(
                    label: _selectedDecisionType!,
                    onRemove: () => setState(() => _selectedDecisionType = null),
                  ),
                if (_selectedActorType != null)
                  _FilterChip(
                    label: _selectedActorType!,
                    onRemove: () => setState(() => _selectedActorType = null),
                  ),
                if (_dateFrom != null)
                  _FilterChip(
                    label: 'From: $_dateFrom',
                    onRemove: () => setState(() => _dateFrom = null),
                  ),
                if (_dateTo != null)
                  _FilterChip(
                    label: 'To: $_dateTo',
                    onRemove: () => setState(() => _dateTo = null),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selectedDecisionType = null;
              _selectedActorType = null;
              _dateFrom = null;
              _dateTo = null;
              _currentPage = 1;
            }),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page $_currentPage', style: theme.textTheme.bodyMedium),
          IconButton(
            onPressed: () => setState(() => _currentPage++),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No decisions found', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Decisions will appear here as the system makes them',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load decisions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(error, style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(decisionLogListProvider(_params)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _undoDecision(String id) async {
    setState(() => _undoingId = id);
    final repo = ref.read(decisionLogRepositoryProvider);
    final result = await repo.undoDecision(id);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decision undone successfully')),
      );
      ref.invalidate(decisionLogListProvider(_params));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String? ?? 'Failed to undo'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    setState(() => _undoingId = null);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _DecisionLogFilterSheet(
        selectedDecisionType: _selectedDecisionType,
        selectedActorType: _selectedActorType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        onApply: (decisionType, actorType, dateFrom, dateTo) {
          setState(() {
            _selectedDecisionType = decisionType;
            _selectedActorType = actorType;
            _dateFrom = dateFrom;
            _dateTo = dateTo;
            _currentPage = 1;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DecisionLogFilterSheet extends StatefulWidget {
  final String? selectedDecisionType;
  final String? selectedActorType;
  final String? dateFrom;
  final String? dateTo;
  final void Function(String?, String?, String?, String?) onApply;

  const _DecisionLogFilterSheet({
    this.selectedDecisionType,
    this.selectedActorType,
    this.dateFrom,
    this.dateTo,
    required this.onApply,
  });

  @override
  State<_DecisionLogFilterSheet> createState() => _DecisionLogFilterSheetState();
}

class _DecisionLogFilterSheetState extends State<_DecisionLogFilterSheet> {
  late String? _decisionType;
  late String? _actorType;
  late String? _dateFrom;
  late String? _dateTo;

  static const List<String> _decisionTypes = [
    'exercise_swap',
    'load_assignment',
    'deload_trigger',
    'progression',
    'plan_generation',
    'modality_selection',
  ];

  static const List<String> _actorTypes = [
    'system',
    'trainer',
    'trainee',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    _decisionType = widget.selectedDecisionType;
    _actorType = widget.selectedActorType;
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Decisions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Decision Type', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _decisionType == null,
                onSelected: (_) => setState(() => _decisionType = null),
              ),
              ..._decisionTypes.map((type) => ChoiceChip(
                    label: Text(type.replaceAll('_', ' ')),
                    selected: _decisionType == type,
                    onSelected: (_) => setState(() => _decisionType = type),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Text('Actor', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _actorType == null,
                onSelected: (_) => setState(() => _actorType = null),
              ),
              ..._actorTypes.map((type) => ChoiceChip(
                    label: Text(type[0].toUpperCase() + type.substring(1)),
                    selected: _actorType == type,
                    onSelected: (_) => setState(() => _actorType = type),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateFrom ?? 'From date'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateTo ?? 'To date'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply(_decisionType, _actorType, _dateFrom, _dateTo),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isFrom) {
          _dateFrom = formatted;
        } else {
          _dateTo = formatted;
        }
      });
    }
  }
}
