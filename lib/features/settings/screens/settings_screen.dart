import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../../../shared/widgets/home_indicator.dart';
import '../../../core/providers/settings_provider.dart';

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
                _buildListTile(
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Invert Scroll Direction', style: TextStyle(color: AppColors.text1, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Natural scrolling (Mac-style)', style: TextStyle(color: AppColors.text3, fontSize: 13)),
                        ],
                      ),
                      AppToggle(value: settings.invertScroll, onChanged: notifier.setInvertScroll),
                    ],
                  ),
                ),
                _buildToggleTile('Click Buttons', settings.showClickButtons, notifier.setShowClickButtons),
                _buildToggleTile('Haptic Feedback', settings.hapticFeedback, notifier.setHapticFeedback),
                _buildToggleTile('Gyro Mouse (Pro)', settings.gyroMouse, notifier.setGyroMouse),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pointer Speed', style: AppTextStyles.bodyText),
                          Text('${settings.pointerSpeed.toStringAsFixed(1)}x', style: const TextStyle(color: AppColors.primary)),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surface3,
                          thumbColor: Colors.white,
                          overlayColor: AppColors.primary.withOpacity(0.2),
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
                _buildToggleTile('Left Handed Mode', settings.leftHanded, notifier.setLeftHanded),
                _buildToggleTile('Sound on Press', settings.soundOnPress, notifier.setSoundOnPress),
                const SizedBox(height: 32),

                // Appearance
                Text('APPEARANCE', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                _buildListTile(
                  title: 'Theme',
                  trailing: const Text('Dark (AMOLED)', style: TextStyle(color: AppColors.text3, fontSize: 13)),
                  onTap: () {},
                ),
                const SizedBox(height: 32),
                
                // About
                Text('ABOUT', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 12),
                _buildListTile(title: 'Version 1.0.0', onTap: null),
                _buildListTile(title: 'Privacy Policy', onTap: () {}),
                _buildListTile(title: 'Terms of Service', onTap: () {}),
                const SizedBox(height: 40),
              ],
            ),
          ),
          const HomeIndicator(),
        ],
      ),
    );
  }

  Widget _buildListTile({IconData? icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.text2, size: 24),
              const SizedBox(width: 16),
            ],
            Expanded(child: Text(title, style: AppTextStyles.bodyText)),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              const Icon(Icons.arrow_forward_ios, color: AppColors.text3, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyText),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
