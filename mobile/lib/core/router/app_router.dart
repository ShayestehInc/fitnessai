import 'package:flutter/foundation.dart';
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
import '../../features/workout_log/presentation/screens/workout_history_screen.dart';
import '../../features/workout_log/presentation/screens/workout_detail_screen.dart';
import '../../features/workout_log/data/models/workout_history_model.dart';
import '../../features/workout_log/presentation/providers/workout_provider.dart';
import '../../features/community/presentation/screens/announcements_screen.dart';
import '../../features/community/presentation/screens/achievements_screen.dart';
import '../../features/community/presentation/screens/school_home_screen.dart';
import '../../features/community/presentation/screens/space_list_screen.dart';
import '../../features/community/presentation/screens/space_detail_screen.dart';
import '../../features/community/presentation/screens/space_create_screen.dart';
import '../../features/community/presentation/screens/saved_items_screen.dart';
import '../../features/community/presentation/screens/event_list_screen.dart';
import '../../features/community/presentation/screens/event_detail_screen.dart';
import '../../features/community/presentation/screens/trainer_event_list_screen.dart';
import '../../features/community/presentation/screens/trainer_event_form_screen.dart';
import '../../features/community/data/models/announcement_model.dart';
import '../../features/trainer/presentation/screens/trainer_announcements_screen.dart';
import '../../features/trainer/presentation/screens/create_announcement_screen.dart';
import '../../features/tv/presentation/screens/tv_mode_screen.dart';
import '../../features/logging/presentation/screens/ai_command_center_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/edit_name_screen.dart';
import '../../features/settings/presentation/screens/edit_goals_screen.dart';
import '../../features/settings/presentation/screens/edit_diet_screen.dart';
import '../../features/settings/presentation/screens/theme_settings_screen.dart';
import '../../features/settings/presentation/screens/branding_screen.dart';
import '../../features/settings/presentation/screens/language_settings_screen.dart';
import '../../features/settings/presentation/screens/admin_notifications_screen.dart';
import '../../features/settings/presentation/screens/admin_security_screen.dart';
import '../../features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import '../../features/trainer/presentation/screens/trainee_list_screen.dart';
import '../../features/trainer/presentation/screens/trainee_detail_screen.dart';
import '../../features/trainer/presentation/screens/invite_trainee_screen.dart';
import '../../features/trainer/presentation/screens/assign_program_screen.dart';
import '../../features/dual_capture/presentation/screens/dual_capture_screen.dart';
import '../../features/nutrition/presentation/screens/meal_plan_builder_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_template_picker_screen.dart';
import '../../features/nutrition/presentation/screens/photo_food_log_screen.dart';
import '../../features/nutrition/presentation/screens/template_assignment_screen.dart';
import '../../features/nutrition/presentation/screens/weekly_checkin_screen.dart';
import '../../features/nutrition/presentation/screens/day_plan_screen.dart';
import '../../features/nutrition/presentation/screens/week_plan_screen.dart';
import '../../features/trainer/presentation/screens/trainer_notifications_screen.dart';
import '../../features/trainer/presentation/screens/retention_analytics_screen.dart';
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
import '../../features/calendar/presentation/screens/calendar_events_screen.dart';
import '../../features/calendar/presentation/screens/trainer_availability_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import '../../shared/widgets/trainer_navigation_shell.dart';
import '../../shared/widgets/admin_navigation_shell.dart';
import '../../features/ambassador/presentation/screens/ambassador_navigation_shell.dart';
// New features
import '../../features/quick_log/presentation/screens/quick_log_screen.dart';
import '../../features/workout_log/presentation/screens/rest_day_screen.dart';
import '../../features/progress_photos/presentation/screens/photo_gallery_screen.dart';
import '../../features/progress_photos/presentation/screens/add_photo_screen.dart';
import '../../features/progress_photos/presentation/screens/comparison_screen.dart';
import '../../features/barcode_scanner/presentation/screens/barcode_scan_screen.dart';
import '../../features/habits/presentation/screens/habit_checklist_screen.dart';
import '../../features/habits/presentation/screens/habit_manager_screen.dart';
import '../../features/progression/presentation/screens/progression_screen.dart';
import '../../features/progression/presentation/screens/deload_screen.dart';
// v6.5 feature imports
import '../../features/session_runner/presentation/screens/session_runner_screen.dart';
import '../../features/session_runner/presentation/screens/session_summary_screen.dart';
import '../../features/session_runner/data/models/session_models.dart';
import '../../features/lift_tracking/presentation/screens/lift_history_screen.dart';
import '../../features/lift_tracking/presentation/screens/lift_max_screen.dart';
import '../../features/lift_tracking/presentation/screens/workload_screen.dart';
import '../../features/session_feedback/presentation/screens/session_feedback_screen.dart';
import '../../features/session_feedback/presentation/screens/pain_log_screen.dart';
import '../../features/session_feedback/presentation/screens/feedback_history_screen.dart';
import '../../features/training_plans/presentation/screens/my_plans_screen.dart';
import '../../features/training_plans/presentation/screens/plan_detail_screen.dart';
import '../../features/training_plans/presentation/screens/plan_session_screen.dart';
import '../../features/training_plans/presentation/screens/builder_mode_screen.dart';
import '../../features/training_plans/presentation/screens/quick_build_screen.dart';
import '../../features/training_plans/presentation/screens/advanced_builder_screen.dart';
import '../../features/decision_log/presentation/screens/decision_log_screen.dart';
import '../../features/trainer_analytics/presentation/screens/correlation_screen.dart';
import '../../features/trainer_analytics/presentation/screens/trainee_patterns_screen.dart';
import '../../features/trainer_analytics/presentation/screens/audit_trail_screen.dart';
import '../../features/voice_memos/presentation/screens/voice_memo_list_screen.dart';
import '../../features/voice_memos/presentation/screens/voice_memo_detail_screen.dart';
import '../../features/video_analysis/presentation/screens/video_analysis_list_screen.dart';
import '../../features/video_analysis/presentation/screens/video_analysis_detail_screen.dart';
import '../../features/program_import/presentation/screens/program_import_screen.dart';
import '../../features/program_import/presentation/screens/import_review_screen.dart';
import '../../features/auto_tagging/presentation/screens/auto_tag_screen.dart';
import '../../features/auto_tagging/presentation/screens/tag_history_screen.dart';
import '../../features/sharing/presentation/screens/share_preview_screen.dart';
import '../../features/anatomy/presentation/screens/anatomy_explorer_screen.dart';
import '../../features/anatomy/presentation/screens/muscle_detail_screen.dart';
import '../../features/checkins/data/models/checkin_models.dart';
import '../../features/checkins/presentation/screens/checkin_form_screen.dart';
import '../../features/checkins/presentation/screens/checkin_builder_screen.dart';
import '../../features/checkins/presentation/screens/checkin_responses_screen.dart';
import '../../features/watch/presentation/screens/watch_sync_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_dashboard_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_referrals_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_settings_screen.dart';
import '../../features/ambassador/presentation/screens/ambassador_payouts_screen.dart';
import '../../features/admin/presentation/screens/admin_ambassadors_screen.dart';
import '../../features/admin/presentation/screens/admin_create_ambassador_screen.dart';
import '../../features/admin/presentation/screens/admin_ambassador_detail_screen.dart';
import '../../features/community/presentation/screens/leaderboard_screen.dart';
import '../../features/messaging/presentation/screens/conversation_list_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/messaging/presentation/screens/new_conversation_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/settings/presentation/screens/reminders_screen.dart';
import '../../features/settings/presentation/screens/help_support_screen.dart';
import 'adaptive_page.dart';

