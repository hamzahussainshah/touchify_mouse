import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  String selectedPlan = 'Lifetime';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFBBF24).withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 64,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'TouchDesk Pro',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock the ultimate trackpad experience and support independent development.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySub,
                  ),
                  const SizedBox(height: 40),
                  _buildFeature('No Ads', Icons.block),
                  _buildFeature('Unlimited Devices', Icons.devices),
                  _buildFeature('Clipboard Sync', Icons.content_paste),
                  _buildFeature('Custom Gestures & Shortcuts', Icons.gesture),
                  _buildFeature('Gyro Mouse Control', Icons.screen_rotation),
                  _buildFeature('Studio Audio (48kHz & Voice Focus)', Icons.mic_external_on),
                  const SizedBox(height: 48),

                  _buildPlanCard(
                    title: 'Lifetime',
                    price: '\$9.99',
                    subtitle: 'One time payment',
                    badge: 'BEST VALUE',
                    isSelected: selectedPlan == 'Lifetime',
                    onTap: () => setState(() => selectedPlan = 'Lifetime'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlanCard(
                          title: 'Yearly',
                          price: '\$14.99',
                          subtitle: '/year',
                          isSelected: selectedPlan == 'Yearly',
                          onTap: () => setState(() => selectedPlan = 'Yearly'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPlanCard(
                          title: 'Monthly',
                          price: '\$1.99',
                          subtitle: '/month',
                          isSelected: selectedPlan == 'Monthly',
                          onTap: () => setState(() => selectedPlan = 'Monthly'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Placeholder logic for IAP
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                    child: Text('Get $selectedPlan for ${_getPrice(selectedPlan)}'),
                  ),
                  const SizedBox(height: 16),
                  Text('7-day free trial on subscriptions', style: AppTextStyles.deviceSub),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Restore Purchase'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPrice(String plan) {
    if (plan == 'Lifetime') return '\$9.99';
    if (plan == 'Yearly') return '\$14.99';
    return '\$1.99';
  }

  Widget _buildFeature(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text1)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String subtitle,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface2,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isSelected ? AppColors.primaryLight : AppColors.text3, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -6,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
