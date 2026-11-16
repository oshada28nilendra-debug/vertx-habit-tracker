import 'package:flutter/material.dart';
import '../models/habit_progress.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onSchedule,
    required this.onEdit,
  });
  final Map<String, dynamic> habit;
  final VoidCallback onToggle, onSchedule, onEdit;
  @override
  Widget build(BuildContext context) {
    final done = HabitProgress.completed(habit, DateTime.now());
    final days = HabitProgress.weekdays(habit);
    final schedule = days.length == 7
        ? 'Daily'
        : days
            .map((d) =>
                const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d - 1])
            .join(', ');
    final minutes = habit['reminderMinutes'] as int? ?? 540;
    final streak = HabitProgress.streak(habit, DateTime.now());
    final detail = habit['reminderEnabled'] == true
        ? '$schedule · ${TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context)}'
        : streak > 0
            ? '$schedule · $streak day streak'
            : '$schedule · ${HabitProgress.goal(habit)}-session goal';
    return Column(children: [
      Row(children: [
        Expanded(
            child: InkWell(
                onTap: onToggle,
                onLongPress: onEdit,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Row(children: [
                      Icon(habitIcon(habit['iconCode'] as int?), size: 25),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(habit['name'] as String? ?? '',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(detail,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 10)),
                          ])),
                    ])))),
        IconButton(
            onPressed: onToggle,
            tooltip: done ? 'Undo completion' : 'Complete habit',
            isSelected: done,
            icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 25)),
        IconButton(
            onPressed: onSchedule,
            tooltip: 'Schedule, reminder and goal',
            icon: const Icon(Icons.tune_outlined, size: 20)),
      ]),
      const Divider(),
    ]);
  }
}

IconData habitIcon(int? code) {
  const icons = [
    Icons.water_drop_outlined,
    Icons.spa_outlined,
    Icons.fitness_center_outlined,
    Icons.menu_book_outlined,
    Icons.self_improvement_outlined,
    Icons.bedtime_outlined,
    Icons.directions_run_outlined,
    Icons.favorite_outline,
    Icons.star_outline,
    Icons.music_note_outlined,
    Icons.code_outlined,
    Icons.brush_outlined,
    Icons.restaurant_outlined,
    Icons.star_rounded,
  ];
  return icons.firstWhere(
    (icon) => icon.codePoint == code,
    orElse: () => Icons.star_rounded,
  );
}
