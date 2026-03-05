import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/workout_template_model.dart';
import '../../data/repositories/quick_log_repository.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final quickLogRepositoryProvider = Provider<QuickLogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuickLogRepository(apiClient);
});

// ---------------------------------------------------------------------------
// Templates — fetched per category (null = all)
// ---------------------------------------------------------------------------

final workoutTemplatesProvider = FutureProvider.autoDispose
    .family<List<WorkoutTemplateModel>, String?>((ref, category) async {
  final repository = ref.watch(quickLogRepositoryProvider);
  final result = await repository.getWorkoutTemplates(category: category);
  if (result['success'] == true) {
    return result['data'] as List<WorkoutTemplateModel>;
  }
  throw Exception(result['error'] ?? 'Failed to load templates');
});

// ---------------------------------------------------------------------------
// UI state providers
// ---------------------------------------------------------------------------

/// Currently selected category tab (null = show all).
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Currently selected template.
final selectedTemplateProvider =
    StateProvider<WorkoutTemplateModel?>((ref) => null);

/// Duration slider value in minutes.
final quickLogDurationProvider = StateProvider<int>((ref) => 30);

/// Manually-edited calorie value (null = use auto-calculated).
final quickLogCaloriesOverrideProvider = StateProvider<double?>((ref) => null);

/// Notes text.
final quickLogNotesProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// Derived: effective calories
// ---------------------------------------------------------------------------

/// Returns the effective calorie value — override if set, otherwise
/// auto-calculated from the selected template and duration.
final effectiveCaloriesProvider = Provider<double>((ref) {
  final override = ref.watch(quickLogCaloriesOverrideProvider);
  if (override != null) return override;

  final template = ref.watch(selectedTemplateProvider);
  final duration = ref.watch(quickLogDurationProvider);
  if (template == null) return 0;
  return template.estimatedCalories(duration);
});

// ---------------------------------------------------------------------------
// Submit action
// ---------------------------------------------------------------------------

final quickLogSubmitProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, void>(
  (ref, _) async {
    final repository = ref.watch(quickLogRepositoryProvider);
    final template = ref.read(selectedTemplateProvider);
    final duration = ref.read(quickLogDurationProvider);
    final calories = ref.read(effectiveCaloriesProvider);
    final notes = ref.read(quickLogNotesProvider);

    if (template == null) {
      throw Exception('Please select a workout template');
    }
    if (duration <= 0) {
      throw Exception('Duration must be greater than zero');
    }

    final result = await repository.submitQuickLog(
      templateId: template.id,
      durationMinutes: duration,
      caloriesBurned: calories,
      notes: notes.isNotEmpty ? notes : null,
    );

    if (result['success'] == true) {
      return result;
    }
    throw Exception(result['error'] ?? 'Failed to submit quick log');
  },
);
