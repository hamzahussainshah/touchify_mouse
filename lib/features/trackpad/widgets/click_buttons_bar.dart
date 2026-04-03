// lib/features/trackpad/widgets/click_buttons_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/trackpad_socket_service.dart';
import '../../../core/theme/app_colors.dart';

class ClickButtonsBar extends StatelessWidget {
  const ClickButtonsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // LEFT CLICK
          Expanded(
            flex: 5,
            child: _ClickButton(
              label: 'Left',
              icon: Icons.mouse_outlined,
              onTap: () {
                print('[Button] LEFT CLICK tapped');
                HapticFeedback.lightImpact();
                TrackpadSocketService.instance.sendClick('left');
              },
              onLongPressStart: (_) {
                print('[Button] LEFT MOUSEDOWN');
                HapticFeedback.heavyImpact();
                TrackpadSocketService.instance.sendMouseDown('left');
              },
              onLongPressEnd: (_) {
                print('[Button] LEFT MOUSEUP');
                TrackpadSocketService.instance.sendMouseUp('left');
              },
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          
          // SCROLL (middle)
          SizedBox(
            width: 48,
            child: _ClickButton(
              label: '',
              icon: Icons.unfold_more,
              onTap: () {
                HapticFeedback.selectionClick();
                TrackpadSocketService.instance.sendClick('middle');
              },
              borderRadius: BorderRadius.zero,
            ),
          ),
          
          // RIGHT CLICK
          Expanded(
            flex: 5,
            child: _ClickButton(
              label: 'Right',
              icon: Icons.mouse_outlined,
              onTap: () {
                print('[Button] RIGHT CLICK tapped');
                HapticFeedback.lightImpact();
                TrackpadSocketService.instance.sendClick('right');
              },
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;
  final BorderRadius borderRadius;

  const _ClickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.borderRadius,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label.isNotEmpty) ...[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text3,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
