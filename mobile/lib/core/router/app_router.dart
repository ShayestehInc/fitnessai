import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/nutrition/presentation/screens/add_food_screen.dart';
import '../../features/nutrition/presentation/screens/weight_checkin_screen.dart';
import '../../features/nutrition/presentation/screens/weight_trends_screen.dart';
import '../../features/workout_log/presentation/screens/workout_log_screen.dart';
import '../../features/workout_log/presentation/screens/workout_calendar_screen.dart';
import '../../features/workout_log/presentation/screens/active_workout_screen.dart';
import '../../features/workout_log/presentation/screens/my_programs_screen.dart';
import '../../features/workout_log/presentation/providers/workout_provider.dart';
import '../../features/forums/presentation/screens/forums_screen.dart';
import '../../features/tv/presentation/screens/tv_screen.dart';
import '../../features/logging/presentation/screens/ai_command_center_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/edit_name_screen.dart';
import '../../features/settings/presentation/screens/edit_goals_screen.dart';
import '../../features/settings/presentation/screens/edit_diet_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../../features/settings/presentation/screens/branding_screen.dart';
import '../../features/settings/presentation/screens/admin_notifications_screen.dart';
import '../../features/settings/presentation/screens/admin_security_screen.dart';
import '../../features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import '../../features/trainer/presentation/screens/trainee_list_screen.dart';
import '../../features/trainer/presentation/screens/trainee_detail_screen.dart';
import '../../features/trainer/presentation/screens/invite_trainee_screen.dart';
import '../../features/trainer/presentation/screens/assign_program_screen.dart';
import '../../features/trainer/presentation/screens/trainer_notifications_screen.dart';
import '../../features/exercises/presentation/screens/exercise_bank_screen.dart';
import '../../features/programs/presentation/screens/programs_screen.dart';
import '../../features/feature_requests/presentation/screens/feature_requests_screen.dart';
import '../../features/feature_requests/presentation/screens/submit_feature_screen.dart';
import '../../features/feature_requests/presentation/screens/feature_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_trainers_screen.dart';
import '../../features/admin/presentation/screens/admin_subscriptions_screen.dart';
import '../../features/admin/presentation/screens/admin_subscription_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_past_due_screen.dart';
import '../../features/admin/presentation/screens/admin_upcoming_payments_screen.dart';
import '../../features/admin/presentation/screens/admin_tiers_screen.dart';
import '../../features/admin/presentation/screens/admin_coupons_screen.dart';
import '../../features/admin/presentation/screens/admin_coupon_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_create_user_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_edit_user_screen.dart';
import '../../features/payments/presentation/screens/stripe_connect_screen.dart';
import '../../features/payments/presentation/screens/trainer_pricing_screen.dart';
import '../../features/payments/presentation/screens/trainer_payments_screen.dart';
import '../../features/payments/presentation/screens/my_subscription_screen.dart';
import '../../features/payments/presentation/screens/trainer_pricing_view_screen.dart';
import '../../features/payments/presentation/screens/trainer_coupons_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/ai_chat/presentation/screens/ai_chat_screen.dart';
import '../../features/calendar/presentation/screens/calendar_connection_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import '../../shared/widgets/trainer_navigation_shell.dart';
import '../../shared/widgets/admin_navigation_shell.dart';
import '../../features/ambassador/presentation/screens/ambassador_navigation_shell.dart';
import '../../features/ambassador/presentation/screens/ambassador_dashboard_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_referrals_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_ambassadors_screen.dart';
import '../../features/admin/presentation/screens/admin_create_ambassador_screen.dart';
import '../../features/admin/presentation/screens/admin_ambassador_detail_screen.dart';

