import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitnessai/features/logging/presentation/screens/ai_command_center_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/achievements_screen.dart';
import 'package:fitnessai/features/progress_photos/presentation/screens/add_photo_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_ambassadors_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_coupons_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_create_ambassador_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_create_user_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/admin_notifications_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_past_due_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/admin_security_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_subscriptions_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_tiers_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_trainers_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_upcoming_payments_screen.dart';
import 'package:fitnessai/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:fitnessai/features/training_plans/presentation/screens/advanced_builder_screen.dart';
import 'package:fitnessai/features/ambassador/presentation/screens/ambassador_dashboard_screen.dart';
import 'package:fitnessai/features/ambassador/presentation/screens/ambassador_payouts_screen.dart';
import 'package:fitnessai/features/ambassador/presentation/screens/ambassador_referrals_screen.dart';
import 'package:fitnessai/features/ambassador/presentation/screens/ambassador_settings_screen.dart';
import 'package:fitnessai/features/video_analysis/presentation/screens/analysis_list_screen.dart';
import 'package:fitnessai/features/anatomy/presentation/screens/anatomy_explorer_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/announcements_screen.dart';
import 'package:fitnessai/features/trainer_analytics/presentation/screens/audit_trail_screen.dart';
import 'package:fitnessai/features/barcode_scanner/presentation/screens/barcode_scan_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/branding_screen.dart';
import 'package:fitnessai/features/training_plans/presentation/screens/builder_mode_screen.dart';
import 'package:fitnessai/features/calendar/presentation/screens/calendar_connection_screen.dart';
import 'package:fitnessai/features/calendar/presentation/screens/calendar_events_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/admin_security_screen.dart';
import 'package:fitnessai/features/checkins/presentation/screens/checkin_builder_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/community_feed_screen.dart';
import 'package:fitnessai/features/messaging/presentation/screens/conversation_list_screen.dart';
import 'package:fitnessai/features/trainer_analytics/presentation/screens/correlation_screen.dart';
import 'package:fitnessai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fitnessai/features/decision_log/presentation/screens/decision_log_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/delete_account_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/edit_diet_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/edit_goals_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/edit_name_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/event_list_screen.dart';
import 'package:fitnessai/features/exercises/presentation/screens/exercise_bank_screen.dart';
import 'package:fitnessai/features/feature_requests/presentation/screens/feature_requests_screen.dart';
import 'package:fitnessai/features/session_feedback/presentation/screens/feedback_history_screen.dart';
import 'package:fitnessai/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:fitnessai/features/forums/presentation/screens/forums_screen.dart';
import 'package:fitnessai/features/habits/presentation/screens/habit_checklist_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/help_support_screen.dart';
import 'package:fitnessai/features/home/presentation/screens/home_screen.dart';
import 'package:fitnessai/features/trainer/presentation/screens/invite_trainee_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/leaderboard_screen.dart';
import 'package:fitnessai/features/lift_tracking/presentation/screens/lift_max_screen.dart';
import 'package:fitnessai/features/auth/presentation/screens/login_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/meal_plan_builder_screen.dart';
import 'package:fitnessai/features/training_plans/presentation/screens/my_plans_screen.dart';
import 'package:fitnessai/features/workout_log/presentation/screens/my_programs_screen.dart';
import 'package:fitnessai/features/payments/presentation/screens/my_subscription_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/nutrition_template_picker_screen.dart';
import 'package:fitnessai/features/onboarding/presentation/screens/onboarding_wizard_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/photo_food_log_screen.dart';
import 'package:fitnessai/features/programs/presentation/screens/program_generator_screen.dart';
import 'package:fitnessai/features/program_import/presentation/screens/program_import_screen.dart';
import 'package:fitnessai/features/programs/presentation/screens/programs_screen.dart';
import 'package:fitnessai/features/progression/presentation/screens/progression_suggestions_screen.dart';
import 'package:fitnessai/features/training_plans/presentation/screens/quick_build_screen.dart';
import 'package:fitnessai/features/quick_log/presentation/screens/quick_log_screen.dart';
import 'package:fitnessai/features/auth/presentation/screens/register_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/reminders_screen.dart';
import 'package:fitnessai/features/workout_log/presentation/screens/rest_day_screen.dart';
import 'package:fitnessai/features/trainer/presentation/screens/retention_analytics_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/saved_items_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/school_home_screen.dart';
import 'package:fitnessai/features/auth/presentation/screens/server_config_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/settings_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/space_create_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/space_list_screen.dart';
import 'package:fitnessai/features/splash/presentation/screens/splash_screen.dart';
import 'package:fitnessai/features/onboarding/presentation/screens/step1_about_you_screen.dart';
import 'package:fitnessai/features/onboarding/presentation/screens/step2_activity_level_screen.dart';
import 'package:fitnessai/features/onboarding/presentation/screens/step3_goal_screen.dart';
import 'package:fitnessai/features/onboarding/presentation/screens/step4_diet_setup_screen.dart';
import 'package:fitnessai/features/payments/presentation/screens/stripe_connect_screen.dart';
import 'package:fitnessai/features/feature_requests/presentation/screens/submit_feature_screen.dart';
import 'package:fitnessai/features/settings/presentation/screens/theme_settings_screen.dart';
import 'package:fitnessai/features/trainer/presentation/screens/trainee_list_screen.dart';
import 'package:fitnessai/features/trainer/presentation/screens/trainer_announcements_screen.dart';
import 'package:fitnessai/features/calendar/presentation/screens/trainer_availability_screen.dart';
import 'package:fitnessai/features/payments/presentation/screens/trainer_coupons_screen.dart';
import 'package:fitnessai/features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import 'package:fitnessai/features/community/presentation/screens/trainer_event_list_screen.dart';
import 'package:fitnessai/features/trainer/presentation/screens/trainer_notifications_screen.dart';
import 'package:fitnessai/features/payments/presentation/screens/trainer_payments_screen.dart';
import 'package:fitnessai/features/payments/presentation/screens/trainer_pricing_screen.dart';
import 'package:fitnessai/features/tv/presentation/screens/tv_mode_screen.dart';
import 'package:fitnessai/features/video_analysis/presentation/screens/video_analysis_list_screen.dart';
import 'package:fitnessai/features/voice_memos/presentation/screens/voice_memo_list_screen.dart';
import 'package:fitnessai/features/voice_memos/presentation/screens/voice_memo_screen.dart';
import 'package:fitnessai/features/watch/presentation/screens/watch_sync_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/week_plan_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/weekly_checkin_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/weight_checkin_screen.dart';
import 'package:fitnessai/features/nutrition/presentation/screens/weight_trends_screen.dart';
import 'package:fitnessai/features/lift_tracking/presentation/screens/workload_screen.dart';
import 'package:fitnessai/features/workout_log/presentation/screens/workout_history_screen.dart';
import 'package:fitnessai/features/workout_log/presentation/screens/workout_log_screen.dart';

