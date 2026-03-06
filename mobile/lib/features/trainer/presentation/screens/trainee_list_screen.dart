import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_refresh_indicator.dart';
import '../../../../shared/widgets/adaptive/adaptive_scroll_physics.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../providers/trainer_provider.dart';
import '../widgets/trainee_card.dart';
import '../../data/models/trainee_model.dart';
import '../../data/models/invitation_model.dart';
import '../../../../core/l10n/l10n_extension.dart';

class TraineeListScreen extends ConsumerWidget {
  const TraineeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traineesAsync = ref.watch(traineesProvider);
    final invitationsAsync = ref.watch(invitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.trainerMyTrainees),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/trainer/invite'),
            tooltip: context.l10n.trainerInviteTrainee,
          ),
        ],
      ),
      body: AdaptiveRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(traineesProvider);
          ref.invalidate(invitationsProvider);
        },
        child: _buildBody(context, ref, traineesAsync, invitationsAsync),
      ),
      floatingActionButton: Theme.of(context).platform == TargetPlatform.iOS
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/trainer/invite'),
              icon: const Icon(Icons.person_add),
              label: Text(context.l10n.trainerInvite),
            ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TraineeModel>> traineesAsync,
    AsyncValue<List<InvitationModel>> invitationsAsync,
  ) {
    final theme = Theme.of(context);

    // Handle loading state
    if (traineesAsync.isLoading && invitationsAsync.isLoading) {
      return const Center(child: AdaptiveSpinner());
    }

    // Handle error state
    if (traineesAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${traineesAsync.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(traineesProvider);
                ref.invalidate(invitationsProvider);
              },
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    final trainees = traineesAsync.valueOrNull ?? [];
    final invitations = invitationsAsync.valueOrNull ?? [];
    final pendingInvitations = invitations.where((i) => i.isPending && !i.isExpired).toList();

    // Show empty state if no trainees and no pending invitations
    if (trainees.isEmpty && pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No Trainees Yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Invite clients to get started',
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/trainer/invite'),
              icon: const Icon(Icons.person_add),
              label: Text(context.l10n.trainerInviteTrainee),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: adaptiveAlwaysScrollablePhysics(context),
      padding: const EdgeInsets.all(16),
      children: [
        // Pending Invitations Section
        if (pendingInvitations.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.mail_outline, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Pending Invitations (${pendingInvitations.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          ...pendingInvitations.map((invitation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInvitationCard(context, ref, invitation),
              )),
          const SizedBox(height: 16),
        ],

        // Active Trainees Section
        if (trainees.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.people, size: 18, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Active Trainees (${trainees.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          ...trainees.map((trainee) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TraineeCard(
                  trainee: trainee,
                  onTap: () => context.push('/trainer/trainees/${trainee.id}'),
                  onLoginAs: () => _startImpersonation(context, ref, trainee.id),
                ),
              )),
        ],

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInvitationCard(BuildContext context, WidgetRef ref, InvitationModel invitation) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3), width: 1),
      ),
      color: Colors.orange.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.2),
              child: const Icon(Icons.mail_outline, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (invitation.expiresAt != null)
                        Text(
                          'Expires ${_formatDate(invitation.expiresAt!)}',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Theme.of(context).platform == TargetPlatform.iOS
              ? IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => showAdaptiveActionSheet(
                    context: context,
                    actions: [
                      AdaptiveAction(
                        label: context.l10n.trainerResend,
                        icon: Icons.refresh,
                        onPressed: () => _resendInvitation(context, ref, invitation.id),
                      ),
                      AdaptiveAction(
                        label: context.l10n.commonCancel,
                        icon: Icons.cancel_outlined,
                        onPressed: () => _cancelInvitation(context, ref, invitation.id),
                        isDestructive: true,
                      ),
                    ],
                  ),
                )
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'resend') {
                      _resendInvitation(context, ref, invitation.id);
                    } else if (value == 'cancel') {
                      _cancelInvitation(context, ref, invitation.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'resend',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text(context.l10n.trainerResend),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(context.l10n.commonCancel, style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = date.difference(now);

      if (diff.inDays > 0) {
        return 'in ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        return 'in ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''}';
      } else {
        return 'soon';
      }
    } catch (_) {
      return dateStr;
    }
  }

  void _startImpersonation(BuildContext context, WidgetRef ref, int traineeId) async {
    final result = await ref.read(impersonationProvider.notifier).startImpersonation(traineeId);

    if (!result['success'] && context.mounted) {
      showAdaptiveToast(context, message: result['error'] ?? 'Failed to start session', type: ToastType.error);
    } else if (context.mounted) {
      // Navigate to trainee home view (with impersonation banner showing)
      context.go('/');
    }
  }

  void _resendInvitation(BuildContext context, WidgetRef ref, int invitationId) async {
    final result = await ref.read(trainerRepositoryProvider).resendInvitation(invitationId);

    if (context.mounted) {
      if (result['success']) {
        showAdaptiveToast(context, message: context.l10n.trainerInvitationResentSuccessfully, type: ToastType.success);
      } else {
        showAdaptiveToast(context, message: result['error'] ?? 'Failed to resend invitation', type: ToastType.error);
      }
    }
  }

  void _cancelInvitation(BuildContext context, WidgetRef ref, int invitationId) async {
    final confirmed = await showAdaptiveConfirmDialog(
      context: context,
      title: context.l10n.trainerCancelInvitation,
      message: 'This will cancel the pending invitation. The trainee will no longer be able to join using this invite.',
      confirmText: context.l10n.trainerCancelInvitation2,
      cancelText: 'Keep',
      isDestructive: true,
    );

    if (confirmed == true) {
      final result = await ref.read(trainerRepositoryProvider).cancelInvitation(invitationId);

      if (context.mounted) {
        if (result['success']) {
          ref.invalidate(invitationsProvider);
          showAdaptiveToast(context, message: context.l10n.trainerInvitationCancelled);
        } else {
          showAdaptiveToast(context, message: result['error'] ?? 'Failed to cancel invitation', type: ToastType.error);
        }
      }
    }
  }
}
