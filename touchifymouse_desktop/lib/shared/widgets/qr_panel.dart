import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class QrPanel extends StatefulWidget {
  const QrPanel({super.key});

  @override
  State<QrPanel> createState() => _QrPanelState();
}

class _QrPanelState extends State<QrPanel> {
  Timer? _refreshTimer;
  Uint8List? _qrBytes;
  String _statusText = 'Starting agent…';
  int _retryCount = 0;

  String get _qrPath => Platform.isMacOS || Platform.isLinux
      ? '/tmp/touchifymouse_qr.png'
      : '${Platform.environment['TEMP'] ?? r'C:\Temp'}/touchifymouse_qr.png';

  @override
  void initState() {
    super.initState();
    _tryLoad();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tryLoad());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Read raw bytes — avoids macOS sandbox image caching issues with File paths
  Future<void> _tryLoad() async {
    try {
      final f = File(_qrPath);
      if (!f.existsSync()) {
        _retryCount++;
        if (mounted) setState(() => _statusText = 'Waiting for agent… ($_retryCount s)');
        return;
      }
      final bytes = await f.readAsBytes();
      if (bytes.length < 100) return; // still being written
      if (mounted) {
        setState(() {
          _qrBytes = bytes;
          _statusText = 'Scan with TouchifyMouse mobile app';
          _refreshTimer?.cancel();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statusText = 'Error: $e');
    }
  }

  Future<String?> _getIP() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  void _copyIp(BuildContext ctx) async {
    final ip = await _getIP();
    if (ip == null) return;
    await Clipboard.setData(ClipboardData(text: ip));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('IP address copied'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getIP(),
      builder: (context, snapshot) {
        final ip = snapshot.data;
        return _buildContent(context, ip);
      },
    );
  }

  Widget _buildContent(BuildContext context, String? ip) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // QR Code frame
        Container(
          width: 192,
          height: 192,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: _qrBytes != null
              ? Image.memory(_qrBytes!, fit: BoxFit.contain)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                    const SizedBox(height: 10),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan to Connect',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1),
        ),
        const SizedBox(height: 4),
        Text(_statusText, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        if (ip != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copyIp(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderMid),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ip,
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 14,
                      color: AppColors.primaryDim,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 14, color: AppColors.text3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Tap to copy IP', style: TextStyle(fontSize: 10, color: AppColors.text3)),
        ],
        const SizedBox(height: 12),
        if (_qrBytes != null)
          TextButton.icon(
            onPressed: () { setState(() { _qrBytes = null; }); _tryLoad(); },
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh QR'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
          ),
      ],
    );
  }
}

