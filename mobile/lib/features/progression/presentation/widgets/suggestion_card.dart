import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/progression_profile_model.dart';

class SuggestionCard extends StatelessWidget {
  final ProgressionPlanSuggestionModel suggestion;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onApprove,
    required this.onDismiss,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _buildComparison(theme),
            if (suggestion.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReason(theme),
            ],
            const SizedBox(height: 16),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_typeIcon, color: _typeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.exerciseName,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${suggestion.typeDisplay} Adjustment',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparison(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildValueColumn(
              theme,
              label: 'Current',
              value: suggestion.currentDisplay,
              color: AppTheme.mutedForeground,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward,
              color: Color(0xFF22C55E),
              size: 22,
            ),
          ),
          Expanded(
            child: _buildValueColumn(
              theme,
              label: 'Suggested',
              value: suggestion.suggestedDisplay,
              color: const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueColumn(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildReason(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppTheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              suggestion.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.zinc300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onDismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.mutedForeground,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Dismiss'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Color get _typeColor {
    switch (suggestion.suggestionType) {
      case 'weight':
        return AppTheme.primary;
      case 'reps':
        return const Color(0xFF22C55E);
      case 'sets':
        return const Color(0xFFF59E0B);
      case 'rest':
        return const Color(0xFF3B82F6);
      default:
        return AppTheme.mutedForeground;
    }
  }

  IconData get _typeIcon {
    switch (suggestion.suggestionType) {
      case 'weight':
        return Icons.fitness_center;
      case 'reps':
        return Icons.repeat;
      case 'sets':
        return Icons.layers;
      case 'rest':
        return Icons.timer;
      default:
        return Icons.trending_up;
    }
  }
}
