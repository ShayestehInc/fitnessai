import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Shorthand to access AppLocalizations from BuildContext.
///
/// Usage: `context.l10n.authLoginTitle`
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
