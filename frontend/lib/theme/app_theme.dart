import 'package:flutter/material.dart';

/// App-wide theming for Village.
/// Owner: A
abstract class AppTheme {
  // Brand colours
  static const Color primary = Color(0xFF1B5E20);      // deep forest green
  static const Color accent = Color(0xFFFFA000);        // warm amber
  static const Color background = Color(0xFF121212);    // near-black
  static const Color surface = Color(0xFF1E1E1E);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color markerVolunteer = Color(0xFF43A047); // green pulse
  static const Color markerElder = Color(0xFFE53935);     // red pin

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: accent,
          background: background,
          surface: surface,
          onSurface: onSurface,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: onSurface,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      );
}
