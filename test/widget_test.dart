import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/Home.dart';
import 'package:flutter_application_1/Nest.dart';
import 'package:flutter_application_1/Onboarding screen.dart';
import 'package:flutter_application_1/auth_screen.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Welcome screen smoke test & navigation to Auth', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LifeNestApp());

    expect(find.text('LifeNest'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);

    // Tap Continue with Google
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    // Verify Auth screen opened
    expect(find.text('Welcome to your nest.'), findsOneWidget);
    expect(find.text('Sign In →'), findsOneWidget);
  });

  testWidgets('Auth screen toggles mode and submits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    // Verify initial sign in mode
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Switch to Create Account mode
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('FIRST NAME'), findsOneWidget);
    expect(find.text('LAST NAME'), findsOneWidget);
    expect(find.text('Create Account →'), findsOneWidget);

    // Switch back to Sign In mode
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Submit sign in
    await tester.tap(find.text('Sign In →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Verify navigates to Onboarding
    expect(find.text('Capture today.\nA calmer tomorrow.'), findsOneWidget);
  });

  testWidgets('Onboarding screen page flow and skip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(userName: 'Alex'),
      ),
    );

    // Screen 1: Intro
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Move to Screen 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Keep what matters.'), findsOneWidget);

    // Move to Screen 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Find it when\nyou need it.'), findsOneWidget);

    // Move to Screen 4
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text("Let's get started"), findsOneWidget);

    // Finish onboarding
    await tester.tap(find.text("Let's get started"));
    await tester.pumpAndSettle();

    // Verify Home Screen appears
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Need action'), findsOneWidget);
  });

  testWidgets('Home screen tabs, add modal, and profile logout modal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(userName: 'Alex'),
      ),
    );

    // Check Home header & widgets
    expect(find.text('LifeNest'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Need action'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Add anything'), findsOneWidget);

    // Switch to Inbox tab
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsWidgets);

    // Tap Nest button to open Nest screen
    await tester.tap(find.text('Nest').first);
    await tester.pumpAndSettle();
    expect(find.byType(NestScreen), findsOneWidget);

    // Tap Home in Nest screen bottom nav to return
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    // Switch back to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // Open Add Anything bottom sheet via bottom nav center button
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);

    // Close bottom sheet
    await tester.tap(find.text('Photos'));
    await tester.pumpAndSettle();

    // Open Profile bottom sheet (initial circle avatar 'A')
    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(find.text('Signed in with LifeNest'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('Full navigation from Auth through Onboarding to Home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    // Tap Sign In to trigger navigation to OnboardingScreen
    await tester.tap(find.text('Sign In →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Verify OnboardingScreen is shown
    expect(find.text('Capture today.\nA calmer tomorrow.'), findsOneWidget);

    // Advance through the pages to the last screen
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // On page 4, verify Let's get started button is present
    expect(find.text("Let's get started"), findsOneWidget);

    // Tap Let's get started
    await tester.tap(find.text("Let's get started"));
    await tester.pumpAndSettle();

    // Verify HomeScreen is successfully rendered
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Need action'), findsOneWidget);
  });
}

