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
  final result = await repo.getTemplates();
  if (result['success'] == true) {
    return result['templates'] as List<NutritionTemplateModel>;
  }
  return [];
});

/// Active template assignment for the current trainee.
final activeAssignmentProvider =
    FutureProvider<NutritionTemplateAssignmentModel?>((ref) async {
  final repo = ref.watch(nutritionTemplateRepositoryProvider);
  final result = await repo.getActiveAssignment();
  if (result['success'] == true) {
    return result['assignment'] as NutritionTemplateAssignmentModel?;
  }
  return null;
});

/// Day plan for a specific date.
final dayPlanProvider = FutureProvider.family<NutritionDayPlanModel?, String>(
  (ref, date) async {
    final repo = ref.watch(nutritionTemplateRepositoryProvider);
    final result = await repo.getDayPlan(date);
    if (result['success'] == true) {
      return result['plan'] as NutritionDayPlanModel?;
    }
    return null;
  },
);

/// Week of day plans starting from a date.
final weekPlansProvider =
    FutureProvider.family<List<NutritionDayPlanModel>, String>(
  (ref, startDate) async {
    final repo = ref.watch(nutritionTemplateRepositoryProvider);
    final result = await repo.getWeekPlans(startDate);
    if (result['success'] == true) {
      return result['plans'] as List<NutritionDayPlanModel>;
    }
    return [];
  },
);
