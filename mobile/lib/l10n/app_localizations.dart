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

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminActive;

  /// No description provided for @adminAddNotesAboutThisSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add notes about this subscription...'**
  String get adminAddNotesAboutThisSubscription;

  /// No description provided for @adminAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminAdmin;

  /// No description provided for @adminAdminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminAdminDashboard;

  /// No description provided for @adminAllTrainersTrainees.
  ///
  /// In en, this message translates to:
  /// **'All (Trainers & Trainees)'**
  String get adminAllTrainersTrainees;

  /// No description provided for @adminAmbassadorDetail.
  ///
  /// In en, this message translates to:
  /// **'Ambassador Detail'**
  String get adminAmbassadorDetail;

  /// No description provided for @adminAmbassadorexampleCom.
  ///
  /// In en, this message translates to:
  /// **'ambassador@example.com'**
  String get adminAmbassadorexampleCom;

  /// No description provided for @adminAmbassadors.
  ///
  /// In en, this message translates to:
  /// **'Ambassadors'**
  String get adminAmbassadors;

  /// No description provided for @adminAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminAmount;

  /// No description provided for @adminAppliesTo.
  ///
  /// In en, this message translates to:
  /// **'Applies To'**
  String get adminAppliesTo;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminApproveAll.
  ///
  /// In en, this message translates to:
  /// **'Approve All'**
  String get adminApproveAll;

  /// No description provided for @adminApproveAllPending.
  ///
  /// In en, this message translates to:
  /// **'Approve All Pending'**
  String get adminApproveAllPending;

  /// No description provided for @adminApproveCommission.
  ///
  /// In en, this message translates to:
  /// **'Approve Commission'**
  String get adminApproveCommission;

  /// No description provided for @adminAreYouSureYouWantToDeleteEmail.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \$_email?'**
  String get adminAreYouSureYouWantToDeleteEmail;

  /// No description provided for @adminBasicAnalyticsnEmailSupportn.
  ///
  /// In en, this message translates to:
  /// **'Basic analytics\\nEmail support\\n...'**
  String get adminBasicAnalyticsnEmailSupportn;

  /// No description provided for @adminBriefDescriptionOfThisTier.
  ///
  /// In en, this message translates to:
  /// **'Brief description of this tier'**
  String get adminBriefDescriptionOfThisTier;

  /// No description provided for @adminChangeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get adminChangeStatus;

  /// No description provided for @adminChangeTier.
  ///
  /// In en, this message translates to:
  /// **'Change Tier'**
  String get adminChangeTier;

  /// No description provided for @adminClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get adminClear;

  /// No description provided for @adminClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get adminClearAll;

  /// No description provided for @adminClearPastDue.
  ///
  /// In en, this message translates to:
  /// **'Clear Past Due'**
  String get adminClearPastDue;

  /// No description provided for @adminCodeCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Code copied to clipboard'**
  String get adminCodeCopiedToClipboard;

  /// No description provided for @adminCommissionApproved.
  ///
  /// In en, this message translates to:
  /// **'Commission approved'**
  String get adminCommissionApproved;

  /// No description provided for @adminCommissionMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Commission marked as paid'**
  String get adminCommissionMarkedAsPaid;

  /// No description provided for @adminContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get adminContinue;

  /// No description provided for @adminCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get adminCopyCode;

  /// No description provided for @adminCouponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon Code'**
  String get adminCouponCode;

  /// No description provided for @adminCouponCreated.
  ///
  /// In en, this message translates to:
  /// **'Coupon created'**
  String get adminCouponCreated;

  /// No description provided for @adminCouponDeleted.
  ///
  /// In en, this message translates to:
  /// **'Coupon deleted'**
  String get adminCouponDeleted;

  /// No description provided for @adminCouponNotFound.
  ///
  /// In en, this message translates to:
  /// **'Coupon not found'**
  String get adminCouponNotFound;

  /// No description provided for @adminCouponReactivated.
  ///
  /// In en, this message translates to:
  /// **'Coupon reactivated'**
  String get adminCouponReactivated;

  /// No description provided for @adminCouponRevoked.
  ///
  /// In en, this message translates to:
  /// **'Coupon revoked'**
  String get adminCouponRevoked;

  /// No description provided for @adminCoupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get adminCoupons;

  /// No description provided for @adminCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get adminCreate;

  /// No description provided for @adminCreateAmbassador.
  ///
  /// In en, this message translates to:
  /// **'Create Ambassador'**
  String get adminCreateAmbassador;

  /// No description provided for @adminCreateCoupon.
  ///
  /// In en, this message translates to:
  /// **'Create Coupon'**
  String get adminCreateCoupon;

  /// No description provided for @adminCreateDefaultTiers.
  ///
  /// In en, this message translates to:
  /// **'Create Default Tiers'**
  String get adminCreateDefaultTiers;

  /// No description provided for @adminCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get adminCreateUser;

  /// No description provided for @adminDefaultTiersCreated.
  ///
  /// In en, this message translates to:
  /// **'Default tiers created'**
  String get adminDefaultTiersCreated;

  /// No description provided for @adminDeleteCoupon.
  ///
  /// In en, this message translates to:
  /// **'Delete Coupon'**
  String get adminDeleteCoupon;

  /// No description provided for @adminDeleteTier.
  ///
  /// In en, this message translates to:
  /// **'Delete Tier'**
  String get adminDeleteTier;

  /// No description provided for @adminDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get adminDeleteUser;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescription;

  /// No description provided for @adminDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get adminDescriptionOptional;

  /// No description provided for @adminDiscountType.
  ///
  /// In en, this message translates to:
  /// **'Discount Type'**
  String get adminDiscountType;

  /// No description provided for @adminDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get adminDisplayName;

  /// No description provided for @adminEGManualPaymentViaCheck.
  ///
  /// In en, this message translates to:
  /// **'e.g., Manual payment via check'**
  String get adminEGManualPaymentViaCheck;

  /// No description provided for @adminEGPROSTARTER.
  ///
  /// In en, this message translates to:
  /// **'e.g., PRO, STARTER'**
  String get adminEGPROSTARTER;

  /// No description provided for @adminEGProfessional.
  ///
  /// In en, this message translates to:
  /// **'e.g., Professional'**
  String get adminEGProfessional;

  /// No description provided for @adminEGSAVE20.
  ///
  /// In en, this message translates to:
  /// **'e.g., SAVE20'**
  String get adminEGSAVE20;

  /// No description provided for @adminEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get adminEarnings;

  /// No description provided for @adminEditCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'Edit Commission Rate'**
  String get adminEditCommissionRate;

  /// No description provided for @adminEditNotes.
  ///
  /// In en, this message translates to:
  /// **'Edit Notes'**
  String get adminEditNotes;

  /// No description provided for @adminEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get adminEditUser;

  /// No description provided for @adminExhausted.
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get adminExhausted;

  /// No description provided for @adminExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get adminExpired;

  /// No description provided for @adminExpiryDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date (optional)'**
  String get adminExpiryDateOptional;

  /// No description provided for @adminFailedToBulkApproveCommissionsPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to bulk approve commissions. Please try again.'**
  String get adminFailedToBulkApproveCommissionsPleaseTryAgain;

  /// No description provided for @adminFailedToBulkPayCommissionsPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to bulk pay commissions. Please try again.'**
  String get adminFailedToBulkPayCommissionsPleaseTryAgain;

  /// No description provided for @adminFailedToactionLabelAmbassadorPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to \$actionLabel ambassador. Please try again.'**
  String get adminFailedToactionLabelAmbassadorPleaseTryAgain;

  /// No description provided for @adminFeaturesOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'Features (one per line)'**
  String get adminFeaturesOnePerLine;

  /// No description provided for @adminFilterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get adminFilterByStatus;

  /// No description provided for @adminFixedAmountOff.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount Off'**
  String get adminFixedAmountOff;

  /// No description provided for @adminFreeTrialDays.
  ///
  /// In en, this message translates to:
  /// **'Free Trial Days'**
  String get adminFreeTrialDays;

  /// No description provided for @adminInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminInactive;

  /// No description provided for @adminInactiveTiersCannotBePurchased.
  ///
  /// In en, this message translates to:
  /// **'Inactive tiers cannot be purchased'**
  String get adminInactiveTiersCannotBePurchased;

  /// No description provided for @adminInternalDescription.
  ///
  /// In en, this message translates to:
  /// **'Internal description'**
  String get adminInternalDescription;

  /// No description provided for @adminLeaveBlankToKeepCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to keep current password'**
  String get adminLeaveBlankToKeepCurrentPassword;

  /// No description provided for @adminLoginAsTrainer.
  ///
  /// In en, this message translates to:
  /// **'Login as Trainer'**
  String get adminLoginAsTrainer;

  /// No description provided for @adminManageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get adminManageUsers;

  /// No description provided for @adminMarkCommissionAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Commission as Paid'**
  String get adminMarkCommissionAsPaid;

  /// No description provided for @adminMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get adminMarkPaid;

  /// No description provided for @adminMaxUses0Unlimited.
  ///
  /// In en, this message translates to:
  /// **'Max Uses (0 = unlimited)'**
  String get adminMaxUses0Unlimited;

  /// No description provided for @adminNewStatus.
  ///
  /// In en, this message translates to:
  /// **'New Status'**
  String get adminNewStatus;

  /// No description provided for @adminNewTier.
  ///
  /// In en, this message translates to:
  /// **'New Tier'**
  String get adminNewTier;

  /// No description provided for @adminNotesUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Notes updated successfully'**
  String get adminNotesUpdatedSuccessfully;

  /// No description provided for @adminPastDueAccounts.
  ///
  /// In en, this message translates to:
  /// **'Past Due Accounts'**
  String get adminPastDueAccounts;

  /// No description provided for @adminPastDueClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Past due cleared successfully'**
  String get adminPastDueClearedSuccessfully;

  /// No description provided for @adminPayAll.
  ///
  /// In en, this message translates to:
  /// **'Pay All'**
  String get adminPayAll;

  /// No description provided for @adminPayAllApproved.
  ///
  /// In en, this message translates to:
  /// **'Pay All Approved'**
  String get adminPayAllApproved;

  /// No description provided for @adminPaymentRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get adminPaymentRecordedSuccessfully;

  /// No description provided for @adminPercentageOff.
  ///
  /// In en, this message translates to:
  /// **'Percentage Off'**
  String get adminPercentageOff;

  /// No description provided for @adminPleaseFixTheErrorsBeforeContinuing.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors before continuing'**
  String get adminPleaseFixTheErrorsBeforeContinuing;

  /// No description provided for @adminPriceMonth.
  ///
  /// In en, this message translates to:
  /// **'Price (\\\$/month)'**
  String get adminPriceMonth;

  /// No description provided for @adminRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get adminRate;

  /// No description provided for @adminReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get adminReactivate;

  /// No description provided for @adminReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get adminReasonOptional;

  /// No description provided for @adminRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get adminRecord;

  /// No description provided for @adminRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get adminRecordPayment;

  /// No description provided for @adminReferrals.
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get adminReferrals;

  /// No description provided for @adminReminderSent.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent'**
  String get adminReminderSent;

  /// No description provided for @adminReturnedToAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Returned to admin account'**
  String get adminReturnedToAdminAccount;

  /// No description provided for @adminRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get adminRevoke;

  /// No description provided for @adminRevokeCoupon.
  ///
  /// In en, this message translates to:
  /// **'Revoke Coupon'**
  String get adminRevokeCoupon;

  /// No description provided for @adminRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get adminRevoked;

  /// No description provided for @adminSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get adminSaveChanges;

  /// No description provided for @adminSearchByEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by email...'**
  String get adminSearchByEmail;

  /// No description provided for @adminSearchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get adminSearchByNameOrEmail;

  /// No description provided for @adminSeedDefaults.
  ///
  /// In en, this message translates to:
  /// **'Seed Defaults'**
  String get adminSeedDefaults;

  /// No description provided for @adminSelectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get adminSelectRole;

  /// No description provided for @adminSendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get adminSendReminder;

  /// No description provided for @adminSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get adminSetPassword;

  /// No description provided for @adminShareThisWithTheAmbassadorSoTheyCanLogIn.
  ///
  /// In en, this message translates to:
  /// **'Share this with the ambassador so they can log in'**
  String get adminShareThisWithTheAmbassadorSoTheyCanLogIn;

  /// No description provided for @adminStatusUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Status updated successfully'**
  String get adminStatusUpdatedSuccessfully;

  /// No description provided for @adminSubscriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get adminSubscriptionDetails;

  /// No description provided for @adminSubscriptionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Subscription not found'**
  String get adminSubscriptionNotFound;

  /// No description provided for @adminSubscriptionTiers.
  ///
  /// In en, this message translates to:
  /// **'Subscription Tiers'**
  String get adminSubscriptionTiers;

  /// No description provided for @adminSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get adminSubscriptions;

  /// No description provided for @adminTapToReload.
  ///
  /// In en, this message translates to:
  /// **'Tap to reload'**
  String get adminTapToReload;

  /// No description provided for @adminTemporaryPassword.
  ///
  /// In en, this message translates to:
  /// **'Temporary Password'**
  String get adminTemporaryPassword;

  /// No description provided for @adminTierDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tier deleted'**
  String get adminTierDeleted;

  /// No description provided for @adminTierNameInternal.
  ///
  /// In en, this message translates to:
  /// **'Tier Name (Internal)'**
  String get adminTierNameInternal;

  /// No description provided for @adminTierUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tier updated successfully'**
  String get adminTierUpdatedSuccessfully;

  /// No description provided for @adminTiers.
  ///
  /// In en, this message translates to:
  /// **'Tiers'**
  String get adminTiers;

  /// No description provided for @adminTraineeCoachingOnly.
  ///
  /// In en, this message translates to:
  /// **'Trainee Coaching Only'**
  String get adminTraineeCoachingOnly;

  /// No description provided for @adminTraineeLimit.
  ///
  /// In en, this message translates to:
  /// **'Trainee Limit'**
  String get adminTraineeLimit;

  /// No description provided for @adminTrainer.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get adminTrainer;

  /// No description provided for @adminTrainerSubscriptionsOnly.
  ///
  /// In en, this message translates to:
  /// **'Trainer Subscriptions Only'**
  String get adminTrainerSubscriptionsOnly;

  /// No description provided for @adminTrainers.
  ///
  /// In en, this message translates to:
  /// **'Trainers'**
  String get adminTrainers;

  /// No description provided for @adminUpcomingPayments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Payments'**
  String get adminUpcomingPayments;

  /// No description provided for @adminUserDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get adminUserDeletedSuccessfully;

  /// No description provided for @adminUserDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get adminUserDetails;

  /// No description provided for @adminUserUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get adminUserUpdatedSuccessfully;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminViewSubscription.
  ///
  /// In en, this message translates to:
  /// **'View Subscription'**
  String get adminViewSubscription;

  /// No description provided for @aiChatAllTrainees.
  ///
  /// In en, this message translates to:
  /// **'All trainees'**
  String get aiChatAllTrainees;

  /// No description provided for @aiChatAreYouSureYouWantToClearTheConversationHistor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the conversation history?'**
  String get aiChatAreYouSureYouWantToClearTheConversationHistor;

  /// No description provided for @aiChatClearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation'**
  String get aiChatClearConversation;

  /// No description provided for @aiChatClearConversation2.
  ///
  /// In en, this message translates to:
  /// **'Clear Conversation'**
  String get aiChatClearConversation2;

  /// No description provided for @aiChatSearchTrainees.
  ///
  /// In en, this message translates to:
  /// **'Search trainees...'**
  String get aiChatSearchTrainees;

  /// No description provided for @ambassadorAmbassadorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Ambassador Dashboard'**
  String get ambassadorAmbassadorDashboard;

  /// No description provided for @ambassadorChangeReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Change Referral Code'**
  String get ambassadorChangeReferralCode;

  /// No description provided for @ambassadorEditReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Edit referral code'**
  String get ambassadorEditReferralCode;

  /// No description provided for @ambassadorFailedToStartStripeOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Failed to start Stripe onboarding'**
  String get ambassadorFailedToStartStripeOnboarding;

  /// No description provided for @ambassadorLogOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Log out of your account'**
  String get ambassadorLogOutOfYourAccount;

  /// No description provided for @ambassadorMyReferrals.
  ///
  /// In en, this message translates to:
  /// **'My Referrals'**
  String get ambassadorMyReferrals;

  /// No description provided for @ambassadorNoEarningsDataYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings data yet'**
  String get ambassadorNoEarningsDataYet;

  /// No description provided for @ambassadorOpeningStripeOnboardingCompleteSetupInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Opening Stripe onboarding... Complete setup in browser.'**
  String get ambassadorOpeningStripeOnboardingCompleteSetupInBrowser;

  /// No description provided for @ambassadorPayouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get ambassadorPayouts;

  /// No description provided for @ambassadorReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get ambassadorReferralCode;

  /// No description provided for @ambassadorReferralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied!'**
  String get ambassadorReferralCodeCopied;

  /// No description provided for @ambassadorReferralCodeUpdatedTocode.
  ///
  /// In en, this message translates to:
  /// **'Referral code updated to \$code'**
  String get ambassadorReferralCodeUpdatedTocode;

  /// No description provided for @ambassadorReferralCodecode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code: \$code'**
  String get ambassadorReferralCodecode;

  /// No description provided for @ambassadorShareMessageCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Share message copied to clipboard!'**
  String get ambassadorShareMessageCopiedToClipboard;

  /// No description provided for @ambassadorShareReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Share Referral Code'**
  String get ambassadorShareReferralCode;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'email'**
  String get authEmail;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailAddress;

  /// No description provided for @authEmailSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email sent successfully'**
  String get authEmailSentSuccessfully;

  /// No description provided for @authHaveAReferralCodeEnterItHere.
  ///
  /// In en, this message translates to:
  /// **'Have a referral code? Enter it here.'**
  String get authHaveAReferralCodeEnterItHere;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get authPassword;

  /// No description provided for @authPasswordResetIcon.
  ///
  /// In en, this message translates to:
  /// **'Password reset icon'**
  String get authPasswordResetIcon;

  /// No description provided for @authReferralCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get authReferralCodeOptional;

  /// No description provided for @authRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegister;

  /// No description provided for @authResetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get authResetToDefault;

  /// No description provided for @authResetToDefaultURL.
  ///
  /// In en, this message translates to:
  /// **'Reset to default URL'**
  String get authResetToDefaultURL;

  /// No description provided for @authRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get authRole;

  /// No description provided for @authServerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Server Configuration'**
  String get authServerConfiguration;

  /// No description provided for @authServerSettings.
  ///
  /// In en, this message translates to:
  /// **'Server Settings'**
  String get authServerSettings;

  /// No description provided for @authServerURL.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get authServerURL;

  /// No description provided for @authServerURLUpdatedTourl.
  ///
  /// In en, this message translates to:
  /// **'Server URL updated to: \$url'**
  String get authServerURLUpdatedTourl;

  /// No description provided for @authSetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get authSetNewPassword;

  /// No description provided for @authTrainee.
  ///
  /// In en, this message translates to:
  /// **'Trainee'**
  String get authTrainee;

  /// No description provided for @barcodeFiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get barcodeFiber;

  /// No description provided for @barcodeFoodAddedToYourLog.
  ///
  /// In en, this message translates to:
  /// **'Food added to your log'**
  String get barcodeFoodAddedToYourLog;

  /// No description provided for @barcodeScanAnother.
  ///
  /// In en, this message translates to:
  /// **'Scan Another'**
  String get barcodeScanAnother;

  /// No description provided for @barcodeScanResult.
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get barcodeScanResult;

  /// No description provided for @barcodeSugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get barcodeSugar;

  /// No description provided for @calendarAddAvailabilitySlot.
  ///
  /// In en, this message translates to:
  /// **'Add availability slot'**
  String get calendarAddAvailabilitySlot;

  /// No description provided for @calendarAuthorizationCode.
  ///
  /// In en, this message translates to:
  /// **'Authorization Code'**
  String get calendarAuthorizationCode;

  /// No description provided for @calendarAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get calendarAvailability;

  /// No description provided for @calendarBackToCalendarSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to Calendar Settings'**
  String get calendarBackToCalendarSettings;

  /// No description provided for @calendarCalendarEvents.
  ///
  /// In en, this message translates to:
  /// **'Calendar Events'**
  String get calendarCalendarEvents;

  /// No description provided for @calendarCalendarNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Calendar not connected'**
  String get calendarCalendarNotConnected;

  /// No description provided for @calendarConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get calendarConnect;

  /// No description provided for @calendarConnectACalendar.
  ///
  /// In en, this message translates to:
  /// **'Connect a Calendar'**
  String get calendarConnectACalendar;

  /// No description provided for @calendarConnecttitle.
  ///
  /// In en, this message translates to:
  /// **'Connect \$title'**
  String get calendarConnecttitle;

  /// No description provided for @calendarCouldNotGetAuthorizationURL.
  ///
  /// In en, this message translates to:
  /// **'Could not get authorization URL'**
  String get calendarCouldNotGetAuthorizationURL;

  /// No description provided for @calendarCouldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser'**
  String get calendarCouldNotOpenBrowser;

  /// No description provided for @calendarDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get calendarDayOfWeek;

  /// No description provided for @calendarDeleteSlot.
  ///
  /// In en, this message translates to:
  /// **'Delete Slot'**
  String get calendarDeleteSlot;

  /// No description provided for @calendarDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get calendarDisconnect;

  /// No description provided for @calendarDisconnectCalendar.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Calendar'**
  String get calendarDisconnectCalendar;

  /// No description provided for @calendarEditTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Edit time slot'**
  String get calendarEditTimeSlot;

  /// No description provided for @calendarEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get calendarEnd;

  /// No description provided for @calendarEndTimeMustBeAfterStartTime.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get calendarEndTimeMustBeAfterStartTime;

  /// No description provided for @calendarFilterBylabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by \$label'**
  String get calendarFilterBylabel;

  /// No description provided for @calendarGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get calendarGoBack;

  /// No description provided for @calendarGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get calendarGoogleCalendar;

  /// No description provided for @calendarManageAvailability.
  ///
  /// In en, this message translates to:
  /// **'Manage Availability'**
  String get calendarManageAvailability;

  /// No description provided for @calendarMicrosoft.
  ///
  /// In en, this message translates to:
  /// **'Microsoft'**
  String get calendarMicrosoft;

  /// No description provided for @calendarMicrosoftOutlook.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Outlook'**
  String get calendarMicrosoftOutlook;

  /// No description provided for @calendarNoAvailability.
  ///
  /// In en, this message translates to:
  /// **'No availability'**
  String get calendarNoAvailability;

  /// No description provided for @calendarNoAvailabilitySet.
  ///
  /// In en, this message translates to:
  /// **'No availability set'**
  String get calendarNoAvailabilitySet;

  /// No description provided for @calendarNoAvailabilitySetTapThePlusButtonToAddYourFir.
  ///
  /// In en, this message translates to:
  /// **'No availability set. Tap the plus button to add your first time slot.'**
  String get calendarNoAvailabilitySetTapThePlusButtonToAddYourFir;

  /// No description provided for @calendarNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get calendarNoEvents;

  /// No description provided for @calendarNoUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get calendarNoUpcomingEvents;

  /// No description provided for @calendarNoUpcomingEventsPullDownToSyncYourCalendar.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events. Pull down to sync your calendar.'**
  String get calendarNoUpcomingEventsPullDownToSyncYourCalendar;

  /// No description provided for @calendarPleaseEnterBothCodeAndState.
  ///
  /// In en, this message translates to:
  /// **'Please enter both code and state'**
  String get calendarPleaseEnterBothCodeAndState;

  /// No description provided for @calendarRemoveThisAvailabilitySlot.
  ///
  /// In en, this message translates to:
  /// **'Remove this availability slot?'**
  String get calendarRemoveThisAvailabilitySlot;

  /// No description provided for @calendarStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get calendarStart;

  /// No description provided for @calendarStateParameter.
  ///
  /// In en, this message translates to:
  /// **'State Parameter'**
  String get calendarStateParameter;

  /// No description provided for @calendarSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get calendarSyncNow;

  /// No description provided for @checkinsAddField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get checkinsAddField;

  /// No description provided for @checkinsAddNotesAboutThisCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Add notes about this check-in...'**
  String get checkinsAddNotesAboutThisCheckIn;

  /// No description provided for @checkinsAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option...'**
  String get checkinsAddOption;

  /// No description provided for @checkinsBuildCheckInForm.
  ///
  /// In en, this message translates to:
  /// **'Build Check-In Form'**
  String get checkinsBuildCheckInForm;

  /// No description provided for @checkinsCheckInResponses.
  ///
  /// In en, this message translates to:
  /// **'Check-In Responses'**
  String get checkinsCheckInResponses;

  /// No description provided for @checkinsCheckInSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Check-in submitted successfully!'**
  String get checkinsCheckInSubmittedSuccessfully;

  /// No description provided for @checkinsDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get checkinsDiscard;

  /// No description provided for @checkinsDiscardCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Discard check-in?'**
  String get checkinsDiscardCheckIn;

  /// No description provided for @checkinsEGHowAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'e.g. How are you feeling?'**
  String get checkinsEGHowAreYouFeeling;

  /// No description provided for @checkinsEGWeeklyProgressCheckIn.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekly Progress Check-In'**
  String get checkinsEGWeeklyProgressCheckIn;

  /// No description provided for @checkinsEnterANumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number...'**
  String get checkinsEnterANumber;

  /// No description provided for @checkinsEnterYourResponse.
  ///
  /// In en, this message translates to:
  /// **'Enter your response...'**
  String get checkinsEnterYourResponse;

  /// No description provided for @checkinsFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get checkinsFields;

  /// No description provided for @checkinsFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get checkinsFrequency;

  /// No description provided for @checkinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get checkinsLabel;

  /// No description provided for @checkinsPleaseFillInAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get checkinsPleaseFillInAllRequiredFields;

  /// No description provided for @checkinsPleaseFillInTheTemplateNameAndAllFieldLabels.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the template name and all field labels'**
  String get checkinsPleaseFillInTheTemplateNameAndAllFieldLabels;

  /// No description provided for @checkinsRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get checkinsRequired;

  /// No description provided for @checkinsSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get checkinsSaveNote;

  /// No description provided for @checkinsSubmitCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Submit Check-In'**
  String get checkinsSubmitCheckIn;

  /// No description provided for @checkinsTemplateCreated.
  ///
  /// In en, this message translates to:
  /// **'Template created!'**
  String get checkinsTemplateCreated;

  /// No description provided for @checkinsTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get checkinsTemplateName;

  /// No description provided for @checkinsType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get checkinsType;

  /// No description provided for @commonActiveCal.
  ///
  /// In en, this message translates to:
  /// **'Active Cal'**
  String get commonActiveCal;

  /// No description provided for @commonApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get commonApplyFilters;

  /// No description provided for @commonHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get commonHeartRate;

  /// No description provided for @commonLoadingHealthData.
  ///
  /// In en, this message translates to:
  /// **'Loading health data'**
  String get commonLoadingHealthData;

  /// No description provided for @commonOpenHealthSettings.
  ///
  /// In en, this message translates to:
  /// **'Open health settings'**
  String get commonOpenHealthSettings;

  /// No description provided for @commonRetryAll.
  ///
  /// In en, this message translates to:
  /// **'Retry All'**
  String get commonRetryAll;

  /// No description provided for @communityAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get communityAchievements;

  /// No description provided for @communityAttendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get communityAttendees;

  /// No description provided for @communityAttendeesJoinViaMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Attendees join via meeting link'**
  String get communityAttendeesJoinViaMeetingLink;

  /// No description provided for @communityAutoJoinNewMembers.
  ///
  /// In en, this message translates to:
  /// **'Auto-join new members'**
  String get communityAutoJoinNewMembers;

  /// No description provided for @communityCancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Cancel event'**
  String get communityCancelEvent;

  /// No description provided for @communityCancelEvent2.
  ///
  /// In en, this message translates to:
  /// **'Cancel Event?'**
  String get communityCancelEvent2;

  /// No description provided for @communityCancelEvent3.
  ///
  /// In en, this message translates to:
  /// **'Cancel Event'**
  String get communityCancelEvent3;

  /// No description provided for @communityCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get communityCancelled;

  /// No description provided for @communityChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get communityChallenge;

  /// No description provided for @communityCloseFullscreenVideo.
  ///
  /// In en, this message translates to:
  /// **'Close fullscreen video'**
  String get communityCloseFullscreenVideo;

  /// No description provided for @communityCouldNotOpenMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open meeting link'**
  String get communityCouldNotOpenMeetingLink;

  /// No description provided for @communityCreateANewEvent.
  ///
  /// In en, this message translates to:
  /// **'Create a new event'**
  String get communityCreateANewEvent;

  /// No description provided for @communityCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get communityCreateEvent;

  /// No description provided for @communityCreateEvent2.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get communityCreateEvent2;

  /// No description provided for @communityCreateSpace.
  ///
  /// In en, this message translates to:
  /// **'Create Space'**
  String get communityCreateSpace;

  /// No description provided for @communityDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get communityDateTime;

  /// No description provided for @communityDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment'**
  String get communityDeleteComment;

  /// No description provided for @communityDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get communityDeleteEvent;

  /// No description provided for @communityDeleteEvent2.
  ///
  /// In en, this message translates to:
  /// **'Delete Event?'**
  String get communityDeleteEvent2;

  /// No description provided for @communityDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get communityDeletePost;

  /// No description provided for @communityDeleteThisComment.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get communityDeleteThisComment;

  /// No description provided for @communityDeleteThisPostThisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Delete this post? This cannot be undone.'**
  String get communityDeleteThisPostThisCannotBeUndone;

  /// No description provided for @communityEGWorkoutTips.
  ///
  /// In en, this message translates to:
  /// **'e.g. Workout Tips'**
  String get communityEGWorkoutTips;

  /// No description provided for @communityEventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Event cancelled'**
  String get communityEventCancelled;

  /// No description provided for @communityEventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get communityEventDeleted;

  /// No description provided for @communityEventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get communityEventDetails;

  /// No description provided for @communityEventNotFoundOrNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Event not found or no longer available'**
  String get communityEventNotFoundOrNoLongerAvailable;

  /// No description provided for @communityEventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get communityEventType;

  /// No description provided for @communityEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get communityEvents;

  /// No description provided for @communityFailedToCancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel event'**
  String get communityFailedToCancelEvent;

  /// No description provided for @communityFailedToCreatePostPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post. Please try again.'**
  String get communityFailedToCreatePostPleaseTryAgain;

  /// No description provided for @communityFailedToCreateSpace.
  ///
  /// In en, this message translates to:
  /// **'Failed to create space'**
  String get communityFailedToCreateSpace;

  /// No description provided for @communityFailedToDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete comment'**
  String get communityFailedToDeleteComment;

  /// No description provided for @communityFailedToDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete event'**
  String get communityFailedToDeleteEvent;

  /// No description provided for @communityFailedToPostComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to post comment'**
  String get communityFailedToPostComment;

  /// No description provided for @communityFire.
  ///
  /// In en, this message translates to:
  /// **'fire'**
  String get communityFire;

  /// No description provided for @communityGeneralFeed.
  ///
  /// In en, this message translates to:
  /// **'General feed'**
  String get communityGeneralFeed;

  /// No description provided for @communityGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get communityGoBack;

  /// No description provided for @communityGoing.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get communityGoing;

  /// No description provided for @communityHeart.
  ///
  /// In en, this message translates to:
  /// **'heart'**
  String get communityHeart;

  /// No description provided for @communityInterested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get communityInterested;

  /// No description provided for @communityJoinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get communityJoinMeeting;

  /// No description provided for @communityJoinSpace.
  ///
  /// In en, this message translates to:
  /// **'Join Space'**
  String get communityJoinSpace;

  /// No description provided for @communityJoinVirtualMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join virtual meeting'**
  String get communityJoinVirtualMeeting;

  /// No description provided for @communityKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get communityKeep;

  /// No description provided for @communityLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get communityLatest;

  /// No description provided for @communityLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get communityLeaderboard;

  /// No description provided for @communityLeaveEmptyForUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for unlimited.'**
  String get communityLeaveEmptyForUnlimited;

  /// No description provided for @communityLeaveSpace.
  ///
  /// In en, this message translates to:
  /// **'Leave Space'**
  String get communityLeaveSpace;

  /// No description provided for @communityLiveSession.
  ///
  /// In en, this message translates to:
  /// **'Live Session'**
  String get communityLiveSession;

  /// No description provided for @communityLoadingAchievements.
  ///
  /// In en, this message translates to:
  /// **'Loading achievements'**
  String get communityLoadingAchievements;

  /// No description provided for @communityLoadingAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Loading announcements'**
  String get communityLoadingAnnouncements;

  /// No description provided for @communityLoadingCommunityFeed.
  ///
  /// In en, this message translates to:
  /// **'Loading community feed'**
  String get communityLoadingCommunityFeed;

  /// No description provided for @communityLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Loading events'**
  String get communityLoadingEvents;

  /// No description provided for @communityMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown'**
  String get communityMarkdown;

  /// No description provided for @communityMaxAttendeesOptional.
  ///
  /// In en, this message translates to:
  /// **'Max Attendees (optional)'**
  String get communityMaxAttendeesOptional;

  /// No description provided for @communityMeetingLink.
  ///
  /// In en, this message translates to:
  /// **'Meeting Link'**
  String get communityMeetingLink;

  /// No description provided for @communityMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get communityMetric;

  /// No description provided for @communityNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get communityNewPost;

  /// No description provided for @communityOpenFullscreenVideo.
  ///
  /// In en, this message translates to:
  /// **'Open fullscreen video'**
  String get communityOpenFullscreenVideo;

  /// No description provided for @communityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get communityOther;

  /// No description provided for @communityPastEvents.
  ///
  /// In en, this message translates to:
  /// **'Past Events'**
  String get communityPastEvents;

  /// No description provided for @communityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get communityPeriod;

  /// No description provided for @communityPlayVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get communityPlayVideo;

  /// No description provided for @communityPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get communityPopular;

  /// No description provided for @communityPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityPost;

  /// No description provided for @communityPostTo.
  ///
  /// In en, this message translates to:
  /// **'Post to'**
  String get communityPostTo;

  /// No description provided for @communityPosted.
  ///
  /// In en, this message translates to:
  /// **'Posted!'**
  String get communityPosted;

  /// No description provided for @communityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get communityPrivate;

  /// No description provided for @communityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get communityPublic;

  /// No description provided for @communityQA.
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get communityQA;

  /// No description provided for @communitySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get communitySaved;

  /// No description provided for @communitySavedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get communitySavedPosts;

  /// No description provided for @communitySearchSpaces.
  ///
  /// In en, this message translates to:
  /// **'Search spaces...'**
  String get communitySearchSpaces;

  /// No description provided for @communitySpaceCreated.
  ///
  /// In en, this message translates to:
  /// **'Space created!'**
  String get communitySpaceCreated;

  /// No description provided for @communitySpaceName.
  ///
  /// In en, this message translates to:
  /// **'Space Name'**
  String get communitySpaceName;

  /// No description provided for @communitySpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get communitySpaces;

  /// No description provided for @communityStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get communityStreak;

  /// No description provided for @communityThisEventHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'This event has been cancelled.'**
  String get communityThisEventHasBeenCancelled;

  /// No description provided for @communityThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get communityThisMonth;

  /// No description provided for @communityThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get communityThisWeek;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get communityTitle;

  /// No description provided for @communityUnmuteVideo.
  ///
  /// In en, this message translates to:
  /// **'Unmute video'**
  String get communityUnmuteVideo;

  /// No description provided for @communityUnsupportedFormatUseMP4MOVOrWebM.
  ///
  /// In en, this message translates to:
  /// **'Unsupported format. Use MP4, MOV, or WebM.'**
  String get communityUnsupportedFormatUseMP4MOVOrWebM;

  /// No description provided for @communityVideoAttachmentTapToPlayLongPressForFullscree.
  ///
  /// In en, this message translates to:
  /// **'Video attachment. Tap to play, long press for fullscreen.'**
  String get communityVideoAttachmentTapToPlayLongPressForFullscree;

  /// No description provided for @communityVideoFileIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Video file is empty.'**
  String get communityVideoFileIsEmpty;

  /// No description provided for @communityVideoMustBeUnder50MB.
  ///
  /// In en, this message translates to:
  /// **'Video must be under 50MB.'**
  String get communityVideoMustBeUnder50MB;

  /// No description provided for @communityVideoSeekBar.
  ///
  /// In en, this message translates to:
  /// **'Video seek bar'**
  String get communityVideoSeekBar;

  /// No description provided for @communityVirtualEvent.
  ///
  /// In en, this message translates to:
  /// **'Virtual Event'**
  String get communityVirtualEvent;

  /// No description provided for @communityWhatIsThisSpaceAbout.
  ///
  /// In en, this message translates to:
  /// **'What is this space about?'**
  String get communityWhatIsThisSpaceAbout;

  /// No description provided for @communityWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get communityWorkouts;

  /// No description provided for @communityWorkshop.
  ///
  /// In en, this message translates to:
  /// **'Workshop'**
  String get communityWorkshop;

  /// No description provided for @dashboardAiCommand.
  ///
  /// In en, this message translates to:
  /// **'AI Command'**
  String get dashboardAiCommand;

  /// No description provided for @dashboardSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get dashboardSteps;

  /// No description provided for @exercisesAddCustomExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Exercise'**
  String get exercisesAddCustomExercise;

  /// No description provided for @exercisesChangeTheExerciseThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Change the exercise thumbnail'**
  String get exercisesChangeTheExerciseThumbnail;

  /// No description provided for @exercisesClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get exercisesClearSelection;

  /// No description provided for @exercisesCouldNotOpenVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not open video'**
  String get exercisesCouldNotOpenVideo;

  /// No description provided for @exercisesCreateExercise.
  ///
  /// In en, this message translates to:
  /// **'Create Exercise'**
  String get exercisesCreateExercise;

  /// No description provided for @exercisesCustomMuscleGroupOptional.
  ///
  /// In en, this message translates to:
  /// **'Custom Muscle Group (optional)'**
  String get exercisesCustomMuscleGroupOptional;

  /// No description provided for @exercisesEGForearmsNeckHipFlexors.
  ///
  /// In en, this message translates to:
  /// **'e.g., Forearms, Neck, Hip Flexors...'**
  String get exercisesEGForearmsNeckHipFlexors;

  /// No description provided for @exercisesEGInclineDumbbellPress.
  ///
  /// In en, this message translates to:
  /// **'e.g., Incline Dumbbell Press'**
  String get exercisesEGInclineDumbbellPress;

  /// No description provided for @exercisesEditImage.
  ///
  /// In en, this message translates to:
  /// **'Edit Image'**
  String get exercisesEditImage;

  /// No description provided for @exercisesEditVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit Video'**
  String get exercisesEditVideo;

  /// No description provided for @exercisesErrorerror.
  ///
  /// In en, this message translates to:
  /// **'Error: \$error'**
  String get exercisesErrorerror;

  /// No description provided for @exercisesExerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get exercisesExerciseLibrary;

  /// No description provided for @exercisesExerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise Name *'**
  String get exercisesExerciseName;

  /// No description provided for @exercisesExercisenameCreated.
  ///
  /// In en, this message translates to:
  /// **'Exercise \"\$name\" created'**
  String get exercisesExercisenameCreated;

  /// No description provided for @exercisesHowToPerformThisExercise.
  ///
  /// In en, this message translates to:
  /// **'How to perform this exercise...'**
  String get exercisesHowToPerformThisExercise;

  /// No description provided for @exercisesImageURL.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get exercisesImageURL;

  /// No description provided for @exercisesImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Image updated'**
  String get exercisesImageUpdated;

  /// No description provided for @exercisesImageUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get exercisesImageUploadedSuccessfully;

  /// No description provided for @exercisesInvalidYouTubeURL.
  ///
  /// In en, this message translates to:
  /// **'Invalid YouTube URL'**
  String get exercisesInvalidYouTubeURL;

  /// No description provided for @exercisesLeaveEmptyToUseOther.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use \"Other\"'**
  String get exercisesLeaveEmptyToUseOther;

  /// No description provided for @exercisesMuscleGroup.
  ///
  /// In en, this message translates to:
  /// **'Muscle Group *'**
  String get exercisesMuscleGroup;

  /// No description provided for @exercisesPleaseEnterAnExerciseName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an exercise name'**
  String get exercisesPleaseEnterAnExerciseName;

  /// No description provided for @exercisesPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get exercisesPreview;

  /// No description provided for @exercisesSaveURL.
  ///
  /// In en, this message translates to:
  /// **'Save URL'**
  String get exercisesSaveURL;

  /// No description provided for @exercisesSeeFullExerciseInformation.
  ///
  /// In en, this message translates to:
  /// **'See full exercise information'**
  String get exercisesSeeFullExerciseInformation;

  /// No description provided for @exercisesVideoURLOptional.
  ///
  /// In en, this message translates to:
  /// **'Video URL (optional)'**
  String get exercisesVideoURLOptional;

  /// No description provided for @exercisesVideoURLUpdated.
  ///
  /// In en, this message translates to:
  /// **'Video URL updated'**
  String get exercisesVideoURLUpdated;

  /// No description provided for @exercisesVideoUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Video uploaded successfully'**
  String get exercisesVideoUploadedSuccessfully;

  /// No description provided for @exercisesViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get exercisesViewDetails;

  /// No description provided for @exercisesWatchTutorialVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch Tutorial Video'**
  String get exercisesWatchTutorialVideo;

  /// No description provided for @exercisesYoutubeURL.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get exercisesYoutubeURL;

  /// No description provided for @featureReqAddAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get featureReqAddAComment;

  /// No description provided for @featureReqApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get featureReqApply;

  /// No description provided for @featureReqBriefDescriptionOfYourIdea.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your idea'**
  String get featureReqBriefDescriptionOfYourIdea;

  /// No description provided for @featureReqCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get featureReqCategory;

  /// No description provided for @featureReqErrorLoadingCommentse.
  ///
  /// In en, this message translates to:
  /// **'Error loading comments: \$e'**
  String get featureReqErrorLoadingCommentse;

  /// No description provided for @featureReqErrore.
  ///
  /// In en, this message translates to:
  /// **'Error: \$e'**
  String get featureReqErrore;

  /// No description provided for @featureReqExplainYourIdeaInDetailWhatProblemDoesItSolve.
  ///
  /// In en, this message translates to:
  /// **'Explain your idea in detail. What problem does it solve? How would it work?'**
  String get featureReqExplainYourIdeaInDetailWhatProblemDoesItSolve;

  /// No description provided for @featureReqFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureReqFeatureRequest;

  /// No description provided for @featureReqFeatureRequestNotFound.
  ///
  /// In en, this message translates to:
  /// **'Feature request not found'**
  String get featureReqFeatureRequestNotFound;

  /// No description provided for @featureReqFeatureRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feature request submitted successfully!'**
  String get featureReqFeatureRequestSubmittedSuccessfully;

  /// No description provided for @featureReqFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature Title'**
  String get featureReqFeatureTitle;

  /// No description provided for @featureReqMostVotes.
  ///
  /// In en, this message translates to:
  /// **'Most Votes'**
  String get featureReqMostVotes;

  /// No description provided for @featureReqRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get featureReqRecent;

  /// No description provided for @featureReqRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get featureReqRequest;

  /// No description provided for @featureReqRequestAFeature.
  ///
  /// In en, this message translates to:
  /// **'Request a Feature'**
  String get featureReqRequestAFeature;

  /// No description provided for @featureReqRequestFeature.
  ///
  /// In en, this message translates to:
  /// **'Request Feature'**
  String get featureReqRequestFeature;

  /// No description provided for @featureReqSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get featureReqSortBy;

  /// No description provided for @featureReqStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get featureReqStatus;

  /// No description provided for @featureReqSubmitFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Feature Request'**
  String get featureReqSubmitFeatureRequest;

  /// No description provided for @habitsBriefDescriptionOfTheHabit.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the habit'**
  String get habitsBriefDescriptionOfTheHabit;

  /// No description provided for @habitsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get habitsCustom;

  /// No description provided for @habitsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get habitsDaily;

  /// No description provided for @habitsDailyHabits.
  ///
  /// In en, this message translates to:
  /// **'Daily Habits'**
  String get habitsDailyHabits;

  /// No description provided for @habitsDeleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete Habit'**
  String get habitsDeleteHabit;

  /// No description provided for @habitsEGDrink8GlassesOfWater.
  ///
  /// In en, this message translates to:
  /// **'e.g., Drink 8 glasses of water'**
  String get habitsEGDrink8GlassesOfWater;

  /// No description provided for @habitsFailedToUpdateHabit.
  ///
  /// In en, this message translates to:
  /// **'Failed to update habit'**
  String get habitsFailedToUpdateHabit;

  /// No description provided for @habitsHabitName.
  ///
  /// In en, this message translates to:
  /// **'Habit Name'**
  String get habitsHabitName;

  /// No description provided for @habitsManageHabits.
  ///
  /// In en, this message translates to:
  /// **'Manage Habits'**
  String get habitsManageHabits;

  /// No description provided for @habitsPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get habitsPickDate;

  /// No description provided for @habitsPleaseSelectAtLeastOneDayForCustomFrequency.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one day for custom frequency'**
  String get habitsPleaseSelectAtLeastOneDayForCustomFrequency;

  /// No description provided for @habitsWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get habitsWeekdays;

  /// No description provided for @homeAdvancedGluteBiomechanicsWithTomJoe.
  ///
  /// In en, this message translates to:
  /// **'Advanced Glute Biomechanics with Tom & Joe'**
  String get homeAdvancedGluteBiomechanicsWithTomJoe;

  /// No description provided for @homeLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get homeLog;

  /// No description provided for @homeLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get homeLogout;

  /// No description provided for @homeLogoutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Logout Anyway'**
  String get homeLogoutAnyway;

  /// No description provided for @homeOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get homeOverview;

  /// No description provided for @homePerfectYourSquatForm.
  ///
  /// In en, this message translates to:
  /// **'Perfect Your Squat Form'**
  String get homePerfectYourSquatForm;

  /// No description provided for @homeStartYourFirstWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start your first workout!'**
  String get homeStartYourFirstWorkout;

  /// No description provided for @homeThisWorkoutIsWaitingToSync.
  ///
  /// In en, this message translates to:
  /// **'This workout is waiting to sync.'**
  String get homeThisWorkoutIsWaitingToSync;

  /// No description provided for @homeUnsyncedData.
  ///
  /// In en, this message translates to:
  /// **'Unsynced Data'**
  String get homeUnsyncedData;

  /// No description provided for @homeUpperBodyStrengthTrainingTips.
  ///
  /// In en, this message translates to:
  /// **'Upper Body Strength Training Tips'**
  String get homeUpperBodyStrengthTrainingTips;

  /// No description provided for @homeViewPrograms.
  ///
  /// In en, this message translates to:
  /// **'View Programs'**
  String get homeViewPrograms;

  /// No description provided for @homeWeekCompleteGreatJob.
  ///
  /// In en, this message translates to:
  /// **'Week complete — great job!'**
  String get homeWeekCompleteGreatJob;

  /// No description provided for @loggingAiCommandCenter.
  ///
  /// In en, this message translates to:
  /// **'AI Command Center'**
  String get loggingAiCommandCenter;

  /// No description provided for @loggingLogSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Log saved successfully!'**
  String get loggingLogSavedSuccessfully;

  /// No description provided for @loggingTypeYourLogHere.
  ///
  /// In en, this message translates to:
  /// **'Type your log here...'**
  String get loggingTypeYourLogHere;

  /// No description provided for @messagingAttachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get messagingAttachImage;

  /// No description provided for @messagingConversationList.
  ///
  /// In en, this message translates to:
  /// **'Conversation list'**
  String get messagingConversationList;

  /// No description provided for @messagingCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get messagingCopy;

  /// No description provided for @messagingDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get messagingDeleteMessage;

  /// No description provided for @messagingEditYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit your message...'**
  String get messagingEditYourMessage;

  /// No description provided for @messagingFullScreenImagePinchToZoom.
  ///
  /// In en, this message translates to:
  /// **'Full screen image. Pinch to zoom.'**
  String get messagingFullScreenImagePinchToZoom;

  /// No description provided for @messagingGoToTrainees.
  ///
  /// In en, this message translates to:
  /// **'Go to Trainees'**
  String get messagingGoToTrainees;

  /// No description provided for @messagingImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get messagingImage;

  /// No description provided for @messagingImageMustBeUnder5MB.
  ///
  /// In en, this message translates to:
  /// **'Image must be under 5MB'**
  String get messagingImageMustBeUnder5MB;

  /// No description provided for @messagingMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get messagingMessageCopied;

  /// No description provided for @messagingOtherPersonIsTyping.
  ///
  /// In en, this message translates to:
  /// **'Other person is typing'**
  String get messagingOtherPersonIsTyping;

  /// No description provided for @messagingSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get messagingSendMessage;

  /// No description provided for @nutritionAddFirstCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Add First Check-In'**
  String get nutritionAddFirstCheckIn;

  /// No description provided for @nutritionAddedFat.
  ///
  /// In en, this message translates to:
  /// **'Added Fat'**
  String get nutritionAddedFat;

  /// No description provided for @nutritionAddedfoodNameToMealmealNumber.
  ///
  /// In en, this message translates to:
  /// **'Added \"\$foodName\" to Meal \$mealNumber'**
  String get nutritionAddedfoodNameToMealmealNumber;

  /// No description provided for @nutritionAreYouSureYouWantToDeleteThisFoodEntry.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this food entry?'**
  String get nutritionAreYouSureYouWantToDeleteThisFoodEntry;

  /// No description provided for @nutritionAssignNutritionTemplate.
  ///
  /// In en, this message translates to:
  /// **'Assign Nutrition Template'**
  String get nutritionAssignNutritionTemplate;

  /// No description provided for @nutritionAssignTemplate.
  ///
  /// In en, this message translates to:
  /// **'Assign Template'**
  String get nutritionAssignTemplate;

  /// No description provided for @nutritionBackToResults.
  ///
  /// In en, this message translates to:
  /// **'Back to results'**
  String get nutritionBackToResults;

  /// No description provided for @nutritionBetween1And10.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 10.'**
  String get nutritionBetween1And10;

  /// No description provided for @nutritionBodyFatMustBeBetween1And70.
  ///
  /// In en, this message translates to:
  /// **'Body fat % must be between 1 and 70'**
  String get nutritionBodyFatMustBeBetween1And70;

  /// No description provided for @nutritionBodyFatOptional.
  ///
  /// In en, this message translates to:
  /// **'Body Fat % (optional)'**
  String get nutritionBodyFatOptional;

  /// No description provided for @nutritionBodyWeightIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Body weight is required'**
  String get nutritionBodyWeightIsRequired;

  /// No description provided for @nutritionBodyWeightLbs.
  ///
  /// In en, this message translates to:
  /// **'Body Weight (lbs)'**
  String get nutritionBodyWeightLbs;

  /// No description provided for @nutritionBodyWeightMustBeAPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Body weight must be a positive number'**
  String get nutritionBodyWeightMustBeAPositiveNumber;

  /// No description provided for @nutritionBodyWeightMustBeUnder1000Lbs.
  ///
  /// In en, this message translates to:
  /// **'Body weight must be under 1,000 lbs'**
  String get nutritionBodyWeightMustBeUnder1000Lbs;

  /// No description provided for @nutritionCarbsG.
  ///
  /// In en, this message translates to:
  /// **'Carbs, g'**
  String get nutritionCarbsG;

  /// No description provided for @nutritionCarbsG2.
  ///
  /// In en, this message translates to:
  /// **'Carbs (g)'**
  String get nutritionCarbsG2;

  /// No description provided for @nutritionCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get nutritionCheckIn;

  /// No description provided for @nutritionClarificationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Clarification needed'**
  String get nutritionClarificationNeeded;

  /// No description provided for @nutritionClearMeal.
  ///
  /// In en, this message translates to:
  /// **'Clear Meal'**
  String get nutritionClearMeal;

  /// No description provided for @nutritionCopyMeal.
  ///
  /// In en, this message translates to:
  /// **'Copy Meal'**
  String get nutritionCopyMeal;

  /// No description provided for @nutritionDayTypeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Day-Type Schedule'**
  String get nutritionDayTypeSchedule;

  /// No description provided for @nutritionDeleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get nutritionDeleteEntry;

  /// No description provided for @nutritionEG150g1Cup.
  ///
  /// In en, this message translates to:
  /// **'e.g., 150g, 1 cup'**
  String get nutritionEG150g1Cup;

  /// No description provided for @nutritionEG2ChickenBreasts1CupRice1Apple.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"2 chicken breasts, 1 cup rice, 1 apple\"'**
  String get nutritionEG2ChickenBreasts1CupRice1Apple;

  /// No description provided for @nutritionEGChickenBreast.
  ///
  /// In en, this message translates to:
  /// **'e.g., Chicken Breast'**
  String get nutritionEGChickenBreast;

  /// No description provided for @nutritionEditFoodEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit food entry'**
  String get nutritionEditFoodEntry;

  /// No description provided for @nutritionFailedToAddFood.
  ///
  /// In en, this message translates to:
  /// **'Failed to add food'**
  String get nutritionFailedToAddFood;

  /// No description provided for @nutritionFailedToAssignTemplatePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign template. Please try again.'**
  String get nutritionFailedToAssignTemplatePleaseTryAgain;

  /// No description provided for @nutritionFailedToLoadWeekPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to load week plan'**
  String get nutritionFailedToLoadWeekPlan;

  /// No description provided for @nutritionFailedToSaveFoodEntry.
  ///
  /// In en, this message translates to:
  /// **'Failed to save food entry'**
  String get nutritionFailedToSaveFoodEntry;

  /// No description provided for @nutritionFailedToSaveFoodEntryPleaseCheckYourConnectio.
  ///
  /// In en, this message translates to:
  /// **'Failed to save food entry. Please check your connection and try again.'**
  String get nutritionFailedToSaveFoodEntryPleaseCheckYourConnectio;

  /// No description provided for @nutritionFatG.
  ///
  /// In en, this message translates to:
  /// **'Fat, g'**
  String get nutritionFatG;

  /// No description provided for @nutritionFatG2.
  ///
  /// In en, this message translates to:
  /// **'Fat (g)'**
  String get nutritionFatG2;

  /// No description provided for @nutritionFatMode.
  ///
  /// In en, this message translates to:
  /// **'Fat Mode'**
  String get nutritionFatMode;

  /// No description provided for @nutritionFoodEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Food entry deleted'**
  String get nutritionFoodEntryDeleted;

  /// No description provided for @nutritionFoodEntryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Food entry updated'**
  String get nutritionFoodEntryUpdated;

  /// No description provided for @nutritionFoodLoggedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Food logged successfully'**
  String get nutritionFoodLoggedSuccessfully;

  /// No description provided for @nutritionFoodName.
  ///
  /// In en, this message translates to:
  /// **'Food name'**
  String get nutritionFoodName;

  /// No description provided for @nutritionHowAreYouFeelingToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get nutritionHowAreYouFeelingToday;

  /// No description provided for @nutritionIfKnownImprovesLeanBodyMassCalculation.
  ///
  /// In en, this message translates to:
  /// **'If known, improves lean body mass calculation.'**
  String get nutritionIfKnownImprovesLeanBodyMassCalculation;

  /// No description provided for @nutritionIncludeQuantitiesAndMeasurementsForAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Include quantities and measurements for accuracy'**
  String get nutritionIncludeQuantitiesAndMeasurementsForAccuracy;

  /// No description provided for @nutritionLoadingNutritionTemplates.
  ///
  /// In en, this message translates to:
  /// **'Loading nutrition templates'**
  String get nutritionLoadingNutritionTemplates;

  /// No description provided for @nutritionMealmealNum.
  ///
  /// In en, this message translates to:
  /// **'Meal \$mealNum'**
  String get nutritionMealmealNum;

  /// No description provided for @nutritionMealsPerDayMustBeBetween1And10.
  ///
  /// In en, this message translates to:
  /// **'Meals per day must be between 1 and 10'**
  String get nutritionMealsPerDayMustBeBetween1And10;

  /// No description provided for @nutritionNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nutritionNextDay;

  /// No description provided for @nutritionNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nutritionNextWeek;

  /// No description provided for @nutritionNoFoodItemsDetectedPleaseDescribeWhatYouAteWi.
  ///
  /// In en, this message translates to:
  /// **'No food items detected. Please describe what you ate with quantities.'**
  String get nutritionNoFoodItemsDetectedPleaseDescribeWhatYouAteWi;

  /// No description provided for @nutritionNoLogFoundForThisDate.
  ///
  /// In en, this message translates to:
  /// **'No log found for this date'**
  String get nutritionNoLogFoundForThisDate;

  /// No description provided for @nutritionNutritionPlan.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Plan'**
  String get nutritionNutritionPlan;

  /// No description provided for @nutritionNutritionTemplateAssigned.
  ///
  /// In en, this message translates to:
  /// **'Nutrition template assigned'**
  String get nutritionNutritionTemplateAssigned;

  /// No description provided for @nutritionOpenScanner.
  ///
  /// In en, this message translates to:
  /// **'Open Scanner'**
  String get nutritionOpenScanner;

  /// No description provided for @nutritionPendingSync.
  ///
  /// In en, this message translates to:
  /// **'Pending sync'**
  String get nutritionPendingSync;

  /// No description provided for @nutritionPleaseLogInToSaveWeightData.
  ///
  /// In en, this message translates to:
  /// **'Please log in to save weight data.'**
  String get nutritionPleaseLogInToSaveWeightData;

  /// No description provided for @nutritionPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get nutritionPreviousDay;

  /// No description provided for @nutritionPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get nutritionPreviousWeek;

  /// No description provided for @nutritionProteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein, g'**
  String get nutritionProteinG;

  /// No description provided for @nutritionProteinG2.
  ///
  /// In en, this message translates to:
  /// **'Protein (g)'**
  String get nutritionProteinG2;

  /// No description provided for @nutritionRefreshGoals.
  ///
  /// In en, this message translates to:
  /// **'Refresh goals'**
  String get nutritionRefreshGoals;

  /// No description provided for @nutritionRequiredUsedToCalculateMacroTargets.
  ///
  /// In en, this message translates to:
  /// **'Required. Used to calculate macro targets.'**
  String get nutritionRequiredUsedToCalculateMacroTargets;

  /// No description provided for @nutritionSaveCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Save Check-In'**
  String get nutritionSaveCheckIn;

  /// No description provided for @nutritionSelectATemplate.
  ///
  /// In en, this message translates to:
  /// **'Select a template'**
  String get nutritionSelectATemplate;

  /// No description provided for @nutritionSelectMealNumber.
  ///
  /// In en, this message translates to:
  /// **'Select meal number'**
  String get nutritionSelectMealNumber;

  /// No description provided for @nutritionTemplate.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get nutritionTemplate;

  /// No description provided for @nutritionTotalFat.
  ///
  /// In en, this message translates to:
  /// **'Total Fat'**
  String get nutritionTotalFat;

  /// No description provided for @nutritionTraineeParameters.
  ///
  /// In en, this message translates to:
  /// **'Trainee Parameters'**
  String get nutritionTraineeParameters;

  /// No description provided for @nutritionTrainingBased.
  ///
  /// In en, this message translates to:
  /// **'Training-Based'**
  String get nutritionTrainingBased;

  /// No description provided for @nutritionViewWeek.
  ///
  /// In en, this message translates to:
  /// **'View Week'**
  String get nutritionViewWeek;

  /// No description provided for @nutritionWeeklyNutrition.
  ///
  /// In en, this message translates to:
  /// **'Weekly Nutrition'**
  String get nutritionWeeklyNutrition;

  /// No description provided for @nutritionWeeklyRotation.
  ///
  /// In en, this message translates to:
  /// **'Weekly Rotation'**
  String get nutritionWeeklyRotation;

  /// No description provided for @nutritionWeightCheckInSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Weight check-in saved successfully!'**
  String get nutritionWeightCheckInSavedSuccessfully;

  /// No description provided for @nutritionWeightTrends.
  ///
  /// In en, this message translates to:
  /// **'Weight Trends'**
  String get nutritionWeightTrends;

  /// No description provided for @onboardingCompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get onboardingCompleteSetup;

  /// No description provided for @onboardingEnterHeight.
  ///
  /// In en, this message translates to:
  /// **'Enter height'**
  String get onboardingEnterHeight;

  /// No description provided for @onboardingEnterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get onboardingEnterWeight;

  /// No description provided for @onboardingEnterYourAge.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get onboardingEnterYourAge;

  /// No description provided for @onboardingEnterYourFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get onboardingEnterYourFirstName;

  /// No description provided for @onboardingFeet.
  ///
  /// In en, this message translates to:
  /// **'Feet'**
  String get onboardingFeet;

  /// No description provided for @onboardingInches.
  ///
  /// In en, this message translates to:
  /// **'Inches'**
  String get onboardingInches;

  /// No description provided for @paymentsCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get paymentsCancelSubscription;

  /// No description provided for @paymentsEGWELCOME10.
  ///
  /// In en, this message translates to:
  /// **'e.g., WELCOME10'**
  String get paymentsEGWELCOME10;

  /// No description provided for @paymentsEGWelcomeDiscountForNewTrainees.
  ///
  /// In en, this message translates to:
  /// **'e.g., Welcome discount for new trainees'**
  String get paymentsEGWelcomeDiscountForNewTrainees;

  /// No description provided for @paymentsMonthlyCoaching.
  ///
  /// In en, this message translates to:
  /// **'Monthly Coaching'**
  String get paymentsMonthlyCoaching;

  /// No description provided for @paymentsMonthlySubscription.
  ///
  /// In en, this message translates to:
  /// **'Monthly Subscription'**
  String get paymentsMonthlySubscription;

  /// No description provided for @paymentsMyCoupons.
  ///
  /// In en, this message translates to:
  /// **'My Coupons'**
  String get paymentsMyCoupons;

  /// No description provided for @paymentsNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No Payments'**
  String get paymentsNoPayments;

  /// No description provided for @paymentsNoPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No Payments Yet'**
  String get paymentsNoPaymentsYet;

  /// No description provided for @paymentsNoSubscribersYet.
  ///
  /// In en, this message translates to:
  /// **'No Subscribers Yet'**
  String get paymentsNoSubscribersYet;

  /// No description provided for @paymentsNoSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No Subscriptions'**
  String get paymentsNoSubscriptions;

  /// No description provided for @paymentsOneTimeConsultation.
  ///
  /// In en, this message translates to:
  /// **'One-Time Consultation'**
  String get paymentsOneTimeConsultation;

  /// No description provided for @paymentsOpenStripeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open Stripe Dashboard'**
  String get paymentsOpenStripeDashboard;

  /// No description provided for @paymentsRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get paymentsRefreshStatus;

  /// No description provided for @paymentsSetYourPrices.
  ///
  /// In en, this message translates to:
  /// **'Set Your Prices'**
  String get paymentsSetYourPrices;

  /// No description provided for @photosAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get photosAddPhoto;

  /// No description provided for @photosAddProgressPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Progress Photo'**
  String get photosAddProgressPhoto;

  /// No description provided for @photosAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get photosAfter;

  /// No description provided for @photosAnyObservationsAboutYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Any observations about your progress...'**
  String get photosAnyObservationsAboutYourProgress;

  /// No description provided for @photosArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get photosArms;

  /// No description provided for @photosBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get photosBefore;

  /// No description provided for @photosChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get photosChest;

  /// No description provided for @photosChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get photosChooseFromGallery;

  /// No description provided for @photosComparePhotos.
  ///
  /// In en, this message translates to:
  /// **'Compare Photos'**
  String get photosComparePhotos;

  /// No description provided for @photosDeletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get photosDeletePhoto;

  /// No description provided for @photosFailedToLoadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Failed to load photos'**
  String get photosFailedToLoadPhotos;

  /// No description provided for @photosFailedToPickImagee.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: \$e'**
  String get photosFailedToPickImagee;

  /// No description provided for @photosFailedToUploadPhotoPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo. Please try again.'**
  String get photosFailedToUploadPhotoPleaseTryAgain;

  /// No description provided for @photosFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get photosFront;

  /// No description provided for @photosHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get photosHips;

  /// No description provided for @photosProgressPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress photo saved!'**
  String get photosProgressPhotoSaved;

  /// No description provided for @photosProgressPhotos.
  ///
  /// In en, this message translates to:
  /// **'Progress Photos'**
  String get photosProgressPhotos;

  /// No description provided for @photosSavePhoto.
  ///
  /// In en, this message translates to:
  /// **'Save Photo'**
  String get photosSavePhoto;

  /// No description provided for @photosSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get photosSide;

  /// No description provided for @photosTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get photosTakePhoto;

  /// No description provided for @photosThighs.
  ///
  /// In en, this message translates to:
  /// **'Thighs'**
  String get photosThighs;

  /// No description provided for @photosWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get photosWaist;

  /// No description provided for @programsAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get programsAddExercise;

  /// No description provided for @programsAddVolume.
  ///
  /// In en, this message translates to:
  /// **'Add Volume'**
  String get programsAddVolume;

  /// No description provided for @programsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get programsAdvanced;

  /// No description provided for @programsAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'All Weeks'**
  String get programsAllWeeks;

  /// No description provided for @programsAppliedProgressiveOverloadAcrossAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Applied progressive overload across all weeks'**
  String get programsAppliedProgressiveOverloadAcrossAllWeeks;

  /// No description provided for @programsApplyWithProgressiveOverload1RepWeek.
  ///
  /// In en, this message translates to:
  /// **'Apply with Progressive Overload (+1 rep/week)'**
  String get programsApplyWithProgressiveOverload1RepWeek;

  /// No description provided for @programsAreYouSureYouWantToRemoveAllExercisesFromThis.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all exercises from this day?'**
  String get programsAreYouSureYouWantToRemoveAllExercisesFromThis;

  /// No description provided for @programsAssignToTrainee.
  ///
  /// In en, this message translates to:
  /// **'Assign to Trainee'**
  String get programsAssignToTrainee;

  /// No description provided for @programsAutoCreateAFullProgramBasedOnSplitGoalDifficu.
  ///
  /// In en, this message translates to:
  /// **'Auto-create a full program based on split, goal & difficulty'**
  String get programsAutoCreateAFullProgramBasedOnSplitGoalDifficu;

  /// No description provided for @programsBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get programsBeginner;

  /// No description provided for @programsBroSplit.
  ///
  /// In en, this message translates to:
  /// **'Bro Split'**
  String get programsBroSplit;

  /// No description provided for @programsBuildACompletelyCustomProgramFromTheGroundUp.
  ///
  /// In en, this message translates to:
  /// **'Build a completely custom program from the ground up'**
  String get programsBuildACompletelyCustomProgramFromTheGroundUp;

  /// No description provided for @programsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get programsChange;

  /// No description provided for @programsClearAllExercises.
  ///
  /// In en, this message translates to:
  /// **'Clear All Exercises'**
  String get programsClearAllExercises;

  /// No description provided for @programsConvertToRestDay.
  ///
  /// In en, this message translates to:
  /// **'Convert to Rest Day'**
  String get programsConvertToRestDay;

  /// No description provided for @programsConvertToWorkoutDay.
  ///
  /// In en, this message translates to:
  /// **'Convert to Workout Day'**
  String get programsConvertToWorkoutDay;

  /// No description provided for @programsConvertedToRestDayForAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Converted to rest day for all weeks'**
  String get programsConvertedToRestDayForAllWeeks;

  /// No description provided for @programsConvertedToRestDayForThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Converted to rest day for this week'**
  String get programsConvertedToRestDayForThisWeek;

  /// No description provided for @programsConvertedToWorkoutDayForAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Converted to workout day for all weeks'**
  String get programsConvertedToWorkoutDayForAllWeeks;

  /// No description provided for @programsConvertedToWorkoutDayForThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Converted to workout day for this week'**
  String get programsConvertedToWorkoutDayForThisWeek;

  /// No description provided for @programsCopiedToAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Copied to all weeks'**
  String get programsCopiedToAllWeeks;

  /// No description provided for @programsCopyToAll.
  ///
  /// In en, this message translates to:
  /// **'Copy to All'**
  String get programsCopyToAll;

  /// No description provided for @programsCopyWeek.
  ///
  /// In en, this message translates to:
  /// **'Copy Week'**
  String get programsCopyWeek;

  /// No description provided for @programsCreateProgram.
  ///
  /// In en, this message translates to:
  /// **'Create Program'**
  String get programsCreateProgram;

  /// No description provided for @programsCreateSuperset.
  ///
  /// In en, this message translates to:
  /// **'Create Superset'**
  String get programsCreateSuperset;

  /// No description provided for @programsCustomSplit.
  ///
  /// In en, this message translates to:
  /// **'Custom Split'**
  String get programsCustomSplit;

  /// No description provided for @programsDayNameEGPushDay.
  ///
  /// In en, this message translates to:
  /// **'Day name (e.g. Push Day)'**
  String get programsDayNameEGPushDay;

  /// No description provided for @programsDecreaseDuration.
  ///
  /// In en, this message translates to:
  /// **'Decrease duration'**
  String get programsDecreaseDuration;

  /// No description provided for @programsDecreaseTrainingDays.
  ///
  /// In en, this message translates to:
  /// **'Decrease training days'**
  String get programsDecreaseTrainingDays;

  /// No description provided for @programsDeleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Delete Draft?'**
  String get programsDeleteDraft;

  /// No description provided for @programsDeleteWeek.
  ///
  /// In en, this message translates to:
  /// **'Delete Week'**
  String get programsDeleteWeek;

  /// No description provided for @programsDeleteWeek2.
  ///
  /// In en, this message translates to:
  /// **'Delete Week?'**
  String get programsDeleteWeek2;

  /// No description provided for @programsDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get programsDifficulty;

  /// No description provided for @programsDraftToMyPrograms.
  ///
  /// In en, this message translates to:
  /// **'Draft to My Programs'**
  String get programsDraftToMyPrograms;

  /// No description provided for @programsDurationdurationWeeksWeeks.
  ///
  /// In en, this message translates to:
  /// **'Duration: \$durationWeeks weeks'**
  String get programsDurationdurationWeeksWeeks;

  /// No description provided for @programsEGMyCustomPPL.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Custom PPL'**
  String get programsEGMyCustomPPL;

  /// No description provided for @programsEditProgramName.
  ///
  /// In en, this message translates to:
  /// **'Edit Program Name'**
  String get programsEditProgramName;

  /// No description provided for @programsEditWeek.
  ///
  /// In en, this message translates to:
  /// **'Edit Week'**
  String get programsEditWeek;

  /// No description provided for @programsEndurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get programsEndurance;

  /// No description provided for @programsErrorLoadingProgramserror.
  ///
  /// In en, this message translates to:
  /// **'Error loading programs: \$error'**
  String get programsErrorLoadingProgramserror;

  /// No description provided for @programsErrorLoadingTrainees.
  ///
  /// In en, this message translates to:
  /// **'Error loading trainees'**
  String get programsErrorLoadingTrainees;

  /// No description provided for @programsFullBody.
  ///
  /// In en, this message translates to:
  /// **'Full Body'**
  String get programsFullBody;

  /// No description provided for @programsGeneralFitness.
  ///
  /// In en, this message translates to:
  /// **'General Fitness'**
  String get programsGeneralFitness;

  /// No description provided for @programsGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get programsGenerate;

  /// No description provided for @programsGenerateProgram.
  ///
  /// In en, this message translates to:
  /// **'Generate Program'**
  String get programsGenerateProgram;

  /// No description provided for @programsGenerateWithAI.
  ///
  /// In en, this message translates to:
  /// **'Generate with AI'**
  String get programsGenerateWithAI;

  /// No description provided for @programsIncreaseDuration.
  ///
  /// In en, this message translates to:
  /// **'Increase duration'**
  String get programsIncreaseDuration;

  /// No description provided for @programsIncreaseTrainingDays.
  ///
  /// In en, this message translates to:
  /// **'Increase training days'**
  String get programsIncreaseTrainingDays;

  /// No description provided for @programsIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get programsIntermediate;

  /// No description provided for @programsLoadingExercises.
  ///
  /// In en, this message translates to:
  /// **'Loading exercises...'**
  String get programsLoadingExercises;

  /// No description provided for @programsMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get programsMoreOptions;

  /// No description provided for @programsOpenInBuilder.
  ///
  /// In en, this message translates to:
  /// **'Open in Builder'**
  String get programsOpenInBuilder;

  /// No description provided for @programsProgramDurationDurationWeeksWeeks.
  ///
  /// In en, this message translates to:
  /// **'Program duration: \$_durationWeeks weeks'**
  String get programsProgramDurationDurationWeeksWeeks;

  /// No description provided for @programsProgramName.
  ///
  /// In en, this message translates to:
  /// **'Program Name'**
  String get programsProgramName;

  /// No description provided for @programsProgramSavedAndAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Program saved and assigned successfully!'**
  String get programsProgramSavedAndAssignedSuccessfully;

  /// No description provided for @programsProgramTemplateSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Program template saved successfully!'**
  String get programsProgramTemplateSavedSuccessfully;

  /// No description provided for @programsProgramUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Program updated successfully!'**
  String get programsProgramUpdatedSuccessfully;

  /// No description provided for @programsPushPullLegs.
  ///
  /// In en, this message translates to:
  /// **'Push / Pull / Legs'**
  String get programsPushPullLegs;

  /// No description provided for @programsQuickPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Presets:'**
  String get programsQuickPresets;

  /// No description provided for @programsRecomp.
  ///
  /// In en, this message translates to:
  /// **'Recomp'**
  String get programsRecomp;

  /// No description provided for @programsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get programsRemove;

  /// No description provided for @programsRemoveExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get programsRemoveExercise;

  /// No description provided for @programsRemoveExercise2.
  ///
  /// In en, this message translates to:
  /// **'Remove Exercise'**
  String get programsRemoveExercise2;

  /// No description provided for @programsRemoveFromSuperset.
  ///
  /// In en, this message translates to:
  /// **'Remove from superset'**
  String get programsRemoveFromSuperset;

  /// No description provided for @programsRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get programsRename;

  /// No description provided for @programsRenameDay.
  ///
  /// In en, this message translates to:
  /// **'Rename Day'**
  String get programsRenameDay;

  /// No description provided for @programsRenameProgram.
  ///
  /// In en, this message translates to:
  /// **'Rename Program'**
  String get programsRenameProgram;

  /// No description provided for @programsRenamedTonewName.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"\$newName\"'**
  String get programsRenamedTonewName;

  /// No description provided for @programsReplaceActiveProgram.
  ///
  /// In en, this message translates to:
  /// **'Replace Active Program?'**
  String get programsReplaceActiveProgram;

  /// No description provided for @programsReplaceExercise.
  ///
  /// In en, this message translates to:
  /// **'Replace exercise'**
  String get programsReplaceExercise;

  /// No description provided for @programsReplaceProgram.
  ///
  /// In en, this message translates to:
  /// **'Replace Program'**
  String get programsReplaceProgram;

  /// No description provided for @programsReps.
  ///
  /// In en, this message translates to:
  /// **'Reps:'**
  String get programsReps;

  /// No description provided for @programsRest.
  ///
  /// In en, this message translates to:
  /// **'Rest:'**
  String get programsRest;

  /// No description provided for @programsSearchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises...'**
  String get programsSearchExercises;

  /// No description provided for @programsSelectAtLeast2ExercisesToCreateASuperset.
  ///
  /// In en, this message translates to:
  /// **'Select at least 2 exercises to create a superset'**
  String get programsSelectAtLeast2ExercisesToCreateASuperset;

  /// No description provided for @programsSets.
  ///
  /// In en, this message translates to:
  /// **'Sets:'**
  String get programsSets;

  /// No description provided for @programsStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get programsStartDate;

  /// No description provided for @programsStartFromScratch.
  ///
  /// In en, this message translates to:
  /// **'Start from Scratch'**
  String get programsStartFromScratch;

  /// No description provided for @programsStartWithAProvenProgramStructureAndCustomizeI.
  ///
  /// In en, this message translates to:
  /// **'Start with a proven program structure and customize it'**
  String get programsStartWithAProvenProgramStructureAndCustomizeI;

  /// No description provided for @programsStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get programsStrength;

  /// No description provided for @programsSuperset.
  ///
  /// In en, this message translates to:
  /// **'Superset'**
  String get programsSuperset;

  /// No description provided for @programsSupersetCreatedForAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Superset created for all weeks!'**
  String get programsSupersetCreatedForAllWeeks;

  /// No description provided for @programsSupersetCreatedForThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Superset created for this week!'**
  String get programsSupersetCreatedForThisWeek;

  /// No description provided for @programsThisWeekOnly.
  ///
  /// In en, this message translates to:
  /// **'This Week Only'**
  String get programsThisWeekOnly;

  /// No description provided for @programsTrainingDaysPerWeekTrainingDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Training days per week: \$_trainingDaysPerWeek'**
  String get programsTrainingDaysPerWeekTrainingDaysPerWeek;

  /// No description provided for @programsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get programsUpdate;

  /// No description provided for @programsUpdatedForAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Updated for all weeks'**
  String get programsUpdatedForAllWeeks;

  /// No description provided for @programsUpdatedForThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Updated for this week'**
  String get programsUpdatedForThisWeek;

  /// No description provided for @programsUpperLower.
  ///
  /// In en, this message translates to:
  /// **'Upper / Lower'**
  String get programsUpperLower;

  /// No description provided for @programsUseATemplate.
  ///
  /// In en, this message translates to:
  /// **'Use a Template'**
  String get programsUseATemplate;

  /// No description provided for @programsWeekDeleted.
  ///
  /// In en, this message translates to:
  /// **'Week deleted'**
  String get programsWeekDeleted;

  /// No description provided for @progressionAcceptDeload.
  ///
  /// In en, this message translates to:
  /// **'Accept Deload'**
  String get progressionAcceptDeload;

  /// No description provided for @progressionCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get progressionCheckAgain;

  /// No description provided for @progressionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get progressionCurrent;

  /// No description provided for @progressionDeloadAppliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deload applied successfully'**
  String get progressionDeloadAppliedSuccessfully;

  /// No description provided for @progressionDeloadDetection.
  ///
  /// In en, this message translates to:
  /// **'Deload Detection'**
  String get progressionDeloadDetection;

  /// No description provided for @progressionDeloadRecommendationDismissed.
  ///
  /// In en, this message translates to:
  /// **'Deload recommendation dismissed'**
  String get progressionDeloadRecommendationDismissed;

  /// No description provided for @progressionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get progressionDismiss;

  /// No description provided for @progressionIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get progressionIntensity;

  /// No description provided for @progressionSmartProgression.
  ///
  /// In en, this message translates to:
  /// **'Smart Progression'**
  String get progressionSmartProgression;

  /// No description provided for @progressionSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get progressionSuggested;

  /// No description provided for @progressionSuggestionDismissed.
  ///
  /// In en, this message translates to:
  /// **'Suggestion dismissed'**
  String get progressionSuggestionDismissed;

  /// No description provided for @progressionVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get progressionVolume;

  /// No description provided for @quickLogDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get quickLogDuration;

  /// No description provided for @quickLogDurationMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Duration must be greater than zero'**
  String get quickLogDurationMustBeGreaterThanZero;

  /// No description provided for @quickLogNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get quickLogNotesOptional;

  /// No description provided for @quickLogPleaseSelectAWorkoutTemplate.
  ///
  /// In en, this message translates to:
  /// **'Please select a workout template'**
  String get quickLogPleaseSelectAWorkoutTemplate;

  /// No description provided for @quickLogQuickLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Quick log saved!'**
  String get quickLogQuickLogSaved;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsAccent;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get settingsActiveSessions;

  /// No description provided for @settingsAlwaysUseDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Always use dark mode'**
  String get settingsAlwaysUseDarkMode;

  /// No description provided for @settingsAlwaysUseLightMode.
  ///
  /// In en, this message translates to:
  /// **'Always use light mode'**
  String get settingsAlwaysUseLightMode;

  /// No description provided for @settingsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get settingsAnalytics;

  /// No description provided for @settingsAnnouncementsFromYourTrainer.
  ///
  /// In en, this message translates to:
  /// **'Announcements from your trainer'**
  String get settingsAnnouncementsFromYourTrainer;

  /// No description provided for @settingsAppleWatch.
  ///
  /// In en, this message translates to:
  /// **'Apple Watch'**
  String get settingsAppleWatch;

  /// No description provided for @settingsAreYouSureYouWantToRemoveYourLogo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove your logo?'**
  String get settingsAreYouSureYouWantToRemoveYourLogo;

  /// No description provided for @settingsAreYouSureYouWantToRemoveYourProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove your profile picture?'**
  String get settingsAreYouSureYouWantToRemoveYourProfilePicture;

  /// No description provided for @settingsBadgesAchievements.
  ///
  /// In en, this message translates to:
  /// **'Badges & Achievements'**
  String get settingsBadgesAchievements;

  /// No description provided for @settingsBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get settingsBilling;

  /// No description provided for @settingsBodyMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Body Measurements'**
  String get settingsBodyMeasurements;

  /// No description provided for @settingsBrandingUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Branding updated successfully'**
  String get settingsBrandingUpdatedSuccessfully;

  /// No description provided for @settingsBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get settingsBusinessName;

  /// No description provided for @settingsButtonsHeadersAccentElements.
  ///
  /// In en, this message translates to:
  /// **'Buttons, headers, accent elements'**
  String get settingsButtonsHeadersAccentElements;

  /// No description provided for @settingsChangeYourActivityLevelAndGoals.
  ///
  /// In en, this message translates to:
  /// **'Change your activity level and goals'**
  String get settingsChangeYourActivityLevelAndGoals;

  /// No description provided for @settingsChangelabelTovalue.
  ///
  /// In en, this message translates to:
  /// **'Change \$label to \$value'**
  String get settingsChangelabelTovalue;

  /// No description provided for @settingsCheckInDays.
  ///
  /// In en, this message translates to:
  /// **'Check-in Days'**
  String get settingsCheckInDays;

  /// No description provided for @settingsChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get settingsChooseImage;

  /// No description provided for @settingsChurnAlert.
  ///
  /// In en, this message translates to:
  /// **'Churn Alert'**
  String get settingsChurnAlert;

  /// No description provided for @settingsCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get settingsCommunication;

  /// No description provided for @settingsCommunityActivity.
  ///
  /// In en, this message translates to:
  /// **'Community Activity'**
  String get settingsCommunityActivity;

  /// No description provided for @settingsCommunityEvents.
  ///
  /// In en, this message translates to:
  /// **'Community Events'**
  String get settingsCommunityEvents;

  /// No description provided for @settingsConfigureCoachingSubscriptionPricing.
  ///
  /// In en, this message translates to:
  /// **'Configure coaching subscription pricing'**
  String get settingsConfigureCoachingSubscriptionPricing;

  /// No description provided for @settingsConfigureSystemNotifications.
  ///
  /// In en, this message translates to:
  /// **'Configure system notifications'**
  String get settingsConfigureSystemNotifications;

  /// No description provided for @settingsConfigureWorkoutAndMealReminders.
  ///
  /// In en, this message translates to:
  /// **'Configure workout and meal reminders'**
  String get settingsConfigureWorkoutAndMealReminders;

  /// No description provided for @settingsConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get settingsConfirmNewPassword;

  /// No description provided for @settingsConfirmationEmailsForPayments.
  ///
  /// In en, this message translates to:
  /// **'Confirmation emails for payments'**
  String get settingsConfirmationEmailsForPayments;

  /// No description provided for @settingsConnectGoogleOrMicrosoftCalendar.
  ///
  /// In en, this message translates to:
  /// **'Connect Google or Microsoft calendar'**
  String get settingsConnectGoogleOrMicrosoftCalendar;

  /// No description provided for @settingsConnectStripeToReceivePayments.
  ///
  /// In en, this message translates to:
  /// **'Connect Stripe to receive payments'**
  String get settingsConnectStripeToReceivePayments;

  /// No description provided for @settingsContactSupportViaEmailAtSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact support via email at \$_supportEmail'**
  String get settingsContactSupportViaEmailAtSupportEmail;

  /// No description provided for @settingsCouldNotOpenEmailAppEmailCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app. Email copied to clipboard.'**
  String get settingsCouldNotOpenEmailAppEmailCopiedToClipboard;

  /// No description provided for @settingsCreateDiscountsForYourTrainees.
  ///
  /// In en, this message translates to:
  /// **'Create discounts for your trainees'**
  String get settingsCreateDiscountsForYourTrainees;

  /// No description provided for @settingsCurrentLogo.
  ///
  /// In en, this message translates to:
  /// **'Current logo'**
  String get settingsCurrentLogo;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsCurrentSession.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get settingsCurrentSession;

  /// No description provided for @settingsCustomizeYourAppColorsLogoAndName.
  ///
  /// In en, this message translates to:
  /// **'Customize your app colors, logo, and name'**
  String get settingsCustomizeYourAppColorsLogoAndName;

  /// No description provided for @settingsDailyOverviewOfPlatformActivity.
  ///
  /// In en, this message translates to:
  /// **'Daily overview of platform activity'**
  String get settingsDailyOverviewOfPlatformActivity;

  /// No description provided for @settingsDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get settingsDailySummary;

  /// No description provided for @settingsDeleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get settingsDeleteMyAccount;

  /// No description provided for @settingsDietPreferencesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Diet preferences updated!'**
  String get settingsDietPreferencesUpdated;

  /// No description provided for @settingsEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get settingsEditName;

  /// No description provided for @settingsEditNameBusiness.
  ///
  /// In en, this message translates to:
  /// **'Edit Name & Business'**
  String get settingsEditNameBusiness;

  /// No description provided for @settingsEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get settingsEmailNotifications;

  /// No description provided for @settingsEnterYourBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get settingsEnterYourBusinessName;

  /// No description provided for @settingsEnterYourLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get settingsEnterYourLastName;

  /// No description provided for @settingsError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get settingsError;

  /// No description provided for @settingsFailedToSaveReminderSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to save reminder settings.'**
  String get settingsFailedToSaveReminderSettings;

  /// No description provided for @settingsFailedToUpdatePreferencePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to update preference. Please try again.'**
  String get settingsFailedToUpdatePreferencePleaseTryAgain;

  /// No description provided for @settingsFitnessGoals.
  ///
  /// In en, this message translates to:
  /// **'Fitness Goals'**
  String get settingsFitnessGoals;

  /// No description provided for @settingsGentleNudgesWhenYouHaveNotLoggedInAWhile.
  ///
  /// In en, this message translates to:
  /// **'Gentle nudges when you have not logged in a while'**
  String get settingsGentleNudgesWhenYouHaveNotLoggedInAWhile;

  /// No description provided for @settingsGetADailyReminderToCompleteYourWorkout.
  ///
  /// In en, this message translates to:
  /// **'Get a daily reminder to complete your workout'**
  String get settingsGetADailyReminderToCompleteYourWorkout;

  /// No description provided for @settingsGetADailyReminderToLogYourMeals.
  ///
  /// In en, this message translates to:
  /// **'Get a daily reminder to log your meals'**
  String get settingsGetADailyReminderToLogYourMeals;

  /// No description provided for @settingsGetAWeeklyReminderToLogYourWeight.
  ///
  /// In en, this message translates to:
  /// **'Get a weekly reminder to log your weight'**
  String get settingsGetAWeeklyReminderToLogYourWeight;

  /// No description provided for @settingsGetHelpWithUsingThePlatform.
  ///
  /// In en, this message translates to:
  /// **'Get help with using the platform'**
  String get settingsGetHelpWithUsingThePlatform;

  /// No description provided for @settingsGettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get settingsGettingStarted;

  /// No description provided for @settingsGoalsUpdatedMacrosRecalculated.
  ///
  /// In en, this message translates to:
  /// **'Goals updated! Macros recalculated.'**
  String get settingsGoalsUpdatedMacrosRecalculated;

  /// No description provided for @settingsHeightWeight.
  ///
  /// In en, this message translates to:
  /// **'Height & Weight'**
  String get settingsHeightWeight;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsHexColor.
  ///
  /// In en, this message translates to:
  /// **'Hex Color'**
  String get settingsHexColor;

  /// No description provided for @settingsHighlightsBadgesSecondaryActions.
  ///
  /// In en, this message translates to:
  /// **'Highlights, badges, secondary actions'**
  String get settingsHighlightsBadgesSecondaryActions;

  /// No description provided for @settingsLogOutFromAllOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Log out from all other devices'**
  String get settingsLogOutFromAllOtherDevices;

  /// No description provided for @settingsLoginAttemptsAndSecurityEvents.
  ///
  /// In en, this message translates to:
  /// **'Login attempts and security events'**
  String get settingsLoginAttemptsAndSecurityEvents;

  /// No description provided for @settingsLogoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Logo removed'**
  String get settingsLogoRemoved;

  /// No description provided for @settingsLogoUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logo uploaded successfully'**
  String get settingsLogoUploadedSuccessfully;

  /// No description provided for @settingsManageCoachingSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Manage coaching subscriptions'**
  String get settingsManageCoachingSubscriptions;

  /// No description provided for @settingsManageDevicesLoggedIntoYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage devices logged into your account'**
  String get settingsManageDevicesLoggedIntoYourAccount;

  /// No description provided for @settingsManageNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get settingsManageNotificationPreferences;

  /// No description provided for @settingsManageYourSubscriptionPlan.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription plan'**
  String get settingsManageYourSubscriptionPlan;

  /// No description provided for @settingsMatchDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Match device settings'**
  String get settingsMatchDeviceSettings;

  /// No description provided for @settingsMealLoggingReminder.
  ///
  /// In en, this message translates to:
  /// **'Meal Logging Reminder'**
  String get settingsMealLoggingReminder;

  /// No description provided for @settingsMySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My Subscriptions'**
  String get settingsMySubscriptions;

  /// No description provided for @settingsNewEventsUpdatesCancellationsAndReminders.
  ///
  /// In en, this message translates to:
  /// **'New events, updates, cancellations, and reminders'**
  String get settingsNewEventsUpdatesCancellationsAndReminders;

  /// No description provided for @settingsNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get settingsNewMessage;

  /// No description provided for @settingsNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get settingsNewPassword;

  /// No description provided for @settingsNewTrainerSignups.
  ///
  /// In en, this message translates to:
  /// **'New Trainer Signups'**
  String get settingsNewTrainerSignups;

  /// No description provided for @settingsNotificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get settingsNotificationPreferences;

  /// No description provided for @settingsNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get settingsNotificationsDisabled;

  /// No description provided for @settingsNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get settingsNutrition;

  /// No description provided for @settingsOpenNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get settingsOpenNotificationSettings;

  /// No description provided for @settingsPassword2FAAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Password, 2FA, and sessions'**
  String get settingsPassword2FAAndSessions;

  /// No description provided for @settingsPasswordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get settingsPasswordChangedSuccessfully;

  /// No description provided for @settingsPastDueAlerts.
  ///
  /// In en, this message translates to:
  /// **'Past Due Alerts'**
  String get settingsPastDueAlerts;

  /// No description provided for @settingsPaymentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Payment Alerts'**
  String get settingsPaymentAlerts;

  /// No description provided for @settingsPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get settingsPaymentHistory;

  /// No description provided for @settingsPaymentReceipts.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipts'**
  String get settingsPaymentReceipts;

  /// No description provided for @settingsPaymentSetup.
  ///
  /// In en, this message translates to:
  /// **'Payment Setup'**
  String get settingsPaymentSetup;

  /// No description provided for @settingsPermanentlyDeleteYourAccountAndAllData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get settingsPermanentlyDeleteYourAccountAndAllData;

  /// No description provided for @settingsPostsAndReactionsInTheCommunityFeed.
  ///
  /// In en, this message translates to:
  /// **'Posts and reactions in the community feed'**
  String get settingsPostsAndReactionsInTheCommunityFeed;

  /// No description provided for @settingsPreviewOfHowYourTraineesWillSeedisplayName.
  ///
  /// In en, this message translates to:
  /// **'Preview of how your trainees will see: \$displayName'**
  String get settingsPreviewOfHowYourTraineesWillSeedisplayName;

  /// No description provided for @settingsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get settingsPrimary;

  /// No description provided for @settingsPrimaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get settingsPrimaryColor;

  /// No description provided for @settingsPrimaryLight.
  ///
  /// In en, this message translates to:
  /// **'Primary Light'**
  String get settingsPrimaryLight;

  /// No description provided for @settingsProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get settingsProfileUpdated;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsReEngagementReminders.
  ///
  /// In en, this message translates to:
  /// **'Re-engagement Reminders'**
  String get settingsReEngagementReminders;

  /// No description provided for @settingsReceiveNotificationsViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications via email'**
  String get settingsReceiveNotificationsViaEmail;

  /// No description provided for @settingsReceivePushNotificationsOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on this device'**
  String get settingsReceivePushNotificationsOnThisDevice;

  /// No description provided for @settingsRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get settingsRegenerate;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// No description provided for @settingsRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get settingsRemoveLogo;

  /// No description provided for @settingsRemoveLogoImage.
  ///
  /// In en, this message translates to:
  /// **'Remove logo image'**
  String get settingsRemoveLogoImage;

  /// No description provided for @settingsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get settingsRemovePhoto;

  /// No description provided for @settingsRemoveProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Remove Profile Picture'**
  String get settingsRemoveProfilePicture;

  /// No description provided for @settingsReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get settingsReplace;

  /// No description provided for @settingsReplaceLogoImage.
  ///
  /// In en, this message translates to:
  /// **'Replace logo image'**
  String get settingsReplaceLogoImage;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsResetBranding.
  ///
  /// In en, this message translates to:
  /// **'Reset Branding'**
  String get settingsResetBranding;

  /// No description provided for @settingsResetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get settingsResetToDefault;

  /// No description provided for @settingsResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetToDefaults;

  /// No description provided for @settingsResetToDefaults2.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults?'**
  String get settingsResetToDefaults2;

  /// No description provided for @settingsSaveBranding.
  ///
  /// In en, this message translates to:
  /// **'Save Branding'**
  String get settingsSaveBranding;

  /// No description provided for @settingsSaveBrandingChanges.
  ///
  /// In en, this message translates to:
  /// **'Save branding changes'**
  String get settingsSaveBrandingChanges;

  /// No description provided for @settingsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get settingsSchedule;

  /// No description provided for @settingsSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get settingsSecondary;

  /// No description provided for @settingsSecondaryColor.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get settingsSecondaryColor;

  /// No description provided for @settingsSecurityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Security Alerts'**
  String get settingsSecurityAlerts;

  /// No description provided for @settingsSetYourWeighInSchedule.
  ///
  /// In en, this message translates to:
  /// **'Set your weigh-in schedule'**
  String get settingsSetYourWeighInSchedule;

  /// No description provided for @settingsSignOutAll.
  ///
  /// In en, this message translates to:
  /// **'Sign Out All'**
  String get settingsSignOutAll;

  /// No description provided for @settingsSignOutAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Sign Out All Devices'**
  String get settingsSignOutAllDevices;

  /// No description provided for @settingsSignOutOfAdminAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of admin account'**
  String get settingsSignOutOfAdminAccount;

  /// No description provided for @settingsSignOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settingsSignOutOfYourAccount;

  /// No description provided for @settingsSignedOutFromAllOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Signed out from all other devices'**
  String get settingsSignedOutFromAllOtherDevices;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsSubscriptionChanges.
  ///
  /// In en, this message translates to:
  /// **'Subscription Changes'**
  String get settingsSubscriptionChanges;

  /// No description provided for @settingsSuccessfulAndFailedPayments.
  ///
  /// In en, this message translates to:
  /// **'Successful and failed payments'**
  String get settingsSuccessfulAndFailedPayments;

  /// No description provided for @settingsSuggestNewFeaturesOrVoteOnIdeas.
  ///
  /// In en, this message translates to:
  /// **'Suggest new features or vote on ideas'**
  String get settingsSuggestNewFeaturesOrVoteOnIdeas;

  /// No description provided for @settingsSyncWorkoutsAndHealthDataWithYourWatch.
  ///
  /// In en, this message translates to:
  /// **'Sync workouts and health data with your watch'**
  String get settingsSyncWorkoutsAndHealthDataWithYourWatch;

  /// No description provided for @settingsThemeColorsAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'Theme, colors, and display'**
  String get settingsThemeColorsAndDisplay;

  /// No description provided for @settingsThisWillResetAllColorCustomizationsBackToTheD.
  ///
  /// In en, this message translates to:
  /// **'This will reset all color customizations back to the default Indigo theme.'**
  String get settingsThisWillResetAllColorCustomizationsBackToTheD;

  /// No description provided for @settingsTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get settingsTime;

  /// No description provided for @settingsTrackYourVisualTransformationOverTime.
  ///
  /// In en, this message translates to:
  /// **'Track your visual transformation over time'**
  String get settingsTrackYourVisualTransformationOverTime;

  /// No description provided for @settingsTraineeActivity.
  ///
  /// In en, this message translates to:
  /// **'Trainee Activity'**
  String get settingsTraineeActivity;

  /// No description provided for @settingsTrainerAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Trainer Announcements'**
  String get settingsTrainerAnnouncements;

  /// No description provided for @settingsUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get settingsUnsavedChanges;

  /// No description provided for @settingsUpdateAgeHeightAndWeight.
  ///
  /// In en, this message translates to:
  /// **'Update age, height, and weight'**
  String get settingsUpdateAgeHeightAndWeight;

  /// No description provided for @settingsUpdateDietTypeAndMealSettings.
  ///
  /// In en, this message translates to:
  /// **'Update diet type and meal settings'**
  String get settingsUpdateDietTypeAndMealSettings;

  /// No description provided for @settingsUpdateYourAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsUpdateYourAccountPassword;

  /// No description provided for @settingsUpdateYourName.
  ///
  /// In en, this message translates to:
  /// **'Update your name'**
  String get settingsUpdateYourName;

  /// No description provided for @settingsUpdateYourNameAndBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Update your name and business name'**
  String get settingsUpdateYourNameAndBusinessName;

  /// No description provided for @settingsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settingsUpdates;

  /// No description provided for @settingsUpgradesDowngradesAndCancellations.
  ///
  /// In en, this message translates to:
  /// **'Upgrades, downgrades, and cancellations'**
  String get settingsUpgradesDowngradesAndCancellations;

  /// No description provided for @settingsUploadALogoImage.
  ///
  /// In en, this message translates to:
  /// **'Upload a logo image'**
  String get settingsUploadALogoImage;

  /// No description provided for @settingsViewReceivedPaymentsAndSubscribers.
  ///
  /// In en, this message translates to:
  /// **'View received payments and subscribers'**
  String get settingsViewReceivedPaymentsAndSubscribers;

  /// No description provided for @settingsViewTraineeProgressAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View trainee progress analytics'**
  String get settingsViewTraineeProgressAnalytics;

  /// No description provided for @settingsViewYourEarnedBadges.
  ///
  /// In en, this message translates to:
  /// **'View your earned badges'**
  String get settingsViewYourEarnedBadges;

  /// No description provided for @settingsWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get settingsWarning;

  /// No description provided for @settingsWeeklyReportWithKeyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Weekly report with key metrics'**
  String get settingsWeeklyReportWithKeyMetrics;

  /// No description provided for @settingsWeeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get settingsWeeklySummary;

  /// No description provided for @settingsWeightCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Weight Check-in'**
  String get settingsWeightCheckIn;

  /// No description provided for @settingsWeightCheckInReminder.
  ///
  /// In en, this message translates to:
  /// **'Weight Check-in Reminder'**
  String get settingsWeightCheckInReminder;

  /// No description provided for @settingsWhenANewTrainerCreatesAnAccount.
  ///
  /// In en, this message translates to:
  /// **'When a new trainer creates an account'**
  String get settingsWhenANewTrainerCreatesAnAccount;

  /// No description provided for @settingsWhenATraineeFinishesAWorkoutSession.
  ///
  /// In en, this message translates to:
  /// **'When a trainee finishes a workout session'**
  String get settingsWhenATraineeFinishesAWorkoutSession;

  /// No description provided for @settingsWhenATraineeIsAtRiskOfChurning.
  ///
  /// In en, this message translates to:
  /// **'When a trainee is at risk of churning'**
  String get settingsWhenATraineeIsAtRiskOfChurning;

  /// No description provided for @settingsWhenATraineeLogsAWorkout.
  ///
  /// In en, this message translates to:
  /// **'When a trainee logs a workout'**
  String get settingsWhenATraineeLogsAWorkout;

  /// No description provided for @settingsWhenATraineeRecordsTheirWeight.
  ///
  /// In en, this message translates to:
  /// **'When a trainee records their weight'**
  String get settingsWhenATraineeRecordsTheirWeight;

  /// No description provided for @settingsWhenATraineeStartsAWorkoutSession.
  ///
  /// In en, this message translates to:
  /// **'When a trainee starts a workout session'**
  String get settingsWhenATraineeStartsAWorkoutSession;

  /// No description provided for @settingsWhenAccountsBecomePastDue.
  ///
  /// In en, this message translates to:
  /// **'When accounts become past due'**
  String get settingsWhenAccountsBecomePastDue;

  /// No description provided for @settingsWhenYouEarnANewAchievement.
  ///
  /// In en, this message translates to:
  /// **'When you earn a new achievement'**
  String get settingsWhenYouEarnANewAchievement;

  /// No description provided for @settingsWhenYouReceiveANewMessage.
  ///
  /// In en, this message translates to:
  /// **'When you receive a new message'**
  String get settingsWhenYouReceiveANewMessage;

  /// No description provided for @settingsWorkoutFinished.
  ///
  /// In en, this message translates to:
  /// **'Workout Finished'**
  String get settingsWorkoutFinished;

  /// No description provided for @settingsWorkoutLogged.
  ///
  /// In en, this message translates to:
  /// **'Workout Logged'**
  String get settingsWorkoutLogged;

  /// No description provided for @settingsWorkoutReminder.
  ///
  /// In en, this message translates to:
  /// **'Workout Reminder'**
  String get settingsWorkoutReminder;

  /// No description provided for @settingsWorkoutStarted.
  ///
  /// In en, this message translates to:
  /// **'Workout Started'**
  String get settingsWorkoutStarted;

  /// No description provided for @settingsYouHaveUnsavedBrandingChangesDiscardThem.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved branding changes. Discard them?'**
  String get settingsYouHaveUnsavedBrandingChangesDiscardThem;

  /// No description provided for @settingsYourTraineesWillSeeThisNameInsteadOfFitnessAI.
  ///
  /// In en, this message translates to:
  /// **'Your trainees will see this name instead of \"FitnessAI\"'**
  String get settingsYourTraineesWillSeeThisNameInsteadOfFitnessAI;

  /// No description provided for @sharingFailedToCaptureWorkoutCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture workout card'**
  String get sharingFailedToCaptureWorkoutCard;

  /// No description provided for @sharingSaveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to Gallery'**
  String get sharingSaveToGallery;

  /// No description provided for @sharingShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sharingShare;

  /// No description provided for @sharingShareWorkout.
  ///
  /// In en, this message translates to:
  /// **'Share Workout'**
  String get sharingShareWorkout;

  /// No description provided for @trainerActiveToday.
  ///
  /// In en, this message translates to:
  /// **'Active Today'**
  String get trainerActiveToday;

  /// No description provided for @trainerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get trainerAdd;

  /// No description provided for @trainerAddAPersonalMessageToYourInvitation.
  ///
  /// In en, this message translates to:
  /// **'Add a personal message to your invitation...'**
  String get trainerAddAPersonalMessageToYourInvitation;

  /// No description provided for @trainerAddNewPreset.
  ///
  /// In en, this message translates to:
  /// **'Add New Preset'**
  String get trainerAddNewPreset;

  /// No description provided for @trainerAdherence.
  ///
  /// In en, this message translates to:
  /// **'Adherence'**
  String get trainerAdherence;

  /// No description provided for @trainerAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Announcement title'**
  String get trainerAnnouncementTitle;

  /// No description provided for @trainerAreYouSureYouWantToDeleteThisAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this announcement?'**
  String get trainerAreYouSureYouWantToDeleteThisAnnouncement;

  /// No description provided for @trainerAskAIAboutThisTrainee.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about this trainee'**
  String get trainerAskAIAboutThisTrainee;

  /// No description provided for @trainerAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get trainerAssign;

  /// No description provided for @trainerAssignADifferentProgram.
  ///
  /// In en, this message translates to:
  /// **'Assign a different program'**
  String get trainerAssignADifferentProgram;

  /// No description provided for @trainerAssignAProgramToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Assign a program to get started'**
  String get trainerAssignAProgramToGetStarted;

  /// No description provided for @trainerAssignExistingProgram.
  ///
  /// In en, this message translates to:
  /// **'Assign Existing Program'**
  String get trainerAssignExistingProgram;

  /// No description provided for @trainerAssignNutritionTemplateToTrainee.
  ///
  /// In en, this message translates to:
  /// **'Assign nutrition template to trainee'**
  String get trainerAssignNutritionTemplateToTrainee;

  /// No description provided for @trainerAssignProgram.
  ///
  /// In en, this message translates to:
  /// **'Assign Program'**
  String get trainerAssignProgram;

  /// No description provided for @trainerAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At-Risk'**
  String get trainerAtRisk;

  /// No description provided for @trainerAvgDailyIntake.
  ///
  /// In en, this message translates to:
  /// **'Avg Daily Intake'**
  String get trainerAvgDailyIntake;

  /// No description provided for @trainerAvgEngagement.
  ///
  /// In en, this message translates to:
  /// **'Avg Engagement'**
  String get trainerAvgEngagement;

  /// No description provided for @trainerAvgRate.
  ///
  /// In en, this message translates to:
  /// **'avg rate'**
  String get trainerAvgRate;

  /// No description provided for @trainerBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get trainerBody;

  /// No description provided for @trainerBuildACustomProgramFromScratch.
  ///
  /// In en, this message translates to:
  /// **'Build a custom program from scratch'**
  String get trainerBuildACustomProgramFromScratch;

  /// No description provided for @trainerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get trainerCalendar;

  /// No description provided for @trainerCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation?'**
  String get trainerCancelInvitation;

  /// No description provided for @trainerCancelInvitation2.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get trainerCancelInvitation2;

  /// No description provided for @trainerCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get trainerCard;

  /// No description provided for @trainerChangeProgram.
  ///
  /// In en, this message translates to:
  /// **'Change Program'**
  String get trainerChangeProgram;

  /// No description provided for @trainerClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get trainerClassic;

  /// No description provided for @trainerClientexampleCom.
  ///
  /// In en, this message translates to:
  /// **'client@example.com'**
  String get trainerClientexampleCom;

  /// No description provided for @trainerCopyAProgramFromAnotherTrainee.
  ///
  /// In en, this message translates to:
  /// **'Copy a program from another trainee'**
  String get trainerCopyAProgramFromAnotherTrainee;

  /// No description provided for @trainerCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get trainerCopyLink;

  /// No description provided for @trainerCouldNotLoadPrograms.
  ///
  /// In en, this message translates to:
  /// **'Could not load programs'**
  String get trainerCouldNotLoadPrograms;

  /// No description provided for @trainerCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get trainerCreateNew;

  /// No description provided for @trainerCreateNewProgram.
  ///
  /// In en, this message translates to:
  /// **'Create New Program'**
  String get trainerCreateNewProgram;

  /// No description provided for @trainerCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get trainerCritical;

  /// No description provided for @trainerDayName.
  ///
  /// In en, this message translates to:
  /// **'Day Name'**
  String get trainerDayName;

  /// No description provided for @trainerDeleteAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Delete Announcement'**
  String get trainerDeleteAnnouncement;

  /// No description provided for @trainerDeletePreset.
  ///
  /// In en, this message translates to:
  /// **'Delete Preset?'**
  String get trainerDeletePreset;

  /// No description provided for @trainerEGPushDayCircuitA.
  ///
  /// In en, this message translates to:
  /// **'e.g., Push Day, Circuit A'**
  String get trainerEGPushDayCircuitA;

  /// No description provided for @trainerEGStrengthBuildingPhase1.
  ///
  /// In en, this message translates to:
  /// **'e.g., Strength Building Phase 1'**
  String get trainerEGStrengthBuildingPhase1;

  /// No description provided for @trainerEGTrainingDayRestDay.
  ///
  /// In en, this message translates to:
  /// **'e.g., Training Day, Rest Day'**
  String get trainerEGTrainingDayRestDay;

  /// No description provided for @trainerEditGoals.
  ///
  /// In en, this message translates to:
  /// **'Edit Goals'**
  String get trainerEditGoals;

  /// No description provided for @trainerEditProgram.
  ///
  /// In en, this message translates to:
  /// **'Edit Program'**
  String get trainerEditProgram;

  /// No description provided for @trainerEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get trainerEmailAddress;

  /// No description provided for @trainerEndProgram.
  ///
  /// In en, this message translates to:
  /// **'End Program'**
  String get trainerEndProgram;

  /// No description provided for @trainerErrorLoadingPresets.
  ///
  /// In en, this message translates to:
  /// **'Error loading presets'**
  String get trainerErrorLoadingPresets;

  /// No description provided for @trainerFailedToDeleteAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete announcement'**
  String get trainerFailedToDeleteAnnouncement;

  /// No description provided for @trainerFailedToDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete notification'**
  String get trainerFailedToDeleteNotification;

  /// No description provided for @trainerFailedToSavee.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: \$e'**
  String get trainerFailedToSavee;

  /// No description provided for @trainerFrequencyOptional.
  ///
  /// In en, this message translates to:
  /// **'Frequency (optional)'**
  String get trainerFrequencyOptional;

  /// No description provided for @trainerGoToTraineeHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Trainee Home'**
  String get trainerGoToTraineeHome;

  /// No description provided for @trainerGoalsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Goals updated successfully'**
  String get trainerGoalsUpdatedSuccessfully;

  /// No description provided for @trainerHittingGoals.
  ///
  /// In en, this message translates to:
  /// **'hitting goals'**
  String get trainerHittingGoals;

  /// No description provided for @trainerImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get trainerImport;

  /// No description provided for @trainerInvitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled'**
  String get trainerInvitationCancelled;

  /// No description provided for @trainerInvitationResent.
  ///
  /// In en, this message translates to:
  /// **'Invitation resent'**
  String get trainerInvitationResent;

  /// No description provided for @trainerInvitationResentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation resent successfully'**
  String get trainerInvitationResentSuccessfully;

  /// No description provided for @trainerInvitationSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully!'**
  String get trainerInvitationSentSuccessfully;

  /// No description provided for @trainerInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get trainerInvite;

  /// No description provided for @trainerInviteLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied to clipboard'**
  String get trainerInviteLinkCopiedToClipboard;

  /// No description provided for @trainerKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get trainerKcal;

  /// No description provided for @trainerLayoutUpdatedTolabel.
  ///
  /// In en, this message translates to:
  /// **'Layout updated to \$label'**
  String get trainerLayoutUpdatedTolabel;

  /// No description provided for @trainerLoadingNutritionTemplateAssignment.
  ///
  /// In en, this message translates to:
  /// **'Loading nutrition template assignment'**
  String get trainerLoadingNutritionTemplateAssignment;

  /// No description provided for @trainerLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get trainerLogged;

  /// No description provided for @trainerLoggedActivity.
  ///
  /// In en, this message translates to:
  /// **'logged activity'**
  String get trainerLoggedActivity;

  /// No description provided for @trainerMarkAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get trainerMarkAllAsRead;

  /// No description provided for @trainerMarkAllNotificationsAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all notifications as read'**
  String get trainerMarkAllNotificationsAsRead;

  /// No description provided for @trainerMarkAllNotificationsAsRead2.
  ///
  /// In en, this message translates to:
  /// **'Mark all notifications as read?'**
  String get trainerMarkAllNotificationsAsRead2;

  /// No description provided for @trainerMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get trainerMarkAllRead;

  /// No description provided for @trainerMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get trainerMessage;

  /// No description provided for @trainerMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get trainerMinimal;

  /// No description provided for @trainerModifyExercisesSetsAndReps.
  ///
  /// In en, this message translates to:
  /// **'Modify exercises, sets, and reps'**
  String get trainerModifyExercisesSetsAndReps;

  /// No description provided for @trainerMyTrainees.
  ///
  /// In en, this message translates to:
  /// **'My Trainees'**
  String get trainerMyTrainees;

  /// No description provided for @trainerNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get trainerNeedsAttention;

  /// No description provided for @trainerNewAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get trainerNewAnnouncement;

  /// No description provided for @trainerNoActiveProgram.
  ///
  /// In en, this message translates to:
  /// **'No Active Program'**
  String get trainerNoActiveProgram;

  /// No description provided for @trainerNoProgramScheduleFound.
  ///
  /// In en, this message translates to:
  /// **'No program schedule found'**
  String get trainerNoProgramScheduleFound;

  /// No description provided for @trainerNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get trainerNotSpecified;

  /// No description provided for @trainerNotificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get trainerNotificationDeleted;

  /// No description provided for @trainerOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get trainerOnTrack;

  /// No description provided for @trainerPersonalMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Personal Message (Optional)'**
  String get trainerPersonalMessageOptional;

  /// No description provided for @trainerPinAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Pin Announcement'**
  String get trainerPinAnnouncement;

  /// No description provided for @trainerPinnedAnnouncementsAppearAtTheTop.
  ///
  /// In en, this message translates to:
  /// **'Pinned announcements appear at the top'**
  String get trainerPinnedAnnouncementsAppearAtTheTop;

  /// No description provided for @trainerPleaseEnterAPresetName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a preset name'**
  String get trainerPleaseEnterAPresetName;

  /// No description provided for @trainerPresetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Preset deleted'**
  String get trainerPresetDeleted;

  /// No description provided for @trainerPresetName.
  ///
  /// In en, this message translates to:
  /// **'Preset Name'**
  String get trainerPresetName;

  /// No description provided for @trainerPrimaryGoal.
  ///
  /// In en, this message translates to:
  /// **'Primary Goal'**
  String get trainerPrimaryGoal;

  /// No description provided for @trainerProgramEndedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Program ended successfully'**
  String get trainerProgramEndedSuccessfully;

  /// No description provided for @trainerProgramOptions.
  ///
  /// In en, this message translates to:
  /// **'Program Options'**
  String get trainerProgramOptions;

  /// No description provided for @trainerProgramUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Program updated successfully'**
  String get trainerProgramUpdatedSuccessfully;

  /// No description provided for @trainerReassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get trainerReassign;

  /// No description provided for @trainerReassignTemplate.
  ///
  /// In en, this message translates to:
  /// **'Reassign Template?'**
  String get trainerReassignTemplate;

  /// No description provided for @trainerRecoveryRest.
  ///
  /// In en, this message translates to:
  /// **'Recovery & rest'**
  String get trainerRecoveryRest;

  /// No description provided for @trainerRemoveThisProgramFromTrainee.
  ///
  /// In en, this message translates to:
  /// **'Remove this program from trainee'**
  String get trainerRemoveThisProgramFromTrainee;

  /// No description provided for @trainerRemoveTrainee.
  ///
  /// In en, this message translates to:
  /// **'Remove Trainee'**
  String get trainerRemoveTrainee;

  /// No description provided for @trainerRenamedTonewNameInAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"\$newName\" in all weeks'**
  String get trainerRenamedTonewNameInAllWeeks;

  /// No description provided for @trainerReplaceExercise.
  ///
  /// In en, this message translates to:
  /// **'Replace Exercise'**
  String get trainerReplaceExercise;

  /// No description provided for @trainerResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get trainerResend;

  /// No description provided for @trainerRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get trainerRestDay;

  /// No description provided for @trainerRetentionRate.
  ///
  /// In en, this message translates to:
  /// **'Retention Rate'**
  String get trainerRetentionRate;

  /// No description provided for @trainerSearch.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get trainerSearch;

  /// No description provided for @trainerSendCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Send Check-In'**
  String get trainerSendCheckIn;

  /// No description provided for @trainerSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get trainerSendMessage;

  /// No description provided for @trainerSetAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get trainerSetAsDefault;

  /// No description provided for @trainerShowAsPrimaryOption.
  ///
  /// In en, this message translates to:
  /// **'Show as primary option'**
  String get trainerShowAsPrimaryOption;

  /// No description provided for @trainerStartWithAPreBuiltProgramTemplate.
  ///
  /// In en, this message translates to:
  /// **'Start with a pre-built program template'**
  String get trainerStartWithAPreBuiltProgramTemplate;

  /// No description provided for @trainerTapToManage.
  ///
  /// In en, this message translates to:
  /// **'Tap to manage'**
  String get trainerTapToManage;

  /// No description provided for @trainerTotalSets.
  ///
  /// In en, this message translates to:
  /// **'Total Sets'**
  String get trainerTotalSets;

  /// No description provided for @trainerTotalTrainees.
  ///
  /// In en, this message translates to:
  /// **'Total Trainees'**
  String get trainerTotalTrainees;

  /// No description provided for @trainerTraineeNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trainee no longer available'**
  String get trainerTraineeNoLongerAvailable;

  /// No description provided for @trainerTraineeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trainee not found'**
  String get trainerTraineeNotFound;

  /// No description provided for @trainerTraineeRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Trainee removed successfully'**
  String get trainerTraineeRemovedSuccessfully;

  /// No description provided for @trainerUpdatedInAllWeeks.
  ///
  /// In en, this message translates to:
  /// **'Updated in all weeks'**
  String get trainerUpdatedInAllWeeks;

  /// No description provided for @trainerUseThisTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use This Template'**
  String get trainerUseThisTemplate;

  /// No description provided for @trainerViewAsTrainee.
  ///
  /// In en, this message translates to:
  /// **'View as Trainee'**
  String get trainerViewAsTrainee;

  /// No description provided for @trainerWeekcurrentWeek.
  ///
  /// In en, this message translates to:
  /// **'Week \$currentWeek'**
  String get trainerWeekcurrentWeek;

  /// No description provided for @trainerWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get trainerWorkout;

  /// No description provided for @trainerWriteYourAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Write your announcement...'**
  String get trainerWriteYourAnnouncement;

  /// No description provided for @trainerYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get trainerYesCancel;

  /// No description provided for @watchAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync'**
  String get watchAutoSync;

  /// No description provided for @watchConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get watchConnected;

  /// No description provided for @watchLogFromYourWrist.
  ///
  /// In en, this message translates to:
  /// **'Log from your wrist'**
  String get watchLogFromYourWrist;

  /// No description provided for @watchPaired.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get watchPaired;

  /// No description provided for @watchRestTimers.
  ///
  /// In en, this message translates to:
  /// **'Rest timers'**
  String get watchRestTimers;

  /// No description provided for @watchSyncRequested.
  ///
  /// In en, this message translates to:
  /// **'Sync requested'**
  String get watchSyncRequested;

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get workoutAddExercise;

  /// No description provided for @workoutAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get workoutAddSet;

  /// No description provided for @workoutAddWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add Workout'**
  String get workoutAddWorkout;

  /// No description provided for @workoutChangesSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Changes saved successfully'**
  String get workoutChangesSavedSuccessfully;

  /// No description provided for @workoutCheckOtherWeeksOrContactYourTrainer.
  ///
  /// In en, this message translates to:
  /// **'Check other weeks or contact your trainer'**
  String get workoutCheckOtherWeeksOrContactYourTrainer;

  /// No description provided for @workoutComparedToYourUsualWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Compared to your usual workouts'**
  String get workoutComparedToYourUsualWorkouts;

  /// No description provided for @workoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get workoutComplete;

  /// No description provided for @workoutEGShoulderFeltTightDuringOverheadPress.
  ///
  /// In en, this message translates to:
  /// **'e.g., \"Shoulder felt tight during overhead press\"'**
  String get workoutEGShoulderFeltTightDuringOverheadPress;

  /// No description provided for @workoutExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get workoutExit;

  /// No description provided for @workoutExitWorkout.
  ///
  /// In en, this message translates to:
  /// **'Exit Workout?'**
  String get workoutExitWorkout;

  /// No description provided for @workoutFailedToSaveRestDaye.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rest day: \$e'**
  String get workoutFailedToSaveRestDaye;

  /// No description provided for @workoutGoToToday.
  ///
  /// In en, this message translates to:
  /// **'Go to today'**
  String get workoutGoToToday;

  /// No description provided for @workoutHowDoYouFeelNow.
  ///
  /// In en, this message translates to:
  /// **'How do you feel now?'**
  String get workoutHowDoYouFeelNow;

  /// No description provided for @workoutHowHappyAreYouWithThisSession.
  ///
  /// In en, this message translates to:
  /// **'How happy are you with this session'**
  String get workoutHowHappyAreYouWithThisSession;

  /// No description provided for @workoutHowIntenseWasIt.
  ///
  /// In en, this message translates to:
  /// **'How intense was it?'**
  String get workoutHowIntenseWasIt;

  /// No description provided for @workoutHowWasYourPerformance.
  ///
  /// In en, this message translates to:
  /// **'How was your performance?'**
  String get workoutHowWasYourPerformance;

  /// No description provided for @workoutMarkAsMissed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Missed'**
  String get workoutMarkAsMissed;

  /// No description provided for @workoutMyPrograms.
  ///
  /// In en, this message translates to:
  /// **'My Programs'**
  String get workoutMyPrograms;

  /// No description provided for @workoutNoProgramsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No programs assigned'**
  String get workoutNoProgramsAssigned;

  /// No description provided for @workoutNoProgramsAvailableToSwitchTo.
  ///
  /// In en, this message translates to:
  /// **'No programs available to switch to'**
  String get workoutNoProgramsAvailableToSwitchTo;

  /// No description provided for @workoutNoWorkoutsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No workouts this week'**
  String get workoutNoWorkoutsThisWeek;

  /// No description provided for @workoutOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get workoutOpenCalendar;

  /// No description provided for @workoutOverallSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Overall satisfaction?'**
  String get workoutOverallSatisfaction;

  /// No description provided for @workoutPostWorkout.
  ///
  /// In en, this message translates to:
  /// **'Post-Workout'**
  String get workoutPostWorkout;

  /// No description provided for @workoutPreWorkout.
  ///
  /// In en, this message translates to:
  /// **'Pre-Workout'**
  String get workoutPreWorkout;

  /// No description provided for @workoutRateHowWellYouExecutedYourExercises.
  ///
  /// In en, this message translates to:
  /// **'Rate how well you executed your exercises'**
  String get workoutRateHowWellYouExecutedYourExercises;

  /// No description provided for @workoutRestDayCompleted.
  ///
  /// In en, this message translates to:
  /// **'Rest day completed!'**
  String get workoutRestDayCompleted;

  /// No description provided for @workoutSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get workoutSaveChanges;

  /// No description provided for @workoutScheduleNotBuiltYet.
  ///
  /// In en, this message translates to:
  /// **'Schedule not built yet'**
  String get workoutScheduleNotBuiltYet;

  /// No description provided for @workoutShareWorkout.
  ///
  /// In en, this message translates to:
  /// **'Share workout'**
  String get workoutShareWorkout;

  /// No description provided for @workoutSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get workoutSkip;

  /// No description provided for @workoutSkipFinish.
  ///
  /// In en, this message translates to:
  /// **'Skip & Finish'**
  String get workoutSkipFinish;

  /// No description provided for @workoutSkipStart.
  ///
  /// In en, this message translates to:
  /// **'Skip & Start'**
  String get workoutSkipStart;

  /// No description provided for @workoutSkipSurvey.
  ///
  /// In en, this message translates to:
  /// **'Skip Survey?'**
  String get workoutSkipSurvey;

  /// No description provided for @workoutStartAWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start a Workout'**
  String get workoutStartAWorkout;

  /// No description provided for @workoutSwitchProgram.
  ///
  /// In en, this message translates to:
  /// **'Switch Program'**
  String get workoutSwitchProgram;

  /// No description provided for @workoutViewAllPrograms.
  ///
  /// In en, this message translates to:
  /// **'View All Programs'**
  String get workoutViewAllPrograms;

  /// No description provided for @workoutViewCalendar.
  ///
  /// In en, this message translates to:
  /// **'View Calendar'**
  String get workoutViewCalendar;

  /// No description provided for @workoutYouCanStillStartYourWorkoutWithoutCompletingT.
  ///
  /// In en, this message translates to:
  /// **'You can still start your workout without completing the survey.'**
  String get workoutYouCanStillStartYourWorkoutWithoutCompletingT;

  /// No description provided for @workoutYouOnlyHaveOneProgramAssigned.
  ///
  /// In en, this message translates to:
  /// **'You only have one program assigned'**
  String get workoutYouOnlyHaveOneProgramAssigned;

  /// No description provided for @workoutYourEnergyLevelAfterTheWorkout.
  ///
  /// In en, this message translates to:
  /// **'Your energy level after the workout'**
  String get workoutYourEnergyLevelAfterTheWorkout;

  /// No description provided for @workoutYourProgressWillNotBeSaved.
  ///
  /// In en, this message translates to:
  /// **'Your progress will not be saved.'**
  String get workoutYourProgressWillNotBeSaved;

  /// No description provided for @workoutYourTrainerWillAssignYouAProgramSoon.
  ///
  /// In en, this message translates to:
  /// **'Your trainer will assign you a program soon'**
  String get workoutYourTrainerWillAssignYouAProgramSoon;
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
