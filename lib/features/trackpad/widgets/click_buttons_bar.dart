import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/trackpad_socket_service.dart';
import '../../../core/theme/app_colors.dart';

/// Tactile click-button row beneath the trackpad surface.
///
/// Three buttons: Left, Middle (scroll/center-click), Right. Each is a
/// rounded pill with icon + label, scales down on press, and uses the brand
/// gradient when held to feel responsive.
class ClickButtonsBar extends StatelessWidget {
  const ClickButtonsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _ClickButton(
                label: 'L',
                icon: Icons.arrow_back_ios_new_rounded,
                isLeft: true,
                onTap: () {
                  HapticFeedback.lightImpact();
                  TrackpadSocketService.instance.sendClick('left');
                },
                onLongPressStart: (_) {
                  HapticFeedback.heavyImpact();
                  TrackpadSocketService.instance.sendMouseDown('left');
                },
                onLongPressEnd: (_) {
                  TrackpadSocketService.instance.sendMouseUp('left');
                },
              ),
            ),
            const SizedBox(width: 8),
            // Middle / scroll click — narrow center pill
            SizedBox(
              width: 64,
              child: _ClickButton(
                label: '',
                icon: Icons.unfold_more_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  TrackpadSocketService.instance.sendClick('middle');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: _ClickButton(
                label: 'R',
                icon: Icons.arrow_forward_ios_rounded,
                isLeft: false,
                onTap: () {
                  HapticFeedback.lightImpact();
                  TrackpadSocketService.instance.sendClick('right');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClickButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool? isLeft;
  final VoidCallback onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;

  const _ClickButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isLeft,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<_ClickButton> createState() => _ClickButtonState();
}

class _ClickButtonState extends State<_ClickButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isCenter = widget.isLeft == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPressStart: (e) {
        _setPressed(true);
        widget.onLongPressStart?.call(e);
      },
      onLongPressEnd: (e) {
        _setPressed(false);
        widget.onLongPressEnd?.call(e);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _pressed ? 0.965 : 1.0,
            _pressed ? 0.965 : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _pressed
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                )
              : null,
          color: _pressed ? null : c.surface2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed ? Colors.transparent : c.border,
            width: 1,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: _content(c, isCenter),
      ),
    );
  }

  Widget _content(AppColorScheme c, bool isCenter) {
    final iconColor = _pressed ? Colors.white : AppColors.primaryLight;
    final labelColor = _pressed ? Colors.white : c.text2;

    if (isCenter) {
      return Center(
        child: Icon(widget.icon, size: 22, color: iconColor),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLeft == true) ...[
          Icon(widget.icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: labelColor,
            letterSpacing: 1.2,
          ),
        ),
        if (widget.isLeft == false) ...[
          const SizedBox(width: 8),
          Icon(widget.icon, size: 14, color: iconColor),
        ],
      ],
    );
  }
}
