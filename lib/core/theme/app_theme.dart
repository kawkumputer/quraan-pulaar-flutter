import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF1F4037);  // Deep Islamic Green
  static const Color secondaryColor = Color(0xFF99B898); // Soft Sage
  static const Color accentColor = Color(0xFFB4A28F);   // Warm Sand
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF8F4E9); // Warm Parchment
  static const Color darkBackgroundColor = Color(0xFF1A2421); // Deep Night
  
  // Additional Colors
  static const Color goldAccent = Color(0xFFD4AF37);    // Islamic Gold
  static const Color textPrimary = Color(0xFF2C3E50);   // Rich Text
  static const Color textSecondary = Color(0xFF34495E); // Subtle Text

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: goldAccent,
        background: backgroundColor,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: textPrimary,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
        ),
        displaySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        shadowColor: primaryColor.withOpacity(0.1),
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: goldAccent,
        background: darkBackgroundColor,
        surface: const Color(0xFF243330),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkBackgroundColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.95),
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.95),
          letterSpacing: 0.3,
        ),
        displaySmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.95),
          letterSpacing: 0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(0.87),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.87),
          height: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF243330),
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      iconTheme: IconThemeData(
        color: Colors.white.withOpacity(0.87),
        size: 24,
      ),
    );
  }
}
