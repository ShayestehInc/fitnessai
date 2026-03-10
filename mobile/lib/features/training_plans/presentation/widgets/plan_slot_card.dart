import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/training_plan_models.dart';
import 'modality_badge_widget.dart';

class PlanSlotCard extends StatelessWidget {
  final PlanSlotModel slot;
  final int index;

  const PlanSlotCard({
    super.key,
    required this.slot,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          _buildMetrics(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _roleColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: theme.textTheme.labelMedium?.copyWith(
              color: _roleColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.exerciseName ?? 'Unknown Exercise',
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                slot.roleDisplay,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _roleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (slot.modalityName != null)
          ModalityBadgeWidget(name: slot.modalityName!),
      ],
    );
  }

  Widget _buildMetrics(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.zinc900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildMetric(theme, 'Sets', '${slot.sets}'),
          _buildDivider(),
          _buildMetric(theme, 'Reps', slot.repsDisplay),
          _buildDivider(),
          _buildMetric(theme, 'Rest', slot.restDisplay),
        ],
      ),
    );
  }

  Widget _buildMetric(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.border.withOpacity(0.5),
    );
  }

  Color get _roleColor {
    switch (slot.slotRole) {
      case 'primary':
        return AppTheme.primary;
      case 'secondary':
        return const Color(0xFF22C55E);
      case 'accessory':
        return const Color(0xFFF59E0B);
      case 'warmup':
        return const Color(0xFF3B82F6);
      case 'cooldown':
        return const Color(0xFF8B5CF6);
      default:
        return AppTheme.mutedForeground;
    }
  }
}
