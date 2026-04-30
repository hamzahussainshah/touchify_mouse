import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/connection_history_provider.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/device_model.dart';

/// Bottom sheet showing previously-connected desktops. Tap to reconnect,
/// swipe to remove, or clear the entire history.
class ConnectionHistorySheet extends ConsumerStatefulWidget {
  const ConnectionHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: const ConnectionHistorySheet(),
      ),
    );
  }

  @override
  ConsumerState<ConnectionHistorySheet> createState() =>
      _ConnectionHistorySheetState();
}

class _ConnectionHistorySheetState
    extends ConsumerState<ConnectionHistorySheet> {
  String? _connectingId;

  Future<void> _reconnect(BuildContext sheetContext, DeviceModel device) async {
    setState(() => _connectingId = device.id);
    try {
      // Verify the agent is still reachable before navigating, so the user
      // gets a clear error instead of a black trackpad screen.
      final s = await Socket.connect(device.ipAddress, device.port)
          .timeout(const Duration(seconds: 4));
      s.destroy();

      await ref.read(connectionProvider.notifier).connect(device);
      await ref.read(connectionHistoryProvider.notifier).recordConnection(device);
      if (!sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
      sheetContext.go('/trackpad');
    } on SocketException {
      if (!sheetContext.mounted) return;
      setState(() => _connectingId = null);
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(
          content: Text('${device.name} isn\'t responding. Make sure the desktop app is open.'),
        ),
      );
    } on TimeoutException {
      if (!sheetContext.mounted) return;
      setState(() => _connectingId = null);
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        SnackBar(content: Text('${device.name} timed out.')),
      );
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: context.appColors.surface1,
        title: const Text('Clear history?'),
        content: const Text(
          'This removes all remembered desktops from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(connectionHistoryProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final history = ref.watch(connectionHistoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (sheetCtx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.surface4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Desktops',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: c.text1,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          history.isEmpty
                              ? 'Your past connections will appear here'
                              : 'Tap to reconnect',
                          style: TextStyle(fontSize: 12, color: c.text3),
                        ),
                      ],
                    ),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClear(sheetCtx),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: c.text2,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: history.isEmpty
                  ? _Empty()
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final d = history[i];
                        final connecting = _connectingId == d.id;
                        return Dismissible(
                          key: ValueKey(d.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => ref
                              .read(connectionHistoryProvider.notifier)
                              .remove(d.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.danger,
                            ),
                          ),
                          child: _HistoryTile(
                            device: d,
                            connecting: connecting,
                            onTap:
                                connecting ? null : () => _reconnect(sheetCtx, d),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final DeviceModel device;
  final bool connecting;
  final VoidCallback? onTap;

  const _HistoryTile({
    required this.device,
    required this.connecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  device.os.toLowerCase().contains('mac') ||
                          device.os.toLowerCase() == 'darwin'
                      ? Icons.apple
                      : Icons.window,
                  color: c.text1,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.text1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${device.ipAddress}:${device.port}',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.text3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryLight,
                      ),
                    )
                  : Icon(Icons.chevron_right_rounded, color: c.text2),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.history_toggle_off_rounded,
                  color: c.text3, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              'No history yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.text1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connect to a desktop and it\'ll appear here for quick reconnects.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: c.text3,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
