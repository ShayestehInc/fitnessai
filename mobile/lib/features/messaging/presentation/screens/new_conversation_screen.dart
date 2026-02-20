import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/messaging_provider.dart';
import '../widgets/chat_input.dart';

/// Screen for starting a new conversation with a trainee.
/// Shows an input field to send the first message.
class NewConversationScreen extends ConsumerWidget {
  final int traineeId;
  final String? traineeName;

  const NewConversationScreen({
    super.key,
    required this.traineeId,
    this.traineeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final newConvState = ref.watch(newConversationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(traineeName ?? 'New Message'),
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
                      'Send a message to ${traineeName ?? 'this trainee'}',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (newConvState.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        newConvState.error!,
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
            onSend: (content, {String? imagePath}) =>
                _handleSend(context, ref, content, imagePath: imagePath),
            isSending: newConvState.isSending,
          ),
        ],
      ),
    );
  }

  Future<bool> _handleSend(
    BuildContext context,
    WidgetRef ref,
    String content, {
    String? imagePath,
  }) async {
    final notifier = ref.read(newConversationProvider.notifier);
    final result = await notifier.startConversation(
      traineeId: traineeId,
      content: content,
      imagePath: imagePath,
    );

    if (result == null) {
      return false;
    }

    // Refresh conversation list and unread count
    ref.read(conversationListProvider.notifier).loadConversations();
    ref.read(unreadMessageCountProvider.notifier).refresh();

    if (context.mounted) {
      // Navigate to the conversation, replacing this screen
      context.pushReplacement(
        '/messages/${result.conversationId}?name=${traineeName ?? ""}',
      );
    }
    return true;
  }
}
