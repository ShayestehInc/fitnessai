import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../data/models/training_plan_models.dart';
import '../providers/training_plan_provider.dart';

class MyPlansScreen extends ConsumerStatefulWidget {
  const MyPlansScreen({super.key});

  @override
  ConsumerState<MyPlansScreen> createState() => _MyPlansScreenState();
}

class _MyPlansScreenState extends ConsumerState<MyPlansScreen> {
  static const _statusFilters = ['All', 'Active', 'Draft', 'Completed', 'Archived'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(trainingPlansProvider.notifier).loadPlans();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    final status = filter == 'All' ? null : filter.toLowerCase();
    ref.read(trainingPlansProvider.notifier).setStatusFilter(status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansState = ref.watch(trainingPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Training Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Build Program',
            onPressed: () => context.push('/build-program'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(theme),
          Expanded(
            child: _buildBody(theme, plansState),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = filter == _selectedFilter;
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => _onFilterChanged(filter),
            backgroundColor: AppTheme.zinc800,
            selectedColor: AppTheme.primary.withOpacity(0.2),
            checkmarkColor: AppTheme.primary,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? AppTheme.primary : AppTheme.mutedForeground,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme, TrainingPlansState plansState) {
    if (plansState.isLoading) {
      return const Center(child: AdaptiveSpinner());
    }

    if (plansState.error != null) {
      return _buildErrorState(theme, plansState.error!);
    }

    if (plansState.plans.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: () async {
        final status =
            _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase();
        await ref.read(trainingPlansProvider.notifier).loadPlans(status: status);
      },
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plansState.plans.length,
        itemBuilder: (context, index) {
          return _PlanListTile(
            plan: plansState.plans[index],
            onTap: () => context.push('/plan-detail/${plansState.plans[index].id}'),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.destructive, size: 48),
            const SizedBox(height: 16),
            Text('Failed to Load Plans', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(trainingPlansProvider.notifier).loadPlans(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
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
              child: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 48),
            ),
            const SizedBox(height: 24),
            Text('No Training Plans', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Your trainer has not assigned any training plans yet. '
              'Check back later or contact your trainer.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanListTile extends StatelessWidget {
  final TrainingPlanModel plan;
  final VoidCallback onTap;

  const _PlanListTile({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: plan.isActive ? AppTheme.primary.withOpacity(0.4) : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 14),
            Expanded(child: _buildContent(theme)),
            const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final Color color;
    final IconData icon;
    switch (plan.status) {
      case 'active':
        color = const Color(0xFF22C55E);
        icon = Icons.play_circle_fill;
      case 'draft':
        color = const Color(0xFFF59E0B);
        icon = Icons.edit_note;
      case 'completed':
        color = AppTheme.primary;
        icon = Icons.check_circle;
      case 'archived':
        color = AppTheme.zinc500;
        icon = Icons.archive;
      default:
        color = AppTheme.mutedForeground;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.goal, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            if (plan.splitTemplateName != null) ...[
              Icon(Icons.dashboard, size: 14, color: AppTheme.mutedForeground),
              const SizedBox(width: 4),
              Text(
                plan.splitTemplateName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Icon(Icons.calendar_view_week, size: 14, color: AppTheme.mutedForeground),
            const SizedBox(width: 4),
            Text(
              '${plan.weeksCount} week${plan.weeksCount == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
