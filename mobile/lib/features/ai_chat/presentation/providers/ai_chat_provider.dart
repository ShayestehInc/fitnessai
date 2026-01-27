import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/ai_chat_repository.dart';

// Repository provider
final aiChatRepositoryProvider = Provider<AIChatRepository>((ref) {
  return AIChatRepository(ApiClient());
});

// Trainees list provider
final traineesForChatProvider = FutureProvider<List<TraineeOption>>((ref) async {
  final repository = ref.watch(aiChatRepositoryProvider);
  return repository.getTrainees();
});

// Chat state
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final int? selectedTraineeId;
  final String? selectedTraineeName;

  AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.selectedTraineeId,
    this.selectedTraineeName,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    int? selectedTraineeId,
    String? selectedTraineeName,
    bool clearTrainee = false,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedTraineeId: clearTrainee ? null : (selectedTraineeId ?? this.selectedTraineeId),
      selectedTraineeName: clearTrainee ? null : (selectedTraineeName ?? this.selectedTraineeName),
    );
  }
}

// Chat notifier
class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIChatRepository _repository;

  AIChatNotifier(this._repository) : super(AIChatState());

  /// Select a trainee to focus the conversation on
  void selectTrainee(int? traineeId, String? traineeName) {
    if (traineeId == null) {
      state = state.copyWith(clearTrainee: true);
    } else {
      state = state.copyWith(
        selectedTraineeId: traineeId,
        selectedTraineeName: traineeName,
      );
    }
  }

  /// Send a message to the AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage.user(message);
    final updatedMessages = [...state.messages, userMessage];

    // Add loading indicator
    state = state.copyWith(
      messages: [...updatedMessages, ChatMessage.loading()],
      isLoading: true,
      error: null,
    );

    // Get conversation history (exclude loading message)
    final history = updatedMessages.length > 1
        ? updatedMessages.sublist(0, updatedMessages.length - 1)
        : null;

    // Send to API
    final response = await _repository.sendMessage(
      message: message,
      conversationHistory: history,
      traineeId: state.selectedTraineeId,
    );

    // Remove loading indicator and add response
    if (response.error != null) {
      state = state.copyWith(
        messages: updatedMessages, // Remove loading
        isLoading: false,
        error: response.error,
      );
    } else {
      final assistantMessage = ChatMessage.assistant(
        response.response,
        traineeContextUsed: response.traineeContextUsed,
      );
      state = state.copyWith(
        messages: [...updatedMessages, assistantMessage],
        isLoading: false,
      );
    }
  }

  /// Clear conversation
  void clearConversation() {
    state = AIChatState(
      selectedTraineeId: state.selectedTraineeId,
      selectedTraineeName: state.selectedTraineeName,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return AIChatNotifier(repository);
});
