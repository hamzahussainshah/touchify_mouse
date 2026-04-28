import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TouchDeskApp(),
    ),
  );
}

class TouchDeskApp extends ConsumerWidget {
  const TouchDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider).theme; // 'amoled' | 'dark' | 'light'

    final ThemeData activeTheme;
    final ThemeMode themeMode;

    switch (theme) {
      case 'light':
        activeTheme = AppTheme.lightTheme;
        themeMode   = ThemeMode.light;
      case 'dark':
        activeTheme = AppTheme.darkTheme;
        themeMode   = ThemeMode.dark;
      default: // 'amoled'
        activeTheme = AppTheme.amoledTheme;
        themeMode   = ThemeMode.dark;
    }

    return MaterialApp.router(
      title: 'TouchifyMouse',
      theme: activeTheme,
      darkTheme: activeTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
