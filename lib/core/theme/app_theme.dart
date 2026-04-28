import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  // ── AMOLED dark ────────────────────────────────────────────────────────────
  static ThemeData get amoledTheme => _build(
    brightness: Brightness.dark,
    scheme: AppColorScheme.amoled,
    scaffoldBg: AppColorScheme.amoled.scaffold,
  );

  // ── Standard dark ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    scheme: AppColorScheme.dark,
    scaffoldBg: AppColorScheme.dark.scaffold,
  );

  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    scheme: AppColorScheme.light,
    scaffoldBg: AppColorScheme.light.scaffold,
  );

  // ── Shared builder ─────────────────────────────────────────────────────────
  static ThemeData _build({
    required Brightness brightness,
    required AppColorScheme scheme,
    required Color scaffoldBg,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      primaryColor: AppColors.primary,
      extensions: [scheme],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        surface: scheme.surface1,
        onSurface: scheme.text1,
        error: AppColors.danger,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayBold,
        headlineLarge: AppTextStyles.h1,
        titleLarge: AppTextStyles.sectionTitle,
        bodyLarge: AppTextStyles.bodyText,
        bodyMedium: AppTextStyles.bodySub,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 8,
          shadowColor: AppColors.primaryGlow,
          padding: const EdgeInsets.all(16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.text3 : AppColorScheme.light.text2,
          textStyle: AppTextStyles.buttonGhost,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(12),
        ),
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface0,
        elevation: 0,
        titleTextStyle: AppTextStyles.navTitle.copyWith(color: scheme.text1),
        iconTheme: IconThemeData(color: scheme.text1),
      ),
    );
  }
}
