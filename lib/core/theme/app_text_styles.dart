import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display/Headings (Outfit)
  static final displayBold = GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
    color: AppColors.text1,
    height: 1.1,
  );

  static final h1 = GoogleFonts.outfit(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.text1,
    height: 1.15,
  );

  static final sectionTitle = GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.text1,
  );

  static final navTitle = GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.text1,
  );

  static final sectionLabel = GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.primaryDim,
  );

  static final phoneLabel = GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: AppColors.text3,
  );

  static final statusTime = GoogleFonts.outfit(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.text1,
  );
  
  static final gestureHint = GoogleFonts.outfit(
    fontSize: 10,
    color: Colors.white.withOpacity(0.1),
    letterSpacing: 0.5,
  );

  // Body (DM Sans)
  static final bodyText = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    color: AppColors.text3,
  );

  static final bodySub = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.text3,
    height: 1.6,
  );

  static final buttonPrimary = GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  static final buttonGhost = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text3,
  );

  static final deviceName = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.text1,
  );

  static final deviceSub = GoogleFonts.dmSans(
    fontSize: 11,
    color: AppColors.text3,
  );

  // Mono/Labels (DM Mono)
  static final monoLabel = GoogleFonts.dmMono(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.text3,
  );
}
