import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../../shared/widgets/home_indicator.dart';
import '../../../core/providers/settings_provider.dart';
import '../../desktop_invite/widgets/get_desktop_sheet.dart';

// Theme options shown in the picker
const _kThemes = [
  ('amoled', 'AMOLED', Icons.brightness_1),
  ('dark',   'Dark',   Icons.brightness_3),
  ('light',  'Light',  Icons.brightness_5),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Pro Banner
                GestureDetector(
                  onTap: () => context.push('/pro'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF818CF8), Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade to TouchDesk Pro',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Unlock gyro mouse, custom workflows & more',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Account
                Text('ACCOUNT', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                _buildListTile(context,
                  icon: Icons.g_mobiledata,
                  title: 'Sign in with Google',
                  onTap: () {},
                ),
                const SizedBox(height: 32),

                // Mouse & Interface
                Text('MOUSE & INTERFACE', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invert Scroll Direction',
                              style: TextStyle(color: context.appColors.text1, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Natural scrolling (Mac-style)',
                              style: TextStyle(color: context.appColors.text3, fontSize: 13)),
                        ],
                      ),
                      AppToggle(value: settings.invertScroll, onChanged: notifier.setInvertScroll),
                    ],
                  ),
                ),
                _buildToggleTile(context, 'Click Buttons', settings.showClickButtons, notifier.setShowClickButtons),
                _buildToggleTile(context, 'Haptic Feedback', settings.hapticFeedback, notifier.setHapticFeedback),
                _buildToggleTile(context, 'Gyro Mouse (Pro)', settings.gyroMouse, notifier.setGyroMouse),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pointer Speed',
                              style: AppTextStyles.bodyText.copyWith(
                                  color: context.appColors.text3)),
                          Text('${settings.pointerSpeed.toStringAsFixed(1)}x',
                              style: const TextStyle(color: AppColors.primary)),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: context.appColors.surface3,
                          thumbColor: Colors.white,
                          overlayColor: AppColors.primary.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: settings.pointerSpeed,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          onChanged: notifier.setPointerSpeed,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildToggleTile(context, 'Left Handed Mode', settings.leftHanded, notifier.setLeftHanded),
                _buildToggleTile(context, 'Sound on Press', settings.soundOnPress, notifier.setSoundOnPress),
                const SizedBox(height: 32),

                // Appearance
                Text('APPEARANCE', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: AppTextStyles.bodyText),
                      const SizedBox(height: 12),
                      Row(
                        children: _kThemes.map(((String id, String label, IconData icon) t) {
                          final isSelected = settings.theme == t.$1;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => notifier.setTheme(t.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : context.appColors.surface3,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : context.appColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(t.$3,
                                        size: 22,
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : context.appColors.text3),
                                    const SizedBox(height: 6),
                                    Text(
                                      t.$2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : context.appColors.text3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Desktop app
                Text('DESKTOP APP', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                _buildListTile(
                  context,
                  icon: Icons.desktop_mac,
                  title: 'Get the desktop app',
                  onTap: () => GetDesktopSheet.show(context),
                ),
                const SizedBox(height: 32),

                // About
                Text('ABOUT', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                _buildListTile(context, title: 'Version 1.0.0', onTap: null),
                _buildListTile(context, title: 'Privacy Policy', onTap: () {}),
                _buildListTile(context, title: 'Terms of Service', onTap: () {}),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const HomeIndicator(),
        ],
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, {
      IconData? icon,
      required String title,
      Widget? trailing,
      VoidCallback? onTap,
  }) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: c.text2, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(
                child: Text(title,
                    style: AppTextStyles.bodyText.copyWith(color: c.text3))),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              Icon(Icons.arrow_forward_ios, color: c.text3, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(
      BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTextStyles.bodyText
                  .copyWith(color: context.appColors.text3)),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
