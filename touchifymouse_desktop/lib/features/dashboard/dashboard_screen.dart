import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/titlebar.dart';
import '../../shared/widgets/sidebar.dart';
import '../../shared/widgets/qr_panel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                Sidebar(
                  activeRoute: '/dashboard',
                  onNavigate: (route) => context.go(route),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.surface0,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildActiveConnectionCard()),
                            const SizedBox(width: 16),
                            const Expanded(child: QrPanel()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildActivityLogCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConnectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_iphone, color: AppColors.text2),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waiting for connection...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                    Text('Ensure phone and Mac are on same Wi-Fi', style: TextStyle(fontSize: 11, color: AppColors.text3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Scan the QR code to pair your device instantly.', style: TextStyle(color: AppColors.text2, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Log', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text1)),
            SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text('No recent connection activity.', style: TextStyle(color: AppColors.text3, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
