import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/analytics_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // runZonedGuarded so any uncaught async error gets reported to Crashlytics.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Disable Crashlytics in debug to keep development noise out of dashboards.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Forward Flutter framework errors.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Forward platform-dispatcher errors (e.g. async errors that escape
    // the framework). Returning true tells Flutter we've handled it.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    final prefs = await SharedPreferences.getInstance();
    unawaited(Analytics.appOpened());

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TouchDeskApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
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
        themeMode = ThemeMode.light;
      case 'dark':
        activeTheme = AppTheme.darkTheme;
        themeMode = ThemeMode.dark;
      default: // 'amoled'
        activeTheme = AppTheme.amoledTheme;
        themeMode = ThemeMode.dark;
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