Widget _wrap(Widget screen) {
  return ProviderScope(child: MaterialApp(home: screen));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin', () {
    testWidgets('AdminAmbassadorsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminAmbassadorsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminAmbassadorsScreen), findsOneWidget);
    });

    testWidgets('AdminCouponsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminCouponsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminCouponsScreen), findsOneWidget);
    });

    testWidgets('AdminCreateAmbassadorScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminCreateAmbassadorScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminCreateAmbassadorScreen), findsOneWidget);
    });

    testWidgets('AdminCreateUserScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminCreateUserScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminCreateUserScreen), findsOneWidget);
    });

    testWidgets('AdminDashboardScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminDashboardScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('AdminPastDueScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminPastDueScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminPastDueScreen), findsOneWidget);
    });

    testWidgets('AdminSubscriptionsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminSubscriptionsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminSubscriptionsScreen), findsOneWidget);
    });

    testWidgets('AdminTiersScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminTiersScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminTiersScreen), findsOneWidget);
    });

    testWidgets('AdminTrainersScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminTrainersScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminTrainersScreen), findsOneWidget);
    });

    testWidgets('AdminUpcomingPaymentsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminUpcomingPaymentsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminUpcomingPaymentsScreen), findsOneWidget);
    });

    testWidgets('AdminUsersScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminUsersScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminUsersScreen), findsOneWidget);
    });

  });

  group('Ambassador', () {
    testWidgets('AmbassadorDashboardScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AmbassadorDashboardScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AmbassadorDashboardScreen), findsOneWidget);
    });

    testWidgets('AmbassadorPayoutsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AmbassadorPayoutsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AmbassadorPayoutsScreen), findsOneWidget);
    });

    testWidgets('AmbassadorReferralsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AmbassadorReferralsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AmbassadorReferralsScreen), findsOneWidget);
    });

    testWidgets('AmbassadorSettingsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AmbassadorSettingsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AmbassadorSettingsScreen), findsOneWidget);
    });

  });

  group('Anatomy', () {
    testWidgets('AnatomyExplorerScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AnatomyExplorerScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AnatomyExplorerScreen), findsOneWidget);
    });

  });

  group('Auth', () {
    testWidgets('ForgotPasswordScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('LoginScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('RegisterScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('ServerConfigScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ServerConfigScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ServerConfigScreen), findsOneWidget);
    });

  });

  group('Barcode Scanner', () {
    testWidgets('BarcodeScanScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const BarcodeScanScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(BarcodeScanScreen), findsOneWidget);
    });

  });

  group('Calendar', () {
    testWidgets('CalendarConnectionScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarConnectionScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CalendarConnectionScreen), findsOneWidget);
    });

    testWidgets('CalendarEventsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const CalendarEventsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CalendarEventsScreen), findsOneWidget);
    });

    testWidgets('TrainerAvailabilityScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerAvailabilityScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerAvailabilityScreen), findsOneWidget);
    });

  });

  group('Checkins', () {
    testWidgets('CheckInBuilderScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const CheckInBuilderScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CheckInBuilderScreen), findsOneWidget);
    });

  });

  group('Community', () {
    testWidgets('AchievementsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AchievementsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AchievementsScreen), findsOneWidget);
    });

    testWidgets('AnnouncementsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AnnouncementsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AnnouncementsScreen), findsOneWidget);
    });

    testWidgets('CommunityFeedScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const CommunityFeedScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CommunityFeedScreen), findsOneWidget);
    });

    testWidgets('EventListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const EventListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(EventListScreen), findsOneWidget);
    });

    testWidgets('LeaderboardScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const LeaderboardScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(LeaderboardScreen), findsOneWidget);
    });

    testWidgets('SavedItemsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SavedItemsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SavedItemsScreen), findsOneWidget);
    });

    testWidgets('SchoolHomeScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SchoolHomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SchoolHomeScreen), findsOneWidget);
    });

    testWidgets('SpaceCreateScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SpaceCreateScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SpaceCreateScreen), findsOneWidget);
    });

    testWidgets('SpaceListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SpaceListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SpaceListScreen), findsOneWidget);
    });

    testWidgets('TrainerEventListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerEventListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerEventListScreen), findsOneWidget);
    });

  });

  group('Dashboard', () {
    testWidgets('DashboardScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const DashboardScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

  });

  group('Decision Log', () {
    testWidgets('DecisionLogScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const DecisionLogScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(DecisionLogScreen), findsOneWidget);
    });

  });

  group('Exercises', () {
    testWidgets('ExerciseBankScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ExerciseBankScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ExerciseBankScreen), findsOneWidget);
    });

  });

  group('Feature Requests', () {
    testWidgets('FeatureRequestsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const FeatureRequestsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(FeatureRequestsScreen), findsOneWidget);
    });

    testWidgets('SubmitFeatureScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SubmitFeatureScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SubmitFeatureScreen), findsOneWidget);
    });

  });

  group('Forums', () {
    testWidgets('ForumsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ForumsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ForumsScreen), findsOneWidget);
    });

  });

  group('Habits', () {
    testWidgets('HabitChecklistScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const HabitChecklistScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(HabitChecklistScreen), findsOneWidget);
    });

  });

  group('Home', () {
    testWidgets('HomeScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

  });

  group('Lift Tracking', () {
    testWidgets('LiftMaxScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const LiftMaxScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(LiftMaxScreen), findsOneWidget);
    });

    testWidgets('WorkloadScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WorkloadScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WorkloadScreen), findsOneWidget);
    });

  });

  group('Logging', () {
    testWidgets('AICommandCenterScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AICommandCenterScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AICommandCenterScreen), findsOneWidget);
    });

  });

  group('Messaging', () {
    testWidgets('ConversationListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ConversationListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ConversationListScreen), findsOneWidget);
    });

  });

  group('Nutrition', () {
    testWidgets('MealPlanBuilderScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const MealPlanBuilderScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(MealPlanBuilderScreen), findsOneWidget);
    });

    testWidgets('NutritionScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const NutritionScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(NutritionScreen), findsOneWidget);
    });

    testWidgets('NutritionTemplatePickerScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const NutritionTemplatePickerScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(NutritionTemplatePickerScreen), findsOneWidget);
    });

    testWidgets('PhotoFoodLogScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const PhotoFoodLogScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(PhotoFoodLogScreen), findsOneWidget);
    });

    testWidgets('WeekPlanScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WeekPlanScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WeekPlanScreen), findsOneWidget);
    });

    testWidgets('WeeklyCheckinScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WeeklyCheckinScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WeeklyCheckinScreen), findsOneWidget);
    });

    testWidgets('WeightCheckInScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WeightCheckInScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WeightCheckInScreen), findsOneWidget);
    });

    testWidgets('WeightTrendsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WeightTrendsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WeightTrendsScreen), findsOneWidget);
    });

  });

  group('Onboarding', () {
    testWidgets('OnboardingWizardScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const OnboardingWizardScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(OnboardingWizardScreen), findsOneWidget);
    });

    testWidgets('Step1AboutYouScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const Step1AboutYouScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Step1AboutYouScreen), findsOneWidget);
    });

    testWidgets('Step2ActivityLevelScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const Step2ActivityLevelScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Step2ActivityLevelScreen), findsOneWidget);
    });

    testWidgets('Step3GoalScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const Step3GoalScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Step3GoalScreen), findsOneWidget);
    });

    testWidgets('Step4DietSetupScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const Step4DietSetupScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Step4DietSetupScreen), findsOneWidget);
    });

  });

  group('Payments', () {
    testWidgets('MySubscriptionScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const MySubscriptionScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(MySubscriptionScreen), findsOneWidget);
    });

    testWidgets('StripeConnectScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const StripeConnectScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(StripeConnectScreen), findsOneWidget);
    });

    testWidgets('TrainerCouponsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerCouponsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerCouponsScreen), findsOneWidget);
    });

    testWidgets('TrainerPaymentsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerPaymentsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerPaymentsScreen), findsOneWidget);
    });

    testWidgets('TrainerPricingScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerPricingScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerPricingScreen), findsOneWidget);
    });

  });

  group('Program Import', () {
    testWidgets('ProgramImportScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ProgramImportScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ProgramImportScreen), findsOneWidget);
    });

  });

  group('Programs', () {
    testWidgets('ProgramGeneratorScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ProgramGeneratorScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ProgramGeneratorScreen), findsOneWidget);
    });

    testWidgets('ProgramsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ProgramsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ProgramsScreen), findsOneWidget);
    });

  });

  group('Progress Photos', () {
    testWidgets('AddPhotoScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AddPhotoScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AddPhotoScreen), findsOneWidget);
    });

  });

  group('Progression', () {
    testWidgets('ProgressionSuggestionsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ProgressionSuggestionsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ProgressionSuggestionsScreen), findsOneWidget);
    });

  });

  group('Quick Log', () {
    testWidgets('QuickLogScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const QuickLogScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(QuickLogScreen), findsOneWidget);
    });

  });

  group('Session Feedback', () {
    testWidgets('FeedbackHistoryScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const FeedbackHistoryScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(FeedbackHistoryScreen), findsOneWidget);
    });

  });

  group('Settings', () {
    testWidgets('AdminNotificationsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminNotificationsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminNotificationsScreen), findsOneWidget);
    });

    testWidgets('AdminSecurityScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdminSecurityScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdminSecurityScreen), findsOneWidget);
    });

    testWidgets('BrandingScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const BrandingScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(BrandingScreen), findsOneWidget);
    });

    testWidgets('ChangePasswordScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ChangePasswordScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('DeleteAccountScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const DeleteAccountScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    });

    testWidgets('EditDietScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const EditDietScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(EditDietScreen), findsOneWidget);
    });

    testWidgets('EditGoalsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const EditGoalsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(EditGoalsScreen), findsOneWidget);
    });

    testWidgets('EditNameScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const EditNameScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(EditNameScreen), findsOneWidget);
    });

    testWidgets('EditProfileScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const EditProfileScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('HelpSupportScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const HelpSupportScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });

    testWidgets('LanguageSettingsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const LanguageSettingsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(LanguageSettingsScreen), findsOneWidget);
    });

    testWidgets('NotificationPreferencesScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const NotificationPreferencesScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(NotificationPreferencesScreen), findsOneWidget);
    });

    testWidgets('RemindersScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const RemindersScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(RemindersScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SettingsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('ThemeSettingsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const ThemeSettingsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ThemeSettingsScreen), findsOneWidget);
    });

  });

  group('Splash', () {
    testWidgets('SplashScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const SplashScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(SplashScreen), findsOneWidget);
    });

  });

  group('Trainer', () {
    testWidgets('InviteTraineeScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const InviteTraineeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(InviteTraineeScreen), findsOneWidget);
    });

    testWidgets('RetentionAnalyticsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const RetentionAnalyticsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(RetentionAnalyticsScreen), findsOneWidget);
    });

    testWidgets('TraineeListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TraineeListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TraineeListScreen), findsOneWidget);
    });

    testWidgets('TrainerAnnouncementsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerAnnouncementsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerAnnouncementsScreen), findsOneWidget);
    });

    testWidgets('TrainerDashboardScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerDashboardScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerDashboardScreen), findsOneWidget);
    });

    testWidgets('TrainerNotificationsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TrainerNotificationsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TrainerNotificationsScreen), findsOneWidget);
    });

  });

  group('Trainer Analytics', () {
    testWidgets('AuditTrailScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AuditTrailScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AuditTrailScreen), findsOneWidget);
    });

    testWidgets('CorrelationScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const CorrelationScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CorrelationScreen), findsOneWidget);
    });

  });

  group('Training Plans', () {
    testWidgets('AdvancedBuilderScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AdvancedBuilderScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AdvancedBuilderScreen), findsOneWidget);
    });

    testWidgets('BuilderModeScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const BuilderModeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(BuilderModeScreen), findsOneWidget);
    });

    testWidgets('MyPlansScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const MyPlansScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(MyPlansScreen), findsOneWidget);
    });

    testWidgets('QuickBuildScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const QuickBuildScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(QuickBuildScreen), findsOneWidget);
    });

  });

  group('Tv', () {
    testWidgets('TvModeScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const TvModeScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(TvModeScreen), findsOneWidget);
    });

  });

  group('Video Analysis', () {
    testWidgets('AnalysisListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const AnalysisListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(AnalysisListScreen), findsOneWidget);
    });

    testWidgets('VideoAnalysisListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const VideoAnalysisListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(VideoAnalysisListScreen), findsOneWidget);
    });

  });

  group('Voice Memos', () {
    testWidgets('VoiceMemoListScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const VoiceMemoListScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(VoiceMemoListScreen), findsOneWidget);
    });

    testWidgets('VoiceMemoScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const VoiceMemoScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(VoiceMemoScreen), findsOneWidget);
    });

  });

  group('Watch', () {
    testWidgets('WatchSyncScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WatchSyncScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WatchSyncScreen), findsOneWidget);
    });

  });

  group('Workout Log', () {
    testWidgets('MyProgramsScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const MyProgramsScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(MyProgramsScreen), findsOneWidget);
    });

    testWidgets('RestDayScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const RestDayScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(RestDayScreen), findsOneWidget);
    });

    testWidgets('WorkoutHistoryScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WorkoutHistoryScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
    });

    testWidgets('WorkoutLogScreen renders', (tester) async {
      await tester.pumpWidget(_wrap(const WorkoutLogScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(WorkoutLogScreen), findsOneWidget);
    });

  });

}