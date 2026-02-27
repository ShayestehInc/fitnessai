import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// App title
  ///
  /// In en, this message translates to:
  /// **'FitnessAI'**
  String get appTitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authLoginButton;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join FitnessAI today'**
  String get authRegisterSubtitle;

  /// No description provided for @authFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get authFirstNameLabel;

  /// No description provided for @authLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get authLastNameLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get authConfirmPasswordHint;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authRegisterButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link'**
  String get authForgotSubtitle;

  /// No description provided for @authSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get authSendResetLink;

  /// No description provided for @authResetSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to your email'**
  String get authResetSent;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get authBackToLogin;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get authGoogle;

  /// No description provided for @authApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get authApple;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get authLoginFailed;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get authRegisterFailed;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @onboardingAboutYou.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get onboardingAboutYou;

  /// No description provided for @onboardingActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get onboardingActivityLevel;

  /// No description provided for @onboardingGoals.
  ///
  /// In en, this message translates to:
  /// **'Your Goals'**
  String get onboardingGoals;

  /// No description provided for @onboardingDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet Preferences'**
  String get onboardingDiet;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get onboardingFinish;

  /// No description provided for @onboardingSexLabel.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get onboardingSexLabel;

  /// No description provided for @onboardingSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingSexMale;

  /// No description provided for @onboardingSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingSexFemale;

  /// No description provided for @onboardingAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get onboardingAgeLabel;

  /// No description provided for @onboardingHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get onboardingHeightLabel;

  /// No description provided for @onboardingWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get onboardingWeightLabel;

  /// No description provided for @onboardingSedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get onboardingSedentary;

  /// No description provided for @onboardingSedentaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Little or no exercise'**
  String get onboardingSedentaryDesc;

  /// No description provided for @onboardingLightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly Active'**
  String get onboardingLightlyActive;

  /// No description provided for @onboardingLightlyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Light exercise 1-3 days/week'**
  String get onboardingLightlyActiveDesc;

  /// No description provided for @onboardingModeratelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately Active'**
  String get onboardingModeratelyActive;

  /// No description provided for @onboardingModeratelyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Moderate exercise 3-5 days/week'**
  String get onboardingModeratelyActiveDesc;

  /// No description provided for @onboardingVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get onboardingVeryActive;

  /// No description provided for @onboardingVeryActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Hard exercise 6-7 days/week'**
  String get onboardingVeryActiveDesc;

  /// No description provided for @onboardingExtremelyActive.
  ///
  /// In en, this message translates to:
  /// **'Extremely Active'**
  String get onboardingExtremelyActive;

  /// No description provided for @onboardingExtremelyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Very hard exercise & physical job'**
  String get onboardingExtremelyActiveDesc;

  /// No description provided for @onboardingBuildMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build Muscle'**
  String get onboardingBuildMuscle;

  /// No description provided for @onboardingBuildMuscleDesc.
  ///
  /// In en, this message translates to:
  /// **'Gain lean muscle mass'**
  String get onboardingBuildMuscleDesc;

  /// No description provided for @onboardingFatLoss.
  ///
  /// In en, this message translates to:
  /// **'Fat Loss'**
  String get onboardingFatLoss;

  /// No description provided for @onboardingFatLossDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduce body fat percentage'**
  String get onboardingFatLossDesc;

  /// No description provided for @onboardingRecomp.
  ///
  /// In en, this message translates to:
  /// **'Body Recomp'**
  String get onboardingRecomp;

  /// No description provided for @onboardingRecompDesc.
  ///
  /// In en, this message translates to:
  /// **'Build muscle while losing fat'**
  String get onboardingRecompDesc;

  /// No description provided for @onboardingLowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low Carb'**
  String get onboardingLowCarb;

  /// No description provided for @onboardingBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get onboardingBalanced;

  /// No description provided for @onboardingHighCarb.
  ///
  /// In en, this message translates to:
  /// **'High Carb'**
  String get onboardingHighCarb;

  /// No description provided for @onboardingMealsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Meals Per Day'**
  String get onboardingMealsPerDay;

  /// No description provided for @onboardingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get homeGoodMorning;

  /// No description provided for @homeGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get homeGoodAfternoon;

  /// No description provided for @homeGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get homeGoodEvening;

  /// No description provided for @homeTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get homeTodaysPlan;

  /// No description provided for @homeQuickLog.
  ///
  /// In en, this message translates to:
  /// **'Quick Log'**
  String get homeQuickLog;

  /// No description provided for @homeRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get homeRecentActivity;

  /// No description provided for @homeNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet. Start logging!'**
  String get homeNoActivity;

  /// No description provided for @homeStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String homeStreak(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get navDiet;

  /// No description provided for @navLogbook.
  ///
  /// In en, this message translates to:
  /// **'Logbook'**
  String get navLogbook;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTrainees.
  ///
  /// In en, this message translates to:
  /// **'Trainees'**
  String get navTrainees;

  /// No description provided for @navPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get navPrograms;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsLanguageSelect;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get settingsChangePassword;

  /// No description provided for @settingsBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get settingsBiometric;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get settingsDeleteAccountWarning;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsFeatureRequests.
  ///
  /// In en, this message translates to:
  /// **'Feature Requests'**
  String get settingsFeatureRequests;

  /// No description provided for @settingsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar Integration'**
  String get settingsCalendar;

  /// No description provided for @settingsBranding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get settingsBranding;

  /// No description provided for @settingsExerciseBank.
  ///
  /// In en, this message translates to:
  /// **'Exercise Bank'**
  String get settingsExerciseBank;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get commonFilter;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonErrorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonErrorTryAgain;

  /// No description provided for @commonNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get commonNoResults;

  /// No description provided for @commonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get commonEmpty;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get commonSaved;

  /// No description provided for @commonDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get commonDeleted;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get commonCopied;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get commonViewAll;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get commonRequired;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get commonLess;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String commonDaysAgo(int count);

  /// No description provided for @commonNeverActive.
  ///
  /// In en, this message translates to:
  /// **'Never active'**
  String get commonNeverActive;

  /// No description provided for @commonNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get commonNoData;

  /// No description provided for @trainerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Trainer Dashboard'**
  String get trainerDashboard;

  /// No description provided for @trainerTrainees.
  ///
  /// In en, this message translates to:
  /// **'Trainees'**
  String get trainerTrainees;

  /// No description provided for @trainerInviteTrainee.
  ///
  /// In en, this message translates to:
  /// **'Invite Trainee'**
  String get trainerInviteTrainee;

  /// No description provided for @trainerNoTrainees.
  ///
  /// In en, this message translates to:
  /// **'No Trainees Yet'**
  String get trainerNoTrainees;

  /// No description provided for @trainerNoTraineesDesc.
  ///
  /// In en, this message translates to:
  /// **'Invite your first trainee to get started'**
  String get trainerNoTraineesDesc;

  /// No description provided for @trainerAtRiskTrainees.
  ///
  /// In en, this message translates to:
  /// **'At-Risk Trainees'**
  String get trainerAtRiskTrainees;

  /// No description provided for @trainerRetentionAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Retention Analytics'**
  String get trainerRetentionAnalytics;

  /// No description provided for @trainerAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get trainerAnnouncements;

  /// No description provided for @trainerManageAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Manage Announcements'**
  String get trainerManageAnnouncements;

  /// No description provided for @trainerBroadcastDesc.
  ///
  /// In en, this message translates to:
  /// **'Broadcast updates to all your trainees'**
  String get trainerBroadcastDesc;

  /// No description provided for @trainerAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get trainerAiAssistant;

  /// No description provided for @trainerPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get trainerPrograms;

  /// No description provided for @trainerExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get trainerExercises;

  /// No description provided for @nutritionCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutritionCalories;

  /// No description provided for @nutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionCarbs;

  /// No description provided for @nutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// No description provided for @nutritionMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get nutritionMacros;

  /// No description provided for @nutritionGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get nutritionGoal;

  /// No description provided for @nutritionRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get nutritionRemaining;

  /// No description provided for @nutritionConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get nutritionConsumed;

  /// No description provided for @nutritionLogFood.
  ///
  /// In en, this message translates to:
  /// **'Log Food'**
  String get nutritionLogFood;

  /// No description provided for @nutritionWeightCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Weight Check-In'**
  String get nutritionWeightCheckIn;

  /// No description provided for @workoutStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get workoutStartWorkout;

  /// No description provided for @workoutCompleteWorkout.
  ///
  /// In en, this message translates to:
  /// **'Complete Workout'**
  String get workoutCompleteWorkout;

  /// No description provided for @workoutSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get workoutSets;

  /// No description provided for @workoutReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutReps;

  /// No description provided for @workoutWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get workoutWeight;

  /// No description provided for @workoutRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get workoutRestTimer;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get workoutHistory;

  /// No description provided for @workoutNoProgram.
  ///
  /// In en, this message translates to:
  /// **'No program assigned'**
  String get workoutNoProgram;

  /// No description provided for @workoutNoProgramDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask your trainer to assign a program'**
  String get workoutNoProgramDesc;

  /// No description provided for @errorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetworkError;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get errorPermissionDenied;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get errorNotFound;

  /// No description provided for @errorServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServerError;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese (Brazil)'**
  String get languagePortuguese;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
