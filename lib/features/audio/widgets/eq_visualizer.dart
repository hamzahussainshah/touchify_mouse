import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EqVisualizer extends StatelessWidget {
  const EqVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    final bars = [0.6, 0.4, 0.8, 0.3, 0.7, 0.5];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((heightFactor) {
        return Container(
          width: 8,
          height: 40 * heightFactor,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }
}
