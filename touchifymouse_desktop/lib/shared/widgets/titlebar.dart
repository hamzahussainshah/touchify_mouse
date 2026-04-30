import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../services/connected_clients_provider.dart';

class TitleBar extends ConsumerWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(connectedClientsProvider).isNotEmpty;
    final count = ref.watch(connectedClientsProvider).length;

    return DragToMoveArea(
      child: Container(
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const SizedBox(width: 70), // macOS traffic light spacing
            const Spacer(),

            // Center brand
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                ],
              ),
              margin: const EdgeInsets.only(right: 8),
              child: const Icon(Icons.mouse, size: 11, color: Colors.white),
            ),
            const Text(
              'TouchifyMouse',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.text1,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),

            // Right status pill — live
            _StatusPill(connected: connected, count: count),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool connected;
  final int count;
  const _StatusPill({required this.connected, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.text3;
    final label = connected
        ? (count == 1 ? '1 phone connected' : '$count phones connected')
        : 'Waiting for phone';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: connected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
