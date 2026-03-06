import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/nutrition_template_models.dart';
import '../../data/repositories/nutrition_template_repository.dart';

final nutritionTemplateRepositoryProvider =
    Provider<NutritionTemplateRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NutritionTemplateRepository(apiClient);
});

/// All available nutrition templates.
final nutritionTemplatesProvider =
    FutureProvider<List<NutritionTemplateModel>>((ref) async {
  final repo = ref.watch(nutritionTemplateRepositoryProvider);
  return repo.getTemplates();
});

/// Active template assignment for the current trainee.
final activeAssignmentProvider =
    FutureProvider<NutritionTemplateAssignmentModel?>((ref) async {
  final repo = ref.watch(nutritionTemplateRepositoryProvider);
  return repo.getActiveAssignment();
});

/// Active template assignment for a specific trainee (trainer view).
final traineeActiveAssignmentProvider = FutureProvider.family<
    NutritionTemplateAssignmentModel?, int>(
  (ref, traineeId) async {
    final repo = ref.watch(nutritionTemplateRepositoryProvider);
    return repo.getActiveAssignment(traineeId: traineeId);
  },
);

/// Day plan for a specific date.
final dayPlanProvider = FutureProvider.family<NutritionDayPlanModel?, String>(
  (ref, date) async {
    final repo = ref.watch(nutritionTemplateRepositoryProvider);
    return repo.getDayPlan(date);
  },
);

/// Week of day plans starting from a date.
final weekPlansProvider =
    FutureProvider.family<List<NutritionDayPlanModel>, String>(
  (ref, startDate) async {
    final repo = ref.watch(nutritionTemplateRepositoryProvider);
    return repo.getWeekPlans(startDate);
  },
);
