import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/screens/habits/add_habit_screen.dart';
import 'package:vertx/utils/app_theme.dart';
import 'package:vertx/widgets/focus_panel.dart';
import 'package:vertx/widgets/habit_tile.dart';
import 'package:vertx/widgets/profile_panel.dart';
import 'package:vertx/widgets/progress_panels.dart';

void main() {
  final demo = <Map<String, dynamic>>[
    {'name': 'Morning movement', 'category': 'Fitness'},
    {'name': 'Read 10 pages', 'category': 'Learning'},
  ];
  Widget shell(Widget child, {double scale = 1}) => MaterialApp(
      theme: buildAppTheme(Brightness.light),
      home: Scaffold(
          body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: child)));
  testWidgets('category filters show matching habits and can return to all',
      (tester) async {
    await tester.pumpWidget(shell(HabitListPanel(
        habits: demo,
        cards: demo
            .map((h) => HabitTile(
                habit: h, onToggle: () {}, onSchedule: () {}, onEdit: () {}))
            .toList(),
        onAdd: () {})));
    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Read 10 pages'), findsOneWidget);
    expect(find.text('Morning movement'), findsNothing);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Morning movement'), findsOneWidget);
  });
  testWidgets('creating a habit returns its selected days, category and target',
      (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(Brightness.light),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddHabitScreen()));
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Read 10 pages');
    await tester.tap(find.text('Learning'));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    for (final day in [2, 4, 6, 7]) {
      await tester.ensureVisible(find.byKey(ValueKey('weekday-$day')));
      await tester.tap(find.byKey(ValueKey('weekday-$day')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Create habit'));
    await tester.tap(find.text('Create habit'));
    await tester.pumpAndSettle();
    expect(result?['name'], 'Read 10 pages');
    expect(result?['category'], 'Learning');
    expect(result?['weekdays'], [1, 3, 5]);
    expect(result?['goalTarget'], 21);
    expect(result?['reminderEnabled'], false);
  });
  testWidgets(
      'focus controls start and save without allowing active duration changes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var toggles = 0, saves = 0, durations = 0;
    Widget panel(
            {bool running = false,
            bool hasSession = false,
            int remaining = 1500}) =>
        FocusPanel(
            minutes: 25,
            remaining: remaining,
            hasSession: hasSession,
            running: running,
            busy: false,
            onDuration: (_) => durations++,
            onToggle: () => toggles++,
            onSave: () => saves++,
            onReset: () {},
            summary: const SizedBox.shrink());
    await tester.pumpWidget(shell(panel()));
    await tester.tap(find.text('15 min'));
    await tester.ensureVisible(find.text('Start focus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start focus'));
    expect(toggles, 1);
    expect(durations, 1);
    await tester.pumpWidget(
        shell(panel(running: true, hasSession: true, remaining: 900)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('45 min'));
    await tester.tap(find.text('45 min'));
    expect(durations, 1);
    await tester.pumpWidget(shell(panel(hasSession: true, remaining: 0)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save session'));
    expect(saves, 1);
  });
  testWidgets('Flow panels fit a small phone at larger text sizes',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final panels = <Widget>[
      HabitListPanel(
          habits: demo,
          cards: demo
              .map((h) => HabitTile(
                  habit: h, onToggle: () {}, onSchedule: () {}, onEdit: () {}))
              .toList(),
          onAdd: () {}),
      GoalsPanel(habits: demo, onEdit: (_) {}),
      ProfilePanel(
          name: 'A long display name for accessibility',
          dark: false,
          onDarkChanged: (_) {},
          onPhoto: () {},
          onNotifications: () {},
          onPrivacy: () {},
          onHelp: () {},
          onSignOut: () {}),
      FocusPanel(
          minutes: 25,
          remaining: 1500,
          hasSession: false,
          running: false,
          busy: false,
          onDuration: (_) {},
          onToggle: () {},
          onSave: () {},
          onReset: () {},
          summary: const Text('8 sessions · 200 focused minutes')),
    ];
    for (final panel in panels) {
      await tester.pumpWidget(shell(panel, scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: panel.runtimeType.toString());
    }
  });
}
