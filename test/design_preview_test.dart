// Optional: VERTX_PREVIEW_FONT=/path/to/Roboto-Regular.ttf flutter test test/design_preview_test.dart
// Renders the actual dashboard and goal widgets using clearly labelled demo data.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/models/habit_progress.dart';
import 'package:vertx/widgets/habit_tile.dart';
import 'package:vertx/widgets/progress_panels.dart';

void main() {
  testWidgets('render dashboard and goals with demo data', (tester) async {
    final fontPath = Platform.environment['VERTX_PREVIEW_FONT'];
    if (fontPath == null) return;
    await tester.runAsync(() async {
      final font = FontLoader('PreviewRoboto')
        ..addFont(Future.value(
            ByteData.sublistView(await File(fontPath).readAsBytes())));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(await File(
                '${File(fontPath).parent.path}/MaterialIcons-Regular.otf')
            .readAsBytes())));
      await icons.load();
      final emojiPath = Platform.environment['VERTX_PREVIEW_EMOJI_FONT'];
      if (emojiPath != null) {
        final emoji = FontLoader('PreviewEmoji')
          ..addFont(Future.value(
              ByteData.sublistView(await File(emojiPath).readAsBytes())));
        await emoji.load();
      }
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final demo = <Map<String, dynamic>>[
      {
        'name': 'A little morning movement',
        'category': 'Fitness',
        'colorValue': 0xFFDA8661,
        'iconCode': Icons.directions_run_outlined.codePoint,
        'goalTarget': 14,
        'completionDays': {
          for (var i = 0; i < 7; i++)
            HabitProgress.dayKey(DateTime(now.year, now.month, now.day - i)):
                true,
        },
      },
      {
        'name': 'Read a few pages',
        'category': 'Learning',
        'colorValue': 0xFF8062D6,
        'iconCode': Icons.menu_book_outlined.codePoint,
        'goalTarget': 21,
      },
    ];
    final key = GlobalKey();
    Widget page(Widget body, int selected) => MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'PreviewRoboto',
            fontFamilyFallback: const ['PreviewEmoji'],
            scaffoldBackgroundColor: const Color(0xFFFFF9F2),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF8062D6),
            ).copyWith(surface: Colors.white),
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: SafeArea(child: body),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (_) {},
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.wb_sunny_rounded),
                    label: 'Today',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.check_circle_outline),
                    label: 'Habits',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.timelapse),
                    label: 'Focus',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.emoji_events_outlined),
                    label: 'Grow',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'You',
                  ),
                ],
              ),
            ),
          ),
        );
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('design').create(recursive: true);
        await File('design/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      page(
        TodayPanel(
          name: 'Alex',
          habits: demo,
          cards: demo
              .map(
                (h) => HabitTile(
                  habit: h,
                  onToggle: () {},
                  onSchedule: () {},
                  onEdit: () {},
                ),
              )
              .toList(),
          onAdd: () {},
          onFocus: () {},
          onGoals: () {},
        ),
        0,
      ),
    );
    await capture('today-demo');
    await tester.pumpWidget(page(GoalsPanel(habits: demo, onEdit: (_) {}), 3));
    await capture('goals-demo');
  });
}
