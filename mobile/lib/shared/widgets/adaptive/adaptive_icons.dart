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
}
