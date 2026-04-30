import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/connected_clients_provider.dart';
import '../../shared/widgets/sidebar.dart';
import '../../shared/widgets/titlebar.dart';

/// Live view of phones currently paired with this desktop. Updates in real
/// time as the Python agent sees connections come and go.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(connectedClientsProvider);

    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  activeRoute: '/devices',
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
                              'Devices',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text1,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _CountPill(count: clients.length),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Phones currently paired with this desktop',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.text3,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Expanded(
                          child: clients.isEmpty
                              ? const _EmptyState()
                              : ListView.separated(
                                  itemCount: clients.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, i) =>
                                      _ClientCard(client: clients[i]),
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

// ─────────────────────────────────────────────────────────────────────────────
class _ClientCard extends StatelessWidget {
  final ConnectedClient client;
  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final dur = DateTime.now().difference(client.connectedAt);
    return Container(
      padding: const EdgeInsets.all(2), // gradient ring
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            spreadRadius: -3,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone_iphone_rounded,
                color: Colors.white,
                size: 24,
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
                        client.host,
                        style: const TextStyle(
                          fontFamily: 'DM Mono',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text1,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const _LiveDot(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connected for ${_fmtDuration(dur)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d';
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.6 * t),
                blurRadius: 4 + (4 * t),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: count > 0
            ? AppColors.brandGradient
            : null,
        color: count > 0 ? null : AppColors.surface3,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: count > 0
              ? Colors.transparent
              : AppColors.border,
        ),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: count > 0 ? Colors.white : AppColors.text3,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.phonelink_off_rounded,
              size: 36,
              color: AppColors.text3,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No phones connected',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.text1,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            width: 360,
            child: Text(
              'Open the TouchifyMouse app on your phone and scan the QR code '
              'shown on the dashboard. Make sure both devices are on the same '
              'Wi-Fi network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.text3,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
