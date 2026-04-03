import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
          const SizedBox(height: 24),
          _buildActionButtons(theme, plan),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  bool _isConverting = false;

  Future<void> _convertToProgram({int? traineeId}) async {
    setState(() => _isConverting = true);
    final repo = ref.read(trainingPlanRepositoryProvider);
    final result = await repo.convertToProgram(
      widget.planId,
      traineeId: traineeId,
    );
    setState(() => _isConverting = false);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final msg = traineeId != null
          ? 'Program assigned to ${data['assigned_to']}'
          : 'Program created: ${data['template_name']}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      if (mounted) context.go('/trainer/programs');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']?.toString() ?? 'Failed')),
      );
    }
  }

  void _showTraineePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _TraineePickerSheet(
        onSelected: (traineeId) {
          Navigator.pop(ctx);
          _convertToProgram(traineeId: traineeId);
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, TrainingPlanModel plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _isConverting ? null : () => _convertToProgram(),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save as Program'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isConverting ? null : _showTraineePicker,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Assign to Trainee'),
          ),
        ),
      ],
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
                () {
                  final count = plan.durationWeeks ?? plan.weeks?.length ?? plan.weeksCount;
                  return '$count week${count == 1 ? '' : 's'}';
                }(),
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

/// Bottom sheet that fetches and displays trainer's trainees for assignment.
class _TraineePickerSheet extends ConsumerWidget {
  final ValueChanged<int> onSelected;

  const _TraineePickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchTrainees(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final trainees = snapshot.data?['trainees'] as List<dynamic>? ?? [];
        if (trainees.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No trainees found', style: TextStyle(color: AppTheme.mutedForeground))),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          itemCount: trainees.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Select Trainee',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              );
            }
            final trainee = trainees[index - 1] as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.zinc700,
                child: Text(
                  (trainee['first_name']?.toString() ?? trainee['email']?.toString() ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: AppTheme.foreground),
                ),
              ),
              title: Text(
                '${trainee['first_name'] ?? ''} ${trainee['last_name'] ?? ''}'.trim().isEmpty
                    ? trainee['email']?.toString() ?? 'Unknown'
                    : '${trainee['first_name'] ?? ''} ${trainee['last_name'] ?? ''}'.trim(),
              ),
              subtitle: Text(trainee['email']?.toString() ?? ''),
              onTap: () => onSelected(trainee['id'] as int),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchTrainees(WidgetRef ref) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final response = await apiClient.dio.get(
        '${ApiConstants.apiBaseUrl}/trainer/trainees/',
      );
      final data = response.data;
      final results = data is Map ? (data['results'] ?? data) : data;
      return {'trainees': results is List ? results : []};
    } catch (_) {
      return {'trainees': []};
    }
  }
}
