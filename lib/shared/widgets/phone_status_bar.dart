import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class PhoneStatusBar extends StatelessWidget {
  const PhoneStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 22, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41', style: AppTextStyles.statusTime),
          // Dynamic Island placeholder
          Container(
            width: 110,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Row(
            children: const [
              Icon(Icons.signal_cellular_4_bar, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.wifi, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Icon(Icons.battery_full, size: 16, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
