import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/setup_guide_screen.dart';
import '../../features/connect/screens/connect_screen.dart';
import '../../features/trackpad/screens/trackpad_screen.dart';
import '../../features/audio/screens/microphone_screen.dart';
import '../../features/audio/screens/speaker_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/pro/screens/pro_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupGuideScreen(),
      ),
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: '/trackpad',
        builder: (context, state) => const TrackpadScreen(),
      ),
      GoRoute(
        path: '/microphone',
        builder: (context, state) => const MicrophoneScreen(),
      ),
      GoRoute(
        path: '/speaker',
        builder: (context, state) => const SpeakerScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/pro',
        builder: (context, state) => const ProScreen(),
      ),
    ],
  );
}
