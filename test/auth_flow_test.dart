import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/models/auth_validation.dart';
import 'package:vertx/screens/auth/login_screen.dart';
import 'package:vertx/screens/auth/signup_screen.dart';
import 'package:vertx/screens/auth/splash_screen.dart';
import 'package:vertx/screens/auth/reset_password_sheet.dart';
import 'package:vertx/utils/app_theme.dart';
import 'support/fake_auth_actions.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(Widget screen) =>
      MaterialApp(theme: buildAppTheme(Brightness.light), home: screen);
  Future<void> enter(WidgetTester tester, String id, String value) async {
    final field = find.byKey(ValueKey(id));
    await tester.ensureVisible(field);
    await tester.pump();
    await tester.enterText(field, value);
  }

  Finder action(String label) =>
      (label == 'Sign in' || label == 'Create account')
          ? find.widgetWithText(FilledButton, label)
          : find.text(label).last;
  Future<void> tap(WidgetTester tester, String label) async {
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(action(label));
    await tester.pumpAndSettle();
    await tester.tap(action(label));
    await tester.pump();
  }

  test(
      'validation preserves the existing signup policy and rejects malformed email',
      () {
    expect(AuthValidation.email('  alex@example.com  '), isNull);
    expect(AuthValidation.email('bad@@example.com'), isNotNull);
    expect(AuthValidation.email('alex@example'), isNotNull);
    expect(AuthValidation.name('   '), isNotNull);
    expect(AuthValidation.newPassword('secret7'), isNotNull);
    expect(AuthValidation.newPassword('Secret'), isNotNull);
    expect(AuthValidation.newPassword(' Secret7 '), isNull);
  });
  testWidgets('sign in rejects invalid fields before calling authentication',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions();
    await tester.pumpWidget(app(LoginScreen(actions: actions)));
    await enter(tester, 'email', 'bad@@example.com');
    await tap(tester, 'Sign in');
    expect(actions.signIns, 0);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });
  testWidgets(
      'sign in preserves password spaces and blocks overlapping requests',
      (tester) async {
    phone(tester);
    final pending = Completer<void>(), actions = FakeAuthActions();
    actions.onSignIn = () => pending.future;
    var authenticated = 0;
    await tester.pumpWidget(app(
        LoginScreen(actions: actions, onAuthenticated: () => authenticated++)));
    await enter(tester, 'email', '  alex@example.com  ');
    await enter(tester, 'password', ' Secret7 ');
    await tap(tester, 'Sign in');
    expect(actions.signIns, 1);
    expect(actions.email, 'alex@example.com');
    expect(actions.password, ' Secret7 ');
    await tester.tap(find.text('Signing in…'));
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(actions.signIns, 1);
    expect(actions.googleSignIns, 0);
    pending.complete();
    await tester.pumpAndSettle();
    expect(authenticated, 1);
  });
  testWidgets(
      'sign in failures show a retryable message and clear the loading state',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions()
      ..onSignIn = () async {
        throw FirebaseAuthException(code: 'network-request-failed');
      };
    await tester.pumpWidget(app(LoginScreen(actions: actions)));
    await enter(tester, 'email', 'alex@example.com');
    await enter(tester, 'password', 'Secret7');
    await tap(tester, 'Sign in');
    await tester.pumpAndSettle();
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Signing in…'), findsNothing);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });
  testWidgets(
      'password visibility can be toggled without changing the credential',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(app(LoginScreen(actions: FakeAuthActions())));
    await enter(tester, 'password', ' Secret7 ');
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('password')))
            .controller!
            .text,
        ' Secret7 ');
    final editables =
        tester.widgetList<EditableText>(find.byType(EditableText)).toList();
    expect(editables.last.obscureText, false);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        true);
  });
  testWidgets('Google cancellation returns to the form without navigating',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions()..onGoogle = () async => false;
    var authenticated = 0;
    await tester.pumpWidget(app(
        LoginScreen(actions: actions, onAuthenticated: () => authenticated++)));
    await tap(tester, 'Continue with Google');
    await tester.pumpAndSettle();
    expect(actions.googleSignIns, 1);
    expect(authenticated, 0);
    expect(find.text('Connecting…'), findsNothing);
  });
  testWidgets('signup validates confirmation then submits the exact password',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions();
    var authenticated = 0;
    await tester.pumpWidget(app(SignupScreen(
        actions: actions, onAuthenticated: () => authenticated++)));
    await enter(tester, 'name', '  Alex Carter  ');
    await enter(tester, 'email', ' alex@example.com ');
    await enter(tester, 'password', ' Secret7 ');
    await enter(tester, 'confirm-password', 'Secret7');
    await tap(tester, 'Create account');
    expect(actions.signUps, 0);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await enter(tester, 'confirm-password', ' Secret7 ');
    await tap(tester, 'Create account');
    await tester.pumpAndSettle();
    expect(actions.signUps, 1);
    expect(actions.name, 'Alex Carter');
    expect(actions.email, 'alex@example.com');
    expect(actions.password, ' Secret7 ');
    expect(authenticated, 1);
  });
  testWidgets('reset validates email and shows a neutral confirmation',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions();
    await tester
        .pumpWidget(app(Scaffold(body: ResetPasswordSheet(actions: actions))));
    await tap(tester, 'Send reset link');
    expect(actions.resets, 0);
    await enter(tester, 'reset-email', ' alex@example.com ');
    await tap(tester, 'Send reset link');
    await tester.pumpAndSettle();
    expect(actions.resets, 1);
    expect(actions.email, 'alex@example.com');
    expect(
        find.textContaining('If an account uses this email'), findsOneWidget);
  });
  testWidgets('unknown reset account has the same confirmation',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions()
      ..onReset = () async {
        throw FirebaseAuthException(code: 'user-not-found');
      };
    await tester.pumpWidget(app(Scaffold(
        body:
            ResetPasswordSheet(actions: actions, email: 'alex@example.com'))));
    await tap(tester, 'Send reset link');
    await tester.pumpAndSettle();
    expect(
        find.textContaining('If an account uses this email'), findsOneWidget);
  });
  for (final signedIn in [false, true]) {
    testWidgets('splash resolves a restored session: $signedIn',
        (tester) async {
      phone(tester);
      final actions = FakeAuthActions()..onRestore = () async => signedIn;
      bool? resolved;
      await tester.pumpWidget(app(SplashScreen(
          actions: actions, onResolved: (value) => resolved = value)));
      await tester.pump(const Duration(seconds: 1));
      expect(resolved, signedIn);
      expect(actions.restores, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
      'splash failures allow retry and do not silently sign the user out',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions();
    var attempt = 0;
    bool? resolved;
    actions.onRestore = () async {
      if (attempt++ == 0) throw Exception('offline');
      return true;
    };
    await tester.pumpWidget(app(SplashScreen(
        actions: actions, onResolved: (value) => resolved = value)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(resolved, isNull);
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(resolved, true);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('disposed sign in screens ignore late results', (tester) async {
    phone(tester);
    final pending = Completer<void>(), actions = FakeAuthActions();
    actions.onSignIn = () => pending.future;
    var authenticated = 0;
    await tester.pumpWidget(app(
        LoginScreen(actions: actions, onAuthenticated: () => authenticated++)));
    await enter(tester, 'email', 'alex@example.com');
    await enter(tester, 'password', 'Secret7');
    await tap(tester, 'Sign in');
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
    expect(authenticated, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('account creation navigates from sign in through signup to home',
      (tester) async {
    phone(tester);
    final actions = FakeAuthActions();
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(actions: actions)),
      GoRoute(
          path: '/signup',
          builder: (context, state) => SignupScreen(actions: actions)),
      GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home ready'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
        theme: buildAppTheme(Brightness.light), routerConfig: router));
    await tap(tester, 'Create an account');
    await tester.pumpAndSettle();
    expect(find.text('Start your rhythm'), findsOneWidget);
    await enter(tester, 'name', 'Alex Carter');
    await enter(tester, 'email', 'alex@example.com');
    await enter(tester, 'password', 'Secret7');
    await enter(tester, 'confirm-password', 'Secret7');
    await tap(tester, 'Create account');
    await tester.pumpAndSettle();
    expect(actions.signUps, 1);
    expect(find.text('Home ready'), findsOneWidget);
  });

  testWidgets(
      'small phones with keyboard and large text can reach auth actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    for (final screen in [
      LoginScreen(actions: FakeAuthActions()),
      SignupScreen(actions: FakeAuthActions())
    ]) {
      await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
          home: screen));
      await tester.pumpAndSettle();
      final target = action(
          screen is LoginScreen ? 'Continue with Google' : 'Create account');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final center = tester.getCenter(target);
      expect(center.dy, lessThan(440));
    }
  });
}
