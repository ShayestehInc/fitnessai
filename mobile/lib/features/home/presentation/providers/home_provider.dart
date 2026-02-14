import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nutrition/data/repositories/nutrition_repository.dart';
import '../../../nutrition/data/models/nutrition_models.dart';
import '../../../workout_log/data/repositories/workout_repository.dart';
import '../../../workout_log/data/models/workout_models.dart';
import '../../../programs/data/models/program_week_model.dart';

final homeStateProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final nutritionRepo = NutritionRepository(apiClient);
  final workoutRepo = WorkoutRepository(apiClient);
  return HomeNotifier(nutritionRepo, workoutRepo);
});

/// Represents the next scheduled workout
class NextWorkout {
  final String dayName;
  final String phaseName;
  final int weekNumber;
  final int dayNumber;
  final List<WorkoutExercise> exercises;
  final bool isRestDay;

  const NextWorkout({
    required this.dayName,
    required this.phaseName,
    required this.weekNumber,
    required this.dayNumber,
    required this.exercises,
    required this.isRestDay,
  });
}

/// Represents a video in the Latest Videos section
class VideoItem {
  final int id;
  final String title;
  final String thumbnailUrl;
  final String? videoUrl;
  final String date;
  final int likes;
  final bool isLiked;

  const VideoItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.videoUrl,
    required this.date,
    this.likes = 0,
    this.isLiked = false,
  });
}

/// Weekly progress data from the API
class WeeklyProgressData {
  final int totalDays;
  final int completedDays;
  final int percentage;
  final bool hasProgram;

  const WeeklyProgressData({
    required this.totalDays,
    required this.completedDays,
    required this.percentage,
    required this.hasProgram,
  });
}

class HomeState {
  final NutritionGoalModel? nutritionGoals;
  final DailyNutritionSummary? todayNutrition;
  final ProgramModel? activeProgram;
  final NextWorkout? nextWorkout;
  final List<VideoItem> latestVideos;
  final int programProgress; // 0-100
  final WeeklyProgressData? weeklyProgress;
  final bool isLoading;
  final String? error;

