import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trainer_provider.dart';
import '../widgets/trainee_card.dart';
import '../../data/models/trainee_model.dart';
import '../../data/models/invitation_model.dart';

class TraineeListScreen extends ConsumerWidget {
  const TraineeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traineesAsync = ref.watch(traineesProvider);
    final invitationsAsync = ref.watch(invitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trainees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/trainer/invite'),
            tooltip: 'Invite Trainee',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(traineesProvider);
          ref.invalidate(invitationsProvider);
        },
        child: _buildBody(context, ref, traineesAsync, invitationsAsync),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trainer/invite'),
        icon: const Icon(Icons.person_add),
        label: const Text('Invite'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TraineeModel>> traineesAsync,
    AsyncValue<List<InvitationModel>> invitationsAsync,
  ) {
    // Handle loading state
    if (traineesAsync.isLoading && invitationsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
              child: const Text('Retry'),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Trainees Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Invite clients to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/trainer/invite'),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Trainee'),
            ),
          ],
        ),
      );
    }

    return ListView(
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      color: Colors.orange.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
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
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'resend') {
                  _resendInvitation(context, ref, invitation.id);
                } else if (value == 'cancel') {
                  _cancelInvitation(context, ref, invitation.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'resend',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Resend'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel', style: TextStyle(color: Colors.red)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to start session'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (context.mounted) {
      // Navigate to trainee home view (with impersonation banner showing)
      context.go('/');
    }
  }

  void _resendInvitation(BuildContext context, WidgetRef ref, int invitationId) async {
    final result = await ref.read(trainerRepositoryProvider).resendInvitation(invitationId);

    if (context.mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to resend invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelInvitation(BuildContext context, WidgetRef ref, int invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation?'),
        content: const Text('This will cancel the pending invitation. The trainee will no longer be able to join using this invite.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Invitation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref.read(trainerRepositoryProvider).cancelInvitation(invitationId);

      if (context.mounted) {
        if (result['success']) {
          ref.invalidate(invitationsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitation cancelled')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to cancel invitation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
