import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

// App uses Inter font family with weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)
// Reference: https://fonts.google.com/specimen/Inter

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

      // Typography - Using Inter Font
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold, // 700
          color: AppPalette.navyPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold, // 700
          color: AppPalette.navyPrimary,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600, // 600
          color: AppPalette.navyPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600, // 600
          color: AppPalette.navyPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600, // 600
          color: AppPalette.navyPrimary, // Dark Text on White Cards
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500, // 500
          color: AppPalette.navyPrimary, // Dark Text on White Cards
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal, // 400
          color: AppPalette.navyPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal, // 400
          color: AppPalette.navyPrimary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600, // 600
          color: AppPalette.white,
        ),
      ),

      // Component Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.orangeAccent, // Orange Buttons
          foregroundColor: AppPalette.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 600
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.orangeAccent,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppPalette.orangeAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 600
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.orangeAccent,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 600
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.orangeAccent,
        foregroundColor: AppPalette.white,
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
        labelStyle: GoogleFonts.inter(
          color: AppPalette.textSecondaryLight,
        ),
        hintStyle: GoogleFonts.inter(color: AppPalette.textDisabled),
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

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent;
          }
          return null;
        }),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent;
          }
          return null;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),

      chipTheme: ChipThemeData(
        selectedColor: AppPalette.orangeAccent,
        checkmarkColor: AppPalette.white,
        labelStyle: GoogleFonts.inter(fontSize: 14),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.navyPrimary, // Navy Blue Header
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppPalette.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600, // 600
          color: AppPalette.white,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.white,
        selectedItemColor: AppPalette.orangeAccent, // Orange Selected
        unselectedItemColor: AppPalette.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      iconTheme: const IconThemeData(color: AppPalette.navyPrimary),
    );
  }

  // Dark Theme (Navy BG, Dark Cards)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppPalette.orangeAccent,
        onPrimary: AppPalette.white,
        secondary: AppPalette.navyLight,
        onSecondary: AppPalette.white,
        error: AppPalette.errorRed,
        onError: AppPalette.white,
        surface: AppPalette.surfaceDark, // Dark Cards
        onSurface: AppPalette.white, // White Text on Dark Cards
        outline: AppPalette.outline,
      ),
      scaffoldBackgroundColor: AppPalette.backgroundDark,

      // Typography (Dark Mode) - Using Inter Font
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 32,
          fontWeight: FontWeight.bold, // 700
        ),
        displayMedium: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 28,
          fontWeight: FontWeight.bold, // 700
        ),
        displaySmall: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 24,
          fontWeight: FontWeight.w600, // 600
        ),
        headlineMedium: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 20,
          fontWeight: FontWeight.w600, // 600
        ),
        titleLarge: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 18,
          fontWeight: FontWeight.w600, // 600
        ),
        titleMedium: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 16,
          fontWeight: FontWeight.w500, // 500
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 16,
          fontWeight: FontWeight.normal, // 400
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppPalette.textSecondaryDark,
          fontSize: 14,
          fontWeight: FontWeight.normal, // 400
        ),
        labelLarge: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 14,
          fontWeight: FontWeight.w600, // 600
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
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 600
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.orangeAccent,
          side: const BorderSide(color: AppPalette.orangeAccent, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 600
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.orangeAccent,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600, // 600
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.orangeAccent,
        foregroundColor: AppPalette.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.navyLight,
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
        labelStyle: GoogleFonts.inter(
          color: AppPalette.textSecondaryDark,
        ),
        hintStyle: GoogleFonts.inter(color: AppPalette.textDisabled),
      ),

      cardTheme: CardThemeData(
        color: AppPalette.surfaceGlassDark, // Glass Cards in Dark Mode
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppPalette.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent;
          }
          return null;
        }),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent;
          }
          return null;
        }),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppPalette.orangeAccent.withValues(alpha: 0.5);
          }
          return null;
        }),
      ),

      chipTheme: ChipThemeData(
        selectedColor: AppPalette.orangeAccent,
        checkmarkColor: AppPalette.white,
        labelStyle: GoogleFonts.inter(fontSize: 14),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.navyPrimary, // Navy Blue Header
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppPalette.white),
        titleTextStyle: GoogleFonts.inter(
          color: AppPalette.white,
          fontSize: 18,
          fontWeight: FontWeight.w600, // 600
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppPalette.surfaceDark,
        selectedItemColor: AppPalette.orangeAccent,
        unselectedItemColor: AppPalette.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      iconTheme: const IconThemeData(color: AppPalette.white),
    );
  }
}

