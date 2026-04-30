import 'package:flutter/material.dart';

// ── Brand colours (consistent across themes) ─────────────────────────────────
class AppColors {
  // Primary brand: vibrant violet — more punchy than the old indigo.
  static const primary       = Color(0xFF8B5CF6); // violet-500
  static const primaryLight  = Color(0xFFA78BFA); // violet-400
  static const primaryDim    = Color(0xFFC4B5FD); // violet-300
  static const primaryDeep   = Color(0xFF6D28D9); // violet-700
  static const primaryBg     = Color(0xFF1E1B4B);
  static const primaryGlow   = Color(0x668B5CF6);

  // Accent: electric pink — for hero moments / pro CTAs / brand gradients.
  static const accent        = Color(0xFFEC4899); // pink-500
  static const accentLight   = Color(0xFFF472B6); // pink-400

  // Highlight / trackpad ambient: cyan — gives "tech" feel on dark surfaces.
  static const highlight     = Color(0xFF22D3EE); // cyan-400

  // Status colours.
  static const success       = Color(0xFF10B981); // emerald-500
  static const warning       = Color(0xFFF59E0B); // amber-500
  static const danger        = Color(0xFFEF4444); // red-500

  // ── Brand gradients — use these for headlines & primary CTAs ──────────────
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], // violet → pink
  );
  static const techGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)], // violet → cyan
  );

  // ── Backwards-compat tokens (kept so nothing breaks) ──────────────────────
  static const amoled    = Color(0xFF06030F);
  static const surface0  = Color(0xFF0E0A1C);
  static const surface1  = Color(0xFF15102A);
  static const surface2  = Color(0xFF1B1632);
  static const surface3  = Color(0xFF231D40);
  static const surface4  = Color(0xFF2D2650);
  static const border    = Color(0x1AFFFFFF);
  static const borderMid = Color(0x29FFFFFF);
  static const text1     = Color(0xFFF5F3FF);
  static const text2     = Color(0xFFC4C2D8);
  static const text3     = Color(0xFF7E7B9C);
}

// ── Per-theme colour tokens (accessed via `context.appColors`) ───────────────
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

  // ── AMOLED — true-dark, deep plum tint (premium feel) ───────────────────
  static const amoled = AppColorScheme(
    scaffold:  Color(0xFF06030F),
    surface0:  Color(0xFF0E0A1C),
    surface1:  Color(0xFF15102A),
    surface2:  Color(0xFF1B1632),
    surface3:  Color(0xFF231D40),
    surface4:  Color(0xFF2D2650),
    border:    Color(0x1AFFFFFF),
    borderMid: Color(0x29FFFFFF),
    text1:     Color(0xFFF5F3FF),
    text2:     Color(0xFFC4C2D8),
    text3:     Color(0xFF7E7B9C),
  );

  // ── Standard dark — softer, warmer ─────────────────────────────────────
  static const dark = AppColorScheme(
    scaffold:  Color(0xFF0F0B1F),
    surface0:  Color(0xFF161126),
    surface1:  Color(0xFF1D1830),
    surface2:  Color(0xFF26203D),
    surface3:  Color(0xFF302849),
    surface4:  Color(0xFF3A3157),
    border:    Color(0x1FFFFFFF),
    borderMid: Color(0x33FFFFFF),
    text1:     Color(0xFFF5F3FF),
    text2:     Color(0xFFC4C2D8),
    text3:     Color(0xFF7E7B9C),
  );

  // ── Light — warm cream rather than cold gray ───────────────────────────
  static const light = AppColorScheme(
    scaffold:  Color(0xFFF7F5FB),
    surface0:  Color(0xFFFFFFFF),
    surface1:  Color(0xFFFFFFFF),
    surface2:  Color(0xFFF1ECF8),
    surface3:  Color(0xFFE6DEF3),
    surface4:  Color(0xFFD8CDED),
    border:    Color(0x14000000),
    borderMid: Color(0x1F000000),
    text1:     Color(0xFF1B1232),
    text2:     Color(0xFF534B6B),
    text3:     Color(0xFF8B85A3),
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

extension AppColorsExt on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.amoled;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
