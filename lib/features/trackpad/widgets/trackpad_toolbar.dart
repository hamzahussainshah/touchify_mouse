import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum ToolbarTab { menu, pad, keys, media, audio }

class TrackpadToolbar extends StatelessWidget {
  final ToolbarTab currentTab;
  final ValueChanged<ToolbarTab> onTabChanged;

  const TrackpadToolbar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface0,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildToolBtn(context, ToolbarTab.menu,  Icons.menu,                'MENU'),
            _buildToolBtn(context, ToolbarTab.pad,   Icons.touch_app,           'PAD'),
            _buildToolBtn(context, ToolbarTab.keys,  Icons.keyboard,            'KEYS'),
            _buildToolBtn(context, ToolbarTab.media, Icons.play_circle_outline, 'MEDIA'),
            _buildToolBtn(context, ToolbarTab.audio, Icons.mic_none,            'AUDIO'),
          ],
        ),
      ),
    );
  }

  Widget _buildToolBtn(
      BuildContext context, ToolbarTab tab, IconData icon, String label) {
    final isActive = currentTab == tab;
    final colors = context.appColors;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTabChanged(tab),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 62,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.55)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 24,
                      color: isActive ? AppColors.primaryLight : colors.text2),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primaryLight : colors.text3,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
