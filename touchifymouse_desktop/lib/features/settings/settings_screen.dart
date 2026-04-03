import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/titlebar.dart';
import '../../shared/widgets/sidebar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _launchOnStartup = false;
  late String _plistPath;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      _plistPath = '${Platform.environment['HOME']}/Library/LaunchAgents/com.touchifymouse.agent.plist';
      _checkLaunchState();
    }
  }

  void _checkLaunchState() {
    if (File(_plistPath).existsSync()) {
      setState(() => _launchOnStartup = true);
    }
  }

  Future<void> _toggleLaunch(bool val) async {
    if (Platform.isMacOS) {
      if (val) {
        final execPath = Platform.resolvedExecutable;
        final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.touchifymouse.agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>$execPath</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>''';
        await File(_plistPath).writeAsString(plistContent);
        setState(() => _launchOnStartup = true);
      } else {
        if (File(_plistPath).existsSync()) {
          await File(_plistPath).delete();
        }
        setState(() => _launchOnStartup = false);
      }
    }
  }

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
                  activeRoute: '/settings',
                  onNavigate: (route) => context.go(route),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.surface0,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Settings', style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text1)),
                        const SizedBox(height: 24),
                        if (Platform.isMacOS)
                          _buildSettingItem(
                            title: 'Launch on Startup',
                            desc: 'Start TouchifyMouse automatically when you log in to your computer.',
                            val: _launchOnStartup,
                            onChanged: _toggleLaunch,
                          ),
                      ],
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

  Widget _buildSettingItem({required String title, required String desc, required bool val, required Function(bool) onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
              ],
            ),
          ),
          Switch(
            value: val,
            onChanged: onChanged,
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
