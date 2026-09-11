import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Glassmorphism tokens extracted from the CSS custom properties in
/// `src/index.css` (`--glass-bg`, `--glass-border`, `--glass-blur`) and
/// `src/App.css` (`.glass-card` radius + shadow), exposed as a
/// `ThemeExtension` so widgets read them via `Theme.of(context)`
/// (Step 6 of FLUTTER_PLAN.md).
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.glassColor,
    required this.glassBorder,
    required this.blurSigma,
    required this.borderRadius,
    required this.shadowColor,
    required this.shadowOffset,
    required this.shadowBlurRadius,
  });

  /// `--glass-bg` — semi-transparent card fill.
  final Color glassColor;

  /// `--glass-border` — 1px card border color.
  final Color glassBorder;

  /// `--glass-blur: blur(12px)` — backdrop blur sigma.
  final double blurSigma;

  /// `.glass-card` border-radius (20px, 24px on wide layouts).
  final double borderRadius;

  /// `--glass-shadow` color component.
  final Color shadowColor;

  /// `--glass-shadow` offset component (`0 8px`).
  final Offset shadowOffset;

  /// `--glass-shadow` blur component (`32px`).
  final double shadowBlurRadius;

  @override
  GlassTheme copyWith({
    Color? glassColor,
    Color? glassBorder,
    double? blurSigma,
    double? borderRadius,
    Color? shadowColor,
    Offset? shadowOffset,
    double? shadowBlurRadius,
  }) =>
      GlassTheme(
        glassColor: glassColor ?? this.glassColor,
        glassBorder: glassBorder ?? this.glassBorder,
        blurSigma: blurSigma ?? this.blurSigma,
        borderRadius: borderRadius ?? this.borderRadius,
        shadowColor: shadowColor ?? this.shadowColor,
        shadowOffset: shadowOffset ?? this.shadowOffset,
        shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      );

  @override
  GlassTheme lerp(GlassTheme? other, double t) {
    if (other == null) return this;
    return GlassTheme(
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shadowOffset: Offset.lerp(shadowOffset, other.shadowOffset, t)!,
      shadowBlurRadius:
          lerpDouble(shadowBlurRadius, other.shadowBlurRadius, t)!,
    );
  }

  @override
  Object get type => GlassTheme;
}

/// App themes mapping the React app's CSS custom properties to
/// `ColorScheme` tokens. Dark mode is the default ("dark mode first").
///
/// Light palette (from `src/index.css` `:root`):
/// - `--bg-dark` #f1f5f9 -> surface
/// - `--accent-primary` #0284c7 -> primary
/// - `--accent-secondary` #4f46e5 -> secondary
/// - `--accent-tertiary` #db2777 -> tertiary
/// - `--accent-success` #16a34a -> (exposed via [AppTheme.successLight])
/// - `--accent-error` #dc2626 -> error
///
/// Dark palette (from `body.dark-mode`):
/// - `--bg-dark` #0f172a -> surface
/// - `--accent-primary` #38bdf8 -> primary
/// - `--accent-secondary` #818cf8 -> secondary
/// - `--accent-tertiary` #f472b6 -> tertiary
/// - `--accent-success` #4ade80 -> (exposed via [AppTheme.successDark])
/// - `--accent-error` #f87171 -> error
class AppTheme {
  AppTheme._();

  /// `--accent-success` in light mode.
  static const Color successLight = Color(0xFF16A34A);

  /// `--accent-success` in dark mode.
  static const Color successDark = Color(0xFF4ADE80);

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          primary: const Color(0xFF38BDF8), // --accent-primary
          secondary: const Color(0xFF818CF8), // --accent-secondary
          tertiary: const Color(0xFFF472B6), // --accent-tertiary
          error: const Color(0xFFF87171), // --accent-error
          surface: const Color(0xFF0F172A), // --bg-dark
          surfaceContainerHighest:
              const Color(0xFF020617), // --bg-darker
          onSurface: const Color(0xFFFFFFFF), // --text-primary
          onSurfaceVariant: const Color(0xFFE2E8F0), // --text-secondary
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        extensions: const [
          GlassTheme(
            glassColor: Color(0xB31E293B), // rgba(30,41,59,0.7)
            glassBorder: Color(0x1AFFFFFF), // rgba(255,255,255,0.1)
            blurSigma: 12,
            borderRadius: 20,
            shadowColor: Color(0x5E000000), // rgba(0,0,0,0.37)
            shadowOffset: Offset(0, 8),
            shadowBlurRadius: 32,
          ),
        ],
      );

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
          primary: const Color(0xFF0284C7), // --accent-primary
          secondary: const Color(0xFF4F46E5), // --accent-secondary
          tertiary: const Color(0xFFDB2777), // --accent-tertiary
          error: const Color(0xFFDC2626), // --accent-error
          surface: const Color(0xFFF1F5F9), // --bg-dark (light value)
          surfaceContainerHighest:
              const Color(0xFFF8FAFC), // --bg-darker (light value)
          onSurface: const Color(0xFF0F172A), // --text-primary
          onSurfaceVariant: const Color(0xFF475569), // --text-secondary
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        extensions: const [
          GlassTheme(
            glassColor: Color(0xB3FFFFFF), // rgba(255,255,255,0.7)
            glassBorder: Color(0x1A000000), // rgba(0,0,0,0.1)
            blurSigma: 12,
            borderRadius: 20,
            shadowColor: Color(0x121F2687), // rgba(31,38,135,0.07)
            shadowOffset: Offset(0, 8),
            shadowBlurRadius: 32,
          ),
        ],
      );
}
