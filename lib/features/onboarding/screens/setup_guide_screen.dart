import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SetupGuideScreen extends StatelessWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Setup Process'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildStep(
                    number: 1,
                    isActive: true,
                    title: 'Download Desktop Agent',
                    description: 'Install the companion application on your computer.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildOsChip(Icons.apple, 'macOS'),
                            const SizedBox(width: 10),
                            _buildOsChip(Icons.window, 'Windows'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.mail_outline, size: 18),
                          label: const Text('Send Link to Email'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text1,
                            side: const BorderSide(color: AppColors.borderMid),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    number: 2,
                    isActive: false,
                    title: 'Connect to same Wi-Fi',
                    description: 'Ensure both your phone and computer are on the same network.',
                  ),
                  _buildStep(
                    number: 3,
                    isActive: false,
                    title: 'Auto-Discovery',
                    description: 'TouchDesk will automatically find your computer on the network.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go('/connect'),
              child: const Center(child: Text('Next Step')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({required int number, required bool isActive, required String title, required String description, Widget? child, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? Colors.transparent : AppColors.borderMid),
                ),
                alignment: Alignment.center,
                child: Text(
                  number.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.text3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.deviceName.copyWith(
                      color: isActive ? AppColors.text1 : AppColors.text3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySub.copyWith(
                      color: isActive ? AppColors.text2 : AppColors.text3,
                    ),
                  ),
                  if (child != null) child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOsChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.text1),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text1)),
        ],
      ),
    );
  }
}
