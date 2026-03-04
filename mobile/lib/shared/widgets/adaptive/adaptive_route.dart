import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Returns a platform-adaptive page route.
///
/// iOS: [CupertinoPageRoute] (slide from right).
/// Android: [MaterialPageRoute] (fade upwards).
PageRoute<T> adaptivePageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  // Use a static platform check -- no BuildContext needed.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
  );
}
