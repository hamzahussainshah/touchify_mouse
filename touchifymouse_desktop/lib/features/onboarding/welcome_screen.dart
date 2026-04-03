import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/titlebar.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Container(
              color: AppColors.surface0,
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B5FDE), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.mouse, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to TouchifyMouse',
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text1),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The desktop companion that receives input from your phone.\nSet up takes about 60 seconds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.text3),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => context.go('/dashboard'),
                    icon: const Text('Get Started',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    label: const Icon(Icons.arrow_forward, size: 16),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
