import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit_progress.dart';

class ReminderService {
  static final instance = ReminderService._();
  ReminderService._();
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  Future<void> initialize() =>
      _initializing ??= _initialize().catchError((Object error) {
        _initializing = null;
        throw error;
      });
  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation(await FlutterTimezone.getLocalTimezone()),
    );
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<void> refreshTimeZone() async {
    await initialize();
    tz.setLocalLocation(
      tz.getLocation(await FlutterTimezone.getLocalTimezone()),
    );
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'vertx_routines',
      'Routine reminders',
      channelDescription: 'Your scheduled habits and focus sessions',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );
  int _id(String id, int weekday) {
    var hash = 5381;
    for (final unit in id.codeUnits) {
      hash = ((hash * 33) ^ unit) & 0x07ffffff;
    }
    return hash * 8 + weekday;
  }

  Future<void> cancelHabit(String id) async {
    await initialize();
    for (var day = 0; day <= 7; day++) {
      await plugin.cancel(_id(id, day));
    }
  }

  Future<void> scheduleHabit(String id, Map<String, dynamic> habit) async {
    await cancelHabit(id);
    if (habit['reminderEnabled'] != true) return;
    final minutes = habit['reminderMinutes'] as int? ?? 540;
    final now = tz.TZDateTime.now(tz.local);
    final weekdays = HabitProgress.weekdays(habit);
    final daily = weekdays.length == 7;
    // iOS permits only 64 pending requests. Leave space for the focus timer.
    final pending = await plugin.pendingNotificationRequests();
    if (pending.length + (daily ? 1 : weekdays.length) > 60) {
      throw StateError('Too many reminders scheduled on this device');
    }
    for (final weekday in daily ? [0] : weekdays) {
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      while ((!daily && next.weekday != weekday) || !next.isAfter(now)) {
        next = tz.TZDateTime(
          tz.local,
          next.year,
          next.month,
          next.day + 1,
          minutes ~/ 60,
          minutes % 60,
        );
      }
      await plugin.zonedSchedule(
        _id(id, weekday),
        'Time for a little progress ✨',
        habit['name'] as String? ?? 'Your habit is waiting',
        next,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: daily
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> focusEnd(DateTime end) async {
    await initialize();
    await plugin.zonedSchedule(
      2147483647,
      'Focus complete! 🎉',
      'You made time for yourself. Come back to save your session.',
      tz.TZDateTime.from(end, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelFocus() async {
    await initialize();
    await plugin.cancel(2147483647);
  }

  Future<void> cancelAll() async {
    await initialize();
    await plugin.cancelAll();
  }
}
