import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmeraldOrbitTheme {
  static const primaryGreen = Color(0xFF166534);
  static const premiumOrange = Color(0xFF22C55E);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceGray = Color(0xFFF3F4F6);
  static const textPrimary = Color(0xFF1F2937);

  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        secondary: premiumOrange,
      ).copyWith(
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: surfaceGray,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: surfaceWhite,
      ),
    );
  }
}
