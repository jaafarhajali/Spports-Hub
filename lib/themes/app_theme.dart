import 'package:flutter/material.dart';

class AppTheme {
  // Define your custom colors
  static const Color buttonBackground = Color(0xFF1A7B9B);
  static const Color darkBackground = Color(0xFF0C0A09);
  static const Color lightBackground = Colors.white;
  static const Color darkSecondary = Color(0xFF1C1917);
  static const Color lightSecondary = Color(0xFFF2F4F7);
  static const Color errorColor = Colors.red;
  static const Color transparentTextDark = Color(0xFF98A2B3);
  static const Color labelLight = Color(0xFF344054);
  static const Color labelDark = Color(0xFF98A2B3);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: buttonBackground,
      colorScheme: ColorScheme.dark(
        primary: buttonBackground,
        secondary: darkSecondary,
        error: errorColor,
        surface: darkSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSecondary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: buttonBackground),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: labelDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: buttonBackground, width: 2),
        ),
        labelStyle: TextStyle(color: labelDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: transparentTextDark),
        labelMedium: TextStyle(color: labelDark),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: buttonBackground,
      colorScheme: ColorScheme.light(
        primary: buttonBackground,
        secondary: lightSecondary,
        error: errorColor,
        surface: lightSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSecondary,
        foregroundColor: Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: buttonBackground),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: labelLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: buttonBackground, width: 2),
        ),
        labelStyle: TextStyle(color: labelLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: labelLight),
        labelMedium: TextStyle(color: labelLight),
      ),
    );
  }
}
