import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../logging/data/repositories/logging_repository.dart';
import '../../../logging/data/models/parsed_log_model.dart';

final loggingRepositoryProvider = Provider<LoggingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoggingRepository(apiClient);
});

final loggingStateProvider =
    StateNotifierProvider.autoDispose<LoggingNotifier, LoggingState>((ref) {
  final repository = ref.watch(loggingRepositoryProvider);
  return LoggingNotifier(repository);
});

class LoggingState {
  final ParsedLogModel? parsedData;
  final bool isProcessing;
  final bool isSaving;
  final String? error;
  final String? clarificationQuestion;

  LoggingState({
    this.parsedData,
    this.isProcessing = false,
    this.isSaving = false,
    this.error,
    this.clarificationQuestion,
  });

  LoggingState copyWith({
    ParsedLogModel? parsedData,
    bool? isProcessing,
    bool? isSaving,
    String? error,
    String? clarificationQuestion,
  }) {
    return LoggingState(
      parsedData: parsedData ?? this.parsedData,
      isProcessing: isProcessing ?? this.isProcessing,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      clarificationQuestion: clarificationQuestion,
    );
  }
}

class LoggingNotifier extends StateNotifier<LoggingState> {
  final LoggingRepository _repository;

  LoggingNotifier(this._repository) : super(LoggingState());

  /// Parse natural language input (optimistic UI)
  Future<void> parseInput(String userInput, {String? date}) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _repository.parseNaturalLanguage(userInput, date: date);

    if (result['success'] == true) {
      final parsedData = result['data'] as ParsedLogModel;
      
      if (parsedData.needsClarification) {
        state = state.copyWith(
          isProcessing: false,
          clarificationQuestion: parsedData.clarificationQuestion,
        );
      } else {
        state = state.copyWith(
          parsedData: parsedData,
          isProcessing: false,
        );
      }
    } else {
      state = state.copyWith(
        isProcessing: false,
        error: result['error'] as String,
      );
    }
  }

  /// Confirm and save the parsed log
  Future<bool> confirmAndSave({String? date}) async {
    if (state.parsedData == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    // Convert ParsedLogModel to JSON for API
    final parsedJson = {
      'nutrition': {
        'meals': state.parsedData!.nutrition.meals
            .map((m) => {
                  'name': m.name,
                  'protein': m.protein,
                  'carbs': m.carbs,
                  'fat': m.fat,
                  'calories': m.calories,
                  'timestamp': m.timestamp,
                })
            .toList(),
      },
      'workout': {
        'exercises': state.parsedData!.workout.exercises
            .map((e) => {
                  'exercise_name': e.exerciseName,
                  'sets': e.sets,
                  'reps': e.reps,
                  'weight': e.weight,
                  'unit': e.unit,
                  'timestamp': e.timestamp,
                })
            .toList(),
      },
      'confidence': state.parsedData!.confidence,
      'needs_clarification': state.parsedData!.needsClarification,
    };

    final result = await _repository.confirmAndSave(parsedJson, date: date);

    if (result['success'] == true) {
      state = LoggingState(); // Reset state
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String,
      );
      return false;
    }
  }

  void clearState() {
    state = LoggingState();
  }

  /// Save a manual food entry directly (no AI parsing)
  Future<bool> saveManualFoodEntry({
    required String name,
    required int protein,
    required int carbs,
    required int fat,
    required int calories,
    String? date,
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    // Build the parsed data structure for manual entry
    final parsedJson = {
      'nutrition': {
        'meals': [
          {
            'name': name,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'calories': calories,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      },
      'workout': {
        'exercises': [],
      },
      'confidence': 1.0,
      'needs_clarification': false,
    };

    final result = await _repository.confirmAndSave(parsedJson, date: date);

    if (result['success'] == true) {
      state = LoggingState(); // Reset state
      return true;
    } else {
      state = state.copyWith(
        isSaving: false,
        error: result['error'] as String?,
      );
      return false;
    }
  }
}
