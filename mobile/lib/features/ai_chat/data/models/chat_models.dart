/// Chat message model
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final int? traineeContextUsed;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.traineeContextUsed,
    this.isLoading = false,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String content, {int? traineeContextUsed}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      traineeContextUsed: traineeContextUsed,
    );
  }

  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  Map<String, String> toHistoryFormat() {
    return {
      'role': role,
      'content': content,
    };
  }
}

/// Chat response from API
class ChatResponse {
  final String response;
  final int? traineeContextUsed;
  final String? provider;
  final String? model;
  final ChatUsage? usage;
  final String? error;

  ChatResponse({
    required this.response,
    this.traineeContextUsed,
    this.provider,
    this.model,
    this.usage,
    this.error,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] ?? '',
      traineeContextUsed: json['trainee_context_used'],
      provider: json['provider'],
      model: json['model'],
      usage: json['usage'] != null ? ChatUsage.fromJson(json['usage']) : null,
    );
  }

  factory ChatResponse.error(String error) {
    return ChatResponse(
      response: '',
      error: error,
    );
  }
}

/// Token usage info
class ChatUsage {
  final int inputTokens;
  final int outputTokens;

  ChatUsage({
    required this.inputTokens,
    required this.outputTokens,
  });

  factory ChatUsage.fromJson(Map<String, dynamic> json) {
    return ChatUsage(
      inputTokens: json['input_tokens'] ?? 0,
      outputTokens: json['output_tokens'] ?? 0,
    );
  }

  int get totalTokens => inputTokens + outputTokens;
}

/// Trainee option for chat context
class TraineeOption {
  final int id;
  final String name;
  final String email;

  TraineeOption({
    required this.id,
    required this.name,
    required this.email,
  });

  factory TraineeOption.fromJson(Map<String, dynamic> json) {
    return TraineeOption(
      id: json['id'],
      name: json['display_name'] ?? json['name'] ?? json['email'],
      email: json['email'],
    );
  }
}

/// AI Provider info
class AIProviderInfo {
  final String provider;
  final String model;
  final bool configured;

  AIProviderInfo({
    required this.provider,
    required this.model,
    required this.configured,
  });

  factory AIProviderInfo.fromJson(Map<String, dynamic> json) {
    return AIProviderInfo(
      provider: json['provider'] ?? '',
      model: json['model'] ?? '',
      configured: json['configured'] ?? false,
    );
  }

  String get displayName {
    switch (provider) {
      case 'openai':
        return 'OpenAI';
      case 'anthropic':
        return 'Anthropic';
      case 'google':
        return 'Google';
      default:
        return provider;
    }
  }
}

/// AI Providers response
class AIProvidersResponse {
  final List<AIProviderInfo> providers;
  final String currentProvider;
  final String currentModel;

  AIProvidersResponse({
    required this.providers,
    required this.currentProvider,
    required this.currentModel,
  });

  factory AIProvidersResponse.fromJson(Map<String, dynamic> json) {
    final providersJson = json['providers'] as List<dynamic>? ?? [];
    final current = json['current'] as Map<String, dynamic>? ?? {};

    return AIProvidersResponse(
      providers: providersJson.map((p) => AIProviderInfo.fromJson(p)).toList(),
      currentProvider: current['provider'] ?? '',
      currentModel: current['model'] ?? '',
    );
  }
}
