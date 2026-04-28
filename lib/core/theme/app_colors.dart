import 'package:flutter/material.dart';

// ── Brand colours (same across all themes) ───────────────────────────────────
class AppColors {
  static const primary      = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDim   = Color(0xFFA5B4FC);
  static const primaryBg    = Color(0xFF1E1B4B);
  static const primaryGlow  = Color(0x596366F1);

  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger  = Color(0xFFF87171);

  // ── Dark / AMOLED (kept as const for backward-compat) ──────────────────
  static const amoled    = Color(0xFF000000);
  static const surface0  = Color(0xFF0A0A0C);
  static const surface1  = Color(0xFF111114);
  static const surface2  = Color(0xFF18181C);
  static const surface3  = Color(0xFF222228);
  static const surface4  = Color(0xFF2C2C35);
  static const border    = Color(0x14FFFFFF);
  static const borderMid = Color(0x1FFFFFFF);
  static const text1     = Color(0xFFF8F8FF);
  static const text2     = Color(0xFFB0B0C8);
  static const text3     = Color(0xFF6B6B88);
}

// ── Per-theme colour tokens (accessed via context.appColors) ─────────────────
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color scaffold;
  final Color surface0, surface1, surface2, surface3, surface4;
  final Color border, borderMid;
  final Color text1, text2, text3;

  const AppColorScheme({
    required this.scaffold,
    required this.surface0, required this.surface1,
    required this.surface2, required this.surface3, required this.surface4,
    required this.border,   required this.borderMid,
    required this.text1,    required this.text2,    required this.text3,
  });

  // AMOLED dark preset
  static const amoled = AppColorScheme(
    scaffold:  Color(0xFF000000),
    surface0:  Color(0xFF0A0A0C),
    surface1:  Color(0xFF111114),
    surface2:  Color(0xFF18181C),
    surface3:  Color(0xFF222228),
    surface4:  Color(0xFF2C2C35),
    border:    Color(0x14FFFFFF),
    borderMid: Color(0x1FFFFFFF),
    text1:     Color(0xFFF8F8FF),
    text2:     Color(0xFFB0B0C8),
    text3:     Color(0xFF6B6B88),
  );

  // Standard dark preset
  static const dark = AppColorScheme(
    scaffold:  Color(0xFF0F0F14),
    surface0:  Color(0xFF141418),
    surface1:  Color(0xFF1C1C22),
    surface2:  Color(0xFF242430),
    surface3:  Color(0xFF2E2E3C),
    surface4:  Color(0xFF383848),
    border:    Color(0x1AFFFFFF),
    borderMid: Color(0x26FFFFFF),
    text1:     Color(0xFFF0F0FF),
    text2:     Color(0xFFB0B0C8),
    text3:     Color(0xFF6B6B88),
  );

  // Light preset
  static const light = AppColorScheme(
    scaffold:  Color(0xFFF2F2F7),
    surface0:  Color(0xFFF8F8FC),
    surface1:  Color(0xFFFFFFFF),
    surface2:  Color(0xFFF0F0F5),
    surface3:  Color(0xFFE4E4EE),
    surface4:  Color(0xFFD8D8E8),
    border:    Color(0x14000000),
    borderMid: Color(0x1F000000),
    text1:     Color(0xFF111122),
    text2:     Color(0xFF4A4A65),
    text3:     Color(0xFF8888A0),
  );

  @override
  AppColorScheme copyWith({
    Color? scaffold,
    Color? surface0, Color? surface1, Color? surface2,
    Color? surface3, Color? surface4,
    Color? border,   Color? borderMid,
    Color? text1,    Color? text2,    Color? text3,
  }) => AppColorScheme(
    scaffold:  scaffold  ?? this.scaffold,
    surface0:  surface0  ?? this.surface0,
    surface1:  surface1  ?? this.surface1,
    surface2:  surface2  ?? this.surface2,
    surface3:  surface3  ?? this.surface3,
    surface4:  surface4  ?? this.surface4,
    border:    border    ?? this.border,
    borderMid: borderMid ?? this.borderMid,
    text1:     text1     ?? this.text1,
    text2:     text2     ?? this.text2,
    text3:     text3     ?? this.text3,
  );

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      scaffold:  Color.lerp(scaffold,  other.scaffold,  t)!,
      surface0:  Color.lerp(surface0,  other.surface0,  t)!,
      surface1:  Color.lerp(surface1,  other.surface1,  t)!,
      surface2:  Color.lerp(surface2,  other.surface2,  t)!,
      surface3:  Color.lerp(surface3,  other.surface3,  t)!,
      surface4:  Color.lerp(surface4,  other.surface4,  t)!,
      border:    Color.lerp(border,    other.border,    t)!,
      borderMid: Color.lerp(borderMid, other.borderMid, t)!,
      text1:     Color.lerp(text1,     other.text1,     t)!,
      text2:     Color.lerp(text2,     other.text2,     t)!,
      text3:     Color.lerp(text3,     other.text3,     t)!,
    );
  }
}

/// Convenience accessor — use `context.appColors.surface1` anywhere.
extension AppColorsExt on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.amoled;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
