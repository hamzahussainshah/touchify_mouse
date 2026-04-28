import 'package:flutter/material.dart';
import '../../../shared/models/device_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final bool isActive;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : colors.surface2,
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : colors.border,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : colors.surface3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                device.os.toLowerCase() == 'macos'
                    ? Icons.apple
                    : Icons.window,
                color: isActive ? AppColors.primaryLight : colors.text1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTextStyles.deviceName.copyWith(
                      color: isActive ? AppColors.primaryLight : colors.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.os} • ${device.ipAddress}',
                    style: AppTextStyles.deviceSub.copyWith(color: colors.text3),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'CONNECTED',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (index) {
                    final isBarActive = index < device.signalStrength;
                    return Container(
                      width: 3,
                      height: 4.0 + (index * 3),
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: isBarActive
                            ? AppColors.success
                            : AppColors.success.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
