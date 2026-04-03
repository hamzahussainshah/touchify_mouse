import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../shared/models/device_model.dart';
import '../../../shared/widgets/icon_button_small.dart';

class QrConnectSheet extends ConsumerStatefulWidget {
  const QrConnectSheet({super.key});

  @override
  ConsumerState<QrConnectSheet> createState() => _QrConnectSheetState();
}

class _QrConnectSheetState extends ConsumerState<QrConnectSheet>
    with WidgetsBindingObserver {
  // Create controller in initState, not as a field, to avoid lifecycle issues
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onQRDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    try {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(rawValue) as Map<String, dynamic>;
      } catch (_) {
        _showSnack('Invalid QR code — not JSON.');
        _scannerController.start();
        setState(() => _isProcessing = false);
        return;
      }

      if (data['app'] != 'touchifymouse') {
        _showSnack('Not a TouchifyMouse QR code.');
        _scannerController.start();
        setState(() => _isProcessing = false);
        return;
      }

      final ip = data['ip'] as String?;
      if (ip == null || ip.isEmpty) {
        _showSnack('QR code missing IP address.');
        _scannerController.start();
        setState(() => _isProcessing = false);
        return;
      }

      final port = (data['tcp_port'] as int?) ?? 35901;

      final device = DeviceModel(
        id: '$ip:$port',
        name: (data['name'] as String?) ?? 'Desktop',
        ipAddress: ip,
        port: port,
        os: (data['os'] as String?) ?? 'unknown',
      );

      if (!mounted) return;
      Navigator.pop(context);

      ref.read(connectionProvider.notifier).connect(device);

      // Small delay so connection state propagates before navigating
      Future.microtask(() {
        if (mounted) context.go('/trackpad');
      });
    } catch (e) {
      _showSnack('Error processing QR code: $e');
      _scannerController.start();
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.amoled,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Scan QR Code', style: AppTextStyles.navTitle),
                IconButtonSmall(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Point camera at the QR code shown in the TouchifyMouse desktop app',
              style: AppTextStyles.bodySub,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Camera viewfinder
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onQRDetected,
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  color: AppColors.danger, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'Camera error: ${error.errorDetails?.message ?? error.errorCode.name}',
                                style: const TextStyle(
                                    color: AppColors.text2, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => _scannerController.start(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Viewfinder frame
                IgnorePointer(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.primary, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                // Corner accents for style
                IgnorePointer(
                  child: _CornerAccents(size: 250),
                ),
                // Processing overlay
                if (_isProcessing)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface1.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 3),
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

/// Decorative corner accent marks around the viewfinder
class _CornerAccents extends StatelessWidget {
  final double size;
  const _CornerAccents({required this.size});

  @override
  Widget build(BuildContext context) {
    const len = 24.0;
    const w = 3.0;
    const color = AppColors.primary;


    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(top: 0, left: 0,
            child: Container(width: len, height: w, color: color)),
          Positioned(top: 0, left: 0,
            child: Container(width: w, height: len, color: color)),
          // Top-right
          Positioned(top: 0, right: 0,
            child: Container(width: len, height: w, color: color)),
          Positioned(top: 0, right: 0,
            child: Container(width: w, height: len, color: color)),
          // Bottom-left
          Positioned(bottom: 0, left: 0,
            child: Container(width: len, height: w, color: color)),
          Positioned(bottom: 0, left: 0,
            child: Container(width: w, height: len, color: color)),
          // Bottom-right
          Positioned(bottom: 0, right: 0,
            child: Container(width: len, height: w, color: color)),
          Positioned(bottom: 0, right: 0,
            child: Container(width: w, height: len, color: color)),
        ],
      ),
    );
  }
}
