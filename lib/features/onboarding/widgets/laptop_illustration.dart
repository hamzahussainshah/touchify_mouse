import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LaptopIllustration extends StatelessWidget {
  const LaptopIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Laptop Body & Screen
          Positioned(
            top: 0,
            left: 10,
            child: Container(
              width: 160,
              height: 95,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2A3A), Color(0xFF1E1E2A)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGlow,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Laptop Base
          Positioned(
            bottom: 25,
            child: Container(
              width: 180,
              height: 10,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF252535), Color(0xFF1A1A28)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Phone Mini
          Positioned(
            bottom: 5,
            right: 10,
            child: Container(
              width: 36,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2A3A), Color(0xFF1E1E2A)],
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 26,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(height: 1.5, color: AppColors.primaryDim.withOpacity(0.5)),
                    Container(height: 1.5, color: AppColors.primaryDim.withOpacity(0.5)),
                    Container(height: 1.5, color: AppColors.primaryDim.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
          // WiFi Arc (Mockup)
          const Positioned(
            top: 50,
            child: Icon(Icons.wifi_tethering, color: AppColors.primaryLight, size: 24),
          ),
        ],
      ),
    );
  }
}
