import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Hero CTA button with the brand violet→pink gradient, glow shadow, and a
/// gentle scale-on-press. Use this for primary "Get Started" / "Connect"
/// type actions instead of the default ElevatedButton.
class BrandGradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final EdgeInsetsGeometry padding;

  const BrandGradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
  });

  @override
  State<BrandGradientButton> createState() => _BrandGradientButtonState();
}

class _BrandGradientButtonState extends State<BrandGradientButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _set(true),
      onTapUp: disabled ? null : (_) => _set(false),
      onTapCancel: disabled ? null : () => _set(false),
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(_pressed ? 0.97 : 1.0, _pressed ? 0.97 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: disabled
              ? LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.accent.withValues(alpha: 0.4),
                ])
              : AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary
                        .withValues(alpha: _pressed ? 0.55 : 0.45),
                    blurRadius: _pressed ? 28 : 22,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: widget.padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: widget.loading
                ? const [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ]
                : [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(widget.icon, size: 18, color: Colors.white),
                    ],
                  ],
          ),
        ),
      ),
    );
  }
}
