import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TouchRipple extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const TouchRipple({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<TouchRipple> createState() => _TouchRippleState();
}

class _TouchRippleState extends State<TouchRipple> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 25,
      top: widget.position.dy - 25,
      child: IgnorePointer(
        child: SizedBox(
          width: 50,
          height: 50,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 0.3 + (_controller.value * 2.2);
              final opacity = 1.0 - _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity * 0.8,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: scale * 0.7,
                    child: Opacity(
                      opacity: opacity * 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryLight.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(opacity),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withOpacity(opacity * 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
