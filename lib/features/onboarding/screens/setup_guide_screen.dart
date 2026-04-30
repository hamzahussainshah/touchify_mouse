import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_gradient_button.dart';
import '../../desktop_invite/widgets/get_desktop_sheet.dart';

class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

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
          Positioned(
            top: -120,
            right: -100,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header — back button + title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: c.text1),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: c.text1,
                                letterSpacing: -0.4,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Three steps to get going',
                              style: TextStyle(fontSize: 13, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Steps
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      _StepCard(
                        number: 1,
                        active: true,
                        title: 'Install the desktop app',
                        description:
                            'Download TouchifyMouse for your computer and open it.',
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _OsChip(icon: Icons.apple, label: 'macOS'),
                                const SizedBox(width: 10),
                                _OsChip(icon: Icons.window, label: 'Windows'),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _ShareButton(
                              onTap: () => GetDesktopSheet.show(context),
                            ),
                          ],
                        ),
                      ),
                      _StepCard(
                        number: 2,
                        active: false,
                        title: 'Same Wi-Fi network',
                        description:
                            'Phone and computer must be on the same network.',
                      ),
                      _StepCard(
                        number: 3,
                        active: false,
                        title: 'Scan the QR code',
                        description:
                            'Tap "Connect" below, then scan the QR shown in the desktop app.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                // Bottom CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: BrandGradientButton(
                      label: 'Continue to Connect',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => context.go('/connect'),
                    ),
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
class _StepCard extends StatelessWidget {
  final int number;
  final bool active;
  final String title;
  final String description;
  final Widget? body;
  final bool isLast;

  const _StepCard({
    required this.number,
    required this.active,
    required this.title,
    required this.description,
    this.body,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator + connector line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.brandGradient : null,
                    color: active ? null : c.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? Colors.transparent : c.borderMid,
                      width: 1,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: active ? Colors.white : c.text3,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Card body
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: active
                      ? c.surface1
                      : c.surface1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : c.border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 20,
                            spreadRadius: -4,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: active ? c.text1 : c.text2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: c.text3,
                        height: 1.45,
                      ),
                    ),
                    if (body != null) body!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _OsChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.accent.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.32),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.text1,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.ios_share_rounded,
                size: 16,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Share download link',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
