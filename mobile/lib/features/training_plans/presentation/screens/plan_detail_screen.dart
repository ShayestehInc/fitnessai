import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/training_plan_models.dart';
import '../providers/training_plan_provider.dart';
import '../widgets/plan_week_card.dart';

class PlanDetailScreen extends ConsumerStatefulWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen> {
  String? _expandedWeekId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(planDetailProvider(widget.planId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
      ),
      body: planAsync.when(
        loading: () => const Center(child: AdaptiveSpinner()),
        error: (error, _) => _buildError(theme, error),
        data: (plan) => _buildContent(theme, plan),
      ),
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.destructive, size: 48),
            const SizedBox(height: 16),
            Text('Failed to Load Plan', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(planDetailProvider(widget.planId)),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, TrainingPlanModel plan) {
    final weeks = plan.weeks ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(planDetailProvider(widget.planId));
      },
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlanHeader(theme, plan),
          const SizedBox(height: 20),
          if (weeks.isEmpty)
            _buildNoWeeks(theme)
          else
            ...weeks.map((week) => _buildWeekSection(theme, week)),
        ],
      ),
    );
  }

  Widget _buildPlanHeader(ThemeData theme, TrainingPlanModel plan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name ?? plan.goal.replaceAll('_', ' '),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              _buildStatusChip(theme, plan.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (plan.splitTemplateName != null) ...[
                _buildInfoPill(theme, Icons.dashboard, plan.splitTemplateName!),
                const SizedBox(width: 12),
              ],
              _buildInfoPill(
                theme,
                Icons.calendar_view_week,
                '${plan.weeksCount} week${plan.weeksCount == 1 ? '' : 's'}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    final Color color;
    switch (status) {
      case 'active':
        color = const Color(0xFF22C55E);
      case 'draft':
        color = const Color(0xFFF59E0B);
      case 'completed':
        color = AppTheme.primary;
      default:
        color = AppTheme.zinc500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoPill(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.zinc800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.mutedForeground),
          const SizedBox(width: 6),
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

  Widget _buildNoWeeks(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'No weeks configured for this plan yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekSection(ThemeData theme, PlanWeekModel week) {
    final isExpanded = _expandedWeekId == week.id;
    final sessions = week.sessions ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          PlanWeekCard(
            week: week,
            isExpanded: isExpanded,
            onTap: () {
              setState(() {
                _expandedWeekId = isExpanded ? null : week.id;
              });
            },
          ),
          if (isExpanded && sessions.isNotEmpty)
            ...sessions.map((session) => _buildSessionTile(theme, session)),
          if (isExpanded && sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Text(
                'No sessions in this week.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(ThemeData theme, PlanSessionModel session) {
    return GestureDetector(
      onTap: () => context.push('/plan-session/${session.id}'),
      child: Container(
        margin: const EdgeInsets.only(left: 16, top: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.zinc800,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                session.dayName.substring(0, 3),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.label, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${session.slotCount} exercise${session.slotCount == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 20),
          ],
        ),
      ),
    );
  }
}
