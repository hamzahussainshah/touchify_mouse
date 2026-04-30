import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/brand_gradient_button.dart';
import '../widgets/laptop_illustration.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient gradient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.scaffold, c.surface0],
                ),
              ),
            ),
          ),
          // Top-right violet glow
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(
              color: AppColors.primary.withValues(alpha: 0.35),
              size: 360,
            ),
          ),
          // Bottom-left pink glow
          Positioned(
            bottom: -120,
            left: -100,
            child: _Glow(
              color: AppColors.accent.withValues(alpha: 0.22),
              size: 320,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top brand mark
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _BrandMark(),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      LaptopIllustration(),
                    ],
                  ),
                ),

                // Bottom card
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.surface1.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: c.borderMid),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Pill(),
                      const SizedBox(height: 14),
                      Text(
                        'Your phone is now a',
                        style: AppTextStyles.h1.copyWith(
                          color: c.text1,
                          height: 1.1,
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.brandGradient.createShader(rect),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'magical trackpad',
                          style: AppTextStyles.h1.copyWith(
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Control your Mac or Windows PC with zero latency. '
                        'Just install the desktop companion and scan a QR.',
                        style: AppTextStyles.bodySub.copyWith(color: c.text2),
                      ),
                      const SizedBox(height: 22),
                      // Pager dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Dot(active: true),
                          const SizedBox(width: 6),
                          _Dot(active: false),
                          const SizedBox(width: 6),
                          _Dot(active: false),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: BrandGradientButton(
                          label: 'Get Started',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => context.push('/setup'),
                        ),
                      ),
                    ],
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

class _Pill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.accent.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.success, blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'WIRELESS · LOW-LATENCY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.primaryDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(
        gradient: active ? AppColors.brandGradient : null,
        color: active ? null : context.appColors.surface4,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(Icons.mouse, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          'TouchifyMouse',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: context.appColors.text1,
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
