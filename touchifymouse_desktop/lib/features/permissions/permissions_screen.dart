import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/titlebar.dart';
import '../../shared/widgets/sidebar.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _accessibilityGranted = false;
  bool _micGranted = true; // macOS grants mic via entitlements
  bool _networkGranted = true; // network access is entitlement-based
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      _checkPermissions();
      _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPermissions());
    } else {
      // Windows — no accessibility check needed; pyautogui works without it
      _accessibilityGranted = true;
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isMacOS) {
      if (mounted) setState(() => _accessibilityGranted = true);
      return;
    }
    try {
      // Use the trusted API — run a privileged osascript that only succeeds with Accessibility
      final res = await Process.run('osascript', [
        '-e', 'tell application "System Events" to return name of first process'
      ]);
      if (mounted) {
        final granted = res.exitCode == 0;
        setState(() => _accessibilityGranted = granted);
        if (granted) _checkTimer?.cancel();
      }
    } catch (_) {
      if (mounted) setState(() => _accessibilityGranted = false);
    }
  }

  void _openAccessibilityPrefs() async {
    // Trigger the "wants to use accessibility" prompt for this process
    await Process.run('osascript', [
      '-e', 'tell application "System Events" to key code 0',
    ]);
    // Open Accessibility pane so user can enable the app there
    await Process.run('open', [
      'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Find "touchifymouse_desktop" in the list and toggle it ON. '
            'Status here updates automatically every 3 seconds.',
          ),
          duration: Duration(seconds: 8),
        ),
      );
    }
  }

  void _checkNetworkAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Network / Firewall', style: TextStyle(color: AppColors.text1, fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
        content: const Text(
          'If macOS firewall is enabled, go to:\n\nSystem Settings → Network → Firewall → Options\n\nFind "touchifymouse_desktop" and allow incoming connections.',
          style: TextStyle(color: AppColors.text2, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Process.run('open', ['x-apple.systempreferences:com.apple.preference.security?Firewall']);
            },
            child: const Text('Open Firewall Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                  activeRoute: '/permissions',
                  onNavigate: (route) => context.go(route),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.surface0,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Permissions',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 24,
                            fontWeight: FontWeight.w700, color: AppColors.text1)),
                        const SizedBox(height: 6),
                        const Text(
                          'TouchifyMouse needs these permissions to control your Mac.',
                          style: TextStyle(color: AppColors.text3, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        _buildPermItem(
                          icon: Icons.accessibility_new,
                          iconColor: AppColors.primary,
                          title: 'Accessibility',
                          desc: 'Required to move the cursor, click, scroll and simulate keyboard events.',
                          granted: _accessibilityGranted,
                          onAction: _openAccessibilityPrefs,
                          actionLabel: 'Open System Settings →',
                        ),
                        const SizedBox(height: 12),
                        _buildPermItem(
                          icon: Icons.shield_outlined,
                          iconColor: AppColors.warning,
                          title: 'Network / Firewall',
                          desc: 'Allow TouchifyMouse through your firewall to receive phone connections.',
                          granted: _networkGranted,
                          onAction: _checkNetworkAlert,
                          actionLabel: 'View Instructions →',
                        ),
                        const SizedBox(height: 12),
                        _buildPermItem(
                          icon: Icons.mic_none,
                          iconColor: AppColors.success,
                          title: 'Microphone',
                          desc: 'Play audio from your phone microphone through this Mac. Granted via app entitlements.',
                          granted: _micGranted,
                          onAction: null,
                          actionLabel: '',
                        ),
                        const Spacer(),
                        if (!_accessibilityGranted) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Without Accessibility, mouse and keyboard control will not work. Grant it then restart the app.',
                                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openAccessibilityPrefs,
                                  child: const Text('Grant Now', style: TextStyle(color: AppColors.danger)),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildPermItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required bool granted,
    required VoidCallback? onAction,
    required String actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted ? AppColors.success.withOpacity(0.2) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                const SizedBox(height: 2),
                Text(desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.text3, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (granted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                  SizedBox(width: 4),
                  Text('Granted', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDim,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
