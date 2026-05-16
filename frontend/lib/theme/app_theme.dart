import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theming for Village — Warm Connection design system.
/// Light theme with warm, human-centered palette inspired by South Asian aesthetics.
/// Owner: A (Design: collaborative)
abstract class AppTheme {
  // ============ Colors ============
  // Primary & Secondary (Trust, heritage)
  static const Color primary = Color(0xFFC85C4F);        // Warm rust
  static const Color secondary = Color(0xFF8B5E3C);      // Spice brown
  static const Color accent = Color(0xFFF4A560);         // Apricot (hope)

  // Backgrounds
  static const Color background = Color(0xFFFAFAF7);     // Off-white
  static const Color surface = Color(0xFFFFFFFF);        // Pure white

  // Text
  static const Color textPrimary = Color(0xFF2C2420);    // Deep charcoal
  static const Color textSecondary = Color(0xFF6B6B67);  // Gray

  // Markers
  static const Color markerElder = Color(0xFFD4866D);    // Terracotta
  static const Color markerVolunteer = Color(0xFF6BA3A8); // Teal

  // States
  static const Color success = Color(0xFF6B9A7D);        // Sage green
  static const Color alert = Color(0xFFD97662);          // Coral
  static const Color disabled = Color(0xFFD0D0CA);       // Light gray

  // ============ Spacing (8px base unit) ============
  static const double spacing_xs = 4;
  static const double spacing_sm = 8;
  static const double spacing_md = 12;
  static const double spacing_lg = 16;
  static const double spacing_xl = 20;
  static const double spacing_xxl = 24;
  static const double spacing_3xl = 32;

  // ============ Border Radius ============
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // ============ Typography ============
  static TextStyle get displayLarge => GoogleFonts.fraunces(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.fraunces(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle get headlineSmall => GoogleFonts.fraunces(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ============ Theme Data ============
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      tertiary: accent,
      surface: surface,
      background: background,
      error: alert,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onBackground: textPrimary,
    ),
    scaffoldBackgroundColor: background,

    // AppBar styling
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.08),
      centerTitle: false,
      titleTextStyle: displayMedium.copyWith(fontSize: 20),
    ),

    // Elevated buttons (Primary action)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing_xl,
          vertical: spacing_lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        elevation: 0,
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined buttons (Secondary)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing_xl,
          vertical: spacing_lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Cards
    cardTheme: CardTheme(
      color: surface,
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),

    // Input decoration (text fields, forms)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing_lg,
        vertical: spacing_lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: disabled, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: disabled, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: alert, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: alert, width: 2),
      ),
      labelStyle: bodyMedium.copyWith(color: textSecondary),
      hintStyle: bodyMedium.copyWith(color: disabled),
      errorStyle: bodySmall.copyWith(color: alert),
    ),

    // Chip styling
    chipTheme: ChipThemeData(
      backgroundColor: background,
      side: const BorderSide(color: disabled, width: 1),
      labelStyle: labelSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spacing_md,
        vertical: spacing_sm,
      ),
    ),

    // Slider styling
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: disabled,
      thumbColor: primary,
      overlayColor: primary.withOpacity(0.2),
      valueIndicatorColor: primary,
      valueIndicatorTextStyle: bodySmall.copyWith(color: Colors.white),
    ),

    // Default text styles
    textTheme: TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displayMedium,
      headlineMedium: headlineSmall,
      headlineSmall: headlineSmall,
      titleLarge: labelLarge,
      titleMedium: labelLarge.copyWith(fontSize: 14),
      titleSmall: labelSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelSmall,
      labelSmall: labelSmall,
    ),
  );
}
