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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolBtn(ToolbarTab.menu, Icons.menu, 'MENU'),
          _buildToolBtn(ToolbarTab.pad, Icons.touch_app, 'PAD'),
          _buildToolBtn(ToolbarTab.keys, Icons.keyboard, 'KEYS'),
          _buildToolBtn(ToolbarTab.media, Icons.play_circle_outline, 'MEDIA'),
          _buildToolBtn(ToolbarTab.audio, Icons.mic_none, 'AUDIO'),
        ],
      ),
    );
  }

  Widget _buildToolBtn(ToolbarTab tab, IconData icon, String label) {
    final isActive = currentTab == tab;
    return GestureDetector(
      onTap: () => onTabChanged(tab),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? AppColors.primaryLight : AppColors.text3),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primaryDim : AppColors.text3,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
