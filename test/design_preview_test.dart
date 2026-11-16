// VERTX_GENERATE_PREVIEWS=1 flutter test test/design_preview_test.dart
// Uses the production widgets with demo data; no Firebase instance is required.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/models/habit_progress.dart';
import 'package:vertx/screens/habits/add_habit_screen.dart';
import 'package:vertx/utils/app_theme.dart';
import 'package:vertx/widgets/flow_layout.dart';
import 'package:vertx/widgets/focus_panel.dart';
import 'package:vertx/widgets/habit_tile.dart';
import 'package:vertx/widgets/profile_panel.dart';
import 'package:vertx/widgets/progress_panels.dart';

void main() {
  testWidgets('Flow screens render with demo data in light and dark appearance',
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
    final now = DateTime.now();
    final demo = <Map<String, dynamic>>[
      {
        'name': 'Morning movement',
        'category': 'Fitness',
        'iconCode': Icons.directions_run_outlined.codePoint,
        'goalTarget': 14,
        'completionDays': {
          for (var i = 0; i < 7; i++)
            HabitProgress.dayKey(DateTime(now.year, now.month, now.day - i)):
                true
        }
      },
      {
        'name': 'Read 10 pages',
        'category': 'Learning',
        'iconCode': Icons.menu_book_outlined.codePoint,
        'goalTarget': 21,
        'weekdays': [1, 3, 5],
        'reminderEnabled': true,
        'reminderMinutes': 1140,
        'completionDays': {
          for (var i = 1; i <= 5; i++)
            HabitProgress.dayKey(DateTime(now.year, now.month, now.day - i)):
                true
        }
      },
      {
        'name': 'Drink water',
        'category': 'Health',
        'iconCode': Icons.water_drop_outlined.codePoint,
        'goalTarget': 30
      },
    ];
    final key = GlobalKey();
    List<Widget> cards() => demo
        .map((habit) => HabitTile(
            habit: habit, onToggle: () {}, onSchedule: () {}, onEdit: () {}))
        .toList();
    Widget today() => TodayPanel(
        name: 'Alex',
        habits: demo,
        cards: cards(),
        onAdd: () {},
        onFocus: () {},
        onGoals: () {});
    Widget habits() =>
        HabitListPanel(habits: demo, cards: cards(), onAdd: () {});
    Widget goals() => GoalsPanel(habits: demo, onEdit: (_) {});
    Widget profile(bool dark) => ProfilePanel(
        name: 'Alex Morgan',
        dark: dark,
        onDarkChanged: (_) {},
        onPhoto: () {},
        onNotifications: () {},
        onPrivacy: () {},
        onHelp: () {},
        onSignOut: () {});
    Widget focus(String state) => FocusPanel(
        minutes: 25,
        remaining: state == 'finished'
            ? 0
            : state == 'idle'
                ? 1500
                : 1122,
        hasSession: state != 'idle',
        running: state == 'running',
        busy: false,
        onDuration: (_) {},
        onToggle: () {},
        onSave: () {},
        onReset: () {},
        summary: const Text('8 sessions · 200 focused minutes',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11)));
    Future<void> mount(Widget body, String id, int index,
        {bool dark = false, bool form = false}) async {
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              key: ValueKey(id),
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(dark ? Brightness.dark : Brightness.light),
              home: form
                  ? body
                  : Scaffold(
                      body: SafeArea(bottom: false, child: body),
                      bottomNavigationBar: FlowNavigationBar(
                          index: index, onChanged: (_) {})))));
      await tester.pumpAndSettle();
    }

    Future<void> capture(String id) async {
      expect(tester.takeException(), isNull, reason: id);
      if (Platform.environment['VERTX_GENERATE_PREVIEWS'] != '1') return;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('design').create(recursive: true);
        await File('design/$id.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final dark in [false, true]) {
      final suffix = dark ? '-dark' : '';
      await mount(today(), 'today$suffix', 0, dark: dark);
      await capture('today-demo$suffix');
      await mount(habits(), 'habits$suffix', 1, dark: dark);
      await capture('habits-demo$suffix');
      await mount(focus('idle'), 'focus$suffix', 2, dark: dark);
      await capture('focus-demo$suffix');
      await mount(goals(), 'goals$suffix', 3, dark: dark);
      await capture('goals-demo$suffix');
      if (!dark) {
        await tester.drag(
            find.byType(CustomScrollView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        await capture('goals-week-demo');
      }
      await mount(profile(dark), 'profile$suffix', 4, dark: dark);
      await capture('profile-demo$suffix');
    }
    for (final state in ['running', 'paused', 'finished']) {
      await mount(focus(state), 'focus-$state', 2);
      await capture('focus-$state-demo');
    }
    await mount(const AddHabitScreen(), 'add-habit', 0, form: true);
    await capture('add-habit-demo');
    await tester.enterText(find.byType(TextFormField).first, 'Read 10 pages');
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -290));
    await tester.pumpAndSettle();
    await capture('add-habit-routine-demo');
    await mount(AddHabitScreen(initial: demo[1]), 'edit-habit', 0, form: true);
    await capture('edit-habit-demo');
    await tester.drag(
        find.byType(CustomScrollView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
    await capture('edit-habit-routine-demo');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
