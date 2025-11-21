import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      // Primary colors (Emerald Green based)
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      primaryContainer: AppColors.primaryLightVariant,

      // Secondary colors
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondaryLight,
      secondaryContainer: AppColors.secondaryLight,

      // Background and surface
      background: AppColors.backgroundLight,
      onBackground: AppColors.textColorLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textColorLight,
      surfaceVariant: AppColors.surfaceVariantLight,

      // Error colors
      error: AppColors.error,
      onError: Colors.white,

      // Outline
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,

    // Text Theme - Optimized for readability
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme.copyWith(
        bodyLarge: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: const TextStyle(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w400,
        ),
        displayLarge: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: const TextStyle(
          color: AppColors.textColorLight,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: const TextStyle(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textColorLight,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.primaryLight),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textColorLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card Theme - FIXED: Using proper CardThemeData class with const where possible
    cardTheme: const CardThemeData(
      color: AppColors.surfaceVariantLight,
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      surfaceTintColor: Colors.transparent,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: AppColors.primaryLight),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textSecondaryLight,
      elevation: 2,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
      hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryLight,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      // Primary colors (Acid Green based)
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryDarkVariant,

      // Secondary colors
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondaryDark,
      secondaryContainer: AppColors.secondaryDark,

      // Background and surface
      background: AppColors.backgroundDark,
      onBackground: AppColors.textColorDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textColorDark,
      surfaceVariant: AppColors.surfaceVariantDark,

      // Error colors
      error: AppColors.error,
      onError: Colors.white,

      // Outline
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,

    // Text Theme
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme.copyWith(
        bodyLarge: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontWeight: FontWeight.w400,
        ),
        displayLarge: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: const TextStyle(
          color: AppColors.textColorDark,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontWeight: FontWeight.w400,
        ),
      ),
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textColorDark,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.primaryDark),
      titleTextStyle: GoogleFonts.poppins(
        color: AppColors.textColorDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Card Theme - FIXED: Using proper CardThemeData class with const where possible
    cardTheme: const CardThemeData(
      color: AppColors.surfaceVariantDark,
      elevation: 4,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      surfaceTintColor: Colors.transparent,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: AppColors.primaryDark),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.onPrimaryDark,
      shape: CircleBorder(),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.textSecondaryDark,
      elevation: 4,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.onPrimaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.primaryDark),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Progress indicators
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryDark,
    ),
  );
}