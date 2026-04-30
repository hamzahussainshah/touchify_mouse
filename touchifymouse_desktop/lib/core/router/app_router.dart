import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/devices/devices_screen.dart';
import '../../features/network/network_scan_screen.dart';
import '../../features/permissions/permissions_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../shared/widgets/titlebar.dart';
import '../../shared/widgets/sidebar.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/qr_panel.dart';

// Generic placeholder screen used for unimplemented sidebar routes
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String activeRoute;
  const _PlaceholderScreen({required this.title, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  activeRoute: activeRoute,
                  onNavigate: (r) => context.go(r),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.surface0,
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// QR-only full screen (accessible from sidebar)
class _QrScreen extends StatelessWidget {
  const _QrScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  activeRoute: '/qr',
                  onNavigate: (r) => context.go(r),
                ),
                const Expanded(
                  child: Center(child: QrPanel()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppRouter {
  static GoRouter buildRouter(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) => _PlaceholderScreen(
      title: 'Page Not Found',
      activeRoute: '/dashboard',
    ),
    routes: [
      GoRoute(path: '/welcome',     builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/dashboard',   builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/permissions', builder: (_, __) => const PermissionsScreen()),
      GoRoute(path: '/settings',    builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/qr',          builder: (_, __) => const _QrScreen()),
      GoRoute(path: '/devices',     builder: (_, __) => const DevicesScreen()),
      GoRoute(path: '/scan',        builder: (_, __) => const NetworkScanScreen()),
    ],
  );

  // Convenience static instance for tray menu access (initialises with /dashboard)
  static final GoRouter router = buildRouter('/dashboard');
}
