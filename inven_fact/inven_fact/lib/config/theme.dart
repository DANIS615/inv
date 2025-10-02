import 'package:flutter/material.dart';

class AppTheme {
  // Main Colors
  static const Color primaryColor = Color(0xFF2C3E50); // Midnight Blue
  static const Color accentColor = Color(0xFF3498DB); // Peter River Blue
  static const Color backgroundColor = Color(0xFFECF0F1); // Clouds White
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF34495E); // Wet Asphalt
  static const Color headingColor = Color(0xFF2C3E50); // Midnight Blue

  // Semantic Colors
  static const Color successColor = Color(0xFF2ECC71); // Emerald Green
  static const Color warningColor = Color(0xFFF1C40F); // Sunflower Yellow
  static const Color errorColor = Color(0xFFE74C3C); // Alizarin Crimson
  static const Color infoColor = Color(0xFF3498DB); // Peter River Blue

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: cardColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: headingColor),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: headingColor),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: headingColor),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headingColor),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: headingColor),
      titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: headingColor),
      bodyLarge: TextStyle(fontSize: 16, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, color: textColor),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, color: textColor),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: accentColor.withOpacity(0.1),
      labelStyle: const TextStyle(color: accentColor, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
    ),
  );

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF3498DB); // Peter River Blue
  static const Color darkAccentColor = Color(0xFF2ECC71); // Emerald Green
  static const Color darkBackgroundColor = Color(0xFF121212); // Dark Background
  static const Color darkCardColor = Color(0xFF1E1E1E); // Dark Card
  static const Color darkTextColor = Color(0xFFE0E0E0); // Light Text
  static const Color darkHeadingColor = Color(0xFFFFFFFF); // White Headings

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: darkPrimaryColor,
      primary: darkPrimaryColor,
      secondary: darkAccentColor,
      surface: darkCardColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextColor,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkHeadingColor),
      displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkHeadingColor),
      displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkHeadingColor),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkHeadingColor),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: darkHeadingColor),
      titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkHeadingColor),
      bodyLarge: TextStyle(fontSize: 16, color: darkTextColor),
      bodyMedium: TextStyle(fontSize: 14, color: darkTextColor),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, color: darkTextColor),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: darkCardColor,
      foregroundColor: darkTextColor,
      elevation: 0,
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextColor),
      iconTheme: const IconThemeData(color: darkTextColor),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade700, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: darkTextColor),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkPrimaryColor.withOpacity(0.2),
      labelStyle: const TextStyle(color: darkPrimaryColor, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: darkPrimaryColor,
      foregroundColor: Colors.white,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade700,
      thickness: 1,
    ),
  );
}