import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive icon constants.
///
/// Returns Cupertino icons on iOS, Material icons on Android.
abstract final class AdaptiveIcons {
  static final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;

  /// Back navigation: iOS chevron `<` vs Android arrow `←`
  static IconData get back =>
      _isIOS ? CupertinoIcons.back : Icons.arrow_back;

  /// Close / dismiss: iOS `×` vs Android `×` (same icon, different weight)
  static IconData get close =>
      _isIOS ? CupertinoIcons.xmark : Icons.close;

  /// Add / create: iOS `+` vs Android `+`
  static IconData get add =>
      _isIOS ? CupertinoIcons.add : Icons.add;

  /// Search: iOS magnifying glass vs Android search
  static IconData get search =>
      _isIOS ? CupertinoIcons.search : Icons.search;

  /// Share: iOS share sheet vs Android share
  static IconData get share =>
      _isIOS ? CupertinoIcons.share : Icons.share;

  /// Settings / gear: iOS gear vs Android settings
  static IconData get settings =>
      _isIOS ? CupertinoIcons.gear : Icons.settings;

  /// Delete / trash: iOS trash vs Android delete
  static IconData get delete =>
      _isIOS ? CupertinoIcons.trash : Icons.delete;

  /// Edit / pencil: iOS pencil vs Android edit
  static IconData get edit =>
      _isIOS ? CupertinoIcons.pencil : Icons.edit;

  /// More options: iOS ellipsis vs Android three dots
  static IconData get more =>
      _isIOS ? CupertinoIcons.ellipsis : Icons.more_vert;

  /// Chevron right (disclosure indicator): iOS chevron vs Android arrow
  static IconData get chevronRight =>
      _isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right;

  /// Info / about: iOS info circle vs Android info
  static IconData get info =>
      _isIOS ? CupertinoIcons.info : Icons.info_outline;

  /// Check / done: iOS checkmark vs Android check
  static IconData get check =>
      _isIOS ? CupertinoIcons.check_mark : Icons.check;

  /// Refresh / reload
  static IconData get refresh =>
      _isIOS ? CupertinoIcons.refresh : Icons.refresh;

  // ── Navigation bar icons ────────────────────────────────────────────

  /// Home (filled)
  static IconData get home =>
      _isIOS ? CupertinoIcons.house_fill : Icons.home;

  /// Home (outlined)
  static IconData get homeOutlined =>
      _isIOS ? CupertinoIcons.house : Icons.home_outlined;

  /// Diet / nutrition (filled)
  static IconData get diet =>
      _isIOS ? CupertinoIcons.leaf_arrow_circlepath : Icons.restaurant;

  /// Diet / nutrition (outlined)
  static IconData get dietOutlined =>
      _isIOS ? CupertinoIcons.leaf_arrow_circlepath : Icons.restaurant_outlined;

  /// Workout / logbook (filled)
  static IconData get workout =>
      _isIOS ? CupertinoIcons.bolt_fill : Icons.fitness_center;

  /// Workout / logbook (outlined)
  static IconData get workoutOutlined =>
      _isIOS ? CupertinoIcons.bolt : Icons.fitness_center_outlined;

  /// Community (filled)
  static IconData get community =>
      _isIOS ? CupertinoIcons.person_2_fill : Icons.people;

  /// Community (outlined)
  static IconData get communityOutlined =>
      _isIOS ? CupertinoIcons.person_2 : Icons.people_outlined;

  /// Messages (filled)
  static IconData get messages =>
      _isIOS ? CupertinoIcons.chat_bubble_fill : Icons.chat_bubble;

  /// Messages (outlined)
  static IconData get messagesOutlined =>
      _isIOS ? CupertinoIcons.chat_bubble : Icons.chat_bubble_outline;

  /// Dashboard (filled)
  static IconData get dashboard =>
      _isIOS ? CupertinoIcons.square_grid_2x2_fill : Icons.dashboard;

  /// Dashboard (outlined)
  static IconData get dashboardOutlined =>
      _isIOS ? CupertinoIcons.square_grid_2x2 : Icons.dashboard_outlined;

  /// Programs / calendar (filled)
  static IconData get programs =>
      _isIOS ? CupertinoIcons.calendar : Icons.calendar_month;

  /// Programs / calendar (outlined)
  static IconData get programsOutlined =>
      _isIOS ? CupertinoIcons.calendar : Icons.calendar_month_outlined;

  /// Settings (filled)
  static IconData get settingsFilled =>
      _isIOS ? CupertinoIcons.gear_solid : Icons.settings;

  /// Settings (outlined) — alias for the existing `settings` getter
  static IconData get settingsOutlined =>
      _isIOS ? CupertinoIcons.gear : Icons.settings_outlined;

  /// Trainers / people (filled) — for admin nav
  static IconData get trainers =>
      _isIOS ? CupertinoIcons.person_2_fill : Icons.people;

  /// Subscriptions (filled) — for admin nav
  static IconData get subscriptions =>
      _isIOS ? CupertinoIcons.creditcard_fill : Icons.subscriptions;

  /// Referrals / people (outlined)
  static IconData get referrals =>
      _isIOS ? CupertinoIcons.person_2 : Icons.people_outline;

  /// Referrals / people (filled)
  static IconData get referralsFilled =>
      _isIOS ? CupertinoIcons.person_2_fill : Icons.people;
}
