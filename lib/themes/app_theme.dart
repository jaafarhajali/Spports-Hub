import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Professional Color Palette
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF1E40AF);
  static const Color secondaryTeal = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // Background Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF334155);

  // Text Colors
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);

  // Border Colors
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color darkBorder = Color(0xFF475569);

  // Gradient Colors
  static const List<Color> gradientBlue = [Color(0xFF3B82F6), Color(0xFF1D4ED8)];
  static const List<Color> gradientTeal = [Color(0xFF06B6D4), Color(0xFF0891B2)];
  static const List<Color> gradientPurple = [Color(0xFF8B5CF6), Color(0xFF7C3AED)];
  static const List<Color> gradientOrange = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const List<Color> gradientGreen = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> gradientPink = [Color(0xFFEC4899), Color(0xFFDB2777)];

  // Legacy colors for backward compatibility
  static const Color buttonBackground = primaryBlue;
  static const Color darkSecondary = darkSurface;
  static const Color lightSecondary = Color(0xFFF1F5F9);
  static const Color errorColor = errorRed;
  static const Color transparentTextDark = darkTextSecondary;
  static const Color labelLight = lightTextSecondary;
  static const Color labelDark = darkTextSecondary;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.dark(
        primary: primaryBlue,
        primaryContainer: primaryBlueDark,
        secondary: secondaryTeal,
        secondaryContainer: Color(0xFF164E63),
        tertiary: accentPurple,
        surface: darkSurface,
        surfaceVariant: darkCard,
        background: darkBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        onError: Colors.white,
        outline: darkBorder,
        shadow: Colors.black54,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 2,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed),
        ),
        labelStyle: TextStyle(color: darkTextSecondary),
        hintStyle: TextStyle(color: darkTextTertiary),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: darkTextPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: darkTextPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: darkTextPrimary, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: darkTextTertiary, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        primaryContainer: Color(0xFFDBEAFE),
        secondary: secondaryTeal,
        secondaryContainer: Color(0xFFCFFAFE),
        tertiary: accentPurple,
        surface: lightSurface,
        surfaceVariant: lightCard,
        background: lightBackground,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
        onError: Colors.white,
        outline: lightBorder,
        shadow: Colors.black12,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorRed),
        ),
        labelStyle: TextStyle(color: lightTextSecondary),
        hintStyle: TextStyle(color: lightTextTertiary),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: lightTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: lightTextPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: lightTextPrimary, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: lightTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: lightTextTertiary, fontSize: 10, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryBlue,
        unselectedItemColor: lightTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // Helper methods for gradient decorations
  static BoxDecoration primaryGradientDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientBlue,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: boxShadow,
    );
  }

  static BoxDecoration secondaryGradientDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientTeal,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: boxShadow,
    );
  }

  static BoxDecoration accentGradientDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientPurple,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: boxShadow,
    );
  }

  // Professional shadow presets
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
