import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeController extends ChangeNotifier {
  // Default to system theme
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  ThemeData? _currentTheme;

  ThemeData? get currentTheme => _currentTheme;

  void setLightTheme() {
    _currentTheme = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E88E5),
        brightness: Brightness.light,
      ),
    );
    notifyListeners();
  }

  void setDarkTheme() {
    _currentTheme = ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E88E5),
        brightness: Brightness.dark,
      ),
    );
    notifyListeners();
  }
}
