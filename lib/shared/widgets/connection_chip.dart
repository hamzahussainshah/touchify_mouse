import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/connection_provider.dart';
import '../../shared/models/connection_state.dart';

class ConnectionChip extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback onTap;

  const ConnectionChip({super.key, required this.label, required this.onTap});

  @override
  ConsumerState<ConnectionChip> createState() => _ConnectionChipState();
}

class _ConnectionChipState extends ConsumerState<ConnectionChip> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getDotColor(ConnectionStatus status) {
    return switch (status) {
      ConnectionStatus.connected    => AppColors.success,
      ConnectionStatus.reconnecting => AppColors.warning,
      ConnectionStatus.failed       => AppColors.danger,
      ConnectionStatus.error        => AppColors.danger,
      _                             => AppColors.surface4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);
    final status = connectionState.status;
    final color = _getDotColor(status);
    final isReconnecting = status == ConnectionStatus.reconnecting;
    final isConnected = status == ConnectionStatus.connected;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final opacity = isReconnecting ? _animController.value : 1.0;
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withOpacity(opacity),
                    shape: BoxShape.circle,
                    boxShadow: (isConnected || isReconnecting) ? [
                      BoxShadow(color: color.withOpacity(opacity * 0.5), blurRadius: 4, spreadRadius: 1)
                    ] : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              isReconnecting ? 'Reconnecting...' : widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (isConnected || isReconnecting) ? color : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
