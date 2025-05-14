import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Import your main app
import 'package:first_attempt/app.dart';
import 'package:first_attempt/pages/signin_page.dart';
import 'package:first_attempt/pages/signup_page.dart';
import 'package:first_attempt/themes/theme_controller.dart';

void main() {
  // Test to ensure the app can be created
  testWidgets('App creates without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeController(),
        child: MyAuthApp(),
      ),
    );

    // Verify that the initial route is the sign-in page
    expect(find.byType(SignInPage), findsOneWidget);
  });

  // Test sign-in page elements
  testWidgets('Sign In page has key elements', (WidgetTester tester) async {
    // Build the SignInPage with proper provider
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => ChangeNotifierProvider(
                create: (_) => ThemeController(),
                child: SignInPage(),
              ),
        ),
      ),
    );

    // Verify key widgets exist
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(
      find.byType(TextFormField),
      findsNWidgets(2),
    ); // Username and Password fields
    expect(find.text('Keep me logged in'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  // Test sign-up page elements
  testWidgets('Sign Up page has key elements', (WidgetTester tester) async {
    // Build the SignUpPage with proper provider
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => ChangeNotifierProvider(
                create: (_) => ThemeController(),
                child: SignUpPage(),
              ),
        ),
      ),
    );

    // Verify key widgets exist
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(
      find.byType(TextFormField),
      findsNWidgets(5),
    ); // Username, Phone, Email, Password, Confirm Password
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  // Test navigation between sign-in and sign-up pages
  testWidgets('Can navigate between Sign In and Sign Up pages', (
    WidgetTester tester,
  ) async {
    // Build the app with proper provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeController(),
        child: MaterialApp(
          routes: {
            '/': (context) => SignInPage(),
            '/signin': (context) => SignInPage(),
            '/signup': (context) => SignUpPage(),
          },
        ),
      ),
    );

    // Find and tap the Sign Up button on Sign In page
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Now we should be on the Sign Up page
    expect(find.text('Already have an account?'), findsOneWidget);

    // Test navigation can be enhanced further as needed
  });

  // Test form validation
  testWidgets('Sign In form validation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeController(),
          child: SignInPage(),
        ),
      ),
    );

    // Find Sign In button and tap it without entering credentials
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();

    // Expect validation messages
    expect(find.text('Please enter your username'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
