import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_spinner.dart';
import '../../../../shared/widgets/adaptive/adaptive_toast.dart';
import '../../data/models/invitation_model.dart';
import '../providers/trainer_provider.dart';

class InviteTraineeScreen extends ConsumerStatefulWidget {
  const InviteTraineeScreen({super.key});

  @override
  ConsumerState<InviteTraineeScreen> createState() => _InviteTraineeScreenState();
}

class _InviteTraineeScreenState extends ConsumerState<InviteTraineeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitationsAsync = ref.watch(invitationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Trainee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invite Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Invitation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'client@example.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Personal Message (Optional)',
                          hintText: 'Add a personal message to your invitation...',
                          prefixIcon: Icon(Icons.message),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendInvitation,
                          icon: _isLoading
                              ? const AdaptiveSpinner.small()
                              : const Icon(Icons.send),
                          label: Text(_isLoading ? 'Sending...' : 'Send Invitation'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pending Invitations
            Text(
              'Pending Invitations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            invitationsAsync.when(
              data: (invitations) {
                final pending = invitations.where((i) => i.isPending).toList();

                if (pending.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.mail_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No pending invitations',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    return _buildInvitationCard(pending[index]);
                  },
                );
              },
              loading: () => const Center(child: AdaptiveSpinner()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(InvitationModel invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.mail),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invitation.email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (invitation.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Expired',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Expires: ${_formatDate(invitation.expiresAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                        label: 'Copy Link',
                        icon: Icons.copy,
                        onPressed: () => _copyInviteLink(invitation),
                      ),
                      AdaptiveAction(
                        label: 'Resend',
                        icon: Icons.refresh,
                        onPressed: () => _resendInvitation(invitation),
                      ),
                      AdaptiveAction(
                        label: 'Cancel',
                        icon: Icons.cancel,
                        onPressed: () => _cancelInvitation(invitation),
                        isDestructive: true,
                      ),
                    ],
                  ),
                )
              : PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'copy') {
                      _copyInviteLink(invitation);
                    } else if (value == 'resend') {
                      await _resendInvitation(invitation);
                    } else if (value == 'cancel') {
                      await _cancelInvitation(invitation);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Copy Link'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'resend',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text('Resend'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 20, color: Colors.red),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _copyInviteLink(InvitationModel invitation) {
    // In a real app, this would be a deep link to the app
    final link = 'https://fitnessai.app/invite/${invitation.invitationCode}';
    Clipboard.setData(ClipboardData(text: link));
    showAdaptiveToast(context, message: 'Invite link copied to clipboard');
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = CreateInvitationRequest(
      email: _emailController.text.trim(),
      message: _messageController.text.trim(),
    );

    final result = await ref.read(trainerRepositoryProvider).createInvitation(request);

    setState(() => _isLoading = false);

    if (result['success']) {
      HapticService.success();
      ref.invalidate(invitationsProvider);
      _emailController.clear();
      _messageController.clear();

      if (mounted) {
        showAdaptiveToast(context, message: 'Invitation sent successfully!', type: ToastType.success);
      }
    } else {
      if (mounted) {
        showAdaptiveToast(context, message: result['error'] ?? 'Failed to send invitation', type: ToastType.error);
      }
    }
  }

  Future<void> _resendInvitation(InvitationModel invitation) async {
    final result = await ref.read(trainerRepositoryProvider).resendInvitation(invitation.id);

    if (result['success']) {
      ref.invalidate(invitationsProvider);
      if (mounted) {
        showAdaptiveToast(context, message: 'Invitation resent');
      }
    } else {
      if (mounted) {
        showAdaptiveToast(context, message: result['error'] ?? 'Failed to resend', type: ToastType.error);
      }
    }
  }

  Future<void> _cancelInvitation(InvitationModel invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref.read(trainerRepositoryProvider).cancelInvitation(invitation.id);

      if (result['success']) {
        ref.invalidate(invitationsProvider);
        if (mounted) {
          showAdaptiveToast(context, message: 'Invitation cancelled');
        }
      }
    }
  }
}
