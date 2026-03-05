import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/progression_models.dart';

class ProgressionCard extends StatelessWidget {
  final ProgressionSuggestionModel suggestion;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;
  final VoidCallback onApply;
  final bool isLoading;

  const ProgressionCard({
    super.key,
    required this.suggestion,
    required this.onApprove,
    required this.onDismiss,
    required this.onApply,
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
            _buildProgressionComparison(theme),
            if (suggestion.rationale.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRationale(theme),
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
            color: AppTheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            suggestion.suggestionType == 'weight'
                ? Icons.fitness_center
                : Icons.repeat,
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.exerciseName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                suggestion.suggestionType == 'weight'
                    ? 'Weight Increase'
                    : 'Rep Increase',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(theme),
      ],
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color badgeColor;
    String label;

    switch (suggestion.status) {
      case 'approved':
        badgeColor = const Color(0xFF22C55E);
        label = 'Approved';
      case 'dismissed':
        badgeColor = AppTheme.zinc500;
        label = 'Dismissed';
      case 'applied':
        badgeColor = AppTheme.primary;
        label = 'Applied';
      default:
        badgeColor = const Color(0xFFF59E0B);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProgressionComparison(ThemeData theme) {
    final bool isWeight = suggestion.suggestionType == 'weight';
    final String currentLabel = isWeight
        ? '${suggestion.currentWeight} ${suggestion.unit}'
        : '${suggestion.currentReps} reps';
    final String suggestedLabel = isWeight
        ? '${suggestion.suggestedWeight} ${suggestion.unit}'
        : '${suggestion.suggestedReps} reps';

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
              value: currentLabel,
              color: AppTheme.mutedForeground,
            ),
          ),
          const _ProgressionArrow(),
          Expanded(
            child: _buildValueColumn(
              theme,
              label: 'Suggested',
              value: suggestedLabel,
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

  Widget _buildRationale(ThemeData theme) {
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
              suggestion.rationale,
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
    if (suggestion.status != 'pending') {
      return const SizedBox.shrink();
    }

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
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onApprove,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Approve'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : onApply,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}

class _ProgressionArrow extends StatefulWidget {
  const _ProgressionArrow();

  @override
  State<_ProgressionArrow> createState() => _ProgressionArrowState();
}

class _ProgressionArrowState extends State<_ProgressionArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12 + _animation.value,
            right: 12 - _animation.value,
          ),
          child: const Icon(
            Icons.arrow_forward,
            color: Color(0xFF22C55E),
            size: 24,
          ),
        );
      },
    );
  }
}
