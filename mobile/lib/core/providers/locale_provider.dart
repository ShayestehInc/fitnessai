import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'preferred_locale';

/// Supported locales matching backend UserProfile.Language choices.
const supportedLocales = [
  Locale('en'),
  Locale('es'),
  Locale('pt', 'BR'),
];

/// Maps backend language codes ('en', 'es', 'pt-br') to Flutter Locales.
Locale localeFromLanguageCode(String code) {
  return switch (code) {
    'es' => const Locale('es'),
    'pt-br' => const Locale('pt', 'BR'),
    _ => const Locale('en'),
  };
}

/// Maps Flutter Locale to backend language code.
String languageCodeFromLocale(Locale locale) {
  if (locale.languageCode == 'pt') return 'pt-br';
  return locale.languageCode;
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null) {
      state = localeFromLanguageCode(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, languageCodeFromLocale(locale));
  }

  /// Set locale from backend profile response without persisting again.
  void setFromProfile(String languageCode) {
    state = localeFromLanguageCode(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
