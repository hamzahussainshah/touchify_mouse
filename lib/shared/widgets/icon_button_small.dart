import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class IconButtonSmall extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const IconButtonSmall({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.2) : AppColors.surface3,
          border: Border.all(
            color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.primaryLight : AppColors.text1,
        ),
      ),
    );
  }
}
