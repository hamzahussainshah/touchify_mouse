import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../shared/models/device_model.dart';
import '../../../shared/widgets/icon_button_small.dart';
import '../widgets/device_card.dart';
import '../widgets/scanning_banner.dart';
import '../widgets/qr_connect_sheet.dart';
import '../services/mdns_discovery_service.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen> {
  final _ipController = TextEditingController();
  bool _isConnecting = false;
  bool _isScanning = true;

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

  bool isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }

  Future<void> _refreshDiscovery() async {
    setState(() {
      _isScanning = true;
    });

    ref.read(mdnsDiscoveryProvider.notifier).stop();
    await Future.delayed(const Duration(milliseconds: 300));
    ref.read(mdnsDiscoveryProvider.notifier).startScan();

    _startScanTimeout();
  }

  void _connectManually(String ip) async {
    FocusScope.of(context).unfocus();

    if (!isValidIP(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid IP address. Use format: 192.168.1.x'))
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
      final socket = await Socket.connect(ip, 35901).timeout(const Duration(seconds: 5));
      socket.destroy();
      
      ref.read(connectionProvider.notifier).connect(device);
      if (mounted) {
        context.go('/trackpad');
      }
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach $ip:35901 — is the agent running?'))
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection timed out. Check IP and try again.'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
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

    // Must pass ProviderScope parent so riverpod works inside the bottom sheet
    // (showModalBottomSheet creates a new Navigator/context tree)
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
    final devices = ref.watch(mdnsDiscoveryProvider);
    final connectionState = ref.watch(connectionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Connect',
                      style: AppTextStyles.navTitle
                          .copyWith(color: context.appColors.text1)),
                  IconButtonSmall(
                    icon: Icons.refresh,
                    onTap: _isScanning ? () {} : () => _refreshDiscovery(),
                  ),
                ],
              ),
            ),
            const ScanningBanner(),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                          ? 'Scanning for devices...'
                          : 'No devices found.\nMake sure desktop agent is running.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.appColors.text3),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isConnected = connectionState.deviceId == device.id;
                        return DeviceCard(
                          device: device,
                          isActive: isConnected,
                          onTap: () async {
                            await ref.read(connectionProvider.notifier).connect(device);
                            if (context.mounted) {
                              context.push('/trackpad');
                            }
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      style: TextStyle(color: context.appColors.text1),
                      decoration: InputDecoration(
                        hintText: 'Enter IP (192...)',
                        hintStyle: TextStyle(color: context.appColors.text3),
                        filled: true,
                        fillColor: context.appColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isConnecting ? null : () => _connectManually(_ipController.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text1,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isConnecting 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text1))
                        : const Text('Connect'),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: InkWell(
                onTap: _openQRScanner,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appColors.surface2,
                    border: Border.all(color: context.appColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.appColors.surface3,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.qr_code_scanner, color: context.appColors.text1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QR Scan to connect',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appColors.text1),
                            ),
                            const SizedBox(height: 2),
                            Text('Align code inside frame', style: AppTextStyles.deviceSub.copyWith(color: context.appColors.text3)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.appColors.text3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
