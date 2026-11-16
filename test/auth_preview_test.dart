// VERTX_GENERATE_AUTH_PREVIEWS=1 flutter test test/auth_preview_test.dart
// Production auth layouts; demo actions never contact Firebase.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/screens/auth/login_screen.dart';
import 'package:vertx/screens/auth/signup_screen.dart';
import 'package:vertx/screens/auth/splash_screen.dart';
import 'package:vertx/utils/app_theme.dart';
import 'support/fake_auth_actions.dart';

void main() {
  testWidgets('approved authentication layouts render in both appearances',
      (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('Poppins')
        ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    Future<void> mount(Widget screen, String id, {bool dark = false}) async {
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              key: ValueKey(id),
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(dark ? Brightness.dark : Brightness.light),
              home: screen)));
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> capture(String id) async {
      expect(tester.takeException(), isNull, reason: id);
      if (Platform.environment['VERTX_GENERATE_AUTH_PREVIEWS'] != '1') return;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5),
            data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('design').create(recursive: true);
        await File('design/$id.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await mount(const SplashView(), 'splash');
    await capture('auth-splash-demo');
    for (final dark in [false, true]) {
      final suffix = dark ? '-dark' : '';
      await mount(LoginScreen(actions: FakeAuthActions()), 'login$suffix',
          dark: dark);
      await capture('auth-signin-demo$suffix');
      await tester.tap(find.text('Forgot password?'));
      await tester.pump(const Duration(milliseconds: 500));
      await capture('auth-reset-demo$suffix');
      await mount(SignupScreen(actions: FakeAuthActions()), 'signup$suffix',
          dark: dark);
      await capture('auth-signup-demo$suffix');
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
