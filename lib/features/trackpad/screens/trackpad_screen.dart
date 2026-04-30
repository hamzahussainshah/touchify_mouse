import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../shared/widgets/connection_chip.dart';
import '../../../shared/widgets/home_indicator.dart';
import '../../keyboard/widgets/keyboard_panel.dart';
import '../../media/widgets/media_remote_panel.dart';
import '../../audio/widgets/audio_hub_panel.dart';
import 'package:go_router/go_router.dart';
import '../services/trackpad_socket_service.dart';
import '../widgets/trackpad_surface.dart';
import '../widgets/click_buttons_bar.dart';
import '../widgets/trackpad_toolbar.dart';

class TrackpadScreen extends ConsumerStatefulWidget {
  const TrackpadScreen({super.key});

  @override
  ConsumerState<TrackpadScreen> createState() => _TrackpadScreenState();
}

class _TrackpadScreenState extends ConsumerState<TrackpadScreen> {
  ToolbarTab _currentTab = ToolbarTab.pad;

  @override
  void initState() {
    super.initState();
    try { WakelockPlus.enable(); } catch (_) {}
    
    // Connect socket AFTER first frame so providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectSocket();
    });
  }

  Future<void> _connectSocket() async {
    final device = ref.read(connectionProvider.notifier).connectedDevice;
    if (device == null) {
      print('[TrackpadScreen] No device in provider — going back to connect');
      context.go('/connect');
      return;
    }
    
    print('[TrackpadScreen] Connecting socket to ${device.ipAddress}:${device.port}');
    final success = await TrackpadSocketService.instance.connect(
      device.ipAddress,
      tcpPort: device.port,
      udpPort: 35900,
    );

    
    if (!success) {
      print('[TrackpadScreen] Socket connection FAILED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect to desktop agent')),
        );
      }
    } else {
      print('[TrackpadScreen] Socket connected ✓');
    }
  }

  @override
  void dispose() {
    try { WakelockPlus.disable(); } catch (_) {}
    // Do NOT disconnect socket on dispose — reconnect should handle it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = ref
        .watch(connectionProvider.notifier)
        .connectedDevice;

    return Scaffold(
      backgroundColor: context.appColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Topbar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConnectionChip(
                    label: connectedDevice?.name ?? 'Not Connected',
                    onTap: () => context.go('/connect'),
                  ),
                  Row(
                    children: [
                      _buildModeBtn(Icons.mouse, true),
                      const SizedBox(width: 8),
                      _buildModeBtn(Icons.open_with, false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Main Content Area
            Expanded(child: _buildActivePanel()),

            if (_currentTab == ToolbarTab.pad) const ClickButtonsBar(),
            if (_currentTab != ToolbarTab.pad) const SizedBox(height: 10),

            // Toolbar
            TrackpadToolbar(
              currentTab: _currentTab,
              onTabChanged: (tab) {
                if (tab == ToolbarTab.menu) {
                  context.push('/settings');
                  return;
                }
                setState(() => _currentTab = tab);
              },
            ),
            const HomeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _getPanelForTab(_currentTab),
    );
  }

  Widget _getPanelForTab(ToolbarTab tab) {
    switch (tab) {
      case ToolbarTab.pad:
        return const TrackpadSurface(key: ValueKey('pad'));
      case ToolbarTab.keys:
        return const KeyboardPanel(key: ValueKey('keys'));
      case ToolbarTab.media:
        return const MediaRemotePanel(key: ValueKey('media'));
      case ToolbarTab.audio:
        return const AudioHubPanel(key: ValueKey('audio'));
      default:
        return const TrackpadSurface(key: ValueKey('default'));
    }
  }

  Widget _buildModeBtn(IconData icon, bool isActive) {
    final c = context.appColors;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.18),
                ],
              )
            : null,
        color: isActive ? null : c.surface2,
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.5)
              : c.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isActive ? AppColors.primaryLight : c.text3,
      ),
    );
  }
}
