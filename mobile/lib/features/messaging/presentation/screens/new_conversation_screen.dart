import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/messaging_repository.dart';
import '../providers/messaging_provider.dart';
import '../widgets/chat_input.dart';

/// Screen for starting a new conversation with a trainee.
/// Shows an input field to send the first message.
class NewConversationScreen extends ConsumerStatefulWidget {
  final int traineeId;
  final String? traineeName;

  const NewConversationScreen({
    super.key,
    required this.traineeId,
    this.traineeName,
  });

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState
    extends ConsumerState<NewConversationScreen> {
  bool _isSending = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.traineeName ?? 'New Message'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Send a message to ${widget.traineeName ?? 'this trainee'}',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ChatInput(
            onSend: _handleSend,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }

  Future<bool> _handleSend(String content) async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final repo = MessagingRepository(apiClient);
      final result = await repo.startConversation(
        traineeId: widget.traineeId,
        content: content,
      );

      // Refresh conversation list
      ref.read(conversationListProvider.notifier).loadConversations();
      ref.read(unreadMessageCountProvider.notifier).refresh();

      if (mounted) {
        // Navigate to the conversation, replacing this screen
        context.pushReplacement(
          '/messages/${result.conversationId}?name=${widget.traineeName ?? ""}',
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = 'Failed to send message. Please try again.';
        });
      }
      return false;
    }
  }
}
