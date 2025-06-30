import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/theme_controller.dart';
import 'themes/app_theme.dart';
import 'screens/sports_hub.dart';
import 'screens/profile_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/create_team_screen.dart';
import 'screens/create_tournament_screen.dart';
import 'screens/create_stadium_screen.dart';
import 'screens/team_management_screen.dart';
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
      title: 'Sports Hub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,

      initialRoute: '/signin', // Start with signin page

      routes: {
        '/sports_hub': (context) => const SportsHub(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/stadiums': (context) => const SportsHub(initialIndex: 3), // Navigate to stadiums tab
        '/academies': (context) => const SportsHub(initialIndex: 1), // Navigate to academies tab
        '/tournaments': (context) => const SportsHub(initialIndex: 2), // Navigate to tournaments tab
        '/bookings': (context) => const SportsHub(shouldShowBookingHistory: true), // Navigate to booking history
        '/profile': (context) => const ProfileScreen(),
        '/booking_history': (context) => const BookingHistoryScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/create_team': (context) => const CreateTeamScreen(),
        '/create_tournament': (context) => const CreateTournamentScreen(),
        '/create_stadium': (context) => const CreateStadiumScreen(),
        '/team_management': (context) => const TeamManagementScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
