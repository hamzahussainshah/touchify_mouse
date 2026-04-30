import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/sidebar.dart';
import '../../shared/widgets/titlebar.dart';

/// Diagnostic-y view: which interfaces this Mac is broadcasting on, the
/// agent's TCP/UDP ports, and how the phone should be configured to find it.
class NetworkScanScreen extends StatefulWidget {
  const NetworkScanScreen({super.key});

  @override
  State<NetworkScanScreen> createState() => _NetworkScanScreenState();
}

class _NetworkScanScreenState extends State<NetworkScanScreen> {
  static const _tcpPort = 35901;
  static const _udpPort = 35900;
  static const _mdnsService = '_touchifymouse._tcp';

  List<_Iface> _interfaces = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _scanning = true);
    try {
      final list = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      final out = <_Iface>[];
      for (final iface in list) {
        for (final addr in iface.addresses) {
          out.add(_Iface(name: iface.name, ip: addr.address));
        }
      }
      out.sort((a, b) {
        // Prefer obvious Wi-Fi-looking interfaces first.
        int score(_Iface i) {
          final n = i.name.toLowerCase();
          if (n.contains('wi-fi') || n == 'en0' || n.contains('wlan')) return 0;
          if (n.contains('eth') || n.startsWith('en')) return 1;
          return 2;
        }
        return score(a).compareTo(score(b));
      });
      if (mounted) setState(() => _interfaces = out);
    } catch (_) {
      // Silently keep stale list.
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 2),
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
                  activeRoute: '/scan',
                  onNavigate: (r) => context.go(r),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.surface0,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Network',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text1,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const Spacer(),
                            _RefreshButton(
                              busy: _scanning,
                              onTap: _refresh,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How your phone discovers this desktop on your network',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text3,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Status card ──
                        _StatusCard(
                          tcpPort: _tcpPort,
                          udpPort: _udpPort,
                          service: _mdnsService,
                        ),
                        const SizedBox(height: 20),

                        // ── Interfaces list ──
                        const _SectionLabel('LISTENING ON'),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _interfaces.isEmpty
                              ? const _EmptyIfaces()
                              : ListView.separated(
                                  itemCount: _interfaces.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final iface = _interfaces[i];
                                    return _IfaceRow(
                                      iface: iface,
                                      port: _tcpPort,
                                      onCopy: _copy,
                                    );
                                  },
                                ),
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
}

class _Iface {
  final String name;
  final String ip;
  _Iface({required this.name, required this.ip});
}

// ─────────────────────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final int tcpPort;
  final int udpPort;
  final String service;
  const _StatusCard({
    required this.tcpPort,
    required this.udpPort,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatTile(
            icon: Icons.lan_rounded,
            label: 'TCP commands',
            value: tcpPort.toString(),
          ),
          _Divider(),
          _StatTile(
            icon: Icons.electric_bolt_rounded,
            label: 'UDP mouse',
            value: udpPort.toString(),
          ),
          _Divider(),
          _StatTile(
            icon: Icons.broadcast_on_personal_rounded,
            label: 'mDNS service',
            value: service,
            mono: false,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.accent.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: mono ? 'DM Mono' : null,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text1,
                    letterSpacing: mono ? 0.5 : -0.2,
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

// ─────────────────────────────────────────────────────────────────────────────
class _IfaceRow extends StatelessWidget {
  final _Iface iface;
  final int port;
  final void Function(String) onCopy;

  const _IfaceRow({
    required this.iface,
    required this.port,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final addr = '${iface.ip}:$port';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_iconFor(iface.name), color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  iface.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  addr,
                  style: const TextStyle(
                    fontFamily: 'DM Mono',
                    fontSize: 13,
                    color: AppColors.primaryDim,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => onCopy(addr),
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Copy'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text2,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('wi-fi') || n == 'en0' || n.contains('wlan')) {
      return Icons.wifi_rounded;
    }
    if (n.contains('eth') || n.startsWith('en')) {
      return Icons.settings_ethernet_rounded;
    }
    if (n.contains('bridge') || n.contains('utun') || n.contains('tun')) {
      return Icons.vpn_lock_rounded;
    }
    return Icons.lan_rounded;
  }
}

class _RefreshButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;
  const _RefreshButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryLight,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.text2,
                ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.text3,
          letterSpacing: 1.4,
        ),
      );
}

class _EmptyIfaces extends StatelessWidget {
  const _EmptyIfaces();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.signal_wifi_off_rounded,
              color: AppColors.text3, size: 36),
          SizedBox(height: 10),
          Text(
            'No active network interfaces',
            style: TextStyle(color: AppColors.text2, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Connect to Wi-Fi and click Refresh.',
            style: TextStyle(color: AppColors.text3, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
