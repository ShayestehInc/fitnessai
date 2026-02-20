import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart'
    show MessageModel, MessageSender, MessagesResponse, StartConversationResponse;
import '../../data/repositories/messaging_repository.dart';

// ---------------------------------------------------------------------------
// Conversation list provider
// ---------------------------------------------------------------------------

class ConversationListState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationListState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationListState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, ConversationListState>(
        (ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConversationListNotifier(MessagingRepository(apiClient));
});

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final MessagingRepository _repo;

  ConversationListNotifier(this._repo)
      : super(const ConversationListState());

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversations = await _repo.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('ConversationListNotifier.loadConversations() failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversations.',
      );
    }
  }

  /// Update a conversation after a new message (optimistic).
  void onNewMessageInConversation(
    int conversationId,
    String preview,
    DateTime timestamp,
  ) {
    final updated = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(
          lastMessagePreview: preview,
          lastMessageAt: timestamp,
          unreadCount: c.unreadCount + 1,
        );
      }
      return c;
    }).toList();
    // Re-sort by most recent
    updated.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    state = state.copyWith(conversations: updated);
  }

  /// Reset unread count for a conversation.
  void markConversationRead(int conversationId) {
    state = state.copyWith(
      conversations: state.conversations.map((c) {
        if (c.id == conversationId) {
          return c.copyWith(unreadCount: 0);
        }
        return c;
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Unread count provider
// ---------------------------------------------------------------------------

final unreadMessageCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UnreadCountNotifier(MessagingRepository(apiClient));
});

class UnreadCountNotifier extends StateNotifier<int> {
  final MessagingRepository _repo;

  UnreadCountNotifier(this._repo) : super(0);

  Future<void> refresh() async {
    try {
      final count = await _repo.getUnreadCount();
      state = count;
    } catch (e) {
      // Keep current count on error, but log it
      // Keep current count on error — non-fatal background operation
    }
  }

  void increment() {
    state = state + 1;
  }

  void decrement(int by) {
    state = (state - by).clamp(0, 999999);
  }
}

// ---------------------------------------------------------------------------
// New conversation state provider
// ---------------------------------------------------------------------------

class NewConversationState {
  final bool isSending;
  final String? error;

  const NewConversationState({
    this.isSending = false,
    this.error,
  });

  NewConversationState copyWith({
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return NewConversationState(
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final newConversationProvider =
    StateNotifierProvider<NewConversationNotifier, NewConversationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NewConversationNotifier(MessagingRepository(apiClient));
});

class NewConversationNotifier extends StateNotifier<NewConversationState> {
  final MessagingRepository _repo;

  NewConversationNotifier(this._repo) : super(const NewConversationState());

  Future<StartConversationResponse?> startConversation({
    required int traineeId,
    String content = '',
    String? imagePath,
  }) async {
    state = const NewConversationState(isSending: true);
    try {
      final result = await _repo.startConversation(
        traineeId: traineeId,
        content: content,
        imagePath: imagePath,
      );
      state = const NewConversationState(isSending: false);
      return result;
    } catch (e) {
      state = const NewConversationState(
        isSending: false,
        error: 'Failed to send message. Please try again.',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ---------------------------------------------------------------------------
// Chat (single conversation) provider
// ---------------------------------------------------------------------------

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final bool isSending;
  final int? typingUserId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.isSending = false,
    this.typingUserId,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
    bool? isSending,
    int? typingUserId,
    bool clearTyping = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
      isSending: isSending ?? this.isSending,
      typingUserId: clearTyping ? null : (typingUserId ?? this.typingUserId),
    );
  }
}

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, int>(
        (ref, conversationId) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatNotifier(MessagingRepository(apiClient), conversationId);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final MessagingRepository _repo;
  final int conversationId;

  ChatNotifier(this._repo, this.conversationId) : super(const ChatState());

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.getMessages(
        conversationId: conversationId,
        page: 1,
      );
      // Messages come newest-first from API, reverse for display
      state = state.copyWith(
        messages: response.results.reversed.toList(),
        isLoading: false,
        hasMore: response.next != null,
        currentPage: 1,
      );
    } catch (e) {
      debugPrint('ChatNotifier.loadMessages() failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages.',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final response = await _repo.getMessages(
        conversationId: conversationId,
        page: nextPage,
      );
      // Prepend older messages (they come newest-first, so reverse)
      state = state.copyWith(
        messages: [
          ...response.results.reversed.toList(),
          ...state.messages,
        ],
        isLoadingMore: false,
        hasMore: response.next != null,
        currentPage: nextPage,
      );
    } catch (e) {
      debugPrint('ChatNotifier.loadMore() failed: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Counter for generating temporary negative IDs for optimistic messages.
  int _tempIdCounter = -1;

  Future<bool> sendMessage(
    String content, {
    String? imagePath,
    int? senderId,
    String? senderFirstName,
    String? senderLastName,
  }) async {
    state = state.copyWith(isSending: true);

    // Create optimistic message for immediate display
    final tempId = _tempIdCounter--;
    final optimistic = MessageModel(
      id: tempId,
      conversationId: conversationId,
      sender: MessageSender(
        id: senderId ?? 0,
        firstName: senderFirstName ?? '',
        lastName: senderLastName ?? '',
      ),
      content: content,
      localImagePath: imagePath,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, optimistic],
    );

    try {
      final message = await _repo.sendMessage(
        conversationId: conversationId,
        content: content,
        imagePath: imagePath,
      );
      // Remove the optimistic message and any WebSocket duplicate, then add the server response
      final updated = state.messages
          .where((m) => m.id != tempId && m.id != message.id)
          .toList()
        ..add(message);
      state = state.copyWith(
        messages: updated,
        isSending: false,
      );
      return true;
    } catch (e) {
      // Mark optimistic message as failed
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == tempId) return m.copyWith(isSendFailed: true);
          return m;
        }).toList(),
        isSending: false,
        error: 'Failed to send message.',
      );
      return false;
    }
  }

  Future<void> markRead() async {
    try {
      await _repo.markRead(conversationId);
      // Mark all messages as read locally
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (!m.isRead) {
            return m.copyWith(isRead: true, readAt: DateTime.now());
          }
          return m;
        }).toList(),
      );
    } catch (e) {
      // Mark-read failure is non-fatal — messages still display correctly
    }
  }

  /// Handle new message from WebSocket.
  void onNewMessage(MessageModel message) {
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(
      messages: [...state.messages, message],
      clearTyping: true,
    );
  }

  /// Handle typing indicator from WebSocket.
  void onTypingIndicator(int userId, bool isTyping) {
    if (isTyping) {
      state = state.copyWith(typingUserId: userId);
    } else {
      if (state.typingUserId == userId) {
        state = state.copyWith(clearTyping: true);
      }
    }
  }

  /// Handle read receipt from WebSocket.
  void onReadReceipt(int readerId, DateTime readAt) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        // Mark messages sent by the current user as read
        // (the reader is the other party)
        if (!m.isRead && m.sender.id != readerId) {
          return m.copyWith(isRead: true, readAt: readAt);
        }
        return m;
      }).toList(),
    );
  }

  /// Handle message-edited event from WebSocket.
  void onMessageEdited(int messageId, String newContent, DateTime editedAt) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: newContent, editedAt: editedAt);
        }
        return m;
      }).toList(),
    );
  }

  /// Handle message-deleted event from WebSocket.
  void onMessageDeleted(int messageId) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(
            content: '',
            isDeleted: true,
            clearImage: true,
          );
        }
        return m;
      }).toList(),
    );
  }

  /// Edit a message. Optimistic update, revert on error.
  Future<bool> editMessage(int messageId, String newContent) async {
    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;
    final original = state.messages[idx];

    // Optimistic update
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: newContent, editedAt: DateTime.now());
        }
        return m;
      }).toList(),
    );

    try {
      await _repo.editMessage(
        conversationId: conversationId,
        messageId: messageId,
        content: newContent,
      );
      return true;
    } catch (e) {
      // Revert optimistic update
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return original;
          }
          return m;
        }).toList(),
        error: 'Failed to edit message.',
      );
      return false;
    }
  }

  /// Delete a message. Optimistic update, revert on error.
  Future<bool> deleteMessage(int messageId) async {
    final idx = state.messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;
    final original = state.messages[idx];

    // Optimistic update
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: '', isDeleted: true, clearImage: true);
        }
        return m;
      }).toList(),
    );

    try {
      await _repo.deleteMessage(
        conversationId: conversationId,
        messageId: messageId,
      );
      return true;
    } catch (e) {
      // Revert optimistic update
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return original;
          }
          return m;
        }).toList(),
        error: 'Failed to delete message.',
      );
      return false;
    }
  }
}
