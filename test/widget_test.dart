import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vertx/models/habit_progress.dart';
import 'package:vertx/widgets/schedule_fields.dart';
import 'package:vertx/widgets/progress_panels.dart';

void main() {
  test('rest days preserve scheduled-day streak and undo removes progress', () {
    final habit = <String, dynamic>{
      'weekdays': [1, 3, 5],
      'completionDays': {'2026-11-11': true, '2026-11-13': true},
    };
    expect(HabitProgress.isDue(habit, DateTime(2026, 11, 14)), false);
    expect(HabitProgress.streak(habit, DateTime(2026, 11, 16)), 2);
    expect(HabitProgress.streak(habit, DateTime(2026, 11, 17)), 0);
    expect(HabitProgress.total(habit), 2);
    (habit['completionDays'] as Map).remove('2026-11-13');
    expect(HabitProgress.total(habit), 1);
    expect(HabitProgress.completed(habit, DateTime(2026, 11, 13)), false);
  });

  test('calendar days survive month boundaries; legacy defaults are daily', () {
    expect(HabitProgress.dayKey(DateTime(2026, 2, 1)), '2026-02-01');
    final habit = <String, dynamic>{
      'completionDays': {'2026-01-31': true},
    };
    expect(HabitProgress.streak(habit, DateTime(2026, 2, 1)), 1);
    expect(HabitProgress.goal(habit), 21);
    expect(HabitProgress.weekdays({'frequency': 'Weekdays'}), [1, 2, 3, 4, 5]);
  });

  testWidgets('schedule cannot become empty and reports changed days', (
    tester,
  ) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleFields(
            initial: const {
              'weekdays': [1],
              'goalTarget': 21,
            },
            onChanged: (v) => result = v,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('weekday-1')));
    expect(result, isNull);
    await tester.tap(find.byKey(const ValueKey('weekday-3')));
    expect(result!['weekdays'], [1, 3]);
    await tester.tap(find.byKey(const ValueKey('weekday-1')));
    expect(result!['weekdays'], [3]);
  });

  testWidgets('today stays usable on a narrow phone with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: TodayPanel(
              name: 'A very long display name',
              habits: const [],
              cards: const [],
              onAdd: () {},
              onFocus: () {},
              onGoals: () {},
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('A little progress, daily'), findsOneWidget);
  });
}
