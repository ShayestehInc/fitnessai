import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/training_plan_models.dart';

class PlanWeekCard extends StatelessWidget {
  final PlanWeekModel week;
  final bool isExpanded;
  final VoidCallback onTap;

  const PlanWeekCard({
    super.key,
    required this.week,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: week.isDeload
                ? const Color(0xFFF59E0B).withOpacity(0.4)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            _buildWeekNumber(theme),
            const SizedBox(width: 14),
            Expanded(child: _buildWeekInfo(theme)),
            if (week.isDeload) ...[
              _buildDeloadBadge(theme),
              const SizedBox(width: 8),
            ],
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.chevron_right,
                color: AppTheme.mutedForeground,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNumber(ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: week.isDeload
            ? const Color(0xFFF59E0B).withOpacity(0.15)
            : AppTheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        'W${week.weekNumber}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: week.isDeload ? const Color(0xFFF59E0B) : AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWeekInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week ${week.weekNumber}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${week.sessionCount} session${week.sessionCount == 1 ? '' : 's'}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildDeloadBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Deload',
        style: theme.textTheme.labelSmall?.copyWith(
          color: const Color(0xFFF59E0B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
