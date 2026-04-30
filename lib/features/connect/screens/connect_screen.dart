import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/connection_history_provider.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../shared/models/device_model.dart';
import '../../../shared/widgets/icon_button_small.dart';
import '../widgets/connection_history_sheet.dart';
import '../widgets/device_card.dart';
import '../widgets/qr_connect_sheet.dart';
import '../services/mdns_discovery_service.dart';
import '../../desktop_invite/widgets/get_desktop_sheet.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _ipController = TextEditingController();
  bool _isConnecting = false;
  bool _isScanning = true;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _startScanTimeout();
  }

  void _startScanTimeout() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isScanning = false);
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }

  Future<void> _refreshDiscovery() async {
    setState(() => _isScanning = true);
    ref.read(mdnsDiscoveryProvider.notifier).stop();
    await Future.delayed(const Duration(milliseconds: 300));
    ref.read(mdnsDiscoveryProvider.notifier).startScan();
    _startScanTimeout();
  }

  Future<void> _connectManually(String ip) async {
    FocusScope.of(context).unfocus();

    if (!_isValidIP(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid IP address. Use format: 192.168.1.x'),
        ),
      );
      return;
    }

    final device = DeviceModel(
      id: '$ip:35901',
      name: 'Manual Device',
      ipAddress: ip,
      port: 35901,
      os: 'unknown',
    );

    setState(() => _isConnecting = true);
    try {
      final socket = await Socket.connect(ip, 35901)
          .timeout(const Duration(seconds: 5));
      socket.destroy();
      ref.read(connectionProvider.notifier).connect(device);
      ref.read(connectionHistoryProvider.notifier).recordConnection(device);
      if (mounted) context.go('/trackpad');
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach $ip:35901 — is the agent running?')),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection timed out. Check IP and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _openQRScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Camera permission is required to scan QR code'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    final container = ProviderScope.containerOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => UncontrolledProviderScope(
        container: container,
        child: const QrConnectSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final devices = ref.watch(mdnsDiscoveryProvider);
    final connectionState = ref.watch(connectionProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Subtle ambient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.scaffold, c.surface0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect',
                              style: AppTextStyles.navTitle.copyWith(
                                color: c.text1,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pair with your desktop in seconds',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButtonSmall(
                        icon: Icons.history_rounded,
                        onTap: () => ConnectionHistorySheet.show(context),
                      ),
                      const SizedBox(width: 6),
                      IconButtonSmall(
                        icon: Icons.refresh,
                        onTap: _isScanning ? () {} : () => _refreshDiscovery(),
                      ),
                    ],
                  ),
                ),

                // ⭐️ Featured QR card (recommended path)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: _FeaturedQrCard(onTap: _openQRScanner),
                ),

                // Section header for device list
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'NEARBY ON WI-FI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: c.text3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isScanning)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primaryLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Device list / empty state
                Expanded(
                  child: devices.isEmpty
                      ? _EmptyDeviceState(scanning: _isScanning)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          itemCount: devices.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            final isConnected =
                                connectionState.deviceId == device.id;
                            return DeviceCard(
                              device: device,
                              isActive: isConnected,
                              onTap: () async {
                                await ref
                                    .read(connectionProvider.notifier)
                                    .connect(device);
                                await ref
                                    .read(connectionHistoryProvider.notifier)
                                    .recordConnection(device);
                                if (context.mounted) {
                                  context.push('/trackpad');
                                }
                              },
                            );
                          },
                        ),
                ),

                // Advanced (manual IP) — collapsible
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                      icon: Icon(
                        _showAdvanced ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: c.text3,
                      ),
                      label: Text(
                        _showAdvanced ? 'Hide manual entry' : 'Enter IP manually',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.text3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: !_showAdvanced
                      ? const SizedBox.shrink()
                      : Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ipController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  style: TextStyle(color: c.text1),
                                  decoration: InputDecoration(
                                    hintText: '192.168.1.x',
                                    hintStyle: TextStyle(color: c.text3),
                                    filled: true,
                                    fillColor: c.surface2,
                                    prefixIcon:
                                        Icon(Icons.language, color: c.text3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isConnecting
                                      ? null
                                      : () => _connectManually(
                                            _ipController.text.trim(),
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isConnecting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Connect'),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//   Featured QR card — recommended pairing flow, with gradient border + glow
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedQrCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FeaturedQrCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(2), // gradient border thickness
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface1,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Scan QR Code',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: c.text1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'EASIEST',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open the desktop app and scan the QR code shown',
                        style: TextStyle(fontSize: 13, color: c.text3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.text2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EmptyDeviceState extends StatelessWidget {
  final bool scanning;
  const _EmptyDeviceState({required this.scanning});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(
                scanning ? Icons.wifi_find : Icons.wifi_off,
                color: c.text3,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              scanning ? 'Looking for desktops...' : 'No desktops found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.text1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              scanning
                  ? 'Make sure both devices are on the same Wi-Fi'
                  : 'Open the desktop companion app, or get it below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: c.text3,
                height: 1.45,
              ),
            ),
            // Only show the install CTA after the timeout — while scanning we
            // don't want to suggest the user is missing the desktop app.
            if (!scanning) ...[
              const SizedBox(height: 22),
              _GetDesktopCta(onTap: () => GetDesktopSheet.show(context)),
            ],
          ],
        ),
      ),
    );
  }
}

class _GetDesktopCta extends StatelessWidget {
  final VoidCallback onTap;
  const _GetDesktopCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.32),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.desktop_mac_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get the desktop app',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Required to pair · Mac available',
                      style: TextStyle(fontSize: 11, color: c.text3),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Icon(Icons.chevron_right_rounded, color: c.text2, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
