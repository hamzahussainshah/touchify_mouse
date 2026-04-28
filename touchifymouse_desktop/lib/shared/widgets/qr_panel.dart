import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';

/// Displays a QR that the mobile app scans to pair with this desktop.
///
/// Payload format is consumed by `qr_connect_sheet.dart` on mobile:
///   {app, ip, tcp_port, udp_port, name, os}
///
/// The Python agent also writes a PNG QR to /tmp/touchifymouse_qr.png, but we
/// render natively here so the UI works immediately without depending on the
/// agent binary being up-to-date.
class QrPanel extends StatefulWidget {
  const QrPanel({super.key});

  @override
  State<QrPanel> createState() => _QrPanelState();
}

class _QrPanelState extends State<QrPanel> {
  Timer? _pollTimer;
  String? _ip;
  String? _payload;
  String _status = 'Detecting network…';

  static const int _tcpPort = 35901;
  static const int _udpPort = 35900;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Re-check the IP periodically — network can change (Wi-Fi switch, VPN).
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final ip = await _resolveLocalIp();
    if (!mounted) return;
    if (ip == null) {
      setState(() {
        _ip = null;
        _payload = null;
        _status = 'No network — connect to Wi-Fi';
      });
      return;
    }
    final payload = jsonEncode({
      'app': 'touchifymouse',
      'ip': ip,
      'tcp_port': _tcpPort,
      'udp_port': _udpPort,
      'name': Platform.localHostname,
      'os': Platform.operatingSystem,
    });
    setState(() {
      _ip = ip;
      _payload = payload;
      _status = 'Scan with TouchifyMouse mobile app';
    });
  }

  Future<String?> _resolveLocalIp() async {
    try {
      final ifaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      // Prefer a private-range address (most likely the Wi-Fi one).
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (_isPrivate(addr.address)) return addr.address;
        }
      }
      // Fallback: first non-loopback v4.
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isPrivate(String ip) =>
      ip.startsWith('192.168.') ||
      ip.startsWith('10.') ||
      RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(ip);

  Future<void> _copyIp() async {
    if (_ip == null) return;
    await Clipboard.setData(ClipboardData(text: _ip!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP address copied'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 208,
          height: 208,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: _payload == null
              ? _loading()
              : QrImageView(
                  data: _payload!,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF111114),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF111114),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan to Connect',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _status,
          style: const TextStyle(fontSize: 12, color: AppColors.text3),
        ),
        if (_ip != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _copyIp,
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
                    '$_ip:$_tcpPort',
                    style: const TextStyle(
                      fontFamily: 'DM Mono',
                      fontSize: 14,
                      color: AppColors.primaryDim,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 14, color: AppColors.text3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to copy — or enter IP manually on mobile',
            style: TextStyle(fontSize: 10, color: AppColors.text3),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Refresh'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
        ),
      ],
    );
  }

  Widget _loading() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(height: 10),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
        ],
      );
}
