import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/api_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API config (load saved base URL)
  await ApiConfigService.initialize();

  runApp(
    const ProviderScope(
      child: FitnessAIApp(),
    ),
  );
}

class FitnessAIApp extends ConsumerWidget {
  const FitnessAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = AppTheme.darkTheme;

    return MaterialApp.router(
      routerConfig: router,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
