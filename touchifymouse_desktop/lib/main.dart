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
      '-e', 'tell application "System Events" to return name of processes'
    ]);
    if (res.exitCode != 0) {
      _initialRoute = '/permissions';
    }
  } catch (_) {
    _initialRoute = '/permissions';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check accessibility BEFORE starting the app
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
  });

  // Tray icon
  await trayManager.setIcon('assets/icons/tray_icon.png');
  await trayManager.setToolTip('TouchifyMouse');
  await trayManager.setContextMenu(Menu(items: [
    MenuItem(key: 'status',    label: 'TouchifyMouse — Running', disabled: true),
    MenuItem(key: 'show_qr',   label: 'Show / Hide Window'),
    MenuItem(key: 'device',    label: 'No device connected',     disabled: true),
    MenuItem.separator(),
    MenuItem(key: 'dashboard', label: 'Open Dashboard'),
    MenuItem(key: 'perms',     label: 'Permissions'),
    MenuItem.separator(),
    MenuItem(key: 'quit',      label: 'Quit'),
  ]));

  // Start the Python backend
  await pythonAgentService.start();

  trayManager.addListener(TrayListenerHandler());
  runApp(ProviderScope(child: TouchifyDesktopApp(initialRoute: _initialRoute)));
}

class TrayListenerHandler with TrayListener {
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_qr':
      case 'dashboard':
        windowManager.show();
        break;
      case 'perms':
        windowManager.show();
        AppRouter.router.go('/permissions');
        break;
      case 'quit':
        pythonAgentService.stop();
        exit(0);
    }
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