// Navigation keys for branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _trainerShellNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

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

      // Password reset routes
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password/:uid/:token',
        name: 'reset-password',
        builder: (context, state) {
          final uid = state.pathParameters['uid']!;
          final token = state.pathParameters['token']!;
          return ResetPasswordScreen(uid: uid, token: token);
        },
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
        path: '/trainer/notifications',
        name: 'trainer-notifications',
        builder: (context, state) => const TrainerNotificationsScreen(),
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

      // Trainer payment routes
      GoRoute(
        path: '/trainer/stripe-connect',
        name: 'stripe-connect',
        builder: (context, state) => const StripeConnectScreen(),
      ),
      GoRoute(
        path: '/trainer/pricing',
        name: 'trainer-pricing',
        builder: (context, state) => const TrainerPricingScreen(),
      ),
      GoRoute(
        path: '/trainer/payments',
        name: 'trainer-payments',
        builder: (context, state) => const TrainerPaymentsScreen(),
      ),
      GoRoute(
        path: '/trainer/coupons',
        name: 'trainer-coupons',
        builder: (context, state) => const TrainerCouponsScreen(),
      ),

      // Trainer subscription (for platform subscription management)
      GoRoute(
        path: '/trainer/subscription',
        name: 'trainer-subscription',
        builder: (context, state) => const MySubscriptionScreen(),
      ),

      // AI Chat for trainers
      GoRoute(
        path: '/trainer/ai-chat',
        name: 'trainer-ai-chat',
        builder: (context, state) {
          final traineeId = state.uri.queryParameters['trainee_id'];
          final traineeName = state.uri.queryParameters['trainee_name'];
          return AIChatScreen(
            initialTraineeId: traineeId != null ? int.tryParse(traineeId) : null,
            initialTraineeName: traineeName,
          );
        },
      ),

      // Calendar integration for trainers
      GoRoute(
        path: '/trainer/calendar',
        name: 'trainer-calendar',
        builder: (context, state) => const CalendarConnectionScreen(),
      ),

      // Branding settings for trainers
      GoRoute(
        path: '/trainer/branding',
        name: 'trainer-branding',
        builder: (context, state) => const BrandingScreen(),
      ),

      // Ambassador Shell - separate navigation for ambassadors
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AmbassadorNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ambassador',
                name: 'ambassador-dashboard',
                builder: (context, state) => const AmbassadorDashboardScreen(),
              ),
            ],
          ),

          // Referrals branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ambassador/referrals',
                name: 'ambassador-referrals',
                builder: (context, state) => const AmbassadorReferralsScreen(),
              ),
            ],
          ),

          // Settings branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ambassador/settings',
                name: 'ambassador-settings',
                builder: (context, state) => const AmbassadorSettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin Shell - separate navigation for admin users
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                name: 'admin-dashboard',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),

          // Trainers branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/trainers',
                name: 'admin-trainers',
                builder: (context, state) => const AdminTrainersScreen(),
              ),
            ],
          ),

          // Subscriptions branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/subscriptions',
                name: 'admin-subscriptions',
                builder: (context, state) => const AdminSubscriptionsScreen(),
              ),
            ],
          ),

          // Settings branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                name: 'admin-settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin detail routes (outside shell)
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/users/create',
        name: 'admin-create-user',
        builder: (context, state) => const AdminCreateUserScreen(),
      ),
      GoRoute(
        path: '/admin/users/:id/edit',
        name: 'admin-edit-user',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AdminEditUserScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/admin/subscriptions/:id',
        name: 'admin-subscription-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AdminSubscriptionDetailScreen(subscriptionId: id);
        },
      ),
      GoRoute(
        path: '/admin/past-due',
        name: 'admin-past-due',
        builder: (context, state) => const AdminPastDueScreen(),
      ),
      GoRoute(
        path: '/admin/upcoming',
        name: 'admin-upcoming-payments',
        builder: (context, state) => const AdminUpcomingPaymentsScreen(),
      ),
      GoRoute(
        path: '/admin/tiers',
        name: 'admin-tiers',
        builder: (context, state) => const AdminTiersScreen(),
      ),
      GoRoute(
        path: '/admin/coupons',
        name: 'admin-coupons',
        builder: (context, state) => const AdminCouponsScreen(),
      ),
      GoRoute(
        path: '/admin/coupons/:id',
        name: 'admin-coupon-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AdminCouponDetailScreen(couponId: id);
        },
      ),

      // Admin ambassador routes
      GoRoute(
        path: '/admin/ambassadors',
        name: 'admin-ambassadors',
        builder: (context, state) => const AdminAmbassadorsScreen(),
      ),
      GoRoute(
        path: '/admin/ambassadors/create',
        name: 'admin-create-ambassador',
        builder: (context, state) => const AdminCreateAmbassadorScreen(),
      ),
      GoRoute(
        path: '/admin/ambassadors/:id',
        name: 'admin-ambassador-detail',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AdminAmbassadorDetailScreen(ambassadorId: id);
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
      GoRoute(
        path: '/weight-trends',
        name: 'weight-trends',
        builder: (context, state) => const WeightTrendsScreen(),
      ),
      GoRoute(
        path: '/workout-calendar',
        name: 'workout-calendar',
        builder: (context, state) => const WorkoutCalendarScreen(),
      ),
      GoRoute(
        path: '/active-workout',
        name: 'active-workout',
        builder: (context, state) {
          final workout = state.extra as ProgramWorkoutDay;
          return ActiveWorkoutScreen(workout: workout);
        },
      ),
      GoRoute(
        path: '/my-programs',
        name: 'my-programs',
        builder: (context, state) => const MyProgramsScreen(),
      ),
      GoRoute(
        path: '/trainer/trainees/:id/calendar',
        name: 'trainee-calendar',
        builder: (context, state) {
          final traineeId = int.parse(state.pathParameters['id']!);
          final traineeName = state.uri.queryParameters['name'];
          final programIdStr = state.uri.queryParameters['program_id'];
          final programId = programIdStr != null ? int.tryParse(programIdStr) : null;
          return WorkoutCalendarScreen(
            traineeId: traineeId,
            traineeName: traineeName,
            programId: programId,
          );
        },
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
        path: '/edit-name',
        name: 'edit-name',
        builder: (context, state) => const EditNameScreen(),
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
      GoRoute(
        path: '/theme-settings',
        name: 'theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin-notifications',
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/security',
        name: 'admin-security',
        builder: (context, state) => const AdminSecurityScreen(),
      ),

      // Trainee subscription routes
      GoRoute(
        path: '/my-subscription',
        name: 'my-subscription',
        builder: (context, state) => const MySubscriptionScreen(),
      ),
      GoRoute(
        path: '/trainer/:id/pricing',
        name: 'trainer-pricing-view',
        builder: (context, state) {
          final trainerId = int.parse(state.pathParameters['id']!);
          final trainerName = state.uri.queryParameters['name'];
          return TrainerPricingViewScreen(
            trainerId: trainerId,
            trainerName: trainerName,
          );
        },
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
      final isSplash = state.matchedLocation == '/splash';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isResetPassword = state.matchedLocation.startsWith('/reset-password');

      // Don't redirect from splash - it handles its own navigation
      if (isSplash) return null;

      // If not logged in, redirect to login (except for register and password reset)
      if (!isLoggedIn) {
        if (isRegistering || isForgotPassword || isResetPassword) return null;
        if (!isLoggingIn) return '/login';
        return null;
      }

      // If logged in and on auth pages, redirect based on role and onboarding status
      if (isLoggingIn || isRegistering) {
        final user = authState.user!;

        // Admin goes to admin dashboard
        if (user.isAdmin) {
          return '/admin';
        }

        // Ambassadors go to ambassador dashboard
        if (user.isAmbassador) {
          return '/ambassador';
        }

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
