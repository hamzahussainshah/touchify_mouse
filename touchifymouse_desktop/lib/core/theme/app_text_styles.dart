import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get titleLarge => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.text1,
      );

  static TextStyle get titleMedium => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text1,
      );

  static TextStyle get subtitle => GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.text3,
      );

  static TextStyle get body => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.text2,
      );

  static TextStyle get monoSequence => GoogleFonts.dmMono(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
        color: AppColors.primaryDim,
      );
}
