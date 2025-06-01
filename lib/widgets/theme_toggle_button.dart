import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/theme_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Theme.of(context);
    final isDarkMode = themeProvider.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Use the provider to toggle the theme
        Provider.of<ThemeController>(context, listen: false).toggleTheme();
      },
      child: Container(
        padding: const EdgeInsets.all(6), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          size: 20, // Smaller icon
          color: isDarkMode ? Colors.amber : Colors.indigo,
        ),
      ),
    );
  }
}
