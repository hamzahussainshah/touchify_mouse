import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class Sidebar extends StatelessWidget {
  final String activeRoute;
  final Function(String) onNavigate;

  const Sidebar({super.key, required this.activeRoute, required this.onNavigate});

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: AppColors.text3,
        ),
      ),
    );
  }

  Widget _buildNavItem({required String label, required IconData icon, required String route}) {
    final isActive = activeRoute == route;
    return InkWell(
      onTap: () => onNavigate(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: isActive ? AppColors.primaryDim : AppColors.text2),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primaryDim : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          
          _buildSectionLabel('OVERVIEW'),
          _buildNavItem(label: 'Dashboard', icon: Icons.grid_view, route: '/dashboard'),
          _buildNavItem(label: 'Devices', icon: Icons.devices, route: '/devices'),
          _buildNavItem(label: 'Permissions', icon: Icons.verified_user, route: '/permissions'),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Divider(height: 1, color: AppColors.border),
          ),

          _buildSectionLabel('CONNECT'),
          _buildNavItem(label: 'QR Connect', icon: Icons.qr_code, route: '/qr'),
          _buildNavItem(label: 'Network Scan', icon: Icons.radar, route: '/scan'),

          const Spacer(),

          _buildNavItem(label: 'Settings', icon: Icons.settings, route: '/settings'),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5FDE), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mouse, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TouchifyMouse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
                      Text('v1.0.0 · macOS', style: TextStyle(fontSize: 10, color: AppColors.text3)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
