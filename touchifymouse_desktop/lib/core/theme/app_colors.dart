import 'package:flutter/material.dart';

/// Brand palette — kept in lock-step with the mobile app
/// (lib/core/theme/app_colors.dart). When you change one, change both.
class AppColors {
  // Primary: vibrant violet
  static const primary       = Color(0xFF8B5CF6);
  static const primaryLight  = Color(0xFFA78BFA);
  static const primaryDim    = Color(0xFFC4B5FD);
  static const primaryDeep   = Color(0xFF6D28D9);

  // Accent: electric pink
  static const accent        = Color(0xFFEC4899);
  static const accentLight   = Color(0xFFF472B6);

  // Highlight: cyan (used sparingly)
  static const highlight     = Color(0xFF22D3EE);

  // Surfaces — deep plum tint, matches mobile AMOLED scheme
  static const amoled        = Color(0xFF06030F);
  static const surface0      = Color(0xFF0E0A1C);
  static const surface1      = Color(0xFF15102A);
  static const surface2      = Color(0xFF1B1632);
  static const surface3      = Color(0xFF231D40);
  static const surface4      = Color(0xFF2D2650);
  static const border        = Color(0x1AFFFFFF);
  static const borderMid     = Color(0x29FFFFFF);

  static const text1         = Color(0xFFF5F3FF);
  static const text2         = Color(0xFFC4C2D8);
  static const text3         = Color(0xFF7E7B9C);

  static const success       = Color(0xFF10B981);
  static const warning       = Color(0xFFF59E0B);
  static const danger        = Color(0xFFEF4444);

  // Brand gradients — drop on hero CTAs / active sidebar item.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );
}
