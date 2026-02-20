import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/messaging_ws_service.dart';
import '../providers/messaging_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

/// Full-screen chat view for a single conversation.
class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  final String? otherPartyName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherPartyName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndConnect();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadAndConnect() async {
    final notifier = ref.read(chatProvider(widget.conversationId).notifier);
    await notifier.loadMessages();
    await notifier.markRead();

    // Mark as read in conversation list
    ref
        .read(conversationListProvider.notifier)
        .markConversationRead(widget.conversationId);

    // Refresh unread count
    ref.read(unreadMessageCountProvider.notifier).refresh();

    // Connect WebSocket
    final wsService =
        ref.read(messagingWsServiceProvider(widget.conversationId));
    await wsService.connect();

    // Scroll to bottom
    _scrollToBottom();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 50) {
      ref.read(chatProvider(widget.conversationId).notifier).loadMore();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider(widget.conversationId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;

    // Scroll to bottom when new messages arrive
    ref.listen(chatProvider(widget.conversationId), (prev, next) {
      if (prev != null &&
          next.messages.length > prev.messages.length &&
          !next.isLoadingMore) {
        _scrollToBottom();
      }

      // Show snackbar when an error occurs (edit/delete failures)
      if (next.error != null &&
          (prev == null || prev.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Clear the error so it doesn't re-display on unrelated state changes
        ref
            .read(chatProvider(widget.conversationId).notifier)
            .clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherPartyName ?? 'Chat'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _buildMessageList(theme, chatState, currentUserId),
          ),

          // Chat input
          ChatInput(
            onSend: (content, {String? imagePath}) async {
              final user = ref.read(authStateProvider).user;
              final success = await ref
                  .read(chatProvider(widget.conversationId).notifier)
                  .sendMessage(
                    content,
                    imagePath: imagePath,
                    senderId: user?.id,
                    senderFirstName: user?.firstName,
                    senderLastName: user?.lastName,
                  );
              if (success) _scrollToBottom();
              return success;
            },
            onTypingStart: () {
              final wsService = ref
                  .read(messagingWsServiceProvider(widget.conversationId));
              wsService.sendTyping();
            },
            isSending: chatState.isSending,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    ThemeData theme,
    ChatState chatState,
    int? currentUserId,
  ) {
    // Loading state
    if (chatState.isLoading) {
      return _buildSkeletonMessages(theme);
    }

    // Error state
    if (chatState.error != null && chatState.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                chatState.error!,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(chatProvider(widget.conversationId).notifier)
                    .loadMessages(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (chatState.messages.isEmpty) {
      return Center(
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
              'No messages yet.\nSend the first message!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: chatState.messages.length +
          (chatState.isLoadingMore ? 1 : 0) +
          (chatState.typingUserId != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading more indicator at top
        if (chatState.isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final messageIndex =
            chatState.isLoadingMore ? index - 1 : index;

        // Typing indicator at bottom
        if (messageIndex >= chatState.messages.length) {
          return const TypingIndicator();
        }

        final message = chatState.messages[messageIndex];
        final isMine = message.sender.id == currentUserId;
        final isLastMessage = messageIndex == chatState.messages.length - 1;

        return MessageBubble(
          message: message,
          isMine: isMine,
          showReadReceipt: isMine && isLastMessage,
          onEdit: isMine && !message.isDeleted
              ? (newContent) {
                  ref
                      .read(chatProvider(widget.conversationId).notifier)
                      .editMessage(message.id, newContent);
                }
              : null,
          onDelete: isMine && !message.isDeleted
              ? () {
                  ref
                      .read(chatProvider(widget.conversationId).notifier)
                      .deleteMessage(message.id);
                }
              : null,
        );
      },
    );
  }

  Widget _buildSkeletonMessages(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isRight = index % 3 == 0;
        return Align(
          alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 40,
            width: 150 + (index % 3) * 40.0,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
