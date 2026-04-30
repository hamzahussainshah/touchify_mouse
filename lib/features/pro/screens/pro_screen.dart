import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/brand_gradient_button.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  String _plan = 'Lifetime';

  static const _features = [
    ('No Ads', Icons.block_rounded),
    ('Unlimited Devices', Icons.devices_rounded),
    ('Clipboard Sync', Icons.content_paste_rounded),
    ('Custom Gestures & Shortcuts', Icons.gesture_rounded),
    ('Gyro Mouse Control', Icons.screen_rotation_rounded),
    ('Studio Audio (48 kHz · Voice Focus)', Icons.mic_external_on_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return Scaffold(
      body: Stack(
        children: [
          // Backdrop
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
          // Top-center violet glow
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: c.text2),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 8),
                      // Hero icon
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.55),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Headline
                      Center(
                        child: ShaderMask(
                          shaderCallback: (rect) =>
                              AppColors.brandGradient.createShader(rect),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'TouchifyMouse Pro',
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Unlock the ultimate trackpad experience and support indie development.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySub.copyWith(color: c.text2),
                      ),
                      const SizedBox(height: 32),

                      // Feature list
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.surface1.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          children: [
                            for (final (i, f) in _features.indexed) ...[
                              _FeatureRow(text: f.$1, icon: f.$2),
                              if (i != _features.length - 1)
                                Divider(
                                  height: 16,
                                  color: c.border,
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Plans
                      _PlanCard(
                        title: 'Lifetime',
                        price: r'$9.99',
                        subtitle: 'One time · own it forever',
                        badge: 'BEST VALUE',
                        selected: _plan == 'Lifetime',
                        onTap: () => setState(() => _plan = 'Lifetime'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _PlanCard(
                              title: 'Yearly',
                              price: r'$14.99',
                              subtitle: '/year',
                              selected: _plan == 'Yearly',
                              onTap: () => setState(() => _plan = 'Yearly'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PlanCard(
                              title: 'Monthly',
                              price: r'$1.99',
                              subtitle: '/month',
                              selected: _plan == 'Monthly',
                              onTap: () => setState(() => _plan = 'Monthly'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Sticky CTA footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: c.scaffold.withValues(alpha: 0.85),
                    border: Border(
                      top: BorderSide(color: c.border),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: BrandGradientButton(
                          label: 'Get $_plan · ${_priceFor(_plan)}',
                          onPressed: () {
                            // TODO: kick off in_app_purchase flow
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '7-day free trial on subscriptions · Cancel anytime',
                        style: TextStyle(fontSize: 11, color: c.text3),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Restore Purchase',
                          style: TextStyle(color: c.text2, fontSize: 12),
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

  String _priceFor(String plan) {
    return switch (plan) {
      'Lifetime' => r'$9.99',
      'Yearly' => r'$14.99',
      _ => r'$1.99',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FeatureRow({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.22),
                AppColors.accent.withValues(alpha: 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.text1,
            ),
          ),
        ),
        Icon(Icons.check_rounded, color: AppColors.success, size: 18),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(selected ? 1.5 : 0),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.brandGradient : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: selected ? c.surface1 : c.surface2,
            border: selected ? null : Border.all(color: c.border),
            borderRadius: BorderRadius.circular(selected ? 16.5 : 18),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppColors.primaryLight : c.text2,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: c.text1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: c.text3),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  top: -8,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
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
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
