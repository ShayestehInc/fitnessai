import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/app_database.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/api_config_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize API config (load saved base URL)
  await ApiConfigService.initialize();

  // Initialize local database and run cleanup
  final database = AppDatabase();
  await database.runStartupCleanup();

  // Initialize connectivity monitoring
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        connectivityServiceProvider.overrideWithValue(connectivityService),
      ],
      child: const FitnessAIApp(),
    ),
  );
}

class FitnessAIApp extends ConsumerWidget {
  const FitnessAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    final themeData = AppThemeBuilder.buildTheme(themeState);

    // Determine theme mode
    ThemeMode themeMode;
    switch (themeState.mode) {
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
    }

    return MaterialApp.router(
      routerConfig: router,
      title: 'FitnessAI',
      theme: AppThemeBuilder.buildTheme(themeState.copyWith(mode: AppThemeMode.light)),
      darkTheme: AppThemeBuilder.buildTheme(themeState.copyWith(mode: AppThemeMode.dark)),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply smooth theme transitions
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
