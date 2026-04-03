import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class InputLevelBar extends StatelessWidget {
  final double level; // 0.0 to 1.0

  const InputLevelBar({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: level,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.primary, AppColors.warning],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
