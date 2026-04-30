import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Stylised laptop + phone illustration shown on the welcome screen.
/// Uses the brand palette and simulates a wireless link with a glowing arc.
class LaptopIllustration extends StatefulWidget {
  const LaptopIllustration({super.key});

  @override
  State<LaptopIllustration> createState() => _LaptopIllustrationState();
}

class _LaptopIllustrationState extends State<LaptopIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
        ..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Soft ambient glow behind the whole scene
          Positioned(
            top: 0,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Laptop screen ──
          Positioned(
            top: 6,
            child: Container(
              width: 200,
              height: 124,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2D2650), Color(0xFF1B1632)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF15102A),
                      AppColors.primary.withValues(alpha: 0.18),
                      const Color(0xFF231D40),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  // Animated connection dot — gently breathes
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) {
                      final t = (1 - (_pulse.value - 0.5).abs() * 2).clamp(0.0, 1.0);
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.5 + 0.4 * t),
                              blurRadius: 10 + 8 * t,
                              spreadRadius: 1 + 2 * t,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // ── Laptop base ──
          Positioned(
            bottom: 36,
            child: Container(
              width: 220,
              height: 11,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2D2650), Color(0xFF15102A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // ── Phone (right side) ──
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              width: 44,
              height: 72,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF15102A),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Container(
                        height: 2,
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                      ),
                      Container(
                        height: 2,
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                      ),
                      Container(
                        height: 2,
                        color: AppColors.primaryLight.withValues(alpha: 0.25),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Wi-Fi arc between them ──
          Positioned(
            top: 70,
            child: ShaderMask(
              shaderCallback: (rect) =>
                  AppColors.brandGradient.createShader(rect),
              blendMode: BlendMode.srcIn,
              child: const Icon(
                Icons.wifi_tethering,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
