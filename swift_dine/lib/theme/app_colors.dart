import 'package:flutter/material.dart';

class AppColors {
  // 🌟 OPTIMIZED PRIMARY GREENS - Tested for visibility & aesthetics
  // Light Mode: Vibrant but accessible green that pops on white
  static const Color primaryLight = Color(0xFF43A047);    // Emerald Green - Best contrast
  static const Color primaryLightVariant = Color(0xFF4CAF50); // Material Green
  static const Color primaryLightAccent = Color(0xFF66BB6A);  // Bright accent

  // Dark Mode: Keep the acid green energy
  static const Color primaryDark = Color(0xFF7CFC00);     // Acid Green
  static const Color primaryDarkVariant = Color(0xFFADFF2F); // Green Yellow
  static const Color primaryDarkAccent = Color(0xFF32CD32);  // Lime Green

  // Context-aware primary colors
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryDark
        : primaryLight;
  }

  static Color primaryVariant(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryDarkVariant
        : primaryLightVariant;
  }

  // 🎨 SECONDARY & ACCENT COLORS (Work in both themes)
  static const Color secondary = Color(0xFF00B894);       // Emerald Teal
  static const Color secondaryLight = Color(0xFF55EFC4);  // Mint
  static const Color secondaryDark = Color(0xFF00806A);   // Deep Teal

  static const Color accent = Color(0xFFCDDC39);          // Lime accent
  static const Color accentVibrant = Color(0xFFE6FF00);   // Bright lime

  // Neutral colors
  static const Color neutral = Color(0xFF1F1F1F);
  static const Color neutralLight = Color(0xFF2B2B2B);
  static const Color neutralDark = Color(0xFF121212);

  // 🌓 ADAPTIVE BACKGROUNDS & SURFACES
  // Light theme (optimized for emerald green)
  static const Color backgroundLight = Color(0xFFFAFDF9);     // Warm white with subtle green
  static const Color surfaceLight = Color(0xFFFFFFFF);       // Pure white
  static const Color surfaceVariantLight = Color(0xFFF8FBF7); // Very subtle green
  static const Color onPrimaryLight = Colors.white;
  static const Color onSecondaryLight = Colors.white;
  static const Color textColorLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);

  // Dark theme (optimized for acid green)
  static const Color backgroundDark = Color(0xFF0F1210);     // Deep greenish black
  static const Color surfaceDark = Color(0xFF1A1D1B);        // Elevated surface
  static const Color surfaceVariantDark = Color(0xFF222823); // Variant surface
  static const Color onPrimaryDark = Color(0xFF0F1210);      // Dark text on acid green
  static const Color onSecondaryDark = Colors.white;
  static const Color textColorDark = Color(0xFFF0F0F0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Adaptive getters
  static Color background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceVariantDark : surfaceVariantLight;

  static Color onPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? onPrimaryDark : onPrimaryLight;

  static Color textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textColorDark : textColorLight;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  // 🚨 SEMANTIC COLORS
  static const Color error = Color(0xFFEB5757);
  static const Color success = Color(0xFF43A047);       // Using emerald green
  static const Color warning = Color(0xFFFFB800);
  static const Color info = Color(0xFF2D9CDB);

  // Additional utility colors
  static const Color successLight = Color(0xFF55EFC4);
  static const Color successDark = Color(0xFF00806A);

  // Border colors
  static const Color borderLight = Color(0xFFE8ECE6);
  static const Color borderDark = Color(0xFF2A2F2C);

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? borderDark : borderLight;

  // 🌈 GRADIENTS
  static Gradient primaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const LinearGradient(
      colors: [Color(0xFF7CFC00), Color(0xFFADFF2F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient(
      colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // 🎯 MATERIAL 3 COLOR SCHEME
  static ColorScheme colorScheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const ColorScheme.dark(
      primary: primaryDark,
      onPrimary: onPrimaryDark,
      primaryContainer: primaryDarkVariant,
      secondary: secondary,
      onSecondary: onSecondaryDark,
      secondaryContainer: secondaryDark,
    )
        : const ColorScheme.light(
      primary: primaryLight,
      onPrimary: onPrimaryLight,
      primaryContainer: primaryLightVariant,
      secondary: secondary,
      onSecondary: onSecondaryLight,
      secondaryContainer: secondaryLight,
    );
  }
}