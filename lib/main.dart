import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_controller.dart';
import 'themes/app_theme.dart';
import 'screens/sports_hub.dart';
import 'log page/signin_page.dart';
import 'log page/signup_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const SportsHubApp(),
    ),
  );
}

class SportsHubApp extends StatelessWidget {
  const SportsHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'Sports Hub App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      home: const SignInPage(),
      routes: {
        '/sports_hub': (context) => const SportsHub(),
        '/signup': (context) => const SignUpPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
