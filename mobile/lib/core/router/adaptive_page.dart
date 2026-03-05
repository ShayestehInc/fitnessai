import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Returns a [CupertinoPage] on iOS (enables swipe-back gesture) or a
/// [MaterialPage] on Android (standard Material transition).
Page<T> adaptivePage<T>({
  required Widget child,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
  bool maintainState = true,
  bool fullscreenDialog = false,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<T>(
      child: child,
      key: key,
      name: name,
      arguments: arguments,
      restorationId: restorationId,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  return MaterialPage<T>(
    child: child,
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
  );
}

/// Fullscreen-dialog variant: slides up from the bottom on iOS,
/// standard fullscreen dialog on Android.
Page<T> adaptiveFullscreenPage<T>({
  required Widget child,
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
}) {
  return adaptivePage<T>(
    child: child,
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    fullscreenDialog: true,
  );
}
