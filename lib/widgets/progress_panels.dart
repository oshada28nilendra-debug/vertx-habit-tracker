import 'package:flutter/material.dart';
import '../models/habit_progress.dart';

class TodayPanel extends StatelessWidget {
  const TodayPanel({
    super.key,
    required this.name,
    required this.habits,
    required this.cards,
    required this.onAdd,
    required this.onFocus,
    required this.onGoals,
  });
  final String name;
  final List<Map<String, dynamic>> habits;
  final List<Widget> cards;
  final VoidCallback onAdd, onFocus, onGoals;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final done = habits.where((h) => HabitProgress.completed(h, now)).length;
    final ratio = habits.isEmpty ? 0.0 : done / habits.length;
    final style = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LET’S MAKE TODAY COUNT',
                    style: style.labelSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hey, $name 👋',
                    style: style.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFFFDF85),
              child: Icon(
                Icons.bolt_rounded,
                color: Color(0xFF493727),
                size: 32,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF8062D6),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A little better, every day.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your small steps are adding up. ✨',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$done of ${habits.length}\nhabits today',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: ratio,
                            strokeWidth: 7,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFFFFDF85),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '${(ratio * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (habits.isNotEmpty && done == habits.length) ...[
                const SizedBox(height: 12),
                const Text(
                  'All done. Celebrate your little wins! 🎉',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _shortcut(
                context,
                'Find your flow',
                'Start a focus session',
                Icons.spa_rounded,
                const Color(0xFFD5F3E5),
                onFocus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shortcut(
                context,
                'Little wins',
                'See your milestones',
                Icons.auto_awesome_rounded,
                const Color(0xFFFFE4CF),
                onGoals,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Today’s little steps',
                style: style.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton.filled(
              onPressed: onAdd,
              tooltip: 'Add habit',
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (cards.isEmpty)
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text('🌻', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                const Text(
                  'A little space to grow.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No habits scheduled today. Enjoy a rest, or plant a new habit.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: onAdd,
                  child: const Text('Plant a new habit'),
                ),
              ],
            ),
          ),
        ...cards,
        const SizedBox(height: 16),
        const Text(
          'Progress, at your own pace. 🌱',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _shortcut(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback tap,
  ) =>
      Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF403849)),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF403849),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: Color(0xFF403849), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
}

class GoalsPanel extends StatelessWidget {
  const GoalsPanel({super.key, required this.habits, required this.onEdit});
  final List<Map<String, dynamic>> habits;
  final ValueChanged<int> onEdit;
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          'Look how you’re growing 🌼',
          style: style.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Every completed session is a step toward your goal.'),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your week in little wins',
                style: style.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final today = DateTime.now();
                  final day = DateTime(
                    today.year,
                    today.month,
                    today.day - (6 - i),
                  );
                  final due = habits.where((h) {
                    final created = h['createdDay'] as String?;
                    return HabitProgress.isDue(h, day) &&
                        (created == null ||
                            created.compareTo(HabitProgress.dayKey(day)) <= 0);
                  }).toList();
                  final count =
                      due.where((h) => HabitProgress.completed(h, day)).length;
                  final ratio = due.isEmpty ? 0.0 : count / due.length;
                  return Expanded(
                    child: Column(
                      children: [
                        Text('$count', style: style.labelSmall),
                        const SizedBox(height: 6),
                        Container(
                          height: 12 + ratio * 70,
                          width: 23,
                          decoration: BoxDecoration(
                            color: i == 6
                                ? const Color(0xFF8062D6)
                                : const Color(0xFFD5C8F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          const [
                            'M',
                            'T',
                            'W',
                            'T',
                            'F',
                            'S',
                            'S',
                          ][day.weekday - 1],
                          style: style.labelSmall,
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text(
                'Recorded completions only. Earlier history is not reconstructed.',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your milestones',
          style: style.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Add a habit to start your first goal. 🌱'),
          ),
        ...List.generate(habits.length, (i) {
          final habit = habits[i];
          final total = HabitProgress.total(habit);
          final goal = HabitProgress.goal(habit);
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${total >= goal ? '🏆' : '🌱'} ${habit['name']}',
                        style: style.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(i),
                      tooltip: 'Edit goal and schedule',
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                Text(
                  '$total / $goal sessions • ${HabitProgress.streak(habit, DateTime.now())} scheduled-day streak',
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (total / goal).clamp(0, 1),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [1, 7, 14, 30, 60, 100]
                      .map(
                        (n) => Chip(
                          avatar: Icon(
                            total >= n
                                ? Icons.check_circle_rounded
                                : Icons.lock_outline_rounded,
                            size: 16,
                          ),
                          label: Text('$n'),
                          backgroundColor:
                              total >= n ? const Color(0xFFD5F3E5) : null,
                          labelStyle: total >= n
                              ? const TextStyle(color: Color(0xFF24553C))
                              : null,
                        ),
                      )
                      .toList(),
                ),
                if (total >= goal)
                  const Text('Goal reached! Time to celebrate. 🎉'),
              ],
            ),
          );
        }),
      ],
    );
  }
}
