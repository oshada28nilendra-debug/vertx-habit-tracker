/// Calendar-day semantics shared by the dashboard, goals and analytics.
class HabitProgress {
  static String dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static List<int> weekdays(Map<String, dynamic> habit) {
    final saved = habit['weekdays'];
    if (saved is List && saved.isNotEmpty) return saved.cast<int>();
    if (habit['frequency'] == 'Weekdays') return [1, 2, 3, 4, 5];
    return [1, 2, 3, 4, 5, 6, 7];
  }

  static bool isDue(Map<String, dynamic> habit, DateTime day) =>
      weekdays(habit).contains(day.weekday);

  static Map<String, dynamic> history(Map<String, dynamic> habit) =>
      Map<String, dynamic>.from(habit['completionDays'] as Map? ?? {});

  static bool completed(Map<String, dynamic> habit, DateTime day) =>
      history(habit)[dayKey(day)] == true;

  static int total(Map<String, dynamic> habit) =>
      history(habit).values.where((value) => value == true).length;

  static int goal(Map<String, dynamic> habit) =>
      (habit['goalTarget'] as num? ?? 21).toInt().clamp(1, 1000);

  /// Rest days do not break a streak; an unfinished current day does not either.
  static int streak(Map<String, dynamic> habit, DateTime now) {
    final days = history(habit);
    if (days.isEmpty) return 0;
    final earliest = days.keys.toList()..sort();
    final start = DateTime.tryParse(earliest.first);
    if (start == null) return 0;
    var day = DateTime(now.year, now.month, now.day);
    var result = 0;
    while (!day.isBefore(start)) {
      if (isDue(habit, day)) {
        if (days[dayKey(day)] == true) {
          result++;
        } else if (dayKey(day) != dayKey(now)) {
          break;
        }
      }
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return result;
  }
}
