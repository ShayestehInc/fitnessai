import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../shared/widgets/animated_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  bool _isSaving = false;

  static const _languages = [
    _LanguageOption(
      locale: Locale('en'),
      nativeName: 'English',
      backendCode: 'en',
    ),
    _LanguageOption(
      locale: Locale('es'),
      nativeName: 'Español',
      backendCode: 'es',
    ),
    _LanguageOption(
      locale: Locale('pt', 'BR'),
      nativeName: 'Português (Brasil)',
      backendCode: 'pt-br',
    ),
  ];

  Future<void> _selectLanguage(_LanguageOption option) async {
    final currentLocale = ref.read(localeProvider);
    if (currentLocale == option.locale) return;

    setState(() => _isSaving = true);

    // Update locale locally (persists via SharedPreferences)
    await ref
        .read(localeProvider.notifier)
        .setLocale(option.locale);

    // Patch the backend profile
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.dio.patch(
        ApiConstants.profiles,
        data: {'preferred_language': option.backendCode},
      );
    } catch (_) {
      // Locale is already saved locally; backend sync can retry later
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.languageChanged)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsLanguageSelect),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final option = _languages[index];
                final isSelected = _isLocaleMatch(currentLocale, option.locale);
                return _buildLanguageTile(
                  context,
                  theme,
                  option,
                  isSelected,
                  index,
                );
              },
            ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    ThemeData theme,
    _LanguageOption option,
    bool isSelected,
    int index,
  ) {
    final primaryColor = theme.colorScheme.primary;

    return StaggeredListItem(
      index: index,
      delay: const Duration(milliseconds: 50),
      child: AnimatedPress(
        onTap: () => _selectLanguage(option),
        scaleDown: 0.98,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : theme.dividerColor.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isSelected ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.language,
                color: isSelected
                    ? primaryColor
                    : theme.textTheme.bodySmall?.color,
                size: 22,
              ),
            ),
            title: Text(
              option.nativeName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: Text(
              _translatedName(option.backendCode),
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: primaryColor)
                : null,
          ),
        ),
      ),
    );
  }

  String _translatedName(String code) {
    final l10n = context.l10n;
    return switch (code) {
      'es' => l10n.languageSpanish,
      'pt-br' => l10n.languagePortuguese,
      _ => l10n.languageEnglish,
    };
  }

  bool _isLocaleMatch(Locale current, Locale target) {
    if (current.languageCode != target.languageCode) return false;
    if (target.countryCode != null) {
      return current.countryCode == target.countryCode;
    }
    return true;
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.locale,
    required this.nativeName,
    required this.backendCode,
  });

  final Locale locale;
  final String nativeName;
  final String backendCode;
}
