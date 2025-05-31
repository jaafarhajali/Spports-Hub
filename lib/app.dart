import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/app_theme.dart';
import 'themes/theme_controller.dart';
import 'log page/signin_page.dart';
import 'log page/signup_page.dart';

class MyAuthApp extends StatelessWidget {
  const MyAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/signin',
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
      },
    );
  }
}
