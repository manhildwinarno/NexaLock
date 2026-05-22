import 'package:flutter/material.dart';

class AppTheme {
  // Fortress Modern Palette
  static const Color primary = Color(0xFF001F3F); // Deep Navy
  static const Color primaryDark = Color(0xFF000613);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF0058BC); // Tech Blue
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF0070EB);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);

  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceVariant = Color(0xFFD3E4FE);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);

  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF43474E);

  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color success = Color(0xFF34C759); // Standardized success color

  // Spacing & Radius Constants
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;

  // Animation Constants
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveSpring = Curves.elasticOut;

  // Box Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF001A41).withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF000613).withValues(alpha: 0.20),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: const Color(0xFF001A41).withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  // Glassmorphism Factory
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(radiusXl),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
        boxShadow: subtleShadow,
      );

  // Typography Scale
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 32, fontWeight: FontWeight.w700, color: primary),
    titleLarge: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 22, fontWeight: FontWeight.w700, color: primary),
    titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: primary),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceVariant),
    labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: outline),
  );

  // Standard ThemeData builder for fallback/Material integrations
  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
      fontFamily: 'Inter',
      textTheme: _textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        hintStyle: const TextStyle(color: outline, fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: secondaryContainer, width: 2),
        ),
      ),
    );
  }
}
