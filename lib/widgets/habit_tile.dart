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
  IconData _icon(int? code) {
    const icons = [
      Icons.water_drop_outlined,
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

  @override
  Widget build(BuildContext context) {
    final done = HabitProgress.completed(habit, DateTime.now());
    final color = Color(habit['colorValue'] as int? ?? 0xFF8062D6);
    final days = HabitProgress.weekdays(habit);
    final schedule = days.length == 7
        ? 'Every day'
        : days
            .map(
              (d) => const [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ][d - 1],
            )
            .join(' · ');
    final minutes = habit['reminderMinutes'] as int? ?? 540;
    final time = TimeOfDay(
      hour: minutes ~/ 60,
      minute: minutes % 60,
    ).format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: done
            ? color.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onToggle,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_icon(habit['iconCode'] as int?), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit['name'] as String? ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        schedule,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      if (habit['reminderEnabled'] == true)
                        Text(
                          'Reminder • $time',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      const SizedBox(height: 6),
                      Text(
                        '🔥 ${HabitProgress.streak(habit, DateTime.now())} streak  ·  ${habit['category'] ?? 'My habit'}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onSchedule,
                  tooltip: 'Schedule, reminder and goal',
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
                Semantics(
                  label: done ? 'Completed today' : 'Not completed today',
                  checked: done,
                  child: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: done ? color : Theme.of(context).colorScheme.outline,
                    size: 27,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
