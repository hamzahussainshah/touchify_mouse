import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:process_run/process_run.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/python_agent_service.dart';

// Holds the initial route so GoRouter can redirect on first launch
String _initialRoute = '/welcome';

Future<void> _checkInitialPermissions() async {
  if (!Platform.isMacOS) return;
  try {
    final res = await runExecutableArguments('osascript', [
      '-e', 'tell application "System Events" to return name of processes',
    ]);
    if (res.exitCode != 0) {
      _initialRoute = '/permissions';
    }
  } catch (_) {
    _initialRoute = '/permissions';
  }
}

Future<void> _quitApp() async {
  await pythonAgentService.stop();
  await trayManager.destroy();
  exit(0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _checkInitialPermissions();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(820, 560),
    minimumSize: Size(700, 480),
    center: true,
    title: 'TouchifyMouse',
    backgroundColor: Color(0xFF0D0D11),
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Intercept the close button so the agent keeps running in the
    // background — only the window goes away. Real quit comes from the
    // tray menu.
    await windowManager.setPreventClose(true);
  });

  // Tray icon (note: "Quit TouchifyMouse" rather than just "Quit" so users
  // who reach for ⌘Q on macOS understand it kills the background agent.)
  await trayManager.setIcon('assets/icons/tray_icon.png');
  await trayManager.setToolTip('TouchifyMouse — running in background');
  await trayManager.setContextMenu(
    Menu(
      items: [
        MenuItem(key: 'status', label: 'TouchifyMouse — Running', disabled: true),
        MenuItem(key: 'device', label: 'No device connected', disabled: true),
        MenuItem.separator(),
        MenuItem(key: 'show', label: 'Open Dashboard'),
        MenuItem(key: 'perms', label: 'Permissions'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit TouchifyMouse'),
      ],
    ),
  );

  await pythonAgentService.start();

  // Window + tray listeners — single object handles both so the close
  // button and tray menu stay in sync.
  final handler = _AppLifecycleHandler();
  trayManager.addListener(handler);
  windowManager.addListener(handler);

  runApp(ProviderScope(child: TouchifyDesktopApp(initialRoute: _initialRoute)));
}

class _AppLifecycleHandler with TrayListener, WindowListener {
  // ── Tray ────────────────────────────────────────────────────────────────
  @override
  void onTrayIconMouseDown() => _showWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'show':
        _showWindow();
      case 'perms':
        _showWindow();
        AppRouter.router.go('/permissions');
      case 'quit':
        _quitApp();
    }
  }

  // ── Window ──────────────────────────────────────────────────────────────
  // setPreventClose(true) routes the platform close into onWindowClose
  // instead of terminating the app. We hide the window; user can re-open
  // from the tray. This keeps the Python agent + mDNS broadcast alive so
  // the mobile app stays connected through window-close.
  @override
  void onWindowClose() async {
    final prevented = await windowManager.isPreventClose();
    if (prevented) {
      await windowManager.hide();
    }
  }

  Future<void> _showWindow() async {
    if (!await windowManager.isVisible()) {
      await windowManager.show();
    }
    await windowManager.focus();
  }
}

class TouchifyDesktopApp extends StatelessWidget {
  final String initialRoute;
  const TouchifyDesktopApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TouchifyMouse',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.buildRouter(initialRoute),
    );
  }
}
