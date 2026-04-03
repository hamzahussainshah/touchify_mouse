import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.surface0,
        useMaterial3: true,
        fontFamily: 'DM Sans',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface0,
          error: AppColors.danger,
        ),
      );
}
