import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/nutrition/presentation/screens/add_food_screen.dart';
import '../../features/nutrition/presentation/screens/weight_checkin_screen.dart';
import '../../features/workout_log/presentation/screens/workout_log_screen.dart';
import '../../features/forums/presentation/screens/forums_screen.dart';
import '../../features/tv/presentation/screens/tv_screen.dart';
import '../../features/logging/presentation/screens/ai_command_center_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/edit_goals_screen.dart';
import '../../features/settings/presentation/screens/edit_diet_screen.dart';
import '../../features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import '../../features/trainer/presentation/screens/trainee_list_screen.dart';
import '../../features/trainer/presentation/screens/trainee_detail_screen.dart';
import '../../features/trainer/presentation/screens/invite_trainee_screen.dart';
import '../../features/trainer/presentation/screens/assign_program_screen.dart';
import '../../features/exercises/presentation/screens/exercise_bank_screen.dart';
import '../../features/programs/presentation/screens/programs_screen.dart';
import '../../features/feature_requests/presentation/screens/feature_requests_screen.dart';
import '../../features/feature_requests/presentation/screens/submit_feature_screen.dart';
import '../../features/feature_requests/presentation/screens/feature_detail_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import '../../shared/widgets/trainer_navigation_shell.dart';

// Navigation keys for branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _trainerShellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Onboarding route (outside shell)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingWizardScreen(),
      ),

      // Trainer Shell - separate navigation for trainers
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TrainerNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer',
                name: 'trainer-dashboard',
                builder: (context, state) => const TrainerDashboardScreen(),
              ),
            ],
          ),

          // Trainees branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer/trainees',
                name: 'trainer-trainees',
                builder: (context, state) => const TraineeListScreen(),
              ),
            ],
          ),

          // Programs branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer/programs',
                name: 'trainer-programs',
                builder: (context, state) => const ProgramsScreen(),
              ),
            ],
          ),

          // Exercises branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer/exercises',
                name: 'trainer-exercises',
                builder: (context, state) => const ExerciseBankScreen(),
              ),
            ],
          ),

          // Settings branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer/settings',
                name: 'trainer-settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Trainer detail routes (outside shell)
      GoRoute(
        path: '/trainer/trainees/:id',
        name: 'trainee-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return TraineeDetailScreen(traineeId: id);
        },
      ),
      GoRoute(
        path: '/trainer/invite',
        name: 'trainer-invite',
        builder: (context, state) => const InviteTraineeScreen(),
      ),
      GoRoute(
        path: '/trainer/programs/assign/:id',
        name: 'assign-program',
        builder: (context, state) {
          final traineeId = int.parse(state.pathParameters['id']!);
          return AssignProgramScreen(traineeId: traineeId);
        },
      ),

      // Main app shell with bottom navigation (for trainees)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Diet/Nutrition branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/diet',
                name: 'diet',
                builder: (context, state) => const NutritionScreen(),
              ),
            ],
          ),

          // Logbook/Workout branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/logbook',
                name: 'logbook',
                builder: (context, state) => const WorkoutLogScreen(),
              ),
            ],
          ),

          // Forums branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/forums',
                name: 'forums',
                builder: (context, state) => const ForumsScreen(),
              ),
            ],
          ),

          // TV branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tv',
                name: 'tv',
                builder: (context, state) => const TvScreen(),
              ),
            ],
          ),
        ],
      ),

      // Feature requests (accessible by both trainers and trainees)
      GoRoute(
        path: '/feature-requests',
        name: 'feature-requests',
        builder: (context, state) => const FeatureRequestsScreen(),
      ),
      GoRoute(
        path: '/feature-requests/submit',
        name: 'submit-feature',
        builder: (context, state) => const SubmitFeatureScreen(),
      ),
      GoRoute(
        path: '/feature-requests/:id',
        name: 'feature-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return FeatureDetailScreen(featureId: id);
        },
      ),

      // Routes outside the navigation shell (modals, full-screen)
      GoRoute(
        path: '/ai-command',
        name: 'ai-command',
        builder: (context, state) => const AICommandCenterScreen(),
      ),
      GoRoute(
        path: '/add-food',
        name: 'add-food',
        builder: (context, state) {
          final mealParam = state.uri.queryParameters['meal'];
          final mealNumber = mealParam != null ? int.tryParse(mealParam) : null;
          return AddFoodScreen(mealNumber: mealNumber);
        },
      ),
      GoRoute(
        path: '/weight-checkin',
        name: 'weight-checkin',
        builder: (context, state) => const WeightCheckInScreen(),
      ),

      // Settings routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/edit-goals',
        name: 'edit-goals',
        builder: (context, state) => const EditGoalsScreen(),
      ),
      GoRoute(
        path: '/edit-diet',
        name: 'edit-diet',
        builder: (context, state) => const EditDietScreen(),
      ),

      // Legacy dashboard route (redirect to home)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        redirect: (context, state) => '/home',
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // If not logged in, redirect to login (except for register)
      if (!isLoggedIn) {
        if (isRegistering) return null;
        if (!isLoggingIn) return '/login';
        return null;
      }

      // If logged in and on auth pages, redirect based on role and onboarding status
      if (isLoggingIn || isRegistering) {
        final user = authState.user!;

        // Trainers go to trainer dashboard
        if (user.isTrainer) {
          return '/trainer';
        }

        // Trainees check onboarding status
        if (user.isTrainee && !user.onboardingCompleted) {
          return '/onboarding';
        }

        return '/home';
      }

      // If logged in trainee on main app but needs onboarding
      if (isLoggedIn && authState.user!.isTrainee && !authState.user!.onboardingCompleted) {
        if (!isOnboarding) {
          return '/onboarding';
        }
      }

      return null;
    },
  );
});
