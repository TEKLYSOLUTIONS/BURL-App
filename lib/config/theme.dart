import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

class AppTheme {
  // Light Theme (Standard: White BG, White/Light Cards, Dark Text)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppPalette.navyPrimary,
        onPrimary: AppPalette.white,
        secondary: AppPalette.orangeAccent,
        onSecondary: AppPalette.white,
        error: AppPalette.error,
        onError: AppPalette.white,
        surface: AppPalette.white, // White Cards (Standard)
        onSurface: AppPalette.navyPrimary, // Navy Text on Cards
        outline: AppPalette.divider,
      ),
      scaffoldBackgroundColor: AppPalette.backgroundLight,

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppPalette.navyPrimary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppPalette.navyPrimary,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppPalette.navyPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppPalette.navyPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppPalette.navyPrimary, // Dark Text on White Cards
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppPalette.navyPrimary, // Dark Text on White Cards
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppPalette.navyPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppPalette.navyPrimary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppPalette.white,
        ),
      ),

      // Component Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.navyPrimary, // Dark Buttons
          foregroundColor: AppPalette.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.navyPrimary,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppPalette.navyPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.navyPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.textSecondaryLight,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppPalette.textDisabled),
      ),

      cardTheme: CardThemeData(
        color: AppPalette.white, // Standard White Cards
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppPalette.divider,
          ), // Add Border for visibility on White BG
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppPalette.navyPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppPalette.navyPrimary,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.white,
        selectedItemColor: AppPalette.navyPrimary, // Dark Selected
        unselectedItemColor: AppPalette.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      iconTheme: const IconThemeData(color: AppPalette.navyPrimary),
    );
  }

  // Dark Theme (Navy BG, White Cards)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppPalette.navyPrimary,
        onPrimary: AppPalette.white,
        secondary: AppPalette.orangeAccent,
        onSecondary: AppPalette.white,
        error: AppPalette.error,
        onError: AppPalette.white,
        surface: AppPalette.white, // White Cards
        onSurface: AppPalette.navyPrimary, // Navy Text on Cards
        outline: AppPalette.divider,
      ),
      scaffoldBackgroundColor: AppPalette.navyPrimary,

      // Typography (Dark Mode)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: AppPalette.white, // onBackground
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: AppPalette.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          color: AppPalette.white,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: AppPalette.white, // Section headers on BG
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppPalette.navyPrimary, // Title inside White Cards
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppPalette.navyPrimary, // Subtitle inside cards
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppPalette.white, // Body on BG
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppPalette.white, // Body on BG
          fontSize: 14,
        ),
      ),

      // Component Themes (Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.orangeAccent,
          foregroundColor: AppPalette.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.orangeAccent,
          side: const BorderSide(color: AppPalette.orangeAccent),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppPalette.orangeAccent,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.textSecondaryDark,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppPalette.textDisabled),
      ),

      cardTheme: CardThemeData(
        color: AppPalette.white, // White Cards in Dark Mode
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.navyPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppPalette.white),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppPalette.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.navyPrimary,
        selectedItemColor: AppPalette.orangeAccent,
        unselectedItemColor: AppPalette.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(color: AppPalette.white),
    );
  }
}
