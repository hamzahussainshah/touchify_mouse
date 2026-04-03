import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class NumpadGrid extends StatelessWidget {
  final Function(String keycode) onKeyPress;

  const NumpadGrid({super.key, required this.onKeyPress});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> rows = {
      'row1': ['F1', 'F2', 'F3', 'F4'],
      'row2': ['F5', 'F6', 'F7', 'F8'],
      'row3': ['F9', 'F10', 'F11', 'F12'],
      'row4': ['7', '8', '9', '⌫'],
      'row5': ['4', '5', '6', '⏎'],
      'row6': ['1', '2', '3', 'Esc'],
      'row7': ['0', '.', '⇥', '⎵'],
    };

    return Column(
      children: rows.values.map((rowKeys) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: rowKeys.map((keyLabel) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: keyLabel == rowKeys.last ? 0 : 8.0),
                  child: _buildKey(keyLabel),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String label) {
    Color bgColor = AppColors.surface2;
    Color textColor = AppColors.text1;
    if (label == '⌫' || label == 'Esc') {
      bgColor = AppColors.danger.withOpacity(0.15);
      textColor = AppColors.danger;
    } else if (label == '⏎') {
      bgColor = AppColors.primary.withOpacity(0.15);
      textColor = AppColors.primaryLight;
    } else if (label.startsWith('F')) {
      bgColor = AppColors.surface3;
      textColor = AppColors.text2;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          String code = label;
          if (label == '⌫') code = 'backspace';
          if (label == '⏎') code = 'enter';
          if (label == 'Esc') code = 'escape';
          if (label == '⇥') code = 'tab';
          if (label == '⎵') code = 'space';
          
          onKeyPress(code);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: label.length > 2 ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
