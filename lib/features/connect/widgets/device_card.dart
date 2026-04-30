import 'package:flutter/material.dart';
import '../../../shared/models/device_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Card representing a discovered desktop on the LAN.
/// Shows OS icon + name + IP, plus signal bars and a CONNECTED pill when
/// active. Active state uses a gradient border + soft glow so it visually
/// pops against the unconnected list.
class DeviceCard extends StatefulWidget {
  final DeviceModel device;
  final bool isActive;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final active = widget.isActive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(_pressed ? 0.985 : 1.0, _pressed ? 0.985 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        padding: EdgeInsets.all(active ? 1.5 : 0), // gradient border ring
        decoration: BoxDecoration(
          gradient: active ? AppColors.brandGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: active ? c.surface1 : c.surface2,
            border: active ? null : Border.all(color: c.border),
            borderRadius: BorderRadius.circular(active ? 18.5 : 20),
          ),
          child: Row(
            children: [
              // OS icon tile
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: active ? AppColors.brandGradient : null,
                  color: active ? null : c.surface3,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.device.os.toLowerCase() == 'macos'
                      ? Icons.apple
                      : Icons.window,
                  color: active ? Colors.white : c.text1,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.device.name,
                      style: AppTextStyles.deviceName.copyWith(
                        color: c.text1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.device.os} · ${widget.device.ipAddress}',
                      style: AppTextStyles.deviceSub.copyWith(color: c.text3),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _Pulse(),
                          SizedBox(width: 5),
                          Text(
                            'CONNECTED',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (i) {
                      final on = i < widget.device.signalStrength;
                      return Container(
                        width: 3,
                        height: 4.0 + (i * 3),
                        margin: const EdgeInsets.only(left: 2.5),
                        decoration: BoxDecoration(
                          color: on
                              ? (active
                                  ? AppColors.primaryLight
                                  : AppColors.success)
                              : c.border,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny breathing dot used in the CONNECTED pill.
class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse>
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
