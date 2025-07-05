import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
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
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
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

class SportsHubApp extends StatefulWidget {
  const SportsHubApp({super.key});

  @override
  State<SportsHubApp> createState() => _SportsHubAppState();
}

class _SportsHubAppState extends State<SportsHubApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Listen to incoming links when app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
    
    // Handle app launched from deep link
    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }
  }

  void _handleDeepLink(Uri uri) {
    print('Deep link received: $uri');
    if (uri.scheme == 'sportshub' && uri.host == 'reset_password') {
      final token = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : '';
      if (token.isNotEmpty) {
        navigatorKey.currentState?.pushNamed('/reset_password/$token');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return MaterialApp(
      title: 'Sports Hub',
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,

      initialRoute: '/signin', // Start with signin page

      routes: {
        '/sports_hub': (context) => const SportsHub(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
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

      // Handle dynamic routes for password reset
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/reset_password/')) {
          final token = settings.name!.split('/')[2];
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: token),
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