  HomeState({
    this.nutritionGoals,
    this.todayNutrition,
    this.activeProgram,
    this.nextWorkout,
    this.latestVideos = const [],
    this.programProgress = 0,
    this.weeklyProgress,
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    NutritionGoalModel? nutritionGoals,
    DailyNutritionSummary? todayNutrition,
    ProgramModel? activeProgram,
    NextWorkout? nextWorkout,
    List<VideoItem>? latestVideos,
    int? programProgress,
    WeeklyProgressData? weeklyProgress,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
      todayNutrition: todayNutrition ?? this.todayNutrition,
      activeProgram: activeProgram ?? this.activeProgram,
      nextWorkout: nextWorkout ?? this.nextWorkout,
      latestVideos: latestVideos ?? this.latestVideos,
      programProgress: programProgress ?? this.programProgress,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Computed values
  int get caloriesRemaining {
    final goal = nutritionGoals?.caloriesGoal ?? 0;
    final consumed = todayNutrition?.consumed.calories ?? 0;
    return (goal - consumed).clamp(0, goal);
  }

  int get caloriesGoal => nutritionGoals?.caloriesGoal ?? 0;
  int get caloriesConsumed => todayNutrition?.consumed.calories ?? 0;

  double get caloriesProgress {
    if (caloriesGoal == 0) return 0;
    return caloriesConsumed / caloriesGoal;
  }

  int get proteinGoal => nutritionGoals?.proteinGoal ?? 0;
  int get proteinConsumed => todayNutrition?.consumed.protein ?? 0;
  double get proteinProgress {
    if (proteinGoal == 0) return 0;
    return proteinConsumed / proteinGoal;
  }

  int get carbsGoal => nutritionGoals?.carbsGoal ?? 0;
  int get carbsConsumed => todayNutrition?.consumed.carbs ?? 0;
  double get carbsProgress {
    if (carbsGoal == 0) return 0;
    return carbsConsumed / carbsGoal;
  }

  int get fatGoal => nutritionGoals?.fatGoal ?? 0;
  int get fatConsumed => todayNutrition?.consumed.fat ?? 0;
  double get fatProgress {
    if (fatGoal == 0) return 0;
    return fatConsumed / fatGoal;
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final NutritionRepository _nutritionRepo;
  final WorkoutRepository _workoutRepo;

  HomeNotifier(this._nutritionRepo, this._workoutRepo) : super(HomeState());

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _nutritionRepo.getNutritionGoals(),
        _nutritionRepo.getDailyNutritionSummary(_todayDate()),
        _workoutRepo.getActiveProgram(),
        _nutritionRepo.getWeeklyProgress(),
      ]);

      final goalsResult = results[0];
      final nutritionResult = results[1];
      final programResult = results[2];
      final weeklyResult = results[3];

      ProgramModel? program;
      NextWorkout? nextWorkout;
      int programProgress = 0;
      WeeklyProgressData? weeklyProgress;

      if (programResult['success'] == true) {
        program = programResult['program'] as ProgramModel;

        // Calculate program progress and next workout
        final progressData = _calculateProgramProgress(program);
        programProgress = progressData['progress'] as int;
        nextWorkout = progressData['nextWorkout'] as NextWorkout?;
      }

      // Parse weekly progress from API
      if (weeklyResult['success'] == true) {
        final data = weeklyResult['data'] as Map<String, dynamic>;
        weeklyProgress = WeeklyProgressData(
          totalDays: data['total_days'] as int? ?? 0,
          completedDays: data['completed_days'] as int? ?? 0,
          percentage: data['percentage'] as int? ?? 0,
          hasProgram: data['has_program'] as bool? ?? false,
        );
      }

      // Load sample latest videos (in a real app, this would come from an API)
      final latestVideos = _getSampleVideos();

      state = state.copyWith(
        isLoading: false,
        nutritionGoals: goalsResult['success'] == true
            ? goalsResult['goals'] as NutritionGoalModel
            : null,
        todayNutrition: nutritionResult['success'] == true
            ? nutritionResult['summary'] as DailyNutritionSummary
            : null,
        activeProgram: program,
        nextWorkout: nextWorkout,
        programProgress: programProgress,
        weeklyProgress: weeklyProgress,
        latestVideos: latestVideos,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Map<String, dynamic> _calculateProgramProgress(ProgramModel program) {
    final now = DateTime.now();
    final startDate = DateTime.tryParse(program.startDate) ?? now;

    // Determine current week and day
    final daysPassed = now.difference(startDate).inDays.clamp(0, 999);
    final currentWeek = (daysPassed ~/ 7) + 1;
    final currentDayOfWeek = daysPassed % 7;

    // Parse schedule to get weeks
    // Schedule can be:
    // 1. A List of week objects (new API format): [{"days": [...], "title": "Week 1"}, ...]
    // 2. A Map with 'weeks' key: {"weeks": [...]}
    // 3. A Map with numeric keys: {"0": {...}, "1": {...}}
    List<dynamic>? weeks;
    final schedule = program.schedule;

    if (schedule != null) {
      if (schedule is List && schedule.isNotEmpty) {
        // New API format: schedule is directly a list of weeks
        weeks = schedule;
      } else if (schedule is Map<String, dynamic> && schedule.isNotEmpty) {
        // Check if schedule has a 'weeks' key with a list
        if (schedule.containsKey('weeks') && schedule['weeks'] is List) {
          weeks = schedule['weeks'] as List;
        } else {
          // The schedule itself might be serialized from a list
          final keys = schedule.keys.toList();
          final isNumericKeys = keys.isNotEmpty &&
              keys.every((k) => int.tryParse(k.toString()) != null);

          if (isNumericKeys) {
            final sortedKeys = keys.map((k) => int.parse(k.toString())).toList()..sort();
            weeks = sortedKeys.map((k) => schedule[k.toString()]).toList();
          } else {
            weeks = schedule.values.toList();
          }
        }
      }
    }

    // Calculate progress based on COMPLETED workouts, not time
    // For now, since we don't have completion data, show 0%
    // TODO: Track actual workout completion and calculate real progress
    int progress = 0;

    // Count total workout days (non-rest days) in the program
    int totalWorkoutDays = 0;
    int completedWorkoutDays = 0; // TODO: Get from actual completion data

    if (weeks != null) {
      for (final week in weeks) {
        if (week is Map<String, dynamic>) {
          final days = week['days'] as List?;
          if (days != null) {
            for (final day in days) {
              if (day is Map<String, dynamic>) {
                final isRestDay = day['is_rest_day'] as bool? ?? false;
                final dayName = day['name'] as String? ?? '';
                final isRestByName = dayName.toLowerCase().contains('rest');
                // Count as workout day only if not a rest day
                if (!isRestDay && !isRestByName) {
                  totalWorkoutDays++;
                }
              }
            }
          }
        }
      }
    }

    // Progress = completed workouts / total workouts
    if (totalWorkoutDays > 0) {
      progress = ((completedWorkoutDays / totalWorkoutDays) * 100).round();
    }

    // Find next workout (skip rest days)
    NextWorkout? nextWorkout;

    if (weeks != null && weeks.isNotEmpty) {
      // Start from current week and day, find the next non-rest workout
      int weekIndex = (currentWeek - 1).clamp(0, weeks.length - 1);
      int dayIndex = currentDayOfWeek;

      // Search through weeks starting from current position
      while (weekIndex < weeks.length) {
        final weekData = weeks[weekIndex];
        if (weekData is Map<String, dynamic>) {
          final days = weekData['days'] as List?;
          if (days != null) {
            // Search through days in this week
            while (dayIndex < days.length) {
              final dayData = days[dayIndex];
              if (dayData is Map<String, dynamic>) {
                final isRestDay = dayData['is_rest_day'] as bool? ?? false;
                final dayName = dayData['name'] as String? ?? 'Workout';

                // Also check if day name contains "rest" (case insensitive) as a fallback
                final isRestByName = dayName.toLowerCase().contains('rest');
                final shouldSkip = isRestDay || isRestByName;

                // Skip rest days - only show actual workouts
                if (!shouldSkip) {
                  final exercisesList = dayData['exercises'] as List? ?? [];
                  final exercises = exercisesList
                      .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
                      .toList();

                  nextWorkout = NextWorkout(
                    dayName: dayName,
                    phaseName: weekData['title'] as String? ?? 'Week ${weekIndex + 1}',
                    weekNumber: weekIndex + 1,
                    dayNumber: dayIndex + 1,
                    exercises: exercises,
                    isRestDay: false,
                  );
                  break;
                }
              }
              dayIndex++;
            }

            if (nextWorkout != null) break;
          }
        }

        // Move to next week, start from day 0
        weekIndex++;
        dayIndex = 0;
      }

    }

    return {
      'progress': progress,
      'nextWorkout': nextWorkout,
    };
  }

  List<VideoItem> _getSampleVideos() {
    // Sample videos - in a real app, this would come from an API
    return const [
      VideoItem(
        id: 1,
        title: 'Advanced Glute Biomechanics with Tom & Joe',
        thumbnailUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400',
        date: '25 April',
        likes: 16,
      ),
      VideoItem(
        id: 2,
        title: 'Perfect Your Squat Form',
        thumbnailUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400',
        date: '22 April',
        likes: 24,
      ),
      VideoItem(
        id: 3,
        title: 'Upper Body Strength Training Tips',
        thumbnailUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c149a?w=400',
        date: '18 April',
        likes: 31,
      ),
    ];
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