// Navigation keys for branches
/// Root navigator key — also used by [AchievementToastService] to find the
/// topmost Overlay for showing celebration toasts from any screen.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _trainerShellNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellNavigatorKey = GlobalKey<NavigatorState>();

/// Converts [authStateProvider] changes into a [Listenable] so that
/// [GoRouter.refreshListenable] can trigger redirect re-evaluation without
/// recreating the entire router (which would reset navigation state).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: true,
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),

      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),

      // Password reset routes
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password/:uid/:token',
        name: 'reset-password',
        pageBuilder: (context, state) {
          final uid = state.pathParameters['uid']!;
          final token = state.pathParameters['token']!;
          return adaptivePage(
            key: state.pageKey,
            child: ResetPasswordScreen(uid: uid, token: token),
          );
        },
      ),

      // Onboarding route (outside shell)
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const OnboardingWizardScreen(),
        ),
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

          // Messages branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainer/messages',
                name: 'trainer-messages',
                builder: (context, state) => const ConversationListScreen(),
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

      // Exercises (outside shell, accessible from settings/programs)
      GoRoute(
        path: '/trainer/exercises',
        name: 'trainer-exercises',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const ExerciseBankScreen(),
        ),
      ),

      // Messaging routes (outside shell, used by both trainers and trainees)
      GoRoute(
        path: '/messages',
        name: 'messages',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const ConversationListScreen(),
        ),
      ),
      GoRoute(
        path: '/messages/new-conversation',
        name: 'new-conversation',
        pageBuilder: (context, state) {
          final traineeId = int.parse(
            state.uri.queryParameters['trainee_id'] ?? '0',
          );
          final name = state.uri.queryParameters['name'];
          return adaptivePage(
            key: state.pageKey,
            child: NewConversationScreen(
              traineeId: traineeId,
              traineeName: name,
            ),
          );
        },
      ),
      GoRoute(
        path: '/messages/:id',
        name: 'chat',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.uri.queryParameters['name'];
          return adaptivePage(
            key: state.pageKey,
            child: ChatScreen(
              conversationId: id,
              otherPartyName: name,
            ),
          );
        },
      ),

      // Trainer detail routes (outside shell)
      GoRoute(
        path: '/trainer/trainees/:id',
        name: 'trainee-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: TraineeDetailScreen(traineeId: id),
          );
        },
      ),
      GoRoute(
        path: '/trainer/notifications',
        name: 'trainer-notifications',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerNotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/invite',
        name: 'trainer-invite',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const InviteTraineeScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/programs/assign/:id',
        name: 'assign-program',
        pageBuilder: (context, state) {
          final traineeId = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: AssignProgramScreen(traineeId: traineeId),
          );
        },
      ),

      // Nutrition template assignment (trainer)
      GoRoute(
        path: '/nutrition/template-assignment/:traineeId',
        name: 'template-assignment',
        pageBuilder: (context, state) {
          final traineeId =
              int.parse(state.pathParameters['traineeId']!);
          return adaptivePage(
            key: state.pageKey,
            child: TemplateAssignmentScreen(traineeId: traineeId),
          );
        },
      ),

      // Nutrition day plan (trainee)
      GoRoute(
        path: '/nutrition/day-plan',
        name: 'day-plan',
        pageBuilder: (context, state) {
          final dateParam = state.uri.queryParameters['date'];
          return adaptivePage(
            key: state.pageKey,
            child: DayPlanScreen(initialDate: dateParam),
          );
        },
      ),

      // Nutrition week plan (trainee)
      GoRoute(
        path: '/nutrition/week-plan',
        name: 'week-plan',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WeekPlanScreen(),
        ),
      ),

      // Nutrition template picker (v6.5 Nutrition Spec §14)
      GoRoute(
        path: '/nutrition/template-picker',
        name: 'nutrition-template-picker',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const NutritionTemplatePickerScreen(),
        ),
      ),

      // Weekly nutrition check-in (v6.5 Nutrition Spec §13)
      GoRoute(
        path: '/nutrition/weekly-checkin',
        name: 'weekly-checkin',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WeeklyCheckinScreen(),
        ),
      ),

      // Photo food log
      GoRoute(
        path: '/nutrition/photo-log',
        name: 'photo-food-log',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const PhotoFoodLogScreen(),
        ),
      ),

      // Meal plan builder
      GoRoute(
        path: '/nutrition/meal-planner',
        name: 'meal-planner',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const MealPlanBuilderScreen(),
        ),
      ),

      // Dual Capture — Loom-style recording (v6.5 §22)
      GoRoute(
        path: '/dual-capture',
        name: 'dual-capture',
        pageBuilder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return adaptivePage(
            key: state.pageKey,
            child: DualCaptureScreen(
              traineeId: queryParams['traineeId'],
              referencedObjectType: queryParams['refType'],
              referencedObjectId: queryParams['refId'],
            ),
          );
        },
      ),

      // Trainer payment routes
      GoRoute(
        path: '/trainer/stripe-connect',
        name: 'stripe-connect',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const StripeConnectScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/pricing',
        name: 'trainer-pricing',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerPricingScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/payments',
        name: 'trainer-payments',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerPaymentsScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/coupons',
        name: 'trainer-coupons',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerCouponsScreen(),
        ),
      ),

      // Trainer subscription (for platform subscription management)
      GoRoute(
        path: '/trainer/subscription',
        name: 'trainer-subscription',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const MySubscriptionScreen(),
        ),
      ),

      // AI Chat for trainers
      GoRoute(
        path: '/trainer/ai-chat',
        name: 'trainer-ai-chat',
        pageBuilder: (context, state) {
          final traineeId = state.uri.queryParameters['trainee_id'];
          final traineeName = state.uri.queryParameters['trainee_name'];
          return adaptivePage(
            key: state.pageKey,
            child: AIChatScreen(
              initialTraineeId: traineeId != null ? int.tryParse(traineeId) : null,
              initialTraineeName: traineeName,
            ),
          );
        },
      ),

      // Retention analytics
      GoRoute(
        path: '/trainer/retention',
        name: 'trainer-retention',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const RetentionAnalyticsScreen(),
        ),
      ),

      // Calendar integration for trainers
      GoRoute(
        path: '/trainer/calendar',
        name: 'trainer-calendar',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const CalendarConnectionScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/calendar/events',
        name: 'trainer-calendar-events',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const CalendarEventsScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/calendar/availability',
        name: 'trainer-calendar-availability',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerAvailabilityScreen(),
        ),
      ),

      // Branding settings for trainers
      GoRoute(
        path: '/trainer/branding',
        name: 'trainer-branding',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const BrandingScreen(),
        ),
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

      // Ambassador detail routes (outside shell)
      GoRoute(
        path: '/ambassador/payouts',
        name: 'ambassador-payouts',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AmbassadorPayoutsScreen(),
        ),
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
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminUsersScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users/create',
        name: 'admin-create-user',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminCreateUserScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users/:id/edit',
        name: 'admin-edit-user',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: AdminEditUserScreen(userId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin/subscriptions/:id',
        name: 'admin-subscription-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: AdminSubscriptionDetailScreen(subscriptionId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin/past-due',
        name: 'admin-past-due',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminPastDueScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/upcoming',
        name: 'admin-upcoming-payments',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminUpcomingPaymentsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/tiers',
        name: 'admin-tiers',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminTiersScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/coupons',
        name: 'admin-coupons',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminCouponsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/coupons/:id',
        name: 'admin-coupon-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: AdminCouponDetailScreen(couponId: id),
          );
        },
      ),

      // Admin ambassador routes
      GoRoute(
        path: '/admin/ambassadors',
        name: 'admin-ambassadors',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminAmbassadorsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/ambassadors/create',
        name: 'admin-create-ambassador',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminCreateAmbassadorScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/ambassadors/:id',
        name: 'admin-ambassador-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: AdminAmbassadorDetailScreen(ambassadorId: id),
          );
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

          // Community branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                name: 'community',
                builder: (context, state) => const SchoolHomeScreen(),
              ),
            ],
          ),

          // Messages branch (trainee)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trainee-messages',
                name: 'trainee-messages',
                builder: (context, state) => const ConversationListScreen(),
              ),
            ],
          ),
        ],
      ),

      // Community screens (outside shell)
      GoRoute(
        path: '/community/announcements',
        name: 'community-announcements',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AnnouncementsScreen(),
        ),
      ),
      GoRoute(
        path: '/community/achievements',
        name: 'community-achievements',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AchievementsScreen(),
        ),
      ),
      GoRoute(
        path: '/community/leaderboard',
        name: 'community-leaderboard',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const LeaderboardScreen(),
        ),
      ),
      GoRoute(
        path: '/community/spaces',
        name: 'community-spaces',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const SpaceListScreen(),
        ),
      ),
      GoRoute(
        path: '/community/spaces/create',
        name: 'community-space-create',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const SpaceCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/community/spaces/:spaceId',
        name: 'community-space-detail',
        pageBuilder: (context, state) {
          final spaceId = int.parse(state.pathParameters['spaceId']!);
          return adaptivePage(
            key: state.pageKey,
            child: SpaceDetailScreen(spaceId: spaceId),
          );
        },
      ),
      GoRoute(
        path: '/community/saved',
        name: 'community-saved',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const SavedItemsScreen(),
        ),
      ),

      // Community events
      GoRoute(
        path: '/community/events',
        name: 'community-events',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const EventListScreen(),
        ),
      ),
      GoRoute(
        path: '/community/events/:id',
        name: 'community-event-detail',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: EventDetailScreen(
            eventId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),

      // Trainer event management
      GoRoute(
        path: '/trainer/events',
        name: 'trainer-events',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerEventListScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/events/create',
        name: 'trainer-event-create',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerEventFormScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/events/:id/edit',
        name: 'trainer-event-edit',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: TrainerEventFormScreen(
            eventId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),

      // Trainer announcement management
      GoRoute(
        path: '/trainer/announcements',
        name: 'trainer-announcements-screen',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const TrainerAnnouncementsScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/announcements/create',
        name: 'trainer-create-announcement',
        pageBuilder: (context, state) {
          final existing = state.extra as AnnouncementModel?;
          return adaptivePage(
            key: state.pageKey,
            child: CreateAnnouncementScreen(existing: existing),
          );
        },
      ),

      // Feature requests (accessible by both trainers and trainees)
      GoRoute(
        path: '/feature-requests',
        name: 'feature-requests',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const FeatureRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/feature-requests/submit',
        name: 'submit-feature',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const SubmitFeatureScreen(),
        ),
      ),
      GoRoute(
        path: '/feature-requests/:id',
        name: 'feature-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: FeatureDetailScreen(featureId: id),
          );
        },
      ),

      // Routes outside the navigation shell (modals, full-screen)
      GoRoute(
        path: '/ai-command',
        name: 'ai-command',
        pageBuilder: (context, state) => adaptiveFullscreenPage(
          key: state.pageKey,
          child: const AICommandCenterScreen(),
        ),
      ),
      GoRoute(
        path: '/add-food',
        name: 'add-food',
        pageBuilder: (context, state) {
          final mealParam = state.uri.queryParameters['meal'];
          final mealNumber = mealParam != null ? int.tryParse(mealParam) : null;
          return adaptiveFullscreenPage(
            key: state.pageKey,
            child: AddFoodScreen(mealNumber: mealNumber),
          );
        },
      ),
      GoRoute(
        path: '/weight-checkin',
        name: 'weight-checkin',
        pageBuilder: (context, state) => adaptiveFullscreenPage(
          key: state.pageKey,
          child: const WeightCheckInScreen(),
        ),
      ),
      GoRoute(
        path: '/weight-trends',
        name: 'weight-trends',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WeightTrendsScreen(),
        ),
      ),
      GoRoute(
        path: '/workout-calendar',
        name: 'workout-calendar',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WorkoutCalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/active-workout',
        name: 'active-workout',
        pageBuilder: (context, state) {
          final workout = state.extra as ProgramWorkoutDay;
          return adaptiveFullscreenPage(
            key: state.pageKey,
            child: ActiveWorkoutScreen(workout: workout),
          );
        },
      ),
      GoRoute(
        path: '/my-programs',
        name: 'my-programs',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const MyProgramsScreen(),
        ),
      ),
      GoRoute(
        path: '/workout-history',
        name: 'workout-history',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WorkoutHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/workout-detail',
        name: 'workout-detail',
        redirect: (context, state) {
          if (state.extra is! WorkoutHistorySummary) {
            return '/workout-history';
          }
          return null;
        },
        pageBuilder: (context, state) {
          final workout = state.extra! as WorkoutHistorySummary;
          return adaptivePage(
            key: state.pageKey,
            child: WorkoutDetailScreen(workout: workout),
          );
        },
      ),
      GoRoute(
        path: '/trainer/trainees/:id/calendar',
        name: 'trainee-calendar',
        pageBuilder: (context, state) {
          final traineeId = int.parse(state.pathParameters['id']!);
          final traineeName = state.uri.queryParameters['name'];
          final programIdStr = state.uri.queryParameters['program_id'];
          final programId = programIdStr != null ? int.tryParse(programIdStr) : null;
          return adaptivePage(
            key: state.pageKey,
            child: WorkoutCalendarScreen(
              traineeId: traineeId,
              traineeName: traineeName,
              programId: programId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/trainer/trainees/:id/habits',
        name: 'trainee-habits',
        pageBuilder: (context, state) {
          final traineeId = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: HabitManagerScreen(traineeId: traineeId),
          );
        },
      ),

      // TV Mode — gym display
      GoRoute(
        path: '/tv-mode',
        name: 'tv-mode',
        pageBuilder: (context, state) => adaptiveFullscreenPage(
          key: state.pageKey,
          child: const TvModeScreen(),
        ),
      ),
      // --- New Feature Routes ---
      GoRoute(
        path: '/quick-log',
        name: 'quick-log',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const QuickLogScreen(),
        ),
      ),
      GoRoute(
        path: '/rest-day',
        name: 'rest-day',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const RestDayScreen(),
        ),
      ),
      GoRoute(
        path: '/progress-photos',
        name: 'progress-photos',
        pageBuilder: (context, state) {
          final traineeIdStr = state.uri.queryParameters['trainee_id'];
          final traineeId = traineeIdStr != null
              ? int.tryParse(traineeIdStr)
              : null;
          final traineeName = state.uri.queryParameters['trainee_name'];
          return adaptivePage(
            key: state.pageKey,
            child: PhotoGalleryScreen(
              traineeId: traineeId,
              traineeName: traineeName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/progress-photos/add',
        name: 'add-progress-photo',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AddPhotoScreen(),
        ),
      ),
      GoRoute(
        path: '/progress-photos/compare',
        name: 'compare-photos',
        pageBuilder: (context, state) {
          final traineeIdStr = state.uri.queryParameters['trainee_id'];
          final traineeId = traineeIdStr != null
              ? int.tryParse(traineeIdStr)
              : null;
          return adaptivePage(
            key: state.pageKey,
            child: ComparisonScreen(traineeId: traineeId),
          );
        },
      ),
      GoRoute(
        path: '/barcode-scan',
        name: 'barcode-scan',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const BarcodeScanScreen(),
        ),
      ),
      GoRoute(
        path: '/habits',
        name: 'habits',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const HabitChecklistScreen(),
        ),
      ),
      GoRoute(
        path: '/progression/:programId',
        name: 'progression',
        pageBuilder: (context, state) {
          final programId = int.parse(state.pathParameters['programId']!);
          return adaptivePage(
            key: state.pageKey,
            child: ProgressionScreen(programId: programId),
          );
        },
      ),
      GoRoute(
        path: '/deload/:programId',
        name: 'deload',
        pageBuilder: (context, state) {
          final programId = int.parse(state.pathParameters['programId']!);
          return adaptivePage(
            key: state.pageKey,
            child: DeloadScreen(programId: programId),
          );
        },
      ),
      GoRoute(
        path: '/share-workout/:logId',
        name: 'share-workout',
        pageBuilder: (context, state) {
          final logId = int.parse(state.pathParameters['logId']!);
          return adaptivePage(
            key: state.pageKey,
            child: SharePreviewScreen(logId: logId),
          );
        },
      ),
      GoRoute(
        path: '/checkin',
        name: 'checkin-form',
        pageBuilder: (context, state) {
          final assignment = state.extra! as CheckInAssignmentModel;
          return adaptivePage(
            key: state.pageKey,
            child: CheckInFormScreen(assignment: assignment),
          );
        },
      ),
      GoRoute(
        path: '/trainer/checkin-builder',
        name: 'checkin-builder',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const CheckInBuilderScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/checkin-responses',
        name: 'checkin-responses',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const CheckInResponsesScreen(),
        ),
      ),

      // Apple Watch
      GoRoute(
        path: '/watch',
        name: 'watch-sync',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WatchSyncScreen(),
        ),
      ),

      // --- v6.5 Feature Routes ---

      // Session Runner
      GoRoute(
        path: '/session-runner',
        name: 'session-runner',
        pageBuilder: (context, state) {
          final sessionId = state.uri.queryParameters['session_id'];
          final planSessionId = state.uri.queryParameters['plan_session_id'];
          return adaptivePage(
            key: state.pageKey,
            child: SessionRunnerScreen(
              sessionId: sessionId,
              planSessionId: planSessionId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/session-summary',
        name: 'session-summary',
        pageBuilder: (context, state) {
          final summary = state.extra! as SessionSummaryModel;
          return adaptivePage(
            key: state.pageKey,
            child: SessionSummaryScreen(summary: summary),
          );
        },
      ),

      // Lift Tracking
      GoRoute(
        path: '/lift-history/:exerciseId',
        name: 'lift-history',
        pageBuilder: (context, state) {
          final exerciseId = int.parse(state.pathParameters['exerciseId']!);
          final exerciseName = state.uri.queryParameters['name'] ?? 'Exercise';
          return adaptivePage(
            key: state.pageKey,
            child: LiftHistoryScreen(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/lift-maxes',
        name: 'lift-maxes',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const LiftMaxScreen(),
        ),
      ),
      GoRoute(
        path: '/workload',
        name: 'workload',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const WorkloadScreen(),
        ),
      ),

      // Session Feedback
      GoRoute(
        path: '/session-feedback/:sessionPk',
        name: 'session-feedback',
        pageBuilder: (context, state) {
          final sessionPk = int.parse(state.pathParameters['sessionPk']!);
          return adaptivePage(
            key: state.pageKey,
            child: SessionFeedbackScreen(sessionPk: sessionPk),
          );
        },
      ),
      GoRoute(
        path: '/pain-log',
        name: 'pain-log',
        pageBuilder: (context, state) {
          final exerciseIdStr = state.uri.queryParameters['exercise_id'];
          final sessionIdStr = state.uri.queryParameters['session_id'];
          final returnResult = state.uri.queryParameters['return_result'] == 'true';
          return adaptivePage(
            key: state.pageKey,
            child: PainLogScreen(
              exerciseId: exerciseIdStr != null ? int.tryParse(exerciseIdStr) : null,
              activeSessionId: sessionIdStr != null ? int.tryParse(sessionIdStr) : null,
              returnResult: returnResult,
            ),
          );
        },
      ),
      GoRoute(
        path: '/feedback-history',
        name: 'feedback-history',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const FeedbackHistoryScreen(),
        ),
      ),

      // Training Plans
      GoRoute(
        path: '/my-plans',
        name: 'my-plans',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const MyPlansScreen(),
        ),
      ),
      GoRoute(
        path: '/build-program',
        name: 'build-program',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const BuilderModeScreen(),
        ),
      ),
      GoRoute(
        path: '/quick-build',
        name: 'quick-build',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const QuickBuildScreen(),
        ),
      ),
      GoRoute(
        path: '/advanced-builder',
        name: 'advanced-builder',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdvancedBuilderScreen(),
        ),
      ),
      GoRoute(
        path: '/plan-detail/:planId',
        name: 'plan-detail',
        pageBuilder: (context, state) {
          final planId = state.pathParameters['planId']!;
          return adaptivePage(
            key: state.pageKey,
            child: PlanDetailScreen(planId: planId),
          );
        },
      ),
      GoRoute(
        path: '/plan-session/:sessionId',
        name: 'plan-session',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return adaptivePage(
            key: state.pageKey,
            child: PlanSessionScreen(sessionId: sessionId),
          );
        },
      ),

      // Decision Log
      GoRoute(
        path: '/decision-log',
        name: 'decision-log',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const DecisionLogScreen(),
        ),
      ),

      // Anatomy
      GoRoute(
        path: '/anatomy',
        name: 'anatomy',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AnatomyExplorerScreen(),
        ),
      ),
      GoRoute(
        path: '/anatomy/muscles/:slug',
        name: 'muscle-detail',
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return adaptivePage(
            key: state.pageKey,
            child: MuscleDetailScreen(slug: slug),
          );
        },
      ),

      // Trainer Analytics (correlations, patterns, audit)
      GoRoute(
        path: '/trainer/correlations',
        name: 'trainer-correlations',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const CorrelationScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/trainee-patterns/:traineeId',
        name: 'trainer-trainee-patterns',
        pageBuilder: (context, state) {
          final traineeId = int.parse(state.pathParameters['traineeId']!);
          final traineeName = state.uri.queryParameters['name'] ?? 'Trainee';
          return adaptivePage(
            key: state.pageKey,
            child: TraineePatternsScreen(
              traineeId: traineeId,
              traineeName: traineeName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/trainer/audit-trail',
        name: 'trainer-audit-trail',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AuditTrailScreen(),
        ),
      ),

      // Voice Memos
      GoRoute(
        path: '/voice-memos',
        name: 'voice-memos',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const VoiceMemoListScreen(),
        ),
      ),
      GoRoute(
        path: '/voice-memos/:id',
        name: 'voice-memo-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: VoiceMemoDetailScreen(memoId: id),
          );
        },
      ),

      // Video Analysis
      GoRoute(
        path: '/video-analysis',
        name: 'video-analysis',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const VideoAnalysisListScreen(),
        ),
      ),
      GoRoute(
        path: '/video-analysis/:id',
        name: 'video-analysis-detail',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return adaptivePage(
            key: state.pageKey,
            child: VideoAnalysisDetailScreen(analysisId: id),
          );
        },
      ),

      // Program Import
      GoRoute(
        path: '/program-import',
        name: 'program-import',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const ProgramImportScreen(),
        ),
      ),
      GoRoute(
        path: '/program-import/:id/review',
        name: 'import-review',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return adaptivePage(
            key: state.pageKey,
            child: ImportReviewScreen(importId: id),
          );
        },
      ),

      // Auto-Tagging
      GoRoute(
        path: '/auto-tag/:exerciseId',
        name: 'auto-tag',
        pageBuilder: (context, state) {
          final exerciseId = int.parse(state.pathParameters['exerciseId']!);
          final exerciseName = state.uri.queryParameters['name'] ?? 'Exercise';
          return adaptivePage(
            key: state.pageKey,
            child: AutoTagScreen(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
            ),
          );
        },
      ),
      GoRoute(
        path: '/tag-history/:exerciseId',
        name: 'tag-history',
        pageBuilder: (context, state) {
          final exerciseId = int.parse(state.pathParameters['exerciseId']!);
          final exerciseName = state.uri.queryParameters['name'] ?? 'Exercise';
          return adaptivePage(
            key: state.pageKey,
            child: TagHistoryScreen(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
            ),
          );
        },
      ),

      // Settings routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-name',
        name: 'edit-name',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const EditNameScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-goals',
        name: 'edit-goals',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const EditGoalsScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-diet',
        name: 'edit-diet',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const EditDietScreen(),
        ),
      ),
      GoRoute(
        path: '/theme-settings',
        name: 'theme-settings',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const ThemeSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/language-settings',
        name: 'language-settings',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const LanguageSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/notification-preferences',
        name: 'notification-preferences',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const NotificationPreferencesScreen(),
        ),
      ),
      GoRoute(
        path: '/reminders',
        name: 'reminders',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const RemindersScreen(),
        ),
      ),
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const HelpSupportScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin-notifications',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminNotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/security',
        name: 'admin-security',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const AdminSecurityScreen(),
        ),
      ),

      // Trainee subscription routes
      GoRoute(
        path: '/my-subscription',
        name: 'my-subscription',
        pageBuilder: (context, state) => adaptivePage(
          key: state.pageKey,
          child: const MySubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: '/trainer/:id/pricing',
        name: 'trainer-pricing-view',
        pageBuilder: (context, state) {
          final trainerId = int.parse(state.pathParameters['id']!);
          final trainerName = state.uri.queryParameters['name'];
          return adaptivePage(
            key: state.pageKey,
            child: TrainerPricingViewScreen(
              trainerId: trainerId,
              trainerName: trainerName,
            ),
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
      // Read current auth state on every redirect evaluation (not a
      // captured snapshot) so the redirect always reflects the latest state.
      final currentAuth = ref.read(authStateProvider);
      final isLoggedIn = currentAuth.user != null;
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
        final user = currentAuth.user!;

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
      if (isLoggedIn && currentAuth.user!.isTrainee && !currentAuth.user!.onboardingCompleted) {
        if (!isOnboarding) {
          return '/onboarding';
        }
      }

      return null;
    },
  );
});
