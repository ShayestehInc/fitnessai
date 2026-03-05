import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_search_bar.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_tappable.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_impersonation_provider.dart';

class AdminTrainersScreen extends ConsumerStatefulWidget {
  const AdminTrainersScreen({super.key});

  @override
  ConsumerState<AdminTrainersScreen> createState() => _AdminTrainersScreenState();
}

class _AdminTrainersScreenState extends ConsumerState<AdminTrainersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminTrainersProvider.notifier).loadTrainers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(adminTrainersProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trainers'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AdaptiveSearchBar(
              controller: _searchController,
              placeholder: 'Search trainers...',
              onSubmitted: (value) {
                ref.read(adminTrainersProvider.notifier).loadTrainers(search: value);
              },
              onClear: () {
                ref.read(adminTrainersProvider.notifier).loadTrainers();
              },
            ),
          ),

          // Trainers list
          Expanded(
            child: state.isLoading
                ? const Center(child: AdaptiveSpinner())
                : state.trainers.isEmpty
                    ? Center(
                        child: Text(
                          'No trainers found',
                          style: TextStyle(color: theme.textTheme.bodySmall?.color),
                        ),
                      )
                    : AdaptiveRefreshIndicator(
                        onRefresh: () => ref
                            .read(adminTrainersProvider.notifier)
                            .loadTrainers(search: _searchController.text),
                        child: ListView.builder(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          physics: adaptiveAlwaysScrollablePhysics(context),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.trainers.length,
                          itemBuilder: (context, index) {
                            return _TrainerCard(trainer: state.trainers[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TrainerCard extends ConsumerWidget {
  final AdminTrainer trainer;

  const _TrainerCard({required this.trainer});

  Future<void> _impersonateTrainer(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Login as Trainer',
      message: 'You will be logged in as ${trainer.displayName} (${trainer.email}). '
          'Click "Exit" in the orange banner to return to your admin account.',
      confirmText: 'Continue',
    );

    if (confirmed != true) return;

    // Use admin impersonation provider to handle token management
    final result = await ref.read(adminImpersonationProvider.notifier).startImpersonation(
      trainerId: trainer.id,
      trainerEmail: trainer.email,
      trainerName: trainer.displayName,
    );

    if (result['success'] == true && context.mounted) {
      // Navigate to trainer dashboard
      context.go('/trainer');
      showAdaptiveToast(context, message: 'Logged in as ${trainer.displayName}', type: ToastType.success);
    } else if (context.mounted) {
      showAdaptiveToast(context, message: result['error'] ?? 'Failed to impersonate trainer', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sub = trainer.subscription;
    final tierColor = _getTierColor(sub?.tier);
    final statusColor = _getStatusColor(sub?.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: AdaptiveTappable(
        onTap: sub?.id != null
            ? () => context.push('/admin/subscriptions/${sub!.id}')
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      trainer.displayName[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainer.displayName,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          trainer.email,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Login as trainer button
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? IconButton(
                          icon: Icon(Icons.more_vert, color: theme.textTheme.bodySmall?.color),
                          onPressed: () => showAdaptiveActionSheet(
                            context: context,
                            actions: [
                              AdaptiveAction(
                                label: 'Login as Trainer',
                                onPressed: () => _impersonateTrainer(context, ref),
                              ),
                              if (sub?.id != null)
                                AdaptiveAction(
                                  label: 'View Subscription',
                                  onPressed: () => context.push('/admin/subscriptions/${sub!.id}'),
                                ),
                            ],
                          ),
                        )
                      : PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: theme.textTheme.bodySmall?.color),
                          onSelected: (value) {
                            if (value == 'impersonate') {
                              _impersonateTrainer(context, ref);
                            } else if (value == 'subscription' && sub?.id != null) {
                              context.push('/admin/subscriptions/${sub!.id}');
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'impersonate',
                              child: Row(
                                children: [
                                  Icon(Icons.login, size: 20),
                                  SizedBox(width: 8),
                                  Text('Login as Trainer'),
                                ],
                              ),
                            ),
                            if (sub?.id != null)
                              const PopupMenuItem(
                                value: 'subscription',
                                child: Row(
                                  children: [
                                    Icon(Icons.credit_card, size: 20),
                                    SizedBox(width: 8),
                                    Text('View Subscription'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                  if (!trainer.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  // Tier badge
                  if (sub != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.tierEnum.displayName,
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sub.statusEnum.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No Subscription',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Trainee count
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        '${trainer.traineeCount} trainees',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Past due warning
              if (sub != null && double.parse(sub.pastDueAmount) > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Past due: \$${sub.pastDueAmount}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor(String? tier) {
    switch (tier) {
      case 'FREE':
        return Colors.grey;
      case 'STARTER':
        return Colors.blue;
      case 'PRO':
        return Colors.purple;
      case 'ENTERPRISE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'past_due':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      case 'trialing':
        return Colors.blue;
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
